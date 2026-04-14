import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_location_model.dart';

class EventLocationServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<EventLocation>> getEventLocations(String eventId) {
    return _db
        .collection("events")
        .doc(eventId)
        .collection("posizioni")
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((d) => EventLocation.fromFirestore(d))
          .toList(),
    );
  }
}
