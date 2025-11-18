"""
Download and integrate Kaggle clothing dataset with the outfit recommendation system
"""

import kagglehub
import os
import shutil
from pathlib import Path

print("=" * 70)
print("KAGGLE CLOTHING DATASET DOWNLOADER")
print("=" * 70)

# Download latest version
print("\n📥 Downloading dataset from Kaggle...")
print("Dataset: agrigorev/clothing-dataset-full")
print("This may take a few minutes depending on your internet connection...\n")

try:
    path = kagglehub.dataset_download("agrigorev/clothing-dataset-full")

    print("\n✅ Download complete!")
    print(f"📁 Path to dataset files: {path}")

    # List the contents
    print("\n📂 Dataset contents:")
    for root, dirs, files in os.walk(path):
        level = root.replace(path, '').count(os.sep)
        indent = ' ' * 2 * level
        print(f'{indent}{os.path.basename(root)}/')
        subindent = ' ' * 2 * (level + 1)
        for file in files[:10]:  # Show first 10 files
            print(f'{subindent}{file}')
        if len(files) > 10:
            print(f'{subindent}... and {len(files) - 10} more files')

    # Check for CSV files with metadata
    print("\n🔍 Looking for metadata files...")
    csv_files = list(Path(path).rglob("*.csv"))
    json_files = list(Path(path).rglob("*.json"))

    if csv_files:
        print(f"✓ Found {len(csv_files)} CSV file(s):")
        for csv in csv_files:
            print(f"  - {csv}")

    if json_files:
        print(f"✓ Found {len(json_files)} JSON file(s):")
        for json_file in json_files:
            print(f"  - {json_file}")

    # Check for image directories
    image_dirs = [d for d in Path(path).rglob("*") if d.is_dir() and any(img in d.name.lower() for img in ['image', 'img', 'photo'])]
    if image_dirs:
        print(f"✓ Found {len(image_dirs)} image director(ies):")
        for img_dir in image_dirs:
            img_count = len(list(img_dir.glob("*.jpg"))) + len(list(img_dir.glob("*.png")))
            print(f"  - {img_dir} ({img_count} images)")

    print("\n" + "=" * 70)
    print("✅ Dataset ready for integration!")
    print("=" * 70)
    print(f"\nDataset location: {path}")
    print("\nNext steps:")
    print("1. Review the dataset structure above")
    print("2. Run the integration script to process and add to your database")

except Exception as e:
    print(f"\n❌ Error downloading dataset: {e}")
    print("\nTroubleshooting:")
    print("- Make sure you have a Kaggle account")
    print("- Set up Kaggle API credentials (kaggle.json)")
    print("- Check your internet connection")
