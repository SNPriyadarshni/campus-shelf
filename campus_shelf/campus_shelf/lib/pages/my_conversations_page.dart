import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/simple_messaging_service.dart';
import '../services/realtime_service.dart';
import '../services/clear_chat_service.dart';
import 'working_chat_page.dart';

class MyConversationsPage extends StatefulWidget {
  const MyConversationsPage({super.key});

  @override
  State<MyConversationsPage> createState() => _MyConversationsPageState();
}

class _MyConversationsPageState extends State<MyConversationsPage> {
  Map<String, List<MessageModel>> _conversations = {};
  Map<String, ItemModel> _items = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null || currentUser.email == null) {
        setState(() => _loading = false);
        return;
      }

      // Get ALL conversations where user is involved (as sender OR receiver)
      List<MessageModel> allMessages = await SimpleMessagingService.getUserMessages(currentUser.email!);
      
      // Group messages by item ID
      Map<String, List<MessageModel>> conversations = {};
      Map<String, ItemModel> items = {};
      
      for (MessageModel message in allMessages) {
        if (!conversations.containsKey(message.itemId)) {
          conversations[message.itemId] = [];
        }
        conversations[message.itemId]!.add(message);
        
        // Get item details
        if (!items.containsKey(message.itemId)) {
          ItemModel? item = await RealtimeService.getItemById(message.itemId);
          if (item != null) {
            items[message.itemId] = item;
          }
        }
      }
      
      setState(() {
        _conversations = conversations;
        _items = items;
        _loading = false;
      });
      
      print('Loaded ${conversations.length} conversations for ${currentUser.email}');
    } catch (e) {
      setState(() => _loading = false);
      print('Error loading conversations: $e');
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
        title: const Text('My Conversations'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start a conversation by contacting item owners',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      String itemId = _conversations.keys.elementAt(index);
                      List<MessageModel> messages = _conversations[itemId]!;
                      ItemModel? item = _items[itemId];
                      
                      return _buildConversationCard(item, messages, itemId);
                    },
                  ),
                ),
    );
  }

  Widget _buildConversationCard(ItemModel? item, List<MessageModel> messages, String itemId) {
    if (item == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          title: const Text('Item not found'),
          subtitle: Text('$messages messages'),
        ),
      );
    }

    // Get latest message
    MessageModel latestMessage = messages.reduce((a, b) => 
      a.timestamp.isAfter(b.timestamp) ? a : b
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            item.name[0],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              latestMessage.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${messages.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Text(
              'messages',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: () => _openConversation(item, messages.first),
      ),
    );
  }

  void _openConversation(ItemModel item, MessageModel firstMessage) {
    // Determine who is the other user
    final currentUser = AuthService().currentUser;
    if (currentUser == null || currentUser.email == null) return;
    
    String otherUserEmail = firstMessage.senderEmail == currentUser.email 
        ? (firstMessage.receiverEmail.isNotEmpty ? firstMessage.receiverEmail : firstMessage.ownerEmail)
        : firstMessage.senderEmail;
    
    String otherUserName = firstMessage.senderEmail == currentUser.email
        ? (firstMessage.receiverEmail == item.ownerEmail ? item.postedBy : "User")
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
}
