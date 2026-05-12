import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/simple_messaging_service.dart';

class SimpleChatPage extends StatefulWidget {
  final ItemModel item;
  final String otherUserEmail;
  final String otherUserName;

  const SimpleChatPage({
    super.key,
    required this.item,
    required this.otherUserEmail,
    required this.otherUserName,
  });

  @override
  State<SimpleChatPage> createState() => _SimpleChatPageState();
}

class _SimpleChatPageState extends State<SimpleChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List<MessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    
    try {
      print('=== DEBUG: Loading messages for item: ${widget.item.id} ===');
      print('=== DEBUG: Current user: ${AuthService().currentUser?.email}');
      print('=== DEBUG: Other user: ${widget.otherUserEmail}');
      print('=== DEBUG: Item owner: ${widget.item.ownerEmail}');
      
      // Get ALL messages for this item
      List<MessageModel> allMessages = await MessagingService.getItemMessages(widget.item.id);
      
      print('=== DEBUG: Found ${allMessages.length} total messages for this item');
      for (MessageModel msg in allMessages) {
        print('=== DEBUG: Message - ${msg.senderEmail} -> ${msg.ownerEmail}: "${msg.message}"');
      }
      
      // Simple filter: Show messages between current user and other user
      final currentUser = AuthService().currentUser;
      if (currentUser != null && currentUser.email != null) {
        _messages = allMessages.where((msg) {
          // Message must involve BOTH users
          bool involvesCurrentUser = msg.senderEmail == currentUser.email || msg.ownerEmail == currentUser.email;
          bool involvesOtherUser = msg.senderEmail == widget.otherUserEmail || msg.ownerEmail == widget.otherUserEmail;
          bool result = involvesCurrentUser && involvesOtherUser;
          
          print('=== DEBUG: Filtering message: ${msg.senderEmail} -> ${msg.ownerEmail}');
          print('=== DEBUG: Involves current user: $involvesCurrentUser');
          print('=== DEBUG: Involves other user: $involvesOtherUser');
          print('=== DEBUG: Include in chat: $result');
          
          return result;
        }).toList();
      }
      
      // Sort by timestamp (oldest first)
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      print('=== DEBUG: Final chat has ${_messages.length} messages:');
      for (MessageModel msg in _messages) {
        print('=== CHAT: ${msg.senderEmail}: "${msg.message}"');
      }
      
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      print('=== ERROR: Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _sending = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null || currentUser.email == null) return;

      String messageText = _messageController.text.trim();
      
      // Send message
      await MessagingService.sendMessageLegacy(
        itemId: widget.item.id,
        itemName: widget.item.name,
        senderEmail: currentUser.email!,
        senderName: currentUser.displayName ?? currentUser.email!.split('@')[0],
        ownerEmail: widget.item.ownerEmail,
        message: messageText,
      );

      // Clear input
      _messageController.clear();
      setState(() => _sending = false);

      // Reload messages to show new one
      _loadMessages();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _sending = false);
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Chat with ${widget.otherUserName}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: Column(
        children: [
          // Item info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.item.category == 'Book' ? Colors.blue.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.item.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.item.category == 'Book' ? Colors.blue.shade800 : Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.item.priceType == 'Free' 
                        ? Colors.green.shade500 
                        : Colors.orange.shade500,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.item.priceType == 'Free' ? 'FREE' : widget.item.priceType,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderEmail == currentUser?.email;
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sending ? null : _sendMessage,
                  backgroundColor: const Color(0xFF6366F1),
                  child: _sending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                Text(
                  'You',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF6366F1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
