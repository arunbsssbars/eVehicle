import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journey.dart';
import '../models/vehicle.dart';
import '../storage/local_database.dart';
import 'auth_provider.dart';

class JourneyState {
  final List<Journey> journeys;
  final Journey? activeJourney;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final JourneyStatus? statusFilter;
  final String? vehicleFilter;
  final DateTime? dateFilter;

  const JourneyState({
    this.journeys = const [],
    this.activeJourney,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.statusFilter,
    this.vehicleFilter,
    this.dateFilter,
  });

  List<Journey> get filteredJourneys {
    return journeys.where((j) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final match = j.vehicleRegistration.toLowerCase().contains(q) ||
            j.destination.toLowerCase().contains(q) ||
            j.startLocation.toLowerCase().contains(q) ||
            j.purpose.toLowerCase().contains(q) ||
            j.driverName.toLowerCase().contains(q) ||
            j.id.toLowerCase().contains(q);
        if (!match) return false;
      }
      if (statusFilter != null && j.status != statusFilter) {
        return false;
      }
      if (vehicleFilter != null &&
          vehicleFilter!.isNotEmpty &&
          j.vehicleId != vehicleFilter) {
        return false;
      }
      if (dateFilter != null) {
        if (j.journeyDate.year != dateFilter!.year ||
            j.journeyDate.month != dateFilter!.month ||
            j.journeyDate.day != dateFilter!.day) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // Dashboard Stats Calculations
  double get todayDistance {
    final now = DateTime.now();
    return journeys
        .where((j) =>
            j.journeyDate.year == now.year &&
            j.journeyDate.month == now.month &&
            j.journeyDate.day == now.day &&
            (j.status == JourneyStatus.approved ||
                j.status == JourneyStatus.pendingApproval ||
                j.status == JourneyStatus.completed ||
                j.status == JourneyStatus.locked))
        .fold(0.0, (sum, j) => sum + j.calculatedDistance);
  }

  int get todayJourneysCount {
    final now = DateTime.now();
    return journeys
        .where((j) =>
            j.journeyDate.year == now.year &&
            j.journeyDate.month == now.month &&
            j.journeyDate.day == now.day)
        .length;
  }

  double get monthlyDistance {
    final now = DateTime.now();
    return journeys
        .where((j) =>
            j.journeyDate.year == now.year &&
            j.journeyDate.month == now.month &&
            (j.status == JourneyStatus.approved ||
                j.status == JourneyStatus.pendingApproval ||
                j.status == JourneyStatus.completed ||
                j.status == JourneyStatus.locked))
        .fold(0.0, (sum, j) => sum + j.calculatedDistance);
  }

  int get pendingApprovalsCount {
    return journeys
        .where((j) =>
            j.status == JourneyStatus.pendingApproval ||
            j.status == JourneyStatus.submitted)
        .length;
  }

  JourneyState copyWith({
    List<Journey>? journeys,
    Journey? activeJourney,
    bool clearActiveJourney = false,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    JourneyStatus? statusFilter,
    bool clearStatusFilter = false,
    String? vehicleFilter,
    bool clearVehicleFilter = false,
    DateTime? dateFilter,
    bool clearDateFilter = false,
  }) {
    return JourneyState(
      journeys: journeys ?? this.journeys,
      activeJourney:
          clearActiveJourney ? null : (activeJourney ?? this.activeJourney),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      vehicleFilter:
          clearVehicleFilter ? null : (vehicleFilter ?? this.vehicleFilter),
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
    );
  }
}

class JourneyNotifier extends StateNotifier<JourneyState> {
  JourneyNotifier() : super(const JourneyState()) {
    refresh();
  }

  void refresh() {
    final dbJourneys = LocalDatabase.instance.journeys;
    final active = LocalDatabase.instance.getActiveJourney();
    state = state.copyWith(
      journeys: dbJourneys,
      activeJourney: active,
      clearActiveJourney: active == null,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(JourneyStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }

  void setVehicleFilter(String? vehicleId) {
    if (vehicleId == null) {
      state = state.copyWith(clearVehicleFilter: true);
    } else {
      state = state.copyWith(vehicleFilter: vehicleId);
    }
  }

  void setDateFilter(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearDateFilter: true);
    } else {
      state = state.copyWith(dateFilter: date);
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
    state = state.copyWith(isLoading: true);
    final journey = await LocalDatabase.instance.startJourney(
      vehicle: vehicle,
      driverId: driverId,
      driverName: driverName,
      startLocation: startLocation,
      purpose: purpose,
      openingOdometer: openingOdometer,
      tripCategory: tripCategory,
      startLat: startLat,
      startLng: startLng,
      accompanyingOfficers: accompanyingOfficers,
      remarks: remarks,
      userOfficerName: userOfficerName,
      userOfficerDesignation: userOfficerDesignation,
      isSubordinateJourney: isSubordinateJourney,
      officerSignatureText: officerSignatureText,
    );
    refresh();
    state = state.copyWith(isLoading: false, activeJourney: journey);
    return journey;
  }

  Future<Journey> completeJourney({
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
    state = state.copyWith(isLoading: true);
    final journey = await LocalDatabase.instance.completeAndSubmitJourney(
      journeyId: journeyId,
      destination: destination,
      closingOdometer: closingOdometer,
      gpsDistance: gpsDistance,
      endLat: endLat,
      endLng: endLng,
      remarks: remarks,
      expenseAmount: expenseAmount,
      expenseReceiptUrl: expenseReceiptUrl,
      saveAsDraft: saveAsDraft,
    );
    refresh();
    state = state.copyWith(isLoading: false, clearActiveJourney: true);
    return journey;
  }

  Future<void> submitDraftJourney(String journeyId) async {
    state = state.copyWith(isLoading: true);
    await LocalDatabase.instance.submitDraftJourney(journeyId);
    refresh();
    state = state.copyWith(isLoading: false);
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
    state = state.copyWith(isLoading: true);
    final journey = await LocalDatabase.instance.editJourney(
      journeyId: journeyId,
      journeyDate: journeyDate,
      startTime: startTime,
      endTime: endTime,
      startLocation: startLocation,
      destination: destination,
      purpose: purpose,
      openingOdometer: openingOdometer,
      closingOdometer: closingOdometer,
      accompanyingOfficers: accompanyingOfficers,
      driverName: driverName,
      userOfficerName: userOfficerName,
      userOfficerDesignation: userOfficerDesignation,
      isSubordinateJourney: isSubordinateJourney,
      officerSignatureText: officerSignatureText,
      requiresApproval: requiresApproval,
      remarks: remarks,
      editReason: editReason,
    );
    refresh();
    state = state.copyWith(isLoading: false);
    return journey;
  }

  Future<void> approveJourney(String journeyId, String approverName) async {
    await LocalDatabase.instance.approveJourney(journeyId, approverName);
    refresh();
  }

  Future<void> rejectJourney(
      String journeyId, String rejectorName, String reason) async {
    await LocalDatabase.instance.rejectJourney(journeyId, rejectorName, reason);
    refresh();
  }

  Future<void> lockJourney(String journeyId, String lockerName) async {
    await LocalDatabase.instance.lockJourney(journeyId, lockerName);
    refresh();
  }

  Future<bool> deleteJourney(String journeyId, {String? reason}) async {
    state = state.copyWith(isLoading: true);
    final deleted = await LocalDatabase.instance
        .deleteJourney(journeyId: journeyId, reason: reason);
    refresh();
    state = state.copyWith(isLoading: false);
    return deleted;
  }

  Future<void> confirmDeletionApproval(
      String journeyId, String approverName) async {
    state = state.copyWith(isLoading: true);
    await LocalDatabase.instance
        .confirmDeletionApproval(journeyId, approverName);
    refresh();
    state = state.copyWith(isLoading: false);
  }

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
    state = state.copyWith(isLoading: true);
    final journey = await LocalDatabase.instance.addQuickLogBookJourney(
      vehicle: vehicle,
      driverId: driverId,
      driverName: driverName,
      journeyDate: journeyDate,
      startTime: startTime,
      endTime: endTime,
      startLocation: startLocation,
      destination: destination,
      purpose: purpose,
      openingOdometer: openingOdometer,
      closingOdometer: closingOdometer,
      accompanyingOfficers: accompanyingOfficers,
      remarks: remarks,
      userOfficerName: userOfficerName,
      userOfficerDesignation: userOfficerDesignation,
      requiresApproval: requiresApproval,
      approvingOfficerId: approvingOfficerId,
      approvingOfficerName: approvingOfficerName,
    );
    refresh();
    state = state.copyWith(isLoading: false);
    return journey;
  }

  Future<List<Journey>> addQuickMonthlyLogBookJourneys({
    required List<Journey> journeys,
    required bool asDraft,
    required bool requiresApproval,
    String? approvingOfficerId,
    String? approvingOfficerName,
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await LocalDatabase.instance.addQuickMonthlyLogBookJourneys(
      journeys: journeys,
      asDraft: asDraft,
      requiresApproval: requiresApproval,
      approvingOfficerId: approvingOfficerId,
      approvingOfficerName: approvingOfficerName,
    );
    refresh();
    state = state.copyWith(isLoading: false);
    return result;
  }
}

final journeyProvider =
    StateNotifierProvider<JourneyNotifier, JourneyState>((ref) {
  final notifier = JourneyNotifier();
  ref.listen<AuthState>(authProvider, (previous, next) {
    notifier.refresh();
  });
  return notifier;
});
