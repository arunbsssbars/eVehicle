import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/driver_fitness_sentinel_service.dart';
import 'package:evehicle_logbook/core/widgets/driver_fitness_sentinel_card.dart';

void main() {
  group('Loop 85: Driver Pre-Trip Fitness Sentinel Tests', () {
    const service = DriverFitnessSentinelService();

    test('Healthy compliant driver is approved for dispatch', () {
      final assessment = DriverFitnessAssessment(
        driverId: 'DRV-771',
        driverName: 'Suresh Kumar',
        assessmentTime: DateTime(2026, 10, 6, 6, 0),
        sleepHoursPriorNight: 7.5,
        hasReportedIllnessOrFever: false,
        isTakingSedatingMedication: false,
        passedVisualReactionScreening: true,
        passedZeroAlcoholBreathTest: true,
        hasCommercialDriverLicenseValid: true,
      );

      final result = service.evaluateFitness(assessment);

      expect(result.status, equals(FitnessStatus.fitForDuty));
      expect(result.isDispatchApproved, isTrue);
      expect(result.disqualifyingFactors, isEmpty);
      expect(result.clearanceCertificateId, startsWith('FIT-'));
    });

    test('Driver with alcohol violation or acute fatigue is grounded', () {
      final assessment = DriverFitnessAssessment(
        driverId: 'DRV-882',
        driverName: 'Ramesh Singh',
        assessmentTime: DateTime(2026, 10, 6, 6, 30),
        sleepHoursPriorNight: 3.5, // Severe sleep deprivation
        hasReportedIllnessOrFever: false,
        isTakingSedatingMedication: false,
        passedVisualReactionScreening: false,
        passedZeroAlcoholBreathTest: false, // Failed breathalyzer
        hasCommercialDriverLicenseValid: true,
      );

      final result = service.evaluateFitness(assessment);

      expect(result.status, equals(FitnessStatus.unfitForDuty));
      expect(result.isDispatchApproved, isFalse);
      expect(result.disqualifyingFactors.length, greaterThanOrEqualTo(2));
      expect(result.recommendation, contains('DISPATCH BLOCKED'));
    });

    testWidgets('AQIL: DriverFitnessSentinelCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final assessment = DriverFitnessAssessment(
        driverId: 'DRV-771',
        driverName: 'Suresh Kumar',
        assessmentTime: DateTime(2026, 10, 6, 6, 0),
        sleepHoursPriorNight: 7.5,
        hasReportedIllnessOrFever: false,
        isTakingSedatingMedication: false,
        passedVisualReactionScreening: true,
        passedZeroAlcoholBreathTest: true,
        hasCommercialDriverLicenseValid: true,
      );

      final result = service.evaluateFitness(assessment);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DriverFitnessSentinelCard(
                result: result,
                onAuthorizeDispatch: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DriverFitnessSentinelCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
