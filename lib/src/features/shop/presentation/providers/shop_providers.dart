import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clothwise/src/features/shop/data/shop_service.dart';
import 'package:clothwise/src/features/wardrobe/presentation/providers/wardrobe_providers.dart';

/// Provider for shop service
final shopServiceProvider = Provider<ShopService>((ref) {
  return ShopService();
});

/// Provider for smart shop products based on wardrobe gaps
final smartShopProductsProvider = FutureProvider<List<ShopProduct>>((ref) async {
  final service = ref.watch(shopServiceProvider);
  final wardrobeAsync = ref.watch(wardrobeItemsProvider);

  // Wait for wardrobe to load
  return wardrobeAsync.when(
    data: (wardrobeItems) async {
      // Get smart suggestions based on what user has
      return service.getSmartSuggestions(
        wardrobeItems: wardrobeItems,
        limit: 50,
      );
    },
    loading: () async {
      // If wardrobe is loading, show all products
      return service.getShopProducts(limit: 50);
    },
    error: (_, __) async {
      // If wardrobe has error, show all products
      return service.getShopProducts(limit: 50);
    },
  );
});

/// Provider for filtered shop products
final filteredShopProductsProvider = Provider.family<List<ShopProduct>, ShopFilters>(
  (ref, filters) {
    final productsAsync = ref.watch(smartShopProductsProvider);

    return productsAsync.when(
      data: (products) {
        var filtered = products;

        // Filter by price range
        if (filters.priceRange != 'All') {
          filtered = filtered.where((p) => p.priceRange == filters.priceRange).toList();
        }

        // Filter by category
        if (filters.category != null && filters.category!.isNotEmpty) {
          filtered = filtered.where((p) => p.category == filters.category).toList();
        }

        // Filter by style type
        if (filters.styleType != null && filters.styleType!.isNotEmpty) {
          final styleFilter = filters.styleType == 'Formal'
              ? 'uniform'
              : filters.styleType == 'Semi-formal'
                  ? 'semi_uniform'
                  : 'casual';
          filtered = filtered.where((p) => p.styleType == styleFilter).toList();
        }

        return filtered;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  },
);

/// Shop filters model
class ShopFilters {
  const ShopFilters({
    this.priceRange = 'All',
    this.category,
    this.styleType,
  });

  final String priceRange; // All, Budget, Mid-range, Premium
  final String? category;
  final String? styleType; // Casual, Formal, Semi-formal

  ShopFilters copyWith({
    String? priceRange,
    String? category,
    String? styleType,
  }) {
    return ShopFilters(
      priceRange: priceRange ?? this.priceRange,
      category: category ?? this.category,
      styleType: styleType ?? this.styleType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopFilters &&
          runtimeType == other.runtimeType &&
          priceRange == other.priceRange &&
          category == other.category &&
          styleType == other.styleType;

  @override
  int get hashCode => priceRange.hashCode ^ category.hashCode ^ styleType.hashCode;
}
