import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionScreenView extends StatelessWidget {
  const LocationPermissionScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "Consenti i permessi di localizzazione per poter continuare",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                },
                child: const Text("Apri impostazioni"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
