import 'package:cloud_firestore/cloud_firestore.dart';

class EventLocation {
  final String id;
  final String titolo;
  final double lat;
  final double lng;

  EventLocation({
    required this.id,
    required this.titolo,
    required this.lat,
    required this.lng,
  });

  factory EventLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geo = data['posizione'] as GeoPoint;

    return EventLocation(
      id: doc.id,
      titolo: data['titolo'],
      lat: geo.latitude,
      lng: geo.longitude,
    );
  }
}

