import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

// Questa classe viene usata come fallback di AROverlayNavigation (viene aperto maps)
class NavigationService {
  static Future<void> open({required double lat, required double lng}) async {
    final uri = Platform.isAndroid
        ? Uri.parse(
            "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking",
          )
        : Uri.parse("http://maps.apple.com/?daddr=$lat,$lng&dirflg=w");

    final canLaunch = await canLaunchUrl(uri);

    if (!canLaunch) {
      throw 'Impossibile aprire $uri';
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> openMap({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
