import 'package:intl/intl.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import 'package:vibevent/controllers/user_controller.dart';
import 'package:vibevent/models/event_chat_model.dart';
import 'package:vibevent/models/event_news_model.dart';
import 'package:vibevent/services/event_location_services.dart';
import '../models/event_location_model.dart';
import '../models/event_model.dart';
import '../services/event_chat_services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/event_news_services.dart';

class LiveController {
  final ChatServices _chatServices = ChatServices();
  final UserController _userController = UserController();
  final EventLocationServices _eventLocationServices = EventLocationServices();
  final EventNewsServices _newsServices = EventNewsServices();


  String? get currentUserId => _userController.currentUser?.uid;

  bool canAccessLive(EventModel event) {
    final now = DateTime.now();
    return now.isAfter(event.data) &&
        now.isBefore(event.data.add(const Duration(hours: 5)));
  }

  Stream<List<EventNewsModel>> streamEventNews(String eventId) {
    return _newsServices.getEventNews(eventId);
  }

  Stream<List<EventLocation>> streamEventLocations(String eventId) {
    return _eventLocationServices.getEventLocations(eventId);
  }

  Stream<List<ChatModel>> streamChat(String eventId) {
    return _chatServices.getMessages(eventId);
  }

  Duration? getCountdown(EventModel event) {
    final now = DateTime.now();
    if (now.isBefore(event.data)) {
      return event.data.difference(now);
    }
    return null;
  }

  // Ritorna il prossimo evento valido di oggi
  EventModel? getNextUpcomingEvent(List<EventModel> events) {
    final now = DateTime.now();

    final upcoming =
        events
            .where((e) => now.isBefore(e.data.add(const Duration(hours: 5))))
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));

    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  // Ritorna gli altri eventi escluso l'evento principale
  List<EventModel> getOtherUpcomingEvents(
    List<EventModel> events,
    EventModel mainEvent,
  ) {
    final now = DateTime.now();

    return events
        .where(
          (e) =>
              e.id != mainEvent.id &&
              now.isBefore(e.data.add(const Duration(hours: 5))),
        )
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
  }

  // Ritorna la data da mostrare al countdown
  String formatCountdown(Duration remaining) {
    if (remaining.inDays >= 2) {
      return "Tra ${remaining.inDays} giorni";
    }

    if (remaining.inDays == 1) {
      return "Domani";
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    return "Tra ${hours}h ${minutes}m";
  }


  // Ritorna il tipo di data dell'evento
  String formatEventDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return "Oggi alle ${DateFormat('HH:mm').format(date)}";
    }

    if (diff.inDays == 1) {
      return "Domani alle ${DateFormat('HH:mm').format(date)}";
    }

    if (diff.inDays < 7) {
      return DateFormat("EEEE 'alle' HH:mm", "it_IT").format(date);
    }

    return DateFormat("d MMM 'alle' HH:mm", "it_IT").format(date);
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Invia foto o video
  Future<void> sendCameraMedia(
    EventModel event,
    XFile file,
    String type,
  ) async {
    final user = _userController.currentUser!;

    final url = await uploadMediaToSupabase(file);

    if (url == null) return;

    final message = ChatModel(
      id: '',
      senderId: user.uid,
      senderName: user.nome,
      type: type,
      content: url,
      timestamp: DateTime.now(),
    );

    await _chatServices.sendMessage(event.id, message);
  }

  // Carica il media su Supabase e ritorna l'URL
  Future<String?> uploadMediaToSupabase(XFile file) async {
    final storage = Supabase.instance.client.storage.from('vibevent_storage');

    final fileExt = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    final mimeType = lookupMimeType(file.path);

    final fileData = File(file.path);

    await storage.upload(
      fileName,
      fileData,
      fileOptions: FileOptions(upsert: true, contentType: mimeType),
    );

    final publicUrl = storage.getPublicUrl(fileName);

    return publicUrl;
  }
}
