import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'user_service.dart';
import 'auth_service.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isTracking = false;
  Timer? _locationTimer;
  
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isTracking => _isTracking;

  // Auto-update location every 5 minutes
  static const Duration _updateInterval = Duration(minutes: 5);

  Future<bool> startLocationTracking(AuthService authService, UserService userService) async {
    if (_isTracking) return true;

    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get initial location
    await _updateLocation(authService, userService);
    
    // Start periodic updates
    _isTracking = true;
    _locationTimer = Timer.periodic(_updateInterval, (timer) {
      _updateLocation(authService, userService);
    });
    
    notifyListeners();
    return true;
  }

  Future<void> _updateLocation(AuthService authService, UserService userService) async {
    try {
      // Get current GPS position (high accuracy)
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address from coordinates
      _currentAddress = await _getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Update backend with real GPS coordinates
      if (authService.token != null) {
        await userService.updateLocation(
          authService.token!,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _currentAddress,
        );
      }

      notifyListeners();
      print('Location updated: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      
    } catch (e) {
      print('Failed to update location: $e');
    }
  }

  Future<String?> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
      }
      return 'Unknown Location';
    } catch (e) {
      return 'Unknown Location';
    }
  }

  void stopLocationTracking() {
    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;
    notifyListeners();
  }

  // Force immediate location update
  Future<void> forceLocationUpdate(AuthService authService, UserService userService) async {
    if (!_isTracking) return;
    await _updateLocation(authService, userService);
  }

  // Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // in km
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}