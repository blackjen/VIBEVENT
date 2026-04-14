import 'package:vibevent/models/event_news_model.dart';
import '../controllers/live_controller.dart';
import '../controllers/user_controller.dart';
import '../models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventNewsPage extends StatelessWidget {
  final EventModel event;
  final LiveController _controller = LiveController();
  final UserController _userController = UserController();

  EventNewsPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {

    // Segna le news come lette appena apro la pagina
    _userController.markEventNewsAsRead(event.id);

    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.lightBlueAccent,

        title: Text(
          "News • ${event.titolo}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: StreamBuilder<List<EventNewsModel>>(
          stream: _controller.streamEventNews(event.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final news = snapshot.data ?? [];

            if (news.isEmpty) {
              return const Center(
                child: Text(
                  "Nessuna news disponibile",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: news.length,
              itemBuilder: (_, index) {
                final n = news[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.titolo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          n.contenuto,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('d MMM HH:mm', 'it_IT').format(n.data),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
