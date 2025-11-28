"""
Flask API Server for Outfit Recommendation System
Provides REST API endpoints for the Flutter app to access AI recommendations
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import torch
import json
import base64
import io
from PIL import Image
from transformers import CLIPImageProcessor, CLIPVisionModel
from train_siamese_resnet50 import SiameseWithProjection
from clothing_classifier import ClothingStyleClassifier
import faiss
import numpy as np
import os
import zipfile

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Configuration
MODEL_PATH = "best_model.pt"
FAISS_DIR = "faiss_indices"
METADATA_PATH = "product_metadata.json"
ZIP_PATH = "all_product_images.zip"

# Global variables for model and data
model = None
processor = None
device = None
metadata = None
faiss_indices = {}
id_maps = {}
style_classifier = None


def load_model():
    """Load the CLIP model and processor"""
    global model, processor, device

    print("Loading CLIP model...")
    clip = CLIPVisionModel.from_pretrained("openai/clip-vit-base-patch32", use_safetensors=True)
    processor = CLIPImageProcessor.from_pretrained("openai/clip-vit-base-patch32")

    # Load trained model
    model = SiameseWithProjection(clip_model=clip)
    state_dict = torch.load(MODEL_PATH, map_location="cpu")
    model.load_state_dict(state_dict)

    device = "cuda" if torch.cuda.is_available() else "cpu"
    model.to(device).eval()

    print(f"Model loaded successfully on {device}")


def load_metadata():
    """Load product metadata"""
    global metadata

    with open(METADATA_PATH, 'r') as f:
        metadata = json.load(f)

    print(f"Loaded {len(metadata)} products from metadata")


def load_faiss_indices():
    """Load all FAISS indices"""
    global faiss_indices, id_maps

    for file in os.listdir(FAISS_DIR):
        if file.endswith(".index"):
            category = file.replace(".index", "")
            index_path = os.path.join(FAISS_DIR, file)
            ids_path = os.path.join(FAISS_DIR, f"{category}_ids.json")

            # Load index
            faiss_indices[category] = faiss.read_index(index_path)

            # Load ID mapping
            with open(ids_path, 'r') as f:
                id_maps[category] = json.load(f)

    print(f"Loaded {len(faiss_indices)} FAISS indices")


def get_recommendations_from_image(image, num_recommendations=15):
    """Generate recommendations for an uploaded image"""
    # Process image
    inputs = processor(images=image, return_tensors="pt").to(device)

    # Generate embedding
    with torch.no_grad():
        user_emb = model.clip(pixel_values=inputs['pixel_values']).last_hidden_state[:, 0, :]
        user_emb = model.projector(user_emb).squeeze(0).cpu().numpy().astype("float32")

    # Search in each category
    recommendations = {}
    for category, index in faiss_indices.items():
        id_map = id_maps[category]
        k = min(num_recommendations, len(id_map))

        D, I = index.search(user_emb[None], k=k)
        top_indices = [int(i) for i in I[0]]

        recommendations[category] = [id_map[idx] for idx in top_indices]

    return recommendations


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'metadata_loaded': metadata is not None,
        'categories': len(faiss_indices)
    })


@app.route('/categories', methods=['GET'])
def get_categories():
    """Get list of available categories"""
    categories = sorted(list(faiss_indices.keys()))
    return jsonify({
        'categories': categories,
        'count': len(categories)
    })


@app.route('/recommend', methods=['POST'])
def recommend():
    """
    Generate outfit recommendations from uploaded image

    Request body (JSON):
    {
        "image": "base64_encoded_image_data",
        "categories": ["Pants", "Shirts"],  // optional, filter by categories
        "num_items": 15  // optional, default 15
    }

    Response:
    {
        "success": true,
        "recommendations": {
            "Pants": [
                {
                    "name": "RELAXED JEANS",
                    "category": "Jeans",
                    "price": "$40.50",
                    "description": "...",
                    "image_id": "data/1234.jpg"
                },
                ...
            ],
            ...
        }
    }
    """
    try:
        data = request.get_json()

        if 'image' not in data:
            return jsonify({'success': False, 'error': 'No image provided'}), 400

        # Decode base64 image
        image_data = base64.b64decode(data['image'])
        image = Image.open(io.BytesIO(image_data)).convert("RGB")

        # Get recommendations
        num_items = data.get('num_items', 15)
        all_recommendations = get_recommendations_from_image(image, num_items)

        # Filter by requested categories if specified
        requested_categories = data.get('categories')
        if requested_categories:
            all_recommendations = {
                cat: items for cat, items in all_recommendations.items()
                if cat in requested_categories
            }

        # Build response with product details
        response_data = {}
        for category, product_names in all_recommendations.items():
            response_data[category] = []
            for product_name in product_names:
                if product_name in metadata:
                    product_info = metadata[product_name]
                    response_data[category].append({
                        'name': product_name,
                        'category': product_info.get('category', category),
                        'price': product_info.get('price', 'N/A'),
                        'description': product_info.get('desc', ''),
                        'image_id': product_info.get('image', ''),
                        'gender': product_info.get('gender', 'unisex'),
                        'url': product_info.get('href', ''),
                        'style_type': product_info.get('style_type', 'casual')
                    })

        return jsonify({
            'success': True,
            'recommendations': response_data,
            'total_categories': len(response_data)
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/image/<path:image_id>', methods=['GET'])
def get_product_image(image_id):
    """
    Get product image from the ZIP archive

    Example: GET /image/data/1234.jpg
    """
    try:
        with zipfile.ZipFile(ZIP_PATH, 'r') as archive:
            image_data = archive.read(image_id)

            # Return image
            return send_file(
                io.BytesIO(image_data),
                mimetype='image/jpeg',
                as_attachment=False
            )

    except KeyError:
        return jsonify({'error': 'Image not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/product/<product_name>', methods=['GET'])
def get_product_details(product_name):
    """Get detailed information about a specific product"""
    if product_name not in metadata:
        return jsonify({'error': 'Product not found'}), 404

    product_info = metadata[product_name]
    return jsonify({
        'success': True,
        'product': {
            'name': product_name,
            'category': product_info.get('category', ''),
            'price': product_info.get('price', 'N/A'),
            'description': product_info.get('desc', ''),
            'image_id': product_info.get('image', ''),
            'gender': product_info.get('gender', 'unisex'),
            'url': product_info.get('href', ''),
            'style_type': product_info.get('style_type', 'casual')
        }
    })


@app.route('/products', methods=['GET'])
def get_all_products():
    """
    Get all products with optional category filtering

    Query parameters:
    - category: Filter by category (optional)
    - limit: Maximum number of products to return (default: 100)
    - offset: Number of products to skip (default: 0)
    """
    try:
        category_filter = request.args.get('category')
        limit = int(request.args.get('limit', 100))
        offset = int(request.args.get('offset', 0))

        products = []
        for product_name, product_info in metadata.items():
            # Apply category filter if specified
            if category_filter and product_info.get('category') != category_filter:
                continue

            products.append({
                'name': product_name,
                'category': product_info.get('category', ''),
                'price': product_info.get('price', 'N/A'),
                'description': product_info.get('desc', ''),
                'image_id': product_info.get('image', ''),
                'gender': product_info.get('gender', 'unisex'),
                'url': product_info.get('href', ''),
                'style_type': product_info.get('style_type', 'casual')
            })

        # Apply pagination
        total = len(products)
        products = products[offset:offset + limit]

        return jsonify({
            'success': True,
            'products': products,
            'total': total,
            'limit': limit,
            'offset': offset
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/shuffle', methods=['POST'])
def shuffle_recommendations():
    """
    Shuffle recommendations excluding already shown items

    Request body:
    {
        "category": "Pants",
        "all_items": ["ITEM1", "ITEM2", ...],  // all 15 items
        "shown_items": ["ITEM1", "ITEM2", "ITEM3"],  // already shown
        "num_to_show": 3
    }
    """
    try:
        data = request.get_json()

        category = data.get('category')
        all_items = data.get('all_items', [])
        shown_items = set(data.get('shown_items', []))
        num_to_show = data.get('num_to_show', 3)

        # Filter out shown items
        available_items = [item for item in all_items if item not in shown_items]

        # If we've shown everything, reset
        if len(available_items) < num_to_show:
            available_items = all_items
            shown_items.clear()

        # Randomly select items
        import random
        selected_items = random.sample(available_items, min(num_to_show, len(available_items)))

        # Get product details
        products = []
        for product_name in selected_items:
            if product_name in metadata:
                product_info = metadata[product_name]
                products.append({
                    'name': product_name,
                    'category': product_info.get('category', category),
                    'price': product_info.get('price', 'N/A'),
                    'description': product_info.get('desc', ''),
                    'image_id': product_info.get('image', ''),
                    'gender': product_info.get('gender', 'unisex'),
                    'url': product_info.get('href', '')
                })

        return jsonify({
            'success': True,
            'products': products,
            'shown_items': list(shown_items.union(set(selected_items)))
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/classify-upload', methods=['POST'])
def classify_user_upload():
    """
    Classify a user-uploaded clothing image into casual/formal/semi-formal

    Request body: {"image": "base64_encoded_image_string"}
    Response: {"success": true, "style_type": "casual", "display_name": "Casual", "confidence": 0.95}
    """
    try:
        data = request.get_json()

        if 'image' not in data:
            return jsonify({'success': False, 'error': 'No image provided'}), 400

        # Decode base64 image
        image_data = base64.b64decode(data['image'])

        # Classify the image
        style_type, confidence = style_classifier.classify_from_bytes(image_data)

        return jsonify({
            'success': True,
            'style_type': style_type,
            'display_name': style_classifier.get_display_name(style_type),
            'confidence': float(confidence)
        })

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/classification-stats', methods=['GET'])
def get_classification_stats():
    """
    Get statistics about product classifications

    Response: {"success": true, "total_products": 1982, "distribution": {...}, "percentages": {...}}
    """
    try:
        total = len(metadata)
        distribution = {'casual': 0, 'formal': 0, 'semi_formal': 0}

        for product_data in metadata.values():
            style_type = product_data.get('style_type', 'casual')

            # Map to display names
            if style_type == 'uniform':
                distribution['formal'] += 1
            elif style_type == 'semi_uniform':
                distribution['semi_formal'] += 1
            else:
                distribution['casual'] += 1

        # Calculate percentages
        percentages = {
            key: round((count / total * 100), 1) if total > 0 else 0
            for key, count in distribution.items()
        }

        return jsonify({
            'success': True,
            'total_products': total,
            'distribution': distribution,
            'percentages': percentages
        })

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


if __name__ == '__main__':
    print("=" * 70)
    print("OUTFIT RECOMMENDATION API SERVER")
    print("=" * 70)

    # Load model and data
    load_model()
    load_metadata()
    load_faiss_indices()

    # Load style classifier
    print("\nLoading clothing style classifier...")
    style_classifier = ClothingStyleClassifier()

    print("\n" + "=" * 70)
    print("Server is ready!")
    print("=" * 70)
    print("\nAPI Endpoints:")
    print("  - GET  /health                - Health check")
    print("  - GET  /categories            - List available categories")
    print("  - POST /recommend             - Get recommendations for image")
    print("  - GET  /image/<image_id>      - Get product image")
    print("  - GET  /product/<name>        - Get product details")
    print("  - POST /shuffle               - Shuffle recommendations")
    print("  - POST /classify-upload       - Classify clothing style (NEW)")
    print("  - GET  /classification-stats  - Get classification statistics (NEW)")
    print("\n" + "=" * 70)

    # Start server
    app.run(host='0.0.0.0', port=5000, debug=False)
