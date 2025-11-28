import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clothwise/src/features/home/domain/entities/clothing_item.dart';
import 'package:clothwise/src/features/wardrobe/data/backend_products_service.dart';

/// Provider for backend products service
final backendProductsServiceProvider = Provider<BackendProductsService>((ref) {
  return BackendProductsService();
});

/// Provider for wardrobe items (from AI backend)
final wardrobeItemsProvider =
    FutureProvider<List<ClothingItem>>((ref) async {
  final service = ref.watch(backendProductsServiceProvider);
  return service.getAllProducts(limit: 100);
});

/// Provider for backend products (from AI backend)
final backendProductsProvider =
    FutureProvider<List<ClothingItem>>((ref) async {
  final service = ref.watch(backendProductsServiceProvider);
  return service.getAllProducts(limit: 100);
});

/// State notifier for managing wardrobe state (using backend products)
class WardrobeNotifier extends StateNotifier<AsyncValue<List<ClothingItem>>> {
  final BackendProductsService _service;

  WardrobeNotifier(this._service) : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _service.getAllProducts(limit: 100);
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Note: Add/delete functionality would require backend API endpoints
  // For now, these are placeholder methods
  Future<void> addItem({
    required dynamic imageFile,
    required String name,
    required ClothingCategory category,
    required String color,
    required ClothingUsage usage,
  }) async {
    // TODO: Implement backend API for adding items
    throw UnimplementedError('Add item requires backend API endpoint');
  }

  Future<void> deleteItem(ClothingItem item) async {
    // TODO: Implement backend API for deleting items
    throw UnimplementedError('Delete item requires backend API endpoint');
  }
}

/// Provider for wardrobe notifier
final wardrobeNotifierProvider =
    StateNotifierProvider<WardrobeNotifier, AsyncValue<List<ClothingItem>>>(
        (ref) {
  final service = ref.watch(backendProductsServiceProvider);
  return WardrobeNotifier(service);
});
