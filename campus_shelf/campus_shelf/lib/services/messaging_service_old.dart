import 'package:firebase_database/firebase_database.dart';
import '../models/message_model.dart';
import '../models/item_model.dart';
import '../models/conversation_model.dart';
import '../services/realtime_service.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

/// Campus Shelf — MessagingService (v2)
///
/// Realtime Database data layout:
///
///   messages/{itemId}/{buyerId}          ← ConversationModel doc
///   messages/{itemId}/{buyerId}/messages ← MessageModel sub-collection
///
/// The [buyerId] is the buyer's email with '.' replaced by '_' so it is a
/// valid document ID.
///
/// This ensures every (item, buyer) pair has exactly one isolated thread —
/// a seller can talk to 5 buyers for the same book without mixing messages.
class MessagingService {
  // ── Realtime Database references ──────────────────────────────────────────

  static final DatabaseReference _messagesRef = 
      FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://campusshelf-b3733-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref().child('messages');

  // ── ID helpers ────────────────────────────────────────────────────────────

  /// Sanitises an email so it can be used as a document ID.
  static String _sanitise(String email) => email.replaceAll('.', '_');

  /// Returns the Realtime Database reference for a conversation document.
  ///
  ///   messages/{itemId}/{sanitised buyerEmail}
  static DatabaseReference _convRef(String itemId, String buyerEmail) {
    return _messagesRef.child(itemId).child(_sanitise(buyerEmail));
  }

  /// Returns the Realtime Database reference for messages sub-collection inside
  /// a conversation.
  static DatabaseReference _messagesRef(String itemId, String buyerEmail) {
    return _convRef(itemId, buyerEmail).child('messages');
  }

  // ── Conversation bootstrap ────────────────────────────────────────────────

  /// Opens or resumes a conversation thread.
  ///
  /// Call this when a buyer taps "Message Seller" on an item detail page.
  /// If the conversation already exists it is returned as-is; otherwise a new
  /// doc is created and a system message is written.
  static Future<ConversationModel> openOrCreateConversation({
    required ItemModel item,
    required String buyerEmail,
    required String buyerName,
    required String sellerName,
  }) async {
    final convDoc = _convRef(item.id, buyerEmail);
    final snapshot = await convDoc.get();

    if (snapshot.exists) {
      return ConversationModel.fromMap(
          snapshot.data() as Map<String, dynamic>, snapshot.id);
    }

    // ── Create a new conversation ─────────────────────────────────────────
    final conversation = ConversationModel(
      conversationId: _sanitise(buyerEmail),
      itemId: item.id,
      itemName: item.name,
      itemImageUrl: item.imageUrl,
      sellerEmail: item.ownerEmail,
      sellerName: sellerName,
      buyerEmail: buyerEmail,
      buyerName: buyerName,
      createdAt: DateTime.now(),
      lastMessage: '$buyerName is interested in ${item.name}',
      lastMessageAt: DateTime.now(),
      lastMessageSender: 'system',
      itemStatus: item.status,
    );

    await convDoc.set(conversation.toMap());

    // Auto-post a system message in the thread
    await _writeSystemMessage(
      itemId: item.id,
      buyerEmail: buyerEmail,
      text: '👋 $buyerName is interested in "${item.name}"',
    );

    return conversation;
  }

  // ── Real-time Streams ─────────────────────────────────────────────────────

  /// **Real-time stream of messages** for a single conversation thread.
  ///
  /// Replaces the old [getItemMessages] Future — the ListView rebuilds
  /// automatically whenever a new message lands, exactly like WhatsApp.
  static Stream<List<MessageModel>> messagesStream(
      String itemId, String buyerEmail) {
    return _messagesRef(itemId, buyerEmail)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                MessageModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// **Real-time stream of the conversation document** itself.
  ///
  /// Use this in the chat header to reactively update the status badge,
  /// meetup card confirmation state, etc.
  static Stream<ConversationModel?> conversationStream(
      String itemId, String buyerEmail) {
    return _convRef(itemId, buyerEmail).snapshots().map((snap) {
      if (!snap.exists) return null;
      return ConversationModel.fromMap(
          snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  /// **Real-time stream of ALL conversations** where the given user is either
  /// buyer or seller — used to populate the Inbox page.
  ///
  /// Because Firestore does not support OR queries across collection groups
  /// for non-indexed fields, we use a collectionGroup query filtered by each
  /// role and merge the streams on the client.
  ///
  /// Returns a combined, de-duplicated, timestamp-sorted list.
  static Stream<List<ConversationModel>> inboxStream(String userEmail) {
    final asSeller = _firestore
        .collectionGroup('conversations')
        .where('sellerEmail', isEqualTo: userEmail)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();

    final asBuyer = _firestore
        .collectionGroup('conversations')
        .where('buyerEmail', isEqualTo: userEmail)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();

    // Combine both streams
    return asSeller.asyncMap((sellerSnap) async {
      final buyerSnap = await asBuyer.first;
      final all = {
        for (final d in sellerSnap.docs)
          d.id: ConversationModel.fromMap(d.data(), d.id),
        for (final d in buyerSnap.docs)
          d.id: ConversationModel.fromMap(d.data(), d.id),
      };
      final list = all.values.toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  // ── Sending messages ──────────────────────────────────────────────────────

  /// Sends a plain **text message** from [senderEmail] in the thread
  /// identified by [itemId] + [buyerEmail].
  ///
  /// The seller passes themselves as [buyerEmail] when opening a thread from
  /// the inbox (the thread doc already exists); callers should use
  /// [openOrCreateConversation] before the first message.
  static Future<void> sendMessage({
    required String itemId,
    required String itemName,
    required String senderEmail,
    required String senderName,
    required String buyerEmail,   // ← always the buyer's email
    required String sellerEmail,  // ← always the seller's email
    required String message,
  }) async {
    final msgRef = _messagesRef(itemId, buyerEmail).doc();
    final convRef = _convRef(itemId, buyerEmail);

    final msgModel = MessageModel(
      id: msgRef.id,
      senderId: senderEmail,
      senderName: senderName,
      senderEmail: senderEmail,
      receiverId: senderEmail == sellerEmail ? buyerEmail : sellerEmail,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      messageType: MessageType.text,
      itemId: itemId,
      itemName: itemName,
      ownerEmail: sellerEmail,
    );

    final isSeller = senderEmail == sellerEmail;

    await msgRef.set(msgModel.toMap());
      // Update conversation summary
      await convRef.update({
        'lastMessage': message,
        'lastMessageAt': ServerValue.timestamp,
        'lastMessageSender': senderEmail,
        if (isSeller)
          'unreadByBuyer': ServerValue.increment(1)
        else
          'unreadBySeller': ServerValue.increment(1),
      });

    // Email notification (fire-and-forget)
    _sendEmailNotification(msgModel, itemId, sellerEmail);
  }

  // ── Meetup Proposal ───────────────────────────────────────────────────────

  /// The seller proposes a campus meetup with one specific buyer.
  ///
  /// Side effects:
  /// 1. Writes a [MessageType.meetupProposal] card to this thread.
  /// 2. Sets [itemStatus] = pendingMeetup on this conversation.
  /// 3. **Locks all other buyer threads** for this item with a system notice.
  /// 4. Updates the item record in Firebase Realtime Database.
  static Future<void> proposeMeetup({
    required String itemId,
    required String sellerEmail,
    required String sellerName,
    required String buyerEmail,
    required String spot,
    required String note,
  }) async {
    final msgRef = _messagesRef(itemId, buyerEmail).doc();

    final proposal = MessageModel.meetupProposal(
      id: msgRef.id,
      sellerEmail: sellerEmail,
      sellerName: sellerName,
      buyerEmail: buyerEmail,
      spot: spot,
      note: note,
    );

    await msgRef.set(proposal.toMap());
    await _convRef(itemId, buyerEmail).update({
      'itemStatus': ItemStatus.pendingMeetup.value,
      'meetupSpot': spot,
      'meetupNote': note,
      'meetupProposedBy': sellerEmail,
      'lastMessage': '📍 Meetup proposed: $spot',
      'lastMessageAt': ServerValue.timestamp,
      'lastMessageSender': sellerEmail,
      'unreadByBuyer': ServerValue.increment(1),
    });

    // Lock all OTHER buyer threads for this item
    await lockOtherThreads(
      itemId: itemId,
      activeBuyerEmail: buyerEmail,
      reason:
          'The seller is currently arranging a meetup with another buyer. You will be notified if the item becomes available again.',
    );
  }

  // ── Meetup Confirmation ───────────────────────────────────────────────────

  /// Called when either party taps "Accept" on the meetup_proposal card.
  static Future<void> confirmMeetup({
    required String itemId,
    required String buyerEmail,
    required String confirmerEmail,
    required String sellerEmail,
  }) async {
    final isSeller = confirmerEmail == sellerEmail;
    final field = isSeller ? 'meetupConfirmedBySeller' : 'meetupConfirmedByBuyer';

    await _convRef(itemId, buyerEmail).update({field: true});

    // Check if both have now confirmed
    final snap = await _convRef(itemId, buyerEmail).get();
    final data = snap.data() as Map<String, dynamic>;

    if ((data['meetupConfirmedBySeller'] ?? false) &&
        (data['meetupConfirmedByBuyer'] ?? false)) {
      final spot = data['meetupSpot'] ?? 'the agreed location';

      await _writeSystemMessage(
          itemId: itemId,
          buyerEmail: buyerEmail,
          text: '✅ Meetup confirmed! Meet at "$spot". '
              'After the exchange, tap "Confirm Receipt" to close the deal.',
        );
        await _convRef(itemId, buyerEmail).update({
          'lastMessage': '✅ Meetup confirmed at "$spot"',
          'lastMessageAt': ServerValue.timestamp,
        });
    }
  }

  // ── Receipt Confirmation ──────────────────────────────────────────────────

  /// Called when buyer or seller taps "Confirm Receipt".
  ///
  /// When BOTH parties confirm:
  /// - Item is marked as [ItemStatus.sold] everywhere.
  /// - All threads for this item are locked.
  /// - A system message is posted in the active thread.
  static Future<void> confirmReceipt({
    required String itemId,
    required String buyerEmail,
    required String confirmerEmail,
    required String sellerEmail,
    required String itemName,
  }) async {
    final isBuyer = confirmerEmail == buyerEmail;
    final field =
        isBuyer ? 'receiptConfirmedByBuyer' : 'receiptConfirmedBySeller';

    await _convRef(itemId, buyerEmail).update({field: true});

    final snap = await _convRef(itemId, buyerEmail).get();
    final data = snap.data() as Map<String, dynamic>;

    if ((data['receiptConfirmedBySeller'] ?? false) &&
        (data['receiptConfirmedByBuyer'] ?? false)) {
      // Both confirmed — transaction complete
      await _writeSystemMessage(
          itemId: itemId,
          buyerEmail: buyerEmail,
          text:
              '🎉 Transaction complete! "$itemName" has been handed over. Thank you for using Campus Shelf!',
        );
        await _convRef(itemId, buyerEmail).update({
          'itemStatus': ItemStatus.sold.value,
          'receiptConfirmedBySeller': true,
          'receiptConfirmedByBuyer': true,
          'closedAt': ServerValue.timestamp,
          'lastMessage': '🎉 Transaction complete!',
          'lastMessageAt': ServerValue.timestamp,
          'pendingBuyerEmail': null,
        }),
        // Lock ALL threads for this item (including the active one)
        lockOtherThreads(
          itemId: itemId,
          activeBuyerEmail: '', // lock everyone
          reason:
              'This item has been sold. Thank you for your interest in Campus Shelf!',
          lockAll: true,
        ),
      ]);
    }
  }

  // ── Thread locking ────────────────────────────────────────────────────────

  /// Locks every buyer thread for [itemId] **except** [activeBuyerEmail],
  /// writing a system notice into each locked thread.
  ///
  /// Set [lockAll] = true to lock every thread (used when item is sold).
  static Future<void> lockOtherThreads({
    required String itemId,
    required String activeBuyerEmail,
    required String reason,
    bool lockAll = false,
  }) async {
    final snapshot = await _firestore
        .collection('items')
        .doc(itemId)
        .collection('conversations')
        .get();

    final futures = <Future>[];

    for (final doc in snapshot.docs) {
      final buyerId = doc.id; // sanitised buyer email
      final data = doc.data();
      final thisBuyerEmail = data['buyerEmail'] ?? '';

      final isActive =
          !lockAll && _sanitise(activeBuyerEmail) == buyerId;
      if (isActive) continue; // skip the active thread

      await doc.reference.update({
        'isLocked': true,
        'lockReason': reason,
        'itemStatus': lockAll
            ? ItemStatus.sold.value
            : ItemStatus.pendingMeetup.value,
        'lastMessageAt': ServerValue.timestamp,
      });
      await _writeSystemMessage(
        itemId: itemId,
        buyerEmail: thisBuyerEmail,
        text: '🔒 $reason',
      );
    }
  }

  // ── Read receipts ─────────────────────────────────────────────────────────

  /// Resets unread counts when the user opens a thread.
  static Future<void> markThreadRead({
    required String itemId,
    required String buyerEmail,
    required bool readerIsSeller,
  }) async {
    await _convRef(itemId, buyerEmail).update({
      if (readerIsSeller) 'unreadBySeller': 0 else 'unreadByBuyer': 0,
    });

    // Mark individual messages as read
    final unread = await _messagesRef(itemId, buyerEmail)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: readerIsSeller ? '' : 'system')
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Deletion (seller only) ────────────────────────────────────────────────

  /// Deletes all messages in a thread and the conversation doc itself.
  ///
  /// Should only be called by the seller or an admin flow.
  static Future<void> deleteConversation({
    required String itemId,
    required String buyerEmail,
  }) async {
    final messages =
        await _messagesRef(itemId, buyerEmail).limit(300).get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_convRef(itemId, buyerEmail));
    await batch.commit();
  }

  // ── Legacy API (backward compatibility) ───────────────────────────────────
  //
  // The methods below preserve the old flat-collection API signatures so that
  // pages that haven't been migrated yet (MessagesPage, ConversationPage)
  // continue to compile. They delegate to the new sub-collection API where
  // possible but fall back to the flat collection for pure reads.

  /// @deprecated Use [sendMessage] with [buyerEmail] + [sellerEmail] instead.
  @Deprecated('Use sendMessage(buyerEmail:, sellerEmail:) instead.')
  static Future<void> sendMessageLegacy({
    required String itemId,
    required String itemName,
    required String senderEmail,
    required String senderName,
    required String ownerEmail,
    required String message,
  }) {
    return sendMessage(
      itemId: itemId,
      itemName: itemName,
      senderEmail: senderEmail,
      senderName: senderName,
      buyerEmail: senderEmail == ownerEmail ? ownerEmail : senderEmail,
      sellerEmail: ownerEmail,
      message: message,
    );
  }

  /// @deprecated Kept for MessagesPage. Prefer [inboxStream].
  static Future<List<MessageModel>> getUserMessages(String userEmail) async {
    final snap = await _firestore
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: userEmail)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return snap.docs
        .map((d) => MessageModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// @deprecated Kept for ConversationPage. Prefer [messagesStream].
  static Future<List<MessageModel>> getItemMessages(String itemId) async {
    final snap = await _firestore
        .collectionGroup('messages')
        .where('itemId', isEqualTo: itemId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();
    return snap.docs
        .map((d) => MessageModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// @deprecated Kept for MessagesPage delete action.
  static Future<void> deleteMessage(String messageId) async {
    // Best-effort delete when we don't have the full path
    final snaps = await _firestore
        .collectionGroup('messages')
        .where('id', isEqualTo: messageId)
        .limit(1)
        .get();
    for (final doc in snaps.docs) {
      await doc.reference.delete();
    }
  }

  /// @deprecated Kept for MessagesPage mark-read action.
  static Future<void> markAsRead(String messageId) async {
    final snaps = await _firestore
        .collectionGroup('messages')
        .where('id', isEqualTo: messageId)
        .limit(1)
        .get();
    for (final doc in snaps.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static Future<void> _writeSystemMessage({
    required String itemId,
    required String buyerEmail,
    required String text,
  }) async {
    final msgRef = _messagesRef(itemId, buyerEmail).doc();
    await msgRef.set(MessageModel.system(id: msgRef.id, text: text).toMap());
  }

  static void _sendEmailNotification(
      MessageModel msg, String itemId, String sellerEmail) {
    // Fire and forget — errors are non-fatal
    NotificationService.sendNewMessageNotification(
      message: msg,
      item: ItemModel(
        id: itemId,
        name: msg.itemName,
        category: '',
        condition: '',
        priceType: '',
        description: '',
        imageUrl: '',
        postedBy: '',
        ownerEmail: sellerEmail,
        postedDate: DateTime.now(),
      ),
    ).catchError((e) => print('[MessagingService] Email error: $e'));
  }
}
