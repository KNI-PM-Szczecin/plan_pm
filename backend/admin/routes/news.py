import base64
import io
import os

import requests as http
from flask import Blueprint, redirect, render_template, request, session, url_for
from PIL import Image, UnidentifiedImageError
from postgrest.exceptions import APIError

from admin.db import get_db, get_env_mode
from notifier import notify_discord

bp = Blueprint("news", __name__)

MESSAGE_TYPES = {
    "info": "Komunikat",
    "warning": "Ostrzeżenie",
    "alert": "Alert",
}
MAX_SIZE = (1024, 1024)


class ImageError(Exception):
    """Raised when an uploaded image can't be decoded or uploaded."""


def upload_image(file) -> str:
    try:
        img = Image.open(file.stream).convert("RGB")
        img.thumbnail(MAX_SIZE, Image.LANCZOS)
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as e:
        raise ImageError("Nieprawidłowy lub uszkodzony plik obrazu.") from e

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=90)
    try:
        r = http.post(
            "https://api.imgbb.com/1/upload",
            params={"key": os.environ["IMGBB_API_KEY"]},
            data={"image": base64.b64encode(buf.getvalue()).decode()},
            timeout=30,
        )
        r.raise_for_status()
        return r.json()["data"]["url"]
    except (http.RequestException, KeyError, ValueError) as e:
        raise ImageError("Nie udało się wysłać obrazu na hosting.") from e


def _read_news_form() -> dict:
    """Read + validate the news form; raises ValueError with a user message."""
    title = (request.form.get("title") or "").strip()
    content = (request.form.get("content") or "").strip()
    message_type = request.form.get("message_type") or "info"
    if not title:
        raise ValueError("Tytuł jest wymagany.")
    if message_type not in MESSAGE_TYPES:
        raise ValueError(f"Nieprawidłowy typ wiadomości: {message_type}.")
    return {"title": title, "content": content, "message_type": message_type}


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


def _flash_error(e) -> str:
    if isinstance(e, APIError) and _is_402(e):
        return "Błąd 402 — Supabase zablokował zapis."
    return f"Błąd: {e}"


@bp.route("/news/add", methods=["POST"])
def add():
    try:
        data = _read_news_form()
    except ValueError as e:
        session["flash"] = str(e)
        return redirect(url_for("news.index"))

    title = data["title"]
    try:
        # Upload the image FIRST, then insert once — so a failed upload never
        # leaves an orphaned, image-less row published as a "success".
        file = request.files.get("image")
        if file and file.filename:
            data["image_url"] = upload_image(file)
        get_db().table("news").insert(data).execute()
        session["flash"] = "Post dodany!"
        notify_discord("Dodano news", success=True, detail=title)
    except (APIError, ImageError) as e:
        session["flash"] = _flash_error(e)
        notify_discord("Dodanie newsa nie powiodło się", success=False, detail=title)
    return redirect(url_for("news.index"))


@bp.route("/news/edit/<uuid:post_id>", methods=["POST"])
def edit(post_id):
    try:
        data = _read_news_form()
    except ValueError as e:
        session["flash"] = str(e)
        return redirect(url_for("news.index"))

    try:
        file = request.files.get("image")
        if file and file.filename:
            data["image_url"] = upload_image(file)
        get_db().table("news").update(data).eq("id", str(post_id)).execute()
        session["flash"] = "Post zaktualizowany!"
        notify_discord("Zaktualizowano news", success=True, detail=data["title"])
    except (APIError, ImageError) as e:
        session["flash"] = _flash_error(e)
        notify_discord("Aktualizacja newsa nie powiodła się", success=False, detail=data["title"])
    return redirect(url_for("news.index"))


@bp.route("/news/delete/<uuid:post_id>", methods=["POST"])
def delete(post_id):
    try:
        get_db().table("news").delete().eq("id", str(post_id)).execute()
    except APIError as e:
        return ("Supabase 402 — egress quota." if _is_402(e) else f"Błąd bazy: {e}"), 503
    notify_discord("Usunięto news", success=True, detail=str(post_id))
    return "", 204
