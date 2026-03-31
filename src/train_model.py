from pathlib import Path
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.svm import SVC
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    confusion_matrix
)

# -----------------------------
# Paths
# -----------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_PATH = BASE_DIR / "data" / "CB_TRAINING_DATA.csv"
MODEL_DIR = BASE_DIR / "models"
RESULTS_DIR = BASE_DIR / "results"

MODEL_DIR.mkdir(exist_ok=True)
RESULTS_DIR.mkdir(exist_ok=True)

# -----------------------------
# Load dataset
# -----------------------------
df = pd.read_csv(DATA_PATH)

print("Dataset loaded successfully.")
print(f"Shape: {df.shape}")
print("\nColumns:")
print(df.columns.tolist())

# -----------------------------
# Features and target
# -----------------------------
feature_cols = [
    "temperature",
    "humidity",
    "pressure",
    "cloud_cover",
    "wind_speed",
    "dew_point"
]

# Prefer binary target if it already exists
if "cloudburst_tomorrow_binary" in df.columns:
    target_col = "cloudburst_tomorrow_binary"
    y = df[target_col]
else:
    target_col = "CloudBurstTomorrow"
    y = df[target_col].astype(str).str.strip().str.lower()

    # Convert common yes/no style values into 0/1
    mapping = {
        "yes": 1,
        "no": 0,
        "1": 1,
        "0": 0,
        "true": 1,
        "false": 0
    }
    y = y.map(mapping)

    if y.isna().any():
        raise ValueError(
            "Target column could not be converted properly. "
            "Please check CloudBurstTomorrow values."
        )

X = df[feature_cols].copy()

print("\nFeature sample:")
print(X.head())

print("\nTarget distribution:")
print(y.value_counts(dropna=False))

# -----------------------------
# Train / test split
# -----------------------------
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

print("\nTrain shape:", X_train.shape)
print("Test shape:", X_test.shape)

# -----------------------------
# Models
# -----------------------------
models = {
    "LogisticRegression": Pipeline([
        ("imputer", SimpleImputer(strategy="median")),
        ("scaler", StandardScaler()),
        ("model", LogisticRegression(max_iter=1000, random_state=42))
    ]),
    "SVM": Pipeline([
        ("imputer", SimpleImputer(strategy="median")),
        ("scaler", StandardScaler()),
        ("model", SVC(probability=True, random_state=42))
    ]),
    "DecisionTree": Pipeline([
        ("imputer", SimpleImputer(strategy="median")),
        ("model", DecisionTreeClassifier(random_state=42, max_depth=6))
    ])
}

results = []
best_model_name = None
best_model = None
best_f1 = -1

# -----------------------------
# Train and evaluate
# -----------------------------
for name, pipeline in models.items():
    print(f"\n{'='*50}")
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
        "f1_score": f1
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

# -----------------------------
# Save results
# -----------------------------
results_df = pd.DataFrame(results).sort_values(by="f1_score", ascending=False)
results_csv = RESULTS_DIR / "model_comparison_results.csv"
results_df.to_csv(results_csv, index=False)

print(f"\nSaved comparison results to: {results_csv}")

# Save best model
best_model_path = MODEL_DIR / "best_cloudburst_model.pkl"
joblib.dump(best_model, best_model_path)

print(f"Best model: {best_model_name}")
print(f"Best model saved to: {best_model_path}")

# Save feature list for reuse later
feature_file = RESULTS_DIR / "feature_columns.txt"
with open(feature_file, "w", encoding="utf-8") as f:
    for col in feature_cols:
        f.write(col + "\n")

print(f"Feature columns saved to: {feature_file}")
print("\nTraining complete.")