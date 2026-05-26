import os

# path to dataset (adjust if needed)
path = r"C:\Users\bilal\.cache\kagglehub\datasets\adarshrouniyar\air-pollution-image-dataset-from-india-and-nepal\versions\10"

for root, dirs, files in os.walk(path):
    print("ROOT:", root)
    print("DIRS:", dirs[:10])
    print("FILES:", files[:10])
    print("-" * 50)
    if root != path:
        break