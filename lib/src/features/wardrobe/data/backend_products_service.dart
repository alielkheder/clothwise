import 'package:dio/dio.dart';
import 'package:clothwise/src/features/home/domain/entities/clothing_item.dart';

/// Service to fetch products from AI backend
class BackendProductsService {
  final Dio _dio;
  final String baseUrl;

  BackendProductsService({
    Dio? dio,
    this.baseUrl = 'http://192.168.1.5:5000', // Local network IP for phone/emulator
  }) : _dio = dio ?? Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Get all products from backend
  Future<List<ClothingItem>> getAllProducts({
    String? category,
    int limit = 30,  // Reduced from 100 to 30 for faster initial loading
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/products',
        queryParameters: {
          if (category != null) 'category': category,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> products = response.data['products'];
        return products.map((product) => _convertToClothingItem(product)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  /// Get categories from backend
  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get('$baseUrl/categories');
      final List<dynamic> categories = response.data['categories'];
      return categories.cast<String>();
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /// Get product image URL
  String getImageUrl(String imageId) {
    return '$baseUrl/image/$imageId';
  }

  /// Convert backend product to ClothingItem
  ClothingItem _convertToClothingItem(Map<String, dynamic> product) {
    return ClothingItem(
      id: product['name'], // Use product name as ID
      name: product['name'],
      category: _mapCategory(product['category']),
      color: _extractColor(product['description'] ?? ''),
      usage: ClothingUsage.casual, // Default to casual
      imageUrl: getImageUrl(product['image_id']),
    );
  }

  /// Map backend category to app category
  ClothingCategory _mapCategory(String backendCategory) {
    final lower = backendCategory.toLowerCase();

    if (lower.contains('shirt') || lower.contains('top') || lower.contains('t-shirt') ||
        lower.contains('blouse') || lower.contains('polo') || lower.contains('sweater') ||
        lower.contains('hoodie') || lower.contains('cardigan') || lower.contains('blazer') ||
        lower.contains('jacket') || lower.contains('coat') || lower.contains('vest')) {
      return ClothingCategory.topwear;
    }

    if (lower.contains('pant') || lower.contains('jean') || lower.contains('short') ||
        lower.contains('trouser')) {
      return ClothingCategory.bottomwear;
    }

    if (lower.contains('dress') || lower.contains('skirt') || lower.contains('jumpsuit')) {
      return ClothingCategory.onePiece;
    }

    if (lower.contains('shoe') || lower.contains('boot') || lower.contains('sandal') ||
        lower.contains('sneaker')) {
      return ClothingCategory.footwear;
    }

    return ClothingCategory.topwear; // Default
  }

  /// Extract color from description (basic implementation)
  String _extractColor(String description) {
    final colors = [
      'black', 'white', 'red', 'blue', 'green', 'yellow',
      'orange', 'purple', 'pink', 'brown', 'grey', 'gray',
      'navy', 'beige', 'khaki', 'maroon', 'burgundy'
    ];

    final lowerDesc = description.toLowerCase();
    for (final color in colors) {
      if (lowerDesc.contains(color)) {
        return color[0].toUpperCase() + color.substring(1);
      }
    }

    return 'Multi-color';
  }
}
