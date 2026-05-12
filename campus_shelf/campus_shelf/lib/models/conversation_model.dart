import 'package:firebase_database/firebase_database.dart';

/// Represents a single conversation thread between one buyer and a seller
/// for a specific item listing.
///
/// Realtime Database path: items/{itemId}/conversations/{buyerId}
class ConversationModel {
  final String conversationId; // same as buyerId (their email, sanitised)
  final String itemId;
  final String itemName;
  final String itemImageUrl;

  final String sellerEmail;
  final String sellerName;

  final String buyerEmail;
  final String buyerName;

  final DateTime createdAt;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastMessageSender; // email of sender of last message

  final int unreadBySeller;
  final int unreadByBuyer;

  // ── Item state mirrored here for fast UI rendering ────────────────────────
  final ItemStatus itemStatus;

  // ── Meetup state ──────────────────────────────────────────────────────────
  final String? meetupSpot;
  final String? meetupNote;
  final String? meetupProposedBy;       // email
  final bool meetupConfirmedBySeller;
  final bool meetupConfirmedByBuyer;

  // ── Receipt / completion state ────────────────────────────────────────────
  final bool receiptConfirmedBySeller;
  final bool receiptConfirmedByBuyer;
  final DateTime? closedAt;

  /// Whether this thread is locked (read-only for the buyer).
  /// True when: another buyer is in a pending meetup for the same item,
  /// OR the item is sold.
  final bool isLocked;
  final String? lockReason; // shown as a banner to the locked buyer

  const ConversationModel({
    required this.conversationId,
    required this.itemId,
    required this.itemName,
    required this.itemImageUrl,
    required this.sellerEmail,
    required this.sellerName,
    required this.buyerEmail,
    required this.buyerName,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSender,
    this.unreadBySeller = 0,
    this.unreadByBuyer = 0,
    this.itemStatus = ItemStatus.available,
    this.meetupSpot,
    this.meetupNote,
    this.meetupProposedBy,
    this.meetupConfirmedBySeller = false,
    this.meetupConfirmedByBuyer = false,
    this.receiptConfirmedBySeller = false,
    this.receiptConfirmedByBuyer = false,
    this.closedAt,
    this.isLocked = false,
    this.lockReason,
  });

  bool get isMeetupFullyConfirmed =>
      meetupConfirmedBySeller && meetupConfirmedByBuyer;

  bool get isTransactionComplete =>
      receiptConfirmedBySeller && receiptConfirmedByBuyer;

  // ── Firestore serialisation ───────────────────────────────────────────────

  factory ConversationModel.fromMap(Map<String, dynamic> map, String docId) {
    return ConversationModel(
      conversationId: docId,
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      itemImageUrl: map['itemImageUrl'] ?? '',
      sellerEmail: map['sellerEmail'] ?? '',
      sellerName: map['sellerName'] ?? '',
      buyerEmail: map['buyerEmail'] ?? '',
      buyerName: map['buyerName'] ?? '',
      createdAt: _toDateTime(map['createdAt']),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: _toDateTime(map['lastMessageAt']),
      lastMessageSender: map['lastMessageSender'] ?? '',
      unreadBySeller: map['unreadBySeller'] ?? 0,
      unreadByBuyer: map['unreadByBuyer'] ?? 0,
      itemStatus: ItemStatus.fromString(map['itemStatus'] ?? 'available'),
      meetupSpot: map['meetupSpot'],
      meetupNote: map['meetupNote'],
      meetupProposedBy: map['meetupProposedBy'],
      meetupConfirmedBySeller: map['meetupConfirmedBySeller'] ?? false,
      meetupConfirmedByBuyer: map['meetupConfirmedByBuyer'] ?? false,
      receiptConfirmedBySeller: map['receiptConfirmedBySeller'] ?? false,
      receiptConfirmedByBuyer: map['receiptConfirmedByBuyer'] ?? false,
      closedAt: map['closedAt'] != null ? _toDateTime(map['closedAt']) : null,
      isLocked: map['isLocked'] ?? false,
      lockReason: map['lockReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemImageUrl': itemImageUrl,
      'sellerEmail': sellerEmail,
      'sellerName': sellerName,
      'buyerEmail': buyerEmail,
      'buyerName': buyerName,
      'createdAt': ServerValue.timestamp,
      'lastMessage': lastMessage,
      'lastMessageAt': ServerValue.timestamp,
      'lastMessageSender': lastMessageSender,
      'unreadBySeller': unreadBySeller,
      'unreadByBuyer': unreadByBuyer,
      'itemStatus': itemStatus.value,
      'meetupSpot': meetupSpot,
      'meetupNote': meetupNote,
      'meetupProposedBy': meetupProposedBy,
      'meetupConfirmedBySeller': meetupConfirmedBySeller,
      'meetupConfirmedByBuyer': meetupConfirmedByBuyer,
      'receiptConfirmedBySeller': receiptConfirmedBySeller,
      'receiptConfirmedByBuyer': receiptConfirmedByBuyer,
      'closedAt': closedAt?.toIso8601String(),
      'isLocked': isLocked,
      'lockReason': lockReason,
    };
  }

  ConversationModel copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSender,
    int? unreadBySeller,
    int? unreadByBuyer,
    ItemStatus? itemStatus,
    String? meetupSpot,
    String? meetupNote,
    String? meetupProposedBy,
    bool? meetupConfirmedBySeller,
    bool? meetupConfirmedByBuyer,
    bool? receiptConfirmedBySeller,
    bool? receiptConfirmedByBuyer,
    DateTime? closedAt,
    bool? isLocked,
    String? lockReason,
  }) {
    return ConversationModel(
      conversationId: conversationId,
      itemId: itemId,
      itemName: itemName,
      itemImageUrl: itemImageUrl,
      sellerEmail: sellerEmail,
      sellerName: sellerName,
      buyerEmail: buyerEmail,
      buyerName: buyerName,
      createdAt: createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadBySeller: unreadBySeller ?? this.unreadBySeller,
      unreadByBuyer: unreadByBuyer ?? this.unreadByBuyer,
      itemStatus: itemStatus ?? this.itemStatus,
      meetupSpot: meetupSpot ?? this.meetupSpot,
      meetupNote: meetupNote ?? this.meetupNote,
      meetupProposedBy: meetupProposedBy ?? this.meetupProposedBy,
      meetupConfirmedBySeller:
          meetupConfirmedBySeller ?? this.meetupConfirmedBySeller,
      meetupConfirmedByBuyer:
          meetupConfirmedByBuyer ?? this.meetupConfirmedByBuyer,
      receiptConfirmedBySeller:
          receiptConfirmedBySeller ?? this.receiptConfirmedBySeller,
      receiptConfirmedByBuyer:
          receiptConfirmedByBuyer ?? this.receiptConfirmedByBuyer,
      closedAt: closedAt ?? this.closedAt,
      isLocked: isLocked ?? this.isLocked,
      lockReason: lockReason ?? this.lockReason,
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

// ── ItemStatus ──────────────────────────────────────────────────────────────

/// The lifecycle state of an item listing.
enum ItemStatus {
  available('available'),
  pendingMeetup('pendingMeetup'),
  sold('sold');

  const ItemStatus(this.value);
  final String value;

  static ItemStatus fromString(String s) {
    return ItemStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => ItemStatus.available,
    );
  }
}
