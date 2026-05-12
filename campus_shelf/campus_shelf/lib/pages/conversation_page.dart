import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../services/auth_service.dart';
import '../services/simple_messaging_service.dart';

class ConversationPage extends StatefulWidget {
  final ItemModel item;
  final MessageModel initialMessage;

  const ConversationPage({
    super.key,
    required this.item,
    required this.initialMessage,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  String get _buyerEmail => widget.initialMessage.senderEmail;
  String get _sellerEmail => widget.item.ownerEmail;

  String get _currentEmail =>
      AuthService().currentUser?.email ?? '';

  bool get _isSeller => _currentEmail == _sellerEmail;

  // ── Send text message ──────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null || currentUser.email == null) return;

      // await MessagingService.sendMessage(
      //   itemId: widget.item.id,
      //   itemName: widget.item.name,
      //   senderEmail: currentUser.email!,
      //   senderName:
      //       currentUser.displayName ?? currentUser.email!.split('@')[0],
      //   buyerEmail: _buyerEmail,
      //   sellerEmail: _sellerEmail,
      //   message: text,
      // );

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Type-dispatching message builder ───────────────────────────────────────

  Widget _buildMessage(MessageModel message, bool isMe) {
    switch (message.messageType) {
      case MessageType.system:
        return _buildSystemPill(message);
      case MessageType.meetupProposal:
        return _buildMeetupCard(message, isMe);
      case MessageType.receiptRequest:
        return _buildReceiptCard(message, isMe);
      case MessageType.text:
      case MessageType.image:
        return _buildBubble(message, isMe);
    }
  }

  // ── System pill ────────────────────────────────────────────────────────────

  Widget _buildSystemPill(MessageModel message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ),
    );
  }

  // ── Meetup proposal card ───────────────────────────────────────────────────

  Widget _buildMeetupCard(MessageModel message, bool isMe) {
    final spot = message.metadata['spot'] as String? ?? '';
    final note = message.metadata['note'] as String? ?? '';
    final confirmedByBuyer =
        message.metadata['confirmedByBuyer'] as bool? ?? false;
    final confirmedBySeller =
        message.metadata['confirmedBySeller'] as bool? ?? false;
    final bothConfirmed = confirmedByBuyer && confirmedBySeller;

    // Only buyer can accept (they are NOT the seller)
    final canAccept = !_isSeller && !confirmedByBuyer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Meetup Proposed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _meetupRow(Icons.place_outlined, 'Location', spot),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 6),
              _meetupRow(Icons.notes_rounded, 'Note', note),
            ],
            const SizedBox(height: 14),
            // Status / actions
            if (bothConfirmed)
              _statusChip(
                  '✅  Meetup confirmed by both parties', Colors.green.shade600)
            else if (confirmedByBuyer && !confirmedBySeller)
              _statusChip(
                  '⏳  Waiting for seller to confirm', Colors.orange.shade600)
            else if (!confirmedByBuyer && confirmedBySeller)
              _statusChip(
                  '⏳  Waiting for buyer\'s confirmation',
                  Colors.orange.shade600)
            else if (canAccept)
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      label: 'Decline',
                      bg: Colors.white24,
                      fg: Colors.white,
                      onTap: _showDeclineDialog,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      label: 'Accept',
                      bg: Colors.white,
                      fg: const Color(0xFF6366F1),
                      onTap: _acceptMeetup,
                    ),
                  ),
                ],
              )
            else
              _statusChip('📨  Awaiting buyer\'s response', Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _meetupRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: '$label: ',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
              TextSpan(
                  text: value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _actionButton({
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }

  Future<void> _acceptMeetup() async {
    // await MessagingService.confirmMeetup(
    //   itemId: widget.item.id,
    //   buyerEmail: _buyerEmail,
    //   confirmerEmail: _currentEmail,
    //   sellerEmail: _sellerEmail,
    // );
  }

  void _showDeclineDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Decline Meetup?'),
        content: const Text(
            'Let the seller know you can\'t make it. They can propose a new time.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // MessagingService.sendMessage(
              //   itemId: widget.item.id,
              //   itemName: widget.item.name,
              //   senderEmail: _currentEmail,
              //   senderName: _currentEmail.split('@').first,
              //   buyerEmail: _buyerEmail,
              //   sellerEmail: _sellerEmail,
              //   message:
              //       '❌ I can\'t make this meetup. Can we arrange another time?',
              // );
            },
            child:
                const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Receipt confirmation card ───────────────────────────────────────────────

  Widget _buildReceiptCard(MessageModel message, bool isMe) {
    final confirmedByBuyer =
        message.metadata['confirmedByBuyer'] as bool? ?? false;
    final confirmedBySeller =
        message.metadata['confirmedBySeller'] as bool? ?? false;
    final bothConfirmed = confirmedByBuyer && confirmedBySeller;
    final myConfirmed = _isSeller ? confirmedBySeller : confirmedByBuyer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.green.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text('Confirm Receipt',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                      fontSize: 15)),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Did you receive the item? Both parties must confirm to complete the transaction.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            if (bothConfirmed)
              _greenChip('🎉 Transaction complete!')
            else if (!myConfirmed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // MessagingService.confirmReceipt(
                    //   itemId: widget.item.id,
                    //   buyerEmail: _buyerEmail,
                    //   confirmerEmail: _currentEmail,
                    //   sellerEmail: _sellerEmail,
                    //   itemName: widget.item.name,
                    // );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Confirm Receipt',
                      style: TextStyle(color: Colors.white)),
                ),
              )
            else
              _greenChip('⏳ Waiting for other party to confirm'),
          ],
        ),
      ),
    );
  }

  Widget _greenChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(text,
          style: TextStyle(color: Colors.green.shade800, fontSize: 12)),
    );
  }

  // ── Standard chat bubble ───────────────────────────────────────────────────

  Widget _buildBubble(MessageModel message, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                Text(message.senderName,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
              ],
              Text(
                DateFormat('hh:mm a').format(message.timestamp),
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                Text('You',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF6366F1)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Locked banner ──────────────────────────────────────────────────────────

  Widget _buildLockedBanner(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange.shade50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded,
              color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 13,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConversationModel?>(
      stream: null, // MessagingService.conversationStream(widget.item.id, _buyerEmail),
      builder: (context, convSnap) {
        final conv = convSnap.data;
        final isLocked = conv?.isLocked ?? false;
        final lockReason =
            conv?.lockReason ?? 'This conversation is locked.';

        return Scaffold(
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.name,
                    style: const TextStyle(fontSize: 16)),
                Text(
                  'with ${widget.initialMessage.senderName}',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF6366F1),
          ),
          body: Column(
            children: [
              // Item category / price badges
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(children: [
                  _badge(
                    widget.item.category,
                    widget.item.category == 'Book'
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                    widget.item.category == 'Book'
                        ? Colors.blue.shade800
                        : Colors.green.shade800,
                  ),
                  const SizedBox(width: 8),
                  _badge(
                    widget.item.priceType == 'Free'
                        ? 'FREE'
                        : widget.item.priceType,
                    widget.item.priceType == 'Free'
                        ? Colors.green.shade500
                        : Colors.orange.shade500,
                    Colors.white,
                  ),
                ]),
              ),

              // Locked banner
              if (isLocked) _buildLockedBanner(lockReason),

              // Messages — real-time stream
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: null, // MessagingService.messagesStream(widget.item.id, _buyerEmail),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return const Center(
                          child: Text('No messages yet',
                              style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == _currentEmail;
                        return _buildMessage(message, isMe);
                      },
                    );
                  },
                ),
              ),

              // Input row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: isLocked
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_rounded,
                                size: 16, color: Colors.grey),
                            SizedBox(width: 6),
                            Text('This conversation is locked',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                ),
                                maxLines: null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FloatingActionButton(
                              heroTag: 'conv_send',
                              onPressed: _sending ? null : _sendMessage,
                              backgroundColor: const Color(0xFF6366F1),
                              mini: true,
                              child: _sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded,
                                      color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}
