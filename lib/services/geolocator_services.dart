import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus { granted, denied, deniedForever, gpsOff }

class GeolocatorServices {
  Future<LocationStatus> checkGeolocatorPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      return LocationStatus.denied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationStatus.deniedForever;
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return LocationStatus.granted;
    }

    // fallback per sicurezza
    return LocationStatus.denied;
  }

  Future<LocationStatus> checkGpsPermissions() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    return isEnabled ? LocationStatus.granted : LocationStatus.gpsOff;
  }

  // Stream posizione in tempo reale
  Stream<GeoPoint> getPositionStream({int distanceFilter = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilter,
      ),
    ).map((pos) => GeoPoint(pos.latitude, pos.longitude));
  }
}
