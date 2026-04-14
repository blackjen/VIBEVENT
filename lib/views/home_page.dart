import 'package:flutter/material.dart';
import 'package:vibevent/controllers/user_controller.dart';
import '../controllers/home_controller.dart';
import '../models/event_model.dart';
import '../utils/error_&_result.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _homeController = HomeController();
  final UserController _userController = UserController();
  final TextEditingController _searchController = TextEditingController();

  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  bool _loading = false;
  bool _hasSearched = false;

  EventSortType _sortType = EventSortType.timeNearest;

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      final events = await _homeController.searchEvents();
      if (!mounted) return;

      setState(() {
        _allEvents = events;
      });

      _applyFiltersAndSort();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore nel caricamento eventi")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFiltersAndSort() {
    final filtered = _homeController.filterAndSortEvents(
      _allEvents,
      _searchController.text,
      _sortType,
    );

    setState(() {
      _filteredEvents = filtered;
    });
  }

  String _mapError(EventError error) {
    switch (error) {
      case EventError.notLogged:
        return "Devi effettuare il login";
      case EventError.tooEarly:
        return "Puoi iscriverti solo nelle 2 ore prima dell'evento";
      case EventError.permissionDenied:
        return "Devi consentire l'accesso alla posizione";
      case EventError.locationUnavailable:
        return "Posizione non disponibile";
      case EventError.tooFar:
        return "Devi essere entro 200 metri dall'evento";
      default:
        return "Errore durante l'iscrizione";
    }
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFiltersAndSort(),
        decoration: InputDecoration(
          hintText: "Cerca evento per nome",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSortSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<EventSortType>(
          value: _sortType,
          isExpanded: true,
          underline: const SizedBox(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _sortType = value;
            });

            _applyFiltersAndSort();
          },
          items: const [
            DropdownMenuItem(
              value: EventSortType.timeNearest,
              child: Text("Ordina per tempo"),
            ),
            DropdownMenuItem(
              value: EventSortType.distanceNearest,
              child: Text("Ordina per distanza"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (!_hasSearched) {
      return const Center(
        child: Text(
          'Premi "Trova Evento" per cercare',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_filteredEvents.isEmpty) {
      return const Center(
        child: Text(
          "Nessun evento trovato",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];
        final localDate = event.data.toLocal();
        final isIscritto =
            _userController.currentUser?.eventiIscritti.contains(event.id) ??
                false;
        final distance = _homeController.getDistanceFromUser(event);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.titolo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(event.descrizione),
                      const SizedBox(height: 6),
                      Text(
                        "${localDate.day}/${localDate.month}/${localDate.year} "
                            "${localDate.hour.toString().padLeft(2, '0')}:"
                            "${localDate.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "$distance km",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isIscritto
                      ? null
                      : () async {
                    final result = await _homeController.iscriviEvento(
                      event,
                    );

                    if (!result.isSuccess) {
                      final message = _mapError(result.error!);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    } else {
                      setState(() {});
                    }
                  },
                  child: Text(isIscritto ? "Iscritto" : "Accedi"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // Libera TextEditingController quando la pagina viene distrutta
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox.expand(
        child: Column(
          children: [
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _loading ? null : _loadEvents,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text(
                    "Trova\nEvento",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      color: Color(0xFF2575FC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildSearchField(),
            const SizedBox(height: 20),
            _buildSortSelector(),
            const SizedBox(height: 20),

            Expanded(child: _buildEventsList()),
          ],
        ),
      ),
    );
  }
}