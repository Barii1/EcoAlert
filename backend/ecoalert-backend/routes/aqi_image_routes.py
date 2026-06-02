from flask import Blueprint, current_app, jsonify, request

from services.aqi_image_service import get_model_status, predict_image_bytes


aqi_image_bp = Blueprint("aqi_image", __name__)

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def _is_allowed_upload(file) -> bool:
    if file.content_type in ALLOWED_TYPES:
        return True
    filename = (file.filename or "").lower()
    return any(filename.endswith(ext) for ext in ALLOWED_EXTENSIONS)


@aqi_image_bp.route("/api/aqi-image/health", methods=["GET"])
def aqi_image_health():
    status = get_model_status()
    http_status = 200 if status.get("model_loaded") else 503
    return jsonify(status), http_status


@aqi_image_bp.route("/api/aqi-image/predict", methods=["POST"])
def predict_aqi_image():
    file = request.files.get("image")
    if not file:
        return jsonify({"error": "No image provided"}), 400

    image_bytes = file.read()
    if not image_bytes:
        return jsonify({"error": "Empty image payload"}), 400

    if len(image_bytes) > MAX_FILE_SIZE:
        return jsonify({"error": "File exceeds 5MB limit"}), 400

    if not _is_allowed_upload(file):
        current_app.logger.warning(
            "AQI image upload has unknown type; attempting decode anyway: content_type=%s filename=%s",
            file.content_type,
            file.filename,
        )

    try:
        prediction = predict_image_bytes(image_bytes)
    except Exception:
        current_app.logger.exception("AQI image inference failed")
        return jsonify({"error": "Inference failed"}), 500

    return jsonify(
        {
            "predictedLabel": prediction["predicted_label"],
            "predicted_label": prediction["predicted_label"],
            "confidence": prediction["confidence"],
            "topK": prediction["top_k"],
            "top_k": prediction["top_k"],
            "probabilities": prediction["probabilities"],
        }
    )
