from pathlib import Path
import pandas as pd
import joblib

# -----------------------------
# Paths
# -----------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_PATH = BASE_DIR / "data" / "CB_TESTING_DATA.csv"
MODEL_PATH = BASE_DIR / "models" / "best_cloudburst_model.pkl"
RESULTS_DIR = BASE_DIR / "results"

RESULTS_DIR.mkdir(exist_ok=True)

# -----------------------------
# Load model
# -----------------------------
model = joblib.load(MODEL_PATH)
print("Model loaded successfully.")

# -----------------------------
# Load Pakistan weather data
# -----------------------------
df = pd.read_csv(DATA_PATH)
print("Testing dataset loaded successfully.")
print(f"Shape: {df.shape}")

# Optional: parse date safely
if "date" in df.columns:
    df["date"] = pd.to_datetime(df["date"], errors="coerce")

# -----------------------------
# Features expected by model
# -----------------------------
feature_cols = [
    "temperature",
    "humidity",
    "pressure",
    "cloud_cover",
    "wind_speed",
    "dew_point"
]

# Check missing columns
missing_cols = [col for col in feature_cols if col not in df.columns]
if missing_cols:
    raise ValueError(f"Missing required columns in Testing dataset: {missing_cols}")

X = df[feature_cols].copy()

# -----------------------------
# Predict probabilities and class
# -----------------------------
# Probability of class 1 = cloudburst tomorrow
df["cloudburst_probability"] = model.predict_proba(X)[:, 1]

# Default classification threshold
threshold = 0.50
df["predicted_class"] = (df["cloudburst_probability"] >= threshold).astype(int)

# -----------------------------
# Risk level mapping
# -----------------------------
def get_risk_level(prob):
    if prob < 0.30:
        return "Low"
    elif prob < 0.60:
        return "Moderate"
    else:
        return "High"

df["risk_level"] = df["cloudburst_probability"].apply(get_risk_level)

# -----------------------------
# Save detailed predictions
# -----------------------------
output_cols = [
    "date",
    "city",
    "region",
    "latitude",
    "longitude",
    "elevation",
    "temperature",
    "humidity",
    "pressure",
    "cloud_cover",
    "wind_speed",
    "dew_point",
    "rainfall",
    "cloudburst_probability",
    "predicted_class",
    "risk_level",
]

# Keep only columns that actually exist
output_cols = [col for col in output_cols if col in df.columns]

output_path = RESULTS_DIR / "CB_TESTING_DATA.csv"
df[output_cols].to_csv(output_path, index=False)

print(f"Predictions saved to: {output_path}")

# -----------------------------
# Show quick summary
# -----------------------------
print("\nPrediction summary:")
print(df["predicted_class"].value_counts(dropna=False))

print("\nRisk level summary:")
print(df["risk_level"].value_counts(dropna=False))

print("\nTop 10 highest-risk records:")
top10 = df.sort_values("cloudburst_probability", ascending=False).head(10)
display_cols = [col for col in ["date", "city", "temperature", "humidity", "pressure", "cloud_cover", "wind_speed", "dew_point", "cloudburst_probability", "risk_level"] if col in top10.columns]
print(top10[display_cols].to_string(index=False))

print("\nTesting prediction run complete.")