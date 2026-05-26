from pathlib import Path
import json

import numpy as np
import tensorflow as tf

BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_PATH = BASE_DIR / "models" / "best_aqi_image_model.keras"
CLASS_NAMES_PATH = BASE_DIR / "models" / "aqi_image_class_names.json"

IMG_SIZE = (224, 224)


def main() -> None:
    model = tf.keras.models.load_model(MODEL_PATH)
    class_data = json.loads(CLASS_NAMES_PATH.read_text())
    class_names = class_data["readable_class_names"]

    samples = [
        BASE_DIR / "processed_6class" / "test" / "a_Good" / "TN_Good_2023-03-21-08.30-2-97.jpg",
        BASE_DIR / "processed_6class" / "test" / "b_Moderate" / "TN_Mod_2023-02-28-08.30-1-96.jpg",
        BASE_DIR / "processed_6class" / "test" / "c_Unhealthy_for_Sensitive_Groups" / "UP_UHFSG_2023-03-06-11.30-4.jpg",
        BASE_DIR / "processed_6class" / "test" / "d_Unhealthy" / "UP_UN_2023-03-01-08.30-1.jpg",
        BASE_DIR / "processed_6class" / "test" / "e_Very_Unhealthy" / "UP_VU_2023-02-16-16.00-4.jpg",
        BASE_DIR / "processed_6class" / "test" / "f_Severe" / "UP_SEV_2023-02-20-08.30-1-47.jpg",
    ]

    for img_path in samples:
        img = tf.keras.utils.load_img(img_path, target_size=IMG_SIZE)
        x = tf.keras.utils.img_to_array(img)
        x = np.expand_dims(x, 0)
        preds = model.predict(x, verbose=0)[0]
        idx = int(np.argmax(preds))
        top3_idx = np.argsort(preds)[-3:][::-1]
        top3 = [(class_names[i], float(preds[i])) for i in top3_idx]

        print(f"Image: {img_path}")
        print(f"Pred: {class_names[idx]} (confidence: {float(preds[idx]):.4f})")
        print(f"Top3: {top3}")
        print("---")


if __name__ == "__main__":
    main()
