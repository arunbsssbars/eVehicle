/// Firmware update status stages in dual-bank (A/B partition) architecture.
enum OtaUpdateStage {
  idleNoUpdatePending,
  downloadingPayload,
  stagedSlotInactiveVerifyingSha256,
  rebootTestingSlotActive,
  committedStable,
  rollbackTriggeredToPreviousSlot,
}

/// Active ECU / TCU firmware flash partition state.
class EcuPartitionState {
  final String activeSlot;     // 'Slot_A' or 'Slot_B'
  final String inactiveSlot;   // 'Slot_B' or 'Slot_A'
  final String currentVersion;
  final String fallbackSafeVersion;
  final int bootAttemptCount;
  final int maxAllowedBootAttemptsBeforeRollback;

  const EcuPartitionState({
    required this.activeSlot,
    required this.inactiveSlot,
    required this.currentVersion,
    required this.fallbackSafeVersion,
    this.bootAttemptCount = 0,
    this.maxAllowedBootAttemptsBeforeRollback = 3,
  });
}

/// Incoming OTA campaign payload metadata.
class OtaCampaignPayload {
  final String campaignId;
  final String targetEcuName;
  final String newVersion;
  final String expectedSha256Checksum;
  final String calculatedSha256Checksum;
  final bool vehicleInParkAndBrakesLocked;
  final double highVoltageBatterySocPercentage; // Must be >= 30% or 12V >= 12.4V

  const OtaCampaignPayload({
    required this.campaignId,
    required this.targetEcuName,
    required this.newVersion,
    required this.expectedSha256Checksum,
    required this.calculatedSha256Checksum,
    required this.vehicleInParkAndBrakesLocked,
    required this.highVoltageBatterySocPercentage,
  });
}

/// Audit result for OTA flash safety and automated A/B partition rollback.
class OtaRollbackAudit {
  final OtaUpdateStage stage;
  final bool flashPreconditionsSatisfied;
  final bool cryptographicSignatureValid;
  final String executionActionMessage;
  final String targetPartitionSlot;
  final bool automatedRollbackArmed;

  const OtaRollbackAudit({
    required this.stage,
    required this.flashPreconditionsSatisfied,
    required this.cryptographicSignatureValid,
    required this.executionActionMessage,
    required this.targetPartitionSlot,
    required this.automatedRollbackArmed,
  });
}

/// Service managing automotive OTA updates, A/B partition flashing, and watchdog rollback protection (ISO 24089 standard).
class OtaFirmwareRollbackService {
  const OtaFirmwareRollbackService();

  static const double minBatterySocPercent = 30.0;

  OtaRollbackAudit evaluateOtaDeployment({
    required EcuPartitionState partition,
    required OtaCampaignPayload? payload,
    bool watchdogHeartbeatFailed = false,
  }) {
    // 1. If boot attempt count exceeds threshold or watchdog heartbeat failed during testing
    if (partition.bootAttemptCount >= partition.maxAllowedBootAttemptsBeforeRollback || watchdogHeartbeatFailed) {
      return OtaRollbackAudit(
        stage: OtaUpdateStage.rollbackTriggeredToPreviousSlot,
        flashPreconditionsSatisfied: false,
        cryptographicSignatureValid: false,
        executionActionMessage: 'WATCHDOG TIMEOUT / BOOT CRASH: Switching bootloader back to ${partition.inactiveSlot} (${partition.fallbackSafeVersion}). New firmware invalidated!',
        targetPartitionSlot: partition.inactiveSlot,
        automatedRollbackArmed: false,
      );
    }

    if (payload == null) {
      return OtaRollbackAudit(
        stage: OtaUpdateStage.idleNoUpdatePending,
        flashPreconditionsSatisfied: true,
        cryptographicSignatureValid: true,
        executionActionMessage: 'No pending OTA campaigns. Running stable on ${partition.activeSlot} (${partition.currentVersion}).',
        targetPartitionSlot: partition.activeSlot,
        automatedRollbackArmed: false,
      );
    }

    // 2. Cryptographic Checksum Verification
    final bool checksumValid = payload.expectedSha256Checksum.toLowerCase() ==
        payload.calculatedSha256Checksum.toLowerCase();

    // 3. Operational In-Cabin Safety Preconditions
    final bool batterySufficient = payload.highVoltageBatterySocPercentage >= minBatterySocPercent;
    final bool vehicleImmobilized = payload.vehicleInParkAndBrakesLocked;
    final bool preconditionsMet = checksumValid && batterySufficient && vehicleImmobilized;

    OtaUpdateStage stage;
    String message;

    if (!checksumValid) {
      stage = OtaUpdateStage.downloadingPayload;
      message = 'CORRUPTED PAYLOAD: SHA-256 signature mismatch! Flash aborted to prevent bricking.';
    } else if (!vehicleImmobilized) {
      stage = OtaUpdateStage.stagedSlotInactiveVerifyingSha256;
      message = 'FLASH INHIBITED: Vehicle must be shifted into PARK with parking brake engaged.';
    } else if (!batterySufficient) {
      stage = OtaUpdateStage.stagedSlotInactiveVerifyingSha256;
      message = 'LOW AUXILIARY POWER: Battery SOC (${payload.highVoltageBatterySocPercentage.toStringAsFixed(0)}%) below 30% requirement.';
    } else {
      stage = OtaUpdateStage.rebootTestingSlotActive;
      message = 'READY TO FLASH: Validated ${payload.newVersion}. Will flash to inactive ${partition.inactiveSlot}. Rollback watchdog armed.';
    }

    return OtaRollbackAudit(
      stage: stage,
      flashPreconditionsSatisfied: preconditionsMet,
      cryptographicSignatureValid: checksumValid,
      executionActionMessage: message,
      targetPartitionSlot: partition.inactiveSlot,
      automatedRollbackArmed: preconditionsMet,
    );
  }
}
