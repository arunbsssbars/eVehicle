import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/journey.dart';
import '../../core/models/vehicle.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/providers/auth_provider.dart';

class QuickLogBookModal extends ConsumerStatefulWidget {
  final DateTime? initialMonth;
  final String? initialVehicleId;
  final int initialTab;

  const QuickLogBookModal({
    super.key,
    this.initialMonth,
    this.initialVehicleId,
    this.initialTab = 0,
  });

  static Future<void> show(
    BuildContext context, {
    DateTime? initialMonth,
    String? initialVehicleId,
    int initialTab = 0,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 700;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 12,
          vertical: isDesktop ? 24 : 12,
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          width: isDesktop ? 840 : double.infinity,
          height: (mediaQuery.size.height * 0.90).clamp(520.0, 840.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: QuickLogBookModal(
            initialMonth: initialMonth,
            initialVehicleId: initialVehicleId,
            initialTab: initialTab,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<QuickLogBookModal> createState() => _QuickLogBookModalState();
}

class _DailyLogItem {
  DateTime date;
  TimeOfDay startTime;
  TimeOfDay endTime;
  String startLocation;
  String destination;
  String purpose;
  double openingOdometer;
  double closingOdometer;
  String driverName;
  String? accompanyingStaff;
  String? remarks;

  _DailyLogItem({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.startLocation,
    required this.destination,
    required this.purpose,
    required this.openingOdometer,
    required this.closingOdometer,
    required this.driverName,
    this.accompanyingStaff,
    this.remarks,
  });

  double get distance =>
      (closingOdometer >= openingOdometer) ? (closingOdometer - openingOdometer) : 0;
}

class _QuickLogBookModalState extends ConsumerState<QuickLogBookModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Monthly batch state
  DateTime _selectedMonth = DateTime(2026, 8, 1);
  String? _selectedVehicleId;
  String _defaultDriverName = 'Rajesh Kumar';
  String _defaultDriverId = 'DRV-001';

  final List<_DailyLogItem> _dailyEntries = [];

  // Single Trip form controllers
  final _singleFormKey = GlobalKey<FormState>();
  DateTime _singleJourneyDate = DateTime.now();
  TimeOfDay _singleStartTime = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay _singleEndTime = const TimeOfDay(hour: 17, minute: 30);
  final _singleStartLocController =
      TextEditingController(text: 'Noida Division Office');
  final _singleDestController =
      TextEditingController(text: 'Sector 62 Site Office');
  final _singlePurposeController =
      TextEditingController(text: 'Site Inspection & Progress Review');
  final _singleOpenOdoController = TextEditingController();
  final _singleCloseOdoController = TextEditingController();
  final _singleAccompanyingController = TextEditingController();
  final _singleRemarksController = TextEditingController();

  // Approval Configuration
  bool _requiresApproval = true;
  String _approverMode = 'PRESET'; // 'PRESET' or 'CUSTOM'
  String _selectedApproverId = 'USR-002';
  String _selectedApproverName =
      'Anjali Sharma, IAS (Superintending Engineer)';

  final _customApproverNameController = TextEditingController();
  final _customApproverDesigController = TextEditingController();
  final _customApproverIdController = TextEditingController();

  final List<Map<String, String>> _presetApprovers = [
    {
      'id': 'USR-002',
      'name': 'Anjali Sharma, IAS (Superintending Engineer)',
    },
    {
      'id': 'USR-001',
      'name': 'Dr. S. K. Verma (Executive Engineer)',
    },
    {
      'id': 'USR-003',
      'name': 'Vikram Singh (State Fleet Administrator)',
    },
    {
      'id': 'CUSTOM',
      'name': '➕ Enter Custom Approving Officer Details',
    },
  ];

  final List<String> _quickPurposes = [
    'Site Inspection & Progress Review',
    'Official Meeting at HQ',
    'VIP Escort & Protocol Duty',
    'Routine Maintenance & Safety Inspection',
    'Survey, Mapping & Assessment',
    'Court Hearing & Legal Duty',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );

    if (widget.initialMonth != null) {
      _selectedMonth =
          DateTime(widget.initialMonth!.year, widget.initialMonth!.month, 1);
    }

    final authState = ref.read(authProvider);
    final user = authState.currentUser;

    if (user != null) {
      _requiresApproval = user.requiresApproval && !user.isSelfApprover;
      if (user.approvingOfficerName != null &&
          user.approvingOfficerName!.isNotEmpty) {
        _selectedApproverName = user.approvingOfficerName!;
      }
    }

    final vehicleState = ref.read(vehicleProvider);
    double initialOdo = 15420.0;
    if (widget.initialVehicleId != null &&
        vehicleState.vehicles.any((v) => v.id == widget.initialVehicleId)) {
      _selectedVehicleId = widget.initialVehicleId;
      final matchV = vehicleState.vehicles
          .firstWhere((v) => v.id == widget.initialVehicleId);
      initialOdo = matchV.currentOdometer;
      _defaultDriverName = matchV.assignedDriverName;
    } else if (vehicleState.vehicles.isNotEmpty) {
      _selectedVehicleId = vehicleState.vehicles.first.id;
      initialOdo = vehicleState.vehicles.first.currentOdometer;
      _defaultDriverName = vehicleState.vehicles.first.assignedDriverName;
    } else {
      _selectedVehicleId = 'VEH-001';
    }

    _singleOpenOdoController.text = initialOdo.toStringAsFixed(1);
    _singleCloseOdoController.text = (initialOdo + 35.0).toStringAsFixed(1);
    _seedMonthlyEntries(initialOdo);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  List<String> _getDriverOptions(List<Vehicle> vehicles) {
    final set = <String>{};
    if (_defaultDriverName.isNotEmpty) {
      set.add(_defaultDriverName);
    }
    for (final v in vehicles) {
      if (v.assignedDriverName.isNotEmpty) {
        set.add(v.assignedDriverName);
      }
    }
    set.add('Rajesh Kumar');
    set.add('Govind');
    set.add('Sunil Verma');
    set.add('Ramesh Singh');
    set.add('Self-Driven (Officer)');
    return set.toList();
  }

  void _generateFullWorkingMonth(double baseOdometer) {
    _dailyEntries.clear();
    double currentOdo = baseOdometer > 1000 ? baseOdometer : 15000.0;
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final routes = [
      {
        'from': 'Division Office',
        'to': 'Sector 62 Sub-Division',
        'p': 'Site Inspection & Progress Review',
        'km': 34.5,
        'staff': 'A. K. Gupta (AE)'
      },
      {
        'from': 'Division Office',
        'to': 'District Collectorate Court',
        'p': 'Court Hearing & Legal Duty',
        'km': 42.0,
        'staff': null
      },
      {
        'from': 'Sector 62 Sub-Division',
        'to': 'Greater Noida Authority HQ',
        'p': 'Official Meeting at HQ',
        'km': 48.0,
        'staff': 'R. S. Negi (JE)'
      },
      {
        'from': 'Division Office',
        'to': 'Expressway Flyover Site B',
        'p': 'Survey, Mapping & Assessment',
        'km': 52.5,
        'staff': 'P. Verma (Surveyor)'
      },
      {
        'from': 'Division Office',
        'to': 'Regional Testing Lab',
        'p': 'Routine Maintenance & Safety Inspection',
        'km': 28.0,
        'staff': null
      },
      {
        'from': 'Division Office',
        'to': 'State Secretariat Annexe',
        'p': 'VIP Escort & Protocol Duty',
        'km': 65.0,
        'staff': 'Dr. Verma & Staff'
      },
    ];

    int routeIdx = 0;
    for (int day = 1; day <= daysInMonth; day++) {
      final dt = DateTime(year, month, day);
      if (dt.weekday == DateTime.sunday) continue;
      if (dt.weekday == DateTime.saturday && (day > 7 && day <= 14)) continue;

      final r = routes[routeIdx % routes.length];
      routeIdx++;
      final km = (r['km'] as double);

      _dailyEntries.add(
        _DailyLogItem(
          date: dt,
          startTime: const TimeOfDay(hour: 9, minute: 30),
          endTime: const TimeOfDay(hour: 17, minute: 45),
          startLocation: r['from'] as String,
          destination: r['to'] as String,
          purpose: r['p'] as String,
          openingOdometer: currentOdo,
          closingOdometer: currentOdo + km,
          driverName: _defaultDriverName,
          accompanyingStaff: r['staff'] as String?,
          remarks: 'Official duty performed as per departmental tour program.',
        ),
      );
      currentOdo += km;
    }
  }

  void _seedMonthlyEntries(double baseOdometer) {
    _dailyEntries.clear();
    double currentOdo = baseOdometer > 15000 ? baseOdometer - 180 : 14850;

    _dailyEntries.addAll([
      _DailyLogItem(
        date: DateTime(_selectedMonth.year, _selectedMonth.month, 3),
        startTime: const TimeOfDay(hour: 9, minute: 15),
        endTime: const TimeOfDay(hour: 17, minute: 30),
        startLocation: 'Division Office',
        destination: 'Sector 62 Sub-Division',
        purpose: 'Site Inspection & Progress Review',
        openingOdometer: currentOdo,
        closingOdometer: currentOdo + 38.5,
        driverName: _defaultDriverName,
        accompanyingStaff: 'A. K. Gupta (AE)',
        remarks: 'Official inspection completed.',
      ),
      _DailyLogItem(
        date: DateTime(_selectedMonth.year, _selectedMonth.month, 7),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 15),
        startLocation: 'Sector 62 Sub-Division',
        destination: 'Greater Noida Authority HQ',
        purpose: 'Official Meeting at HQ',
        openingOdometer: currentOdo + 38.5,
        closingOdometer: currentOdo + 86.0,
        driverName: _defaultDriverName,
        accompanyingStaff: 'R. S. Negi (JE)',
        remarks: 'Monthly coordination review.',
      ),
      _DailyLogItem(
        date: DateTime(_selectedMonth.year, _selectedMonth.month, 12),
        startTime: const TimeOfDay(hour: 8, minute: 45),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        startLocation: 'Division Office',
        destination: 'Expressway Flyover Site B',
        purpose: 'Survey, Mapping & Assessment',
        openingOdometer: currentOdo + 86.0,
        closingOdometer: currentOdo + 134.2,
        driverName: _defaultDriverName,
        accompanyingStaff: 'P. Verma (Surveyor)',
        remarks: 'Structural load test verified.',
      ),
      _DailyLogItem(
        date: DateTime(_selectedMonth.year, _selectedMonth.month, 18),
        startTime: const TimeOfDay(hour: 9, minute: 30),
        endTime: const TimeOfDay(hour: 19, minute: 0),
        startLocation: 'Division Office',
        destination: 'District Collectorate Court',
        purpose: 'Court Hearing & Legal Duty',
        openingOdometer: currentOdo + 134.2,
        closingOdometer: currentOdo + 178.0,
        driverName: _defaultDriverName,
        accompanyingStaff: null,
        remarks: 'Affidavit submitted to Sub-Divisional Magistrate.',
      ),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _singleStartLocController.dispose();
    _singleDestController.dispose();
    _singlePurposeController.dispose();
    _singleOpenOdoController.dispose();
    _singleCloseOdoController.dispose();
    _singleAccompanyingController.dispose();
    _singleRemarksController.dispose();
    _customApproverNameController.dispose();
    _customApproverDesigController.dispose();
    _customApproverIdController.dispose();
    super.dispose();
  }

  double get _totalMonthlyDistance {
    double total = 0;
    for (var item in _dailyEntries) {
      total += item.distance;
    }
    return total;
  }

  void _showAddOrEditDayDialog({_DailyLogItem? existingItem, int? editIndex}) {
    final isEditing = existingItem != null && editIndex != null;

    DateTime entryDate = existingItem?.date ??
        DateTime(
            _selectedMonth.year,
            _selectedMonth.month,
            _dailyEntries.isEmpty
                ? 1
                : (_dailyEntries.last.date.day + 1).clamp(1, 28));
    TimeOfDay startTime =
        existingItem?.startTime ?? const TimeOfDay(hour: 9, minute: 30);
    TimeOfDay endTime =
        existingItem?.endTime ?? const TimeOfDay(hour: 17, minute: 30);

    double defaultOpen = 0.0;
    if (isEditing) {
      defaultOpen = existingItem.openingOdometer;
    } else if (_dailyEntries.isNotEmpty) {
      defaultOpen = _dailyEntries.last.closingOdometer;
    } else {
      defaultOpen = 15420.0;
    }

    final startLocCtrl = TextEditingController(
        text: existingItem?.startLocation ?? 'Division Office');
    final destCtrl = TextEditingController(
        text: existingItem?.destination ?? 'District Site B');
    final purposeCtrl = TextEditingController(
        text: existingItem?.purpose ?? 'Site Inspection & Progress Review');
    final openOdoCtrl = TextEditingController(
        text: (existingItem?.openingOdometer ?? defaultOpen).toStringAsFixed(1));
    final closeOdoCtrl = TextEditingController(
        text: (existingItem?.closingOdometer ?? (defaultOpen + 35.0))
            .toStringAsFixed(1));
    final driverCtrl = TextEditingController(
        text: existingItem?.driverName ?? _defaultDriverName);
    final staffCtrl =
        TextEditingController(text: existingItem?.accompanyingStaff ?? '');
    final remarksCtrl =
        TextEditingController(text: existingItem?.remarks ?? '');

    final dayFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final openVal = double.tryParse(openOdoCtrl.text.trim()) ?? 0;
          final closeVal = double.tryParse(closeOdoCtrl.text.trim()) ?? 0;
          final distPreview =
              (closeVal >= openVal) ? (closeVal - openVal) : 0.0;

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isEditing
                      ? Icons.edit_note_rounded
                      : Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Edit Day Journey' : 'Add Day Journey Entry',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: dayFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Selector
                      InkWell(
                        onTap: () async {
                          final firstDate = DateTime(
                              _selectedMonth.year, _selectedMonth.month, 1);
                          final lastDate = DateTime(
                              _selectedMonth.year, _selectedMonth.month + 1, 0);
                          final safeInit = entryDate.isBefore(firstDate)
                              ? firstDate
                              : (entryDate.isAfter(lastDate)
                                  ? lastDate
                                  : entryDate);
                          final picked = await showDatePicker(
                            context: dctx,
                            initialDate: safeInit,
                            firstDate: firstDate,
                            lastDate: lastDate,
                          );
                          if (picked != null) {
                            setDialogState(() => entryDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderSubtle),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('EEE, dd MMMM yyyy')
                                        .format(entryDate),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const Text('Change',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Start & End Time Pickers ──────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: dctx,
                                  initialTime: startTime,
                                );
                                if (picked != null) {
                                  setDialogState(() => startTime = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.borderSubtle),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSm),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                            Icons.access_time_outlined,
                                            size: 13,
                                            color: AppColors.primary),
                                        SizedBox(width: 4),
                                        Text('Start Time',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.secondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTimeOfDay(startTime),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: dctx,
                                  initialTime: endTime,
                                );
                                if (picked != null) {
                                  setDialogState(() => endTime = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.borderSubtle),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSm),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                            Icons.access_time_filled_outlined,
                                            size: 13,
                                            color: AppColors.secondary),
                                        SizedBox(width: 4),
                                        Text('End Time',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.secondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTimeOfDay(endTime),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Route
                      CustomTextField(
                        label: 'Starting Location',
                        controller: startLocCtrl,
                        isRequired: true,
                        prefixIcon: const Icon(Icons.trip_origin, size: 18),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Destination',
                        controller: destCtrl,
                        isRequired: true,
                        prefixIcon: const Icon(Icons.location_on, size: 18),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),

                      // Purpose with quick-pick chips
                      const Text(
                        'Purpose of Journey *',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _quickPurposes.map((p) {
                          final isSelected = purposeCtrl.text == p;
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => purposeCtrl.text = p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.borderSubtle,
                                ),
                              ),
                              child: Text(
                                p,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.onSurface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        label: 'Purpose of Journey',
                        controller: purposeCtrl,
                        isRequired: true,
                        prefixIcon: const Icon(Icons.work_outline, size: 18),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),

                      // Odometer Readings
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Opening KM',
                              controller: openOdoCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              isRequired: true,
                              onChanged: (_) => setDialogState(() {}),
                              validator: (v) =>
                                  v == null || double.tryParse(v) == null
                                      ? 'Invalid'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              label: 'Closing KM',
                              controller: closeOdoCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              isRequired: true,
                              onChanged: (_) => setDialogState(() {}),
                              validator: (v) {
                                if (v == null || double.tryParse(v) == null) {
                                  return 'Invalid';
                                }
                                final o = double.tryParse(
                                        openOdoCtrl.text.trim()) ??
                                    0;
                                if (double.parse(v) < o) return '>= Opening';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Day Distance:',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                            Text(
                              '${distPreview.toStringAsFixed(1)} KM',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Driver & Staff
                      CustomTextField(
                        label: 'Driver Name',
                        controller: driverCtrl,
                        isRequired: true,
                        prefixIcon:
                            const Icon(Icons.person_pin_outlined, size: 18),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Accompanying Staff',
                        hint: 'e.g. A. K. Gupta (AE)',
                        controller: staffCtrl,
                        prefixIcon: const Icon(Icons.group_outlined, size: 18),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        label: 'Remarks',
                        hint: 'Notes on day travel...',
                        controller: remarksCtrl,
                        prefixIcon: const Icon(Icons.notes_outlined, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (!dayFormKey.currentState!.validate()) return;
                  final open = double.parse(openOdoCtrl.text.trim());
                  final close = double.parse(closeOdoCtrl.text.trim());

                  final newItem = _DailyLogItem(
                    date: entryDate,
                    startTime: startTime,
                    endTime: endTime,
                    startLocation: startLocCtrl.text.trim(),
                    destination: destCtrl.text.trim(),
                    purpose: purposeCtrl.text.trim(),
                    openingOdometer: open,
                    closingOdometer: close,
                    driverName: driverCtrl.text.trim(),
                    accompanyingStaff: staffCtrl.text.trim().isEmpty
                        ? null
                        : staffCtrl.text.trim(),
                    remarks: remarksCtrl.text.trim().isEmpty
                        ? null
                        : remarksCtrl.text.trim(),
                  );

                  setState(() {
                    if (isEditing) {
                      _dailyEntries[editIndex] = newItem;
                    } else {
                      _dailyEntries.add(newItem);
                      _dailyEntries.sort((a, b) => a.date.compareTo(b.date));
                    }
                  });

                  Navigator.pop(dctx);
                },
                child: Text(isEditing ? 'Save Changes' : 'Add Entry'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteDayEntry(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Day Entry'),
        content: Text(
          'Remove trip entry for ${DateFormat("dd MMMM").format(_dailyEntries[index].date)} (${_dailyEntries[index].distance.toStringAsFixed(1)} KM)?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _dailyEntries.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete Day'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveMonthlyBatch({required bool asDraft}) async {
    if (_dailyEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one day journey entry.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final vehicleState = ref.read(vehicleProvider);
    final vehicleToUse = vehicleState.vehicles.firstWhere(
      (v) => v.id == _selectedVehicleId,
      orElse: () => vehicleState.vehicles.isNotEmpty
          ? vehicleState.vehicles.first
          : Vehicle(
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
            ),
    );

    final authState = ref.read(authProvider);
    final user = authState.currentUser;

    final String finalApproverName;
    final String? finalApproverId;

    if (!_requiresApproval) {
      finalApproverName = '${user?.name ?? "Officer"} (Self-Approved)';
      finalApproverId = null;
    } else if (_approverMode == 'CUSTOM') {
      finalApproverName =
          '${_customApproverNameController.text.trim()} (${_customApproverDesigController.text.trim()})';
      finalApproverId = _customApproverIdController.text.trim().isNotEmpty
          ? _customApproverIdController.text.trim()
          : null;
    } else {
      finalApproverName = _selectedApproverName;
      finalApproverId = _selectedApproverId;
    }

    final List<Journey> journeysToSave = [];
    final now = DateTime.now();

    for (var item in _dailyEntries) {
      final startDT = DateTime(item.date.year, item.date.month, item.date.day,
          item.startTime.hour, item.startTime.minute);
      final endDT = DateTime(item.date.year, item.date.month, item.date.day,
          item.endTime.hour, item.endTime.minute);

      final j = Journey(
        id: '',
        localId: '',
        clientOperationId: 'OP-${item.date.millisecondsSinceEpoch}',
        department: user?.department ?? 'Public Works Department',
        office: user?.office ?? 'District Division 1',
        vehicleId: vehicleToUse.id,
        vehicleRegistration: vehicleToUse.registrationNumber,
        vehicleModel: '${vehicleToUse.make} ${vehicleToUse.model}',
        driverId: _defaultDriverId,
        driverName: item.driverName,
        officerId: user?.id ?? 'USR-001',
        officerName: user?.name ?? 'Dr. S. K. Verma',
        userOfficerName: user?.name ?? 'Dr. S. K. Verma',
        userOfficerDesignation: user?.designation ?? 'Executive Engineer',
        journeyDate: item.date,
        startTime: startDT,
        endTime: endDT,
        startLocation: item.startLocation,
        destination: item.destination,
        purpose: item.purpose,
        openingOdometer: item.openingOdometer,
        closingOdometer: item.closingOdometer,
        officialDistance: item.distance,
        accompanyingOfficers: item.accompanyingStaff,
        remarks: item.remarks,
        status: asDraft
            ? JourneyStatus.draft
            : (_requiresApproval
                ? JourneyStatus.pendingApproval
                : JourneyStatus.approved),
        requiresApproval: _requiresApproval,
        createdAt: now,
        updatedAt: now,
      );

      journeysToSave.add(j);
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    await ref.read(journeyProvider.notifier).addQuickMonthlyLogBookJourneys(
          journeys: journeysToSave,
          asDraft: asDraft,
          requiresApproval: _requiresApproval,
          approvingOfficerId: finalApproverId,
          approvingOfficerName: finalApproverName,
        );

    final monthTitle = DateFormat('MMMM yyyy').format(_selectedMonth);
    messenger.showSnackBar(
      SnackBar(
        content: Text(asDraft
            ? '💾 Monthly Log Book for $monthTitle (${_dailyEntries.length} days) saved as DRAFT!'
            : (!_requiresApproval
                ? '🚀 Monthly Log Book for $monthTitle created & Self-Certified!'
                : '🚀 Monthly Log Book for $monthTitle submitted for Approval!')),
        backgroundColor: asDraft
            ? AppColors.secondary
            : (!_requiresApproval ? AppColors.success : AppColors.primary),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleSingleTripSubmit() async {
    if (!_singleFormKey.currentState!.validate()) return;

    final vehicleState = ref.read(vehicleProvider);
    final vehicleToUse = vehicleState.vehicles.firstWhere(
      (v) => v.id == _selectedVehicleId,
      orElse: () => vehicleState.vehicles.isNotEmpty
          ? vehicleState.vehicles.first
          : Vehicle(
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
            ),
    );

    final authState = ref.read(authProvider);
    final user = authState.currentUser;

    final openVal = double.parse(_singleOpenOdoController.text.trim());
    final closeVal = double.parse(_singleCloseOdoController.text.trim());

    final startDateTime = DateTime(
      _singleJourneyDate.year,
      _singleJourneyDate.month,
      _singleJourneyDate.day,
      _singleStartTime.hour,
      _singleStartTime.minute,
    );

    final endDateTime = DateTime(
      _singleJourneyDate.year,
      _singleJourneyDate.month,
      _singleJourneyDate.day,
      _singleEndTime.hour,
      _singleEndTime.minute,
    );

    final String finalApproverName;
    final String? finalApproverId;

    if (!_requiresApproval) {
      finalApproverName = '${user?.name ?? "Officer"} (Self-Approved)';
      finalApproverId = null;
    } else if (_approverMode == 'CUSTOM') {
      finalApproverName =
          '${_customApproverNameController.text.trim()} (${_customApproverDesigController.text.trim()})';
      finalApproverId = _customApproverIdController.text.trim().isNotEmpty
          ? _customApproverIdController.text.trim()
          : null;
    } else {
      finalApproverName = _selectedApproverName;
      finalApproverId = _selectedApproverId;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    await ref.read(journeyProvider.notifier).addQuickLogBookJourney(
          vehicle: vehicleToUse,
          driverId: _defaultDriverId,
          driverName: _defaultDriverName,
          journeyDate: _singleJourneyDate,
          startTime: startDateTime,
          endTime: endDateTime,
          startLocation: _singleStartLocController.text.trim(),
          destination: _singleDestController.text.trim(),
          purpose: _singlePurposeController.text.trim(),
          openingOdometer: openVal,
          closingOdometer: closeVal,
          accompanyingOfficers:
              _singleAccompanyingController.text.trim().isEmpty
                  ? null
                  : _singleAccompanyingController.text.trim(),
          remarks: _singleRemarksController.text.trim().isEmpty
              ? null
              : _singleRemarksController.text.trim(),
          userOfficerName: user?.name,
          userOfficerDesignation: user?.designation,
          requiresApproval: _requiresApproval,
          approvingOfficerId: finalApproverId,
          approvingOfficerName: finalApproverName,
        );

    messenger.showSnackBar(
      SnackBar(
        content: Text(!_requiresApproval
            ? '📖 Quick Log Book Entry Created & Self-Certified!'
            : '📖 Quick Log Book Entry Submitted for Approval!'),
        backgroundColor:
            !_requiresApproval ? AppColors.success : AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final vehicles = vehicleState.vehicles;
    if (_selectedVehicleId == null && vehicles.isNotEmpty) {
      _selectedVehicleId = vehicles.first.id;
    }

    return Material(
      color: AppColors.surfaceWhite,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Log Book',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Monthly Date-Wise Batch & Single Entry',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 24),
                  tooltip: 'Close Modal',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: AppColors.surfaceContainerLow,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.secondary,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(
                  icon: Icon(Icons.calendar_month_rounded, size: 18),
                  text: '🗓️ Monthly Log (Date-Wise)',
                ),
                Tab(
                  icon: Icon(Icons.add_road_rounded, size: 18),
                  text: '🚗 Single Trip Entry',
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMonthlyBatchView(vehicles),
                _buildSingleTripView(vehicles),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MONTHLY BATCH VIEW
  Widget _buildMonthlyBatchView(List<Vehicle> vehicles) {
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);

    // Fallback if vehicles is empty
    final rawVehicles = vehicles.isNotEmpty
        ? vehicles
        : [
            Vehicle(
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
            )
          ];

    final uniqueVehicles = <String, Vehicle>{};
    for (final v in rawVehicles) {
      uniqueVehicles[v.id] = v;
    }
    final effectiveVehicles = uniqueVehicles.values.toList();

    final safeVehicleId = effectiveVehicles.any((v) => v.id == _selectedVehicleId)
        ? _selectedVehicleId!
        : effectiveVehicles.first.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Vehicle & Month Selector Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOG BOOK CONFIGURATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: safeVehicleId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Official Vehicle *',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          prefixIcon: const Icon(Icons.directions_car_outlined,
                              size: 18, color: AppColors.primary),
                        ),
                        items: effectiveVehicles.map((v) {
                          return DropdownMenuItem<String>(
                            value: v.id,
                            child: Text(
                              '${v.registrationNumber} (${v.model})',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (vId) {
                          if (vId != null) {
                            setState(() {
                              _selectedVehicleId = vId;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedMonth,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedMonth =
                                  DateTime(picked.year, picked.month, 1);
                              _seedMonthlyEntries(15420.0);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            border: Border.all(color: AppColors.borderSubtle),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Month',
                                  style: TextStyle(
                                      fontSize: 9, color: AppColors.secondary)),
                              Text(
                                monthLabel,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Summary KPI Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${_dailyEntries.length} Days Recorded',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Total Distance: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      '${_totalMonthlyDistance.toStringAsFixed(1)} KM',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Date-wise Entries Header with Action Buttons
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text(
                'DAY-WISE JOURNEYS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on_rounded, size: 14),
                    label: const Text('⚡ Auto-Fill Month (20 Days)'),
                    onPressed: () {
                      final vState = ref.read(vehicleProvider);
                      final currentV = vState.vehicles.firstWhere(
                        (v) => v.id == _selectedVehicleId,
                        orElse: () => vState.vehicles.isNotEmpty
                            ? vState.vehicles.first
                            : Vehicle(
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
                              ),
                      );
                      setState(() {
                        _generateFullWorkingMonth(currentV.currentOdometer);
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('+ Add Day'),
                    onPressed: () => _showAddOrEditDayDialog(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Day-wise entries list
          if (_dailyEntries.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  const Icon(Icons.playlist_add_rounded,
                      size: 36, color: AppColors.secondary),
                  const SizedBox(height: 8),
                  const Text(
                    'No day journeys added yet for this month.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: '+ Add First Day Entry',
                    height: 36,
                    onPressed: () => _showAddOrEditDayDialog(),
                  ),
                ],
              ),
            ),
          ] else ...[
            Column(
              children: _dailyEntries.asMap().entries.map((entryMap) {
                final index = entryMap.key;
                final entry = entryMap.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Date Pill & Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              DateFormat('EEE, dd MMM yyyy').format(entry.date),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.primary),
                                tooltip: 'Edit Day Journey',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: () => _showAddOrEditDayDialog(
                                    existingItem: entry, editIndex: index),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: AppColors.error),
                                tooltip: 'Delete Day Journey',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: () => _deleteDayEntry(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Route & Purpose
                      Text(
                        '${entry.startLocation} > ${entry.destination}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Purpose: ${entry.purpose}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_outlined,
                              size: 12, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatTimeOfDay(entry.startTime)} – ${_formatTimeOfDay(entry.endTime)}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.secondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Odometer & Distance Strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${entry.openingOdometer.toStringAsFixed(0)} > ${entry.closingOdometer.toStringAsFixed(0)} KM',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.secondary),
                            ),
                            Text(
                              '${entry.distance.toStringAsFixed(1)} KM',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),

          // 5. Approval Configuration Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _requiresApproval
                  ? AppColors.surfaceContainerLow
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: _requiresApproval
                    ? AppColors.borderSubtle
                    : const Color(0xFFBBF7D0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Requires Secondary Approval?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _requiresApproval
                                ? 'Monthly log will be routed to the designated Approver'
                                : '⚡ Self-Approving Officer (Self-Certified)',
                            style: TextStyle(
                              fontSize: 11,
                              color: _requiresApproval
                                  ? AppColors.secondary
                                  : const Color(0xFF15803D),
                              fontWeight: _requiresApproval
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _requiresApproval,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _requiresApproval = val;
                        });
                      },
                    ),
                  ],
                ),
                if (_requiresApproval) ...[
                  const Divider(height: 20),
                  const Text(
                    'Approving Authority *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Builder(builder: (context) {
                    final approverOptions = <Map<String, String>>[
                      ..._presetApprovers,
                    ];
                    if (_selectedApproverId.isNotEmpty &&
                        !approverOptions.any((a) => a['id'] == _selectedApproverId)) {
                      approverOptions.insert(0, {
                        'id': _selectedApproverId,
                        'name': _selectedApproverName,
                      });
                    }
                    final safeApproverVal = _approverMode == 'CUSTOM'
                        ? 'CUSTOM'
                        : (approverOptions.any((a) => a['id'] == _selectedApproverId)
                            ? _selectedApproverId
                            : approverOptions.first['id']!);

                    return DropdownButtonFormField<String>(
                      initialValue: safeApproverVal,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        prefixIcon: const Icon(Icons.shield_outlined,
                            size: 16, color: AppColors.primary),
                      ),
                      items: approverOptions.map((appr) {
                        final isCustom = appr['id'] == 'CUSTOM';
                        return DropdownMenuItem<String>(
                          value: appr['id'],
                          child: Text(
                            appr['name']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isCustom ? FontWeight.w700 : FontWeight.w500,
                              color: isCustom
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            if (val == 'CUSTOM') {
                              _approverMode = 'CUSTOM';
                            } else {
                              _approverMode = 'PRESET';
                              _selectedApproverId = val;
                              _selectedApproverName = approverOptions
                                  .firstWhere((a) => a['id'] == val)['name']!;
                            }
                          });
                        }
                      },
                    );
                  }),
                  if (_approverMode == 'CUSTOM') ...[
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Approving Officer Name',
                      hint: 'e.g. S. P. Sharma',
                      controller: _customApproverNameController,
                      isRequired: true,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Designation',
                            hint: 'e.g. Chief Engineer',
                            controller: _customApproverDesigController,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            label: 'Officer ID',
                            hint: 'e.g. EMP-998',
                            controller: _customApproverIdController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 6. Action Buttons: Save as Draft & Submit
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: '💾 Save as Draft',
                  height: 48,
                  onPressed: () => _handleSaveMonthlyBatch(asDraft: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: _requiresApproval
                      ? '🚀 Submit Log Book'
                      : '🚀 Self-Certify Log',
                  backgroundColor: _requiresApproval
                      ? AppColors.primary
                      : AppColors.success,
                  height: 48,
                  onPressed: () => _handleSaveMonthlyBatch(asDraft: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // SINGLE TRIP VIEW
  Widget _buildSingleTripView(List<Vehicle> vehicles) {
    final singleOpen =
        double.tryParse(_singleOpenOdoController.text.trim()) ?? 0;
    final singleClose =
        double.tryParse(_singleCloseOdoController.text.trim()) ?? 0;
    final singleDist =
        (singleClose >= singleOpen) ? (singleClose - singleOpen) : 0.0;

    final rawVehicles = vehicles.isNotEmpty
        ? vehicles
        : [
            Vehicle(
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
            )
          ];

    final uniqueVehicles = <String, Vehicle>{};
    for (final v in rawVehicles) {
      uniqueVehicles[v.id] = v;
    }
    final effectiveVehicles = uniqueVehicles.values.toList();

    final safeVehicleId =
        effectiveVehicles.any((v) => v.id == _selectedVehicleId)
            ? _selectedVehicleId!
            : effectiveVehicles.first.id;

    final driverOptions = _getDriverOptions(effectiveVehicles);
    final safeDriver = driverOptions.contains(_defaultDriverName)
        ? _defaultDriverName
        : driverOptions.first;

    return Form(
      key: _singleFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle & Driver
            const Text(
              'VEHICLE & DRIVER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: safeVehicleId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Official Vehicle *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                prefixIcon: const Icon(Icons.directions_car_outlined,
                    size: 20, color: AppColors.primary),
              ),
              items: effectiveVehicles.map((v) {
                return DropdownMenuItem<String>(
                  value: v.id,
                  child: Text(
                    '${v.registrationNumber} (${v.make} ${v.model})',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (vId) {
                if (vId != null) {
                  setState(() {
                    _selectedVehicleId = vId;
                    final v = effectiveVehicles.firstWhere((x) => x.id == vId);
                    _singleOpenOdoController.text =
                        v.currentOdometer.toStringAsFixed(1);
                    _singleCloseOdoController.text =
                        (v.currentOdometer + 35.0).toStringAsFixed(1);
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: safeDriver,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Assigned Driver *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                prefixIcon: const Icon(Icons.person_pin_outlined,
                    size: 20, color: AppColors.primary),
              ),
              items: driverOptions.map((d) {
                return DropdownMenuItem<String>(
                  value: d,
                  child: Text(
                    d == 'Self-Driven (Officer)'
                        ? 'Self-Driven by Officer'
                        : '$d (Official Driver)',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _defaultDriverName = val;
                    if (val == 'Self-Driven (Officer)') {
                      _defaultDriverId = 'SELF';
                    } else {
                      _defaultDriverId = 'DRV-001';
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Date & Timings
            const Text(
              'DATE & TIMINGS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _singleJourneyDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() => _singleJourneyDate = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy')
                              .format(_singleJourneyDate),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const Text('Change',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _singleStartTime,
                      );
                      if (picked != null) {
                        setState(() => _singleStartTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outlineVariant),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Time',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.secondary)),
                          Text(_formatTimeOfDay(_singleStartTime),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _singleEndTime,
                      );
                      if (picked != null) {
                        setState(() => _singleEndTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outlineVariant),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Time',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.secondary)),
                          Text(_formatTimeOfDay(_singleEndTime),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Route & Purpose
            const Text(
              'ROUTE & PURPOSE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Starting Location',
              controller: _singleStartLocController,
              isRequired: true,
              prefixIcon: const Icon(Icons.trip_origin, size: 20),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Final Destination',
              controller: _singleDestController,
              isRequired: true,
              prefixIcon: const Icon(Icons.location_on, size: 20),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickPurposes.map((p) {
                final isSelected = _singlePurposeController.text == p;
                return ChoiceChip(
                  label: Text(p,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _singlePurposeController.text = p;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Purpose of Journey',
              controller: _singlePurposeController,
              isRequired: true,
              prefixIcon: const Icon(Icons.work_outline, size: 20),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // Odometer Readings
            const Text(
              'ODOMETER & DISTANCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Opening KM',
                    controller: _singleOpenOdoController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    isRequired: true,
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        v == null || double.tryParse(v) == null ? 'Invalid' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Closing KM',
                    controller: _singleCloseOdoController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    isRequired: true,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || double.tryParse(v) == null) {
                        return 'Invalid';
                      }
                      final o =
                          double.tryParse(_singleOpenOdoController.text) ?? 0;
                      if (double.parse(v) < o) return 'Must be >= Opening';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Official Distance:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    '${singleDist.toStringAsFixed(1)} KM',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Accompanying Staff & Remarks
            CustomTextField(
              label: 'Accompanying Staff (Optional)',
              hint: 'e.g. A. K. Gupta (AE)',
              controller: _singleAccompanyingController,
              prefixIcon: const Icon(Icons.group_outlined, size: 20),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Remarks (Optional)',
              controller: _singleRemarksController,
              prefixIcon: const Icon(Icons.notes_outlined, size: 20),
            ),
            const SizedBox(height: 24),

            // Action Button
            PrimaryButton(
              label: _requiresApproval
                ? 'Create & Submit Single Trip'
                : 'Create & Self-Certify Trip',
              icon: _requiresApproval
                  ? Icons.send_rounded
                  : Icons.verified_rounded,
              backgroundColor:
                  _requiresApproval ? AppColors.primary : AppColors.success,
              onPressed: _handleSingleTripSubmit,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
