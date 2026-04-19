import 'package:flutter/material.dart';
import '../controllers/my_events_controller.dart';
import '../models/event_model.dart';
import 'media_events_view.dart';
import 'event_news_page.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  final MyEventsController _controller = MyEventsController();

  // Funzione per determinare lo stato dell'evento
  String getEventStatus(EventModel e) {
    final now = DateTime.now();
    final start = e.data;
    final end = e.data.add(const Duration(hours: 5)); // Durata stimata evento

    if (now.isBefore(start)) return "FUTURO";
    if (now.isAfter(end)) return "TERMINATO";
    return "LIVE";
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "LIVE":
        return Colors.red;
      case "FUTURO":
        return Colors.blue;
      case "TERMINATO":
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  // Funzione che permette di mostrare le opzioni dell'evento
  void _showEventOptions(EventModel event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                _option(
                  icon: Icons.photo_library,
                  text: "Mostra Media",
                  color: Colors.lightBlueAccent,
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MediaEventView.mediaEventView(
                          event: event,
                          controller: _controller,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _option(
                  icon: Icons.article,
                  text: "Mostra News",
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventNewsPage(event: event),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget riutilizzabile per le opzioni
  Widget _option({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white60),
          ],
        ),
      ),
    );
  }


  Widget _eventTile(EventModel e, String status, bool hasUnreadNews) {
    return GestureDetector(
      onTap: () {
        _showEventOptions(e);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Row(
          children: [
            Stack(
              children: [
                const Icon(Icons.event, color: Colors.blue, size: 32),
                if (hasUnreadNews)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.titolo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${e.data.day.toString().padLeft(2, '0')}/"
                    "${e.data.month.toString().padLeft(2, '0')} • "
                    "${e.data.hour.toString().padLeft(2, '0')}:"
                    "${e.data.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.white70, fontSize: 17),
                  ),
                ],
              ),
            ),
            _statusChip(status),
            const Icon(Icons.chevron_right, color: Colors.white60),
          ],
        ),
      ),
    );
  }

  // Restituisce stato evento
  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: _controller.subscribedEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Non sei iscritto a nessun evento"));
        }

        final events = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            final status = getEventStatus(e);

            // StreamBuilder per verificare se ci sono news non lette
            return StreamBuilder<bool>(
              stream: _controller.hasUnreadNews(e.id),
              initialData: false,
              builder: (context, snapshot) {
                final hasUnread = snapshot.data ?? false;
                return _eventTile(e, status, hasUnread);
              },
            );
          },
        );
      },
    );
  }
}
