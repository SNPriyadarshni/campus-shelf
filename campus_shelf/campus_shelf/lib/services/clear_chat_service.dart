import 'package:firebase_database/firebase_database.dart';

class ClearChatService {
  static final DatabaseReference _messagesRef = 
      FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://campusshelf-b3733-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref().child('messages');

  // Clear all messages for specific items to start fresh
  static Future<void> clearDSAMessages() async {
    try {
      print('=== CLEARING DSA MESSAGES ===');
      
      // Get all messages for DSA item
      DataSnapshot snapshot = await _messagesRef
          .orderByChild('itemId')
          .equalTo('-OknmZ1bs-AaZdz6rpVX')
          .get();
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map;
        
        // Delete each message
        for (String key in values.keys) {
          await _messagesRef.child(key).remove();
          print('Deleted message: $key');
        }
        
        print('=== CLEARED ${values.length} DSA MESSAGES ===');
      }
    } catch (e) {
      print('Error clearing DSA messages: $e');
    }
  }

  // Clear all messages for specific items to start fresh
  static Future<void> clearCalculatorMessages() async {
    try {
      print('=== CLEARING CALCULATOR MESSAGES ===');
      
      // Get all messages for Calculator item
      DataSnapshot snapshot = await _messagesRef
          .orderByChild('itemId')
          .equalTo('-OknltxoeAUJkTKsFWf0')
          .get();
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> values = snapshot.value as Map;
        
        // Delete each message
        for (String key in values.keys) {
          await _messagesRef.child(key).remove();
          print('Deleted message: $key');
        }
        
        print('=== CLEARED ${values.length} CALCULATOR MESSAGES ===');
      }
    } catch (e) {
      print('Error clearing Calculator messages: $e');
    }
  }

  // Clear all messages completely
  static Future<void> clearAllMessages() async {
    try {
      print('=== CLEARING ALL MESSAGES ===');
      
      await _messagesRef.remove();
      
      print('=== CLEARED ALL MESSAGES ===');
    } catch (e) {
      print('Error clearing all messages: $e');
    }
  }
}
