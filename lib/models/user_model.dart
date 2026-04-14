import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  String nome;
  String cognome;
  String email;
  GeoPoint posizione;
  List<String> eventiIscritti; // Lista degli ID eventi

  UserModel({
    required this.uid,
    required this.nome,
    required this.cognome,
    required this.email,
    this.posizione = const GeoPoint(0, 0),
    List<String>? eventiIscritti,
  }) : eventiIscritti = eventiIscritti ?? []; // Se non ha eventi -> lista vuota

  // Converti in mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "nome": nome,
      "cognome": cognome,
      "email": email,
      "posizione": posizione,
      "eventiIscritti": eventiIscritti,
    };
  }

  // Ricostruisci da Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      nome: map['nome'] as String,
      cognome: map['cognome'] as String,
      email: map['email'] as String,
      posizione: map['posizione'] as GeoPoint,
      eventiIscritti: List<String>.from(map['eventiIscritti'] ?? []),
    );
  }
}
