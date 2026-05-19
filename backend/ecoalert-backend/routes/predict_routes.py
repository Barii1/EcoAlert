"""
EcoAlert Prediction Routes
==========================
POST /api/predict/cloudburst  — main prediction endpoint (lat/lon)
POST /api/predict/cloudburst/features — prediction from raw features
POST /api/predict/aqi         — AQI prediction from sensor readings
GET  /api/predict/status      — model health check
"""

from flask import Blueprint, request, jsonify
from services.model_service import model_service, CITY_COORDS
from services.supabase_service import log_prediction

predict_bp = Blueprint("predict", __name__, url_prefix="/api/predict")


# ── Main endpoint: Flutter sends lat/lon, backend fetches weather + predicts ──
@predict_bp.route("/cloudburst", methods=["POST"])
def predict_cloudburst():
    """
    Request body (JSON) — two ways to call this:

    Option A — send coordinates (recommended):
    {
        "latitude":  31.5497,
        "longitude": 74.3436,
        "city":      "Lahore"    (optional, for display)
    }

    Option B — send city name, backend resolves coordinates:
    {
        "city": "Karachi"
    }

    Response:
    {
        "risk_level":             "Low" | "Moderate" | "High",
        "cloudburst_probability":  0.36,
        "predicted_class":         0,
        "features_used":           { "temperature": 28.1, ... },
        "using_model":             true,
        "city":                    "Lahore",
        "timestamp":               "2026-05-10T14:32:00"
    }
    """
    data = request.get_json(silent=True) or {}

    city = data.get("city", "")
    latitude  = data.get("latitude")
    longitude = data.get("longitude")

    # Resolve city → coords if not supplied directly
    if (latitude is None or longitude is None) and city:
        coords = model_service.city_to_coords(city)
        if coords:
            latitude, longitude = coords
        else:
            return jsonify({
                "error": f"Unknown city '{city}'. "
                         f"Supported: {list(CITY_COORDS.keys())}"
            }), 400

    if latitude is None or longitude is None:
        return jsonify({
            "error": "Provide either 'latitude'+'longitude' or a known 'city' name."
        }), 400

    try:
        result = model_service.predict_cloudburst(
            latitude=float(latitude),
            longitude=float(longitude),
            city=city,
        )
        log_prediction({
            "type": "cloudburst",
            "city": result.get("city") or city,
            "using_model": result.get("using_model"),
            "risk_level": result.get("risk_level"),
            "probability": result.get("cloudburst_probability"),
        })
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ── Alternative: Flutter sends its own weather readings ───────────────────
@predict_bp.route("/cloudburst/features", methods=["POST"])
def predict_cloudburst_from_features():
    """
    Use this if you already have weather data in Flutter and don't want
    a second Open-Meteo call in the backend.

    Request body:
    {
        "temperature": 28.5,    celsius
        "humidity":    72.0,    %
        "pressure":    1008.0,  hPa
        "cloud_cover": 65.0,    0-100 OR 0-8 (backend auto-detects)
        "wind_speed":  22.0,    km/h
        "dew_point":   20.1,    celsius (optional — calculated if missing)
        "city":        "Multan"
    }
    """
    data = request.get_json(silent=True) or {}
    city = data.pop("city", "")

    required = ["temperature", "humidity", "pressure", "cloud_cover", "wind_speed"]
    missing = [k for k in required if k not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {missing}"}), 400

    try:
        result = model_service.predict_cloudburst_from_features(data, city)
        log_prediction({
            "type": "cloudburst_features",
            "city": result.get("city") or city,
            "using_model": result.get("using_model"),
            "risk_level": result.get("risk_level"),
            "probability": result.get("cloudburst_probability"),
        })
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ── AQI prediction from current pollutant readings ────────────────────────
@predict_bp.route("/aqi", methods=["POST"])
def predict_aqi():
    """
    Predict AQI from current pollutant readings and weather context.

    Request body:
    {
        "pm25": 35.2,
        "pm10": 61.8,
        "no2": 18.4,
        "o3": 22.1,
        "co": 1.1,
        "city": "Lahore"
    }
    """
    data = request.get_json(silent=True) or {}
    city = data.pop("city", "")

    required = ["pm25", "pm10", "no2", "o3", "co"]
    missing = [k for k in required if k not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {missing}"}), 400

    try:
        result = model_service.predict_aqi(data, city)
        log_prediction({
            "type": "aqi",
            "city": result.get("city") or city,
            "using_model": result.get("using_model"),
            "predicted_aqi": result.get("predicted_aqi"),
            "predicted_category": result.get("predicted_category"),
            "predicted_class": result.get("predicted_class"),
        })
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ── Model health check ────────────────────────────────────────────────────
@predict_bp.route("/status", methods=["GET"])
def predict_status():
    """
    Returns whether the real model is loaded or rule-based fallback is active.
    GET /api/predict/status
    """
    return jsonify(model_service.status), 200
