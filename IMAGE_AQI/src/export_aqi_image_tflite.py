from pathlib import Path

import tensorflow as tf

BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_PATH = BASE_DIR / "models" / "best_aqi_image_model.keras"
OUTPUT_PATH = BASE_DIR / "models" / "aqi_image_model.tflite"


def main() -> None:
    model = tf.keras.models.load_model(MODEL_PATH)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    OUTPUT_PATH.write_bytes(tflite_model)
    print(f"TFLite model saved to: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
