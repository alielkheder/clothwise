"""
Integrate Kaggle clothing dataset with the outfit recommendation system
This script will:
1. Process images from the Kaggle dataset
2. Generate embeddings using the CLIP model
3. Create FAISS indices
4. Update metadata
"""

import torch
import json
import os
import csv
from PIL import Image
from transformers import CLIPImageProcessor, CLIPVisionModel
from train_siamese_resnet50 import SiameseWithProjection
import faiss
import numpy as np
from pathlib import Path
from tqdm import tqdm

# Configuration
KAGGLE_DATASET_PATH = None  # Will be set after download
MODEL_PATH = "best_model.pt"
OUTPUT_FAISS_DIR = "faiss_indices_kaggle"
OUTPUT_METADATA = "product_metadata_kaggle.json"
BATCH_SIZE = 32

print("=" * 70)
print("KAGGLE DATASET INTEGRATION TOOL")
print("=" * 70)

def load_model():
    """Load the CLIP model for generating embeddings"""
    print("\n📥 Loading CLIP model...")

    clip = CLIPVisionModel.from_pretrained("openai/clip-vit-base-patch32")
    processor = CLIPImageProcessor.from_pretrained("openai/clip-vit-base-patch32")

    # Load trained model if available
    if os.path.exists(MODEL_PATH):
        print(f"✓ Loading trained model from {MODEL_PATH}")
        model = SiameseWithProjection(clip_model=clip)
        state_dict = torch.load(MODEL_PATH, map_location="cpu")
        model.load_state_dict(state_dict)
    else:
        print("⚠ Using base CLIP model (trained model not found)")
        model = SiameseWithProjection(clip_model=clip)

    device = "cuda" if torch.cuda.is_available() else "cpu"
    model.to(device).eval()
    print(f"✓ Model loaded on {device}")

    return model, processor, device

def process_kaggle_metadata(dataset_path):
    """
    Process the Kaggle dataset metadata
    Expected format: CSV with columns like image_path, category, description, etc.
    """
    print("\n📊 Processing Kaggle dataset metadata...")

    # Find CSV files
    csv_files = list(Path(dataset_path).rglob("*.csv"))

    if not csv_files:
        print("❌ No CSV metadata files found")
        return None

    print(f"✓ Found metadata file: {csv_files[0]}")

    metadata = {}
    products_by_category = {}

    # Read CSV
    with open(csv_files[0], 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)

        for row in reader:
            # Extract product information
            # Adjust field names based on actual CSV structure
            product_name = row.get('id', row.get('name', f"product_{len(metadata)}"))
            image_path = row.get('image', row.get('img', ''))
            category = row.get('category', row.get('articleType', 'Unknown'))

            # Build full image path
            full_image_path = Path(dataset_path) / image_path

            if not full_image_path.exists():
                continue

            metadata[product_name] = {
                'category': category,
                'image': str(full_image_path),
                'desc': row.get('description', row.get('productDisplayName', '')),
                'price': row.get('price', 'N/A'),
                'gender': row.get('gender', 'unisex')
            }

            # Group by category
            if category not in products_by_category:
                products_by_category[category] = []
            products_by_category[category].append(product_name)

    print(f"✓ Processed {len(metadata)} products")
    print(f"✓ Found {len(products_by_category)} categories")

    return metadata, products_by_category

def generate_embeddings_batch(image_paths, model, processor, device):
    """Generate embeddings for a batch of images"""
    embeddings = []

    for img_path in image_paths:
        try:
            image = Image.open(img_path).convert("RGB")
            inputs = processor(images=image, return_tensors="pt").to(device)

            with torch.no_grad():
                emb = model.clip(pixel_values=inputs['pixel_values']).last_hidden_state[:, 0, :]
                emb = model.projector(emb).squeeze(0).cpu().numpy().astype("float32")
                embeddings.append(emb)
        except Exception as e:
            print(f"⚠ Error processing {img_path}: {e}")
            # Add zero embedding as placeholder
            embeddings.append(np.zeros(512, dtype='float32'))

    return np.array(embeddings)

def create_faiss_indices(metadata, products_by_category, model, processor, device):
    """Create FAISS indices for each category"""
    print("\n🔍 Creating FAISS indices...")

    os.makedirs(OUTPUT_FAISS_DIR, exist_ok=True)

    for category, product_names in tqdm(products_by_category.items(), desc="Categories"):
        print(f"\n  Processing category: {category} ({len(product_names)} items)")

        # Get image paths
        image_paths = [metadata[name]['image'] for name in product_names]

        # Generate embeddings in batches
        all_embeddings = []
        for i in range(0, len(image_paths), BATCH_SIZE):
            batch_paths = image_paths[i:i+BATCH_SIZE]
            batch_embeddings = generate_embeddings_batch(batch_paths, model, processor, device)
            all_embeddings.append(batch_embeddings)

        embeddings = np.vstack(all_embeddings)

        # Create FAISS index
        dimension = embeddings.shape[1]
        index = faiss.IndexFlatL2(dimension)
        index.add(embeddings)

        # Save index
        safe_category = category.replace('/', '_').replace('\\', '_')
        index_path = os.path.join(OUTPUT_FAISS_DIR, f"{safe_category}.index")
        faiss.write_index(index, index_path)

        # Save product IDs
        ids_path = os.path.join(OUTPUT_FAISS_DIR, f"{safe_category}_ids.json")
        with open(ids_path, 'w') as f:
            json.dump(product_names, f)

        print(f"  ✓ Created index with {len(product_names)} vectors")

def main(dataset_path):
    """Main integration workflow"""

    # Step 1: Load model
    model, processor, device = load_model()

    # Step 2: Process metadata
    metadata, products_by_category = process_kaggle_metadata(dataset_path)

    if not metadata:
        print("\n❌ Failed to process dataset")
        return

    # Step 3: Generate embeddings and create FAISS indices
    create_faiss_indices(metadata, products_by_category, model, processor, device)

    # Step 4: Save metadata
    print(f"\n💾 Saving metadata to {OUTPUT_METADATA}...")
    with open(OUTPUT_METADATA, 'w') as f:
        json.dump(metadata, f, indent=2)

    print("\n" + "=" * 70)
    print("✅ INTEGRATION COMPLETE!")
    print("=" * 70)
    print(f"\nGenerated files:")
    print(f"  - FAISS indices: {OUTPUT_FAISS_DIR}/")
    print(f"  - Metadata: {OUTPUT_METADATA}")
    print(f"\nTotal products: {len(metadata)}")
    print(f"Total categories: {len(products_by_category)}")
    print("\nTo use the new dataset:")
    print("1. Update app.py to point to new FAISS_DIR and METADATA_PATH")
    print("2. Restart the Streamlit app")

if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        dataset_path = sys.argv[1]
    else:
        print("\nUsage: python integrate_kaggle_dataset.py <path_to_kaggle_dataset>")
        print("\nExample: python integrate_kaggle_dataset.py ~/.cache/kagglehub/datasets/...")
        sys.exit(1)

    if not os.path.exists(dataset_path):
        print(f"❌ Dataset path not found: {dataset_path}")
        sys.exit(1)

    main(dataset_path)
