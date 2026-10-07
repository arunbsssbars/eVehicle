import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/cross_border_compliance_service.dart';
import 'package:evehicle_logbook/core/widgets/cross_border_cabotage_card.dart';

void main() {
  group('Loop 39 - Cross-Border Customs & Cabotage Compliance Service', () {
    const service = CrossBorderComplianceService();

    test('Legitimate inbound international transport allows up to 3 cabotage operations', () {
      final entry = DateTime(2026, 10, 1, 10, 0);
      final current = DateTime(2026, 10, 3, 14, 0); // 2 days later

      final trips = [
        DomesticCabotageTrip(tripId: 't1', originCity: 'Munich', destinationCity: 'Nuremberg', completionTimestamp: DateTime(2026, 10, 2), cargoWeightKg: 8500),
      ];

      final audit = service.evaluateCabotage(
        hostCountry: 'Germany',
        internationalEntryDate: entry,
        completedCabotageTrips: trips,
        currentTimestamp: current,
        declaredCustomsSeal: 'SEAL-DE-8921',
        observedCustomsSeal: 'SEAL-DE-8921',
      );

      expect(audit.isLegallyCompliant, isTrue);
      expect(audit.completedOperationsCount, equals(1));
      expect(audit.remainingAllowedOperations, equals(2));
      expect(audit.isCustomsSealVerified, isTrue);
      expect(audit.isWithin7DayWindow, isTrue);
    });

    test('Performing 4th cabotage trip violates statutory quotas and triggers PROHIBITED status', () {
      final entry = DateTime(2026, 10, 1);
      final current = DateTime(2026, 10, 4);

      final trips = [
        DomesticCabotageTrip(tripId: 't1', originCity: 'A', destinationCity: 'B', completionTimestamp: entry, cargoWeightKg: 5000),
        DomesticCabotageTrip(tripId: 't2', originCity: 'B', destinationCity: 'C', completionTimestamp: entry, cargoWeightKg: 5000),
        DomesticCabotageTrip(tripId: 't3', originCity: 'C', destinationCity: 'D', completionTimestamp: entry, cargoWeightKg: 5000),
        DomesticCabotageTrip(tripId: 't4', originCity: 'D', destinationCity: 'E', completionTimestamp: current, cargoWeightKg: 5000),
      ];

      final audit = service.evaluateCabotage(
        hostCountry: 'France',
        internationalEntryDate: entry,
        completedCabotageTrips: trips,
        currentTimestamp: current,
        declaredCustomsSeal: 'FR-001',
        observedCustomsSeal: 'FR-001',
      );

      expect(audit.isLegallyCompliant, isFalse);
      expect(audit.completedOperationsCount, equals(4));
      expect(audit.remainingAllowedOperations, equals(0));
      expect(audit.complianceAdvisory, contains('ILLEGAL CABOTAGE BREACH'));
    });

    test('Customs seal mismatch detects cargo tampering', () {
      final entry = DateTime(2026, 10, 1);
      final current = DateTime(2026, 10, 2);

      final audit = service.evaluateCabotage(
        hostCountry: 'Austria',
        internationalEntryDate: entry,
        completedCabotageTrips: [],
        currentTimestamp: current,
        declaredCustomsSeal: 'SEAL-VALID-123',
        observedCustomsSeal: 'SEAL-BROKEN-999',
      );

      expect(audit.isLegallyCompliant, isFalse);
      expect(audit.isCustomsSealVerified, isFalse);
      expect(audit.complianceAdvisory, contains('CUSTOMS VIOLATION'));
    });
  });

  group('Loop 39 - Cabotage Compliance AQIL Responsive UI Tests', () {
    testWidgets('CrossBorderCabotageCard renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final audit = CabotageAuditResult(
        hostCountry: 'Germany',
        internationalEntryDate: DateTime(2026, 10, 1),
        completedOperationsCount: 1,
        maxAllowedOperations: 3,
        remainingAllowedOperations: 2,
        isWithin7DayWindow: true,
        isCoolingOffPeriodActive: false,
        isCustomsSealVerified: true,
        isLegallyCompliant: true,
        complianceAdvisory: 'PERMITTED: 2 cabotage domestic operations remaining in Germany.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrossBorderCabotageCard(
              audit: audit,
              onVerifyCustomsSeal: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cabotage & Customs Guard'), findsOneWidget);
      expect(find.text('PERMITTED'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CrossBorderCabotageCard preserves layout stability under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final audit = CabotageAuditResult(
        hostCountry: 'France',
        internationalEntryDate: DateTime(2026, 10, 1),
        completedOperationsCount: 4,
        maxAllowedOperations: 3,
        remainingAllowedOperations: 0,
        isWithin7DayWindow: true,
        isCoolingOffPeriodActive: true,
        isCustomsSealVerified: false,
        isLegallyCompliant: false,
        complianceAdvisory: 'ILLEGAL CABOTAGE BREACH: Exceeded statutory limit of 3 operations.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
              body: CrossBorderCabotageCard(
                audit: audit,
                onVerifyCustomsSeal: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROHIBITED'), findsOneWidget);
      expect(find.text('Scan & Authenticate Customs Cargo Seal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
