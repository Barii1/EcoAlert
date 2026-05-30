import io
import json
import os
from pathlib import Path
from typing import Any

import numpy as np
import tensorflow as tf
from PIL import Image

IMG_SIZE = (224, 224)

_MODEL = None
_CLASS_NAMES = None


def _resolve_path(env_var: str, default_path: Path) -> Path:
    value = os.getenv(env_var)
    if value:
        return Path(value)
    return default_path


def _get_default_paths() -> tuple[Path, Path]:
    base_dir = Path(__file__).resolve().parents[3]
    model_path = base_dir / "IMAGE_AQI" / "models" / "best_aqi_image_model.keras"
    class_names_path = base_dir / "IMAGE_AQI" / "models" / "aqi_image_class_names.json"
    return model_path, class_names_path


def _load_assets() -> tuple[tf.keras.Model, list[str]]:
    global _MODEL
    global _CLASS_NAMES

    if _MODEL is None or _CLASS_NAMES is None:
        default_model_path, default_class_names_path = _get_default_paths()
        model_path = _resolve_path("AQI_IMAGE_MODEL_PATH", default_model_path)
        class_names_path = _resolve_path(
            "AQI_IMAGE_CLASS_NAMES_PATH",
            default_class_names_path,
        )

        if _MODEL is None:
            _MODEL = tf.keras.models.load_model(model_path)

        if _CLASS_NAMES is None:
            data = json.loads(class_names_path.read_text())
            if isinstance(data, dict):
                class_names = data.get("readable_class_names") or data.get(
                    "raw_class_names"
                )
            else:
                class_names = data
            if not class_names:
                raise ValueError("Class names not found in metadata")
            _CLASS_NAMES = list(class_names)

    return _MODEL, _CLASS_NAMES


def get_model_status() -> dict[str, Any]:
    default_model_path, default_class_names_path = _get_default_paths()
    model_path = _resolve_path("AQI_IMAGE_MODEL_PATH", default_model_path)
    class_names_path = _resolve_path(
        "AQI_IMAGE_CLASS_NAMES_PATH",
        default_class_names_path,
    )

    status = {
        "model_loaded": _MODEL is not None,
        "class_names_loaded": _CLASS_NAMES is not None,
        "model_path": str(model_path),
        "model_exists": model_path.exists(),
        "class_names_path": str(class_names_path),
        "class_names_exists": class_names_path.exists(),
        "image_size": list(IMG_SIZE),
    }

    try:
        model, class_names = _load_assets()
        status.update({
            "model_loaded": True,
            "class_names_loaded": True,
            "num_classes": len(class_names),
            "class_names": class_names,
            "input_shape": list(model.input_shape),
            "output_shape": list(model.output_shape),
        })
    except Exception as exc:
        status.update({
            "model_loaded": False,
            "error": str(exc),
        })

    return status


def predict_image_bytes(image_bytes: bytes, top_k: int = 3) -> dict[str, Any]:
    model, class_names = _load_assets()

    image = Image.open(io.BytesIO(image_bytes))
    if image.mode != "RGB":
        image = image.convert("RGB")
    image = image.resize(IMG_SIZE)

    # Keep raw 0-255 range; model graph applies MobileNetV2 preprocessing.
    x = np.asarray(image, dtype=np.float32)
    x = np.expand_dims(x, axis=0)

    preds = model.predict(x, verbose=0)[0]
    idx = int(np.argmax(preds))

    top_indices = np.argsort(preds)[-top_k:][::-1]
    top_scores = [
        {"label": class_names[i], "confidence": float(preds[i])}
        for i in top_indices
    ]
    probabilities = {
        class_names[i]: float(preds[i])
        for i in range(len(class_names))
    }

    return {
        "predicted_label": class_names[idx],
        "confidence": float(preds[idx]),
        "top_k": top_scores,
        "probabilities": probabilities,
    }
