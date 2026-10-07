import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/journey.dart';
import 'package:evehicle_logbook/core/services/hours_of_service_engine.dart';
import 'package:evehicle_logbook/core/widgets/hos_compliance_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 14: Automated Shift & Driving Hours Fatigue Compliance Tests', () {
    final shiftDate = DateTime(2025, 4, 15);

    test('Compliant shift within safe driving limits', () {
      final trip1 = Journey(
        id: 'J-01',
        localId: 'LOC-01',
        clientOperationId: 'OP-01',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        vehicleModel: 'Toyota Innova',
        driverId: 'DRV-10',
        driverName: 'Driver 10',
        officerId: 'USR-01',
        officerName: 'Officer 1',
        department: 'Logistics',
        office: 'HQ',
        journeyDate: shiftDate,
        startTime: DateTime(2025, 4, 15, 8, 0),
        endTime: DateTime(2025, 4, 15, 10, 0), // 2 hours
        startLocation: 'Depot',
        destination: 'Client A',
        purpose: 'Delivery',
        openingOdometer: 1000.0,
        closingOdometer: 1080.0,
        createdAt: shiftDate,
        updatedAt: shiftDate,
      );

      final report = HoursOfServiceEngine.evaluateDriverShift(
        driverId: 'DRV-10',
        date: shiftDate,
        journeys: [trip1],
      );

      expect(report.status, equals(HosStatus.compliant));
      expect(report.totalDrivingTime.inHours, equals(2));
      expect(report.remainingDailyDriveTime.inHours, equals(7));
    });

    test('Mandatory 30-min break resets continuous driving counter', () {
      // Trip 1: 3 hours
      final trip1 = Journey(
        id: 'J-02',
        localId: 'LOC-02',
        clientOperationId: 'OP-02',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        vehicleModel: 'Toyota Innova',
        driverId: 'DRV-10',
        driverName: 'Driver 10',
        officerId: 'USR-01',
        officerName: 'Officer 1',
        department: 'Logistics',
        office: 'HQ',
        journeyDate: shiftDate,
        startTime: DateTime(2025, 4, 15, 8, 0),
        endTime: DateTime(2025, 4, 15, 11, 0),
        startLocation: 'A',
        destination: 'B',
        purpose: 'Transit',
        openingOdometer: 1000.0,
        closingOdometer: 1150.0,
        createdAt: shiftDate,
        updatedAt: shiftDate,
      );

      // Break from 11:00 to 11:45 (45 min break >= 30 min)

      // Trip 2: 2 hours
      final trip2 = Journey(
        id: 'J-03',
        localId: 'LOC-03',
        clientOperationId: 'OP-03',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        vehicleModel: 'Toyota Innova',
        driverId: 'DRV-10',
        driverName: 'Driver 10',
        officerId: 'USR-01',
        officerName: 'Officer 1',
        department: 'Logistics',
        office: 'HQ',
        journeyDate: shiftDate,
        startTime: DateTime(2025, 4, 15, 11, 45),
        endTime: DateTime(2025, 4, 15, 13, 45),
        startLocation: 'B',
        destination: 'C',
        purpose: 'Transit',
        openingOdometer: 1150.0,
        closingOdometer: 1250.0,
        createdAt: shiftDate,
        updatedAt: shiftDate,
      );

      final report = HoursOfServiceEngine.evaluateDriverShift(
        driverId: 'DRV-10',
        date: shiftDate,
        journeys: [trip1, trip2],
      );

      // Continuous was reset by 45-min break, so currentContinuous is 2h, not 5h!
      expect(report.currentContinuousDrivingTime.inHours, equals(2));
      expect(report.totalDrivingTime.inHours, equals(5));
      expect(report.status, equals(HosStatus.compliant));
    });

    test('Exceeding 4.5 hours continuous without rest triggers HOS violation', () {
      final longTrip = Journey(
        id: 'J-04',
        localId: 'LOC-04',
        clientOperationId: 'OP-04',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        vehicleModel: 'Toyota Innova',
        driverId: 'DRV-20',
        driverName: 'Driver 20',
        officerId: 'USR-01',
        officerName: 'Officer 1',
        department: 'Logistics',
        office: 'HQ',
        journeyDate: shiftDate,
        startTime: DateTime(2025, 4, 15, 6, 0),
        endTime: DateTime(2025, 4, 15, 11, 0), // 5 hours continuous (> 4.5h)
        startLocation: 'HQ',
        destination: 'Far Depot',
        purpose: 'Long Haul',
        openingOdometer: 1000.0,
        closingOdometer: 1350.0,
        createdAt: shiftDate,
        updatedAt: shiftDate,
      );

      final report = HoursOfServiceEngine.evaluateDriverShift(
        driverId: 'DRV-20',
        date: shiftDate,
        journeys: [longTrip],
      );

      expect(report.status, equals(HosStatus.violation));
      expect(report.warnings.first, contains('exceeds mandatory 4.5h limit'));
    });

    testWidgets('AQIL: HosComplianceCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final report = HosShiftReport(
        driverId: 'DRV-10',
        shiftDate: DateTime(2025, 4, 15),
        totalDrivingTime: const Duration(hours: 3, minutes: 30),
        currentContinuousDrivingTime: const Duration(hours: 3, minutes: 30),
        totalRestTime: const Duration(minutes: 45),
        remainingContinuousDriveTime: const Duration(hours: 1),
        remainingDailyDriveTime: const Duration(hours: 5, minutes: 30),
        status: HosStatus.compliant,
        warnings: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: HosComplianceCard(report: report),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HosComplianceCard), findsOneWidget);
      expect(find.text('Hours of Service (HOS)'), findsOneWidget);
    });

    testWidgets('AQIL: HosComplianceCard scales safely under 1.5x dynamic text scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final report = HosShiftReport(
        driverId: 'DRV-20',
        shiftDate: DateTime(2025, 4, 15),
        totalDrivingTime: const Duration(hours: 5),
        currentContinuousDrivingTime: const Duration(hours: 5),
        totalRestTime: Duration.zero,
        remainingContinuousDriveTime: Duration.zero,
        remainingDailyDriveTime: const Duration(hours: 4),
        status: HosStatus.violation,
        warnings: const ['Continuous driving (5h 0m) exceeds mandatory 4.5h limit without rest'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: HosComplianceCard(report: report),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HosComplianceCard), findsOneWidget);
      expect(find.text('LIMIT'), findsOneWidget);
    });
  });
}
