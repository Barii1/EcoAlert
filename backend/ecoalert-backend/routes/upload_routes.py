import io

from flask import Blueprint, jsonify, request
from PIL import Image
from services.firestore_service import (
    update_report_image_urls,
    update_user_profile_picture,
)
from services.supabase_service import upload_profile_picture, upload_report_image

upload_bp = Blueprint("upload", __name__)

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}


def compress_image(file_bytes: bytes, max_size_kb: int = 800) -> bytes:
    """Compress image to under max_size_kb."""
    img = Image.open(io.BytesIO(file_bytes))
    if img.mode != "RGB":
        img = img.convert("RGB")
    output = io.BytesIO()
    quality = 85
    img.save(output, format="JPEG", quality=quality, optimize=True)
    while output.tell() > max_size_kb * 1024 and quality > 20:
        quality -= 10
        output = io.BytesIO()
        img.save(output, format="JPEG", quality=quality, optimize=True)
    return output.getvalue()


@upload_bp.route("/api/upload/report-images", methods=["POST"])
def upload_report_images():
    """
    Accepts multiple images for a hazard report.
    Flutter sends: multipart/form-data with fields:
      - report_id: string
      - images: one or more image files
    Returns: { "imageUrls": [...] }
    """
    report_id = request.form.get("report_id")
    if not report_id:
        return jsonify({"error": "report_id is required"}), 400

    files = request.files.getlist("images")
    if not files:
        return jsonify({"error": "No images provided"}), 400

    if len(files) > 5:
        return jsonify({"error": "Maximum 5 images per report"}), 400

    image_urls = []

    for index, file in enumerate(files):
        if file.content_type not in ALLOWED_TYPES:
            return jsonify({"error": f"Invalid file type: {file.content_type}"}), 400

        file_bytes = file.read()

        if len(file_bytes) > MAX_FILE_SIZE:
            return jsonify({"error": "File exceeds 5MB limit"}), 400

        compressed = compress_image(file_bytes)
        url = upload_report_image(compressed, report_id, index)
        image_urls.append(url)

    # Write URLs back to Firestore
    update_report_image_urls(report_id, image_urls)

    return jsonify({"imageUrls": image_urls}), 200


@upload_bp.route("/api/upload/profile-picture", methods=["POST"])
def upload_profile_pic():
    """
    Accepts a single profile picture.
    Flutter sends: multipart/form-data with fields:
      - uid: string
      - image: single image file
    Returns: { "photoUrl": "..." }
    """
    uid = request.form.get("uid")
    if not uid:
        return jsonify({"error": "uid is required"}), 400

    file = request.files.get("image")
    if not file:
        return jsonify({"error": "No image provided"}), 400

    if file.content_type not in ALLOWED_TYPES:
        return jsonify({"error": "Invalid file type"}), 400

    file_bytes = file.read()
    if len(file_bytes) > 2 * 1024 * 1024:
        return jsonify({"error": "File exceeds 2MB limit"}), 400

    compressed = compress_image(file_bytes, max_size_kb=400)
    url = upload_profile_picture(compressed, uid)
    update_user_profile_picture(uid, url)

    return jsonify({"photoUrl": url}), 200
