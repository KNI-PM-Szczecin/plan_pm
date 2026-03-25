import io
import os
from flask import Flask, request, render_template, redirect, url_for, session
from dotenv import load_dotenv
from supabase import create_client
from PIL import Image

load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

_env_mode_path = os.path.join(os.path.dirname(__file__), "..", ".env_mode")
_prefix = "TEST_" if open(_env_mode_path).read().strip() == "test" else ""
db = create_client(os.environ[f"{_prefix}SUPABASE_URL"], os.environ[f"{_prefix}SUPABASE_SERVICE_KEY"])

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

BUCKET = "Files"
IMAGE_PATH = "News/{post_id}.png"
MESSAGE_TYPES = {
    "info": "Komunikat",
    "warning": "Ostrzeżenie",
    "alert": "Alert",
}
MAX_SIZE = (1024, 1024)


def image_url(post_id: str) -> str:
    return db.storage.from_(BUCKET).get_public_url(IMAGE_PATH.format(post_id=post_id))


def upload_image(file, post_id: str) -> None:
    img = Image.open(file.stream).convert("RGBA")
    img.thumbnail(MAX_SIZE, Image.LANCZOS)

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)

    path = IMAGE_PATH.format(post_id=post_id)
    db.storage.from_(BUCKET).upload(path, buf.read(), {"content-type": "image/png", "x-upsert": "true"})  # type: ignore[arg-type]


@app.route("/")
def index():
    flash = session.pop("flash", None)
    posts = db.table("news").select("*").order("created_at", desc=True).execute().data
    for post in posts:
        post["_image_url"] = image_url(post["id"])
    return render_template("index.html", posts=posts, message_types=MESSAGE_TYPES, flash=flash)


@app.route("/add", methods=["POST"])
def add():
    result = db.table("news").insert({
        "title": request.form["title"],
        "content": request.form["content"],
        "message_type": request.form["message_type"],
    }).execute()

    file = request.files.get("image")
    if file and file.filename:
        post_id = result.data[0]["id"]
        upload_image(file, post_id)

    session["flash"] = "Post dodany!"
    return redirect(url_for("index"))


@app.route("/edit/<uuid:post_id>", methods=["POST"])
def edit(post_id):
    db.table("news").update({
        "title": request.form["title"],
        "content": request.form["content"],
        "message_type": request.form["message_type"],
    }).eq("id", str(post_id)).execute()

    file = request.files.get("image")
    if file and file.filename:
        upload_image(file, str(post_id))

    session["flash"] = "Post zaktualizowany!"
    return redirect(url_for("index"))


@app.route("/delete/<uuid:post_id>", methods=["POST"])
def delete(post_id):
    db.table("news").delete().eq("id", str(post_id)).execute()
    try:
        db.storage.from_(BUCKET).remove([IMAGE_PATH.format(post_id=str(post_id))])
    except Exception:
        pass
    return "", 204


if __name__ == "__main__":
    debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    app.run(debug=debug, port=5050)
