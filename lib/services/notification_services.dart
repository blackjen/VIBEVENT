import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Singleton
class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init(BuildContext context) async {
    await _messaging.requestPermission();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // App APERTA → banner interno
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? "Notifica";
      final body = message.notification?.body ?? "";

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$title\n$body"),
          duration: const Duration(seconds: 4),
        ),
      );
    });

    // App in background, tap notifica
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final eventId = message.data['eventId'];
      if (eventId != null && context.mounted) {
        Navigator.pushNamed(context, "/eventNews", arguments: eventId);
      }
    });

    // App chiusa, apertura da notifica
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && context.mounted) {
      final eventId = initialMessage.data['eventId'];
      if (eventId != null) {
        Navigator.pushNamed(context, "/eventNews", arguments: eventId);
      }
    }
  }

  String _sanitize(String eventId) {
    return eventId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  Future<void> subscribeToEvent(String eventId) async {
    final safeId = _sanitize(eventId);
    await _messaging.subscribeToTopic("event_$safeId");
  }

  Future<void> unsubscribeFromEvent(String eventId) async {
    final safeId = _sanitize(eventId);
    await _messaging.unsubscribeFromTopic("event_$safeId");
  }
}
