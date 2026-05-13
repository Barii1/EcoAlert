"""
EcoAlert ML Model Service
=========================
Loads the trained cloudburst model and fetches live Open-Meteo data to
make predictions. No API key required — Open-Meteo is free.

Model details (from your partner's commit):
  - Algorithm:  LogisticRegression
  - Features:   temperature, humidity, pressure, cloud_cover, wind_speed, dew_point
  - Output:     cloudburst_probability (0-1)
  - Thresholds: Low < 0.30 | Moderate 0.30-0.60 | High >= 0.60

Model file location (relative to Flask app root):
  ../../cloudburst/models/best_cloudburst_model.pkl
  or ../../models/best_cloudburst_model.pkl  (root-level copy)

When the model file is found it runs real ML predictions.
When it is missing it falls back to a rule-based estimate so the app
still works during development.
"""

import json
import math
import logging
from pathlib import Path
from datetime import datetime, timedelta

import requests

logger = logging.getLogger(__name__)

# ── Paths ─────────────────────────────────────────────────────────────────
_HERE = Path(__file__).resolve().parent.parent          # backend/ecoalert-backend/
_REPO_ROOT = _HERE.parent.parent                        # repo root

MODEL_CANDIDATES = [
    _REPO_ROOT / "cloudburst" / "models" / "best_cloudburst_model.pkl",
    _REPO_ROOT / "models" / "best_cloudburst_model.pkl",
    _HERE / "models" / "best_cloudburst_model.pkl",     # local copy fallback
]

# ── Feature contract (must match training exactly) ────────────────────────
FEATURE_COLS = ["temperature", "humidity", "pressure", "cloud_cover", "wind_speed", "dew_point"]

# ── Risk thresholds (from cloudburst/src/config.py) ──────────────────────
THRESHOLD           = 0.50
LOW_RISK_CUTOFF     = 0.30
MODERATE_RISK_CUTOFF = 0.60

# ── Open-Meteo forecast endpoint (free, no key) ───────────────────────────
OPEN_METEO_FORECAST_URL = "https://api.open-meteo.com/v1/forecast"

OPEN_METEO_HOURLY_VARS = [
    "temperature_2m",
    "relative_humidity_2m",
    "dew_point_2m",
    "pressure_msl",
    "cloud_cover",
    "wind_speed_10m",
]

# ── City → coordinates lookup ─────────────────────────────────────────────
CITY_COORDS = {
    "lahore":      (31.5497, 74.3436),
    "karachi":     (24.8607, 67.0011),
    "islamabad":   (33.7294, 73.0931),
    "rawalpindi":  (33.6007, 73.0679),
    "peshawar":    (34.0151, 71.5249),
    "multan":      (30.1978, 71.4711),
    "faisalabad":  (31.4504, 73.1350),
    "quetta":      (30.1798, 66.9750),
    "hyderabad":   (25.3960, 68.3578),
    "sukkur":      (27.7052, 68.8574),
}


class ModelService:
    """
    Singleton service. Loads the cloudburst pkl once at startup.
    Exposes predict_cloudburst(lat, lon) → dict.
    """

    def __init__(self):
        self._model = None
        self._model_path = None
        self._load_model()

    # ─────────────────────────────────────────────────────────────────────
    # Public API
    # ─────────────────────────────────────────────────────────────────────

    def predict_cloudburst(self, latitude: float, longitude: float, city: str = "") -> dict:
        """
        Fetches today's weather from Open-Meteo for the given coordinates,
        runs it through the cloudburst model, and returns a structured result.

        Returns:
            {
                "risk_level":           "Low" | "Moderate" | "High",
                "cloudburst_probability": 0.0-1.0,
                "predicted_class":      0 | 1,
                "features_used":        { ... },
                "using_model":          True | False,
                "city":                 str,
                "timestamp":            ISO string
            }
        """
        try:
            features = self._fetch_open_meteo_features(latitude, longitude)
        except Exception as e:
            logger.error("[ModelService] Open-Meteo fetch failed: %s", e)
            # If weather fetch fails, return a sensible unknown state
            return {
                "risk_level": "Unknown",
                "cloudburst_probability": 0.0,
                "predicted_class": 0,
                "features_used": {},
                "using_model": False,
                "error": str(e),
                "city": city,
                "timestamp": datetime.utcnow().isoformat(),
            }

        if self._model is not None:
            return self._predict_with_model(features, city)

        logger.warning("[ModelService] Model not loaded — using rule-based fallback")
        return self._rule_based_cloudburst(features, city)

    def predict_cloudburst_from_features(self, features: dict, city: str = "") -> dict:
        """
        Same as predict_cloudburst but accepts pre-built feature dict
        (for when Flutter sends its own weather data instead of lat/lon).
        """
        enriched = self._enrich_features(features)
        if self._model is not None:
            return self._predict_with_model(enriched, city)
        return self._rule_based_cloudburst(enriched, city)

    @property
    def status(self) -> dict:
        return {
            "cloudburst_model_loaded": self._model is not None,
            "model_path": str(self._model_path) if self._model_path else None,
            "feature_cols": FEATURE_COLS,
            "thresholds": {
                "low":      f"< {LOW_RISK_CUTOFF}",
                "moderate": f"{LOW_RISK_CUTOFF} – {MODERATE_RISK_CUTOFF}",
                "high":     f">= {MODERATE_RISK_CUTOFF}",
            },
        }

    # ─────────────────────────────────────────────────────────────────────
    # Model loading
    # ─────────────────────────────────────────────────────────────────────

    def _load_model(self):
        for candidate in MODEL_CANDIDATES:
            if candidate.exists():
                try:
                    import joblib
                    self._model = joblib.load(candidate)
                    self._model_path = candidate
                    logger.info("[ModelService] Loaded: %s", candidate)
                    return
                except Exception as e:
                    logger.error("[ModelService] Failed to load %s: %s", candidate, e)

        logger.warning(
            "[ModelService] No model file found. Checked: %s",
            [str(p) for p in MODEL_CANDIDATES],
        )

    # ─────────────────────────────────────────────────────────────────────
    # Open-Meteo data fetch (free, no API key needed)
    # ─────────────────────────────────────────────────────────────────────

    def _fetch_open_meteo_features(self, latitude: float, longitude: float) -> dict:
        """Fetches today's hourly forecast and aggregates to daily features."""
        today = datetime.utcnow().date()
        tomorrow = today + timedelta(days=1)

        params = {
            "latitude":      latitude,
            "longitude":     longitude,
            "hourly":        ",".join(OPEN_METEO_HOURLY_VARS),
            "start_date":    today.isoformat(),
            "end_date":      tomorrow.isoformat(),
            "timezone":      "auto",
            "wind_speed_unit": "kmh",
        }

        resp = requests.get(OPEN_METEO_FORECAST_URL, params=params, timeout=15)
        resp.raise_for_status()
        data = resp.json()

        hourly = data.get("hourly", {})
        n = len(hourly.get("time", []))
        if n == 0:
            raise ValueError("Open-Meteo returned empty hourly data")

        def mean(lst):
            vals = [v for v in lst if v is not None]
            return sum(vals) / len(vals) if vals else 0.0

        raw_cloud = mean(hourly.get("cloud_cover", []))
        # Partner's code converts 0-100 percentage to 0-8 scale
        cloud_cover_scaled = (raw_cloud / 100.0) * 8.0

        temperature = mean(hourly.get("temperature_2m", []))
        humidity    = mean(hourly.get("relative_humidity_2m", []))
        dew_point   = mean(hourly.get("dew_point_2m", [])) or self._calc_dew_point(temperature, humidity)
        pressure    = mean(hourly.get("pressure_msl", []))
        wind_speed  = mean(hourly.get("wind_speed_10m", []))

        features = {
            "temperature": round(temperature, 3),
            "humidity":    round(humidity, 3),
            "pressure":    round(pressure, 3),
            "cloud_cover": round(cloud_cover_scaled, 3),
            "wind_speed":  round(wind_speed, 3),
            "dew_point":   round(dew_point, 3),
        }

        logger.info("[ModelService] Open-Meteo features: %s", features)
        return features

    # ─────────────────────────────────────────────────────────────────────
    # Prediction with real model
    # ─────────────────────────────────────────────────────────────────────

    def _predict_with_model(self, features: dict, city: str) -> dict:
        try:
            import pandas as pd
            # Pass a DataFrame with named columns — the Pipeline's
            # SimpleImputer was fitted with feature names so this is required.
            X = pd.DataFrame([{col: features.get(col, 0.0) for col in FEATURE_COLS}])

            prob = float(self._model.predict_proba(X)[0][1])
            pred_class = 1 if prob >= THRESHOLD else 0
            risk_level = self._risk_level(prob)

            logger.info(
                "[ModelService] Cloudburst → %.3f (%s) | model=True | city=%s",
                prob, risk_level, city,
            )

            return {
                "risk_level":             risk_level,
                "cloudburst_probability": round(prob, 4),
                "predicted_class":        pred_class,
                "features_used":          features,
                "using_model":            True,
                "city":                   city,
                "timestamp":              datetime.utcnow().isoformat(),
            }
        except Exception as e:
            logger.error("[ModelService] Prediction error: %s", e)
            return self._rule_based_cloudburst(features, city)

    # ─────────────────────────────────────────────────────────────────────
    # Rule-based fallback (used when model file is missing)
    # ─────────────────────────────────────────────────────────────────────

    def _rule_based_cloudburst(self, features: dict, city: str) -> dict:
        humidity    = features.get("humidity", 0)
        cloud_cover = features.get("cloud_cover", 0)   # 0-8 scale
        wind_speed  = features.get("wind_speed", 0)

        # Simple heuristic: high humidity + high cloud cover + strong wind = likely cloudburst
        score = 0.0
        score += min(humidity / 100.0, 1.0) * 0.4
        score += min(cloud_cover / 8.0, 1.0) * 0.35
        score += min(wind_speed / 80.0, 1.0) * 0.25

        risk_level = self._risk_level(score)
        return {
            "risk_level":             risk_level,
            "cloudburst_probability": round(score, 4),
            "predicted_class":        1 if score >= THRESHOLD else 0,
            "features_used":          features,
            "using_model":            False,
            "city":                   city,
            "timestamp":              datetime.utcnow().isoformat(),
        }

    # ─────────────────────────────────────────────────────────────────────
    # Utility
    # ─────────────────────────────────────────────────────────────────────

    @staticmethod
    def _risk_level(prob: float) -> str:
        if prob < LOW_RISK_CUTOFF:
            return "Low"
        if prob < MODERATE_RISK_CUTOFF:
            return "Moderate"
        return "High"

    @staticmethod
    def _calc_dew_point(temp_c: float, humidity: float) -> float:
        """Magnus formula — same as partner's utils.py dew_point_celsius()."""
        humidity = max(1.0, min(float(humidity), 100.0))
        a, b = 17.27, 237.7
        gamma = math.log(humidity / 100.0) + (a * temp_c / (b + temp_c))
        return (b * gamma) / (a - gamma)

    @staticmethod
    def _enrich_features(features: dict) -> dict:
        f = dict(features)
        if "dew_point" not in f or f["dew_point"] == 0:
            t = f.get("temperature", 20)
            h = f.get("humidity", 50)
            a, b = 17.27, 237.7
            gamma = math.log(max(h, 1) / 100.0) + (a * t / (b + t))
            f["dew_point"] = (b * gamma) / (a - gamma)
        if "cloud_cover" in f and f["cloud_cover"] > 10:
            f["cloud_cover"] = (f["cloud_cover"] / 100.0) * 8.0
        return f

    @staticmethod
    def city_to_coords(city: str):
        """Returns (lat, lon) for a city name, or None if not found."""
        return CITY_COORDS.get(city.lower().strip())


# ── Singleton ─────────────────────────────────────────────────────────────
model_service = ModelService()
