import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing and retrieving user's outfit history
class OutfitStorageService {
  static const String _outfitHistoryKey = 'outfit_history';
  static const String _latestOutfitKey = 'latest_outfit';
  static const int _maxHistorySize = 50; // Keep last 50 outfits

  /// Save a new outfit to history
  Future<void> saveOutfit(Map<String, dynamic> outfitData) async {
    final prefs = await SharedPreferences.getInstance();

    // Add timestamp
    outfitData['timestamp'] = DateTime.now().toIso8601String();

    // Save as latest outfit
    await prefs.setString(_latestOutfitKey, jsonEncode(outfitData));

    // Add to history
    final history = await getOutfitHistory();
    history.insert(0, outfitData); // Add to beginning

    // Keep only max history size
    if (history.length > _maxHistorySize) {
      history.removeRange(_maxHistorySize, history.length);
    }

    // Save updated history
    final historyJson = history.map((outfit) => jsonEncode(outfit)).toList();
    await prefs.setStringList(_outfitHistoryKey, historyJson);
  }

  /// Get the latest outfit (most recently saved)
  Future<Map<String, dynamic>?> getLatestOutfit() async {
    final prefs = await SharedPreferences.getInstance();
    final outfitJson = prefs.getString(_latestOutfitKey);

    if (outfitJson == null) return null;

    try {
      return jsonDecode(outfitJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get outfit history (all saved outfits)
  Future<List<Map<String, dynamic>>> getOutfitHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_outfitHistoryKey);

    if (historyJson == null) return [];

    try {
      return historyJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all outfit history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_outfitHistoryKey);
    await prefs.remove(_latestOutfitKey);
  }

  /// Save uploaded image path for outfit
  Future<void> saveUploadedImage(String imagePath) async {
    final outfitData = {
      'type': 'uploaded_image',
      'imagePath': imagePath,
      'description': 'Outfit from uploaded photo',
    };
    await saveOutfit(outfitData);
  }

  /// Save recommendation result
  Future<void> saveRecommendation({
    required String imagePath,
    required Map<String, List<dynamic>> recommendations,
  }) async {
    final outfitData = {
      'type': 'ai_recommendation',
      'imagePath': imagePath,
      'recommendations': recommendations,
      'description': 'AI-powered outfit recommendation',
    };
    await saveOutfit(outfitData);
  }
}
