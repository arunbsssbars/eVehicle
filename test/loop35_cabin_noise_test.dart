import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/noise_ergonomics_service.dart';
import 'package:evehicle_logbook/core/widgets/cabin_noise_card.dart';

void main() {
  group('Loop 35 - Cabin Noise & Auditory Ergonomics Service', () {
    const service = NoiseErgonomicsService();

    test('Quiet highway ride produces nominal rating and safe OSHA dose', () {
      final now = DateTime.now();
      final samples = List.generate(20, (i) {
        return NoiseSample(
          timestamp: now.add(Duration(seconds: i)),
          decibelsDba: 68.0 + (i % 2),
          speedKmph: 80.0,
        );
      });

      final audit = service.evaluateNoiseTelemetry(samples);
      expect(audit.isExceedingSafetyThreshold, isFalse);
      expect(audit.averageDecibelsDba, lessThan(72.0));
      expect(audit.oshaDosePercentage, lessThan(50.0));
      expect(audit.acousticRating, equals('NOMINAL'));
    });

    test('Sustained loud cabin noise (>88 dBA) triggers HAZARDOUS rating and safety breach', () {
      final now = DateTime.now();
      final samples = List.generate(80, (i) {
        return NoiseSample(
          timestamp: now.add(Duration(seconds: i)),
          decibelsDba: 91.0, // High exhaust / wind roar
          speedKmph: 100.0,
        );
      });

      final audit = service.evaluateNoiseTelemetry(samples);
      expect(audit.isExceedingSafetyThreshold, isTrue);
      expect(audit.averageDecibelsDba, greaterThan(88.0));
      expect(audit.acousticRating, equals('HAZARDOUS'));
      expect(audit.advisory, contains('AUDITORY RISK'));
    });

    test('Empty noise samples list handled gracefully', () {
      final audit = service.evaluateNoiseTelemetry([]);
      expect(audit.isExceedingSafetyThreshold, isFalse);
      expect(audit.averageDecibelsDba, equals(0.0));
      expect(audit.acousticRating, equals('QUIET'));
    });
  });

  group('Loop 35 - Cabin Noise AQIL Responsive UI Tests', () {
    testWidgets('CabinNoiseCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = NoiseExposureAudit(
        averageDecibelsDba: 69.2,
        peakDecibelsDba: 73.5,
        twa8HourDba: 67.8,
        oshaDosePercentage: 14.5,
        isExceedingSafetyThreshold: false,
        acousticRating: 'NOMINAL',
        advisory: 'STANDARD CABIN: Normal road noise within safe limits.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CabinNoiseCard(
              audit: audit,
              onScheduleAcousticCheck: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cabin Noise Ergonomics'), findsOneWidget);
      expect(find.text('NOMINAL'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CabinNoiseCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = NoiseExposureAudit(
        averageDecibelsDba: 89.4,
        peakDecibelsDba: 94.2,
        twa8HourDba: 88.1,
        oshaDosePercentage: 135.0,
        isExceedingSafetyThreshold: true,
        acousticRating: 'HAZARDOUS',
        advisory: 'AUDITORY RISK: Sustained noise exceeds 85 dB(A).',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: CabinNoiseCard(
                audit: audit,
                onScheduleAcousticCheck: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HAZARDOUS'), findsOneWidget);
      expect(find.text('Book Exhaust & Acoustic Vibration Inspection'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
