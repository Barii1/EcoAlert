import pandas as pd

from config import TEST_DATA_PATH, PREDICTIONS_CSV_PATH
from utils import load_model_and_metadata, standardize_columns, score_dataframe


def main():
    model, metadata = load_model_and_metadata()

    print("Model loaded successfully.")

    df = pd.read_csv(TEST_DATA_PATH, low_memory=False)
    df = standardize_columns(df)

    if "date" in df.columns:
        df["date"] = pd.to_datetime(df["date"], errors="coerce", dayfirst=True)

    print("Testing dataset loaded successfully.")
    print(f"Shape: {df.shape}")
    print("\nColumns:")
    print(df.columns.tolist())

    threshold = metadata.get("threshold", 0.50)
    scored_df = score_dataframe(df, model, threshold=threshold)

    scored_df.to_csv(PREDICTIONS_CSV_PATH, index=False)

    print(f"\nPredictions saved to: {PREDICTIONS_CSV_PATH}")

    print("\nPrediction summary:")
    print(scored_df["predicted_class"].value_counts(dropna=False))

    print("\nRisk level summary:")
    print(scored_df["risk_level"].value_counts(dropna=False))

    print("\nTop 10 highest-risk records:")
    top10 = scored_df.sort_values("cloudburst_probability", ascending=False).head(10)

    display_cols = [
        col for col in [
            "date",
            "city",
            "location",
            "temperature",
            "humidity",
            "pressure",
            "cloud_cover",
            "wind_speed",
            "dew_point",
            "cloudburst_probability",
            "predicted_class",
            "risk_level",
        ]
        if col in top10.columns
    ]

    print(top10[display_cols].to_string(index=False))
    print("\nCSV prediction run complete.")


if __name__ == "__main__":
    main()