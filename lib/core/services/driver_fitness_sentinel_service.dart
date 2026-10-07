/// Driver fitness-for-duty checklist status.
enum FitnessStatus {
  fitForDuty,
  requiresSecondaryReview,
  unfitForDuty,
}

/// Dynamic self-certification & medical screening questionnaire response.
class DriverFitnessAssessment {
  final String driverId;
  final String driverName;
  final DateTime assessmentTime;
  final double sleepHoursPriorNight;
  final bool hasReportedIllnessOrFever;
  final bool isTakingSedatingMedication;
  final bool passedVisualReactionScreening;
  final bool passedZeroAlcoholBreathTest;
  final bool hasCommercialDriverLicenseValid;

  const DriverFitnessAssessment({
    required this.driverId,
    required this.driverName,
    required this.assessmentTime,
    required this.sleepHoursPriorNight,
    required this.hasReportedIllnessOrFever,
    required this.isTakingSedatingMedication,
    required this.passedVisualReactionScreening,
    required this.passedZeroAlcoholBreathTest,
    required this.hasCommercialDriverLicenseValid,
  });
}

/// Evaluation result for dispatch fitness compliance.
class FitnessEvaluationResult {
  final String driverId;
  final String driverName;
  final FitnessStatus status;
  final bool isDispatchApproved;
  final List<String> disqualifyingFactors;
  final String recommendation;
  final String clearanceCertificateId;

  const FitnessEvaluationResult({
    required this.driverId,
    required this.driverName,
    required this.status,
    required this.isDispatchApproved,
    required this.disqualifyingFactors,
    required this.recommendation,
    required this.clearanceCertificateId,
  });
}

/// Driver Pre-Trip Fitness-for-Duty & Fatigue Declaration Sentinel Service.
class DriverFitnessSentinelService {
  const DriverFitnessSentinelService();

  static const double minimumRequiredSleepHours = 6.0;

  FitnessEvaluationResult evaluateFitness(DriverFitnessAssessment assessment) {
    final disqualifiers = <String>[];

    if (!assessment.hasCommercialDriverLicenseValid) {
      disqualifiers.add('Invalid or expired commercial driver license');
    }

    if (!assessment.passedZeroAlcoholBreathTest) {
      disqualifiers.add('Failed zero-tolerance alcohol screening');
    }

    if (assessment.isTakingSedatingMedication) {
      disqualifiers.add('Driver declared sedating medication consumption');
    }

    if (!assessment.passedVisualReactionScreening) {
      disqualifiers.add('Reaction time screening outside safe thresholds');
    }

    if (assessment.sleepHoursPriorNight < minimumRequiredSleepHours) {
      disqualifiers.add('Acute fatigue risk: only ${assessment.sleepHoursPriorNight} hours of sleep (< 6.0h statutory limit)');
    }

    if (assessment.hasReportedIllnessOrFever) {
      disqualifiers.add('Driver reported active fever / debilitating illness');
    }

    FitnessStatus status;
    bool approved;
    String recommendation;

    if (disqualifiers.isEmpty) {
      status = FitnessStatus.fitForDuty;
      approved = true;
      recommendation = 'Driver cleared for commercial vehicle operation.';
    } else if (disqualifiers.length == 1 && assessment.sleepHoursPriorNight >= 5.0 && !assessment.isTakingSedatingMedication && assessment.passedZeroAlcoholBreathTest) {
      status = FitnessStatus.requiresSecondaryReview;
      approved = false;
      recommendation = 'Supervisor review required before vehicle key issuance.';
    } else {
      status = FitnessStatus.unfitForDuty;
      approved = false;
      recommendation = 'DISPATCH BLOCKED: Critical safety criteria failed. Assign relief driver.';
    }

    final certId = 'FIT-${assessment.driverId.hashCode.abs().toRadixString(16).padLeft(6, '0').toUpperCase()}';

    return FitnessEvaluationResult(
      driverId: assessment.driverId,
      driverName: assessment.driverName,
      status: status,
      isDispatchApproved: approved,
      disqualifyingFactors: disqualifiers,
      recommendation: recommendation,
      clearanceCertificateId: certId,
    );
  }
}
