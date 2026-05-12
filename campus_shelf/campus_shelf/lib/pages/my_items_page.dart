import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../services/simple_messaging_service.dart';
import '../services/clear_chat_service.dart';
import 'item_detail_page.dart';
import 'working_chat_page.dart';

class MyItemsPage extends StatefulWidget {
  const MyItemsPage({super.key});

  @override
  State<MyItemsPage> createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<MyItemsPage> {
  List<ItemModel> _myItems = [];
  Map<String, List<MessageModel>> _itemMessages = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyItems();
  }

  Future<void> _loadMyItems() async {
    setState(() => _loading = true);
    
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null || currentUser.email == null) {
        setState(() => _loading = false);
        return;
      }

      // Get user's posted items
      List<ItemModel> items = await RealtimeService.getUserItems(currentUser.email!);
      
      // Get messages for each item
      Map<String, List<MessageModel>> messages = {};
      for (ItemModel item in items) {
        List<MessageModel> itemMsgs = await SimpleMessagingService.getItemMessages(item.id);
        messages[item.id] = itemMsgs;
      }
      
      setState(() {
        _myItems = items;
        _itemMessages = messages;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('Error loading my items: $e');
    }
  }

  Future<void> _removeItem(ItemModel item) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Are you sure you want to remove "${item.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await RealtimeService.deleteItem(item.id);
        _showSuccess('Item removed successfully!');
        _loadMyItems(); // Refresh items
      } catch (e) {
        _showError('Failed to remove item: $e');
      }
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
        title: const Text('My Posted Items'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No items posted yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Items you post will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMyItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myItems.length,
                    itemBuilder: (context, index) {
                      final item = _myItems[index];
                      final messages = _itemMessages[item.id] ?? [];
                      return _buildItemCard(item, messages);
                    },
                  ),
                ),
    );
  }

  Widget _buildItemCard(ItemModel item, List<MessageModel> messages) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item header with remove button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
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
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeItem(item),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove Item',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Item description
            Text(
              item.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Posted date
            Text(
              'Posted: ${_formatDate(item.postedDate)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Messages section
            if (messages.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.message, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Messages (${messages.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _viewConversation(item, messages.first),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'View Conversation',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Show latest message preview
              if (messages.isNotEmpty)
                  Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${messages.first.senderName}: "${messages.first.message}"',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'No messages yet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessagePreview(MessageModel message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                message.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.message,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton(
                onPressed: () => _showReplyDialog(message),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Reply',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(MessageModel message) {
    final TextEditingController _replyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${message.senderName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Original message:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.message,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your reply:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _replyController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your reply...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_replyController.text.trim().isEmpty) {
                return;
              }
              
              Navigator.pop(context);
              
              try {
                // Find the item for this message
                ItemModel? item;
                for (ItemModel currentItem in _myItems) {
                  if (currentItem.id == message.itemId) {
                    item = currentItem;
                    break;
                  }
                }
                
                if (item != null) {
                  final currentUser = AuthService().currentUser;
                  if (currentUser != null && currentUser.email != null) {
                    await SimpleMessagingService.sendMessage(
                      itemId: item.id,
                      itemName: item.name,
                      senderEmail: currentUser.email!,
                      senderName: currentUser.displayName ?? currentUser.email!.split('@')[0],
                      ownerEmail: item.ownerEmail,
                      receiverEmail: message.senderEmail,
                      message: _replyController.text.trim(),
                    );
                    
                    _showSuccess('Reply sent successfully!');
                  }
                }
              } catch (e) {
                _showError('Failed to send reply: $e');
              }
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  void _viewConversation(ItemModel item, MessageModel firstMessage) {
    // Determine who is the other user (owner is chatting with buyer)
    final currentUser = AuthService().currentUser;
    if (currentUser == null || currentUser.email == null) return;
    
    String otherUserEmail = firstMessage.senderEmail == currentUser.email 
        ? (firstMessage.receiverEmail.isNotEmpty ? firstMessage.receiverEmail : firstMessage.ownerEmail)
        : firstMessage.senderEmail;
    
    String otherUserName = firstMessage.senderName == currentUser.displayName
        ? item.postedBy
        : firstMessage.senderName;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkingChatPage(
          item: item,
          otherUserEmail: otherUserEmail,
          otherUserName: otherUserName,
        ),
      ),
    );
  }

  void _showAllMessages(ItemModel item, List<MessageModel> messages) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Messages for ${item.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ListTile(
                title: Text(message.senderName),
                subtitle: Text(message.message),
                trailing: Text(_formatDate(message.timestamp)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
