import base64
import io
import os
import requests as http
from flask import Flask, request, render_template, redirect, url_for, session
from dotenv import load_dotenv
from supabase import create_client
from PIL import Image
from postgrest.exceptions import APIError

load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

_env_mode_path = os.path.join(os.path.dirname(__file__), "..", ".env_mode")
_prefix = "TEST_" if open(_env_mode_path).read().strip() == "test" else ""
db = create_client(os.environ[f"{_prefix}SUPABASE_URL"], os.environ[f"{_prefix}SUPABASE_SERVICE_KEY"])

IMGBB_API_KEY = os.environ["IMGBB_API_KEY"]

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024  # 10 MB
app.secret_key = os.environ.get("FLASK_SECRET_KEY") or os.urandom(24)


@app.before_request
def check_origin():
    if request.method == "POST":
        origin = request.headers.get("Origin", "")
        referer = request.headers.get("Referer", "")
        if not (origin.startswith("http://localhost") or referer.startswith("http://localhost")):
            return "Forbidden", 403


MESSAGE_TYPES = {
    "info": "Komunikat",
    "warning": "Ostrzeżenie",
    "alert": "Alert",
}
MAX_SIZE = (1024, 1024)


def upload_image(file) -> str:
    """Uploaduje obraz na ImgBB i zwraca bezpośredni URL."""
    img = Image.open(file.stream).convert("RGB")
    img.thumbnail(MAX_SIZE, Image.LANCZOS)
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=90)
    r = http.post(
        "https://api.imgbb.com/1/upload",
        params={"key": IMGBB_API_KEY},
        data={"image": base64.b64encode(buf.getvalue()).decode()},
        timeout=30,
    )
    r.raise_for_status()
    return r.json()["data"]["url"]


def _is_402(e: APIError) -> bool:
    return str(getattr(e, "code", "")) == "402"


@app.route("/")
def index():
    flash = session.pop("flash", None)
    try:
        posts = db.table("news").select("*").order("created_at", desc=True).execute().data
    except APIError as e:
        error = "Supabase — przekroczony limit egress (402). Nie można pobrać postów." if _is_402(e) else f"Błąd bazy danych: {e}"
        return render_template("index.html", posts=[], message_types=MESSAGE_TYPES, flash=flash, error=error)
    return render_template("index.html", posts=posts, message_types=MESSAGE_TYPES, flash=flash)


@app.route("/add", methods=["POST"])
def add():
    try:
        result = db.table("news").insert({
            "title": request.form["title"],
            "content": request.form["content"],
            "message_type": request.form["message_type"],
        }).execute()

        file = request.files.get("image")
        if file and file.filename:
            post_id = result.data[0]["id"]
            url = upload_image(file)
            db.table("news").update({"image_url": url}).eq("id", post_id).execute()

        session["flash"] = "Post dodany!"
    except APIError as e:
        session["flash"] = "Błąd 402 — Supabase zablokował zapis (egress quota)." if _is_402(e) else f"Błąd bazy: {e}"
    return redirect(url_for("index"))


@app.route("/edit/<uuid:post_id>", methods=["POST"])
def edit(post_id):
    try:
        update_data = {
            "title": request.form["title"],
            "content": request.form["content"],
            "message_type": request.form["message_type"],
        }
        file = request.files.get("image")
        if file and file.filename:
            update_data["image_url"] = upload_image(file)

        db.table("news").update(update_data).eq("id", str(post_id)).execute()
        session["flash"] = "Post zaktualizowany!"
    except APIError as e:
        session["flash"] = "Błąd 402 — Supabase zablokował zapis (egress quota)." if _is_402(e) else f"Błąd bazy: {e}"
    return redirect(url_for("index"))


@app.route("/delete/<uuid:post_id>", methods=["POST"])
def delete(post_id):
    try:
        db.table("news").delete().eq("id", str(post_id)).execute()
    except APIError as e:
        return ("Supabase 402 — egress quota przekroczona." if _is_402(e) else f"Błąd bazy: {e}"), 503
    return "", 204


if __name__ == "__main__":
    debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    app.run(debug=debug, port=5050)
