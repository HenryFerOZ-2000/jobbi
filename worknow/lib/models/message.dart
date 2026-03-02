import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? messageId;
  final String senderId;
  final String message;
  final Timestamp timestamp;
  final bool seen;
  final String type;

  Message({
    this.messageId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    required this.seen,
    required this.type,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Message(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      seen: data['seen'] ?? false,
      type: data['type'] ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'message': message,
      'timestamp': timestamp,
      'seen': seen,
      'type': type,
    };
  }

  bool isMine(String currentUserId) {
    return senderId == currentUserId;
  }

  bool isValid() {
    return message.trim().isNotEmpty;
  }
}

