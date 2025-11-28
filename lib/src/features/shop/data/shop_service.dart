import 'package:dio/dio.dart';
import 'package:clothwise/src/features/home/domain/entities/clothing_item.dart';

/// Service for shopping recommendations
class ShopService {
  final Dio _dio;
  final String baseUrl;

  ShopService({
    Dio? dio,
    this.baseUrl = 'http://192.168.1.5:5000', // Local network IP for phone/emulator
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  /// Get shopping products (all products from backend)
  Future<List<ShopProduct>> getShopProducts({
    String? category,
    int limit = 50,
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
        return products
            .map((product) => ShopProduct.fromJson(product))
            .toList();
      } else {
        throw Exception('Failed to load shop products');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error fetching shop products: $e');
    }
  }

  /// Get product image URL
  String getProductImageUrl(String imageId) {
    return '$baseUrl/image/$imageId';
  }

  /// Get categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get('$baseUrl/categories');
      final List<dynamic> categories = response.data['categories'];
      return categories.cast<String>();
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /// Get smart shopping suggestions based on wardrobe gaps
  /// Analyzes what user has and suggests what they're missing
  Future<List<ShopProduct>> getSmartSuggestions({
    required List<ClothingItem> wardrobeItems,
    int limit = 50,
  }) async {
    // Get all available products
    final allProducts = await getShopProducts(limit: limit);

    // Analyze wardrobe to find gaps
    final wardrobeColors = wardrobeItems.map((item) => item.color.toLowerCase()).toSet();

    // Find products that fill gaps
    final suggestions = <ShopProduct>[];

    for (final product in allProducts) {
      final productCategory = _mapToClothingCategory(product.category);

      // Prioritize products from categories user doesn't have much of
      final categoryCount = wardrobeItems.where((item) =>
        item.category == productCategory
      ).length;

      // Suggest if:
      // 1. User has 0-2 items in this category, OR
      // 2. Product has a color user doesn't have
      final productColor = _extractColor(product.description.toLowerCase());

      if (categoryCount < 2 || !wardrobeColors.contains(productColor)) {
        suggestions.add(product);
      }
    }

    // If no gaps found, return diverse selection
    if (suggestions.isEmpty) {
      return allProducts.take(20).toList();
    }

    return suggestions;
  }

  /// Map backend category to ClothingCategory enum
  ClothingCategory _mapToClothingCategory(String category) {
    final lower = category.toLowerCase();

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

    return ClothingCategory.topwear;
  }

  /// Extract color from description
  String _extractColor(String description) {
    final colors = [
      'black', 'white', 'red', 'blue', 'green', 'yellow',
      'orange', 'purple', 'pink', 'brown', 'grey', 'gray',
      'navy', 'beige', 'khaki', 'maroon', 'burgundy'
    ];

    for (final color in colors) {
      if (description.contains(color)) {
        return color;
      }
    }

    return 'multi-color';
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Make sure the API server is running.';
      default:
        return 'Network error: ${e.message}';
    }
  }
}

/// Shop product model
class ShopProduct {
  ShopProduct({
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageId,
    required this.url,
    this.gender = 'unisex',
    this.styleType = 'casual',
  });

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    return ShopProduct(
      name: json['name'] as String,
      category: json['category'] as String,
      price: json['price'] as String,
      description: json['description'] as String,
      imageId: json['image_id'] as String,
      url: json['url'] as String? ?? '',
      gender: json['gender'] as String? ?? 'unisex',
      styleType: json['style_type'] as String? ?? 'casual',
    );
  }

  final String name;
  final String category;
  final String price;
  final String description;
  final String imageId;
  final String url; // Shopping website URL
  final String gender;
  final String styleType;

  // Parse price to get numeric value for filtering
  double get priceValue {
    try {
      // Remove $ and any other characters, parse the number
      final numStr = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(numStr) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Determine price range
  String get priceRange {
    if (priceValue == 0) return 'Unknown';
    if (priceValue < 30) return 'Budget';
    if (priceValue < 60) return 'Mid-range';
    return 'Premium';
  }
}
