import 'package:flutter/material.dart';
import 'dart:convert';
import 'login_page.dart';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../services/realtime_service.dart';
import '../services/auth_service.dart';
import '../models/message_model.dart';
import '../services/simple_messaging_service.dart';
import 'post_item_page.dart';
import 'item_detail_page.dart';
import 'messages_page.dart';
import 'my_items_page.dart';
import 'my_conversations_page.dart';
import 'clear_chat_page.dart';
import '../models/conversation_model.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _freeOnly = false;
  bool _availableOnly = true; // Default to showing available items
  List<ItemModel> _filteredItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadMessageCounts();
  }

  int _unreadMessagesCount = 0;
  int _unreadConversationsCount = 0;

  Future<void> _loadMessageCounts() async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser != null && currentUser.email != null) {
        // Get conversations count (unique items user has messaged about)
        List<MessageModel> conversations = await SimpleMessagingService.getUserMessages(currentUser.email!);
        Set<String> uniqueItemIds = conversations.map((msg) => msg.itemId).toSet();
          
        // Get unread messages count (messages where user is not the sender and it's unread)
        int unreadCount = conversations.where((msg) => !msg.isRead && msg.senderEmail != currentUser.email).length;
          
        setState(() {
          _unreadMessagesCount = unreadCount;
          _unreadConversationsCount = uniqueItemIds.length;
        });
      }
    } catch (e) {
      print('Error loading message counts: $e');
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      List<ItemModel> items = await RealtimeService.getAllItems();
      
      
      setState(() {
        _filteredItems = items.where((item) => !_availableOnly || item.status == ItemStatus.available).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('Error loading items: $e');
    }
  }

  Future<void> _filterItems() async {
    setState(() => _loading = true);
    try {
      List<ItemModel> items;
      
      if (_searchController.text.isNotEmpty) {
        items = await RealtimeService.searchItems(_searchController.text);
      } else {
        items = await RealtimeService.filterItems(
          category: _selectedCategory,
          freeOnly: _freeOnly,
        );
      }
      
      
      setState(() {
        _filteredItems = items.where((item) => !_availableOnly || item.status == ItemStatus.available).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('Error filtering items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : const Color(0xFF212121),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        title: const Text('CampusShelf'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyConversationsPage()),
                  ).then((_) => _loadMessageCounts()); // Refresh on return
                },
                tooltip: 'My Conversations',
              ),
              if (_unreadMessagesCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadMessagesCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyItemsPage()),
              );
            },
            tooltip: 'My Items',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PostItemPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => _filterItems(),
                  ),
                  const SizedBox(height: 12),
                  // Filters
                  Row(
                    children: [
                      // Category Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const ['All', 'Book', 'Stationery'].map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                            _filterItems();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Available Only Filter
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: _availableOnly,
                              onChanged: (value) {
                                setState(() {
                                  _availableOnly = value!;
                                });
                                _filterItems();
                              },
                            ),
                            const Text('Available'),
                          ],
                        ),
                      ),
                      // Free Only Filter
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: _freeOnly,
                              onChanged: (value) {
                                setState(() {
                                  _freeOnly = value!;
                                });
                                _filterItems();
                              },
                            ),
                            const Text('Free'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Items Grid
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _filteredItems.isEmpty
                      ? const Center(
                          child: Text(
                            'No items found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : GridView.builder(
                          itemCount: _filteredItems.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return _buildItemCard(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailPage(item: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
              children: [
                _buildItemImage(item),
                if (item.status == ItemStatus.sold)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    alignment: Alignment.center,
                    child: const Text(
                      'Sold Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
                ),
              ),
            ),
            // Item Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.category == 'Book' ? Colors.blue.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: item.category == 'Book' ? Colors.blue.shade800 : Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Price/Free Badge - More Visible
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.priceType == 'Free' 
                                ? Colors.green.shade500 
                                : Colors.orange.shade500,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.priceType == 'Free' ? 'FREE' : item.priceType,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Posted by ${item.postedBy}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(ItemModel item) {
    if (item.imageUrl.startsWith('data:image')) {
      return Image.memory(
        base64Decode(item.imageUrl.split(',')[1]),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: Icon(
                item.category == 'Book' ? Icons.book : Icons.edit,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
          );
        },
      );
    } else if (item.imageUrl.startsWith('https://via.placeholder.com')) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            item.category == 'Book' ? Icons.book : Icons.edit,
            size: 40,
            color: Colors.grey.shade400,
          ),
        ),
      );
    } else {
      return Image.network(
        item.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: Icon(
                item.category == 'Book' ? Icons.book : Icons.edit,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
          );
        },
      );
    }
  }
}
