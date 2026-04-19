import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vibevent/controllers/user_controller.dart';
import '../controllers/mainview_controller.dart';
import '../controllers/my_events_controller.dart';
import '../services/geolocator_services.dart';
import 'home_page.dart';
import 'my_events_page.dart';
import 'live_page.dart';
import 'profile_page.dart';
import 'location_permession_screen_view.dart';
import 'package:vibevent/services/notification_services.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with WidgetsBindingObserver {
  int currentIndex = 0;
  final List<Widget> pages = const [
    HomePage(),
    MyEventsPage(),
    LivePage(),
    ProfilePage(),
  ];

  late final UserController _userController;
  late final GeolocatorServices _geoService;
  late final MainviewController _mainviewController;

  // Variabili per notifica News
  late final MyEventsController _eventsController;
  late final Stream<bool> _hasUnreadNewsStream;

  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _userController = UserController();
    _geoService = GeolocatorServices();
    _mainviewController = MainviewController(_geoService, _userController);
    _eventsController = MyEventsController(); // inizializzazione

    _initLocationFlow();
    _initNotifications();

    // Stream globale per pallino BottomNavigationBar
    _hasUnreadNewsStream = _eventsController
        .subscribedEventsStream()
        .switchMap((events) {
          if (events.isEmpty) return Stream.value(false);
          final streams = events.map(
            (e) => _eventsController.hasUnreadNews(e.id),
          );
          return Rx.combineLatestList<bool>(
            streams.toList(),
          ).map((list) => list.any((b) => b));
        })
        .startWith(false);
  }

  Future<void> _initNotifications() async {
    // aspetta che l'utente sia in memoria
    final user = _userController.currentUser;
    if (user == null) return;

    await NotificationService.instance.init(context);
    if (!mounted) return;

    // Subscribe a tutti gli eventi già iscritti (copre reinstall/cambio telefono)
    for (final eventId in user.eventiIscritti) {
      await NotificationService.instance.subscribeToEvent(eventId);
    }
    if (!mounted) return;
  }

  // Resetta posizione all'accesso, chiama check sui permessi e starta position track
  Future<void> _initLocationFlow() async {
    await _mainviewController.resetPositionOnAppEnter();
    await _checkPermissionsAndStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mainviewController.stopPositionTracking();
    super.dispose();
  }

  // Check permessi posizione e start position track
  Future<void> _checkPermissionsAndStart() async {
    final permissionStatus = await _geoService.checkGeolocatorPermission();
    final gpsStatus = await _geoService.checkGpsPermissions();

    if (permissionStatus != LocationStatus.granted ||
        gpsStatus != LocationStatus.granted) {
      if (permissionStatus == LocationStatus.deniedForever) {
        setState(() => _permissionsGranted = false);
        return;
      }
      final newPermission = await Geolocator.requestPermission();
      if (newPermission != LocationPermission.always &&
          newPermission != LocationPermission.whileInUse) {
        setState(() => _permissionsGranted = false);
        return;
      }
    }

    setState(() => _permissionsGranted = true);
    _mainviewController.startPositionTracking();
  }

  // Quando l'app torna in foreground richiama _checkPermissionsAndStart();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndStart();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _mainviewController.stopPositionTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Se _permissionsGranted è true allora mostra il body
      // Altrimenti mostra LocationPermissionScreenView()
      body: _permissionsGranted
          ? Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                IndexedStack(index: currentIndex, children: pages),
              ],
            )
          : const LocationPermissionScreenView(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.lightBlueAccent,
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30),
            label: "Home",
          ),

          // icona myEvents con StreamBuilder e pallino rosso
          BottomNavigationBarItem(
            icon: StreamBuilder<bool>(
              stream: _hasUnreadNewsStream,
              initialData: false,
              builder: (context, snapshot) {
                final hasUnread = snapshot.data ?? false;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.event, size: 30),
                    if (hasUnread)
                      Positioned(
                        top: -2,
                        right: -2,
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
                );
              },
            ),
            label: "I Miei Eventi",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.live_tv, size: 30),
            label: "Live",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 30),
            label: "Profilo",
          ),
        ],
      ),
    );
  }
}
