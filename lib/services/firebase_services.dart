import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import 'notification_services.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // AUTH
  Future<User?> register(String email, String password) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCred.user;
  }

  Future<User?> login(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCred.user;
  }

  Future<void> logout() => _auth.signOut();

  // FIRESTORE
  Future<void> saveUser(UserModel user) async {
    await _db.collection("users").doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // LOGIN GOOGLE
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // L'utente ha annullato il login

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Login su Firebase
      final userCred = await _auth.signInWithCredential(credential);
      return userCred.user;
    } catch (e) {
      throw Exception('Errore login Google: $e');
    }
  }

  Future<void> updateUserPosition(String uid, GeoPoint geo) async {
    await _db.collection("users").doc(uid).update({"posizione": geo});
  }

  // Iscrive l'utente all'evento
  Future<void> iscriviEvento(String uid, String eventId) async {
    final userRef = _db.collection("users").doc(uid);

    await userRef.update({
      "eventiIscritti": FieldValue.arrayUnion([eventId]),
    });

    await NotificationService.instance.subscribeToEvent(eventId);
  }

  Future<List<EventModel>> getEventsByIds(List<String> eventIds) async {
    if (eventIds.isEmpty) return [];

    final FirebaseFirestore db = FirebaseFirestore.instance;
    List<EventModel> events = [];

    // Firestore permette massimo 10 elementi per whereIn, quindi dividiamo in batch
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

      events.addAll(snapshot.docs.map((doc) => EventModel.fromFirestore(doc)));
    }

    return events;
  }

  Future<List<EventModel>> getEventsFromToday() async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final snapshot = await _db
        .collection('events')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .orderBy('data')
        .get();

    return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
  }

  Future<List<EventModel>> getEvents() async {
    final snapshot = await _db.collection('events').get();
    return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
  }

}
