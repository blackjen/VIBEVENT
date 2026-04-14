import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/firebase_services.dart';

class UserController {
  // SINGLETON (Ovunque chiamo UserController, ottengo la stessa istanza)
  static final UserController _instance = UserController._internal();

  factory UserController() => _instance;

  UserController._internal();

  final FirebaseServices _firebase = FirebaseServices();

  // Utente corrente in memoria
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  // Imposta l'utente corrente
  void setUser(UserModel user) {
    _currentUser = user;
  }

  // Aggiorna posizione in memoria
  void updatePosition(GeoPoint geo) {
    if (_currentUser != null) {
      _currentUser!.posizione = geo;
    }
  }

  // Ritorna posizione
  GeoPoint? getPosition() {
    return _currentUser?.posizione;
  }

  // Controllo login
  bool isLoggedIn() {
    return _currentUser != null;
  }

  // Logout
  void logout() {
    _currentUser = null;
  }

  Future<List<EventModel>> eventiIscrittiCompleti() async {
    if (_currentUser?.eventiIscritti == null) return [];
    return await _firebase.getEventsByIds(_currentUser!.eventiIscritti);
  }

  Stream<List<EventModel>> eventiIscrittiCompletiStream() {
    if (_currentUser == null) {
      return Stream.value([]);
    }

    final userId = _currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userSnap) async {
      if (!userSnap.exists) return <EventModel>[];

      final data = userSnap.data();
      if (data == null || data['eventiIscritti'] == null) {
        return <EventModel>[];
      }

      final List<String> eventIds =
      List<String>.from(data['eventiIscritti']);

      if (eventIds.isEmpty) return <EventModel>[];

      final FirebaseFirestore db = FirebaseFirestore.instance;
      List<EventModel> events = [];

      // Firestore: max 10 ID per whereIn
      const batchSize = 10;

      for (var i = 0; i < eventIds.length; i += batchSize) {
        final batchIds = eventIds.sublist(
          i,
          i + batchSize > eventIds.length ? eventIds.length : i + batchSize,
        );

        final snapshot = await db
            .collection('events')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        events.addAll(
          snapshot.docs.map((d) => EventModel.fromFirestore(d)),
        );
      }

      // Ordina per data evento
      events.sort((a, b) => a.data.compareTo(b.data));

      return events;
    });
  }

  // Ritorna il documento con l'ultima news letta per un evento
  Future<DocumentSnapshot?> getEventLastRead(String eventId) async {
    final userId = _currentUser?.uid;
    if (userId == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('eventsRead')
        .doc(eventId)
        .get();

    return doc.exists ? doc : null;
  }

// Aggiorna l'ultima news letta
  Future<void> markEventNewsAsRead(String eventId) async {
    final userId = _currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('eventsRead')
        .doc(eventId)
        .set({'lastRead': DateTime.now()});
  }


}
