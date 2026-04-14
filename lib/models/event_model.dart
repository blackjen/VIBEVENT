import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String titolo;
  final String id;
  final DateTime data;
  final String descrizione;
  final GeoPoint posizione;

  EventModel({
    required this.titolo,
    required this.id,
    required this.data,
    required this.descrizione,
    required this.posizione,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      titolo: map['titolo'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      descrizione: map['descrizione'] ?? '',
      posizione: map['posizione'] as GeoPoint,
    );
  }
}
