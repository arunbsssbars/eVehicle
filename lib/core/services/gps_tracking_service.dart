import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed;
  final double? altitude;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.altitude,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'accuracy': accuracy,
        'speed': speed,
        'altitude': altitude,
      };

  factory LocationPoint.fromPosition(Position p) => LocationPoint(
        latitude: p.latitude,
        longitude: p.longitude,
        timestamp: p.timestamp,
        accuracy: p.accuracy,
        speed: p.speed,
        altitude: p.altitude,
      );
}

class GpsTrackingService {
  GpsTrackingService._internal();
  static final GpsTrackingService instance = GpsTrackingService._internal();

  bool _isPermissionGranted = false;
  bool _isTracking = false;
  DateTime? _trackingStartTime;
  double _accumulatedDistanceKm = 0.0;
  LocationPoint? _lastPoint;
  Position? _lastGpsPosition;

  StreamSubscription<Position>? _positionStreamSub;
  final _distanceStreamController = StreamController<double>.broadcast();
  final _locationStreamController = StreamController<LocationPoint>.broadcast();

  // Address cache to prevent repetitive reverse geocoding requests
  static final Map<String, String> _addressCache = {};

  Stream<double> get distanceStream => _distanceStreamController.stream;
  Stream<LocationPoint> get locationStream => _locationStreamController.stream;

  bool get isPermissionGranted => _isPermissionGranted;
  bool get isTracking => _isTracking;
  DateTime? get trackingStartTime => _trackingStartTime;
  LocationPoint? get lastPoint => _lastPoint;
  double get currentDistanceKm =>
      (double.parse((_accumulatedDistanceKm).toStringAsFixed(2)));

  void grantPermission(bool granted) {
    _isPermissionGranted = granted;
  }

  /// Request actual GPS permission from the device/browser
  Future<bool> checkAndRequestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[GPS] Location service is disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[GPS] Location permission denied by user');
          _isPermissionGranted = false;
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[GPS] Location permission denied forever');
        _isPermissionGranted = false;
        return false;
      }

      _isPermissionGranted = true;
      return true;
    } catch (e) {
      debugPrint('[GPS] Permission check error: $e');
      return false;
    }
  }

  /// Fetch actual real-time device location via GPS hardware / browser HTML5 Geolocation
  Future<LocationPoint> detectCurrentLocationAsync({
    double defaultLat = 28.5726,
    double defaultLng = 77.3243,
  }) async {
    try {
      final hasPerm = await checkAndRequestPermission();
      if (hasPerm) {
        const settings = LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        );
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: settings,
        );
        _lastGpsPosition = pos;
        _lastPoint = LocationPoint.fromPosition(pos);
        _locationStreamController.add(_lastPoint!);
        return _lastPoint!;
      }
    } catch (e) {
      debugPrint('[GPS] getCurrentPosition error: $e');
    }

    // Fallback if hardware GPS times out or is denied
    _lastPoint = LocationPoint(
      latitude: defaultLat,
      longitude: defaultLng,
      timestamp: DateTime.now(),
      accuracy: 10.0,
    );
    return _lastPoint!;
  }

  /// Synchronous detect fallback for instant UI binding
  LocationPoint detectCurrentLocation({
    double defaultLat = 28.5726,
    double defaultLng = 77.3243,
  }) {
    if (_lastPoint != null) return _lastPoint!;
    // Trigger async fetch in background
    detectCurrentLocationAsync(defaultLat: defaultLat, defaultLng: defaultLng);
    _lastPoint = LocationPoint(
      latitude: defaultLat,
      longitude: defaultLng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
    );
    return _lastPoint!;
  }

  /// Starts live GPS continuous tracking
  Future<void> startTracking({
    double initialLat = 28.5726,
    double initialLng = 77.3243,
    DateTime? startTime,
    double initialDistanceKm = 0.0,
  }) async {
    _trackingStartTime = startTime ?? DateTime.now();
    _accumulatedDistanceKm = initialDistanceKm;
    _isTracking = true;

    // First attempt to get actual fix
    try {
      await checkAndRequestPermission();
      final point = await detectCurrentLocationAsync(
        defaultLat: initialLat,
        defaultLng: initialLng,
      );
      _lastPoint = point;
      _distanceStreamController.add(currentDistanceKm);
      _locationStreamController.add(_lastPoint!);
    } catch (_) {
      _lastPoint = LocationPoint(
        latitude: initialLat,
        longitude: initialLng,
        timestamp: DateTime.now(),
        accuracy: 5.0,
      );
    }

    // Cancel any existing subscription
    await _positionStreamSub?.cancel();

    // Start real GPS position stream from device hardware
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3, // Update every 3 meters moved
    );

    try {
      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          if (!_isTracking) return;

          // Compute actual distance from previous fix
          if (_lastGpsPosition != null) {
            final deltaMeters = Geolocator.distanceBetween(
              _lastGpsPosition!.latitude,
              _lastGpsPosition!.longitude,
              position.latitude,
              position.longitude,
            );

            // Filter out GPS noise / accuracy jumps (>150m in 1 tick is likely noise)
            if (deltaMeters >= 2.0 && deltaMeters < 500.0) {
              _accumulatedDistanceKm += (deltaMeters / 1000.0);
            }
          }

          _lastGpsPosition = position;
          _lastPoint = LocationPoint.fromPosition(position);

          _distanceStreamController.add(currentDistanceKm);
          _locationStreamController.add(_lastPoint!);
        },
        onError: (err) {
          debugPrint('[GPS] Stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('[GPS] Failed to initialize position stream: $e');
    }
  }

  /// Stops tracking and returns final actual distance in KM
  double stopTracking() {
    _isTracking = false;
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    return currentDistanceKm;
  }

  /// Reverse geocodes coordinates to actual human-readable street/locality address
  /// Uses OpenStreetMap Nominatim API with in-memory caching and fallback
  static Future<String> reverseGeocodeOnline({
    required double latitude,
    required double longitude,
    String? fallbackName,
  }) async {
    final cacheKey =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'EVehicleLogBook/1.0 (Government Fleet Management)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final parts = <String>[];

          final road = address['road'] ?? address['street'] ?? address['suburb'];
          final locality = address['neighbourhood'] ??
              address['sub-district'] ??
              address['city_district'] ??
              address['city'] ??
              address['town'] ??
              address['village'];
          final state = address['state'];
          final postcode = address['postcode'];

          if (road != null && road.toString().isNotEmpty) {
            parts.add(road.toString());
          }
          if (locality != null && locality.toString().isNotEmpty) {
            parts.add(locality.toString());
          }
          if (state != null && state.toString().isNotEmpty) {
            parts.add(state.toString());
          }
          if (postcode != null && postcode.toString().isNotEmpty) {
            parts.add(postcode.toString());
          }

          if (parts.isNotEmpty) {
            final formatted = parts.join(', ');
            _addressCache[cacheKey] = formatted;
            return formatted;
          }
        }

        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          // Take first 3 components
          final shortName = displayName.split(',').take(3).join(',').trim();
          _addressCache[cacheKey] = shortName;
          return shortName;
        }
      }
    } catch (e) {
      debugPrint('[GPS] Online reverse geocode timeout/error: $e');
    }

    return reverseGeocode(
      latitude: latitude,
      longitude: longitude,
      fallbackName: fallbackName,
    );
  }

  /// Synchronous reverse geocode fallback
  static String reverseGeocode({
    double? latitude,
    double? longitude,
    String? fallbackName,
  }) {
    if (fallbackName != null && fallbackName.isNotEmpty) {
      return fallbackName;
    }

    if (latitude == null || longitude == null) {
      return 'District Division Office, Sector 27';
    }

    final cacheKey =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    return 'Location (${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E)';
  }
}
