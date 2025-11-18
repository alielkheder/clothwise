"""
Script to scale up the outfit recommendation database for testing
This will duplicate products and FAISS indices with variations
"""

import json
import faiss
import numpy as np
import os
from shutil import copy2

# Configuration
SCALE_FACTOR = 5  # Multiply database size by this factor
FAISS_DIR = "faiss_indices"
METADATA_PATH = "product_metadata.json"
BACKUP_SUFFIX = "_backup"

def backup_files():
    """Backup original files before scaling"""
    print("Creating backups...")

    # Backup metadata
    if os.path.exists(METADATA_PATH):
        copy2(METADATA_PATH, METADATA_PATH + BACKUP_SUFFIX)
        print(f"✓ Backed up {METADATA_PATH}")

    # Backup FAISS indices
    for file in os.listdir(FAISS_DIR):
        if file.endswith(".index") or file.endswith("_ids.json"):
            src = os.path.join(FAISS_DIR, file)
            dst = os.path.join(FAISS_DIR, file + BACKUP_SUFFIX)
            copy2(src, dst)
    print(f"✓ Backed up FAISS indices")

def scale_metadata(scale_factor):
    """Scale up product metadata"""
    print(f"\n📊 Scaling metadata by factor of {scale_factor}...")

    with open(METADATA_PATH, 'r') as f:
        original_metadata = json.load(f)

    original_count = len(original_metadata)
    print(f"Original product count: {original_count}")

    scaled_metadata = {}

    # Keep originals
    scaled_metadata.update(original_metadata)

    # Add duplicates with modified names
    for i in range(1, scale_factor):
        for product_name, product_info in original_metadata.items():
            new_name = f"{product_name} - Variant {i}"
            new_info = product_info.copy()
            # Slightly vary price for realism
            if 'price' in new_info and new_info['price'].startswith('$'):
                try:
                    price = float(new_info['price'].replace('$', ''))
                    # Add random variation (+/- 10%)
                    variation = np.random.uniform(-0.1, 0.1)
                    new_price = price * (1 + variation)
                    new_info['price'] = f"${new_price:.2f}"
                except:
                    pass

            scaled_metadata[new_name] = new_info

    # Save scaled metadata
    with open(METADATA_PATH, 'w') as f:
        json.dump(scaled_metadata, f, indent=2)

    new_count = len(scaled_metadata)
    print(f"✓ Scaled metadata: {original_count} → {new_count} products")

    return scaled_metadata

def scale_faiss_indices(scale_factor):
    """Scale up FAISS indices"""
    print(f"\n🔍 Scaling FAISS indices by factor of {scale_factor}...")

    for file in os.listdir(FAISS_DIR):
        if file.endswith(".index") and not file.endswith(BACKUP_SUFFIX):
            category = file.replace(".index", "")
            index_path = os.path.join(FAISS_DIR, file)
            ids_path = os.path.join(FAISS_DIR, f"{category}_ids.json")

            print(f"\n  Processing category: {category}")

            # Load original index
            index = faiss.read_index(index_path)
            original_vectors = index.reconstruct_n(0, index.ntotal)

            # Load original IDs
            with open(ids_path, 'r') as f:
                original_ids = json.load(f)

            original_count = len(original_ids)
            print(f"    Original vectors: {original_count}")

            # Scale up
            scaled_vectors = [original_vectors]
            scaled_ids = original_ids.copy()

            for i in range(1, scale_factor):
                # Add slight noise to duplicated vectors for variety
                noise = np.random.normal(0, 0.01, original_vectors.shape)
                noisy_vectors = original_vectors + noise
                scaled_vectors.append(noisy_vectors)

                # Add variant IDs
                variant_ids = [f"{pid} - Variant {i}" for pid in original_ids]
                scaled_ids.extend(variant_ids)

            # Combine all vectors
            all_vectors = np.vstack(scaled_vectors).astype('float32')

            # Create new index
            dimension = all_vectors.shape[1]
            new_index = faiss.IndexFlatL2(dimension)
            new_index.add(all_vectors)

            # Save scaled index
            faiss.write_index(new_index, index_path)

            # Save scaled IDs
            with open(ids_path, 'w') as f:
                json.dump(scaled_ids, f)

            new_count = len(scaled_ids)
            print(f"    ✓ Scaled: {original_count} → {new_count} vectors")

def verify_scaling():
    """Verify that scaling was successful"""
    print("\n🔍 Verifying scaled database...")

    # Check metadata
    with open(METADATA_PATH, 'r') as f:
        metadata = json.load(f)
    print(f"✓ Metadata products: {len(metadata)}")

    # Check FAISS indices
    total_vectors = 0
    for file in os.listdir(FAISS_DIR):
        if file.endswith(".index") and not file.endswith(BACKUP_SUFFIX):
            category = file.replace(".index", "")
            index_path = os.path.join(FAISS_DIR, file)
            ids_path = os.path.join(FAISS_DIR, f"{category}_ids.json")

            index = faiss.read_index(index_path)
            with open(ids_path, 'r') as f:
                ids = json.load(f)

            total_vectors += len(ids)
            print(f"  {category}: {len(ids)} vectors")

    print(f"✓ Total FAISS vectors: {total_vectors}")
    print("\n✅ Database scaling complete!")

def restore_backup():
    """Restore from backup if needed"""
    print("\n♻️  Restoring from backup...")

    # Restore metadata
    backup_path = METADATA_PATH + BACKUP_SUFFIX
    if os.path.exists(backup_path):
        copy2(backup_path, METADATA_PATH)
        os.remove(backup_path)
        print(f"✓ Restored {METADATA_PATH}")

    # Restore FAISS indices
    for file in os.listdir(FAISS_DIR):
        if file.endswith(BACKUP_SUFFIX):
            src = os.path.join(FAISS_DIR, file)
            dst = os.path.join(FAISS_DIR, file.replace(BACKUP_SUFFIX, ""))
            copy2(src, dst)
            os.remove(src)

    print("✓ Restored FAISS indices")
    print("✅ Backup restored successfully!")

if __name__ == "__main__":
    import sys

    print("=" * 60)
    print("DATABASE SCALING TOOL")
    print("=" * 60)

    if len(sys.argv) > 1 and sys.argv[1] == "--restore":
        restore_backup()
    else:
        print(f"\nThis will scale the database by {SCALE_FACTOR}x")
        print("Original files will be backed up with '_backup' suffix")
        print("\nTo restore original data, run: python scale_database.py --restore")

        response = input("\nProceed with scaling? (yes/no): ").lower().strip()

        if response == 'yes':
            try:
                backup_files()
                scaled_metadata = scale_metadata(SCALE_FACTOR)
                scale_faiss_indices(SCALE_FACTOR)
                verify_scaling()

                print("\n" + "=" * 60)
                print("🎉 SUCCESS! Database has been scaled up")
                print("=" * 60)
                print(f"\nYou can now restart your Streamlit app to test with the larger database.")
                print(f"To restore original data: python scale_database.py --restore")

            except Exception as e:
                print(f"\n❌ Error during scaling: {e}")
                print("You can restore the backup by running: python scale_database.py --restore")
        else:
            print("Scaling cancelled.")
