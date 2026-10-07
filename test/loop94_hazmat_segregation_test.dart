import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/hazmat_segregation_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/hazmat_segregation_auditor_card.dart';

void main() {
  group('Loop 94: Dangerous Goods Co-Loading Segregation Matrix Tests', () {
    const service = HazmatSegregationAuditorService();

    test('Incompatible explosives and flammable liquids trigger segregation violation', () {
      final packages = [
        const HazmatPackage(
          unNumber: 'UN0082',
          properShippingName: 'Explosive, Blasting, Type B',
          primaryClass: DgClassCode.class1Explosives,
          quantityKg: 500.0,
        ),
        const HazmatPackage(
          unNumber: 'UN1203',
          properShippingName: 'Gasoline Motor Fuel',
          primaryClass: DgClassCode.class3FlammableLiquids,
          quantityKg: 1000.0,
        ),
      ];

      final result = service.auditCoLoading(
        vehicleOrTrailerId: 'HAZ-TRK-01',
        packages: packages,
      );

      expect(result.isCoLoadingPermitted, isFalse);
      expect(result.isSafe, isFalse);
      expect(result.segregationConflicts.length, equals(1));
      expect(result.isPlacardingMandatory, isTrue);
      expect(result.segregationSummary, contains('SEGREGATION VIOLATION'));
    });

    test('Compatible goods allow shared vehicle transport unit', () {
      final packages = [
        const HazmatPackage(
          unNumber: 'UN1203',
          properShippingName: 'Gasoline',
          primaryClass: DgClassCode.class3FlammableLiquids,
          quantityKg: 200.0,
        ),
        const HazmatPackage(
          unNumber: 'UN1223',
          properShippingName: 'Kerosene',
          primaryClass: DgClassCode.class3FlammableLiquids,
          quantityKg: 200.0,
        ),
      ];

      final result = service.auditCoLoading(
        vehicleOrTrailerId: 'HAZ-TRK-02',
        packages: packages,
      );

      expect(result.isCoLoadingPermitted, isTrue);
      expect(result.isSafe, isTrue);
      expect(result.segregationConflicts, isEmpty);
    });

    testWidgets('AQIL: HazmatSegregationAuditorCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final packages = [
        const HazmatPackage(
          unNumber: 'UN1203',
          properShippingName: 'Gasoline',
          primaryClass: DgClassCode.class3FlammableLiquids,
          quantityKg: 500.0,
        ),
      ];

      final result = service.auditCoLoading(
        vehicleOrTrailerId: 'HAZ-TRK-02',
        packages: packages,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HazmatSegregationAuditorCard(
                result: result,
                onSeparateShipments: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(HazmatSegregationAuditorCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
