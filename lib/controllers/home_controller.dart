import 'dart:math';
import 'package:vibevent/controllers/user_controller.dart';
import '../models/event_model.dart';
import '../services/firebase_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/error_&_result.dart';

enum EventSortType { timeNearest, distanceNearest }

class HomeController {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final UserController _userController = UserController();

  Future<List<EventModel>> searchEvents() async {
    return await _firebaseServices.getEventsFromToday();
  }

  double _calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000; // Metri

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  List<EventModel> sortEvents(List<EventModel> events, EventSortType sortType) {
    final sorted = List<EventModel>.from(events);

    switch (sortType) {
      case EventSortType.timeNearest:
        sorted.sort((a, b) => a.data.compareTo(b.data));
        break;

      case EventSortType.distanceNearest:
        final user = _userController.currentUser;
        if (user == null) {
          return sorted;
        }

        final userPos = user.posizione;
        if (userPos.latitude == 0 && userPos.longitude == 0) {
          return sorted;
        }

        sorted.sort((a, b) {
          final distanceA = _calculateDistanceInMeters(
            userPos.latitude,
            userPos.longitude,
            a.posizione.latitude,
            a.posizione.longitude,
          );

          final distanceB = _calculateDistanceInMeters(
            userPos.latitude,
            userPos.longitude,
            b.posizione.latitude,
            b.posizione.longitude,
          );

          return distanceA.compareTo(distanceB);
        });
        break;
    }

    return sorted;
  }

  int? getDistanceFromUser(EventModel event) {
    final user = _userController.currentUser;
    if (user == null) return null;

    final userPos = user.posizione;
    if (userPos.latitude == 0 && userPos.longitude == 0) {
      return null;
    }

    final meters = _calculateDistanceInMeters(
      userPos.latitude,
      userPos.longitude,
      event.posizione.latitude,
      event.posizione.longitude,
    );

    return (meters / 1000).truncate();

  }

  Future<Result<void>> iscriviEvento(EventModel evento) async {
    final user = _userController.currentUser;
    if (user == null) {
      return Result.failure(EventError.notLogged);
    }

    final now = DateTime.now();
    final diff = evento.data.difference(now);
    if (diff.inMinutes > 120) {
      return Result.failure(EventError.tooEarly);
    }

    final permission = await Permission.location.status;
    if (!permission.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        return Result.failure(EventError.permissionDenied);
      }
    }

    final GeoPoint userPos = user.posizione;
    if (userPos.latitude == 0 && userPos.longitude == 0) {
      return Result.failure(EventError.locationUnavailable);
    }

    final distance = _calculateDistanceInMeters(
      userPos.latitude,
      userPos.longitude,
      evento.posizione.latitude,
      evento.posizione.longitude,
    );

    if (distance > 200) {
      return Result.failure(EventError.tooFar);
    }

    await _firebaseServices.iscriviEvento(user.uid, evento.id);

    if (!user.eventiIscritti.contains(evento.id)) {
      user.eventiIscritti.add(evento.id);
    }

    return Result.success(null);
  }

  List<EventModel> filterAndSortEvents(
      List<EventModel> events,
      String query,
      EventSortType sortType,
      ) {
    final lowerQuery = query.trim().toLowerCase();

    List<EventModel> filtered = events.where((event) {
      return event.titolo.toLowerCase().contains(lowerQuery);
    }).toList();

    return sortEvents(filtered, sortType);
  }

}
