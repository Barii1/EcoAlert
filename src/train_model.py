import json
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    confusion_matrix,
)

from config import (
    TRAIN_DATA_PATH,
    MODEL_PATH,
    METADATA_PATH,
    RESULTS_CSV_PATH,
    FEATURES_PATH,
    FEATURE_COLS,
    THRESHOLD,
)
from utils import standardize_columns, map_target_to_binary, ensure_feature_frame


def main():
    df = pd.read_csv(TRAIN_DATA_PATH, low_memory=False)
    df = standardize_columns(df)

    print("Dataset loaded successfully.")
    print(f"Shape: {df.shape}")
    print("\nColumns:")
    print(df.columns.tolist())

    if "cloudburst_tomorrow_binary" in df.columns:
        target_col = "cloudburst_tomorrow_binary"
    elif "cloudburst_tomorrow" in df.columns:
        target_col = "cloudburst_tomorrow"
    else:
        raise ValueError("Target column not found.")

    y = map_target_to_binary(df[target_col])

    if y.isna().any():
        raise ValueError("Target column could not be converted properly.")

    X = ensure_feature_frame(df)

    print("\nFeature sample:")
    print(X.head())

    print("\nTarget distribution:")
    print(y.value_counts(dropna=False))

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=42,
        stratify=y,
    )

    print("\nTrain shape:", X_train.shape)
    print("Test shape:", X_test.shape)

    models = {
        "LogisticRegression": Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
            ("model", LogisticRegression(max_iter=1000, random_state=42)),
        ]),
        "SVM": Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
            ("model", SVC(probability=True, random_state=42)),
        ]),
        "DecisionTree": Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("model", DecisionTreeClassifier(random_state=42, max_depth=6)),
        ]),
    }

    results = []
    best_model_name = None
    best_model = None
    best_f1 = -1

    for name, pipeline in models.items():
        print(f"\n{'=' * 50}")
        print(f"Training {name}...")
        pipeline.fit(X_train, y_train)

        y_pred = pipeline.predict(X_test)

        accuracy = accuracy_score(y_test, y_pred)
        precision = precision_score(y_test, y_pred, zero_division=0)
        recall = recall_score(y_test, y_pred, zero_division=0)
        f1 = f1_score(y_test, y_pred, zero_division=0)

        results.append({
            "model": name,
            "accuracy": accuracy,
            "precision": precision,
            "recall": recall,
            "f1_score": f1,
        })

        print(f"Accuracy : {accuracy:.4f}")
        print(f"Precision: {precision:.4f}")
        print(f"Recall   : {recall:.4f}")
        print(f"F1 Score : {f1:.4f}")

        print("\nClassification Report:")
        print(classification_report(y_test, y_pred, zero_division=0))

        print("Confusion Matrix:")
        print(confusion_matrix(y_test, y_pred))

        if f1 > best_f1:
            best_f1 = f1
            best_model_name = name
            best_model = pipeline

    results_df = pd.DataFrame(results).sort_values(by="f1_score", ascending=False)
    results_df.to_csv(RESULTS_CSV_PATH, index=False)

    joblib.dump(best_model, MODEL_PATH)

    metadata = {
        "best_model": best_model_name,
        "feature_cols": FEATURE_COLS,
        "threshold": THRESHOLD,
    }

    with open(METADATA_PATH, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    with open(FEATURES_PATH, "w", encoding="utf-8") as f:
        for col in FEATURE_COLS:
            f.write(col + "\n")

    print(f"\nSaved comparison results to: {RESULTS_CSV_PATH}")
    print(f"Best model: {best_model_name}")
    print(f"Best model saved to: {MODEL_PATH}")
    print(f"Metadata saved to: {METADATA_PATH}")
    print("Training complete.")


if __name__ == "__main__":
    main()