import 'package:vibevent/controllers/user_controller.dart';
import '../models/user_model.dart';
import '../services/firebase_services.dart';
import 'dart:async';

class RegisterController {
  final FirebaseServices _firebaseService = FirebaseServices();
  final UserController _userController = UserController();

  Future<String?> register(
    String nome,
    String cognome,
    String email,
    String password,
  ) async {
    try {
      final user = await _firebaseService.register(email, password);
      if (user == null) return "Errore nella creazione dell’account.";

      final userModel = UserModel(
        uid: user.uid,
        nome: nome,
        cognome: cognome,
        email: email,
      );

      await _firebaseService.saveUser(userModel);

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> registerWithGoogle() async {
    try {
      final user = await _firebaseService.signInWithGoogle();
      if (user == null) return "Registrazione annullata.";

      // Suddivisione nome/cognome da displayName
      final fullName = user.displayName ?? '';
      final parts = fullName.trim().split(' ');

      final nome = parts.isNotEmpty ? parts.first : '';
      final cognome = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      // Controlla se esiste già su Firestore
      UserModel? existingUser = await _firebaseService.getUser(user.uid);
      if (existingUser == null) {
        existingUser = UserModel(
          uid: user.uid,
          nome: nome,
          cognome: cognome,
          email: user.email ?? '',
        );
        await _firebaseService.saveUser(existingUser);
      }

      // Salva in memoria l'utente appena loggato
      _userController.setUser(existingUser);

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Ritorna l'utente corrente
  UserModel? get currentUser => _userController.currentUser;
}
