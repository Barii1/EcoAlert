from pathlib import Path
import json
import pandas as pd
import joblib

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    confusion_matrix,
)

# -----------------------------
# Paths
# -----------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_PATH = BASE_DIR / "data" / "aqi_numerical_testing_baseline.csv"
MODEL_PATH = BASE_DIR / "models" / "best_aqi_numerical_model.pkl"
METADATA_PATH = BASE_DIR / "models" / "aqi_numerical_metadata.json"
RESULTS_DIR = BASE_DIR / "results"

RESULTS_DIR.mkdir(exist_ok=True)

OUTPUT_PATH = RESULTS_DIR / "aqi_numerical_testing_predictions.csv"

AQI_LABEL_MAP = {
    1: "Good",
    2: "Fair",
    3: "Moderate",
    4: "Poor",
    5: "Very Poor",
}


def main():
    # -----------------------------
    # Load model + metadata
    # -----------------------------
    model = joblib.load(MODEL_PATH)

    with open(METADATA_PATH, "r", encoding="utf-8") as f:
        metadata = json.load(f)

    feature_cols = metadata["feature_cols"]
    target_col = metadata["target_col"]

    print("Model loaded successfully.")

    # -----------------------------
    # Load testing dataset
    # -----------------------------
    df = pd.read_csv(DATA_PATH, low_memory=False)
    df.columns = [col.strip().lower() for col in df.columns]

    if "datetime" in df.columns:
        df["datetime"] = pd.to_datetime(df["datetime"], errors="coerce")

    print("Testing dataset loaded successfully.")
    print(f"Shape: {df.shape}")
    print("\nColumns:")
    print(df.columns.tolist())

    # -----------------------------
    # Validate columns
    # -----------------------------
    required_cols = feature_cols + [target_col]
    missing_cols = [col for col in required_cols if col not in df.columns]
    if missing_cols:
        raise ValueError(f"Missing required columns: {missing_cols}")

    # -----------------------------
    # Features and target
    # -----------------------------
    X_test = df[feature_cols].copy()
    y_test = pd.to_numeric(df[target_col], errors="coerce")

    if y_test.isna().any():
        raise ValueError("Testing target contains invalid values.")

    y_test = y_test.astype(int)

    # -----------------------------
    # Predict
    # -----------------------------
    y_pred = model.predict(X_test)
    y_prob = model.predict_proba(X_test)

    df["predicted_aqi_class"] = y_pred
    df["predicted_aqi_label"] = df["predicted_aqi_class"].map(AQI_LABEL_MAP)

    # probability for predicted class
    df["prediction_confidence"] = y_prob.max(axis=1)

    # -----------------------------
    # Metrics
    # -----------------------------
    accuracy = accuracy_score(y_test, y_pred)
    macro_precision = precision_score(y_test, y_pred, average="macro", zero_division=0)
    macro_recall = recall_score(y_test, y_pred, average="macro", zero_division=0)
    macro_f1 = f1_score(y_test, y_pred, average="macro", zero_division=0)

    print("\nTesting Performance:")
    print(f"Accuracy       : {accuracy:.4f}")
    print(f"Macro Precision: {macro_precision:.4f}")
    print(f"Macro Recall   : {macro_recall:.4f}")
    print(f"Macro F1 Score : {macro_f1:.4f}")

    print("\nClassification Report:")
    print(classification_report(
        y_test,
        y_pred,
        labels=[1, 2, 3, 4, 5],
        target_names=[AQI_LABEL_MAP[i] for i in [1, 2, 3, 4, 5]],
        zero_division=0
    ))

    print("Confusion Matrix:")
    print(confusion_matrix(y_test, y_pred, labels=[1, 2, 3, 4, 5]))

    # -----------------------------
    # Save predictions
    # -----------------------------
    df.to_csv(OUTPUT_PATH, index=False)
    print(f"\nPredictions saved to: {OUTPUT_PATH}")

    print("\nPrediction distribution:")
    print(df["predicted_aqi_class"].value_counts(dropna=False).sort_index())

    print("\nTop 10 lowest-confidence predictions:")
    show_cols = [
        col for col in [
            "city",
            "datetime",
            "main_aqi",
            "main_aqi_label",
            "predicted_aqi_class",
            "predicted_aqi_label",
            "prediction_confidence"
        ]
        if col in df.columns
    ]

    print(df.sort_values("prediction_confidence", ascending=True)[show_cols].head(10).to_string(index=False))

    print("\nAQI numerical testing complete.")


if __name__ == "__main__":
    main()