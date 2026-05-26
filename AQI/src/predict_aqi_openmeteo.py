from pathlib import Path
import argparse
import json
import pandas as pd
import joblib
import requests

BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_PATH = BASE_DIR / "models" / "best_aqi_openmeteo_model.pkl"
METADATA_PATH = BASE_DIR / "models" / "aqi_openmeteo_metadata.json"
RESULTS_DIR = BASE_DIR / "results"
RESULTS_DIR.mkdir(exist_ok=True)

OUTPUT_CSV_PATH = RESULTS_DIR / "aqi_openmeteo_live_prediction.csv"
OUTPUT_JSON_PATH = RESULTS_DIR / "aqi_openmeteo_live_prediction.json"

OPEN_METEO_AQI_URL = "https://air-quality-api.open-meteo.com/v1/air-quality"

CURRENT_VARS = [
    "sulphur_dioxide",
    "nitrogen_dioxide",
    "pm2_5",
    "carbon_monoxide",
    "pm10",
    "ozone",
    "ammonia",   # requested in your URL; kept as extra, not required by model
]

LABEL_FALLBACK = {
    1: "Good",
    2: "Fair",
    3: "Moderate",
    4: "Poor",
    5: "Very Poor",
}


def fetch_openmeteo_aqi(lat: float, lon: float) -> dict:
    params = {
        "latitude": lat,
        "longitude": lon,
        "hourly": "pm10,pm2_5,carbon_monoxide,carbon_dioxide,nitrogen_dioxide,sulphur_dioxide,ammonia,methane",
        "current": ",".join(CURRENT_VARS),
        "domains": "cams_global",
        "timezone": "auto",
    }

    response = requests.get(OPEN_METEO_AQI_URL, params=params, timeout=30)
    response.raise_for_status()
    return response.json()


def build_feature_row(payload: dict, feature_cols: list[str]) -> pd.DataFrame:
    current = payload.get("current", {})

    row = {
        "latitude": payload.get("latitude"),
        "longitude": payload.get("longitude"),
        "timezone": payload.get("timezone"),
        "datetime": current.get("time"),
        "components_co": current.get("carbon_monoxide"),
        "components_no2": current.get("nitrogen_dioxide"),
        "components_so2": current.get("sulphur_dioxide"),
        "components_o3": current.get("ozone"),
        "components_pm2_5": current.get("pm2_5"),
        "components_pm10": current.get("pm10"),
        "raw_ammonia": current.get("ammonia"),
    }

    df = pd.DataFrame([row])

    for col in feature_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    missing = [col for col in feature_cols if df[col].isna().any()]
    if missing:
        raise ValueError(f"API payload is missing required model features: {missing}")

    return df


def main():
    parser = argparse.ArgumentParser(description="Predict AQI class from Open-Meteo Air Quality API.")
    parser.add_argument("--lat", type=float, required=True, help="Latitude")
    parser.add_argument("--lon", type=float, required=True, help="Longitude")
    args = parser.parse_args()

    model = joblib.load(MODEL_PATH)

    with open(METADATA_PATH, "r", encoding="utf-8") as f:
        metadata = json.load(f)

    feature_cols = metadata["feature_cols"]
    label_map = metadata.get("label_map", LABEL_FALLBACK)
    label_map = {int(k): v for k, v in label_map.items()}

    print("Model loaded successfully.")
    print("Fetching AQI data from Open-Meteo...")

    payload = fetch_openmeteo_aqi(lat=args.lat, lon=args.lon)

    print("Building feature row...")
    df = build_feature_row(payload, feature_cols)

    X = df[feature_cols].copy()

    y_pred = model.predict(X)
    y_prob = model.predict_proba(X)

    predicted_class = int(y_pred[0])
    predicted_label = label_map[predicted_class]
    confidence = float(y_prob.max(axis=1)[0])

    df["predicted_aqi_class"] = predicted_class
    df["predicted_aqi_label"] = predicted_label
    df["prediction_confidence"] = confidence

    df.to_csv(OUTPUT_CSV_PATH, index=False)
    df.to_json(OUTPUT_JSON_PATH, orient="records", indent=2)

    print("\nLive AQI prediction:")
    print(df.to_string(index=False))

    print(f"\nSaved CSV to: {OUTPUT_CSV_PATH}")
    print(f"Saved JSON to: {OUTPUT_JSON_PATH}")


if __name__ == "__main__":
    main()