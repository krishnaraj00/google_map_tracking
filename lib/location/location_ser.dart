import 'dart:async';
import 'package:geolocator/geolocator.dart';

import '../data_base/app_db.dart';


class LocationService {
  final AppDatabase db;
  final String routeId;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  LocationService({required this.db, required this.routeId});

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    );
  }

  Future<void> startForegroundTracking() async {
    if (_isTracking) {
      print('Tracking already active');
      return;
    }

    try {
      print('Starting location tracking...');
      _isTracking = true;

      // Start location stream for immediate updates
      _positionStream = getPositionStream().listen(
            (Position position) async {
          print('Location update: ${position.latitude}, ${position.longitude}');
          await _saveLocation(position);
        },
        onError: (error) {
          print('Location stream error: $error');
        },
      );

      print('Location tracking started successfully');
    } catch (e) {
      print('Error starting location tracking: $e');
      _isTracking = false;
      rethrow;
    }
  }

  Future<void> stopForegroundTracking() async {
    if (!_isTracking) {
      print('Tracking not active');
      return;
    }

    try {
      print('Stopping location tracking...');
      _isTracking = false;

      // Stop location stream
      await _positionStream?.cancel();
      _positionStream = null;

      print('Location tracking stopped successfully');
    } catch (e) {
      print('Error stopping location tracking: $e');
      rethrow;
    }
  }

  Future<void> _saveLocation(Position position) async {
    try {
      await db.insertPoint(
        LocationPointsCompanion.insert(
          latitude: position.latitude,
          longitude: position.longitude,
          routeId: routeId,
        ),
      );
      print(
        'Location saved to database: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('Error saving location to database: $e');
    }
  }

  Future<List<LocationPoint>> getRoutePoints() async {
    return await db.getPointsByRoute(routeId);
  }

  bool get isTracking => _isTracking;
}