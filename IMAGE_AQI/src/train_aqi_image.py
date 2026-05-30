from pathlib import Path
import json
import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.utils.class_weight import compute_class_weight
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

# -----------------------------
# Paths
# -----------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "processed_6class"

TRAIN_DIR = DATA_DIR / "train"
VAL_DIR = DATA_DIR / "val"
TEST_DIR = DATA_DIR / "test"

MODEL_DIR = BASE_DIR / "models"
RESULTS_DIR = BASE_DIR / "results"

MODEL_DIR.mkdir(exist_ok=True)
RESULTS_DIR.mkdir(exist_ok=True)

MODEL_PATH = MODEL_DIR / "best_aqi_image_model.keras"
CLASS_NAMES_PATH = MODEL_DIR / "aqi_image_class_names.json"
REPORT_PATH = RESULTS_DIR / "aqi_image_classification_report.txt"
CONFUSION_MATRIX_PATH = RESULTS_DIR / "aqi_image_confusion_matrix.csv"
HISTORY_PATH = RESULTS_DIR / "aqi_image_training_history.csv"
CONFUSION_MATRIX_PLOT_PATH = RESULTS_DIR / "aqi_image_confusion_matrix.png"

# -----------------------------
# Config
# -----------------------------
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
SEED = 42
INITIAL_EPOCHS = 8
FINE_TUNE_EPOCHS = 5
FINE_TUNE_AT = 30
HEAD_LEARNING_RATE = 1e-3
FINE_TUNE_LEARNING_RATE = 1e-5

LABEL_MAP = {
    "a_Good": "Good",
    "b_Moderate": "Moderate",
    "c_Unhealthy_for_Sensitive_Groups": "Unhealthy for Sensitive Groups",
    "d_Unhealthy": "Unhealthy",
    "e_Very_Unhealthy": "Very Unhealthy",
    "f_Severe": "Severe",
}


def check_directories():
    for folder in [TRAIN_DIR, VAL_DIR, TEST_DIR]:
        if not folder.exists():
            raise FileNotFoundError(f"Missing folder: {folder}")


def load_datasets():
    train_ds = tf.keras.utils.image_dataset_from_directory(
        TRAIN_DIR,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="int",
        shuffle=True,
        seed=SEED,
    )

    val_ds = tf.keras.utils.image_dataset_from_directory(
        VAL_DIR,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="int",
        shuffle=False,
    )

    test_ds = tf.keras.utils.image_dataset_from_directory(
        TEST_DIR,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="int",
        shuffle=False,
    )

    class_names = train_ds.class_names
    return train_ds, val_ds, test_ds, class_names


def build_model(num_classes: int):
    data_augmentation = tf.keras.Sequential([
        tf.keras.layers.RandomFlip("horizontal"),
        tf.keras.layers.RandomRotation(0.05),
        tf.keras.layers.RandomTranslation(0.05, 0.05),
        tf.keras.layers.RandomZoom(0.12),
        tf.keras.layers.RandomContrast(0.15),
        tf.keras.layers.RandomBrightness(0.12),
    ])

    base_model = tf.keras.applications.MobileNetV2(
        input_shape=IMG_SIZE + (3,),
        include_top=False,
        weights="imagenet",
    )
    base_model.trainable = False

    inputs = tf.keras.Input(shape=IMG_SIZE + (3,))
    x = data_augmentation(inputs)
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    x = base_model(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    outputs = tf.keras.layers.Dense(
        num_classes,
        activation="softmax",
        kernel_regularizer=tf.keras.regularizers.l2(1e-4),
    )(x)

    model = tf.keras.Model(inputs, outputs)
    return model, base_model


def compute_training_class_weights(train_ds) -> dict[int, float]:
    labels = np.concatenate([y.numpy() for _, y in train_ds], axis=0)
    classes = np.unique(labels)
    weights = compute_class_weight(
        class_weight="balanced",
        classes=classes,
        y=labels,
    )
    return {
        int(cls): float(weight)
        for cls, weight in zip(classes, weights)
    }


def configure_fine_tuning(base_model: tf.keras.Model):
    base_model.trainable = True

    for layer in base_model.layers[:-FINE_TUNE_AT]:
        layer.trainable = False

    # BatchNorm statistics are unstable on small datasets; keep pretrained stats.
    for layer in base_model.layers:
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False


def plot_and_save_confusion_matrix(cm, labels):
    plt.figure(figsize=(10, 8))
    plt.imshow(cm, interpolation="nearest")
    plt.title("AQI Image Confusion Matrix")
    plt.colorbar()
    tick_marks = np.arange(len(labels))
    plt.xticks(tick_marks, labels, rotation=45, ha="right")
    plt.yticks(tick_marks, labels)
    plt.ylabel("True Label")
    plt.xlabel("Predicted Label")
    plt.tight_layout()
    plt.savefig(CONFUSION_MATRIX_PLOT_PATH, dpi=200, bbox_inches="tight")
    plt.close()


def calculate_ordinal_metrics(y_true: np.ndarray, y_pred: np.ndarray) -> dict[str, float]:
    distances = np.abs(y_true - y_pred)
    return {
        "mean_class_distance": float(np.mean(distances)),
        "within_1_class_accuracy": float(np.mean(distances <= 1)),
        "within_2_class_accuracy": float(np.mean(distances <= 2)),
        "severe_error_rate": float(np.mean(distances >= 3)),
    }


def format_ordinal_metrics(metrics: dict[str, float]) -> str:
    return (
        "Ordinal AQI Metrics:\n"
        f"Mean class distance: {metrics['mean_class_distance']:.4f}\n"
        f"Within 1 class accuracy: {metrics['within_1_class_accuracy']:.4f}\n"
        f"Within 2 classes accuracy: {metrics['within_2_class_accuracy']:.4f}\n"
        f"Severe error rate (>= 3 classes away): {metrics['severe_error_rate']:.4f}\n"
    )


def main():
    check_directories()

    train_ds, val_ds, test_ds, class_names = load_datasets()
    class_weights = compute_training_class_weights(train_ds)

    readable_class_names = [LABEL_MAP.get(name, name) for name in class_names]

    print("\nClass weights:")
    for index, name in enumerate(readable_class_names):
        print(f"  {name}: {class_weights.get(index, 1.0):.4f}")

    with open(CLASS_NAMES_PATH, "w", encoding="utf-8") as f:
        json.dump({
            "raw_class_names": class_names,
            "readable_class_names": readable_class_names,
        }, f, indent=2)

    autotune = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(buffer_size=autotune)
    val_ds = val_ds.prefetch(buffer_size=autotune)
    test_ds = test_ds.prefetch(buffer_size=autotune)

    model, base_model = build_model(num_classes=len(class_names))

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=HEAD_LEARNING_RATE),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    callbacks = [
        tf.keras.callbacks.ModelCheckpoint(
            filepath=str(MODEL_PATH),
            monitor="val_accuracy",
            save_best_only=True,
            verbose=1,
        ),
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            patience=3,
            restore_best_weights=True,
            verbose=1,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=2,
            verbose=1,
        ),
    ]

    print("\nStarting initial training...")
    history_initial = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=INITIAL_EPOCHS,
        callbacks=callbacks,
        class_weight=class_weights,
    )

    print("\nStarting fine-tuning...")
    configure_fine_tuning(base_model)

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=FINE_TUNE_LEARNING_RATE),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    history_finetune = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=INITIAL_EPOCHS + FINE_TUNE_EPOCHS,
        initial_epoch=len(history_initial.history["loss"]),
        callbacks=callbacks,
        class_weight=class_weights,
    )

    print("\nLoading best saved model...")
    best_model = tf.keras.models.load_model(MODEL_PATH)

    print("\nEvaluating on test set...")
    test_loss, test_accuracy = best_model.evaluate(test_ds, verbose=1)

    y_true = np.concatenate([y.numpy() for _, y in test_ds], axis=0)
    y_prob = best_model.predict(test_ds, verbose=1)
    y_pred = np.argmax(y_prob, axis=1)

    report = classification_report(
        y_true,
        y_pred,
        target_names=readable_class_names,
        digits=4,
        zero_division=0,
    )

    cm = confusion_matrix(y_true, y_pred)
    ordinal_metrics = calculate_ordinal_metrics(y_true, y_pred)
    ordinal_report = format_ordinal_metrics(ordinal_metrics)

    print(f"\nTest Accuracy: {test_accuracy:.4f}")
    print("\nClassification Report:")
    print(report)
    print(ordinal_report)
    print("Confusion Matrix:")
    print(cm)

    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        f.write(f"Test Accuracy: {test_accuracy:.4f}\n\n")
        f.write(report)
        f.write("\n")
        f.write(ordinal_report)
        f.write("\nConfusion Matrix:\n")
        f.write(np.array2string(cm))

    cm_df = pd.DataFrame(cm, index=readable_class_names, columns=readable_class_names)
    cm_df.to_csv(CONFUSION_MATRIX_PATH, index=True)

    plot_and_save_confusion_matrix(cm, readable_class_names)

    history_df = pd.DataFrame(history_initial.history)
    history_df["phase"] = "initial"

    history_ft_df = pd.DataFrame(history_finetune.history)
    history_ft_df["phase"] = "finetune"

    final_history_df = pd.concat([history_df, history_ft_df], ignore_index=True)
    final_history_df.to_csv(HISTORY_PATH, index=False)

    print(f"\nBest model saved to: {MODEL_PATH}")
    print(f"Class names saved to: {CLASS_NAMES_PATH}")
    print(f"Classification report saved to: {REPORT_PATH}")
    print(f"Confusion matrix CSV saved to: {CONFUSION_MATRIX_PATH}")
    print(f"Confusion matrix image saved to: {CONFUSION_MATRIX_PLOT_PATH}")
    print(f"Training history saved to: {HISTORY_PATH}")
    print("AQI image training complete.")


if __name__ == "__main__":
    main()
