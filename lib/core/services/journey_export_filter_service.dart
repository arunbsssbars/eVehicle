import 'package:intl/intl.dart';
import '../models/journey.dart';

/// Supported sort fields for journeys
enum JourneySortField {
  date('Date'),
  distance('Distance'),
  driver('Driver Name'),
  vehicle('Vehicle Reg'),
  status('Status');

  final String label;
  const JourneySortField(this.label);
}

/// Filter criteria for querying and exporting journeys
class JourneyFilterCriteria {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? vehicleId;
  final String? driverId;
  final JourneyStatus? status;
  final TripCategory? category;
  final String? searchQuery;
  final double? minDistance;
  final double? maxDistance;
  final JourneySortField sortBy;
  final bool sortAscending;

  const JourneyFilterCriteria({
    this.startDate,
    this.endDate,
    this.vehicleId,
    this.driverId,
    this.status,
    this.category,
    this.searchQuery,
    this.minDistance,
    this.maxDistance,
    this.sortBy = JourneySortField.date,
    this.sortAscending = false,
  });

  JourneyFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? vehicleId,
    String? driverId,
    JourneyStatus? status,
    TripCategory? category,
    String? searchQuery,
    double? minDistance,
    double? maxDistance,
    JourneySortField? sortBy,
    bool? sortAscending,
  }) {
    return JourneyFilterCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      minDistance: minDistance ?? this.minDistance,
      maxDistance: maxDistance ?? this.maxDistance,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      vehicleId != null ||
      driverId != null ||
      status != null ||
      category != null ||
      (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
      minDistance != null ||
      maxDistance != null;
}

/// Production service providing filtering, multi-column sorting, and secure RFC 4180 CSV generation
class JourneyExportFilterService {
  /// Filter and sort a list of journeys based on criteria
  static List<Journey> filterAndSortJourneys(
    List<Journey> journeys,
    JourneyFilterCriteria criteria,
  ) {
    var result = journeys.where((j) {
      // Date bounds
      if (criteria.startDate != null) {
        final start = DateTime(criteria.startDate!.year, criteria.startDate!.month, criteria.startDate!.day);
        if (j.journeyDate.isBefore(start)) return false;
      }
      if (criteria.endDate != null) {
        final end = DateTime(criteria.endDate!.year, criteria.endDate!.month, criteria.endDate!.day, 23, 59, 59);
        if (j.journeyDate.isAfter(end)) return false;
      }

      // Vehicle
      if (criteria.vehicleId != null && criteria.vehicleId!.isNotEmpty) {
        if (j.vehicleId != criteria.vehicleId) return false;
      }

      // Driver
      if (criteria.driverId != null && criteria.driverId!.isNotEmpty) {
        if (j.driverId != criteria.driverId) return false;
      }

      // Status
      if (criteria.status != null) {
        if (j.status != criteria.status) return false;
      }

      // Category
      if (criteria.category != null) {
        if (j.category != criteria.category) return false;
      }

      // Distance
      final dist = j.calculatedDistance;
      if (criteria.minDistance != null && dist < criteria.minDistance!) {
        return false;
      }
      if (criteria.maxDistance != null && dist > criteria.maxDistance!) {
        return false;
      }

      // Text query
      if (criteria.searchQuery != null && criteria.searchQuery!.trim().isNotEmpty) {
        final q = criteria.searchQuery!.trim().toLowerCase();
        final matchesLoc = j.startLocation.toLowerCase().contains(q) || j.destination.toLowerCase().contains(q);
        final matchesPurpose = j.purpose.toLowerCase().contains(q);
        final matchesDriver = j.driverName.toLowerCase().contains(q);
        final matchesVehicle = j.vehicleRegistration.toLowerCase().contains(q) || j.vehicleModel.toLowerCase().contains(q);
        final matchesOfficer = j.officerName.toLowerCase().contains(q);
        if (!matchesLoc && !matchesPurpose && !matchesDriver && !matchesVehicle && !matchesOfficer) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort
    result.sort((a, b) {
      int cmp = 0;
      switch (criteria.sortBy) {
        case JourneySortField.date:
          cmp = a.journeyDate.compareTo(b.journeyDate);
          break;
        case JourneySortField.distance:
          cmp = a.calculatedDistance.compareTo(b.calculatedDistance);
          break;
        case JourneySortField.driver:
          cmp = a.driverName.toLowerCase().compareTo(b.driverName.toLowerCase());
          break;
        case JourneySortField.vehicle:
          cmp = a.vehicleRegistration.toLowerCase().compareTo(b.vehicleRegistration.toLowerCase());
          break;
        case JourneySortField.status:
          cmp = a.status.name.compareTo(b.status.name);
          break;
      }
      return criteria.sortAscending ? cmp : -cmp;
    });

    return result;
  }

  /// Sanitizes fields to prevent Excel/CSV formula injection (CWE-1236)
  /// Neutralizes prefix symbols `=, +, -, @, \t, \r` with a prepended single quote
  static String sanitizeCsvCell(String? input) {
    if (input == null || input.isEmpty) return '""';

    String value = input.trim();

    // Check for dangerous formula injection trigger
    if (value.startsWith('=') ||
        value.startsWith('+') ||
        value.startsWith('-') ||
        value.startsWith('@') ||
        value.startsWith('\t') ||
        value.startsWith('\r')) {
      value = "'$value";
    }

    // RFC 4180 Escaping: double up any internal quotes and wrap in quotes
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Generates a standardized, secure RFC 4180 CSV export of journeys
  static String generateJourneyCsv(List<Journey> journeys) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    final header = [
      'Journey ID',
      'Date',
      'Start Time',
      'End Time',
      'Vehicle Registration',
      'Vehicle Model',
      'Driver Name',
      'Officer Name',
      'Department',
      'From Location',
      'To Location',
      'Purpose',
      'Opening KM',
      'Closing KM',
      'Distance (KM)',
      'GPS Distance (KM)',
      'Trip Category',
      'Status',
    ].map(sanitizeCsvCell).join(',');

    final rows = <String>[header];

    for (final j in journeys) {
      final startTimeStr = timeFormat.format(j.startTime);
      final endTimeStr = j.endTime != null ? timeFormat.format(j.endTime!) : '--';

      final row = [
        sanitizeCsvCell(j.id),
        sanitizeCsvCell(dateFormat.format(j.journeyDate)),
        sanitizeCsvCell(startTimeStr),
        sanitizeCsvCell(endTimeStr),
        sanitizeCsvCell(j.vehicleRegistration),
        sanitizeCsvCell(j.vehicleModel),
        sanitizeCsvCell(j.driverName),
        sanitizeCsvCell(j.officerName),
        sanitizeCsvCell(j.department),
        sanitizeCsvCell(j.startLocation),
        sanitizeCsvCell(j.destination),
        sanitizeCsvCell(j.purpose),
        sanitizeCsvCell(j.openingOdometer.toStringAsFixed(1)),
        sanitizeCsvCell(j.closingOdometer?.toStringAsFixed(1) ?? '--'),
        sanitizeCsvCell(j.calculatedDistance.toStringAsFixed(1)),
        sanitizeCsvCell(j.gpsDistance?.toStringAsFixed(1) ?? '--'),
        sanitizeCsvCell(j.category.name),
        sanitizeCsvCell(j.status.label),
      ].join(',');

      rows.add(row);
    }

    return rows.join('\r\n');
  }
}
