import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/cargo_manifest_service.dart';
import 'package:evehicle_logbook/core/widgets/cargo_overload_card.dart';

void main() {
  group('Loop 24 - Cargo Manifest & Weight Compliance Service', () {
    const service = CargoManifestService();

    test('Standard legal cargo manifest evaluates compliant with 0 fine', () {
      const manifest = [
        CargoItem(id: 'c1', description: 'Electronics', unitWeightKg: 25.0, quantity: 10, destinationHub: 'HUB-A'),
        CargoItem(id: 'c2', description: 'Dry Goods', unitWeightKg: 50.0, quantity: 5, destinationHub: 'HUB-B'),
      ];

      final audit = service.evaluatePayload(
        manifest: manifest,
        tareWeightKg: 2200.0,
        gvwrLimitKg: 3500.0,
      );

      expect(audit.status, equals(WeightComplianceStatus.legal));
      expect(audit.totalCargoWeightKg, equals(500.0));
      expect(audit.grossVehicleWeightKg, equals(2700.0));
      expect(audit.finePenaltyUsd, equals(0.0));
      expect(audit.hazardousItemCount, equals(0));
    });

    test('Manifest exceeding GVWR calculates overweight fine and status', () {
      const manifest = [
        CargoItem(id: 'c1', description: 'Steel Beams', unitWeightKg: 500.0, quantity: 4, destinationHub: 'HUB-C'),
        CargoItem(id: 'c2', description: 'Chemicals', unitWeightKg: 100.0, quantity: 2, isHazardous: true, destinationHub: 'HUB-D'),
      ];

      final audit = service.evaluatePayload(
        manifest: manifest,
        tareWeightKg: 2000.0,
        gvwrLimitKg: 3500.0, // Gross is 4200, excess is 700
      );

      expect(audit.status, equals(WeightComplianceStatus.overloaded));
      expect(audit.totalCargoWeightKg, equals(2200.0));
      expect(audit.grossVehicleWeightKg, equals(4200.0));
      expect(audit.finePenaltyUsd, greaterThan(1000.0));
      expect(audit.hazardousItemCount, equals(2));
    });

    test('Near-capacity weight evaluates to nearCapacity status', () {
      const manifest = [
        CargoItem(id: 'c1', description: 'Pallet load', unitWeightKg: 1300.0, quantity: 1, destinationHub: 'HUB-A'),
      ];

      final audit = service.evaluatePayload(
        manifest: manifest,
        tareWeightKg: 2000.0,
        gvwrLimitKg: 3500.0, // Gross is 3300 = 94.2%
      );

      expect(audit.status, equals(WeightComplianceStatus.nearCapacity));
      expect(audit.finePenaltyUsd, equals(0.0));
    });
  });

  group('Loop 24 - Cargo Overload AQIL Responsive UI Tests', () {
    testWidgets('CargoOverloadCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = WeightComplianceAudit(
        tareWeightKg: 2000.0,
        totalCargoWeightKg: 1100.0,
        grossVehicleWeightKg: 3100.0,
        gvwrLimitKg: 3500.0,
        payloadCapacityKg: 1500.0,
        utilizationPercentage: 88.5,
        status: WeightComplianceStatus.legal,
        frontAxleWeightKg: 1085.0,
        rearAxleWeightKg: 2015.0,
        finePenaltyUsd: 0.0,
        hazardousItemCount: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CargoOverloadCard(
              audit: audit,
              onViewManifest: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cargo Manifest & Weight'), findsOneWidget);
      expect(find.text('COMPLIANT'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CargoOverloadCard handles overloaded warning safely under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = WeightComplianceAudit(
        tareWeightKg: 2200.0,
        totalCargoWeightKg: 2000.0,
        grossVehicleWeightKg: 4200.0,
        gvwrLimitKg: 3500.0,
        payloadCapacityKg: 1300.0,
        utilizationPercentage: 120.0,
        status: WeightComplianceStatus.overloaded,
        frontAxleWeightKg: 1470.0,
        rearAxleWeightKg: 2730.0,
        finePenaltyUsd: 1300.0,
        hazardousItemCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: CargoOverloadCard(
                audit: audit,
                onViewManifest: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OVERWEIGHT'), findsOneWidget);
      expect(find.textContaining('OVERLOAD RISK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
