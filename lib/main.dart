import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:project/permissions/google_map_per.dart';
import 'package:project/permissions/location_his.dart';
import 'package:uuid/uuid.dart';

import 'data_base/app_db.dart';
import 'location/location_ser.dart';
import 'map/google_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AppDatabase db;
  LocationService? locationService;
  String? routeId;
  bool _isTracking = false;
  bool _isInitialized = false;
  String? _permissionError;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    db = AppDatabase(driftDatabase(name: 'app'));
    _init();
  }

  Future<void> _init() async {
    try {
      final permissionsGranted = await PermissionHelper.requestPermissions();
      if (permissionsGranted) {
        routeId = const Uuid().v4();
        locationService = LocationService(db: db, routeId: routeId!);
        setState(() {
          _isInitialized = true;
          _permissionError = null;
        });
      } else {
        setState(() {
          _isInitialized = true;
          _permissionError = 'Location permissions are required to track your route.';
        });
      }
    } catch (e) {
      setState(() {
        _isInitialized = true;
        _permissionError = 'Error initializing app: $e';
      });
    }
  }

  Future<void> _retryPermissions() async {
    setState(() {
      _permissionError = null;
    });
    await _init();
  }

  Future<void> _startTracking() async {
    if (locationService != null && !_isTracking) {
      try {
        await locationService!.startForegroundTracking();
        setState(() {
          _isTracking = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting tracking: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _stopTracking() async {
    if (locationService != null && _isTracking) {
      try {
        await locationService!.stopForegroundTracking();
        setState(() {
          _isTracking = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error stopping tracking: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _openHistory() {
    _navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => LocationHistoryScreen(database: db)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    locationService?.stopForegroundTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isTracking && locationService != null) {
      locationService!.startForegroundTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Background Geolocation Tracker',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      navigatorKey: _navigatorKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Live Route Tracker'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            if (_isInitialized)
              IconButton(icon: const Icon(Icons.history), onPressed: _openHistory, tooltip: 'View History'),
            if (_isInitialized && locationService != null)
              IconButton(
                icon: Icon(_isTracking ? Icons.stop_circle_outlined : Icons.play_circle_fill_outlined),
                onPressed: _isTracking ? _stopTracking : _startTracking,
                tooltip: _isTracking ? 'Stop Tracking' : 'Start Tracking',
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Location Permission Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_permissionError!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: _retryPermissions, icon: const Icon(Icons.refresh), label: const Text('Retry Permissions')),
              TextButton.icon(
                onPressed: () async => await PermissionHelper.openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Open App Settings'),
              ),
            ],
          ),
        ),
      );
    }

    if (locationService == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Location service not available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Please restart the app', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isTracking ? [Colors.green.shade400, Colors.green.shade700] : [Colors.grey.shade300, Colors.grey.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(_isTracking ? Icons.location_on : Icons.location_off, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                _isTracking ? 'Tracking Active' : 'Tracking Stopped',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_isTracking)
                const Chip(
                  label: Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.red,
                ),
            ],
          ),
        ),
        Expanded(
          child: routeId != null
              ? GoogleMapWidget(pointsStream: db.watchPointsByRoute(routeId!))
              : const Center(child: Text('No route data', style: TextStyle(fontSize: 16))),
        ),
      ],
    );
  }
}
