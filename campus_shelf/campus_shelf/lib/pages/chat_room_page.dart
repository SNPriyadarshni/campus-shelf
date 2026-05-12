import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../models/item_model.dart';
import '../models/conversation_model.dart';
import '../services/simple_messaging_service.dart';

class ChatRoomPage extends StatefulWidget {
  final String currentUserId; // typically user.email
  final String targetUserId;  // seller or buyer email (the other party)
  final String targetUserName;
  final ItemModel? item;

  /// Whether the current user is the seller.
  /// Used to determine [buyerEmail] / [sellerEmail] for the thread.
  final bool isSeller;

  const ChatRoomPage({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
    required this.targetUserName,
    this.item,
    this.isSeller = false,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();

  String get _buyerEmail =>
      widget.isSeller ? widget.targetUserId : widget.currentUserId;
  String get _sellerEmail =>
      widget.isSeller ? widget.currentUserId : widget.targetUserId;

  // ── Send text message ──────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (widget.item == null) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    await MessagingService.sendMessage(
      itemId: widget.item!.id,
      itemName: widget.item!.name,
      senderEmail: widget.currentUserId,
      senderName: widget.currentUserId.split('@').first,
      buyerEmail: _buyerEmail,
      sellerEmail: _sellerEmail,
      message: text,
    );
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // ── Meetup proposal card ───────────────────────────────────────────────────

  Widget _buildMeetupCard(MessageModel message, bool isMe) {
    final spot = message.metadata['spot'] as String? ?? '';
    final note = message.metadata['note'] as String? ?? '';
    final confirmedByBuyer = message.metadata['confirmedByBuyer'] as bool? ?? false;
    final confirmedBySeller = message.metadata['confirmedBySeller'] as bool? ?? false;
    final bothConfirmed = confirmedByBuyer && confirmedBySeller;

    // Buyer sees Accept/Decline; seller sees their own proposal summary
    final canRespond = !isMe && !confirmedByBuyer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
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
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Spot
              _meetupRow(Icons.place_outlined, 'Location', spot),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 6),
                _meetupRow(Icons.notes_rounded, 'Note', note),
              ],
              const SizedBox(height: 14),
              // Status / actions
              if (bothConfirmed)
                _statusChip('✅  Meetup confirmed by both parties',
                    Colors.green.shade600)
              else if (confirmedByBuyer && !confirmedBySeller)
                _statusChip('⏳  Waiting for seller to confirm',
                    Colors.orange.shade600)
              else if (!confirmedByBuyer && confirmedBySeller)
                _statusChip('⏳  Waiting for your confirmation',
                    Colors.orange.shade600)
              else if (canRespond)
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: 'Decline',
                        color: Colors.white24,
                        textColor: Colors.white,
                        onTap: () => _showDeclineDialog(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        label: 'Accept',
                        color: Colors.white,
                        textColor: const Color(0xFF6366F1),
                        onTap: () => _acceptMeetup(),
                      ),
                    ),
                  ],
                )
              else
                _statusChip('📨  Awaiting buyer\'s response',
                    Colors.white24),
            ],
          ),
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
            text: TextSpan(
              children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                TextSpan(
                    text: value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ),
    );
  }

  Future<void> _acceptMeetup() async {
    if (widget.item == null) return;
    await MessagingService.confirmMeetup(
      itemId: widget.item!.id,
      buyerEmail: _buyerEmail,
      confirmerEmail: widget.currentUserId,
      sellerEmail: _sellerEmail,
    );
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
              // Post a system message on the buyer side indicating decline
              if (widget.item != null) {
                MessagingService.sendMessage(
                  itemId: widget.item!.id,
                  itemName: widget.item!.name,
                  senderEmail: widget.currentUserId,
                  senderName: widget.currentUserId.split('@').first,
                  buyerEmail: _buyerEmail,
                  sellerEmail: _sellerEmail,
                  message: '❌ I can\'t make this meetup. Can we arrange another time?',
                );
              }
            },
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Receipt request card ───────────────────────────────────────────────────

  Widget _buildReceiptCard(MessageModel message, bool isMe) {
    final confirmedByBuyer =
        message.metadata['confirmedByBuyer'] as bool? ?? false;
    final confirmedBySeller =
        message.metadata['confirmedBySeller'] as bool? ?? false;
    final bothConfirmed = confirmedByBuyer && confirmedBySeller;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text('Confirm Receipt',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Did you receive the item? Both parties must confirm to complete the transaction.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            if (bothConfirmed)
              _greenChip('🎉 Transaction complete!')
            else if (!widget.isSeller && !confirmedByBuyer)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmReceipt(),
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

  Future<void> _confirmReceipt() async {
    if (widget.item == null) return;
    await MessagingService.confirmReceipt(
      itemId: widget.item!.id,
      buyerEmail: _buyerEmail,
      confirmerEmail: widget.currentUserId,
      sellerEmail: _sellerEmail,
      itemName: widget.item!.name,
    );
  }

  // ── Standard text bubble ───────────────────────────────────────────────────

  Widget _buildBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6366F1) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white60 : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.check,
                    color: message.isRead
                        ? Colors.blue.shade200
                        : Colors.white60,
                    size: 14,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Locked thread banner ───────────────────────────────────────────────────

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

  // ── Input bar ──────────────────────────────────────────────────────────────

  Widget _buildMessageInput({bool disabled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: disabled
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      'This conversation is locked',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.item == null) {
      return const Scaffold(
        body: Center(child: Text('No item context provided.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.targetUserName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text(
              widget.item!.name,
              style:
                  const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : const Color(0xFF212121),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // ── Wrap body in conversationStream so locked state is reactive ──
      body: StreamBuilder<ConversationModel?>(
        stream: MessagingService.conversationStream(
            widget.item!.id, _buyerEmail),
        builder: (context, convSnap) {
          final conv = convSnap.data;
          final isLocked = conv?.isLocked ?? false;
          final lockReason =
              conv?.lockReason ?? 'This conversation is locked.';

          return Column(
            children: [
              // Locked banner (shown reactively when isLocked flips to true)
              if (isLocked) _buildLockedBanner(lockReason),

              // Messages list
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: MessagingService.messagesStream(
                      widget.item!.id, _buyerEmail),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final messages = snapshot.data!;

                    // Mark as read
                    MessagingService.markThreadRead(
                      itemId: widget.item!.id,
                      buyerEmail: _buyerEmail,
                      readerIsSeller: widget.isSeller,
                    );

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message =
                            messages[messages.length - 1 - index];
                        final isMe =
                            message.senderId == widget.currentUserId;
                        return _buildMessage(message, isMe);
                      },
                    );
                  },
                ),
              ),

              // Input (disabled when locked)
              _buildMessageInput(disabled: isLocked),
            ],
          );
        },
      ),
    );
  }
}
