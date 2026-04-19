import '../models/user_model.dart';
import '../services/firebase_services.dart';
import 'user_controller.dart';
import '../services/notification_services.dart';

class ProfileController {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final UserController _userController = UserController();

  UserModel? get currentUser => _userController.currentUser;

  // Validazioni
  bool _validateNotEmpty(String value) => value.trim().isNotEmpty;

  // Aggiorna profilo con verifica
  Future<String?> updateProfile({
    required String nome,
    required String cognome,
  }) async {
    final user = _userController.currentUser;
    if (user == null) return "Utente non loggato";

    // Validazioni
    if (!_validateNotEmpty(nome)) return "Inserisci il nome";
    if (!_validateNotEmpty(cognome)) return "Inserisci il cognome";

    try {
      // Aggiorna in memoria
      user.nome = nome.trim();
      user.cognome = cognome.trim();

      // Salva su Firestore
      await _firebaseServices.saveUser(user);
      return null; // aggiornamento ok
    } catch (e) {
      return "Errore aggiornamento: $e";
    }
  }

  // Logout
  Future<void> logout() async {
    final user = _userController.currentUser;

    // Unsubscribe dai topic dell’utente corrente
    if (user != null) {
      for (final eventId in user.eventiIscritti) {
        await NotificationService.instance.unsubscribeFromEvent(eventId);
      }
    }

    // Logout firebase + pulizia memoria
    await _firebaseServices.logout();
    _userController.logout();
  }
}
