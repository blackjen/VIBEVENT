import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibevent/models/event_chat_model.dart';

class ChatServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ChatModel>> getMessages(String eventId) {
    return _db
        .collection("events")
        .doc(eventId)
        .collection("chat")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => ChatModel.fromFirestore(d)).toList());
  }

  Future<void> sendMessage(
      String eventId,
      ChatModel message,
      ) async {
    await _db
        .collection("events")
        .doc(eventId)
        .collection("chat")
        .add(message.toMap());
  }
}
