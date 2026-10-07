import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/iso_carbon_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/iso_carbon_auditor_card.dart';

void main() {
  group('Loop 84: ISO 14083 / GLEC Carbon Intensity Auditor Tests', () {
    const service = IsoCarbonAuditorService();

    test('Electric freight generates low carbon intensity and A+ rating', () {
      const factors = RouteCarbonFactors(
        distanceKm: 250.0,
        cargoWeightTons: 12.0, // 3,000 ton-km
        propulsion: FleetPropulsionType.batteryElectric,
        energyUnitsConsumed: 150.0, // 150 kWh
      );

      final audit = service.auditRouteEmissions(
        routeId: 'ROUTE-EV-DEL-JPR',
        factors: factors,
      );

      expect(audit.isGlecCertified, isTrue);
      expect(audit.efficiencyGrade, equals('A+'));
      expect(audit.tankToWheelCo2eKg, equals(0.0)); // Zero tailpipe emissions
      expect(audit.totalWellToWheelCo2eKg, equals(78.0)); // 150 * 0.52
      expect(audit.certifiedAvoidedCo2eKg > 50.0, isTrue);
      expect(audit.certificationHash, startsWith('GLEC-'));
    });

    test('Diesel heavy freight calculates accurate Scope 1 and Scope 3 breakdown', () {
      const factors = RouteCarbonFactors(
        distanceKm: 500.0,
        cargoWeightTons: 20.0, // 10,000 ton-km
        propulsion: FleetPropulsionType.internalCombustion,
        energyUnitsConsumed: 180.0, // 180 Litres
      );

      final audit = service.auditRouteEmissions(
        routeId: 'ROUTE-DSL-MUM-PUN',
        factors: factors,
      );

      expect(audit.tankToWheelCo2eKg, equals(482.4)); // 180 * 2.68
      expect(audit.wellToTankCo2eKg, equals(104.4));  // 180 * 0.58
      expect(audit.totalWellToWheelCo2eKg, equals(586.8)); // 180 * 3.26
      expect(audit.efficiencyGrade, isNotNull);
    });

    testWidgets('AQIL: IsoCarbonAuditorCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const factors = RouteCarbonFactors(
        distanceKm: 250.0,
        cargoWeightTons: 12.0,
        propulsion: FleetPropulsionType.batteryElectric,
        energyUnitsConsumed: 150.0,
      );

      final audit = service.auditRouteEmissions(
        routeId: 'ROUTE-EV-DEL-JPR',
        factors: factors,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IsoCarbonAuditorCard(
                result: audit,
                onDownloadCertificate: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(IsoCarbonAuditorCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
