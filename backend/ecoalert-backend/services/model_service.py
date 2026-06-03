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
from collections import defaultdict

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

AQI_MODEL_CANDIDATES = [
    _REPO_ROOT / "AQI" / "models" / "best_aqi_openmeteo_model.pkl",
    _HERE.parent / "models" / "best_aqi_openmeteo_model.pkl",
    _REPO_ROOT / "AQI" / "models" / "best_aqi_numerical_model.pkl",
    _HERE.parent / "models" / "best_aqi_numerical_model.pkl",
]

AQI_METADATA_CANDIDATES = [
    _REPO_ROOT / "AQI" / "models" / "aqi_openmeteo_metadata.json",
    _HERE.parent / "models" / "aqi_openmeteo_metadata.json",
    _REPO_ROOT / "AQI" / "models" / "aqi_numerical_metadata.json",
    _HERE.parent / "models" / "aqi_numerical_metadata.json",
]

# ── Feature contract (must match training exactly) ────────────────────────
FEATURE_COLS = ["temperature", "humidity", "pressure", "cloud_cover", "wind_speed", "dew_point"]

AQI_FEATURE_COLS = [
    "components_co",
    "components_no2",
    "components_so2",
    "components_o3",
    "components_pm2_5",
    "components_pm10",
]

# ── Risk thresholds (from cloudburst/src/config.py) ──────────────────────
THRESHOLD           = 0.50
LOW_RISK_CUTOFF     = 0.30
MODERATE_RISK_CUTOFF = 0.60

AQI_CLASS_TO_VALUE = {
    1: 25,
    2: 75,
    3: 125,
    4: 175,
    5: 250,
}

# ── Open-Meteo endpoints (free, no key) ───────────────────────────────────
OPEN_METEO_FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
OPEN_METEO_ARCHIVE_URL = "https://archive-api.open-meteo.com/v1/archive"

OPEN_METEO_HOURLY_VARS = [
    "temperature_2m",
    "relative_humidity_2m",
    "dew_point_2m",
    "precipitation",
    "rain",
    "pressure_msl",
    "cloud_cover",
    "wind_speed_100m",
    "apparent_temperature",
    "weather_code",
    "surface_pressure",
]

OPEN_METEO_DAILY_VARS = [
    "weather_code",
    "precipitation_sum",
    "rain_sum",
    "precipitation_hours",
    "temperature_2m_mean",
    "temperature_2m_max",
    "temperature_2m_min",
]

AQI_OPEN_METEO_CURRENT_VARS = [
    "temperature_2m",
    "relative_humidity_2m",
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
        self._aqi_model = None
        self._aqi_model_path = None
        self._aqi_feature_cols = AQI_FEATURE_COLS
        self._load_model()
        self._load_aqi_model()

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

    def predict_aqi(self, features: dict, city: str = "") -> dict:
        """
        Predict AQI from pollutant readings and weather context.

        The trained AQI model in this repository is a classifier that predicts
        an AQI class. We convert that class to a representative AQI value so
        the Flutter UI can continue working with numeric AQI readings.
        """
        enriched = self._enrich_aqi_features(features, city)
        if self._aqi_model is not None:
            return self._predict_aqi_with_model(enriched, city)
        return self._rule_based_aqi(enriched, city)

    @property
    def status(self) -> dict:
        return {
            "cloudburst_model_loaded": self._model is not None,
            "model_path": str(self._model_path) if self._model_path else None,
            "feature_cols": FEATURE_COLS,
            "aqi_model_loaded": self._aqi_model is not None,
            "aqi_model_path": str(self._aqi_model_path) if self._aqi_model_path else None,
            "aqi_feature_cols": self._aqi_feature_cols,
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

    def _load_aqi_model(self):
        metadata = None
        for meta_candidate in AQI_METADATA_CANDIDATES:
            if meta_candidate.exists():
                try:
                    with open(meta_candidate, "r", encoding="utf-8") as f:
                        metadata = json.load(f)
                    self._aqi_feature_cols = metadata.get("feature_cols", AQI_FEATURE_COLS)
                    logger.info("[ModelService] Loaded AQI metadata: %s", meta_candidate)
                    break
                except Exception as e:
                    logger.error("[ModelService] Failed to load AQI metadata %s: %s", meta_candidate, e)

        for candidate in AQI_MODEL_CANDIDATES:
            if candidate.exists():
                try:
                    import joblib
                    self._aqi_model = joblib.load(candidate)
                    self._aqi_model_path = candidate
                    logger.info("[ModelService] Loaded AQI model: %s", candidate)
                    return
                except Exception as e:
                    logger.error("[ModelService] Failed to load AQI model %s: %s", candidate, e)

        logger.warning(
            "[ModelService] No AQI model file found. Checked: %s",
            [str(p) for p in AQI_MODEL_CANDIDATES],
        )

    # ─────────────────────────────────────────────────────────────────────
    # Open-Meteo data fetch (free, no API key needed)
    # ─────────────────────────────────────────────────────────────────────

    def _fetch_open_meteo_features(self, latitude: float, longitude: float) -> dict:
        """Fetch recent archived hourly Open-Meteo data and aggregate features."""
        # Archive data is more stable for model inputs than live forecast rows.
        # Use the most recent complete archive day, with a two-week window so the
        # API shape matches the refined cloudburst query used in project testing.
        end_date = datetime.utcnow().date() - timedelta(days=1)
        start_date = end_date - timedelta(days=14)

        params = {
            "latitude":      latitude,
            "longitude":     longitude,
            "hourly":        ",".join(OPEN_METEO_HOURLY_VARS),
            "daily":         ",".join(OPEN_METEO_DAILY_VARS),
            "start_date":    start_date.isoformat(),
            "end_date":      end_date.isoformat(),
            "timezone":      "auto",
            "wind_speed_unit": "kmh",
        }

        last_error = None
        for _ in range(2):
            try:
                resp = requests.get(OPEN_METEO_ARCHIVE_URL, params=params, timeout=15)
                resp.raise_for_status()
                break
            except requests.RequestException as exc:
                last_error = exc
        else:
            raise last_error

        data = resp.json()

        hourly = data.get("hourly", {})
        n = len(hourly.get("time", []))
        if n == 0:
            raise ValueError("Open-Meteo returned empty hourly data")

        def mean(values):
            vals = [v for v in values if v is not None]
            return sum(vals) / len(vals) if vals else 0.0

        rows_by_date = defaultdict(lambda: defaultdict(list))
        times = hourly.get("time", [])
        for index, timestamp in enumerate(times):
            date_key = str(timestamp).split("T", 1)[0]
            for api_key in OPEN_METEO_HOURLY_VARS:
                values = hourly.get(api_key, [])
                if index < len(values):
                    rows_by_date[date_key][api_key].append(values[index])

        if not rows_by_date:
            raise ValueError("Open-Meteo returned no hourly rows")

        latest_date = sorted(rows_by_date.keys())[-1]
        daily = rows_by_date[latest_date]

        raw_cloud = mean(daily.get("cloud_cover", []))
        cloud_cover_scaled = (
            (raw_cloud / 100.0) * 8.0
            if raw_cloud > 10
            else raw_cloud
        )

        temperature = mean(daily.get("temperature_2m", []))
        humidity    = mean(daily.get("relative_humidity_2m", []))
        dew_point   = mean(daily.get("dew_point_2m", [])) or self._calc_dew_point(temperature, humidity)
        pressure    = mean(daily.get("pressure_msl", []))
        wind_speed  = mean(daily.get("wind_speed_100m", []))

        features = {
            "temperature": round(temperature, 3),
            "humidity":    round(humidity, 3),
            "pressure":    round(pressure, 3),
            "cloud_cover": round(cloud_cover_scaled, 3),
            "wind_speed":  round(wind_speed, 3),
            "dew_point":   round(dew_point, 3),
        }

        logger.info(
            "[ModelService] Open-Meteo archive features (%s to %s): %s",
            start_date,
            end_date,
            features,
        )
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

    def _predict_aqi_with_model(self, features: dict, city: str) -> dict:
        try:
            import pandas as pd

            X = pd.DataFrame([{col: features.get(col, 0.0) for col in self._aqi_feature_cols}])
            raw_pred = self._aqi_model.predict(X)[0]

            predicted_class = None
            if hasattr(self._aqi_model, "classes_"):
                try:
                    predicted_class = int(raw_pred)
                except Exception:
                    predicted_class = None

            if predicted_class in AQI_CLASS_TO_VALUE:
                predicted_value = AQI_CLASS_TO_VALUE[predicted_class]
                source_label = f"class {predicted_class}"
            else:
                predicted_value = int(round(float(raw_pred)))
                source_label = "regression"

            predicted_value = max(0, min(500, predicted_value))
            category = self._aqi_category_from_value(predicted_value)

            proba = None
            if hasattr(self._aqi_model, "predict_proba"):
                try:
                    proba = self._aqi_model.predict_proba(X)[0]
                except Exception:
                    proba = None

            confidence = float(max(proba)) if proba is not None else None

            logger.info(
                "[ModelService] AQI → %s (%s) | model=True | city=%s",
                predicted_value,
                category,
                city,
            )

            return {
                "predicted_aqi": predicted_value,
                "predicted_category": category,
                "predicted_class": predicted_class,
                "using_model": True,
                "model_loaded": True,
                "source": source_label,
                "confidence": round(confidence, 4) if confidence is not None else None,
                "features_used": features,
                "city": city,
                "timestamp": datetime.utcnow().isoformat(),
            }
        except Exception as e:
            logger.error("[ModelService] AQI prediction error: %s", e)
            return self._rule_based_aqi(features, city)

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

    def _rule_based_aqi(self, features: dict, city: str) -> dict:
        pm25 = float(features.get("pm25", 0) or 0)
        pm10 = float(features.get("pm10", 0) or 0)
        no2 = float(features.get("no2", 0) or 0)
        o3 = float(features.get("o3", 0) or 0)
        co = float(features.get("co", 0) or 0)
        temperature = float(features.get("temperature", 0) or 0)
        humidity = float(features.get("humidity", 0) or 0)
        wind_speed = float(features.get("wind_speed", 0) or 0)

        score = 0.0
        score += min(pm25 / 250.0, 1.0) * 0.42
        score += min(pm10 / 300.0, 1.0) * 0.2
        score += min(no2 / 200.0, 1.0) * 0.12
        score += min(o3 / 200.0, 1.0) * 0.1
        score += min(co / 10.0, 1.0) * 0.08
        score += max(0.0, min((humidity - 30.0) / 70.0, 1.0)) * 0.05
        score += max(0.0, min((35.0 - wind_speed) / 35.0, 1.0)) * 0.03
        score -= max(0.0, min((temperature - 20.0) / 25.0, 1.0)) * 0.02

        predicted_value = int(round(max(0.0, min(500.0, score * 500.0))))
        category = self._aqi_category_from_value(predicted_value)

        return {
            "predicted_aqi": predicted_value,
            "predicted_category": category,
            "predicted_class": None,
            "using_model": False,
            "model_loaded": False,
            "source": "rule-based estimate",
            "confidence": None,
            "features_used": features,
            "city": city,
            "timestamp": datetime.utcnow().isoformat(),
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
    def _aqi_category_from_value(value: int) -> str:
        if value <= 50:
            return "Good"
        if value <= 100:
            return "Moderate"
        if value <= 150:
            return "Unhealthy for Sensitive Groups"
        if value <= 200:
            return "Unhealthy"
        if value <= 300:
            return "Very Unhealthy"
        return "Hazardous"

    def _normalize_aqi_features(self, features: dict) -> dict:
        f = dict(features)
        aliases = {
            "components_pm2_5": ["pm25", "pm2_5"],
            "components_pm10": ["pm10"],
            "components_no2": ["no2"],
            "components_o3": ["o3"],
            "components_co": ["co"],
            "components_so2": ["so2"],
            "components_no": ["no"],
            "components_nh3": ["nh3"],
        }

        for target, sources in aliases.items():
            if target in f and f[target] not in (None, ""):
                continue
            for source in sources:
                if source in f and f[source] not in (None, ""):
                    f[target] = f[source]
                    break

        for key in self._aqi_feature_cols:
            value = f.get(key, 0)
            try:
                f[key] = float(value)
            except Exception:
                f[key] = 0.0
        return f

    def _enrich_aqi_features(self, features: dict, city: str) -> dict:
        f = self._normalize_aqi_features(features)

        missing_weather = (
            f.get("temperature", 0) == 0
            or f.get("humidity", 0) == 0
            or f.get("wind_speed", 0) == 0
        )
        if not missing_weather:
            return f

        coords = self.city_to_coords(city)
        if not coords:
            return f

        try:
            resp = requests.get(
                OPEN_METEO_FORECAST_URL,
                params={
                    "latitude": coords[0],
                    "longitude": coords[1],
                    "current": ",".join(AQI_OPEN_METEO_CURRENT_VARS),
                    "timezone": "auto",
                },
                timeout=15,
            )
            resp.raise_for_status()
            data = resp.json().get("current", {})

            if f.get("temperature", 0) == 0:
                f["temperature"] = float(data.get("temperature_2m") or 0)
            if f.get("humidity", 0) == 0:
                f["humidity"] = float(data.get("relative_humidity_2m") or 0)
            if f.get("wind_speed", 0) == 0:
                f["wind_speed"] = float(data.get("wind_speed_10m") or 0)
        except Exception as e:
            logger.warning("[ModelService] AQI weather enrichment failed: %s", e)

        return f

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
