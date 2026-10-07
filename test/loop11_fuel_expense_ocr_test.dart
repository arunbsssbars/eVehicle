import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/core/services/fuel_expense_audit_service.dart';
import 'package:evehicle_logbook/core/widgets/fuel_receipt_audit_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Loop 11: Real-Time Fuel Expense & Receipt OCR Audit Tests', () {
    final now = DateTime.now();

    test('auditRecord flags tank capacity overflow', () {
      final overflowingRecord = FuelExpenseRecord(
        id: 'FUEL-01',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        timestamp: now,
        odometerAtRefuel: 10000.0,
        fuelVolumeLiters: 75.0, // 75L in a 50L tank!
        totalCost: 6750.0,
        fuelType: 'Diesel',
        tankCapacityLiters: 50.0,
      );

      final audited = FuelExpenseAuditService.auditRecord(overflowingRecord);
      expect(audited.isFlagged, isTrue);
      expect(audited.flagReason, contains('exceeds vehicle physical tank capacity'));
    });

    test('auditRecord flags unit fuel price variance exceeding threshold', () {
      final abnormalPriceRecord = FuelExpenseRecord(
        id: 'FUEL-02',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        timestamp: now,
        odometerAtRefuel: 10000.0,
        fuelVolumeLiters: 40.0,
        totalCost: 6400.0, // 160 INR/L for diesel (benchmark is 90)
        fuelType: 'Diesel',
        tankCapacityLiters: 60.0,
      );

      final audited = FuelExpenseAuditService.auditRecord(abnormalPriceRecord);
      expect(audited.isFlagged, isTrue);
      expect(audited.flagReason, contains('deviates'));
    });

    test('calculateFleetSummary computes accurate CPK and economy between refills', () {
      final refill1 = FuelExpenseRecord(
        id: 'REF-01',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        timestamp: now.subtract(const Duration(days: 5)),
        odometerAtRefuel: 20000.0,
        fuelVolumeLiters: 50.0,
        totalCost: 4500.0,
        fuelType: 'Diesel',
      );

      final refill2 = FuelExpenseRecord(
        id: 'REF-02',
        vehicleId: 'VEH-01',
        vehicleRegistration: 'DL01-AB-1234',
        timestamp: now,
        odometerAtRefuel: 20600.0, // 600 km driven
        fuelVolumeLiters: 40.0,
        totalCost: 3600.0,
        fuelType: 'Diesel',
      );

      final summary = FuelExpenseAuditService.calculateFleetSummary([refill1, refill2]);

      expect(summary.totalSpend, equals(8100.0));
      expect(summary.totalFuelLiters, equals(90.0));
      // 600 km on 40L = 15 km/L
      expect(summary.avgKmPerLiter, closeTo(15.0, 0.1));
      // 3600 cost over 600 km = ₹6.00/km
      expect(summary.costPerKm, closeTo(6.0, 0.1));
    });

    testWidgets('AQIL: FuelReceiptAuditCard renders cleanly on 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const summary = FuelAnalyticsSummary(
        totalSpend: 15400.0,
        totalFuelLiters: 170.0,
        averageUnitPrice: 90.5,
        costPerKm: 6.2,
        avgKmPerLiter: 14.6,
        totalRefuels: 4,
        flaggedAnomaliesCount: 0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(12),
              child: FuelReceiptAuditCard(
                summary: summary,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FuelReceiptAuditCard), findsOneWidget);
      expect(find.text('Fuel & Expense OCR Audit'), findsOneWidget);
    });

    testWidgets('AQIL: FuelReceiptAuditCard scales safely under 1.5x dynamic text scaling', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const summary = FuelAnalyticsSummary(
        totalSpend: 25000.0,
        totalFuelLiters: 275.0,
        averageUnitPrice: 91.0,
        costPerKm: 6.8,
        avgKmPerLiter: 13.5,
        totalRefuels: 6,
        flaggedAnomaliesCount: 1,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: FuelReceiptAuditCard(
                    summary: summary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FuelReceiptAuditCard), findsOneWidget);
    });
  });
}
