import base64
import io
import os

import requests as http
from flask import Blueprint, redirect, render_template, request, session, url_for
from PIL import Image
from postgrest.exceptions import APIError

from admin.db import get_db, get_env_mode

bp = Blueprint("news", __name__)

MESSAGE_TYPES = {
    "info": "Komunikat",
    "warning": "Ostrzeżenie",
    "alert": "Alert",
}
MAX_SIZE = (1024, 1024)


def upload_image(file) -> str:
    img = Image.open(file.stream).convert("RGB")
    img.thumbnail(MAX_SIZE, Image.LANCZOS)
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=90)
    r = http.post(
        "https://api.imgbb.com/1/upload",
        params={"key": os.environ["IMGBB_API_KEY"]},
        data={"image": base64.b64encode(buf.getvalue()).decode()},
        timeout=30,
    )
    r.raise_for_status()
    return r.json()["data"]["url"]


def _is_402(e: APIError) -> bool:
    return str(getattr(e, "code", "")) == "402"


@bp.route("/news")
def index():
    flash = session.pop("flash", None)
    error = None
    try:
        posts = get_db().table("news").select("*").order("created_at", desc=True).execute().data
    except APIError as e:
        posts = []
        error = "Supabase — przekroczony limit egress (402)." if _is_402(e) else f"Błąd bazy: {e}"
    return render_template(
        "news.html",
        title="News",
        active="news",
        env_mode=get_env_mode(),
        posts=posts,
        message_types=MESSAGE_TYPES,
        flash=flash,
        error=error,
    )


@bp.route("/news/add", methods=["POST"])
def add():
    try:
        result = get_db().table("news").insert({
            "title": request.form["title"],
            "content": request.form["content"],
            "message_type": request.form["message_type"],
        }).execute()

        file = request.files.get("image")
        if file and file.filename:
            url = upload_image(file)
            get_db().table("news").update({"image_url": url}).eq("id", result.data[0]["id"]).execute()

        session["flash"] = "Post dodany!"
    except APIError as e:
        session["flash"] = "Błąd 402 — Supabase zablokował zapis." if _is_402(e) else f"Błąd bazy: {e}"
    return redirect(url_for("news.index"))


@bp.route("/news/edit/<uuid:post_id>", methods=["POST"])
def edit(post_id):
    try:
        data = {
            "title": request.form["title"],
            "content": request.form["content"],
            "message_type": request.form["message_type"],
        }
        file = request.files.get("image")
        if file and file.filename:
            data["image_url"] = upload_image(file)
        get_db().table("news").update(data).eq("id", str(post_id)).execute()
        session["flash"] = "Post zaktualizowany!"
    except APIError as e:
        session["flash"] = "Błąd 402 — Supabase zablokował zapis." if _is_402(e) else f"Błąd bazy: {e}"
    return redirect(url_for("news.index"))


@bp.route("/news/delete/<uuid:post_id>", methods=["POST"])
def delete(post_id):
    try:
        get_db().table("news").delete().eq("id", str(post_id)).execute()
    except APIError as e:
        return ("Supabase 402 — egress quota." if _is_402(e) else f"Błąd bazy: {e}"), 503
    return "", 204
