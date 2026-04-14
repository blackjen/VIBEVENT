import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibevent/models/event_news_model.dart';


class EventNewsServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<EventNewsModel>> getEventNews(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('news')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((d) => EventNewsModel.fromFirestore(d)).toList());
  }
}
