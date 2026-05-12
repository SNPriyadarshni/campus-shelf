# Campus Shelf - Real-Time Messaging System Design

## Overview
A WhatsApp-like real-time messaging system for peer-to-peer marketplace with multi-user scaling, trust & safety features, and transaction workflow integration.

---

## Database Schema

### Users Collection
```json
{
  "userId": "user_unique_id",
  "email": "user@college.edu",
  "displayName": "John Doe",
  "profilePicture": "url_to_image",
  "collegeId": "college_001",
  "verified": true,
  "rating": 4.5,
  "totalTransactions": 12,
  "lastActive": "2026-04-13T10:30:00Z",
  "isOnline": true
}
```

### Items Collection
```json
{
  "itemId": "item_unique_id",
  "title": "Data Structures Book",
  "description": "Used DS book in good condition",
  "category": "Book",
  "price": 450,
  "priceType": "Fixed", // "Fixed", "Negotiable", "Free"
  "condition": "Good", // "New", "Good", "Fair", "Poor"
  "images": ["url1", "url2"],
  "ownerId": "user_unique_id",
  "ownerName": "John Doe",
  "ownerEmail": "john@college.edu",
  "collegeId": "college_001",
  "location": "Library Building",
  "status": "Available", // "Available", "Pending_Meetup", "Sold", "Removed"
  "postedAt": "2026-04-13T09:00:00Z",
  "views": 45,
  "interestedCount": 3,
  "meetupLocation": null,
  "soldTo": null,
  "soldAt": null
}
```

### Conversations Collection
```json
{
  "conversationId": "conv_unique_id",
  "itemId": "item_unique_id",
  "itemTitle": "Data Structures Book",
  "participants": [
    {
      "userId": "buyer_unique_id",
      "role": "buyer",
      "joinedAt": "2026-04-13T09:15:00Z"
    },
    {
      "userId": "seller_unique_id", 
      "role": "seller",
      "joinedAt": "2026-04-13T09:15:00Z"
    }
  ],
  "status": "active", // "active", "completed", "cancelled"
  "lastMessage": {
    "text": "Sure, let's meet tomorrow",
    "senderId": "buyer_unique_id",
    "timestamp": "2026-04-13T10:30:00Z"
  },
  "itemStatus": "Available", // Syncs with item status
  "createdAt": "2026-04-13T09:15:00Z",
  "updatedAt": "2026-04-13T10:30:00Z"
}
```

### Messages Collection
```json
{
  "messageId": "msg_unique_id",
  "conversationId": "conv_unique_id",
  "senderId": "user_unique_id",
  "senderName": "John Doe",
  "senderRole": "buyer", // "buyer", "seller", "system"
  "text": "Is this book still available?",
  "type": "text", // "text", "image", "location", "system_notification"
  "metadata": {
    "imageUrl": null,
    "location": null,
    "notificationType": "item_status_change"
  },
  "timestamp": "2026-04-13T09:15:00Z",
  "readBy": [
    {
      "userId": "seller_unique_id",
      "readAt": "2026-04-13T09:16:00Z"
    }
  ],
  "isEdited": false,
  "editedAt": null
}
```

### Transactions Collection
```json
{
  "transactionId": "txn_unique_id",
  "conversationId": "conv_unique_id",
  "itemId": "item_unique_id",
  "buyerId": "buyer_unique_id",
  "sellerId": "seller_unique_id",
  "amount": 450,
  "paymentMethod": "upi", // "cash", "upi", "bank_transfer", "card"
  "paymentStatus": "pending", // "pending", "completed", "failed", "refunded"
  "meetupLocation": "Library Building - 2nd Floor",
  "meetupTime": "2026-04-14T14:00:00Z",
  "status": "pending_meetup", // "pending_meetup", "completed", "cancelled", "disputed"
  "receiptConfirmed": false,
  "receiptImage": "url_to_receipt",
  "createdAt": "2026-04-13T11:00:00Z",
  "completedAt": null
}
```

---

## Conversation Flow Logic

### 1. Entry Point - Item Listing
```dart
// User views item detail page
ItemDetailPage(itemId: "item_123")

// User clicks "Message" button
onMessagePressed() {
  // Check if conversation exists
  checkExistingConversation(itemId, currentUserId, ownerId)
    .then((conversation) {
      if (conversation != null) {
        // Open existing conversation
        navigateToConversation(conversation.id);
      } else {
        // Create new conversation
        createNewConversation(itemId, currentUserId, ownerId)
          .then((newConversation) {
            navigateToConversation(newConversation.id);
          });
      }
    });
}
```

### 2. Conversation States Based on Item Status

#### Available State
```dart
Widget buildConversationUI(ItemStatus itemStatus) {
  switch (itemStatus) {
    case 'Available':
      return Column(
        children: [
          MessageInput(), // Normal messaging
          ActionButtons([
            'Request Meetup',
            'Make Offer' (if negotiable)
          ]),
          PaymentButton() // For fixed price items
        ],
      );
      
    case 'Pending_Meetup':
      return Column(
        children: [
          MeetupDetailsCard(
            location: transaction.meetupLocation,
            time: transaction.meetupTime,
            status: transaction.status
          ),
          MessageInput(), // Still can communicate
          ActionButtons([
            'Change Meetup Location',
            'Cancel Meetup'
          ]),
          ConfirmReceiptButton() // For buyer after meetup
        ],
      );
      
    case 'Sold':
      return Column(
        children: [
          SoldBanner(
            soldTo: transaction.buyerId,
            soldAt: item.soldAt
          ),
          MessageInput(enabled: false), // Read-only
          TransactionHistoryCard() // Show completed transaction
        ],
      );
  }
}
```

### 3. Multi-User Scaling Logic

#### Thread Isolation
```dart
class ConversationManager {
  Map<String, Conversation> activeConversations = {};
  
  // Each item can have multiple buyer conversations
  Future<List<Conversation>> getItemConversations(String itemId) async {
    return await db.collection('conversations')
      .where('itemId', isEqualTo: itemId)
      .where('participants.userId', isEqualTo: currentUserId)
      .get();
  }
  
  // Create unique conversation per buyer-seller pair
  Future<Conversation> createConversation(
    String itemId, 
    String buyerId, 
    String sellerId
  ) async {
    // Check if conversation already exists
    String conversationKey = "${itemId}_${buyerId}_${sellerId}";
    
    if (activeConversations.containsKey(conversationKey)) {
      return activeConversations[conversationKey]!;
    }
    
    // Create new unique conversation
    Conversation newConv = Conversation(
      id: generateId(),
      itemId: itemId,
      participants: [
        Participant(userId: buyerId, role: 'buyer'),
        Participant(userId: sellerId, role: 'seller')
      ],
      status: 'active'
    );
    
    await saveConversation(newConv);
    activeConversations[conversationKey] = newConv;
    return newConv;
  }
}
```

#### Real-Time Message Sync
```dart
class MessageSync {
  StreamSubscription<QuerySnapshot>? messageSubscription;
  
  void listenToMessages(String conversationId) {
    messageSubscription = db
      .collection('messages')
      .where('conversationId', isEqualTo: conversationId)
      .orderBy('timestamp')
      .onSnapshot()
      .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
              handleNewMessage(change.doc);
              break;
            case DocumentChangeType.modified:
              handleMessageUpdate(change.doc);
              break;
          }
        }
      });
  }
  
  void handleNewMessage(DocumentSnapshot messageDoc) {
    Message message = Message.fromSnapshot(messageDoc);
    
    // Update UI immediately
    messageController.add(message);
    
    // Mark as read if not from current user
    if (message.senderId != currentUserId) {
      markMessageAsRead(message.id);
    }
    
    // Update conversation's last message
    updateConversationLastMessage(message.conversationId, message);
    
    // Send push notification if app is background
    if (isAppInBackground) {
      sendPushNotification(message);
    }
  }
}
```

### 4. Trust & Safety Features

#### Meetup Location Sharing
```dart
class MeetupManager {
  // Suggest safe campus locations
  List<CampusLocation> getSafeLocations() {
    return [
      CampusLocation(
        name: "Library - 2nd Floor",
        coordinates: LatLng(13.0827, 80.2707),
        safetyRating: "High",
        hasCCTV: true,
        hasSecurity: true
      ),
      CampusLocation(
        name: "Student Center - Ground Floor", 
        coordinates: LatLng(13.0828, 80.2708),
        safetyRating: "High",
        hasCCTV: true,
        hasSecurity: true
      )
    ];
  }
  
  // Propose meetup
  Future<void> proposeMeetup(
    String conversationId,
    CampusLocation location,
    DateTime time
  ) async {
    // Send system message
    await sendSystemMessage(
      conversationId,
      "📍 Meetup Proposed: ${location.name} at ${time.toString()}",
      type: "location",
      metadata: {
        "location": location.toJson(),
        "time": time.toIso8601String()
      }
    );
    
    // Update transaction
    await updateTransaction(
      conversationId,
      meetupLocation: location.name,
      meetupTime: time
    );
    
    // Change item status
    await updateItemStatus(conversationId, "Pending_Meetup");
  }
}
```

#### Receipt Confirmation System
```dart
class ReceiptManager {
  // Buyer confirms receipt
  Future<void> confirmReceipt(
    String transactionId,
    String receiptImageUrl
  ) async {
    // Update transaction
    await updateTransaction(transactionId, {
      'receiptConfirmed': true,
      'receiptImage': receiptImageUrl,
      'status': 'completed',
      'completedAt': DateTime.now().toIso8601String()
    });
    
    // Mark item as sold
    Transaction transaction = await getTransaction(transactionId);
    await updateItemStatus(transaction.itemId, "Sold", {
      'soldTo': transaction.buyerId,
      'soldAt': DateTime.now().toIso8601String()
    });
    
    // Send confirmation messages
    await sendSystemMessage(
      transaction.conversationId,
      "✅ Transaction completed! Receipt confirmed by buyer.",
      type: "system_notification"
    );
    
    // Update user ratings
    await updateUserRatings(transaction.buyerId, transaction.sellerId);
    
    // Close conversation
    await updateConversationStatus(transaction.conversationId, "completed");
  }
  
  // Dispute resolution
  Future<void> raiseDispute(
    String transactionId,
    String reason,
    String description
  ) async {
    await createDispute({
      'transactionId': transactionId,
      'raisedBy': currentUserId,
      'reason': reason,
      'description': description,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String()
    });
    
    // Notify admin
    await notifyAdmin(transactionId, reason);
    
    // Temporarily hold transaction
    await updateTransaction(transactionId, {
      'status': 'disputed'
    });
  }
}
```

---

## UI State Management

### Conversation List State
```dart
class ConversationListState {
  List<Conversation> conversations = [];
  Map<String, int> unreadCounts = {};
  bool isLoading = false;
  
  // Real-time updates
  void initialize() {
    listenToConversations();
    listenToNewMessages();
  }
  
  void listenToConversations() {
    db.collection('conversations')
      .where('participants.userId', isEqualTo: currentUserId)
      .where('status', isEqualTo: 'active')
      .onSnapshot()
      .listen((snapshot) {
        conversations = snapshot.docs
          .map((doc) => Conversation.fromSnapshot(doc))
          .toList();
        
        // Sort by last message timestamp
        conversations.sort((a, b) => 
          b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp));
        
        notifyListeners();
      });
  }
}
```

### Chat UI State
```dart
class ChatState {
  List<Message> messages = [];
  bool isTyping = false;
  bool isOnline = false;
  User? otherUser;
  Item? item;
  
  void loadConversation(String conversationId) async {
    // Load conversation details
    Conversation conv = await getConversation(conversationId);
    otherUser = await getUser(conv.getOtherParticipant(currentUserId));
    item = await getItem(conv.itemId);
    
    // Load messages
    messages = await getMessages(conversationId);
    
    // Start real-time listening
    listenToMessages(conversationId);
    
    // Mark messages as read
    await markAllAsRead(conversationId);
  }
  
  void sendMessage(String text) async {
    Message message = Message(
      conversationId: conversationId,
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now()
    );
    
    // Add to UI immediately
    messages.add(message);
    notifyListeners();
    
    // Save to database
    await saveMessage(message);
    
    // Update conversation last message
    await updateConversationLastMessage(conversationId, message);
  }
}
```

---

## Security & Privacy

### Message Encryption
```dart
class MessageSecurity {
  // End-to-end encryption for sensitive info
  Future<String> encryptMessage(String text) async {
    final key = await getEncryptionKey();
    return await encrypt(text, key);
  }
  
  // Only decrypt on recipient's device
  Future<String> decryptMessage(String encryptedText) async {
    final key = await getEncryptionKey();
    return await decrypt(encryptedText, key);
  }
}
```

### Content Moderation
```dart
class ContentModerator {
  List<String> blockedWords = ['spam', 'inappropriate', ...];
  
  bool isMessageAppropriate(String text) {
    // Check for blocked content
    for (String word in blockedWords) {
      if (text.toLowerCase().contains(word)) {
        return false;
      }
    }
    
    // Check for spam patterns
    if (isSpamPattern(text)) {
      return false;
    }
    
    return true;
  }
  
  Future<void> reportMessage(String messageId, String reason) async {
    await createReport({
      'messageId': messageId,
      'reportedBy': currentUserId,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String()
    });
  }
}
```

---

## Performance Optimization

### Message Pagination
```dart
class MessagePagination {
  static const int pageSize = 50;
  
  Future<List<Message>> loadMessages(
    String conversationId, 
    {int limit = pageSize, 
     DocumentSnapshot? startAfter}
  ) async {
    Query query = db
      .collection('messages')
      .where('conversationId', isEqualTo: conversationId)
      .orderBy('timestamp', descending: true)
      .limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    QuerySnapshot snapshot = await query.get();
    return snapshot.docs
      .map((doc) => Message.fromSnapshot(doc))
      .reversed
      .toList();
  }
}
```

### Caching Strategy
```dart
class ConversationCache {
  static const Duration cacheExpiry = Duration(minutes: 5);
  
  Future<List<Message>> getCachedMessages(String conversationId) async {
    CacheEntry? cached = cache[conversationId];
    
    if (cached != null && 
        DateTime.now().difference(cached.timestamp) < cacheExpiry) {
      return cached.data;
    }
    
    // Load from database
    List<Message> messages = await loadMessages(conversationId);
    cache[conversationId] = CacheEntry(messages, DateTime.now());
    return messages;
  }
}
```

---

## Testing Strategy

### Unit Tests
```dart
void main() {
  test('Conversation creation works correctly', () async {
    ConversationManager manager = ConversationManager();
    
    Conversation conv = await manager.createConversation(
      'item_123', 'buyer_456', 'seller_789'
    );
    
    expect(conv.participants.length, 2);
    expect(conv.itemId, 'item_123');
    expect(conv.status, 'active');
  });
  
  test('Message filtering works', () {
    List<Message> messages = [
      Message(senderId: 'user1', text: 'Hello'),
      Message(senderId: 'user2', text: 'Hi there'),
      Message(senderId: 'user1', text: 'How are you?')
    ];
    
    List<Message> user1Messages = filterMessagesForUser(messages, 'user1');
    expect(user1Messages.length, 2);
  });
}
```

### Integration Tests
```dart
void main() {
  testWidgets('Real-time messaging works', (tester) async {
    // Setup test environment
    await setupFirebaseTest();
    
    // Build chat page
    await tester.pumpWidget(ChatPage(conversationId: 'test_conv'));
    
    // Send message
    await tester.enterText(find.byType(TextField), 'Test message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    
    // Verify message appears
    expect(find.text('Test message'), findsOneWidget);
    
    // Verify database update
    await verifyMessageSaved('Test message');
  });
}
```

This comprehensive design provides a robust, scalable, and secure real-time messaging system that handles all the requirements while maintaining excellent user experience and safety features.
