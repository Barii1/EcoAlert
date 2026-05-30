import os
import kagglehub

path = kagglehub.dataset_download("adarshrouniyar/air-pollution-image-dataset-from-india-and-nepal")
print("Path to dataset files:", path)

print("\nTop-level contents:")
for item in os.listdir(path):
    print(item)
    
for root, dirs, files in os.walk(path):
    print("ROOT:", root)
    print("DIRS:", dirs[:10])
    print("FILES:", files[:10])
    print("-" * 50)
    if root != path:
        break