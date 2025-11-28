import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Service for AI-powered outfit recommendations
class RecommendationService {
  RecommendationService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'http://192.168.1.5:5000', // Local network IP for phone/emulator
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  final Dio _dio;

  /// Get recommendations for an uploaded image (accepts path string for web compatibility)
  Future<Map<String, List<ProductRecommendation>>> getRecommendations({
    required String imagePath,
    List<String>? categories,
    int numItems = 15,
  }) async {
    try {
      // Convert image to base64 using XFile (works on both web and mobile)
      final xFile = XFile(imagePath);
      final bytes = await xFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Make API request
      final response = await _dio.post<Map<String, dynamic>>(
        '/recommend',
        data: {
          'image': base64Image,
          if (categories != null) 'categories': categories,
          'num_items': numItems,
        },
      );

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      final data = response.data!;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Unknown error occurred');
      }

      // Parse recommendations
      final recommendationsData = data['recommendations'] as Map<String, dynamic>;
      final recommendations = <String, List<ProductRecommendation>>{};

      for (final entry in recommendationsData.entries) {
        final category = entry.key;
        final products = (entry.value as List)
            .map((p) => ProductRecommendation.fromJson(p as Map<String, dynamic>))
            .toList();

        recommendations[category] = products;
      }

      return recommendations;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  /// Shuffle recommendations excluding already shown items
  Future<List<ProductRecommendation>> shuffleRecommendations({
    required String category,
    required List<String> allItems,
    required List<String> shownItems,
    int numToShow = 3,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/shuffle',
        data: {
          'category': category,
          'all_items': allItems,
          'shown_items': shownItems,
          'num_to_show': numToShow,
        },
      );

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      final data = response.data!;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Unknown error occurred');
      }

      final products = (data['products'] as List)
          .map((p) => ProductRecommendation.fromJson(p as Map<String, dynamic>))
          .toList();

      return products;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to shuffle recommendations: $e');
    }
  }

  /// Get list of available categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/categories');

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      final categories = (response.data!['categories'] as List)
          .map((c) => c.toString())
          .toList();

      return categories;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Get product details
  Future<ProductRecommendation> getProductDetails(String productName) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/product/$productName',
      );

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      final data = response.data!;

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Unknown error occurred');
      }

      return ProductRecommendation.fromJson(data['product'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to get product details: $e');
    }
  }

  /// Get product image URL
  String getProductImageUrl(String imageId) {
    return '${_dio.options.baseUrl}/image/$imageId';
  }

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/health');
      return response.data?['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Connection timeout. Please check your internet connection.');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['error'] ?? 'Server error';
        return Exception('Server error ($statusCode): $message');

      case DioExceptionType.cancel:
        return Exception('Request was cancelled');

      case DioExceptionType.connectionError:
        return Exception(
          'Cannot connect to server. Make sure the API server is running.',
        );

      default:
        return Exception('Network error: ${e.message}');
    }
  }
}

/// Product recommendation model
class ProductRecommendation {
  ProductRecommendation({
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.imageId,
    this.gender = 'unisex',
    this.url = '',
    this.styleType = 'casual',
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      name: json['name'] as String,
      category: json['category'] as String,
      price: json['price'] as String,
      description: json['description'] as String,
      imageId: json['image_id'] as String,
      gender: json['gender'] as String? ?? 'unisex',
      url: json['url'] as String? ?? '',
      styleType: json['style_type'] as String? ?? 'casual',
    );
  }

  final String name;
  final String category;
  final String price;
  final String description;
  final String imageId;
  final String gender;
  final String url;
  final String styleType; // casual, uniform, semi_uniform

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'image_id': imageId,
      'gender': gender,
      'url': url,
      'style_type': styleType,
    };
  }
}
