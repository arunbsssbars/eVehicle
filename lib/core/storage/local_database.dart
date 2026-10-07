import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/organization.dart';
import '../models/vehicle.dart';
import '../models/vehicle_document.dart';
import '../models/journey.dart';
import '../models/fuel_and_service.dart';
import '../models/audit_and_notification.dart';
import '../models/membership_request.dart';
import 'seed_data.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._internal();
  LocalDatabase._internal();

  static const String _prefKeyUsers = 'ev_users_v1';
  static const String _prefKeyOrgs = 'ev_orgs_v1';
  static const String _prefKeyVehicles = 'ev_vehicles_v1';
  static const String _prefKeyJourneys = 'ev_journeys_v1';
  static const String _prefKeyFuel = 'ev_fuel_v1';
  static const String _prefKeyMaint = 'ev_maint_v1';
  static const String _prefKeyNotifs = 'ev_notifs_v1';
  static const String _prefKeyMembershipReqs = 'ev_membership_reqs_v1';
  static const String _prefKeyActiveUser = 'ev_active_user_v1';
  static const String _prefKeyOfflineMode = 'ev_offline_mode_v1';
  static const String _prefKeyAudit = 'ev_audit_v1';

  // Bump this version number whenever the data schema changes significantly.
  // Doing so will wipe all cached data on first load and re-seed from SeedData.
  static const int _schemaVersion = 7;
  static const String _prefKeySchemaVersion = 'ev_schema_version';

  final _uuid = const Uuid();

  List<User> _users = [];
  List<Organization> _organizations = [];
  List<Vehicle> _vehicles = [];
  List<Journey> _journeys = [];
  List<FuelEntry> _fuelEntries = [];
  List<MaintenanceRecord> _maintenanceRecords = [];
  List<NotificationItem> _notifications = [];
  List<MembershipRequest> _membershipRequests = [];
  final List<AuditLog> _auditLogs = [];

  User? _currentUser;
  bool _isOfflineMode = false;
  bool _initialized = false;

  bool get isOfflineMode => _isOfflineMode;
  set isOfflineMode(bool val) {
    _isOfflineMode = val;
    _saveOfflineMode();
  }

  User? get currentUser => _currentUser;

  /// All users list (for admin/management screens)
  List<User> get users => List.unmodifiable(_users);

  /// All registered organizations
  List<Organization> get organizations => List.unmodifiable(_organizations);

  // ── Role-based & Multi-Tenant data scoping ───────────────────────────────
  // superAdmin                    → sees ALL data across all organizations
  // companyAdmin / departmentAdmin→ sees all fleet data within their organization
  // approvingOfficer              → own data + journeys pending their approval
  // driver / user (officer)       → only their own journeys & assigned vehicle
  // individualUser                → private personal logbook
  // ─────────────────────────────────────────────────────────────────────────

  bool get _isAdmin =>
      _currentUser?.role == UserRole.superAdmin ||
      _currentUser?.role == UserRole.companyAdmin ||
      _currentUser?.role == UserRole.departmentAdmin;

  /// All vehicles in the system without role filtering
  List<Vehicle> get allVehicles => List.unmodifiable(_vehicles);

  /// Vehicles scoped to the current user's role and organization
  List<Vehicle> get vehicles {
    if (_currentUser == null || _currentUser!.role == UserRole.superAdmin) {
      return List.unmodifiable(_vehicles);
    }
    final uid = _currentUser!.id;
    if (_currentUser!.isIndividual) {
      final scoped = _vehicles
          .where((v) => v.id == _currentUser!.assignedVehicleId || v.assignedDriverId == uid)
          .toList();
      return List.unmodifiable(scoped.isNotEmpty ? scoped : _vehicles.take(1).toList());
    }
    if (_currentUser!.isCompanyAdmin) {
      return List.unmodifiable(_vehicles);
    }
    final assignedId = _currentUser!.assignedVehicleId;
    final scoped = _vehicles
        .where((v) => v.id == assignedId || v.assignedDriverId == uid)
        .toList();
    return List.unmodifiable(scoped.isNotEmpty ? scoped : _vehicles);
  }

  /// Journeys scoped to the current user's role and organization
  List<Journey> get journeys {
    if (_currentUser == null || _currentUser!.role == UserRole.superAdmin) {
      return List.unmodifiable(_journeys);
    }
    final uid = _currentUser!.id;
    if (_currentUser!.isIndividual) {
      return List.unmodifiable(
          _journeys.where((j) => j.officerId == uid || j.driverId == uid).toList());
    }
    if (_currentUser!.isCompanyAdmin) {
      return List.unmodifiable(_journeys);
    }
    final isApprover = _currentUser!.role == UserRole.approvingOfficer;
    return List.unmodifiable(_journeys.where((j) {
      // Own journeys (as officer or as driver)
      if (j.officerId == uid || j.driverId == uid) return true;
      // Approving officer: also show journeys pending approval
      if (isApprover &&
          (j.status == JourneyStatus.pendingApproval ||
              j.status == JourneyStatus.submitted)) {
        return true;
      }
      return false;
    }).toList());
  }

  /// Fuel entries scoped to the user's assigned vehicles
  List<FuelEntry> get fuelEntries {
    if (_currentUser == null || _isAdmin) {
      return List.unmodifiable(_fuelEntries);
    }
    final vehicleIds = vehicles.map((v) => v.id).toSet();
    return List.unmodifiable(
        _fuelEntries.where((f) => vehicleIds.contains(f.vehicleId)).toList());
  }

  /// Maintenance records scoped to the user's assigned vehicles
  List<MaintenanceRecord> get maintenanceRecords {
    if (_currentUser == null || _isAdmin) {
      return List.unmodifiable(_maintenanceRecords);
    }
    final vehicleIds = vehicles.map((v) => v.id).toSet();
    return List.unmodifiable(_maintenanceRecords
        .where((m) => vehicleIds.contains(m.vehicleId))
        .toList());
  }

  /// Notifications scoped to the current user
  List<NotificationItem> get notifications {
    if (_currentUser == null || _isAdmin) {
      return List.unmodifiable(_notifications);
    }
    final uid = _currentUser!.id;
    // Show notifications with no specific user (broadcast) or targeted to this user
    return List.unmodifiable(
        _notifications.where((n) => n.userId == null || n.userId == uid).toList());
  }

  /// Audit logs scoped to the current user (admins see all)
  List<AuditLog> get auditLogs {
    if (_currentUser == null || _isAdmin) {
      return List.unmodifiable(_auditLogs);
    }
    final uid = _currentUser!.id;
    return List.unmodifiable(
        _auditLogs.where((a) => a.userId == uid).toList());
  }

  /// All platform audit logs (unfiltered for Super Admin)
  List<AuditLog> get allAuditLogs => List.unmodifiable(_auditLogs);

  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Schema version migration: clear all stale data if schema changed
      final storedVersion = prefs.getInt(_prefKeySchemaVersion) ?? 0;
      if (storedVersion < _schemaVersion) {
        await prefs.remove(_prefKeyUsers);
        await prefs.remove(_prefKeyOrgs);
        await prefs.remove(_prefKeyVehicles);
        await prefs.remove(_prefKeyJourneys);
        await prefs.remove(_prefKeyFuel);
        await prefs.remove(_prefKeyMaint);
        await prefs.remove(_prefKeyNotifs);
        await prefs.remove(_prefKeyActiveUser);
        await prefs.setInt(_prefKeySchemaVersion, _schemaVersion);
      }

      // Load or initialize organizations
      final orgsRaw = prefs.getString(_prefKeyOrgs);
      if (orgsRaw != null) {
        try {
          final list = jsonDecode(orgsRaw) as List<dynamic>;
          _organizations = list
              .whereType<Map<String, dynamic>>()
              .map((e) {
                try {
                  return Organization.fromJson(e);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Organization>()
              .toList();
          if (_organizations.isEmpty) {
            _organizations = List.from(SeedData.demoOrganizations);
            await _saveOrganizations();
          }
        } catch (_) {
          _organizations = List.from(SeedData.demoOrganizations);
          await _saveOrganizations();
        }
      } else {
        _organizations = List.from(SeedData.demoOrganizations);
        await _saveOrganizations();
      }

      // Load or initialize users
      final usersRaw = prefs.getString(_prefKeyUsers);
      if (usersRaw != null) {
        try {
          final list = jsonDecode(usersRaw) as List<dynamic>;
          _users = list
              .whereType<Map<String, dynamic>>()
              .map((e) { try { return User.fromJson(e); } catch (_) { return null; } })
              .whereType<User>()
              .toList();
          if (_users.isEmpty) {
            _users = List.from(SeedData.demoUsers);
            await _saveUsers();
          }
        } catch (_) {
          _users = List.from(SeedData.demoUsers);
          await _saveUsers();
        }
      } else {
        _users = List.from(SeedData.demoUsers);
        await _saveUsers();
      }

      // Load or initialize vehicles
      final vehiclesRaw = prefs.getString(_prefKeyVehicles);
      if (vehiclesRaw != null) {
        try {
          final list = jsonDecode(vehiclesRaw) as List<dynamic>;
          _vehicles = list
              .whereType<Map<String, dynamic>>()
              .map((e) { try { return Vehicle.fromJson(e); } catch (_) { return null; } })
              .whereType<Vehicle>()
              .toList();
          if (_vehicles.isEmpty) {
            _vehicles = List.from(SeedData.demoVehicles);
            await _saveVehicles();
          }
        } catch (_) {
          _vehicles = List.from(SeedData.demoVehicles);
          await _saveVehicles();
        }
      } else {
        _vehicles = List.from(SeedData.demoVehicles);
        await _saveVehicles();
      }

      // Load or initialize journeys
      final journeysRaw = prefs.getString(_prefKeyJourneys);
      if (journeysRaw != null) {
        try {
          final list = jsonDecode(journeysRaw) as List<dynamic>;
          _journeys = list
              .whereType<Map<String, dynamic>>()
              .map((e) {
                try {
                  return Journey.fromJson(e);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Journey>()
              .toList();
          // If parsing produced 0 journeys but the key existed (all bad), reset
          if (_journeys.isEmpty) {
            _journeys = List.from(SeedData.demoJourneys);
            await _saveJourneys();
          }
        } catch (_) {
          _journeys = List.from(SeedData.demoJourneys);
          await _saveJourneys();
        }
      } else {
        _journeys = List.from(SeedData.demoJourneys);
        await _saveJourneys();
      }


      // Load or initialize fuel
      final fuelRaw = prefs.getString(_prefKeyFuel);
      if (fuelRaw != null) {
        final list = jsonDecode(fuelRaw) as List<dynamic>;
        _fuelEntries =
            list.map((e) => FuelEntry.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _fuelEntries = List.from(SeedData.demoFuelEntries);
        await _saveFuel();
      }

      // Load or initialize maintenance
      final maintRaw = prefs.getString(_prefKeyMaint);
      if (maintRaw != null) {
        final list = jsonDecode(maintRaw) as List<dynamic>;
        _maintenanceRecords = list
            .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _maintenanceRecords = List.from(SeedData.demoMaintenanceRecords);
        await _saveMaintenance();
      }

      // Load notifications
      final notifsRaw = prefs.getString(_prefKeyNotifs);
      if (notifsRaw != null) {
        try {
          final list = jsonDecode(notifsRaw) as List<dynamic>;
          _notifications = list
              .whereType<Map<String, dynamic>>()
              .map((e) {
                try {
                  return NotificationItem.fromJson(e);
                } catch (_) {
                  return null;
                }
              })
              .whereType<NotificationItem>()
              .toList();
        } catch (_) {
          _notifications = List.from(SeedData.demoNotifications);
          await _saveNotifications();
        }
      } else {
        _notifications = List.from(SeedData.demoNotifications);
        await _saveNotifications();
      }

      // Membership Requests
      final reqsRaw = prefs.getString(_prefKeyMembershipReqs);
      if (reqsRaw != null) {
        try {
          final list = jsonDecode(reqsRaw) as List<dynamic>;
          _membershipRequests = list
              .whereType<Map<String, dynamic>>()
              .map((e) {
                try {
                  return MembershipRequest.fromJson(e);
                } catch (_) {
                  return null;
                }
              })
              .whereType<MembershipRequest>()
              .toList();
        } catch (_) {
          _membershipRequests = _createDemoMembershipRequests();
          await _saveMembershipRequests();
        }
      } else {
        _membershipRequests = _createDemoMembershipRequests();
        await _saveMembershipRequests();
      }

      // Load audit logs
      final auditRaw = prefs.getString(_prefKeyAudit);
      if (auditRaw != null) {
        try {
          final list = jsonDecode(auditRaw) as List<dynamic>;
          _auditLogs.clear();
          _auditLogs.addAll(list
              .whereType<Map<String, dynamic>>()
              .map((e) {
                try {
                  return AuditLog.fromJson(e);
                } catch (_) {
                  return null;
                }
              })
              .whereType<AuditLog>());
        } catch (_) {}
      }
      if (_auditLogs.isEmpty) {
        _seedInitialAuditLogs();
        await _saveAuditLogs();
      }

      // Active User
      final activeUserRaw = prefs.getString(_prefKeyActiveUser);
      if (activeUserRaw != null) {
        try {
          _currentUser =
              User.fromJson(jsonDecode(activeUserRaw) as Map<String, dynamic>);
        } catch (_) {
          _currentUser = _users.isNotEmpty ? _users.first : null;
        }
      } else {
        _currentUser = _users.isNotEmpty ? _users.first : null;
      }

      _isOfflineMode = prefs.getBool(_prefKeyOfflineMode) ?? false;
      _initialized = true;
    } catch (e) {
      // Fallback in memory
      _users = List.from(SeedData.demoUsers);
      _vehicles = List.from(SeedData.demoVehicles);
      _journeys = List.from(SeedData.demoJourneys);
      _fuelEntries = List.from(SeedData.demoFuelEntries);
      _maintenanceRecords = List.from(SeedData.demoMaintenanceRecords);
      _notifications = List.from(SeedData.demoNotifications);
      _membershipRequests = _createDemoMembershipRequests();
      _currentUser = _users.isNotEmpty ? _users.first : null;
      _initialized = true;
    }
  }

  // --- Auth & Session ---
  Future<void> setCurrentUser(User user) async {
    _currentUser = user;
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      _users[idx] = user;
      await _saveUsers();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyActiveUser, jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyActiveUser);
  }

  // --- Journey Operations ---
  Journey? getActiveJourney() {
    try {
      return _journeys.firstWhere((j) => j.status == JourneyStatus.active);
    } catch (_) {
      return null;
    }
  }

  Future<Journey> startJourney({
    required Vehicle vehicle,
    required String driverId,
    required String driverName,
    required String startLocation,
    required String purpose,
    required double openingOdometer,
    TripCategory tripCategory = TripCategory.business,
    double? startLat,
    double? startLng,
    String? accompanyingOfficers,
    String? remarks,
    String? userOfficerName,
    String? userOfficerDesignation,
    bool isSubordinateJourney = false,
    String? officerSignatureText,
  }) async {
    final now = DateTime.now();
    final localId = 'LOC-JRN-${_uuid.v4().substring(0, 8)}';
    final serverId = _isOfflineMode ? localId : 'JRN-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 4).toUpperCase()}';

    final effectiveUserOfficerName = userOfficerName ?? _currentUser?.name ?? 'Dr. S. K. Verma';
    final effectiveUserOfficerDesignation = userOfficerDesignation ?? _currentUser?.designation ?? 'Executive Engineer';
    final effectiveSignature = officerSignatureText ?? effectiveUserOfficerName;
    final requiresApproval = _currentUser?.requiresApproval ?? true;

    final journey = Journey(
      id: serverId,
      localId: localId,
      clientOperationId: 'OP-${_uuid.v4()}',
      vehicleId: vehicle.id,
      vehicleRegistration: vehicle.registrationNumber,
      vehicleModel: '${vehicle.make} ${vehicle.model}',
      driverId: driverId,
      driverName: driverName,
      officerId: _currentUser?.id ?? 'USR-001',
      officerName: _currentUser?.name ?? 'Dr. S. K. Verma',
      userOfficerName: effectiveUserOfficerName,
      userOfficerDesignation: effectiveUserOfficerDesignation,
      isSubordinateJourney: isSubordinateJourney,
      officerSignatureText: effectiveSignature,
      requiresApproval: requiresApproval,
      department: _currentUser?.department ?? 'Public Works Department',
      office: _currentUser?.office ?? 'District Division 1, Noida',
      journeyDate: DateTime(now.year, now.month, now.day),
      startTime: now,
      startLocation: startLocation,
      purpose: purpose,
      openingOdometer: openingOdometer,
      tripCategory: tripCategory,
      startLatitude: startLat ?? 28.5726,
      startLongitude: startLng ?? 77.3243,
      routePoints: [
        JourneyLocationPoint(
          latitude: startLat ?? 28.5726,
          longitude: startLng ?? 77.3243,
          timestamp: now,
        ),
      ],
      accompanyingOfficers: accompanyingOfficers,
      remarks: remarks,
      status: JourneyStatus.active,
      syncStatus: _isOfflineMode ? SyncStatus.pending : SyncStatus.synced,
      createdAt: now,
      updatedAt: now,
    );

    _journeys.insert(0, journey);
    await _saveJourneys();
    _addAudit(
      action: 'START_JOURNEY',
      entity: 'JOURNEY',
      entityId: journey.id,
      newValue: 'Opening Odometer: $openingOdometer KM | Category: ${tripCategory.label} | Officer: $effectiveUserOfficerName ($effectiveUserOfficerDesignation)',
      reason: 'Journey initiated from $startLocation ${isSubordinateJourney ? "(Subordinate Usage)" : ""}',
    );
    return journey;
  }

  Future<Journey> completeAndSubmitJourney({
    required String journeyId,
    required String destination,
    required double closingOdometer,
    double? gpsDistance,
    double? endLat,
    double? endLng,
    String? remarks,
    double? expenseAmount,
    String? expenseReceiptUrl,
    bool saveAsDraft = false,
  }) async {
    final index = _journeys.indexWhere((j) => j.id == journeyId || j.localId == journeyId);
    if (index == -1) throw Exception('Journey not found');

    final existing = _journeys[index];
    final now = DateTime.now();
    final officialDistance = closingOdometer - existing.openingOdometer;
    final finalGpsDist = gpsDistance ?? (officialDistance * 0.98);

    final isSelfApproving = !existing.requiresApproval || (_currentUser?.isSelfApprover ?? false);

    JourneyStatus status;
    String? approvedBy;
    DateTime? approvedAt;

    if (saveAsDraft) {
      status = JourneyStatus.draft;
    } else if (isSelfApproving) {
      status = JourneyStatus.approved;
      approvedBy = '${_currentUser?.name ?? existing.userOfficerName} (Self-Approved)';
      approvedAt = now;
    } else {
      status = JourneyStatus.pendingApproval;
    }

    final updated = existing.copyWith(
      destination: destination,
      endTime: now,
      closingOdometer: closingOdometer,
      officialDistance: officialDistance,
      gpsDistance: finalGpsDist,
      endLatitude: endLat ?? 28.5355,
      endLongitude: endLng ?? 77.3910,
      remarks: remarks ?? existing.remarks,
      expenseAmount: expenseAmount ?? existing.expenseAmount,
      expenseReceiptUrl: expenseReceiptUrl ?? existing.expenseReceiptUrl,
      status: status,
      approvedBy: approvedBy ?? existing.approvedBy,
      approvedAt: approvedAt ?? existing.approvedAt,
      syncStatus: _isOfflineMode ? SyncStatus.pending : SyncStatus.synced,
      updatedAt: now,
    );

    _journeys[index] = updated;
    await _saveJourneys();

    // Update Vehicle Odometer
    await updateVehicleOdometer(existing.vehicleId, closingOdometer);

    _addAudit(
      action: saveAsDraft
          ? 'SAVE_DRAFT_JOURNEY'
          : (isSelfApproving ? 'SELF_APPROVE_JOURNEY' : 'SUBMIT_JOURNEY'),
      entity: 'JOURNEY',
      entityId: updated.id,
      newValue: 'Distance: ${officialDistance.toStringAsFixed(1)} KM | Status: ${status.label}',
      reason: isSelfApproving
          ? 'Journey completed and self-certified by officer (no approver required)'
          : 'Journey finished at $destination and submitted for approval',
    );

    if (!saveAsDraft) {
      addNotification(
        category: isSelfApproving
            ? NotificationCategory.approval
            : NotificationCategory.journey,
        title: isSelfApproving ? 'Journey Self-Approved' : 'Journey Submitted',
        message: isSelfApproving
            ? 'Journey ${updated.id} (${officialDistance.toStringAsFixed(1)} KM) was verified and self-approved.'
            : 'Journey ${updated.id} (${officialDistance.toStringAsFixed(1)} KM) submitted for verification.',
      );
    }

    return updated;
  }

  Future<Journey> submitDraftJourney(String journeyId) async {
    final index = _journeys.indexWhere((j) => j.id == journeyId || j.localId == journeyId);
    if (index == -1) throw Exception('Journey not found');

    final existing = _journeys[index];
    final now = DateTime.now();
    final isSelfApproving = !existing.requiresApproval || (_currentUser?.isSelfApprover ?? false);

    final status = isSelfApproving
        ? JourneyStatus.approved
        : JourneyStatus.pendingApproval;
    final approvedBy = isSelfApproving
        ? '${_currentUser?.name ?? existing.userOfficerName} (Self-Approved)'
        : existing.approvedBy;
    final approvedAt = isSelfApproving ? now : existing.approvedAt;

    final updated = existing.copyWith(
      status: status,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      syncStatus: _isOfflineMode ? SyncStatus.pending : SyncStatus.synced,
      updatedAt: now,
    );

    _journeys[index] = updated;
    await _saveJourneys();

    _addAudit(
      action: isSelfApproving ? 'SELF_APPROVE_DRAFT_JOURNEY' : 'SUBMIT_DRAFT_JOURNEY',
      entity: 'JOURNEY',
      entityId: updated.id,
      newValue: 'Status: ${status.label}',
      reason: isSelfApproving
          ? 'Draft journey self-approved upon submission'
          : 'Draft journey submitted for approval',
    );

    addNotification(
      category: isSelfApproving
          ? NotificationCategory.approval
          : NotificationCategory.journey,
      title: isSelfApproving
          ? 'Draft Journey Self-Approved'
          : 'Draft Journey Submitted',
      message:
          'Journey ${updated.id} (${updated.calculatedDistance.toStringAsFixed(1)} KM) submitted and ${isSelfApproving ? "self-approved" : "queued for approval"}.',
    );

    return updated;
  }

  Future<Journey> editJourney({
    required String journeyId,
    DateTime? journeyDate,
    DateTime? startTime,
    DateTime? endTime,
    String? startLocation,
    String? destination,
    String? purpose,
    double? openingOdometer,
    double? closingOdometer,
    String? accompanyingOfficers,
    String? driverName,
    String? userOfficerName,
    String? userOfficerDesignation,
    bool? isSubordinateJourney,
    String? officerSignatureText,
    bool? requiresApproval,
    String? remarks,
    String? editReason,
  }) async {
    final index =
        _journeys.indexWhere((j) => j.id == journeyId || j.localId == journeyId);
    if (index == -1) throw Exception('Journey not found');

    final existing = _journeys[index];
    final wasApproved = existing.status == JourneyStatus.approved;
    final now = DateTime.now();

    final newOpening = openingOdometer ?? existing.openingOdometer;
    final newClosing = closingOdometer ?? existing.closingOdometer;
    double? newOfficialDistance;
    if (newClosing != null) {
      newOfficialDistance =
          (newClosing >= newOpening) ? (newClosing - newOpening) : existing.officialDistance;
    }

    final effectiveRequiresApproval = requiresApproval ?? existing.requiresApproval;

    // Check if user is self-approving authority or does not require approval
    final isSelfApproving = !effectiveRequiresApproval ||
        (_currentUser != null && _currentUser!.isSelfApprover);

    final JourneyStatus newStatus;
    final String? newApprovedBy;
    final DateTime? newApprovedAt;

    if (isSelfApproving) {
      // Self-approving officer does not require re-approval from any other officer
      newStatus = JourneyStatus.approved;
      newApprovedBy = '${_currentUser?.name ?? userOfficerName ?? existing.userOfficerName} (Self-Approved)';
      newApprovedAt = now;
    } else {
      // Subordinate / regular user requires approval from designated approving officer
      newStatus = existing.status == JourneyStatus.draft
          ? JourneyStatus.draft
          : JourneyStatus.pendingApproval;
      newApprovedBy = null;
      newApprovedAt = null;
    }

    final shouldClearAccompanying =
        accompanyingOfficers != null && accompanyingOfficers.trim().isEmpty;
    final shouldClearRemarks = remarks != null && remarks.trim().isEmpty;

    final updated = existing.copyWith(
      journeyDate: journeyDate ?? existing.journeyDate,
      startTime: startTime ?? existing.startTime,
      endTime: endTime ?? existing.endTime,
      startLocation: startLocation ?? existing.startLocation,
      destination: destination ?? existing.destination,
      purpose: purpose ?? existing.purpose,
      openingOdometer: newOpening,
      closingOdometer: newClosing,
      officialDistance: newOfficialDistance,
      accompanyingOfficers: shouldClearAccompanying ? null : accompanyingOfficers,
      clearAccompanyingOfficers: shouldClearAccompanying,
      driverName: driverName ?? existing.driverName,
      userOfficerName: userOfficerName ?? existing.userOfficerName,
      userOfficerDesignation:
          userOfficerDesignation ?? existing.userOfficerDesignation,
      isSubordinateJourney: isSubordinateJourney ?? existing.isSubordinateJourney,
      officerSignatureText:
          officerSignatureText ?? userOfficerName ?? existing.userOfficerName,
      requiresApproval: effectiveRequiresApproval,
      remarks: shouldClearRemarks ? null : remarks,
      clearRemarks: shouldClearRemarks,
      status: newStatus,
      approvedBy: newApprovedBy,
      approvedAt: newApprovedAt,
      syncStatus: _isOfflineMode ? SyncStatus.pending : SyncStatus.synced,
      updatedAt: now,
    );

    _journeys[index] = updated;
    await _saveJourneys();

    if (newClosing != null) {
      await updateVehicleOdometer(existing.vehicleId, newClosing);
    }

    _addAudit(
      action: isSelfApproving
          ? 'EDIT_SELF_APPROVED_JOURNEY'
          : (wasApproved ? 'EDIT_APPROVED_JOURNEY' : 'EDIT_JOURNEY'),
      entity: 'JOURNEY',
      entityId: updated.id,
      previousValue: 'Status: ${existing.status.label} | Dist: ${existing.calculatedDistance.toStringAsFixed(1)} KM',
      newValue: 'Status: ${newStatus.label} | Dist: ${updated.calculatedDistance.toStringAsFixed(1)} KM',
      reason: editReason ??
          (isSelfApproving
              ? 'Self-approving officer edited journey details. Self-certified immediately.'
              : (wasApproved
                  ? 'Approved journey modified by officer. Prior approval revoked; re-queued for official approval.'
                  : 'Journey details modified and queued for approval.')),
    );

    addNotification(
      category: NotificationCategory.approval,
      title: isSelfApproving
          ? 'Journey Updated (Self-Approved)'
          : (wasApproved ? 'Approved Journey Revised' : 'Journey Edited'),
      message: isSelfApproving
          ? 'Journey ${updated.id} (${updated.calculatedDistance.toStringAsFixed(1)} KM) was edited and self-approved.'
          : 'Journey ${updated.id} was edited (${updated.calculatedDistance.toStringAsFixed(1)} KM) and resubmitted for official approval.',
    );

    return updated;
  }

  Future<Journey> approveJourney(String journeyId, String approverName) async {
    final index = _journeys.indexWhere((j) => j.id == journeyId);
    if (index == -1) throw Exception('Journey not found');

    final now = DateTime.now();
    final updated = _journeys[index].copyWith(
      status: JourneyStatus.approved,
      approvedBy: approverName,
      approvedAt: now,
      updatedAt: now,
    );

    _journeys[index] = updated;
    await _saveJourneys();

    _addAudit(
      action: 'APPROVE_JOURNEY',
      entity: 'JOURNEY',
      entityId: journeyId,
      newValue: 'APPROVED',
      reason: 'Approved by $approverName',
    );

    addNotification(
      category: NotificationCategory.approval,
      title: 'Journey Approved',
      message: 'Journey $journeyId has been approved by $approverName.',
    );

    return updated;
  }

  Future<Journey> rejectJourney(
      String journeyId, String rejectorName, String reason) async {
    final index = _journeys.indexWhere((j) => j.id == journeyId);
    if (index == -1) throw Exception('Journey not found');

    final now = DateTime.now();
    final updated = _journeys[index].copyWith(
      status: JourneyStatus.rejected,
      rejectedBy: rejectorName,
      rejectionReason: reason,
      rejectedAt: now,
      updatedAt: now,
    );

    _journeys[index] = updated;
    await _saveJourneys();

    _addAudit(
      action: 'REJECT_JOURNEY',
      entity: 'JOURNEY',
      entityId: journeyId,
      newValue: 'REJECTED: $reason',
      reason: reason,
    );

    addNotification(
      category: NotificationCategory.approval,
      title: 'Journey Rejected',
      message: 'Journey $journeyId was rejected: $reason',
    );

    return updated;
  }

  Future<Journey> lockJourney(String journeyId, String lockerName) async {
    final index = _journeys.indexWhere((j) => j.id == journeyId);
    if (index == -1) throw Exception('Journey not found');

    final now = DateTime.now();
    final updated = _journeys[index].copyWith(
      status: JourneyStatus.locked,
      lockedBy: lockerName,
      lockedAt: now,
      updatedAt: now,
    );

    _journeys[index] = updated;
    await _saveJourneys();

    _addAudit(
      action: 'LOCK_RECORD',
      entity: 'JOURNEY',
      entityId: journeyId,
      newValue: 'LOCKED',
      reason: 'Official monthly record finalized and locked by $lockerName',
    );

    return updated;
  }

  /// Delete Journey: If not approved (or if officer is self-approver), deletes directly.
  /// If approved and user is not self-approver, requests deletion approval from Approver.
  Future<bool> deleteJourney({
    required String journeyId,
    String? reason,
  }) async {
    final index =
        _journeys.indexWhere((j) => j.id == journeyId || j.localId == journeyId);
    if (index == -1) throw Exception('Journey not found');

    final existing = _journeys[index];
    final isSelfApproving = !existing.requiresApproval ||
        (_currentUser != null && _currentUser!.isSelfApprover);

    if (existing.status != JourneyStatus.approved || isSelfApproving) {
      // Direct deletion allowed
      _journeys.removeAt(index);
      await _saveJourneys();

      _addAudit(
        action: isSelfApproving && existing.status == JourneyStatus.approved
            ? 'DELETE_SELF_APPROVED_JOURNEY'
            : 'DELETE_JOURNEY',
        entity: 'JOURNEY',
        entityId: journeyId,
        previousValue:
            'Status: ${existing.status.label} | Dist: ${existing.calculatedDistance.toStringAsFixed(1)} KM',
        newValue: 'DELETED',
        reason: reason ?? 'Journey record deleted by officer',
      );

      addNotification(
        category: NotificationCategory.journey,
        title: 'Journey Deleted',
        message: 'Journey $journeyId was removed from official logbook.',
      );

      return true; // Permanently deleted
    } else {
      // Approved journey requires re-approval / confirmation for deletion
      final now = DateTime.now();
      final updated = existing.copyWith(
        status: JourneyStatus.pendingDeletion,
        remarks: (existing.remarks != null && existing.remarks!.isNotEmpty)
            ? '${existing.remarks}\n[Deletion Requested]: ${reason ?? "Official deletion requested"}'
            : '[Deletion Requested]: ${reason ?? "Official deletion requested"}',
        updatedAt: now,
      );

      _journeys[index] = updated;
      await _saveJourneys();

      _addAudit(
        action: 'REQUEST_DELETION_APPROVAL',
        entity: 'JOURNEY',
        entityId: journeyId,
        previousValue: 'APPROVED',
        newValue: 'PENDING_DELETION',
        reason: reason ?? 'Deletion approval requested for approved journey',
      );

      addNotification(
        category: NotificationCategory.approval,
        title: 'Deletion Approval Requested',
        message:
            'Deletion request submitted for approved Journey $journeyId and routed to Approving Officer.',
      );

      return false; // Deletion pending approval
    }
  }

  /// Approve deletion of an approved journey (by Approving Officer)
  Future<void> confirmDeletionApproval(
      String journeyId, String approverName) async {
    final index =
        _journeys.indexWhere((j) => j.id == journeyId || j.localId == journeyId);
    if (index == -1) return;

    _journeys.removeAt(index);
    await _saveJourneys();

    _addAudit(
      action: 'APPROVE_JOURNEY_DELETION',
      entity: 'JOURNEY',
      entityId: journeyId,
      previousValue: 'PENDING_DELETION',
      newValue: 'DELETED',
      reason: 'Deletion request approved by $approverName',
    );

    addNotification(
      category: NotificationCategory.approval,
      title: 'Journey Deletion Approved',
      message:
          'Journey $journeyId deletion was approved by $approverName and removed from register.',
    );
  }

  Future<Journey> duplicateJourney(String journeyId) async {
    final idx = _journeys.indexWhere((j) => j.id == journeyId || j.localId == journeyId);
    if (idx == -1) throw Exception('Journey not found');

    final orig = _journeys[idx];
    final now = DateTime.now();
    final localId = 'LOC-JRN-${_uuid.v4().substring(0, 8)}';
    final serverId = _isOfflineMode
        ? localId
        : 'JRN-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 4).toUpperCase()}';

    // Find latest odometer for this vehicle
    final vIdx = _vehicles.indexWhere((v) => v.id == orig.vehicleId);
    final currentOdo = (vIdx != -1) ? _vehicles[vIdx].currentOdometer : orig.openingOdometer;

    final duplicated = Journey(
      id: serverId,
      localId: localId,
      clientOperationId: 'OP-${_uuid.v4()}',
      vehicleId: orig.vehicleId,
      vehicleRegistration: orig.vehicleRegistration,
      vehicleModel: orig.vehicleModel,
      driverId: orig.driverId,
      driverName: orig.driverName,
      officerId: _currentUser?.id ?? orig.officerId,
      officerName: _currentUser?.name ?? orig.officerName,
      userOfficerName: _currentUser?.name ?? orig.userOfficerName,
      userOfficerDesignation: _currentUser?.designation ?? orig.userOfficerDesignation,
      isSubordinateJourney: orig.isSubordinateJourney,
      officerSignatureText: _currentUser?.name ?? orig.officerSignatureText,
      requiresApproval: _currentUser?.requiresApproval ?? orig.requiresApproval,
      department: _currentUser?.department ?? orig.department,
      office: _currentUser?.office ?? orig.office,
      journeyDate: DateTime(now.year, now.month, now.day),
      startTime: now,
      startLocation: orig.startLocation,
      destination: orig.destination,
      purpose: '[Repeat] ${orig.purpose}',
      openingOdometer: currentOdo,
      startLatitude: orig.startLatitude,
      startLongitude: orig.startLongitude,
      category: orig.category,
      status: JourneyStatus.draft,
      syncStatus: _isOfflineMode ? SyncStatus.pending : SyncStatus.synced,
      createdAt: now,
      updatedAt: now,
    );

    _journeys.insert(0, duplicated);
    await _saveJourneys();

    _addAudit(
      action: 'DUPLICATE_JOURNEY',
      entity: 'JOURNEY',
      entityId: duplicated.id,
      newValue: 'Duplicated from ${orig.id} as Draft',
      reason: 'Created draft recurring trip',
    );

    addNotification(
      category: NotificationCategory.journey,
      title: 'Journey Duplicated',
      message: 'Draft journey created from ${orig.id} at ${currentOdo.toStringAsFixed(1)} KM.',
    );

    return duplicated;
  }

  Future<Journey> updateJourneyExpense(
    String journeyId, {
    required double expenseAmount,
    TripCategory? category,
    String? expenseReceiptUrl,
    String? receiptNote,
  }) async {
    final idx = _journeys.indexWhere((j) => j.id == journeyId || j.localId == journeyId);
    if (idx == -1) throw Exception('Journey not found');

    final existing = _journeys[idx];
    final effectiveCategory = category ?? existing.category;
    final note = expenseReceiptUrl ?? receiptNote;
    String? updatedRemarks = existing.remarks;
    if (note != null && note.trim().isNotEmpty) {
      final noteText = '[Expense: ₹${expenseAmount.toStringAsFixed(0)} - $note]';
      updatedRemarks = (updatedRemarks != null && updatedRemarks.isNotEmpty)
          ? '$updatedRemarks\n$noteText'
          : noteText;
    }

    final updated = existing.copyWith(
      expenseAmount: expenseAmount,
      expenseReceiptUrl: note ?? existing.expenseReceiptUrl,
      category: effectiveCategory,
      remarks: updatedRemarks,
      updatedAt: DateTime.now(),
    );

    _journeys[idx] = updated;
    await _saveJourneys();

    _addAudit(
      action: 'LOG_JOURNEY_EXPENSE',
      entity: 'JOURNEY',
      entityId: journeyId,
      newValue: '₹${expenseAmount.toStringAsFixed(2)} (${effectiveCategory.label})',
      reason: note ?? 'Trip expense updated',
    );

    return updated;
  }

  /// Add Quick Log Book Journey directly
  Future<Journey> addQuickLogBookJourney({
    required Vehicle vehicle,
    required String driverId,
    required String driverName,
    required DateTime journeyDate,
    required DateTime startTime,
    required DateTime endTime,
    required String startLocation,
    required String destination,
    required String purpose,
    required double openingOdometer,
    required double closingOdometer,
    String? accompanyingOfficers,
    String? remarks,
    String? userOfficerName,
    String? userOfficerDesignation,
    required bool requiresApproval,
    String? approvingOfficerId,
    String? approvingOfficerName,
  }) async {
    final now = DateTime.now();
    final localId = 'LOC-JRN-${_uuid.v4().substring(0, 8)}';
    final serverId = _isOfflineMode
        ? localId
        : 'JRN-${journeyDate.year}${journeyDate.month.toString().padLeft(2, '0')}${journeyDate.day.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 4).toUpperCase()}';

    final effectiveUserOfficerName =
        userOfficerName ?? _currentUser?.name ?? 'Dr. S. K. Verma';
    final effectiveUserOfficerDesignation = userOfficerDesignation ??
        _currentUser?.designation ??
        'Executive Engineer';

    final isSelfApproving = !requiresApproval ||
        (approvingOfficerName?.toLowerCase().contains('self') == true) ||
        ((_currentUser?.isSelfApprover ?? false) && approvingOfficerId == null);

    final distance = (closingOdometer >= openingOdometer)
        ? (closingOdometer - openingOdometer)
        : 0.0;

    final journey = Journey(
      id: serverId,
      localId: localId,
      clientOperationId: 'OP-${_uuid.v4()}',
      vehicleId: vehicle.id,
      vehicleRegistration: vehicle.registrationNumber,
      vehicleModel: '${vehicle.make} ${vehicle.model}',
      driverId: driverId,
      driverName: driverName,
      officerId: _currentUser?.id ?? 'USR-001',
      officerName: _currentUser?.name ?? 'Dr. S. K. Verma',
      userOfficerName: effectiveUserOfficerName,
      userOfficerDesignation: effectiveUserOfficerDesignation,
      isSubordinateJourney: false,
      officerSignatureText: effectiveUserOfficerName,
      requiresApproval: !isSelfApproving,
      department: _currentUser?.department ?? 'Public Works Department',
      office: _currentUser?.office ?? 'District Division 1, Noida',
      journeyDate:
          DateTime(journeyDate.year, journeyDate.month, journeyDate.day),
      startTime: startTime,
      endTime: endTime,
      startLocation: startLocation,
      destination: destination,
      purpose: purpose,
      openingOdometer: openingOdometer,
      closingOdometer: closingOdometer,
      officialDistance: distance,
      accompanyingOfficers: accompanyingOfficers,
      remarks: remarks,
      status: isSelfApproving
          ? JourneyStatus.approved
          : JourneyStatus.pendingApproval,
      approvedBy: isSelfApproving
          ? '$effectiveUserOfficerName (Self-Approved)'
          : null,
      approvedAt: isSelfApproving ? now : null,
      syncStatus: _isOfflineMode ? SyncStatus.pending : SyncStatus.synced,
      createdAt: now,
      updatedAt: now,
    );

    _journeys.insert(0, journey);
    await _saveJourneys();

    if (closingOdometer > 0) {
      await updateVehicleOdometer(vehicle.id, closingOdometer);
    }

    _addAudit(
      action: isSelfApproving
          ? 'QUICK_LOG_SELF_APPROVED'
          : 'QUICK_LOG_SUBMITTED',
      entity: 'JOURNEY',
      entityId: journey.id,
      newValue:
          'Distance: ${distance.toStringAsFixed(1)} KM | Status: ${journey.status.label}',
      reason: isSelfApproving
          ? 'Quick log entry self-certified by officer'
          : 'Quick log entry submitted for approval to ${approvingOfficerName ?? "designated approver"}',
    );

    addNotification(
      category: isSelfApproving
          ? NotificationCategory.approval
          : NotificationCategory.journey,
      title:
          isSelfApproving ? 'Quick Log Self-Approved' : 'Quick Log Submitted',
      message:
          'Journey ${journey.id} (${distance.toStringAsFixed(1)} KM) was created and ${isSelfApproving ? "self-approved." : "sent for approval."}',
    );

    return journey;
  }

  /// Add multiple day-wise journeys for a quick monthly log book (as Draft or Submitted/Approved)
  Future<List<Journey>> addQuickMonthlyLogBookJourneys({
    required List<Journey> journeys,
    required bool asDraft,
    required bool requiresApproval,
    String? approvingOfficerId,
    String? approvingOfficerName,
  }) async {
    final now = DateTime.now();
    final isSelfApproving = !requiresApproval ||
        (approvingOfficerName?.toLowerCase().contains('self') == true) ||
        ((_currentUser?.isSelfApprover ?? false) && approvingOfficerId == null);

    final List<Journey> processedJourneys = [];
    double highestClosingOdo = 0.0;
    String? vehicleId;

    for (final j in journeys) {
      final localId = j.localId.isNotEmpty
          ? j.localId
          : 'LOC-JRN-${_uuid.v4().substring(0, 8)}';
      final serverId = _isOfflineMode
          ? localId
          : 'JRN-${j.journeyDate.year}${j.journeyDate.month.toString().padLeft(2, '0')}${j.journeyDate.day.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 4).toUpperCase()}';

      final JourneyStatus finalStatus;
      final String? approvedBy;
      final DateTime? approvedAt;

      if (asDraft) {
        finalStatus = JourneyStatus.draft;
        approvedBy = null;
        approvedAt = null;
      } else if (isSelfApproving) {
        finalStatus = JourneyStatus.approved;
        approvedBy = '${j.userOfficerName} (Self-Approved)';
        approvedAt = now;
      } else {
        finalStatus = JourneyStatus.pendingApproval;
        approvedBy = null;
        approvedAt = null;
      }

      vehicleId = j.vehicleId;
      if ((j.closingOdometer ?? 0) > highestClosingOdo) {
        highestClosingOdo = j.closingOdometer ?? 0;
      }

      final processed = j.copyWith(
        id: serverId,
        localId: localId,
        status: finalStatus,
        approvedBy: approvedBy,
        approvedAt: approvedAt,
        requiresApproval: !isSelfApproving,
        updatedAt: now,
      );

      processedJourneys.add(processed);
      _journeys.insert(0, processed);
    }

    await _saveJourneys();

    if (vehicleId != null && highestClosingOdo > 0) {
      await updateVehicleOdometer(vehicleId, highestClosingOdo);
    }

    final monthLabel = journeys.isNotEmpty
        ? DateFormat('MMMM yyyy').format(journeys.first.journeyDate)
        : 'Month';

    _addAudit(
      action: asDraft
          ? 'SAVE_MONTHLY_LOG_DRAFT'
          : (isSelfApproving
              ? 'MONTHLY_LOG_SELF_APPROVED'
              : 'MONTHLY_LOG_SUBMITTED'),
      entity: 'MONTHLY_LOG',
      entityId: monthLabel,
      newValue:
          '${journeys.length} daily entries (${asDraft ? "DRAFT" : (isSelfApproving ? "APPROVED" : "PENDING_APPROVAL")})',
      reason: asDraft
          ? 'Monthly quick log book saved as draft'
          : (isSelfApproving
              ? 'Monthly quick log book self-certified by officer'
              : 'Monthly quick log book submitted for approval to ${approvingOfficerName ?? "approver"}'),
    );

    addNotification(
      category: asDraft
          ? NotificationCategory.journey
          : NotificationCategory.approval,
      title: asDraft
          ? 'Monthly Log Draft Saved'
          : (isSelfApproving
              ? 'Monthly Log Self-Approved'
              : 'Monthly Log Submitted'),
      message:
          'Quick Monthly Log Book for $monthLabel (${journeys.length} days) ${asDraft ? "saved as draft." : (isSelfApproving ? "self-approved." : "submitted for approval.")}',
    );

    return processedJourneys;
  }

  Future<void> updateVehicleOdometer(String vehicleId, double newOdometer) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final v = _vehicles[index];
      if (newOdometer > v.currentOdometer) {
        _vehicles[index] = v.copyWith(currentOdometer: newOdometer);
        await _saveVehicles();
      }
    }
  }

  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    _vehicles.insert(0, vehicle);
    await _saveVehicles();

    // If current user is an individual user and has no assigned vehicle, assign this new one
    if (_currentUser != null && _currentUser!.isIndividual) {
      if (_currentUser!.assignedVehicleId == null || _currentUser!.assignedVehicleId!.isEmpty) {
        final updatedUser = _currentUser!.copyWith(assignedVehicleId: vehicle.id);
        _currentUser = updatedUser;
        final uIdx = _users.indexWhere((u) => u.id == updatedUser.id);
        if (uIdx != -1) {
          _users[uIdx] = updatedUser;
          await _saveUsers();
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyActiveUser, jsonEncode(updatedUser.toJson()));
      }
    } else if (_currentUser != null && _currentUser!.isCompanyAdmin) {
      // Increment organization vehicle count
      final orgId = _currentUser!.organizationId;
      if (orgId.isNotEmpty) {
        final oIdx = _organizations.indexWhere((o) => o.id == orgId);
        if (oIdx != -1) {
          _organizations[oIdx] = _organizations[oIdx].copyWith(
            activeVehiclesCount: _organizations[oIdx].activeVehiclesCount + 1,
          );
          await _saveOrganizations();
        }
      }
    }

    _addAudit(
      action: 'ADD_VEHICLE',
      entity: 'VEHICLE',
      entityId: vehicle.id,
      newValue: '${vehicle.displayName} (${vehicle.fuelType})',
      reason: 'Vehicle registered in fleet / logbook',
    );

    addNotification(
      category: NotificationCategory.vehicle,
      title: 'Vehicle Added',
      message: 'Vehicle ${vehicle.registrationNumber} was successfully added.',
    );

    return vehicle;
  }

  Future<Vehicle> updateVehicle(Vehicle updated) async {
    final idx = _vehicles.indexWhere((v) => v.id == updated.id);
    if (idx == -1) throw Exception('Vehicle not found');

    final previous = _vehicles[idx];
    _vehicles[idx] = updated;
    await _saveVehicles();

    _addAudit(
      action: 'UPDATE_VEHICLE',
      entity: 'VEHICLE',
      entityId: updated.id,
      previousValue: previous.displayName,
      newValue: updated.displayName,
      reason: 'Vehicle details updated',
    );

    addNotification(
      category: NotificationCategory.vehicle,
      title: 'Vehicle Updated',
      message: 'Details for ${updated.registrationNumber} were updated.',
    );

    return updated;
  }

  Future<bool> deleteVehicle(String vehicleId, {String? reason}) async {
    final idx = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (idx == -1) return false;

    final vehicle = _vehicles[idx];
    _vehicles.removeAt(idx);
    await _saveVehicles();

    // Decrement org vehicle count if company admin
    if (_currentUser?.organizationId != null) {
      final oIdx = _organizations.indexWhere((o) => o.id == _currentUser!.organizationId);
      if (oIdx != -1 && _organizations[oIdx].activeVehiclesCount > 0) {
        _organizations[oIdx] = _organizations[oIdx].copyWith(
          activeVehiclesCount: _organizations[oIdx].activeVehiclesCount - 1,
        );
        await _saveOrganizations();
      }
    }

    // Unassign vehicle from users if assigned
    for (int i = 0; i < _users.length; i++) {
      if (_users[i].assignedVehicleId == vehicleId) {
        _users[i] = _users[i].copyWith(clearAssignedVehicle: true);
      }
    }
    await _saveUsers();

    if (_currentUser?.assignedVehicleId == vehicleId) {
      _currentUser = _currentUser!.copyWith(clearAssignedVehicle: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyActiveUser, jsonEncode(_currentUser!.toJson()));
    }

    _addAudit(
      action: 'DECOMMISSION_VEHICLE',
      entity: 'VEHICLE',
      entityId: vehicleId,
      previousValue: vehicle.displayName,
      newValue: 'DECOMMISSIONED / REMOVED',
      reason: reason ?? 'Vehicle decommissioned from active fleet',
    );

    addNotification(
      category: NotificationCategory.vehicle,
      title: 'Vehicle Removed',
      message: 'Vehicle ${vehicle.registrationNumber} was decommissioned from fleet.',
    );

    return true;
  }

  Future<Vehicle> renewVehicleDocument(String vehicleId, VehicleDocument document) async {
    final idx = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (idx == -1) throw Exception('Vehicle not found');

    final vehicle = _vehicles[idx];
    final updatedDocs = List<VehicleDocument>.from(vehicle.documents);
    final docIdx = updatedDocs.indexWhere((d) => d.type == document.type || d.id == document.id);
    if (docIdx != -1) {
      updatedDocs[docIdx] = document;
    } else {
      updatedDocs.add(document);
    }

    final updatedVehicle = vehicle.copyWith(documents: updatedDocs);
    _vehicles[idx] = updatedVehicle;
    await _saveVehicles();

    _addAudit(
      action: 'RENEW_DOCUMENT',
      entity: 'VEHICLE',
      entityId: vehicleId,
      newValue: '${document.type.label} renewed: #${document.documentNumber}',
      reason: 'Valid until ${DateFormat('dd MMM yyyy').format(document.expiryDate)}',
    );

    addNotification(
      category: NotificationCategory.document,
      title: 'Document Renewed',
      message: '${document.type.label} for ${vehicle.registrationNumber} renewed successfully.',
    );

    return updatedVehicle;
  }

  Future<void> addFuelEntry(FuelEntry entry) async {
    _fuelEntries.insert(0, entry);
    await _saveFuel();
    await updateVehicleOdometer(entry.vehicleId, entry.odometerKm);
    _addAudit(
      action: 'ADD_FUEL_RECORD',
      entity: 'VEHICLE',
      entityId: entry.vehicleId,
      newValue: '${entry.quantityLiters}L @ ₹${entry.ratePerLiter} (₹${entry.totalAmount})',
      reason: 'Fuel logged at ${entry.fuelStation}',
    );
  }

  Future<void> addMaintenanceRecord(MaintenanceRecord record) async {
    _maintenanceRecords.insert(0, record);
    await _saveMaintenance();

    // Auto-sync vehicle next service parameters
    final vIdx = _vehicles.indexWhere((v) => v.id == record.vehicleId);
    if (vIdx != -1) {
      _vehicles[vIdx] = _vehicles[vIdx].copyWith(
        nextServiceKm: record.nextServiceKm,
        nextServiceDate: record.nextServiceDate,
      );
      await _saveVehicles();
    }

    _addAudit(
      action: 'ADD_MAINTENANCE_RECORD',
      entity: 'VEHICLE',
      entityId: record.vehicleId,
      newValue: '${record.serviceType} (₹${record.cost}) by ${record.vendor}',
      reason: record.workPerformed,
    );

    addNotification(
      category: NotificationCategory.maintenance,
      title: 'Maintenance Service Logged',
      message: '${record.serviceType} logged for vehicle. Next service due at ${record.nextServiceKm.toStringAsFixed(0)} KM.',
    );
  }

  List<MaintenanceRecord> getMaintenanceRecordsForVehicle(String vehicleId) {
    return _maintenanceRecords.where((m) => m.vehicleId == vehicleId).toList();
  }

  double getTotalMaintenanceCostForVehicle(String vehicleId) {
    return _maintenanceRecords
        .where((m) => m.vehicleId == vehicleId)
        .fold(0.0, (sum, m) => sum + m.cost);
  }

  List<Vehicle> getVehiclesRequiringService() {
    return _vehicles
        .where((v) => v.isServiceDue || v.isServiceDueSoon)
        .toList();
  }

  // --- Offline Sync Engine ---
  int get pendingSyncCount =>
      _journeys.where((j) => j.syncStatus == SyncStatus.pending).length;

  Future<int> syncPendingRecords() async {
    int syncedCount = 0;
    for (int i = 0; i < _journeys.length; i++) {
      if (_journeys[i].syncStatus == SyncStatus.pending) {
        _journeys[i] = _journeys[i].copyWith(
          syncStatus: SyncStatus.synced,
          updatedAt: DateTime.now(),
        );
        syncedCount++;
      }
    }
    if (syncedCount > 0) {
      await _saveJourneys();
      addNotification(
        category: NotificationCategory.system,
        title: 'Sync Complete',
        message: 'Successfully synchronized $syncedCount pending records to the server.',
      );
    }
    return syncedCount;
  }

  void addNotification({
    String? userId,
    required NotificationCategory category,
    required String title,
    required String message,
    String? targetRoute,
  }) {
    final notif = NotificationItem(
      id: 'NOTIF-${_uuid.v4().substring(0, 8)}',
      userId: userId ?? _currentUser?.id,
      category: category,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      targetRoute: targetRoute,
    );
    _notifications.insert(0, notif);
    _saveNotifications();
  }

  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _saveNotifications();
    }
  }

  void markAllNotificationsAsRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _saveNotifications();
  }

  void _addAudit({
    required String action,
    required String entity,
    required String entityId,
    String? field,
    String? previousValue,
    String? newValue,
    String? reason,
  }) {
    _auditLogs.insert(
      0,
      AuditLog(
        id: 'AUD-${_uuid.v4().substring(0, 8)}',
        userId: _currentUser?.id ?? 'USR-001',
        userName: _currentUser?.name ?? 'Dr. S. K. Verma',
        action: action,
        entity: entity,
        entityId: entityId,
        field: field,
        previousValue: previousValue,
        newValue: newValue,
        reason: reason,
        timestamp: DateTime.now(),
      ),
    );
    _saveAuditLogs();
  }

  // --- Persistence Helpers ---
  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKeyUsers, jsonEncode(_users.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKeyVehicles, jsonEncode(_vehicles.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveJourneys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKeyJourneys, jsonEncode(_journeys.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveFuel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKeyFuel, jsonEncode(_fuelEntries.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveMaintenance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyMaint,
        jsonEncode(_maintenanceRecords.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKeyNotifs,
      jsonEncode(_notifications.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyOfflineMode, _isOfflineMode);
  }

  // --- Organization & Multi-Tenant Helpers ---
  Future<void> _saveOrganizations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKeyOrgs, jsonEncode(_organizations.map((e) => e.toJson()).toList()));
  }

  Future<Organization> createOrganization({
    required String name,
    required String adminId,
    required String adminName,
    required String contactEmail,
    required String contactMobile,
    SubscriptionTier tier = SubscriptionTier.free,
  }) async {
    final prefix = name.trim().replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final codePrefix = prefix.length >= 3 ? prefix.substring(0, 3) : 'ORG';
    final randomDigits = (DateTime.now().millisecondsSinceEpoch % 9000 + 1000).toString();
    final joinCode = '$codePrefix-$randomDigits';
    final orgId = 'ORG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final org = Organization(
      id: orgId,
      name: name,
      code: joinCode,
      adminId: adminId,
      adminName: adminName,
      contactEmail: contactEmail,
      contactMobile: contactMobile,
      subscriptionTier: tier,
      activeVehiclesCount: 1,
      activeMembersCount: 1,
      createdAt: DateTime.now(),
      isVerified: true,
    );

    _organizations.add(org);
    await _saveOrganizations();

    // Link current admin user to this organization
    final userIdx = _users.indexWhere((u) => u.id == adminId);
    if (userIdx != -1) {
      final updatedAdmin = _users[userIdx].copyWith(
        organizationId: org.id,
        organizationName: org.name,
        role: UserRole.companyAdmin,
        isIndividual: false,
      );
      _users[userIdx] = updatedAdmin;
      await _saveUsers();
      if (_currentUser?.id == adminId) {
        _currentUser = updatedAdmin;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyActiveUser, jsonEncode(updatedAdmin.toJson()));
      }
    }

    return org;
  }

  Organization? getOrganizationByCode(String code) {
    final clean = code.trim().toUpperCase();
    return _organizations.cast<Organization?>().firstWhere(
          (o) => o?.code.toUpperCase() == clean,
          orElse: () => null,
        );
  }

  Organization? getOrganizationById(String id) {
    return _organizations.cast<Organization?>().firstWhere(
          (o) => o?.id == id,
          orElse: () => null,
        );
  }

  Future<bool> joinOrganizationByCode(String userId, String code) async {
    final org = getOrganizationByCode(code);
    if (org == null) return false;

    final userIdx = _users.indexWhere((u) => u.id == userId);
    if (userIdx != -1) {
      final updatedUser = _users[userIdx].copyWith(
        organizationId: org.id,
        organizationName: org.name,
        joinCodeUsed: org.code,
        isIndividual: false,
      );
      _users[userIdx] = updatedUser;
      await _saveUsers();
      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyActiveUser, jsonEncode(updatedUser.toJson()));
      }
    }

    final orgIdx = _organizations.indexWhere((o) => o.id == org.id);
    if (orgIdx != -1) {
      _organizations[orgIdx] = _organizations[orgIdx].copyWith(
        activeMembersCount: _organizations[orgIdx].activeMembersCount + 1,
      );
      await _saveOrganizations();
    }
    return true;
  }

  /// Update an organization's subscription tier (Super Admin or B2B upgrade)
  Future<bool> updateOrganizationTier(String orgId, SubscriptionTier newTier) async {
    final orgIdx = _organizations.indexWhere((o) => o.id == orgId);
    if (orgIdx == -1) return false;
    _organizations[orgIdx] = _organizations[orgIdx].copyWith(subscriptionTier: newTier);
    await _saveOrganizations();

    // If current user belongs to this org, sync their active state
    if (_currentUser?.organizationId == orgId) {
      final updatedUser = _currentUser!.copyWith(personalSubscriptionTier: newTier);
      _currentUser = updatedUser;
      final uIdx = _users.indexWhere((u) => u.id == updatedUser.id);
      if (uIdx != -1) {
        _users[uIdx] = updatedUser;
        await _saveUsers();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyActiveUser, jsonEncode(updatedUser.toJson()));
    }
    return true;
  }

  /// Update an individual user's personal subscription tier (Pro Individual)
  Future<bool> updateUserSubscriptionTier(String userId, SubscriptionTier newTier) async {
    final userIdx = _users.indexWhere((u) => u.id == userId);
    if (userIdx == -1) return false;
    final updated = _users[userIdx].copyWith(personalSubscriptionTier: newTier);
    _users[userIdx] = updated;
    await _saveUsers();
    if (_currentUser?.id == userId) {
      _currentUser = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyActiveUser, jsonEncode(updated.toJson()));
    }
    return true;
  }

  // --- Membership Requests & Approvals ---
  List<MembershipRequest> get membershipRequests =>
      List.unmodifiable(_membershipRequests);

  List<MembershipRequest> getPendingMembershipRequests(String orgId) {
    return _membershipRequests
        .where((r) => r.organizationId == orgId && r.isPending)
        .toList();
  }

  Future<void> _saveMembershipRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKeyMembershipReqs,
      jsonEncode(_membershipRequests.map((e) => e.toJson()).toList()),
    );
  }

  List<MembershipRequest> _createDemoMembershipRequests() {
    return [
      MembershipRequest(
        id: 'REQ-DEMO-01',
        organizationId: 'ORG-PWD-01',
        organizationName: 'Public Works Department (PWD)',
        organizationCode: 'PWD-8042',
        userId: 'USR-REQ-101',
        userName: 'Arjun Verma',
        userEmail: 'arjun.verma@pwd-field.gov.in',
        userMobile: '+91 98765 43210',
        requestedRole: UserRole.driver,
        status: MembershipRequestStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      MembershipRequest(
        id: 'REQ-DEMO-02',
        organizationId: 'ORG-PWD-01',
        organizationName: 'Public Works Department (PWD)',
        organizationCode: 'PWD-8042',
        userId: 'USR-REQ-102',
        userName: 'Priya Sharma',
        userEmail: 'priya.sharma@pwd-ops.gov.in',
        userMobile: '+91 98111 22334',
        requestedRole: UserRole.user,
        status: MembershipRequestStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<MembershipRequest> submitMembershipRequest({
    required String orgCode,
    required User user,
    UserRole requestedRole = UserRole.driver,
  }) async {
    final org = getOrganizationByCode(orgCode);
    if (org == null) {
      throw Exception('Invalid organization join code: $orgCode');
    }

    final reqId = 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final request = MembershipRequest(
      id: reqId,
      organizationId: org.id,
      organizationName: org.name,
      organizationCode: org.code,
      userId: user.id,
      userName: user.name,
      userEmail: user.email,
      userMobile: user.mobile,
      requestedRole: requestedRole,
      status: MembershipRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    _membershipRequests.insert(0, request);
    await _saveMembershipRequests();

    _addAudit(
      action: 'SUBMIT_MEMBERSHIP_REQUEST',
      entity: 'ORGANIZATION',
      entityId: org.id,
      newValue: 'User ${user.name} requested to join as ${requestedRole.label}',
      reason: 'Entered Join Code $orgCode',
    );

    return request;
  }

  Future<bool> approveMembershipRequest(
    String requestId, {
    required UserRole assignedRole,
    required String approvedBy,
    String? remarks,
  }) async {
    final idx = _membershipRequests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return false;

    final req = _membershipRequests[idx];
    final updatedReq = req.copyWith(
      status: MembershipRequestStatus.approved,
      requestedRole: assignedRole,
      reviewedAt: DateTime.now(),
      reviewedBy: approvedBy,
      reviewRemarks: remarks ?? 'Approved by Company Admin',
    );
    _membershipRequests[idx] = updatedReq;
    await _saveMembershipRequests();

    // Promote user into organization
    final userIdx = _users.indexWhere((u) => u.id == req.userId);
    if (userIdx != -1) {
      final updatedUser = _users[userIdx].copyWith(
        organizationId: req.organizationId,
        organizationName: req.organizationName,
        role: assignedRole,
        joinCodeUsed: req.organizationCode,
        isIndividual: false,
        requiresApproval: true,
      );
      _users[userIdx] = updatedUser;
      await _saveUsers();

      if (_currentUser?.id == req.userId) {
        _currentUser = updatedUser;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyActiveUser, jsonEncode(updatedUser.toJson()));
      }
    }

    // Increment active members in org
    final orgIdx = _organizations.indexWhere((o) => o.id == req.organizationId);
    if (orgIdx != -1) {
      _organizations[orgIdx] = _organizations[orgIdx].copyWith(
        activeMembersCount: _organizations[orgIdx].activeMembersCount + 1,
      );
      await _saveOrganizations();
    }

    _addAudit(
      action: 'APPROVE_MEMBERSHIP_REQUEST',
      entity: 'ORGANIZATION',
      entityId: req.organizationId,
      newValue: 'Approved ${req.userName} as ${assignedRole.label}',
      reason: remarks ?? 'Admin Approval',
    );

    return true;
  }

  Future<bool> rejectMembershipRequest(
    String requestId, {
    required String rejectedBy,
    String? remarks,
  }) async {
    final idx = _membershipRequests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return false;

    final req = _membershipRequests[idx];
    final updatedReq = req.copyWith(
      status: MembershipRequestStatus.rejected,
      reviewedAt: DateTime.now(),
      reviewedBy: rejectedBy,
      reviewRemarks: remarks ?? 'Rejected by Company Admin',
    );
    _membershipRequests[idx] = updatedReq;
    await _saveMembershipRequests();

    _addAudit(
      action: 'REJECT_MEMBERSHIP_REQUEST',
      entity: 'ORGANIZATION',
      entityId: req.organizationId,
      newValue: 'Rejected join request for ${req.userName}',
      reason: remarks ?? 'Admin Rejection',
    );

    return true;
  }

  /// Update an organization's status (Active, Suspended, Pending Verification)
  Future<bool> updateOrganizationStatus(
    String orgId,
    OrganizationStatus newStatus, {
    String? reason,
  }) async {
    final orgIdx = _organizations.indexWhere((o) => o.id == orgId);
    if (orgIdx == -1) return false;

    _organizations[orgIdx] = _organizations[orgIdx].copyWith(
      status: newStatus,
      statusReason: reason,
    );
    await _saveOrganizations();

    _addAudit(
      action: 'UPDATE_ORGANIZATION_STATUS',
      entity: 'ORGANIZATION',
      entityId: orgId,
      newValue: 'Status changed to ${newStatus.label}',
      reason: reason ?? 'Super Admin Lifecycle Action',
    );

    return true;
  }

  Future<Organization> updateOrganization(Organization updated) async {
    final idx = _organizations.indexWhere((o) => o.id == updated.id);
    if (idx == -1) throw Exception('Organization not found');

    final prev = _organizations[idx];
    _organizations[idx] = updated;
    await _saveOrganizations();

    // If org name changed, update enrolled users
    if (prev.name != updated.name) {
      for (int i = 0; i < _users.length; i++) {
        if (_users[i].organizationId == updated.id) {
          _users[i] = _users[i].copyWith(organizationName: updated.name);
        }
      }
      await _saveUsers();
      if (_currentUser?.organizationId == updated.id) {
        _currentUser = _currentUser!.copyWith(organizationName: updated.name);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyActiveUser, jsonEncode(_currentUser!.toJson()));
      }
    }

    _addAudit(
      action: 'UPDATE_ORGANIZATION',
      entity: 'ORGANIZATION',
      entityId: updated.id,
      previousValue: prev.name,
      newValue: updated.name,
      reason: 'Organization profile updated by Admin',
    );

    return updated;
  }

  Future<bool> deleteOrganization(String orgId, {String? reason}) async {
    final idx = _organizations.indexWhere((o) => o.id == orgId);
    if (idx == -1) return false;

    final org = _organizations[idx];
    _organizations.removeAt(idx);
    await _saveOrganizations();

    // Safe unlinking of all members back to individual users
    for (int i = 0; i < _users.length; i++) {
      if (_users[i].organizationId == orgId) {
        _users[i] = _users[i].copyWith(
          isIndividual: true,
          clearOrganization: true,
          role: UserRole.individualUser,
        );
      }
    }
    await _saveUsers();

    if (_currentUser?.organizationId == orgId) {
      _currentUser = _currentUser!.copyWith(
        isIndividual: true,
        clearOrganization: true,
        role: UserRole.individualUser,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyActiveUser, jsonEncode(_currentUser!.toJson()));
    }

    _addAudit(
      action: 'ARCHIVE_ORGANIZATION',
      entity: 'ORGANIZATION',
      entityId: orgId,
      previousValue: org.name,
      newValue: 'ARCHIVED / REMOVED',
      reason: reason ?? 'Organization decommissioned by Super Admin',
    );

    return true;
  }

  Future<String> regenerateOrganizationCode(String orgId) async {
    final idx = _organizations.indexWhere((o) => o.id == orgId);
    if (idx == -1) throw Exception('Organization not found');

    final org = _organizations[idx];
    final prefix = org.name.trim().replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final codePrefix = prefix.length >= 3 ? prefix.substring(0, 3) : 'ORG';
    final randomDigits = (DateTime.now().millisecondsSinceEpoch % 9000 + 1000).toString();
    final newCode = '$codePrefix-$randomDigits';

    _organizations[idx] = org.copyWith(code: newCode);
    await _saveOrganizations();

    _addAudit(
      action: 'REGENERATE_JOIN_CODE',
      entity: 'ORGANIZATION',
      entityId: orgId,
      previousValue: org.code,
      newValue: newCode,
      reason: 'Join code refreshed for security',
    );

    addNotification(
      category: NotificationCategory.system,
      title: 'New Join Code Generated',
      message: 'New Join Code for ${org.name} is $newCode',
    );

    return newCode;
  }

  Future<User> addOrganizationMember({
    required String orgId,
    required String orgName,
    required String name,
    required String mobile,
    required String designation,
    required String department,
    required UserRole role,
    String? assignedVehicleId,
  }) async {
    final now = DateTime.now();
    final user = User(
      id: 'USR-${_uuid.v4().substring(0, 6).toUpperCase()}',
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '.')}@fleet.local',
      mobile: mobile,
      employeeId: 'EMP-${_uuid.v4().substring(0, 4).toUpperCase()}',
      role: role,
      organizationId: orgId,
      organizationName: orgName,
      department: department,
      designation: designation,
      office: 'HQ',
      assignedVehicleId: assignedVehicleId,
      isIndividual: false,
      requiresApproval: role == UserRole.user || role == UserRole.driver,
      createdAt: now,
    );
    return addMemberUser(user);
  }

  Future<User> addMemberUser(User user) async {
    _users.insert(0, user);
    await _saveUsers();

    if (user.organizationId.isNotEmpty) {
      final oIdx = _organizations.indexWhere((o) => o.id == user.organizationId);
      if (oIdx != -1) {
        _organizations[oIdx] = _organizations[oIdx].copyWith(
          activeMembersCount: _organizations[oIdx].activeMembersCount + 1,
        );
        await _saveOrganizations();
      }
    }

    _addAudit(
      action: 'DIRECT_ADD_MEMBER',
      entity: 'USER',
      entityId: user.id,
      newValue: '${user.name} (${user.role.label})',
      reason: 'Enrolled directly by Organization Admin',
    );

    addNotification(
      category: NotificationCategory.system,
      title: 'Member Added',
      message: '${user.name} was added to the organization as ${user.role.label}.',
    );

    return user;
  }

  Future<User> updateMemberRole(
    String userId, {
    UserRole? newRole,
    String? assignedVehicleId,
    String? designation,
    String? department,
    String? office,
    bool clearVehicleAssignment = false,
  }) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx == -1) throw Exception('User not found');

    final existing = _users[idx];
    final effectiveRole = newRole ?? existing.role;
    final updated = existing.copyWith(
      role: effectiveRole,
      assignedVehicleId: clearVehicleAssignment ? null : (assignedVehicleId ?? existing.assignedVehicleId),
      clearAssignedVehicle: clearVehicleAssignment,
      designation: designation ?? existing.designation,
      department: department ?? existing.department,
      office: office ?? existing.office,
      requiresApproval: effectiveRole == UserRole.user || effectiveRole == UserRole.driver,
    );

    _users[idx] = updated;
    await _saveUsers();

    if (_currentUser?.id == userId) {
      _currentUser = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyActiveUser, jsonEncode(updated.toJson()));
    }

    // Also update vehicle's assignedDriver if assignedVehicleId changed
    if (clearVehicleAssignment) {
      for (int i = 0; i < _vehicles.length; i++) {
        if (_vehicles[i].assignedDriverId == userId) {
          _vehicles[i] = _vehicles[i].copyWith(
            clearAssignedDriver: true,
            assignedDriverName: 'Unassigned',
          );
        }
      }
      await _saveVehicles();
    } else if (assignedVehicleId != null && assignedVehicleId.isNotEmpty) {
      final vIdx = _vehicles.indexWhere((v) => v.id == assignedVehicleId);
      if (vIdx != -1) {
        _vehicles[vIdx] = _vehicles[vIdx].copyWith(
          assignedDriverId: updated.id,
          assignedDriverName: updated.name,
        );
        await _saveVehicles();
      }
    }

    _addAudit(
      action: 'UPDATE_MEMBER_ROLE',
      entity: 'USER',
      entityId: userId,
      previousValue: existing.role.label,
      newValue: effectiveRole.label,
      reason: 'Member role and assignments updated by Admin',
    );

    return updated;
  }

  Future<bool> removeMemberFromOrganization(String userId, {String? reason}) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx == -1) return false;

    final existing = _users[idx];
    final orgId = existing.organizationId;

    final updated = existing.copyWith(
      isIndividual: true,
      clearOrganization: true,
      role: UserRole.individualUser,
      clearAssignedVehicle: true,
    );

    _users[idx] = updated;
    await _saveUsers();

    if (_currentUser?.id == userId) {
      _currentUser = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyActiveUser, jsonEncode(updated.toJson()));
    }

    if (orgId.isNotEmpty) {
      final oIdx = _organizations.indexWhere((o) => o.id == orgId);
      if (oIdx != -1 && _organizations[oIdx].activeMembersCount > 0) {
        _organizations[oIdx] = _organizations[oIdx].copyWith(
          activeMembersCount: _organizations[oIdx].activeMembersCount - 1,
        );
        await _saveOrganizations();
      }
    }

    _addAudit(
      action: 'REMOVE_MEMBER',
      entity: 'USER',
      entityId: userId,
      previousValue: existing.name,
      newValue: 'REMOVED_TO_INDIVIDUAL',
      reason: reason ?? 'Unlinked from organization by Admin',
    );

    return true;
  }

  void broadcastSystemNotification(
    String title,
    String message, {
    String? targetOrgId,
  }) {
    if (targetOrgId != null && targetOrgId.isNotEmpty) {
      final orgUsers = _users.where((u) => u.organizationId == targetOrgId).toList();
      for (final u in orgUsers) {
        addNotification(
          userId: u.id,
          category: NotificationCategory.system,
          title: title,
          message: message,
        );
      }
    } else {
      addNotification(
        userId: null,
        category: NotificationCategory.system,
        title: title,
        message: message,
      );
    }

    _addAudit(
      action: 'BROADCAST_ANNOUNCEMENT',
      entity: 'SYSTEM',
      entityId: targetOrgId ?? 'ALL',
      newValue: title,
      reason: message,
    );
  }

  String exportPlatformDataJson() {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'organizations': _organizations.map((o) => o.toJson()).toList(),
      'users': _users.map((u) => u.toJson()).toList(),
      'vehicles': _vehicles.map((v) => v.toJson()).toList(),
      'journeys': _journeys.map((j) => j.toJson()).toList(),
      'fuel_entries': _fuelEntries.map((f) => f.toJson()).toList(),
      'maintenance_records': _maintenanceRecords.map((m) => m.toJson()).toList(),
      'audit_logs': _auditLogs.map((a) => a.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> _saveAuditLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKeyAudit,
        jsonEncode(_auditLogs.take(200).map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  void _seedInitialAuditLogs() {
    final now = DateTime.now();
    _auditLogs.addAll([
      AuditLog(
        id: 'AUD-INIT-01',
        userId: 'USR-SUPER',
        userName: 'Super Admin',
        action: 'SYSTEM_BOOTSTRAP',
        entity: 'SYSTEM',
        entityId: 'SYS-GLOBAL',
        newValue: 'v2.0 Enterprise Release initialized',
        reason: 'Platform initialization and multi-tenant schema ready',
        timestamp: now.subtract(const Duration(days: 30)),
      ),
      AuditLog(
        id: 'AUD-INIT-02',
        userId: 'USR-004',
        userName: 'Vikram Singh',
        action: 'REGISTER_ORGANIZATION',
        entity: 'ORGANIZATION',
        entityId: 'ORG-PWD-01',
        newValue: 'Public Works Department (PWD)',
        reason: 'Government division enterprise onboarding',
        timestamp: now.subtract(const Duration(days: 28)),
      ),
      AuditLog(
        id: 'AUD-INIT-03',
        userId: 'USR-001',
        userName: 'Dr. S. K. Verma',
        action: 'ASSIGN_VEHICLE',
        entity: 'VEHICLE',
        entityId: 'VEH-001',
        newValue: 'UP16 AB 1234 assigned to Dr. S. K. Verma',
        reason: 'Executive inspection vehicle deployment',
        timestamp: now.subtract(const Duration(days: 25)),
      ),
    ]);
  }
}

