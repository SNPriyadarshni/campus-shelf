// ── MessageType enum ────────────────────────────────────────────────────────

/// Controls how a chat bubble is rendered.
///
/// | Type              | Who creates it | What the UI shows                          |
/// |-------------------|----------------|--------------------------------------------|
/// | text              | Buyer / Seller | Standard speech bubble                     |
/// | image             | Buyer / Seller | Full-width image thumbnail                 |
/// | system            | System         | Centred grey pill (no avatar, no actions)  |
/// | meetup_proposal   | Seller         | Rich card with location + Accept / Decline |
/// | receipt_request   | System         | "Did you receive the item?" action card    |
enum MessageType {
  text('text'),
  image('image'),
  system('system'),
  meetupProposal('meetup_proposal'),
  receiptRequest('receipt_request');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String s) {
    return MessageType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => MessageType.text,
    );
  }
}

// ── MessageModel ────────────────────────────────────────────────────────────

class MessageModel {
  final String id;
  final String senderId;   // email (or 'system')
  final String senderName;
  final String receiverId; // email (or 'all' for system broadcasts)
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final MessageType messageType;

  /// Extra structured payload for rich message types.
  ///
  /// meetup_proposal  → { spot, note, confirmedBySeller, confirmedByBuyer }
  /// receipt_request  → { confirmedBySeller, confirmedByBuyer }
  /// image            → { imageUrl }
  final Map<String, dynamic> metadata;

  // ── Backward-compatibility fields (kept so existing pages don't break) ────
  final String itemId;
  final String itemName;
  final String senderEmail;
  final String ownerEmail;
  final String receiverEmail;

  MessageModel({
    required this.id,
    this.senderId = '',
    this.senderName = '',
    this.receiverId = '',
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.messageType = MessageType.text,
    this.metadata = const {},
    this.itemId = '',
    this.itemName = '',
    this.senderEmail = '',
    this.ownerEmail = '',
    this.receiverEmail = '',
  });

  // ── Factory helpers ───────────────────────────────────────────────────────

  /// Creates a plain text message.
  factory MessageModel.text({
    required String id,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String text,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderEmail: senderId,
      receiverId: receiverId,
      message: text,
      timestamp: DateTime.now(),
      isRead: false,
      messageType: MessageType.text,
    );
  }

  /// Creates an automated system notification bubble.
  factory MessageModel.system({
    required String id,
    required String text,
    Map<String, dynamic> metadata = const {},
  }) {
    return MessageModel(
      id: id,
      senderId: 'system',
      senderName: 'Campus Shelf',
      receiverId: 'all',
      message: text,
      timestamp: DateTime.now(),
      isRead: true, // system messages are always "read"
      messageType: MessageType.system,
      metadata: metadata,
    );
  }

  /// Creates a meetup-proposal card sent by the seller.
  factory MessageModel.meetupProposal({
    required String id,
    required String sellerEmail,
    required String sellerName,
    required String buyerEmail,
    required String spot,
    required String note,
  }) {
    return MessageModel(
      id: id,
      senderId: sellerEmail,
      senderName: sellerName,
      senderEmail: sellerEmail,
      receiverId: buyerEmail,
      message: '📍 Meetup proposed: $spot',
      timestamp: DateTime.now(),
      isRead: false,
      messageType: MessageType.meetupProposal,
      metadata: {
        'spot': spot,
        'note': note,
        'confirmedBySeller': false,
        'confirmedByBuyer': false,
      },
    );
  }

  /// Creates a receipt-confirmation action card posted by the system.
  factory MessageModel.receiptRequest({
    required String id,
    required String buyerEmail,
  }) {
    return MessageModel(
      id: id,
      senderId: 'system',
      senderName: 'Campus Shelf',
      receiverId: buyerEmail,
      message: '✅ Please confirm you received the item.',
      timestamp: DateTime.now(),
      isRead: false,
      messageType: MessageType.receiptRequest,
      metadata: {
        'confirmedByBuyer': false,
        'confirmedBySeller': false,
      },
    );
  }

  // ── Firestore serialisation ───────────────────────────────────────────────

  factory MessageModel.fromMap(Map<String, dynamic> map, [String documentId = '']) {
    return MessageModel(
      id: documentId.isNotEmpty ? documentId : (map['id'] ?? ''),
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: _toDateTime(map['timestamp']),
      isRead: map['isRead'] ?? false,
      messageType: MessageType.fromString(map['messageType'] ?? 'text'),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      // backward-compat
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      senderEmail: map['senderEmail'] ?? map['senderId'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      receiverEmail: map['receiverEmail'] ?? map['receiverId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': isRead,
      'messageType': messageType.value,
      'metadata': metadata,
      // backward-compat
      'itemId': itemId,
      'itemName': itemName,
      'senderEmail': senderEmail,
      'ownerEmail': ownerEmail,
      'receiverEmail': receiverEmail,
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
