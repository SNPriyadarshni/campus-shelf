import 'api_service.dart';
import '../models/item_model.dart';

class FirestoreService {
  // Add new item
  static Future<void> addItem(ItemModel item) async {
    try {
      await ApiService.addItem(item);
    } catch (e) {
      print('Error adding item: $e');
      rethrow;
    }
  }

  // Get all items
  static Future<List<ItemModel>> getAllItems() async {
    try {
      return await ApiService.getItems();
    } catch (e) {
      print('Error getting items: $e');
      return [];
    }
  }

  // Search items
  static Future<List<ItemModel>> searchItems(String query) async {
    try {
      return await ApiService.getItems(search: query);
    } catch (e) {
      print('Error searching items: $e');
      return [];
    }
  }

  // Filter items
  static Future<List<ItemModel>> filterItems({
    String? category,
    bool? freeOnly,
  }) async {
    try {
      return await ApiService.getItems(category: category, freeOnly: freeOnly);
    } catch (e) {
      print('Error filtering items: $e');
      return [];
    }
  }

  // Get item by ID
  static Future<ItemModel?> getItemById(String id) async {
    try {
      final items = await ApiService.getItems(); // Ideally we should have a getById in ApiService
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      print('Error getting item by ID: $e');
      return null;
    }
  }

  // Get items posted by current user
  static Future<List<ItemModel>> getUserItems(String userEmail) async {
    try {
      return await ApiService.getItems(userEmail: userEmail);
    } catch (e) {
      print('Error getting user items: $e');
      return [];
    }
  }
}
