import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:clothwise/src/features/wardrobe/domain/user_wardrobe_item.dart';
import 'package:uuid/uuid.dart';

/// Service for storing and retrieving user's wardrobe items locally
class LocalWardrobeStorage {
  static const String _wardrobeFileName = 'user_wardrobe.json';
  static const String _imagesFolder = 'wardrobe_images';
  final _uuid = const Uuid();

  /// Get the wardrobe file path
  Future<File> _getWardrobeFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_wardrobeFileName');
  }

  /// Get the images directory
  Future<Directory> _getImagesDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/$_imagesFolder');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Save a new wardrobe item
  Future<UserWardrobeItem> saveItem({
    required String imagePath,
    required String name,
    required String category,
    required String styleType,
    String? color,
    String? notes,
  }) async {
    // Copy image to app storage
    final imageFile = File(imagePath);
    final imagesDir = await _getImagesDirectory();
    final newImagePath = '${imagesDir.path}/${_uuid.v4()}.jpg';
    await imageFile.copy(newImagePath);

    // Create wardrobe item
    final item = UserWardrobeItem(
      id: _uuid.v4(),
      name: name,
      category: category,
      styleType: styleType,
      imagePath: newImagePath,
      color: color,
      notes: notes,
      addedAt: DateTime.now(),
    );

    // Load existing items
    final items = await getAllItems();
    items.add(item);

    // Save to file
    final file = await _getWardrobeFile();
    final jsonList = items.map((item) => item.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));

    return item;
  }

  /// Get all wardrobe items
  Future<List<UserWardrobeItem>> getAllItems() async {
    try {
      final file = await _getWardrobeFile();
      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList
          .map((json) => UserWardrobeItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading wardrobe items: $e');
      return [];
    }
  }

  /// Delete a wardrobe item
  Future<void> deleteItem(String itemId) async {
    final items = await getAllItems();
    final item = items.firstWhere((item) => item.id == itemId);

    // Delete image file
    try {
      final imageFile = File(item.imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }

    // Remove from list and save
    items.removeWhere((item) => item.id == itemId);
    final file = await _getWardrobeFile();
    final jsonList = items.map((item) => item.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  /// Clear all wardrobe items
  Future<void> clearAll() async {
    // Delete all images
    try {
      final imagesDir = await _getImagesDirectory();
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error deleting images: $e');
    }

    // Delete wardrobe file
    try {
      final file = await _getWardrobeFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting wardrobe file: $e');
    }
  }
}
