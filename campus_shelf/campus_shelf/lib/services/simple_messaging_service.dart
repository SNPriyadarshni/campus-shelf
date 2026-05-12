import 'api_service.dart';
import '../models/message_model.dart';
import '../models/item_model.dart';
import '../services/realtime_service.dart';

class SimpleMessagingService {
  // Send message and save to database
  static Future<void> sendMessage({
    required String itemId,
    required String itemName,
    required String senderEmail,
    required String senderName,
    required String ownerEmail,
    required String receiverEmail,
    required String message,
  }) async {
    try {
      final messageData = {
        'itemId': itemId,
        'itemName': itemName,
        'senderEmail': senderEmail,
        'senderName': senderName,
        'ownerEmail': ownerEmail,
        'receiverEmail': receiverEmail,
        'message': message,
      };
      
      await ApiService.sendMessage(messageData);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a specific item
  static Future<List<MessageModel>> getItemMessages(String itemId) async {
    try {
      return await ApiService.getItemMessages(itemId);
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Get all messages for current user (as owner or buyer)
  static Future<List<MessageModel>> getUserMessages(String userEmail) async {
    try {
      return await ApiService.getMessages(userEmail);
    } catch (e) {
      print('Error getting user messages: $e');
      return [];
    }
  }

  // Get all conversations for current user
  static Future<List<MessageModel>> getUserConversations(String userEmail) async {
    try {
      final allMessages = await getUserMessages(userEmail);
      allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allMessages;
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }
}
