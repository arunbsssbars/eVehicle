import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Operational state of vehicle immobilizer and electronic ignition.
enum ImmobilizerState {
  disarmedActive,   // Token valid, engine start permitted
  armedStandby,     // Vehicle locked, ignition disabled
  emergencyLockdown, // Remote SOS lock triggered by fleet dispatcher
  tokenExpired,     // Ephemeral token expired, re-auth required
}

/// Signed digital access token for keyless BLE/NFC vehicle entry.
class DigitalKeyToken {
  final String tokenId;
  final String driverId;
  final String vehicleVin;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String cryptographicSignature; // SHA-256 HMAC of payload

  const DigitalKeyToken({
    required this.tokenId,
    required this.driverId,
    required this.vehicleVin,
    required this.issuedAt,
    required this.expiresAt,
    required this.cryptographicSignature,
  });

  bool isExpired([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return now.isAfter(expiresAt);
  }
}

/// Result of digital key verification and immobilizer status.
class DigitalKeyAccessAudit {
  final ImmobilizerState state;
  final bool ignitionAllowed;
  final int remainingSecondsValid;
  final String statusDescription;
  final bool requiresReauthorization;

  const DigitalKeyAccessAudit({
    required this.state,
    required this.ignitionAllowed,
    required this.remainingSecondsValid,
    required this.statusDescription,
    required this.requiresReauthorization,
  });
}

/// Service managing offline-capable cryptographic digital key generation and immobilizer validation.
class DigitalKeyService {
  final String _fleetSharedSecret;

  const DigitalKeyService({
    String fleetSharedSecret = 'FLEET_KEYLESS_HMAC_MASTER_KEY_2026',
  }) : _fleetSharedSecret = fleetSharedSecret;

  /// Generates a signed ephemeral digital key token valid for [validityMinutes].
  DigitalKeyToken issueEphemeralKey({
    required String driverId,
    required String vehicleVin,
    int validityMinutes = 15,
    DateTime? issuanceTime,
  }) {
    final now = issuanceTime ?? DateTime.now();
    final expiry = now.add(Duration(minutes: validityMinutes));
    final tokenId = 'KEY-${now.millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';

    final payload = '$tokenId|$driverId|$vehicleVin|${now.toIso8601String()}|${expiry.toIso8601String()}';
    final keyBytes = utf8.encode(_fleetSharedSecret);
    final hmac = Hmac(sha256, keyBytes);
    final signature = hmac.convert(utf8.encode(payload)).toString();

    return DigitalKeyToken(
      tokenId: tokenId,
      driverId: driverId,
      vehicleVin: vehicleVin,
      issuedAt: now,
      expiresAt: expiry,
      cryptographicSignature: signature,
    );
  }

  /// Verifies digital key signature and returns current immobilizer authorization.
  DigitalKeyAccessAudit verifyTokenAndImmobilizer({
    required DigitalKeyToken token,
    required String targetVehicleVin,
    bool dispatcherLockdownActive = false,
    DateTime? checkTime,
  }) {
    if (dispatcherLockdownActive) {
      return const DigitalKeyAccessAudit(
        state: ImmobilizerState.emergencyLockdown,
        ignitionAllowed: false,
        remainingSecondsValid: 0,
        statusDescription: 'DISPATCHER LOCKDOWN: Vehicle immobilizer locked remotely due to security incident.',
        requiresReauthorization: true,
      );
    }

    // Verify VIN binding
    if (token.vehicleVin != targetVehicleVin) {
      return const DigitalKeyAccessAudit(
        state: ImmobilizerState.armedStandby,
        ignitionAllowed: false,
        remainingSecondsValid: 0,
        statusDescription: 'VIN MISMATCH: Digital key is not authorized for this specific vehicle.',
        requiresReauthorization: true,
      );
    }

    final now = checkTime ?? DateTime.now();
    if (token.isExpired(now)) {
      return const DigitalKeyAccessAudit(
        state: ImmobilizerState.tokenExpired,
        ignitionAllowed: false,
        remainingSecondsValid: 0,
        statusDescription: 'TOKEN EXPIRED: Ephemeral digital key window expired. Re-authenticate via NFC/BLE.',
        requiresReauthorization: true,
      );
    }

    // Verify cryptographic signature integrity
    final payload = '${token.tokenId}|${token.driverId}|${token.vehicleVin}|${token.issuedAt.toIso8601String()}|${token.expiresAt.toIso8601String()}';
    final keyBytes = utf8.encode(_fleetSharedSecret);
    final hmac = Hmac(sha256, keyBytes);
    final calculatedSignature = hmac.convert(utf8.encode(payload)).toString();

    if (calculatedSignature != token.cryptographicSignature) {
      return const DigitalKeyAccessAudit(
        state: ImmobilizerState.armedStandby,
        ignitionAllowed: false,
        remainingSecondsValid: 0,
        statusDescription: 'INTEGRITY TAMPERING: Cryptographic key signature invalid. Access rejected.',
        requiresReauthorization: true,
      );
    }

    final remainingSec = token.expiresAt.difference(now).inSeconds;

    return DigitalKeyAccessAudit(
      state: ImmobilizerState.disarmedActive,
      ignitionAllowed: true,
      remainingSecondsValid: remainingSec,
      statusDescription: 'KEY VERIFIED: Digital immobilizer disarmed. Ignition start authorized.',
      requiresReauthorization: false,
    );
  }
}
