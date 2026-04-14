import 'package:cloud_firestore/cloud_firestore.dart';

class EventNewsModel {
  final String id;
  final String titolo;
  final String contenuto;
  final DateTime data;

  EventNewsModel({
    required this.id,
    required this.titolo,
    required this.contenuto,
    required this.data,
  });

  factory EventNewsModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    return EventNewsModel(
      id: doc.id,
      titolo: map['titolo'] ?? '',
      contenuto: map['contenuto'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
    );
  }
}
