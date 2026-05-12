import 'conversation_model.dart';

class ItemModel {
  final String id;
  final String name;
  final String category; // 'Book' or 'Stationery'
  final String condition; // 'New' or 'Used'
  final String priceType; // 'Free' or 'Exchange'
  final String description;
  final String imageUrl;
  final String postedBy; // 'Senior', 'Junior', 'Staff'
  final String ownerEmail;
  final DateTime postedDate;

  // ── State machine fields ──────────────────────────────────────────────────
  /// Current lifecycle state of the listing.
  final ItemStatus status;

  /// Email of the buyer whose meetup is currently in progress.
  /// Non-null only when [status] == [ItemStatus.pendingMeetup].
  final String? pendingBuyerEmail;

  /// Email of the buyer who confirmed receipt (transaction complete).
  /// Non-null only when [status] == [ItemStatus.sold].
  final String? soldToBuyerEmail;

  /// Time when the item was purchased.
  final DateTime? purchaseTime;

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.condition,
    required this.priceType,
    required this.description,
    required this.imageUrl,
    required this.postedBy,
    required this.ownerEmail,
    required this.postedDate,
    this.status = ItemStatus.available,
    this.pendingBuyerEmail,
    this.soldToBuyerEmail,
    this.purchaseTime,
  });

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'condition': condition,
      'priceType': priceType,
      'description': description,
      'imageUrl': imageUrl,
      'postedBy': postedBy,
      'ownerEmail': ownerEmail,
      'postedDate': postedDate.toIso8601String(),
      'status': status.value,
      'pendingBuyerEmail': pendingBuyerEmail,
      'soldToBuyerEmail': soldToBuyerEmail,
      'purchaseTime': purchaseTime?.toIso8601String(),
    };
  }

  // Create from map
  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      condition: map['condition'],
      priceType: map['priceType'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      postedBy: map['postedBy'],
      ownerEmail: map['ownerEmail'],
      postedDate: DateTime.parse(map['postedDate']),
      status: ItemStatus.fromString(map['status'] ?? 'available'),
      pendingBuyerEmail: map['pendingBuyerEmail'],
      soldToBuyerEmail: map['soldToBuyerEmail'],
      purchaseTime: map['purchaseTime'] != null ? DateTime.parse(map['purchaseTime']) : null,
    );
  }

  ItemModel copyWith({
    ItemStatus? status,
    String? pendingBuyerEmail,
    String? soldToBuyerEmail,
  }) {
    return ItemModel(
      id: id,
      name: name,
      category: category,
      condition: condition,
      priceType: priceType,
      description: description,
      imageUrl: imageUrl,
      postedBy: postedBy,
      ownerEmail: ownerEmail,
      postedDate: postedDate,
      status: status ?? this.status,
      pendingBuyerEmail: pendingBuyerEmail ?? this.pendingBuyerEmail,
      soldToBuyerEmail: soldToBuyerEmail ?? this.soldToBuyerEmail,
      purchaseTime: purchaseTime ?? this.purchaseTime,
    );
  }
}
