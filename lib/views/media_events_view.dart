import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../controllers/my_events_controller.dart';
import '../models/event_model.dart';
import '../models/event_chat_model.dart';

class MediaEventView extends StatefulWidget {
  final EventModel event;
  final MyEventsController controller;

  const MediaEventView.mediaEventView({
    super.key,
    required this.event,
    required this.controller,
  });

  @override
  State<MediaEventView> createState() => _MediaEventViewState();
}

class _MediaEventViewState extends State<MediaEventView> {
  final Map<String, VideoPlayerController> _videoControllers = {};

  @override
  void dispose() {
    for (var c in _videoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.lightBlueAccent,
        title: Text(
          "Media • ${widget.event.titolo}",
          style: const TextStyle(fontWeight: FontWeight.bold),
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

        child: StreamBuilder<List<ChatModel>>(
          stream: widget.controller.getMediaForEvent(widget.event.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final media = snapshot.data!;

            if (media.isEmpty) {
              return const Center(
                child: Text(
                  "Nessun media nella live",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: media.length,
              itemBuilder: (_, index) {
                final m = media[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildMedia(m),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMedia(ChatModel media) {
    if (media.type == "image") {
      return Image.network(
        media.content,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
      );
    }

    if (!_videoControllers.containsKey(media.content)) {
      final controller = VideoPlayerController.network(media.content)
        ..initialize().then((_) => setState(() {}));

      _videoControllers[media.content] = controller;
    }

    final controller = _videoControllers[media.content]!;

    if (!controller.value.isInitialized) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          controller.value.isPlaying ? controller.pause() : controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),

          if (!controller.value.isPlaying)
            const Icon(Icons.play_circle_fill, size: 70, color: Colors.white70),
        ],
      ),
    );
  }
}
