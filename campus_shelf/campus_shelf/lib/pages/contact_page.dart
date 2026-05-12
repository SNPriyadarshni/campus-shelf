import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../services/auth_service.dart';
import '../services/simple_messaging_service.dart';

class ContactPage extends StatefulWidget {
  final ItemModel item;

  const ContactPage({super.key, required this.item});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _messageController = TextEditingController();
  bool _loading = false;
  String _selectedMethod = 'In-app message';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_selectedMethod == 'In-app message') {
      if (_messageController.text.trim().isEmpty) {
        _showError('Please enter a message');
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null || currentUser.email == null) {
        _showError('User not logged in');
        return;
      }

      if (_selectedMethod == 'In-app message') {
        // Send in-app message
        await SimpleMessagingService.sendMessage(
          itemId: widget.item.id,
          itemName: widget.item.name,
          senderEmail: currentUser.email!,
          senderName: currentUser.displayName ?? currentUser.email!.split('@')[0],
          ownerEmail: widget.item.ownerEmail,
          receiverEmail: widget.item.ownerEmail,
          message: _messageController.text.trim(),
        );
        
        _showSuccess('Message sent successfully!');
      } else if (_selectedMethod == 'Email') {
        // Open email app
        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: widget.item.ownerEmail,
          query: 'subject=Interest in your item: ${widget.item.name}&body=Hi, I\'m interested in your item "${widget.item.name}" posted on CampusShelf.',
        );
        
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          _showSuccess('Email app opened!');
        } else {
          _showError('Could not open email app');
          return;
        }
      }
      
      Navigator.pop(context);
    } catch (e) {
      _showError('Failed to send message: $e');
    } finally {
      setState(() => _loading = false);
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
        title: const Text('Contact Owner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
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
                          color: widget.item.priceType == 'Free' ? Colors.orange.shade100 : Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.item.priceType,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.item.priceType == 'Free' ? Colors.orange.shade800 : Colors.purple.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Owner Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      widget.item.postedBy[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.postedBy,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Owner of this item',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contact Method Selection
            const Text(
              'Choose Contact Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('In-app message'),
                    subtitle: const Text('Send message through the app'),
                    value: 'In-app message',
                    groupValue: _selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value!;
                      });
                    },
                  ),
                  const Divider(),
                  RadioListTile<String>(
                    title: const Text('Email contact'),
                    subtitle: Text(widget.item.ownerEmail),
                    value: 'Email',
                    groupValue: _selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Message Input
            if (_selectedMethod == 'In-app message') ...[
              const Text(
                'Your Message',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Hi, I\'m interested in your item...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendMessage,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        _selectedMethod == 'In-app message' ? 'Send Message' : 'Open Email App',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
