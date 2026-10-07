import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/ota_firmware_rollback_service.dart';
import 'package:evehicle_logbook/core/widgets/ota_firmware_rollback_card.dart';

void main() {
  group('Loop 69 - OtaFirmwareRollbackService Unit Tests', () {
    late OtaFirmwareRollbackService service;
    late EcuPartitionState partition;

    setUp(() {
      service = const OtaFirmwareRollbackService();
      partition = const EcuPartitionState(
        activeSlot: 'Slot_A',
        inactiveSlot: 'Slot_B',
        currentVersion: 'v2.4.1',
        fallbackSafeVersion: 'v2.4.0',
        bootAttemptCount: 0,
      );
    });

    test('Valid payload with vehicle immobilized and good battery permits flash', () {
      const payload = OtaCampaignPayload(
        campaignId: 'OTA-2026-BMS-09',
        targetEcuName: 'BMS-Master',
        newVersion: 'v2.5.0',
        expectedSha256Checksum: 'abcdef1234567890abcdef1234567890',
        calculatedSha256Checksum: 'abcdef1234567890abcdef1234567890',
        vehicleInParkAndBrakesLocked: true,
        highVoltageBatterySocPercentage: 68.0,
      );

      final audit = service.evaluateOtaDeployment(
        partition: partition,
        payload: payload,
      );

      expect(audit.stage, OtaUpdateStage.rebootTestingSlotActive);
      expect(audit.flashPreconditionsSatisfied, isTrue);
      expect(audit.cryptographicSignatureValid, isTrue);
      expect(audit.targetPartitionSlot, 'Slot_B');
      expect(audit.automatedRollbackArmed, isTrue);
    });

    test('Corrupted payload with checksum mismatch aborts flash', () {
      const payload = OtaCampaignPayload(
        campaignId: 'OTA-2026-BMS-09',
        targetEcuName: 'BMS-Master',
        newVersion: 'v2.5.0',
        expectedSha256Checksum: '11111111111111111111111111111111',
        calculatedSha256Checksum: '99999999999999999999999999999999',
        vehicleInParkAndBrakesLocked: true,
        highVoltageBatterySocPercentage: 68.0,
      );

      final audit = service.evaluateOtaDeployment(
        partition: partition,
        payload: payload,
      );

      expect(audit.stage, OtaUpdateStage.downloadingPayload);
      expect(audit.flashPreconditionsSatisfied, isFalse);
      expect(audit.cryptographicSignatureValid, isFalse);
      expect(audit.executionActionMessage, contains('CORRUPTED PAYLOAD'));
    });

    test('Watchdog heartbeat failure or repeated boot crash triggers automatic rollback', () {
      const crashedPartition = EcuPartitionState(
        activeSlot: 'Slot_B',
        inactiveSlot: 'Slot_A',
        currentVersion: 'v2.5.0-rc1',
        fallbackSafeVersion: 'v2.4.1',
        bootAttemptCount: 3, // Max reached
      );

      final audit = service.evaluateOtaDeployment(
        partition: crashedPartition,
        payload: null,
        watchdogHeartbeatFailed: true,
      );

      expect(audit.stage, OtaUpdateStage.rollbackTriggeredToPreviousSlot);
      expect(audit.targetPartitionSlot, 'Slot_A');
      expect(audit.executionActionMessage, contains('WATCHDOG TIMEOUT'));
    });
  });

  group('Loop 69 - OtaFirmwareRollbackCard Widget & AQIL Tests', () {
    const partition = EcuPartitionState(
      activeSlot: 'Slot_A',
      inactiveSlot: 'Slot_B',
      currentVersion: 'v2.4.1',
      fallbackSafeVersion: 'v2.4.0',
    );

    testWidgets('Renders cleanly at 320px compact viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const audit = OtaRollbackAudit(
        stage: OtaUpdateStage.idleNoUpdatePending,
        flashPreconditionsSatisfied: true,
        cryptographicSignatureValid: true,
        executionActionMessage: 'No pending OTA campaigns. Running stable.',
        targetPartitionSlot: 'Slot_A',
        automatedRollbackArmed: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OtaFirmwareRollbackCard(
                audit: audit,
                partition: partition,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ECU Firmware Status'), findsOneWidget);
      expect(find.text('UP TO DATE'), findsOneWidget);
      expect(find.text('Slot_A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Displays flash action button and scales under 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const payload = OtaCampaignPayload(
        campaignId: 'OTA-2026-TCU-01',
        targetEcuName: 'Telematics-Gateway',
        newVersion: 'v3.1.0',
        expectedSha256Checksum: 'aaa',
        calculatedSha256Checksum: 'aaa',
        vehicleInParkAndBrakesLocked: true,
        highVoltageBatterySocPercentage: 80.0,
      );

      const audit = OtaRollbackAudit(
        stage: OtaUpdateStage.rebootTestingSlotActive,
        flashPreconditionsSatisfied: true,
        cryptographicSignatureValid: true,
        executionActionMessage: 'READY TO FLASH: Validated v3.1.0.',
        targetPartitionSlot: 'Slot_B',
        automatedRollbackArmed: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: OtaFirmwareRollbackCard(
                  audit: audit,
                  partition: partition,
                  payload: payload,
                  onExecuteFlash: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Telematics-Gateway Firmware OTA'), findsOneWidget);
      expect(find.text('READY TO FLASH'), findsOneWidget);
      expect(find.text('Install & Flash to Slot_B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
