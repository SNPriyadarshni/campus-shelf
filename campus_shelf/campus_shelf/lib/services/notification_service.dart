import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../models/message_model.dart';
import '../models/item_model.dart';

class NotificationService {
  // Send email notification to item owner about new message
  static Future<void> sendNewMessageNotification({
    required MessageModel message,
    required ItemModel item,
  }) async {
    try {
      final Email email = Email(
        body: _buildNewMessageEmailBody(message, item),
        subject: '🔔 New message for your item: ${item.name}',
        recipients: [item.ownerEmail],
        isHTML: false,
      );

      await FlutterEmailSender.send(email);
      print('Email notification sent to ${item.ownerEmail}');
    } catch (e) {
      print('Error sending email notification: $e');
    }
  }

  // Send reply email from owner to interested user
  static Future<void> sendReplyEmail({
    required MessageModel originalMessage,
    required ItemModel item,
    required String replyMessage,
    required String ownerEmail,
  }) async {
    try {
      final Email email = Email(
        body: _buildReplyEmailBody(originalMessage, item, replyMessage, ownerEmail),
        subject: '📝 Reply regarding your interest in: ${item.name}',
        recipients: [originalMessage.senderEmail],
        isHTML: false,
      );

      await FlutterEmailSender.send(email);
      print('Reply email sent to ${originalMessage.senderEmail}');
    } catch (e) {
      print('Error sending reply email: $e');
    }
  }

  static String _buildNewMessageEmailBody(MessageModel message, ItemModel item) {
    return '''
🎓 CAMPUS SHELF - NEW MESSAGE NOTIFICATION

Hello ${item.postedBy},

Someone is interested in your item posted on Campus Shelf!

📦 ITEM DETAILS:
• Name: ${item.name}
• Category: ${item.category}
• Price: ${item.priceType}
• Posted: ${_formatDate(item.postedDate)}

💬 MESSAGE FROM:
• Name: ${message.senderName}
• Email: ${message.senderEmail}
• Sent: ${_formatDate(message.timestamp)}

📝 MESSAGE:
"${message.message}"

🔗 NEXT STEPS:
1. Reply to this email to contact the interested user
2. Or use the Campus Shelf app to manage all messages

Thank you for using Campus Shelf!
📚 Your College Marketplace
    ''';
  }

  static String _buildReplyEmailBody(
    MessageModel originalMessage,
    ItemModel item,
    String replyMessage,
    String ownerEmail,
  ) {
    return '''
🎓 CAMPUS SHELF - REPLY TO YOUR INQUIRY

Hello ${originalMessage.senderName},

Great news! The owner of "${item.name}" has replied to your message.

📦 ITEM DETAILS:
• Name: ${item.name}
• Category: ${item.category}
• Price: ${item.priceType}
• Owner: ${item.postedBy}

💬 YOUR ORIGINAL MESSAGE:
"${originalMessage.message}"

📝 OWNER'S REPLY:
"${replyMessage}"

🔗 NEXT STEPS:
1. Reply to this email to continue the conversation
2. Or check the Campus Shelf app for more updates

Thank you for using Campus Shelf!
📚 Your College Marketplace
    ''';
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
