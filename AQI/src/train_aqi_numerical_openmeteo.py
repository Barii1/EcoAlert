from pathlib import Path
import json
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    confusion_matrix,
)

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_PATH = BASE_DIR / "data" / "aqi_numerical_training_baseline.csv"
MODEL_DIR = BASE_DIR / "models"
RESULTS_DIR = BASE_DIR / "results"

MODEL_DIR.mkdir(exist_ok=True)
RESULTS_DIR.mkdir(exist_ok=True)

MODEL_PATH = MODEL_DIR / "best_aqi_openmeteo_model.pkl"
METADATA_PATH = MODEL_DIR / "aqi_openmeteo_metadata.json"
RESULTS_CSV_PATH = RESULTS_DIR / "aqi_openmeteo_model_comparison.csv"

TARGET_COL = "main_aqi"

FEATURE_COLS = [
    "components_co",
    "components_no2",
    "components_so2",
    "components_o3",
    "components_pm2_5",
    "components_pm10",
]

AQI_LABEL_MAP = {
    1: "Good",
    2: "Fair",
    3: "Moderate",
    4: "Poor",
    5: "Very Poor",
}


def main():
    df = pd.read_csv(DATA_PATH, low_memory=False)
    df.columns = [col.strip().lower() for col in df.columns]

    required_cols = FEATURE_COLS + [TARGET_COL]
    missing_cols = [col for col in required_cols if col not in df.columns]
    if missing_cols:
        raise ValueError(f"Missing required columns: {missing_cols}")

    X = df[FEATURE_COLS].copy()
    y = pd.to_numeric(df[TARGET_COL], errors="coerce")

    if y.isna().any():
        raise ValueError("Target column contains invalid values.")

    y = y.astype(int)

    print("Dataset loaded successfully.")
    print("Shape:", df.shape)
    print("\nFeatures used:")
    print(FEATURE_COLS)
    print("\nTarget distribution:")
    print(y.value_counts(dropna=False).sort_index())

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=42,
        stratify=y,
    )

    models = {
        "LogisticRegression": Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
            ("model", LogisticRegression(
                max_iter=2000,
                random_state=42,
                class_weight="balanced"
            )),
        ]),
        "DecisionTree": Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("model", DecisionTreeClassifier(
                max_depth=8,
                random_state=42,
                class_weight="balanced"
            )),
        ]),
        "RandomForest": Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("model", RandomForestClassifier(
                n_estimators=200,
                max_depth=12,
                random_state=42,
                class_weight="balanced_subsample",
                n_jobs=-1
            )),
        ]),
    }

    results = []
    best_model_name = None
    best_model = None
    best_macro_f1 = -1

    for name, pipeline in models.items():
        print("\n" + "=" * 60)
        print(f"Training {name}...")

        pipeline.fit(X_train, y_train)
        y_pred = pipeline.predict(X_test)

        accuracy = accuracy_score(y_test, y_pred)
        macro_precision = precision_score(y_test, y_pred, average="macro", zero_division=0)
        macro_recall = recall_score(y_test, y_pred, average="macro", zero_division=0)
        macro_f1 = f1_score(y_test, y_pred, average="macro", zero_division=0)

        results.append({
            "model": name,
            "accuracy": accuracy,
            "macro_precision": macro_precision,
            "macro_recall": macro_recall,
            "macro_f1": macro_f1,
        })

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

        if macro_f1 > best_macro_f1:
            best_macro_f1 = macro_f1
            best_model_name = name
            best_model = pipeline

    pd.DataFrame(results).sort_values(by="macro_f1", ascending=False).to_csv(RESULTS_CSV_PATH, index=False)
    joblib.dump(best_model, MODEL_PATH)

    metadata = {
        "best_model": best_model_name,
        "target_col": TARGET_COL,
        "feature_cols": FEATURE_COLS,
        "label_map": AQI_LABEL_MAP,
        "selection_metric": "macro_f1",
        "api_family": "open-meteo",
    }

    with open(METADATA_PATH, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    print(f"\nSaved comparison results to: {RESULTS_CSV_PATH}")
    print(f"Best model: {best_model_name}")
    print(f"Best model saved to: {MODEL_PATH}")
    print(f"Metadata saved to: {METADATA_PATH}")
    print("AQI Open-Meteo training complete.")


if __name__ == "__main__":
    main()