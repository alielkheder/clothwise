"""
Script to classify products into casual, uniform, and semi_uniform categories
"""

import json

# Classification rules based on category and product name
def classify_product(name, category, desc):
    """
    Classify a product as casual, uniform, or semi_uniform

    - casual: Everyday wear, relaxed clothing
    - uniform: Formal business attire, suits, formal dresses
    - semi_uniform: Smart casual, business casual, polo shirts
    """

    name_lower = name.lower()
    category_lower = category.lower()
    desc_lower = desc.lower() if desc else ""

    # Uniform (Formal) keywords
    uniform_keywords = [
        'suit', 'blazer', 'dress shirt', 'formal', 'business', 'tie',
        'dress pants', 'dress shoes', 'tuxedo', 'evening dress',
        'formal dress', 'oxford', 'loafer', 'cocktail dress'
    ]

    # Semi-uniform (Smart Casual / Business Casual) keywords
    semi_uniform_keywords = [
        'polo', 'chino', 'khaki', 'button-down', 'blouse', 'cardigan',
        'dress casual', 'smart', 'vest', 'trench', 'peacoat',
        'ankle boot', 'derby', 'professional'
    ]

    # Casual keywords
    casual_keywords = [
        't-shirt', 'tee', 'jeans', 'shorts', 'hoodie', 'sweatshirt',
        'sweatpants', 'sneaker', 'sandal', 'flip-flop', 'tank top',
        'athletic', 'sporty', 'jogger', 'legging', 'crop top',
        'casual', 'relaxed', 'oversized', 'boxy'
    ]

    combined_text = f"{name_lower} {category_lower} {desc_lower}"

    # Check for uniform (highest priority)
    if any(keyword in combined_text for keyword in uniform_keywords):
        # Special case: if it's explicitly casual despite having suit/blazer in name
        if 'casual' in combined_text and 'suit' not in category_lower:
            return 'semi_uniform'
        return 'uniform'

    # Check for semi-uniform
    if any(keyword in combined_text for keyword in semi_uniform_keywords):
        return 'semi_uniform'

    # Check for casual
    if any(keyword in combined_text for keyword in casual_keywords):
        return 'casual'

    # Category-based classification for items that don't match keywords
    if 'suits & blazers' in category_lower or 'dress' in category_lower:
        return 'uniform'
    elif 'cardigan' in category_lower or 'sweater' in category_lower:
        return 'semi_uniform'
    elif any(cat in category_lower for cat in ['t-shirt', 'short', 'hoodie', 'sweatshirt', 'jean']):
        return 'casual'

    # Default to casual for unclassified items
    return 'casual'


def main():
    # Load existing metadata
    with open('product_metadata.json', 'r') as f:
        metadata = json.load(f)

    # Classify each product
    classified_count = {'casual': 0, 'uniform': 0, 'semi_uniform': 0}

    for product_name, product_data in metadata.items():
        category = product_data.get('category', '')
        desc = product_data.get('desc', '')

        style_type = classify_product(product_name, category, desc)
        product_data['style_type'] = style_type
        classified_count[style_type] += 1

    # Save updated metadata
    with open('product_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=4)

    print(f"Successfully classified {len(metadata)} products:")
    print(f"   - Casual: {classified_count['casual']}")
    print(f"   - Uniform: {classified_count['uniform']}")
    print(f"   - Semi-uniform: {classified_count['semi_uniform']}")

    # Show some examples
    print("\nSample classifications:")
    count = 0
    for name, data in metadata.items():
        if count >= 10:
            break
        print(f"   {data['style_type']:12} - {name} ({data['category']})")
        count += 1


if __name__ == '__main__':
    main()
