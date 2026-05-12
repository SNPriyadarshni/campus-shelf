import '../models/item_model.dart';

class ItemService {
  static final List<ItemModel> _items = [];
  static final List<ItemModel> _userItems = []; // Items posted by current user

  // Get all items
  static List<ItemModel> getAllItems() {
    print('Getting all items: ${_items.length} items found');
    return List.from(_items);
  }

  // Get items posted by current user
  static List<ItemModel> getUserItems() {
    return List.from(_userItems);
  }

  // Add new item
  static void addItem(ItemModel item) {
    _items.add(item);
    _userItems.add(item);
    print('Item added: ${item.name} | Total items: ${_items.length}');
  }

  // Search items
  static List<ItemModel> searchItems(String query) {
    if (query.isEmpty) return getAllItems();
    
    return _items.where((item) => 
      item.name.toLowerCase().contains(query.toLowerCase()) ||
      item.description.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Filter items
  static List<ItemModel> filterItems({
    String? category,
    bool? freeOnly,
  }) {
    List<ItemModel> filtered = List.from(_items);
    
    if (category != null && category != 'All') {
      filtered = filtered.where((item) => item.category == category).toList();
    }
    
    if (freeOnly == true) {
      filtered = filtered.where((item) => item.priceType == 'Free').toList();
    }
    
    return filtered;
  }

  // Get item by ID
  static ItemModel? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Initialize with sample data
  static void initializeSampleData() {
    // No hardcoded data - only user posted items will be shown
    print('ItemService initialized - ready for user posts');
  }
}
