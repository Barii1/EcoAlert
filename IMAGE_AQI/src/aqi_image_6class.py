from pathlib import Path
import random
import shutil
import os


# -----------------------------
# Config
# -----------------------------
SOURCE_DIR = Path(r"C:\Users\bilal\Desktop\Cloudburst_project\IMAGE_AQI\Data")
OUTPUT_DIR = Path(r"C:\Users\bilal\Desktop\Cloudburst_project\IMAGE_AQI\processed_6class")

SEED = 42
TRAIN_RATIO = 0.70
VAL_RATIO = 0.15
TEST_RATIO = 0.15

CLASS_NAMES = [
    "a_Good",
    "b_Moderate",
    "c_Unhealthy_for_Sensitive_Groups",
    "d_Unhealthy",
    "e_Very_Unhealthy",
    "f_Severe",
]

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}

random.seed(SEED)


def find_class_folders(base_dir: Path):
    found = {}

    for cls in CLASS_NAMES:
        matches = []
        for root, dirs, files in os.walk(base_dir):
            root_path = Path(root)
            if root_path.name == cls:
                matches.append(root_path)

        if not matches:
            raise FileNotFoundError(f"Could not find class folder '{cls}' inside {base_dir}")

        # take first match if multiple found
        found[cls] = matches[0]

    return found


def list_images(folder: Path):
    return sorted(
        [p for p in folder.iterdir() if p.is_file() and p.suffix.lower() in IMAGE_EXTENSIONS]
    )


def split_files(files):
    files = files.copy()
    random.shuffle(files)

    n = len(files)
    train_end = int(n * TRAIN_RATIO)
    val_end = train_end + int(n * VAL_RATIO)

    train_files = files[:train_end]
    val_files = files[train_end:val_end]
    test_files = files[val_end:]

    return train_files, val_files, test_files


def copy_files(files, target_dir: Path):
    target_dir.mkdir(parents=True, exist_ok=True)
    for f in files:
        shutil.copy2(f, target_dir / f.name)


def main():
    print("Source directory:", SOURCE_DIR)

    if not SOURCE_DIR.exists():
        raise FileNotFoundError(f"Source directory does not exist: {SOURCE_DIR}")

    class_folders = find_class_folders(SOURCE_DIR)

    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)

    # create output structure
    for split in ["train", "val", "test"]:
        for cls in CLASS_NAMES:
            (OUTPUT_DIR / split / cls).mkdir(parents=True, exist_ok=True)

    summary = []

    for cls, class_dir in class_folders.items():
        images = list_images(class_dir)

        if not images:
            raise ValueError(f"No images found in: {class_dir}")

        train_files, val_files, test_files = split_files(images)

        copy_files(train_files, OUTPUT_DIR / "train" / cls)
        copy_files(val_files, OUTPUT_DIR / "val" / cls)
        copy_files(test_files, OUTPUT_DIR / "test" / cls)

        summary.append(
            {
                "class": cls,
                "source_folder": str(class_dir),
                "total": len(images),
                "train": len(train_files),
                "val": len(val_files),
                "test": len(test_files),
            }
        )

    print("\nSplit completed successfully.")
    print("Output directory:", OUTPUT_DIR)
    print("\nClass-wise summary:")
    for row in summary:
        print(row)


if __name__ == "__main__":
    main()
from pathlib import Path
import shutil
import random
import os

# -----------------------------
# Config
# -----------------------------
SOURCE_DIR = Path(r"C:\Users\bilal\Desktop\Cloudburst_project\IMAGE_AQI\Data")
OUTPUT_DIR = Path(r"C:\Users\bilal\Desktop\Cloudburst_project\IMAGE_AQI\processed_6class")

SEED = 42
TRAIN_RATIO = 0.70
VAL_RATIO = 0.15
TEST_RATIO = 0.15

CLASS_NAMES = [
    "a_Good",
    "b_Moderate",
    "c_Unhealthy_for_Sensitive_Groups",
    "d_Unhealthy",
    "e_Very_Unhealthy",
    "f_Severe",
]

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}

random.seed(SEED)


def find_class_folders(base_dir: Path):
    found = {}

    for cls in CLASS_NAMES:
        matches = []
        for root, dirs, files in os.walk(base_dir):
            root_path = Path(root)
            if root_path.name == cls:
                matches.append(root_path)

        if not matches:
            raise FileNotFoundError(f"Could not find class folder '{cls}' inside {base_dir}")

        # take first match if multiple found
        found[cls] = matches[0]

    return found


def list_images(folder: Path):
    return sorted([
        p for p in folder.iterdir()
        if p.is_file() and p.suffix.lower() in IMAGE_EXTENSIONS
    ])


def split_files(files):
    files = files.copy()
    random.shuffle(files)

    n = len(files)
    train_end = int(n * TRAIN_RATIO)
    val_end = train_end + int(n * VAL_RATIO)

    train_files = files[:train_end]
    val_files = files[train_end:val_end]
    test_files = files[val_end:]

    return train_files, val_files, test_files


def copy_files(files, target_dir: Path):
    target_dir.mkdir(parents=True, exist_ok=True)
    for f in files:
        shutil.copy2(f, target_dir / f.name)


def main():
    print("Source directory:", SOURCE_DIR)

    if not SOURCE_DIR.exists():
        raise FileNotFoundError(f"Source directory does not exist: {SOURCE_DIR}")

    class_folders = find_class_folders(SOURCE_DIR)

    # create output structure
    for split in ["train", "val", "test"]:
        for cls in CLASS_NAMES:
            (OUTPUT_DIR / split / cls).mkdir(parents=True, exist_ok=True)

    summary = []

    for cls, class_dir in class_folders.items():
        images = list_images(class_dir)

        if not images:
            raise ValueError(f"No images found in: {class_dir}")

        train_files, val_files, test_files = split_files(images)

        copy_files(train_files, OUTPUT_DIR / "train" / cls)
        copy_files(val_files, OUTPUT_DIR / "val" / cls)
        copy_files(test_files, OUTPUT_DIR / "test" / cls)

        summary.append({
            "class": cls,
            "source_folder": str(class_dir),
            "total": len(images),
            "train": len(train_files),
            "val": len(val_files),
            "test": len(test_files),
        })

    print("\nSplit completed successfully.")
    print("Output directory:", OUTPUT_DIR)
    print("\nClass-wise summary:")
    for row in summary:
        print(row)


if __name__ == "__main__":
    main()