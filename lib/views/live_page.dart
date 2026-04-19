import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibevent/controllers/live_controller.dart';
import 'package:vibevent/controllers/user_controller.dart';
import 'package:vibevent/models/event_chat_model.dart';
import 'package:vibevent/models/event_model.dart';
import 'package:vibevent/views/video_screen.dart';
import '../models/event_location_model.dart';
import '../services/ar_overlay_navigation.dart';
import 'event_news_page.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => LivePageState();
}

class LivePageState extends State<LivePage> {
  final LiveController _controller = LiveController();
  final UserController _userController = UserController();

  EventModel? _selectedEvent; // Evento attualmente selezionato
  List<EventModel> _todayEvents = [];

  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
  }

  void _updateRemaining() {
    if (_selectedEvent == null) return;
    final countdown = _controller.getCountdown(_selectedEvent!);
    setState(() {
      _remaining = countdown ?? Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: _userController.eventiIscrittiCompletiStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Errore caricamento eventi: ${snapshot.error}"),
          );
        }

        final events = snapshot.data ?? [];
        _todayEvents = events;

        // Primo evento valido di oggi
        final firstEvent = _controller.getNextUpcomingEvent(events);

        // Se l'evento selezionato non è più nella lista, resetto
        if (_selectedEvent == null ||
            !events.any((e) => e.id == _selectedEvent!.id)) {
          _selectedEvent = firstEvent;
          // Aggiorna remaining senza chiamare setState durante la build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateRemaining();
          });
        }

        if (_selectedEvent == null) {
          return const Center(
            child: Text(
              "Nessun evento programmato in giornata\nLive Chat non disponibile",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.white70),
            ),
          );
        }

        return Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 60),
                _buildEventMenu(_selectedEvent!, _todayEvents),
                if (!_controller.canAccessLive(_selectedEvent!))
                  Expanded(
                    child: Center(
                      child: _buildCountdownOrLive(_selectedEvent!),
                    ),
                  ),

                if (_controller.canAccessLive(_selectedEvent!))
                  Expanded(child: _buildLive(_selectedEvent!)),
              ],
            ),

            // Pulsante Refresh manuale SOLO se la live non è ancora accessibile
            if (!_controller.canAccessLive(_selectedEvent!))
              Positioned(
                bottom: 16,
                left: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.blueAccent,
                  onPressed: _updateRemaining,
                  child: const Icon(Icons.refresh, size: 20),
                ),
              ),
          ],
        );
      },
    );
  }

  // ===================== LIVE CHAT =====================
  Widget _buildLive(EventModel event) {
    return SafeArea(
      child: Column(
        children: [_buildHeader(event), _buildChat(event), _buildInput(event)],
      ),
    );
  }

  Widget _buildHeader(EventModel event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black26,
      width: double.infinity,
      child: Text(
        "${event.titolo} Live",
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildChat(EventModel event) {
    return Expanded(
      child: StreamBuilder<List<ChatModel>>(
        stream: _controller.streamChat(event.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data ?? [];
          if (messages.isEmpty) {
            return const Center(
              child: Text(
                "Nessuna foto/video",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: messages.length,
            itemBuilder: (_, index) => _buildMessage(messages[index]),
          );
        },
      ),
    );
  }

  Widget _buildMessage(ChatModel msg) {
    final bool isMe = msg.senderId == _controller.currentUserId;

    Widget contentWidget;

    switch (msg.type) {
      case "image":
        contentWidget = GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(child: Image.network(msg.content)),
                ),
              ),
            );
          },
          child: Image.network(msg.content, width: 200),
        );
        break;
      case "video":
        contentWidget = GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VideoScreen(url: msg.content)),
            );
          },
          child: Container(
            width: 200,
            height: 150,
            color: Colors.black,
            child: const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
        );
        break;
      default:
        contentWidget = const SizedBox();
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.senderName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            contentWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildInput(EventModel event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.black12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.green, size: 32),
            onPressed: () => _openCameraAndSend(event),
          ),
        ],
      ),
    );
  }

  // Ritorna i 3 pulsanti dell'evento
  Widget _buildEventMenu(EventModel event, List<EventModel> events) {
    final otherEvents = _controller.getOtherUpcomingEvents(events, event);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      color: Colors.black12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pulsante SCEGLI ALTRO EVENTO
          if (otherEvents.isNotEmpty) ...[
            ElevatedButton(
              onPressed: () {
                _showEventPicker(otherEvents);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
              child: const Text("SCEGLI ALTRO EVENTO"),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventNewsPage(event: _selectedEvent!),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                  ),
                  child: const Text(
                    "INFO EVENTO",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showLocations(_selectedEvent!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                  ),
                  child: const Text(
                    "PUNTI DI INTERESSE",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ===================== COUNTDOWN / LIVE =====================
  Widget _buildCountdownOrLive(EventModel event) {
    if (_remaining > Duration.zero) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              event.titolo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Inizio live ${_controller.formatCountdown(_remaining)}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: Colors.white70),
            ),
          ],
        ),
      );
    } else if (_controller.canAccessLive(event)) {
      return const SizedBox.shrink(); // Mostra subito la live chat
    } else {
      return _buildNoLive();
    }
  }

  Widget _buildNoLive() {
    return const Center(
      child: Text(
        "Nessun evento in corso\nLiveChat non disponibile",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, color: Colors.white70),
      ),
    );
  }

  // Permette di scegliere un evento tra quelli dello stesso giorno
  void _showEventPicker(List<EventModel> events) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Scegli evento"),
        children: events.map((event) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedEvent = event;
                _updateRemaining();
              });
            },
            child: Text(
              "${event.titolo} – ${_controller.formatEventDate(event.data)}",
            ),
          );
        }).toList(),
      ),
    );
  }

  // Mostra i Punti Di Interesse dell'evento
  void _showLocations(EventModel event) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StreamBuilder<List<EventLocation>>(
          stream: _controller.streamEventLocations(event.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final locations = snapshot.data ?? [];

            if (locations.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    "Nessun punto di interesse",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }

            final sortedLocations =
                locations.map((loc) {
                  final distance = Geolocator.distanceBetween(
                    _userController.getPosition()!.latitude,
                    _userController.getPosition()!.longitude,
                    loc.lat,
                    loc.lng,
                  );

                  return {"location": loc, "distance": distance};
                }).toList()..sort(
                  (a, b) => (a["distance"] as double).compareTo(
                    b["distance"] as double,
                  ),
                );

            return ListView.builder(
              shrinkWrap: true,
              itemCount: sortedLocations.length,
              itemBuilder: (_, index) {
                final loc = sortedLocations[index]["location"] as EventLocation;
                final distance = sortedLocations[index]["distance"] as double;

                return ListTile(
                  title: Text(
                    loc.titolo,
                    style: const TextStyle(color: Colors.white),
                  ),

                  trailing: Text(
                    "${distance.toStringAsFixed(0)} m",
                    style: const TextStyle(
                      color: Colors.lightGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  leading: const Icon(Icons.location_on, color: Colors.orange),

                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AROverlayNavigation(
                          targetLat: loc.lat,
                          targetLng: loc.lng,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Apre fotocamera e manda foto/video nella chat
  Future<void> _openCameraAndSend(EventModel event) async {
    final picker = ImagePicker();
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Scegli tipo di media"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, "image"),
            child: const Text("Foto"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, "video"),
            child: const Text("Video"),
          ),
        ],
      ),
    );

    if (choice == null) return;

    XFile? file;
    if (choice == "image") {
      file = await picker.pickImage(source: ImageSource.camera);
    } else {
      file = await picker.pickVideo(source: ImageSource.camera);
    }

    if (file != null) {
      await _controller.sendCameraMedia(event, file, choice);
    }
  }
}
