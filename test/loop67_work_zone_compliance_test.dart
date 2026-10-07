import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/work_zone_compliance_service.dart';
import 'package:evehicle_logbook/core/widgets/work_zone_compliance_card.dart';

void main() {
  group('Loop 67 - WorkZoneComplianceService Unit Tests', () {
    late WorkZoneComplianceService service;
    late WorkZoneGeometry zone;

    setUp(() {
      service = const WorkZoneComplianceService();
      zone = const WorkZoneGeometry(
        zoneId: 'WZ-884',
        zoneName: 'I-95 Bridge Rehabilitation',
        variableSpeedLimitKmh: 60.0,
        startPostKm: 142.0,
        endPostKm: 146.5,
        workersPresentOnRoadway: true,
        automatedSpeedCameraActive: true,
      );
    });

    test('Approaching work zone with beacon generates caution advisory', () {
      const telemetry = VehicleWorkZoneTelemetry(
        currentVehicleSpeedKmh: 95.0,
        currentMilepostKm: 141.6,
        approachingWarningBeaconDetected: true,
        distanceToZoneEntryMeters: 400.0,
      );

      final audit = service.assessCompliance(zone: zone, telemetry: telemetry);

      expect(audit.status, WorkZoneComplianceStatus.cautionApproachingZone);
      expect(audit.isInsideZone, isFalse);
      expect(audit.driverAlertNotice, contains('ahead'));
    });

    test('Compliant speed inside work zone confirms safety', () {
      const telemetry = VehicleWorkZoneTelemetry(
        currentVehicleSpeedKmh: 58.0,
        currentMilepostKm: 143.5,
        approachingWarningBeaconDetected: false,
        distanceToZoneEntryMeters: 0.0,
      );

      final audit = service.assessCompliance(zone: zone, telemetry: telemetry);

      expect(audit.status, WorkZoneComplianceStatus.compliantNormal);
      expect(audit.isInsideZone, isTrue);
      expect(audit.speedDeltaKmh, lessThanOrEqualTo(0.0));
      expect(audit.driverAlertNotice, contains('COMPLIANT'));
    });

    test('Severe overspeed triggers high-risk penalty and camera enforcement alert', () {
      const telemetry = VehicleWorkZoneTelemetry(
        currentVehicleSpeedKmh: 82.0, // 22 km/h over limit
        currentMilepostKm: 144.2,
        approachingWarningBeaconDetected: false,
        distanceToZoneEntryMeters: 0.0,
      );

      final audit = service.assessCompliance(zone: zone, telemetry: telemetry);

      expect(audit.status, WorkZoneComplianceStatus.severeViolationEnforcementRisk);
      expect(audit.isInsideZone, isTrue);
      expect(audit.speedDeltaKmh, 22.0);
      expect(audit.doubleFineMultiplier, 2.0);
      expect(audit.actionRequired, contains('Automated work-zone speed cameras'));
    });
  });

  group('Loop 67 - WorkZoneComplianceCard Widget & AQIL Tests', () {
    const zone = WorkZoneGeometry(
      zoneId: 'WZ-884',
      zoneName: 'I-95 Bridge Rehabilitation',
      variableSpeedLimitKmh: 60.0,
      startPostKm: 142.0,
      endPostKm: 146.5,
      workersPresentOnRoadway: true,
      automatedSpeedCameraActive: true,
    );

    testWidgets('Renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = VehicleWorkZoneTelemetry(
        currentVehicleSpeedKmh: 58.0,
        currentMilepostKm: 143.5,
        approachingWarningBeaconDetected: false,
        distanceToZoneEntryMeters: 0.0,
      );

      const audit = WorkZoneComplianceAudit(
        status: WorkZoneComplianceStatus.compliantNormal,
        speedDeltaKmh: -2.0,
        isInsideZone: true,
        doubleFineMultiplier: 2.0,
        driverAlertNotice: 'WORK ZONE COMPLIANT: Speed 58 km/h within safe limit.',
        actionRequired: 'Maintain cautious distance and watch for construction.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WorkZoneComplianceCard(
                audit: audit,
                zone: zone,
                telemetry: telemetry,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('I-95 Bridge Rehabilitation'), findsOneWidget);
      expect(find.text('COMPLIANT'), findsOneWidget);
      expect(find.text('60 km/h'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Displays severe violation button and scales under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const telemetry = VehicleWorkZoneTelemetry(
        currentVehicleSpeedKmh: 82.0,
        currentMilepostKm: 144.0,
        approachingWarningBeaconDetected: false,
        distanceToZoneEntryMeters: 0.0,
      );

      const audit = WorkZoneComplianceAudit(
        status: WorkZoneComplianceStatus.severeViolationEnforcementRisk,
        speedDeltaKmh: 22.0,
        isInsideZone: true,
        doubleFineMultiplier: 2.0,
        driverAlertNotice: 'SEVERE WORK ZONE OVERSPEED: 82 km/h in 60 km/h zone!',
        actionRequired: 'Brake immediately. Automated cameras active!',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: WorkZoneComplianceCard(
                  audit: audit,
                  zone: zone,
                  telemetry: telemetry,
                  onAcknowledgeAlert: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SEVERE VIOLATION'), findsOneWidget);
      expect(find.text('Acknowledge Speed Restriction'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
