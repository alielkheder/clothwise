"""
Download large model files from external storage
This script downloads best_model.pt and all_product_images.zip from cloud storage
"""

import os
import requests
from tqdm import tqdm


def download_file(url, destination, description="Downloading"):
    """Download a file from URL with progress bar"""
    response = requests.get(url, stream=True)
    response.raise_for_status()

    total_size = int(response.headers.get('content-length', 0))
    block_size = 8192

    with open(destination, 'wb') as f:
        with tqdm(total=total_size, unit='B', unit_scale=True, desc=description) as pbar:
            for chunk in response.iter_content(block_size):
                f.write(chunk)
                pbar.update(len(chunk))

    print(f"✓ Downloaded {destination}")


def main():
    """Download all required model files"""

    # Get URLs from environment variables (set in Render dashboard)
    model_url = os.environ.get('MODEL_URL')
    images_url = os.environ.get('IMAGES_URL')

    if not model_url or not images_url:
        print("⚠️  MODEL_URL or IMAGES_URL not set. Skipping download.")
        print("Set these environment variables in Render dashboard with direct download links.")
        return

    # Download files
    if not os.path.exists('best_model.pt'):
        print("Downloading model file (334 MB)...")
        download_file(model_url, 'best_model.pt', 'Model')
    else:
        print("✓ Model file already exists")

    if not os.path.exists('all_product_images.zip'):
        print("Downloading product images (104 MB)...")
        download_file(images_url, 'all_product_images.zip', 'Images')
    else:
        print("✓ Images file already exists")

    print("\n✓ All files ready!")


if __name__ == '__main__':
    main()
