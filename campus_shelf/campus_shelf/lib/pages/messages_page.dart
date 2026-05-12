import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/message_model.dart';
import '../models/item_model.dart';
import '../services/auth_service.dart';
import '../services/simple_messaging_service.dart';
import '../services/realtime_service.dart';
import 'conversation_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<MessageModel> _messages = [];
  Map<String, ItemModel> _items = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null || currentUser.email == null) {
        setState(() => _loading = false);
        return;
      }

      List<MessageModel> messages = await SimpleMessagingService.getUserMessages(currentUser.email!);
      
      // Get item details for each message
      Map<String, ItemModel> items = {};
      for (MessageModel message in messages) {
        if (!items.containsKey(message.itemId)) {
          ItemModel? item = await RealtimeService.getItemById(message.itemId);
          if (item != null) {
            items[message.itemId] = item;
          }
        }
      }
      
      setState(() {
        _messages = messages;
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('Error loading messages: $e');
    }
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      // await MessagingService.markAsRead(messageId);
      _loadMessages(); // Refresh messages
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      // await MessagingService.deleteMessage(messageId);
      _loadMessages(); // Refresh messages
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
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
        title: const Text('My Messages'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Messages from interested users will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMessages,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageCard(message);
                    },
                  ),
                ),
    );
  }

  Widget _buildMessageCard(MessageModel message) {
    final item = _items[message.itemId];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with item name and timestamp
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item?.name ?? 'Item not found',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${message.senderName} (${message.senderEmail})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Read/Unread indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: message.isRead ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.isRead ? 'Read' : 'New',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Message content
            Text(
              message.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            // Item info and actions
            if (item != null) ...[
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
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _viewConversation(message, item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      'View Conversation',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Timestamp and actions
            Row(
              children: [
                Text(
                  _formatDate(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                if (!message.isRead)
                  TextButton(
                    onPressed: () => _markAsRead(message.id),
                    child: const Text('Mark as Read'),
                  ),
                TextButton(
                  onPressed: () => _deleteMessage(message.id),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewConversation(MessageModel message, ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationPage(
          item: item,
          initialMessage: message,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
