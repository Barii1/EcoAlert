import io

from flask import Blueprint, jsonify, request
from PIL import Image
from services.firestore_service import (
    report_belongs_to_user,
    update_report_image_urls,
    update_user_profile_picture,
    user_is_admin,
    verify_id_token,
)
from services.supabase_service import (
    delete_report_image_paths,
    upload_profile_picture,
    upload_report_image,
)

upload_bp = Blueprint("upload", __name__)

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}


def _extract_bearer_token() -> str | None:
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None
    return auth_header.split(" ", 1)[1].strip()


def _require_authenticated_user(target_uid: str):
    id_token = _extract_bearer_token()
    if not id_token:
        return None, (jsonify({"error": "Missing Authorization bearer token"}), 401)

    try:
        claims = verify_id_token(id_token)
    except Exception:
        return None, (jsonify({"error": "Invalid or expired auth token"}), 401)

    actor_uid = claims.get("uid")
    if actor_uid != target_uid and not user_is_admin(actor_uid):
        return None, (jsonify({"error": "Forbidden"}), 403)

    return actor_uid, None


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

    requester_uid = request.form.get("uid")
    if not requester_uid:
        return jsonify({"error": "uid is required"}), 400

    actor_uid, auth_error = _require_authenticated_user(requester_uid)
    if auth_error is not None:
        return auth_error

    if not report_belongs_to_user(report_id, requester_uid) and not user_is_admin(actor_uid):
        return jsonify({"error": "You can only upload images for your own report"}), 403

    files = request.files.getlist("images")
    if not files:
        return jsonify({"error": "No images provided"}), 400

    if len(files) > 5:
        return jsonify({"error": "Maximum 5 images per report"}), 400

    image_urls = []
    uploaded_paths = []

    try:
        for index, file in enumerate(files):
            if file.content_type not in ALLOWED_TYPES:
                return jsonify({"error": f"Invalid file type: {file.content_type}"}), 400

            file_bytes = file.read()

            if len(file_bytes) > MAX_FILE_SIZE:
                return jsonify({"error": "File exceeds 5MB limit"}), 400

            compressed = compress_image(file_bytes)
            url = upload_report_image(compressed, report_id, index)
            uploaded_paths.append(f"{report_id}/image_{index}.jpg")
            image_urls.append(url)

        # Write URLs back to Firestore
        update_report_image_urls(report_id, image_urls)
    except Exception:
        # Clean up only files uploaded in this request.
        delete_report_image_paths(uploaded_paths)
        return jsonify({"error": "Failed to upload report images"}), 500

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

    _, auth_error = _require_authenticated_user(uid)
    if auth_error is not None:
        return auth_error

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
