import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../models/vehicle_document.dart';
import '../models/fuel_and_service.dart';
import '../storage/local_database.dart';
import 'auth_provider.dart';

class VehicleState {
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final List<FuelEntry> fuelEntries;
  final List<MaintenanceRecord> maintenanceRecords;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  const VehicleState({
    this.vehicles = const [],
    this.selectedVehicle,
    this.fuelEntries = const [],
    this.maintenanceRecords = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  List<Vehicle> get filteredVehicles {
    if (searchQuery.isEmpty) return vehicles;
    final q = searchQuery.toLowerCase();
    return vehicles
        .where((v) =>
            v.registrationNumber.toLowerCase().contains(q) ||
            v.make.toLowerCase().contains(q) ||
            v.model.toLowerCase().contains(q) ||
            v.assignedDriverName.toLowerCase().contains(q) ||
            v.assignedOffice.toLowerCase().contains(q))
        .toList();
  }

  int get serviceDueCount => vehicles.where((v) => v.isServiceDue).length;
  int get expiringDocsCount =>
      vehicles.fold(0, (sum, v) => sum + v.expiringSoonDocumentsCount + v.expiredDocumentsCount);

  VehicleState copyWith({
    List<Vehicle>? vehicles,
    Vehicle? selectedVehicle,
    List<FuelEntry>? fuelEntries,
    List<MaintenanceRecord>? maintenanceRecords,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      fuelEntries: fuelEntries ?? this.fuelEntries,
      maintenanceRecords: maintenanceRecords ?? this.maintenanceRecords,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  VehicleNotifier() : super(const VehicleState()) {
    refresh();
  }

  void refresh() {
    final v = LocalDatabase.instance.vehicles;
    final fuel = LocalDatabase.instance.fuelEntries;
    final maint = LocalDatabase.instance.maintenanceRecords;
    final currentSelectedId = state.selectedVehicle?.id;
    final updatedSelected = currentSelectedId != null
        ? v.cast<Vehicle?>().firstWhere((item) => item?.id == currentSelectedId, orElse: () => null)
        : null;
    state = state.copyWith(
      vehicles: v,
      selectedVehicle: updatedSelected ?? (v.isNotEmpty ? v.first : null),
      fuelEntries: fuel,
      maintenanceRecords: maint,
    );
  }

  void selectVehicle(Vehicle vehicle) {
    state = state.copyWith(selectedVehicle: vehicle);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addFuel(FuelEntry entry) async {
    await LocalDatabase.instance.addFuelEntry(entry);
    refresh();
  }

  Future<void> addMaintenance(MaintenanceRecord record) async {
    await LocalDatabase.instance.addMaintenanceRecord(record);
    refresh();
  }

  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    final created = await LocalDatabase.instance.addVehicle(vehicle);
    refresh();
    state = state.copyWith(selectedVehicle: created);
    return created;
  }

  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final updated = await LocalDatabase.instance.updateVehicle(vehicle);
    refresh();
    state = state.copyWith(selectedVehicle: updated);
    return updated;
  }

  Future<bool> deleteVehicle(String vehicleId, {String? reason}) async {
    final result = await LocalDatabase.instance.deleteVehicle(vehicleId, reason: reason);
    refresh();
    return result;
  }

  Future<Vehicle> renewDocument(String vehicleId, VehicleDocument document) async {
    final updated = await LocalDatabase.instance.renewVehicleDocument(vehicleId, document);
    refresh();
    state = state.copyWith(selectedVehicle: updated);
    return updated;
  }
}

final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  final notifier = VehicleNotifier();
  ref.listen<AuthState>(authProvider, (previous, next) {
    notifier.refresh();
  });
  return notifier;
});
