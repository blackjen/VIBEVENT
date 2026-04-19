import 'package:rxdart/rxdart.dart';
import '../controllers/user_controller.dart';
import '../models/event_model.dart';
import '../models/event_chat_model.dart';
import '../models/event_news_model.dart';
import '../services/event_chat_services.dart';
import '../services/event_news_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyEventsController {
  final UserController _userController = UserController();
  final ChatServices _chatServices = ChatServices();

  Stream<List<EventModel>> subscribedEventsStream() {
    return _userController.eventiIscrittiCompletiStream();
  }

  Stream<List<ChatModel>> getMediaForEvent(String eventId) {
    return _chatServices
        .getMessages(eventId)
        .map(
          (messages) => messages
              .where((m) => m.type == "image" || m.type == "video")
              .toList(),
        );
  }

  // Ritorna true se c'è almeno una news non letta
  Stream<bool> hasUnreadNews(String eventId) {
    final userId = _userController.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    final newsStream = EventNewsServices().getEventNews(eventId);
    final lastReadStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('eventsRead')
        .doc(eventId)
        .snapshots();

    return Rx.combineLatest2<List<EventNewsModel>, DocumentSnapshot?, bool>(
      newsStream,
      lastReadStream,
      (newsList, lastReadDoc) {
        final latestNews = newsList.isNotEmpty ? newsList.first.data : null;
        final data = lastReadDoc?.data() as Map<String, dynamic>?;
        final lastRead = (data != null && data.containsKey('lastRead'))
            ? (data['lastRead'] as Timestamp).toDate()
            : null;

        return latestNews != null &&
            (lastRead == null || latestNews.isAfter(lastRead));
      },
    );
  }
}
