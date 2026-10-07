import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/models/dvir_inspection.dart';
import 'package:evehicle_logbook/core/services/dvir_service.dart';
import 'package:evehicle_logbook/core/widgets/dvir_status_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 12: Automated DVIR Inspection & Defect Lifecycle Tests', () {
    test('DvirService grounds vehicle when critical defect is present', () {
      const brakeDefect = DvirDefect(
        component: 'Foot Brake',
        severity: DefectSeverity.critical,
        description: 'Brake pedal sinks to floor; hydraulic pressure loss',
      );

      final inspection = DvirService.createInspection(
        id: 'DVIR-01',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        driverId: 'DRV-01',
        driverName: 'Vikram Singh',
        odometer: 14500.0,
        type: DvirType.preTrip,
        defects: [brakeDefect],
      );

      expect(inspection.isSafeToOperate, isFalse);
      expect(inspection.hasCriticalDefects, isTrue);

      final groundedList = DvirService.getGroundedVehicleIds([inspection]);
      expect(groundedList, contains('VEH-01'));
    });

    test('DvirService permits operation when only minor defect is present', () {
      const wiperDefect = DvirDefect(
        component: 'Wiper Blade',
        severity: DefectSeverity.minor,
        description: 'Passenger side wiper squeaking',
      );

      final inspection = DvirService.createInspection(
        id: 'DVIR-02',
        vehicleId: 'VEH-02',
        vehicleRegistration: 'DL01-CD-5678',
        driverId: 'DRV-02',
        driverName: 'Rajesh Kumar',
        odometer: 22000.0,
        type: DvirType.preTrip,
        defects: [wiperDefect],
      );

      expect(inspection.isSafeToOperate, isTrue);
      expect(inspection.hasCriticalDefects, isFalse);
      expect(inspection.hasDefects, isTrue);
    });

    testWidgets('AQIL: DvirStatusCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final inspection = DvirService.createInspection(
        id: 'DVIR-03',
        vehicleId: 'VEH-03',
        vehicleRegistration: 'DL01-EF-9012',
        driverId: 'DRV-03',
        driverName: 'Amit Roy',
        odometer: 5100.0,
        type: DvirType.preTrip,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: DvirStatusCard(
                latestInspection: inspection,
                onStartInspection: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DvirStatusCard), findsOneWidget);
      expect(find.text('Daily Vehicle Inspection (DVIR)'), findsOneWidget);
      expect(find.text('ROADWORTHY & VERIFIED'), findsOneWidget);
    });

    testWidgets('AQIL: DvirStatusCard scales safely under 1.5x dynamic text scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const criticalDefect = DvirDefect(
        component: 'Steering Rack',
        severity: DefectSeverity.critical,
        description: 'Excessive play in steering column',
      );

      final inspection = DvirService.createInspection(
        id: 'DVIR-04',
        vehicleId: 'VEH-04',
        vehicleRegistration: 'DL01-GH-3456',
        driverId: 'DRV-04',
        driverName: 'Sanjay Mehra',
        odometer: 31000.0,
        type: DvirType.preTrip,
        defects: [criticalDefect],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DvirStatusCard(
                    latestInspection: inspection,
                    onStartInspection: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DvirStatusCard), findsOneWidget);
      expect(find.text('GROUNDED: CRITICAL DEFECT'), findsOneWidget);
    });
  });
}
