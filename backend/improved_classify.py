"""
Improved Classification System for Clothing Items
Uses comprehensive rules based on product names, categories, and descriptions
to classify items into: casual, uniform (formal), and semi_uniform (semi-formal)
"""

import json
import re


def classify_clothing_item(name, category, description):
    """
    Classify clothing item based on comprehensive rules

    Returns: 'casual', 'uniform', or 'semi_uniform'
    """

    name_lower = name.lower()
    category_lower = category.lower()
    desc_lower = description.lower() if description else ""

    # Combine all text for analysis
    full_text = f"{name_lower} {category_lower} {desc_lower}"

    # ============================================
    # UNIFORM (FORMAL) CLASSIFICATION
    # ============================================

    # Explicit formal keywords
    formal_keywords = [
        'suit jacket', 'suit vest', 'blazer', 'tuxedo',
        'dress shirt', 'oxford shirt', 'formal shirt',
        'dress pants', 'suit pants', 'tailored pants',
        'evening dress', 'formal dress', 'cocktail dress', 'gown',
        'bow tie', 'necktie', 'cufflinks',
        'dress shoes', 'oxford shoes', 'loafers', 'heels',
        'tailored', 'business suit', 'three-piece'
    ]

    # Check for explicit formal keywords
    for keyword in formal_keywords:
        if keyword in full_text:
            return 'uniform'

    # Category-based formal classification
    formal_categories = [
        'suits & blazers',
        'blazers & vests'
    ]

    if any(cat in category_lower for cat in formal_categories):
        # Exception: casual blazer
        if 'casual' in full_text and 'denim' in full_text:
            return 'semi_uniform'
        return 'uniform'

    # Dresses - check formality
    if 'dress' in category_lower or ('dress' in name_lower and 'dressing' not in name_lower):
        formal_dress_indicators = [
            'evening', 'cocktail', 'formal', 'gown', 'party',
            'satin', 'silk', 'lace', 'sequin', 'velvet',
            'maxi', 'midi', 'a-line', 'sheath', 'bodycon'
        ]

        casual_dress_indicators = [
            'jersey', 't-shirt', 'tank', 'cami', 'smock',
            'sweat', 'hoodie', 'denim', 'oversized'
        ]

        if any(indicator in full_text for indicator in formal_dress_indicators):
            return 'uniform'
        elif any(indicator in full_text for indicator in casual_dress_indicators):
            return 'casual'
        else:
            # Default dresses to semi-formal
            return 'semi_uniform'

    # ============================================
    # SEMI-FORMAL (SEMI_UNIFORM) CLASSIFICATION
    # ============================================

    semi_formal_keywords = [
        'polo', 'polo shirt',
        'chino', 'khaki',
        'button-down', 'button-up', 'collared shirt',
        'blouse', 'dress blouse',
        'cardigan', 'sweater cardigan',
        'smart casual', 'business casual',
        'trench coat', 'peacoat', 'wool coat',
        'ankle boots', 'chelsea boots', 'loafers',
        'pencil skirt', 'midi skirt', 'a-line skirt'
    ]

    for keyword in semi_formal_keywords:
        if keyword in full_text:
            return 'semi_uniform'

    # Shirts and Blouses - detailed classification
    if 'shirt' in category_lower or 'blouse' in category_lower:
        # Casual shirts
        casual_shirt_indicators = [
            't-shirt', 'tee', 'tank', 'cami', 'crop',
            'oversized', 'relaxed', 'loose',
            'jersey', 'cotton jersey',
            'graphic', 'printed', 'slogan'
        ]

        # Semi-formal shirts
        semi_formal_shirt_indicators = [
            'button', 'collar', 'oxford', 'poplin',
            'blouse', 'tunic', 'peplum',
            'wrap', 'tie-front', 'bow'
        ]

        if any(indicator in full_text for indicator in casual_shirt_indicators):
            return 'casual'
        elif any(indicator in full_text for indicator in semi_formal_shirt_indicators):
            return 'semi_uniform'

    # Pants - detailed classification
    if 'pant' in category_lower or 'trouser' in category_lower:
        casual_pants_indicators = [
            'sweat', 'jogger', 'track', 'cargo',
            'legging', 'yoga', 'athletic',
            'denim', 'jean', 'ripped', 'distressed',
            'wide-leg jersey', 'pull-on', 'elastic'
        ]

        semi_formal_pants_indicators = [
            'chino', 'khaki', 'tailored', 'dress',
            'wide-leg', 'straight-leg', 'slim-fit',
            'high-waist', 'cigarette', 'ankle'
        ]

        if any(indicator in full_text for indicator in casual_pants_indicators):
            return 'casual'
        elif any(indicator in full_text for indicator in semi_formal_pants_indicators):
            return 'semi_uniform'

    # Sweaters and Cardigans
    if 'sweater' in category_lower or 'cardigan' in category_lower:
        casual_sweater_indicators = [
            'hoodie', 'sweatshirt', 'oversized',
            'knit pullover', 'chunky'
        ]

        if any(indicator in full_text for indicator in casual_sweater_indicators):
            return 'casual'
        else:
            # Most cardigans and sweaters are semi-formal
            return 'semi_uniform'

    # Jackets and Coats
    if 'jacket' in category_lower or 'coat' in category_lower:
        casual_jacket_indicators = [
            'hoodie', 'sweatshirt', 'denim jacket',
            'bomber', 'windbreaker', 'puffer',
            'fleece', 'track jacket'
        ]

        formal_jacket_indicators = [
            'blazer', 'suit', 'tuxedo',
            'wool coat', 'trench', 'peacoat',
            'overcoat', 'topcoat'
        ]

        if any(indicator in full_text for indicator in casual_jacket_indicators):
            return 'casual'
        elif any(indicator in full_text for indicator in formal_jacket_indicators):
            return 'semi_uniform'

    # Skirts
    if 'skirt' in category_lower:
        casual_skirt_indicators = [
            'denim', 'jean', 'mini', 'short',
            'jersey', 'skort', 'athletic'
        ]

        semi_formal_skirt_indicators = [
            'pencil', 'midi', 'maxi', 'a-line',
            'pleated', 'wrap', 'high-waist'
        ]

        if any(indicator in full_text for indicator in casual_skirt_indicators):
            return 'casual'
        elif any(indicator in full_text for indicator in semi_formal_skirt_indicators):
            return 'semi_uniform'

    # ============================================
    # CASUAL CLASSIFICATION
    # ============================================

    casual_keywords = [
        't-shirt', 'tee', 'tank top', 'cami',
        'jeans', 'denim',
        'shorts', 'short',
        'hoodie', 'sweatshirt', 'sweatpants',
        'sneakers', 'sandals', 'flip-flops',
        'athletic', 'sporty', 'activewear',
        'joggers', 'leggings',
        'crop top', 'tube top',
        'oversized', 'relaxed fit', 'loose fit',
        'jersey', 'cotton jersey'
    ]

    for keyword in casual_keywords:
        if keyword in full_text:
            return 'casual'

    # Category-based casual classification
    casual_categories = [
        't-shirt', 'tops & t-shirts',
        'jeans',
        'shorts',
        'hoodies & sweatshirts',
        'activewear', 'sportswear'
    ]

    if any(cat in category_lower for cat in casual_categories):
        return 'casual'

    # ============================================
    # DEFAULT CLASSIFICATION
    # ============================================

    # If we can't determine, default based on category
    if 'top' in category_lower or 'shirt' in category_lower:
        return 'casual'
    elif 'pant' in category_lower or 'bottom' in category_lower:
        return 'casual'

    # Final fallback
    return 'casual'


def main():
    """Classify all products and update metadata"""

    print("Loading product metadata...")
    with open('product_metadata.json', 'r', encoding='utf-8') as f:
        metadata = json.load(f)

    print(f"Classifying {len(metadata)} products...\n")

    # Classify each product
    classification_counts = {'casual': 0, 'uniform': 0, 'semi_uniform': 0}

    for product_name, product_data in metadata.items():
        category = product_data.get('category', '')
        description = product_data.get('desc', '')

        style_type = classify_clothing_item(product_name, category, description)
        product_data['style_type'] = style_type
        classification_counts[style_type] += 1

    # Save updated metadata
    print("Saving updated classifications...")
    with open('product_metadata.json', 'w', encoding='utf-8') as f:
        json.dump(metadata, f, indent=4)

    # Print results
    print("\n" + "="*60)
    print("CLASSIFICATION RESULTS")
    print("="*60)
    print(f"Total products: {len(metadata)}")
    print(f"\nBreakdown:")
    print(f"  Casual:      {classification_counts['casual']:4d} ({classification_counts['casual']/len(metadata)*100:.1f}%)")
    print(f"  Formal:      {classification_counts['uniform']:4d} ({classification_counts['uniform']/len(metadata)*100:.1f}%)")
    print(f"  Semi-formal: {classification_counts['semi_uniform']:4d} ({classification_counts['semi_uniform']/len(metadata)*100:.1f}%)")
    print("="*60)

    # Show sample classifications by type
    print("\nSample Classifications:\n")

    samples_by_type = {'casual': [], 'uniform': [], 'semi_uniform': []}
    for name, data in metadata.items():
        style = data['style_type']
        if len(samples_by_type[style]) < 5:
            samples_by_type[style].append((name, data['category']))

    print("CASUAL:")
    for name, cat in samples_by_type['casual']:
        print(f"  - {name} ({cat})")

    print("\nFORMAL:")
    for name, cat in samples_by_type['uniform']:
        print(f"  - {name} ({cat})")

    print("\nSEMI-FORMAL:")
    for name, cat in samples_by_type['semi_uniform']:
        print(f"  - {name} ({cat})")

    print("\n" + "="*60)
    print("Classification complete!")
    print("="*60)


if __name__ == '__main__':
    main()
