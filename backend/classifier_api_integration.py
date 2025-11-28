"""
Integration code to add clothing style classification endpoints to api_server.py

Add these lines to the top of api_server.py imports:
from clothing_classifier import ClothingStyleClassifier

Add this to the global variables section:
style_classifier = None

Add this to the initialization section (after load_model, load_metadata, load_faiss_indices):
style_classifier = ClothingStyleClassifier()

Add these endpoints to api_server.py:
"""

# Endpoint 1: Classify a user-uploaded image
CLASSIFY_UPLOAD_ENDPOINT = '''
@app.route('/classify-upload', methods=['POST'])
def classify_user_upload():
    """
    Classify a user-uploaded clothing image into casual/formal/semi-formal

    Request body (JSON):
    {
        "image": "base64_encoded_image_string"
    }

    Response:
    {
        "success": true,
        "style_type": "casual",  // or "uniform" (formal), or "semi_uniform" (semi-formal)
        "display_name": "Casual",  // Human-readable name
        "confidence": 0.95  // Confidence score 0-1
    }
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
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
'''

# Endpoint 2: Reclassify all products using ML model
RECLASSIFY_PRODUCTS_ENDPOINT = '''
@app.route('/reclassify-products', methods=['POST'])
def reclassify_all_products():
    """
    Reclassify all products in the database using the ML model
    Only updates classifications with confidence > 0.6

    Request body (JSON): {} (empty)

    Response:
    {
        "success": true,
        "message": "Products reclassified",
        "results": {
            "casual": 1500,
            "uniform": 150,
            "semi_uniform": 332
        },
        "total_updated": 1982
    }
    """
    try:
        results = {'casual': 0, 'uniform': 0, 'semi_uniform': 0}
        total_updated = 0

        print("Starting product reclassification...")

        # Get all product image paths
        product_paths = []
        product_names = []

        for product_name, product_data in metadata.items():
            image_id = product_data.get('image', '')
            if image_id:
                product_paths.append(image_id)
                product_names.append(product_name)

        # Batch classify all products
        print(f"Classifying {len(product_paths)} products...")
        classifications = style_classifier.classify_batch(product_paths)

        # Update metadata with new classifications
        for i, (product_name, (style_type, confidence)) in enumerate(zip(product_names, classifications)):
            # Only update if confidence is high enough
            if confidence > 0.6:
                metadata[product_name]['style_type'] = style_type
                metadata[product_name]['classification_confidence'] = float(confidence)
                results[style_type] += 1
                total_updated += 1

            # Progress update every 100 products
            if (i + 1) % 100 == 0:
                print(f"Processed {i + 1}/{len(product_paths)} products...")

        # Save updated metadata
        with open(METADATA_PATH, 'w') as f:
            json.dump(metadata, f, indent=4)

        print("Reclassification complete!")

        return jsonify({
            'success': True,
            'message': f'Successfully reclassified {total_updated} products',
            'results': results,
            'total_updated': total_updated
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
'''

# Endpoint 3: Get classification statistics
CLASSIFICATION_STATS_ENDPOINT = '''
@app.route('/classification-stats', methods=['GET'])
def get_classification_stats():
    """
    Get statistics about product classifications

    Response:
    {
        "success": true,
        "total_products": 1982,
        "distribution": {
            "casual": 1500,
            "formal": 150,
            "semi_formal": 332
        },
        "percentages": {
            "casual": 75.7,
            "formal": 7.6,
            "semi_formal": 16.7
        }
    }
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
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
'''

print("=" * 60)
print("CLASSIFIER API INTEGRATION CODE")
print("=" * 60)
print("\n1. Add to imports at top of api_server.py:")
print("   from clothing_classifier import ClothingStyleClassifier")
print("\n2. Add to global variables section:")
print("   style_classifier = None")
print("\n3. Add to load_model() or create new init function:")
print("   style_classifier = ClothingStyleClassifier()")
print("\n4. Add these three endpoints:")
print("\nEndpoint 1: Classify User Upload")
print(CLASSIFY_UPLOAD_ENDPOINT)
print("\nEndpoint 2: Reclassify All Products")
print(RECLASSIFY_PRODUCTS_ENDPOINT)
print("\nEndpoint 3: Classification Statistics")
print(CLASSIFICATION_STATS_ENDPOINT)
