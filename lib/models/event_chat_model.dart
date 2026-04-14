import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String senderId;
  final String senderName;
  final String type; // image, video
  final String content;
  final DateTime timestamp;

  ChatModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.content,
    required this.timestamp,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      senderId: data['senderId'],
      senderName: data['senderName'],
      type: data['type'],
      content: data['content'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    "senderId": senderId,
    "senderName": senderName,
    "type": type,
    "content": content,
    "timestamp": FieldValue.serverTimestamp(),
  };
}
