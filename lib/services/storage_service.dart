import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rating_item.dart';

class StorageService {
  static const String _ratingsKey = 'ratings';
  static const String _categoriesKey = 'categories';

  // Save ratings to storage
  static Future<void> saveRatings(List<RatingItem> ratings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratingsJson = ratings.map((r) => r.toJson()).toList();
      await prefs.setString(_ratingsKey, jsonEncode(ratingsJson));
    } catch (e) {
      print('Error saving ratings: $e');
    }
  }

  // Load ratings from storage
  static Future<List<RatingItem>> loadRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratingsJsonString = prefs.getString(_ratingsKey);
      
      if (ratingsJsonString == null) {
        return [];
      }

      final List<dynamic> ratingsJson = jsonDecode(ratingsJsonString);
      return ratingsJson.map((json) => RatingItem.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading ratings: $e');
      return [];
    }
  }

  // Save categories to storage
  static Future<void> saveCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_categoriesKey, categories);
    } catch (e) {
      print('Error saving categories: $e');
    }
  }

  // Load categories from storage
  static Future<List<String>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_categoriesKey) ?? [];
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

  // Clear all data (for testing/debugging)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ratingsKey);
      await prefs.remove(_categoriesKey);
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
}

