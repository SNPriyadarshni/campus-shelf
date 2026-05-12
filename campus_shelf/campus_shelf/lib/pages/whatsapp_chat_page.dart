import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/simple_messaging_service.dart';

class WhatsAppChatPage extends StatefulWidget {
  final ItemModel item;
  final String otherUserEmail;
  final String otherUserName;

  const WhatsAppChatPage({
    super.key,
    required this.item,
    required this.otherUserEmail,
    required this.otherUserName,
  });

  @override
  State<WhatsAppChatPage> createState() => _WhatsAppChatPageState();
}

class _WhatsAppChatPageState extends State<WhatsAppChatPage> {
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
      print('=== WHATSAPP CHAT: Loading messages ===');
      print('Item: ${widget.item.name}');
      print('Current user: ${AuthService().currentUser?.email}');
      print('Other user: ${widget.otherUserEmail}');
      
      // Get ALL messages for this item
      List<MessageModel> allMessages = await SimpleMessagingService.getItemMessages(widget.item.id);
      
      print('Found ${allMessages.length} total messages');
      for (MessageModel msg in allMessages) {
        print('DB: ${msg.senderEmail} -> ${msg.message}');
      }
      
      // Simple filter: Messages between these two users
      final currentUser = AuthService().currentUser;
      if (currentUser != null && currentUser.email != null) {
        _messages = allMessages.where((msg) {
          // Message involves both users
          bool involvesUser1 = msg.senderEmail == currentUser.email || msg.receiverEmail == currentUser.email || msg.ownerEmail == currentUser.email;
          bool involvesUser2 = msg.senderEmail == widget.otherUserEmail || msg.receiverEmail == widget.otherUserEmail;
          return involvesUser1 && involvesUser2;
        }).toList();
      }
      
      // Sort by timestamp (oldest first)
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      print('Chat has ${_messages.length} messages:');
      for (MessageModel msg in _messages) {
        print('CHAT: ${msg.senderEmail}: ${msg.message}');
      }
      
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      print('ERROR loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _sending = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null || currentUser.email == null) return;

      String messageText = _messageController.text.trim();
      
      print('=== SENDING NEW MESSAGE ===');
      print('From: ${currentUser.email}');
      print('Message: $messageText');
      
      // Send message
      await SimpleMessagingService.sendMessage(
        itemId: widget.item.id,
        itemName: widget.item.name,
        senderEmail: currentUser.email!,
        senderName: currentUser.displayName ?? currentUser.email!.split('@')[0],
        ownerEmail: widget.item.ownerEmail,
        receiverEmail: widget.otherUserEmail,
        message: messageText,
      );

      print('=== MESSAGE SENT ===');

      // Clear input
      _messageController.clear();
      setState(() => _sending = false);

      // Reload messages to show new one
      await _loadMessages();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _sending = false);
      print('ERROR sending message: $e');
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
      backgroundColor: const Color(0xFFF0F2F5), // WhatsApp dark green
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            Text(
              widget.otherUserName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF075E54), // WhatsApp green
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Item info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFECE5DD), // WhatsApp light grey
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.item.category == 'Book' ? Colors.blue.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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
          
          // Messages area
          Expanded(
            child: Container(
              color: const Color(0xFFECE5DD), // WhatsApp background
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: const Text(
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
                            return _buildWhatsAppMessage(message, isMe);
                          },
                        ),
            ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF128C7E), // WhatsApp blue
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppMessage(MessageModel message, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade400,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFDCF8C6) : Colors.white, // WhatsApp message colors
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.black87 : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF128C7E),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
