import 'dart:ui';
import 'package:vibevent/controllers/user_controller.dart';
import '../models/user_model.dart';
import '../services/firebase_services.dart';
import '../services/geolocator_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MainviewController {
  final GeolocatorServices _locationService;
  final UserController _userController;
  final FirebaseServices _firebaseServices = FirebaseServices();

  StreamSubscription<GeoPoint>? _positionSubscription;

  MainviewController(this._locationService, this._userController);

  // Controlla permessi e GPS e avvia lo stream
  Future<void> startPositionTracking() async {
    final permissionStatus = await _locationService.checkGeolocatorPermission();
    final gpsStatus = await _locationService.checkGpsPermissions();

    if (permissionStatus != LocationStatus.granted ||
        gpsStatus != LocationStatus.granted) {
      return; // Non parte la stream finché non è tutto OK
    }

    // Avvia lo stream se non già attivo
    _positionSubscription ??=
        _locationService // Stream parte solo se _positionSub == Null
            .getPositionStream(distanceFilter: 5)
            .handleError((_) {})
            .listen(
              (geoPoint) {
                _userController.updatePosition(geoPoint);
              },
              onError: (err) {
                print("Errore stream posizione: $err");
                stopPositionTracking(); // Evita crash quando permessi cambiano
              },
              cancelOnError: true,
            );
  }

  // Ferma lo stream
  void stopPositionTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Resetta la posizione utente su Firebase
  Future<void> resetPositionOnAppEnter() async {
    final user = _userController.currentUser;
    if (user == null) return;

    await _firebaseServices.updateUserPosition(user.uid, const GeoPoint(0, 0));
  }

  UserModel? get currentUser => _userController.currentUser;
}
