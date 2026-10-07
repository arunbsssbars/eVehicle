import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/services/journey_playback_service.dart';
import 'package:evehicle_logbook/core/widgets/journey_playback_controller.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 8: Journey Route Waypoint Playback Tests', () {
    test('calculateBearing calculates standard compass directions accurately', () {
      // Due North (latitude increases, longitude constant)
      final northBearing = JourneyPlaybackService.calculateBearing(
        lat1: 10.0,
        lon1: 70.0,
        lat2: 20.0,
        lon2: 70.0,
      );
      expect(northBearing, closeTo(0.0, 1.0));

      // Due East (latitude constant, longitude increases)
      final eastBearing = JourneyPlaybackService.calculateBearing(
        lat1: 10.0,
        lon1: 70.0,
        lat2: 10.0,
        lon2: 80.0,
      );
      expect(eastBearing, closeTo(90.0, 1.5));

      // Due South
      final southBearing = JourneyPlaybackService.calculateBearing(
        lat1: 20.0,
        lon1: 70.0,
        lat2: 10.0,
        lon2: 70.0,
      );
      expect(southBearing, closeTo(180.0, 1.0));
    });

    test('getPlaybackState interpolates correctly from start to finish', () {
      final now = DateTime.now();
      final points = [
        JourneyLocationPoint(
          latitude: 28.6000,
          longitude: 77.2000,
          timestamp: now,
          speed: 10.0, // 36 km/h
        ),
        JourneyLocationPoint(
          latitude: 28.6100,
          longitude: 77.2100,
          timestamp: now.add(const Duration(minutes: 10)),
          speed: 15.0, // 54 km/h
        ),
        JourneyLocationPoint(
          latitude: 28.6200,
          longitude: 77.2200,
          timestamp: now.add(const Duration(minutes: 20)),
          speed: 12.0,
        ),
      ];

      // Progress 0.0 -> First point
      final stateStart = JourneyPlaybackService.getPlaybackState(
        routePoints: points,
        progress: 0.0,
      );
      expect(stateStart.currentPointIndex, equals(0));
      expect(stateStart.speedKmH, closeTo(36.0, 0.1));

      // Progress 1.0 -> Last point
      final stateEnd = JourneyPlaybackService.getPlaybackState(
        routePoints: points,
        progress: 1.0,
      );
      expect(stateEnd.currentPointIndex, equals(2));
      expect(stateEnd.totalDuration.inMinutes, equals(20));

      // Progress 0.5 -> Middle point
      final stateMid = JourneyPlaybackService.getPlaybackState(
        routePoints: points,
        progress: 0.5,
      );
      expect(stateMid.currentPointIndex, equals(1));
    });

    test('detectRouteStops detects dwelling longer than 3 minutes at same location', () {
      final now = DateTime.now();
      final points = [
        JourneyLocationPoint(
          latitude: 28.6000,
          longitude: 77.2000,
          timestamp: now,
        ),
        // Stationary at same location for 5 minutes
        JourneyLocationPoint(
          latitude: 28.60001,
          longitude: 77.20001,
          timestamp: now.add(const Duration(minutes: 5)),
        ),
        // Moves far away
        JourneyLocationPoint(
          latitude: 28.6500,
          longitude: 77.2500,
          timestamp: now.add(const Duration(minutes: 15)),
        ),
      ];

      final stops = JourneyPlaybackService.detectRouteStops(points);
      expect(stops.length, equals(1));
      expect(stops.first.dwellDuration.inMinutes, greaterThanOrEqualTo(5));
    });

    testWidgets('AQIL: JourneyPlaybackController renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dummyPoint = JourneyLocationPoint(
        latitude: 28.6,
        longitude: 77.2,
        timestamp: DateTime.now(),
      );

      final playbackState = RoutePlaybackState(
        currentPointIndex: 0,
        currentPoint: dummyPoint,
        progress: 0.35,
        distanceTraveledKm: 8.4,
        totalDistanceKm: 24.0,
        elapsedTime: const Duration(minutes: 12),
        totalDuration: const Duration(minutes: 35),
        speedKmH: 42.0,
        bearingDegrees: 45.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: JourneyPlaybackController(
                state: playbackState,
                isPlaying: true,
                playbackSpeed: 1.0,
                onPlayPause: () {},
                onSeek: (_) {},
                onSpeedChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(JourneyPlaybackController), findsOneWidget);
      expect(find.text('42 km/h'), findsOneWidget);
    });

    testWidgets('AQIL: JourneyPlaybackController scales safely under 1.5x dynamic text scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dummyPoint = JourneyLocationPoint(
        latitude: 28.6,
        longitude: 77.2,
        timestamp: DateTime.now(),
      );

      final playbackState = RoutePlaybackState(
        currentPointIndex: 0,
        currentPoint: dummyPoint,
        progress: 0.5,
        distanceTraveledKm: 12.0,
        totalDistanceKm: 24.0,
        elapsedTime: const Duration(minutes: 18),
        totalDuration: const Duration(minutes: 36),
        speedKmH: 55.0,
        bearingDegrees: 90.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: JourneyPlaybackController(
                    state: playbackState,
                    isPlaying: false,
                    playbackSpeed: 2.0,
                    onPlayPause: () {},
                    onSeek: (_) {},
                    onSpeedChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(JourneyPlaybackController), findsOneWidget);
    });
  });
}
