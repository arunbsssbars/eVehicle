import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/cargo_restraint_auditor_service.dart';
import 'package:evehicle_logbook/core/widgets/cargo_restraint_auditor_card.dart';

void main() {
  group('Loop 92: Dynamic Cargo Restraint & Tie-Down Tension Auditor Tests', () {
    const service = CargoRestraintAuditorService();

    test('Properly lashed heavy cargo with edge protection reports compliant', () {
      const profile = CargoDeckProfile(
        cargoId: 'CRG-STEEL-COIL',
        cargoDescription: 'Slit Steel Coil Skids',
        totalMassKg: 10000.0,
        isBlockedAgainstHeadboard: true,
        restraints: [
          CargoRestraintDevice(
            deviceId: 'chain-01',
            type: LashingDeviceType.grade80AlloyChain,
            workingLoadLimitKg: 3500.0,
            measuredTensionKn: 20.0,
            lashingAngleDegrees: 45.0,
            isEdgeProtectorFitted: true,
          ),
          CargoRestraintDevice(
            deviceId: 'chain-02',
            type: LashingDeviceType.grade80AlloyChain,
            workingLoadLimitKg: 3500.0,
            measuredTensionKn: 20.0,
            lashingAngleDegrees: 45.0,
            isEdgeProtectorFitted: true,
          ),
        ],
      );

      final result = service.auditCargoSecuring(profile: profile);

      expect(result.isSecuredCompliant, isTrue);
      expect(result.aggregateWorkingLoadLimitKg, equals(7000.0));
      expect(result.requiredMinimumWllKg, equals(5000.0));
      expect(result.hasSharpEdgeChafingRisk, isFalse);
      expect(result.complianceCertificateId, startsWith('EN12195-'));
    });

    test('Unprotected strap without corner protectors flags chafing risk violation', () {
      const profile = CargoDeckProfile(
        cargoId: 'CRG-CONCRETE-01',
        cargoDescription: 'Precast Concrete Blocks',
        totalMassKg: 8000.0,
        isBlockedAgainstHeadboard: false,
        restraints: [
          CargoRestraintDevice(
            deviceId: 'strap-01',
            type: LashingDeviceType.webbingStrap,
            workingLoadLimitKg: 5000.0,
            measuredTensionKn: 15.0,
            lashingAngleDegrees: 60.0,
            isEdgeProtectorFitted: false, // Chafing hazard on rough stone
          ),
        ],
      );

      final result = service.auditCargoSecuring(profile: profile);

      expect(result.isSecuredCompliant, isFalse);
      expect(result.hasSharpEdgeChafingRisk, isTrue);
      expect(result.enforcementSummary, contains('NON-COMPLIANT'));
    });

    testWidgets('AQIL: CargoRestraintAuditorCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const profile = CargoDeckProfile(
        cargoId: 'CRG-STEEL-COIL',
        cargoDescription: 'Slit Steel Coil Skids',
        totalMassKg: 10000.0,
        isBlockedAgainstHeadboard: true,
        restraints: [
          CargoRestraintDevice(
            deviceId: 'chain-01',
            type: LashingDeviceType.grade80AlloyChain,
            workingLoadLimitKg: 3500.0,
            measuredTensionKn: 20.0,
            lashingAngleDegrees: 45.0,
            isEdgeProtectorFitted: true,
          ),
        ],
      );

      final result = service.auditCargoSecuring(profile: profile);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CargoRestraintAuditorCard(
                result: result,
                onCertifyLashingManifest: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CargoRestraintAuditorCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
