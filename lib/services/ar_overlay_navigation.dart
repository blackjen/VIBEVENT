import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'navigation_services.dart';

class AROverlayNavigation extends StatefulWidget {
  final double targetLat;
  final double targetLng;

  const AROverlayNavigation({
    super.key,
    required this.targetLat,
    required this.targetLng,
  });

  @override
  State<AROverlayNavigation> createState() => _AROverlayNavigationState();
}

class _AROverlayNavigationState extends State<AROverlayNavigation> {
  CameraController? _cameraController;

  double _bearingToTarget = 0; // direzione GPS
  double _heading = 0;         // bussola telefono
  double _distance = 0;        // distanza in metri

  Timer? _gpsTimer;
  StreamSubscription<CompassEvent>? _compassSub;

  static const double maxDistance = 200; // LIMITE 200 METRI

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startCompass();
    _startGpsUpdates();
  }

  // FOTOCAMERA
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    setState(() {});
  }

  // BUSSOLA
  void _startCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        setState(() => _heading = event.heading!);
      }
    });
  }

  // GPS
  void _startGpsUpdates() {
    _updateNavigation();
    _gpsTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _updateNavigation(),
    );
  }

  Future<void> _updateNavigation() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      widget.targetLat,
      widget.targetLng,
    );

    // Se sei troppo lontano → fallback su mappe
    if (distance > maxDistance) {
      if (mounted) {
        Navigator.pop(context); // chiudi AR
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sei troppo lontano per AR. Apro maps"),
          ),
        );

        // fallback su NavigationService
        await NavigationService.open(
          lat: widget.targetLat,
          lng: widget.targetLng,
        );
      }
      return;
    }

    final bearing = _calculateBearing(
      pos.latitude,
      pos.longitude,
      widget.targetLat,
      widget.targetLng,
    );

    setState(() {
      _bearingToTarget = bearing;
      _distance = distance;
    });
  }


  double _calculateBearing(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      ) {
    final startLatRad = startLat * math.pi / 180;
    final startLngRad = startLng * math.pi / 180;
    final endLatRad = endLat * math.pi / 180;
    final endLngRad = endLng * math.pi / 180;

    final dLon = endLngRad - startLngRad;

    final y = math.sin(dLon) * math.cos(endLatRad);
    final x = math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) *
            math.cos(endLatRad) *
            math.cos(dLon);

    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  // DISPOSE
  @override
  void dispose() {
    _cameraController?.dispose();
    _gpsTimer?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ROTAZIONE AR
    final double rotationAngle =
    ((_bearingToTarget - _heading) * math.pi / 180);

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController!), // CAMERA LIVE

          // FRECCIA AR
          Center(
            child: Transform.rotate(
              angle: rotationAngle,
              child: const Icon(
                Icons.navigation,
                size: 100,
                color: Colors.redAccent,
              ),
            ),
          ),

          // DISTANZA
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_distance.toStringAsFixed(1)} m",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // FRECCIA INDIETRO
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context), // Torna indietro
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }
}
