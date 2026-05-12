import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/simple_messaging_service.dart';

class WorkingChatPage extends StatefulWidget {
  final ItemModel item;
  final String otherUserEmail;
  final String otherUserName;

  const WorkingChatPage({
    super.key,
    required this.item,
    required this.otherUserEmail,
    required this.otherUserName,
  });

  @override
  State<WorkingChatPage> createState() => _WorkingChatPageState();
}

class _WorkingChatPageState extends State<WorkingChatPage> {
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
      print('=== WORKING CHAT: Loading messages ===');
      print('Item: ${widget.item.name}');
      print('Current user: ${AuthService().currentUser?.email}');
      print('Other user: ${widget.otherUserEmail}');
      
      // Get ALL messages for this item
      List<MessageModel> allMessages = await SimpleMessagingService.getItemMessages(widget.item.id);
      
      print('Found ${allMessages.length} total messages');
      for (MessageModel msg in allMessages) {
        print('DB: ${msg.senderEmail} -> ${msg.ownerEmail}: "${msg.message}"');
      }
      
      // SIMPLE FILTER: Messages between these two users
      final currentUser = AuthService().currentUser;
      if (currentUser != null && currentUser.email != null) {
        _messages = allMessages.where((msg) {
          // Check if message involves both users
          bool involvesMe = (msg.senderEmail == currentUser.email || msg.receiverEmail == currentUser.email || msg.ownerEmail == currentUser.email);
          bool involvesOther = (msg.senderEmail == widget.otherUserEmail || msg.receiverEmail == widget.otherUserEmail);
          return involvesMe && involvesOther;
        }).toList();
      }
      
      // Sort by timestamp (oldest first)
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      print('Final chat has ${_messages.length} messages:');
      for (MessageModel msg in _messages) {
        print('CHAT: ${msg.senderEmail}: "${msg.message}"');
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
      
      print('=== SENDING MESSAGE ===');
      print('From: ${currentUser.email}');
      print('To: ${widget.otherUserEmail}');
      print('Message: $messageText');
      
      // Send message - ALWAYS save with correct receiver
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.otherUserName,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Item info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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
                const Spacer(),
                // Payment options
                if (widget.item.priceType != 'Free')
                  ElevatedButton.icon(
                    onPressed: () => _showPaymentOptions(),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Pay Online', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
              ],
            ),
          ),
          
          // Messages area
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
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
                            return _buildMessage(message, isMe);
                          },
                        ),
            ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
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
                    color: Theme.of(context).colorScheme.primary,
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

  Widget _buildMessage(MessageModel message, bool isMe) {
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
                color: isMe
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 2,
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose your payment method:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.blue),
              title: const Text('Bank Transfer'),
              subtitle: const Text('Direct bank transfer'),
              onTap: () {
                Navigator.pop(context);
                _showBankTransfer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_android, color: Colors.green),
              title: const Text('UPI Payment'),
              subtitle: const Text('Google Pay, PhonePe, PayTM'),
              onTap: () {
                Navigator.pop(context);
                _showUPIPayment();
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.orange),
              title: const Text('Credit/Debit Card'),
              subtitle: const Text('Card payment online'),
              onTap: () {
                Navigator.pop(context);
                _showCardPayment();
              },
            ),
            ListTile(
              leading: const Icon(Icons.money, color: Colors.grey),
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when you receive'),
              onTap: () {
                Navigator.pop(context);
                _showCashPayment();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBankTransfer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bank Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bank Details:'),
            const SizedBox(height: 16),
            const Text('Account Name: CampusShelf'),
            const Text('Account Number: XXXX-XXXX-XXXX'),
            const Text('Bank: Example Bank'),
            const Text('IFSC: EXMP0001234'),
            const SizedBox(height: 16),
            const Text('After payment, share screenshot here'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUPIPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('UPI Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('UPI ID: campusshelf@ybl'),
            const SizedBox(height: 16),
            const Text('Scan QR code or use UPI ID'),
            const SizedBox(height: 16),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('QR Code\n(Placeholder)')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCardPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Card Payment'),
        content: const Text('Card payment gateway would be integrated here.\n\nThis would redirect to secure payment page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCashPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cash on Delivery'),
        content: const Text('You can pay when you receive the item.\n\nPlease have exact amount ready.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
