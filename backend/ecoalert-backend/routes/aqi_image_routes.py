from flask import Blueprint, current_app, jsonify, request

from services.aqi_image_service import predict_image_bytes


aqi_image_bp = Blueprint("aqi_image", __name__)

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}


@aqi_image_bp.route("/api/aqi-image/predict", methods=["POST"])
def predict_aqi_image():
    file = request.files.get("image")
    if not file:
        return jsonify({"error": "No image provided"}), 400

    if file.content_type not in ALLOWED_TYPES:
        return jsonify({"error": "Invalid file type"}), 400

    image_bytes = file.read()
    if not image_bytes:
        return jsonify({"error": "Empty image payload"}), 400

    if len(image_bytes) > MAX_FILE_SIZE:
        return jsonify({"error": "File exceeds 5MB limit"}), 400

    try:
        prediction = predict_image_bytes(image_bytes)
    except Exception:
        current_app.logger.exception("AQI image inference failed")
        return jsonify({"error": "Inference failed"}), 500

    return jsonify(
        {
            "predictedLabel": prediction["predicted_label"],
            "confidence": prediction["confidence"],
            "topK": prediction["top_k"],
        }
    )
