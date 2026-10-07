import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/journey.dart';
import '../../core/models/vehicle.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/theme/app_colors.dart';

class JourneyBatchItem {
  final String keyId;
  DateTime date;
  TimeOfDay startTime;
  TimeOfDay endTime;
  final TextEditingController startLocCtrl;
  final TextEditingController destCtrl;
  final TextEditingController purposeCtrl;
  final TextEditingController openOdoCtrl;
  final TextEditingController closeOdoCtrl;
  final TextEditingController driverCtrl;
  final TextEditingController accompCtrl;
  final TextEditingController remarksCtrl;
  bool isExpanded;

  JourneyBatchItem({
    required this.keyId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required String startLocation,
    required String destination,
    required String purpose,
    required double openingOdometer,
    required double closingOdometer,
    required String driverName,
    String? accompanyingStaff,
    String? remarks,
    this.isExpanded = true,
  })  : startLocCtrl = TextEditingController(text: startLocation),
        destCtrl = TextEditingController(text: destination),
        purposeCtrl = TextEditingController(text: purpose),
        openOdoCtrl =
            TextEditingController(text: openingOdometer.toStringAsFixed(1)),
        closeOdoCtrl =
            TextEditingController(text: closingOdometer.toStringAsFixed(1)),
        driverCtrl = TextEditingController(text: driverName),
        accompCtrl = TextEditingController(text: accompanyingStaff ?? ''),
        remarksCtrl = TextEditingController(text: remarks ?? '');

  double get openingOdo => double.tryParse(openOdoCtrl.text.trim()) ?? 0.0;
  double get closingOdo => double.tryParse(closeOdoCtrl.text.trim()) ?? 0.0;
  double get distance =>
      (closingOdo >= openingOdo) ? (closingOdo - openingOdo) : 0.0;

  void dispose() {
    startLocCtrl.dispose();
    destCtrl.dispose();
    purposeCtrl.dispose();
    openOdoCtrl.dispose();
    closeOdoCtrl.dispose();
    driverCtrl.dispose();
    accompCtrl.dispose();
    remarksCtrl.dispose();
  }
}

class BatchJourneyCreateScreen extends ConsumerStatefulWidget {
  final DateTime? initialMonth;
  final String? initialVehicleId;

  const BatchJourneyCreateScreen({
    super.key,
    this.initialMonth,
    this.initialVehicleId,
  });

  @override
  ConsumerState<BatchJourneyCreateScreen> createState() =>
      _BatchJourneyCreateScreenState();
}

class _BatchJourneyCreateScreenState
    extends ConsumerState<BatchJourneyCreateScreen> {
  final _uuid = const Uuid();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _selectedVehicleId = '';
  String _defaultDriverName = '';

  final List<JourneyBatchItem> _items = [];
  bool _requiresApproval = true;

  static const _quickPurposes = [
    'Site Inspection',
    'Official Meeting',
    'VIP Escort Duty',
    'Maintenance Inspection',
    'Survey & Assessment',
    'Court Hearing',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialMonth != null) {
      _selectedMonth = DateTime(
          widget.initialMonth!.year, widget.initialMonth!.month, 1);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_items.isEmpty) {
      _initializeDefaults();
    }
  }

  void _initializeDefaults() {
    final authState = ref.read(authProvider);
    final user = authState.currentUser;
    if (user != null) {
      _requiresApproval = user.requiresApproval && !user.isSelfApprover;
    }

    final vehicleState = ref.read(vehicleProvider);
    double initialOdo = 15420.0;

    if (vehicleState.vehicles.isNotEmpty) {
      final matchV = vehicleState.vehicles.firstWhere(
        (v) => v.id == widget.initialVehicleId,
        orElse: () => vehicleState.vehicles.first,
      );
      _selectedVehicleId = matchV.id;
      initialOdo = matchV.currentOdometer;
      _defaultDriverName = matchV.assignedDriverName;
    } else {
      _selectedVehicleId = 'VEH-001';
      _defaultDriverName = 'Rajesh Kumar';
    }

    setState(() {
      _items.add(JourneyBatchItem(
        keyId: _uuid.v4(),
        date: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
        startTime: const TimeOfDay(hour: 9, minute: 30),
        endTime: const TimeOfDay(hour: 17, minute: 30),
        startLocation: 'Division Office',
        destination: 'District Site Office',
        purpose: 'Site Inspection',
        openingOdometer: initialOdo,
        closingOdometer: initialOdo + 38.5,
        driverName: _defaultDriverName,
        accompanyingStaff: '',
        remarks: '',
        isExpanded: true,
      ));
    });
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  double get _totalDistance =>
      _items.fold(0.0, (sum, it) => sum + it.distance);

  void _addJourney() {
    final double openOdo = _items.isNotEmpty
        ? (_items.last.closingOdo > 0
            ? _items.last.closingOdo
            : _items.last.openingOdo + 35.0)
        : 15420.0;
    final int nextDay = _items.isEmpty
        ? 1
        : (_items.last.date.day + 1).clamp(1, 28);
    setState(() {
      _items.add(JourneyBatchItem(
        keyId: _uuid.v4(),
        date: DateTime(_selectedMonth.year, _selectedMonth.month, nextDay),
        startTime: const TimeOfDay(hour: 9, minute: 30),
        endTime: const TimeOfDay(hour: 17, minute: 30),
        startLocation: 'Division Office',
        destination: 'District Site Office',
        purpose: 'Site Inspection',
        openingOdometer: openOdo,
        closingOdometer: openOdo + 38.5,
        driverName: _defaultDriverName,
        isExpanded: true,
      ));
    });
  }

  void _autoFillMonth() {
    final vehicleState = ref.read(vehicleProvider);
    double baseOdo = 15000.0;
    if (vehicleState.vehicles.isNotEmpty) {
      final v = vehicleState.vehicles.firstWhere(
        (v) => v.id == _selectedVehicleId,
        orElse: () => vehicleState.vehicles.first,
      );
      baseOdo = v.currentOdometer;
    }

    for (final it in _items) {
      it.dispose();
    }
    _items.clear();

    double odo = baseOdo;
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final routes = [
      {'from': 'Division Office', 'to': 'Sector 62 Sub-Division', 'p': 'Site Inspection', 'km': 34.5},
      {'from': 'Division Office', 'to': 'District Collectorate', 'p': 'Court Hearing', 'km': 42.0},
      {'from': 'Sub-Division', 'to': 'Authority HQ', 'p': 'Official Meeting', 'km': 48.0},
      {'from': 'Division Office', 'to': 'Expressway Site B', 'p': 'Survey & Assessment', 'km': 52.5},
      {'from': 'Division Office', 'to': 'Regional Testing Lab', 'p': 'Maintenance Inspection', 'km': 28.0},
      {'from': 'Division Office', 'to': 'State Secretariat', 'p': 'VIP Escort Duty', 'km': 65.0},
    ];

    int routeIdx = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      final dt = DateTime(year, month, day);
      if (dt.weekday == DateTime.sunday) continue;
      final r = routes[routeIdx % routes.length];
      routeIdx++;
      final km = (r['km'] as double);
      _items.add(JourneyBatchItem(
        keyId: _uuid.v4(),
        date: dt,
        startTime: const TimeOfDay(hour: 9, minute: 30),
        endTime: const TimeOfDay(hour: 17, minute: 45),
        startLocation: r['from'] as String,
        destination: r['to'] as String,
        purpose: r['p'] as String,
        openingOdometer: odo,
        closingOdometer: odo + km,
        driverName: _defaultDriverName,
        remarks: 'Official duty performed.',
        isExpanded: false,
      ));
      odo += km;
    }
    setState(() {});
  }

  void _deleteItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _save({required bool asDraft}) async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add at least 1 journey entry.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final vehicleState = ref.read(vehicleProvider);
    final authState = ref.read(authProvider);
    final user = authState.currentUser;

    Vehicle? vehicle;
    if (vehicleState.vehicles.isNotEmpty) {
      vehicle = vehicleState.vehicles.firstWhere(
        (v) => v.id == _selectedVehicleId,
        orElse: () => vehicleState.vehicles.first,
      );
    }
    vehicle ??= Vehicle(
      id: 'VEH-001',
      registrationNumber: 'UP16 AB 1234',
      make: 'Toyota',
      model: 'Innova Crysta',
      vehicleType: 'SUV',
      fuelType: 'Diesel',
      manufacturingYear: 2022,
      currentOdometer: 15420.0,
      assignedOffice: 'Noida Division',
      assignedDriverId: 'DRV-001',
      assignedDriverName: 'Rajesh Kumar',
      nextServiceDate: DateTime(2027),
    );

    final now = DateTime.now();
    final List<Journey> toSave = _items.map((it) {
      final startDT = DateTime(it.date.year, it.date.month, it.date.day,
          it.startTime.hour, it.startTime.minute);
      final endDT = DateTime(it.date.year, it.date.month, it.date.day,
          it.endTime.hour, it.endTime.minute);
      return Journey(
        id: '',
        localId: '',
        clientOperationId: 'OP-${it.date.millisecondsSinceEpoch}',
        department: user?.department ?? 'Public Works Department',
        office: user?.office ?? 'District Division',
        vehicleId: vehicle!.id,
        vehicleRegistration: vehicle.registrationNumber,
        vehicleModel: '${vehicle.make} ${vehicle.model}',
        driverId: 'DRV-001',
        driverName: it.driverCtrl.text.trim().isNotEmpty
            ? it.driverCtrl.text.trim()
            : _defaultDriverName,
        officerId: user?.id ?? 'USR-001',
        officerName: user?.name ?? 'Dr. S. K. Verma',
        userOfficerName: user?.name ?? 'Dr. S. K. Verma',
        userOfficerDesignation:
            user?.designation ?? 'Executive Engineer',
        journeyDate: it.date,
        startTime: startDT,
        endTime: endDT,
        startLocation: it.startLocCtrl.text.trim(),
        destination: it.destCtrl.text.trim(),
        purpose: it.purposeCtrl.text.trim(),
        openingOdometer: it.openingOdo,
        closingOdometer: it.closingOdo,
        officialDistance: it.distance,
        accompanyingOfficers: it.accompCtrl.text.trim().isNotEmpty
            ? it.accompCtrl.text.trim()
            : null,
        remarks: it.remarksCtrl.text.trim().isNotEmpty
            ? it.remarksCtrl.text.trim()
            : null,
        status: asDraft
            ? JourneyStatus.draft
            : (_requiresApproval
                ? JourneyStatus.pendingApproval
                : JourneyStatus.approved),
        requiresApproval: _requiresApproval,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    final messenger = ScaffoldMessenger.of(context);
    await ref.read(journeyProvider.notifier).addQuickMonthlyLogBookJourneys(
          journeys: toSave,
          asDraft: asDraft,
          requiresApproval: _requiresApproval,
        );

    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);
    messenger.showSnackBar(SnackBar(
      content: Text(asDraft
          ? '💾 Draft saved: $monthLabel (${_items.length} journeys)'
          : '🚀 Log Book submitted: $monthLabel (${_items.length} journeys)'),
      backgroundColor:
          asDraft ? AppColors.secondary : AppColors.success,
      duration: const Duration(seconds: 4),
    ));

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final vehicles = vehicleState.vehicles;
    final monthLabel = DateFormat('MMM yyyy').format(_selectedMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Multi-Journey Log Book',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('Auto-Fill'),
            onPressed: _autoFillMonth,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Journey',
            onPressed: _addJourney,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Config Header ──
          Material(
            color: Colors.white,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          vehicles.isNotEmpty
                              ? _vehicleLabel(vehicles)
                              : 'UP16 AB 1234 – Toyota Innova Crysta',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vehicles.length > 1)
                        TextButton(
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(40, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          onPressed: () => _pickVehicle(context, vehicles),
                          child: const Text('Change',
                              style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      InkWell(
                        onTap: () => _pickMonth(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                size: 16, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              monthLabel,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppColors.secondary),
                            ),
                            const SizedBox(width: 4),
                            const Text('Change',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch.adaptive(
                            value: _requiresApproval,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _requiresApproval = v),
                          ),
                          Text(
                            _requiresApproval ? 'Approval req.' : 'Self-certified',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _requiresApproval
                                    ? AppColors.secondary
                                    : AppColors.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Journey Count Banner ──
          Container(
            color: AppColors.primaryFixed,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '${_items.length} Journey Entries',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
                Text(
                  'Total Distance: ${_totalDistance.toStringAsFixed(1)} KM',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),

          // ── Journey List ──
          Expanded(
            child: _items.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) =>
                        _buildCard(_items[i], i),
                  ),
          ),
        ],
      ),

      // ── Bottom Action Bar ──
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.secondary)),
                  onPressed: () => _save(asDraft: true),
                  child: const Text('💾  Save Draft',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _requiresApproval
                        ? AppColors.primary
                        : AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _save(asDraft: false),
                  child: Text(
                    _requiresApproval ? '🚀  Submit' : '🚀  Self-Certify',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper: vehicle label ──
  String _vehicleLabel(List<Vehicle> vehicles) {
    if (_selectedVehicleId.isEmpty) return vehicles.first.registrationNumber;
    final v = vehicles.firstWhere((v) => v.id == _selectedVehicleId,
        orElse: () => vehicles.first);
    return '${v.registrationNumber} – ${v.make} ${v.model}';
  }

  // ── Pick Month ──
  Future<void> _pickMonth(BuildContext ctx) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  // ── Pick Vehicle ──
  Future<void> _pickVehicle(BuildContext ctx, List<Vehicle> vehicles) async {
    final result = await showModalBottomSheet<String>(
      context: ctx,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: vehicles.map((v) {
          return ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: Text(v.registrationNumber),
            subtitle: Text('${v.make} ${v.model}'),
            selected: v.id == _selectedVehicleId,
            onTap: () => Navigator.pop(ctx, v.id),
          );
        }).toList(),
      ),
    );
    if (result != null && mounted) {
      final v = vehicles.firstWhere((v) => v.id == result);
      setState(() {
        _selectedVehicleId = result;
        _defaultDriverName = v.assignedDriverName;
      });
    }
  }

  // ── Empty State ──
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.playlist_add_rounded,
                size: 56, color: AppColors.outline),
            const SizedBox(height: 16),
            const Text('No journeys added yet.',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Tap "+ Add Journey" to add entries manually,\nor "⚡ Auto-Fill" to generate a full month.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.secondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              icon: const Icon(Icons.add),
              label: const Text('Add First Journey'),
              onPressed: _addJourney,
            ),
          ],
        ),
      ),
    );
  }

  // ── Journey Card ──
  Widget _buildCard(JourneyBatchItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header (tap to expand/collapse) ──
          InkWell(
            onTap: () => setState(() => item.isExpanded = !item.isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${index + 1} ${DateFormat('dd MMM').format(item.date)}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.startLocCtrl.text.split(',').first} > ${item.destCtrl.text.split(',').first}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '${item.distance.toStringAsFixed(1)}k',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    item.isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  InkWell(
                    onTap: () => _deleteItem(index),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 16, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Form ──
          if (item.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),

                  // Row 1: Date | Start time | End time
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _tapBox(
                            label: 'Date',
                            value: DateFormat('dd MMM yyyy').format(item.date),
                            icon: Icons.calendar_today_outlined,
                            onTap: () async {
                              final first = DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month, 1);
                              final last = DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month + 1, 0);
                              final d = await showDatePicker(
                                context: context,
                                initialDate: item.date.isBefore(first)
                                    ? first
                                    : (item.date.isAfter(last) ? last : item.date),
                                firstDate: first,
                                lastDate: last,
                              );
                              if (d != null) setState(() => item.date = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _tapBox(
                            label: 'Start',
                            value: _fmtTime(item.startTime),
                            icon: Icons.access_time_outlined,
                            onTap: () async {
                              final t = await showTimePicker(
                                  context: context,
                                  initialTime: item.startTime);
                              if (t != null) setState(() => item.startTime = t);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _tapBox(
                            label: 'End',
                            value: _fmtTime(item.endTime),
                            icon: Icons.access_time_filled_outlined,
                            onTap: () async {
                              final t = await showTimePicker(
                                  context: context,
                                  initialTime: item.endTime);
                              if (t != null) setState(() => item.endTime = t);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Row 2: From | To
                  Row(children: [
                    Expanded(child: _field('From / Start', item.startLocCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('To / Destination', item.destCtrl)),
                  ]),
                  const SizedBox(height: 8),

                  // Row 3: Purpose
                  _field('Purpose of Journey', item.purposeCtrl),
                  const SizedBox(height: 6),

                  // Quick purpose chips
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: _quickPurposes.map((p) {
                      final sel = item.purposeCtrl.text == p;
                      return GestureDetector(
                        onTap: () => setState(() => item.purposeCtrl.text = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(p,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.onSurface)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Row 4: Opening KM | Closing KM | Distance
                  Row(children: [
                    Expanded(
                        child: _field('Opening KM', item.openOdoCtrl,
                            numeric: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('Closing KM', item.closeOdoCtrl,
                            numeric: true)),
                    const SizedBox(width: 8),
                    Container(
                      width: 70,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Dist.',
                              style: TextStyle(
                                  fontSize: 9, color: AppColors.secondary)),
                          Text(
                            item.distance.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),

                  // Row 5: Driver | Accompanying
                  Row(children: [
                    Expanded(child: _field('Driver', item.driverCtrl)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field('Accompanying (opt.)', item.accompCtrl)),
                  ]),
                  const SizedBox(height: 8),

                  // Row 6: Remarks
                  _field('Remarks (optional)', item.remarksCtrl),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Simple inline text field (no label above) ──
  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool numeric = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      onChanged: numeric ? (_) => setState(() {}) : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 11, color: AppColors.secondary),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // ── Tap-to-select box (replaces DropdownButtonFormField) ──
  Widget _tapBox({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 10, color: AppColors.secondary),
                const SizedBox(width: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.secondary)),
              ],
            ),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
