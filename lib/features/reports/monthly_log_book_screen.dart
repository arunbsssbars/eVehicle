import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/vehicle.dart';
import '../../core/models/journey.dart';
import '../../core/models/user.dart';
import '../../core/models/signatory_config.dart';
import '../../core/utils/file_download_helper.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/ad_service.dart';
import 'pdf_report_generator.dart';

class MonthlyLogBookScreen extends ConsumerStatefulWidget {
  const MonthlyLogBookScreen({super.key});

  @override
  ConsumerState<MonthlyLogBookScreen> createState() =>
      _MonthlyLogBookScreenState();
}

class _MonthlyLogBookScreenState extends ConsumerState<MonthlyLogBookScreen> {
  DateTime _selectedMonth = DateTime(2026, 8);
  Vehicle? _selectedVehicle;

  // Customizable Column Visibility Flags
  final Map<String, bool> _columns = {
    'date': true,
    'driver': true,
    'from_to': true,
    'purpose': true,
    'opening': true,
    'closing': true,
    'distance': true,
    'status': true,
    'officer_signature': true,
    'signatures': true,
    'actions': true,
  };

  // Customizable Signatory Persons
  SignatoryConfig _signatoryConfig = const SignatoryConfig();

  @override
  void initState() {
    super.initState();
    final vehicles = ref.read(vehicleProvider).vehicles;
    if (vehicles.isNotEmpty) {
      _selectedVehicle = vehicles.first;
      _signatoryConfig = SignatoryConfig(
        signatory1Name: _selectedVehicle!.assignedDriverName,
        signatory2Name: 'Dr. S. K. Verma (EE)',
      );
    }
  }

  void _showColumnCustomizerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.view_column_rounded,
                              color: AppColors.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Customize Export Columns',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            for (var key in _columns.keys) {
                              _columns[key] = true;
                            }
                          });
                          setState(() {});
                        },
                        child: const Text('Select All',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Text(
                    'Select or exclude columns from the screen table, official PDF, and CSV exports.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  _buildColumnToggle('Date', 'date', setModalState),
                  _buildColumnToggle('Driver Name', 'driver', setModalState),
                  _buildColumnToggle('Route (From → To)', 'from_to', setModalState),
                  _buildColumnToggle('Purpose of Travel', 'purpose', setModalState),
                  _buildColumnToggle('Opening KM', 'opening', setModalState),
                  _buildColumnToggle('Closing KM', 'closing', setModalState),
                  _buildColumnToggle('Total Distance (KM)', 'distance', setModalState),
                  _buildColumnToggle('Approval Status', 'status', setModalState),
                  _buildColumnToggle('Signature of Traveling Officer', 'officer_signature', setModalState),
                  _buildColumnToggle('Signatures Block', 'signatures', setModalState),
                  _buildColumnToggle('Actions (Edit / Delete)', 'actions', setModalState),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Apply Columns Filter',
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  void _showSignatoryCustomizerDialog() {
    bool enableSig1 = _signatoryConfig.enableSignatory1;
    final sig1TitleCtrl =
        TextEditingController(text: _signatoryConfig.signatory1Title);
    final sig1NameCtrl =
        TextEditingController(text: _signatoryConfig.signatory1Name);
    bool enableSig2 = _signatoryConfig.enableSignatory2;
    final sig2TitleCtrl =
        TextEditingController(text: _signatoryConfig.signatory2Title);
    final sig2NameCtrl =
        TextEditingController(text: _signatoryConfig.signatory2Name);
    bool enableSig3 = _signatoryConfig.enableSignatory3;
    final sig3TitleCtrl = TextEditingController(
        text: _signatoryConfig.signatory3Title ?? 'Counter-Signature / HOD');
    final sig3NameCtrl = TextEditingController(
        text: _signatoryConfig.signatory3Name ?? 'Anjali Sharma, IAS');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Material(
              type: MaterialType.transparency,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_ind_outlined,
                          color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Customize Signatory Persons',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Define the official names and designations for the logbook certification signatures.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),

                  // Signatory 1 (Driver / In-charge)
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Enable Signatory 1 (Driver / Vehicle In-charge)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    value: enableSig1,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => enableSig1 = val),
                  ),
                  if (enableSig1) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: sig1TitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title / Role Label',
                        hintText: 'e.g. Signature of Driver',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sig1NameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Officer / Driver Name',
                        hintText: 'e.g. Rajesh Kumar',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Signatory 2 (Controlling Officer)
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Enable Signatory 2 (Controlling / Verifying Officer)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    value: enableSig2,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => enableSig2 = val),
                  ),
                  if (enableSig2) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: sig2TitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title / Designation',
                        hintText: 'e.g. Controlling Officer (EE / SE)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sig2NameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Officer Name',
                        hintText: 'e.g. Dr. S. K. Verma (EE)',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Optional Signatory 3 (Counter-Signature)
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Enable 3rd Counter-Signature (HOD / DM)',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    value: enableSig3,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setModalState(() => enableSig3 = val);
                    },
                  ),
                  if (enableSig3) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: sig3TitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Counter-Signatory Designation',
                        hintText: 'e.g. Superintending Engineer / HOD',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sig3NameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Counter-Signatory Name',
                        hintText: 'e.g. Anjali Sharma, IAS',
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  PrimaryButton(
                    label: 'Save & Apply Signatories',
                    onPressed: () {
                      setState(() {
                        _signatoryConfig = SignatoryConfig(
                          enableSignatory1: enableSig1,
                          signatory1Title: sig1TitleCtrl.text.trim(),
                          signatory1Name: sig1NameCtrl.text.trim(),
                          enableSignatory2: enableSig2,
                          signatory2Title: sig2TitleCtrl.text.trim(),
                          signatory2Name: sig2NameCtrl.text.trim(),
                          enableSignatory3: enableSig3,
                          signatory3Title: sig3TitleCtrl.text.trim(),
                          signatory3Name: sig3NameCtrl.text.trim(),
                        );
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signatory persons updated successfully.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildColumnToggle(
      String title, String key, void Function(void Function()) setModalState) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      value: _columns[key] ?? true,
      activeThumbColor: AppColors.primary,
      onChanged: (val) {
        setModalState(() {
          _columns[key] = val;
        });
        setState(() {});
      },
    );
  }

  void _handleDownloadPdf(List<Journey> journeys) {
    if (_selectedVehicle == null) return;
    AdService.showRewardedAdGate(
      context: context,
      ref: ref,
      benefit: 'Monthly Log Book PDF',
      onRewardEarned: () => _executeDownloadPdf(journeys),
    );
  }

  void _executeDownloadPdf(List<Journey> journeys) {
    if (_selectedVehicle == null) return;
    final currentUser = ref.read(authProvider).currentUser;
    PdfReportGenerator.generateMonthlyLogBookPdf(
      context: context,
      vehicle: _selectedVehicle!,
      monthYear: DateFormat('MMMM yyyy').format(_selectedMonth),
      journeys: journeys,
      organizationName: currentUser?.organizationName,
      department: currentUser?.department,
      visibleColumns: {
        'sno': true,
        'date': _columns['date'] ?? true,
        'driver': _columns['driver'] ?? true,
        'from': _columns['from_to'] ?? true,
        'to': _columns['from_to'] ?? true,
        'purpose': _columns['purpose'] ?? true,
        'opening': _columns['opening'] ?? true,
        'closing': _columns['closing'] ?? true,
        'distance': _columns['distance'] ?? true,
        'status': _columns['status'] ?? true,
        'officer_signature': _columns['officer_signature'] ?? true,
        'signatures': _columns['signatures'] ?? true,
      },
      signatoryConfig: _signatoryConfig,
    );
  }

  void _handleExportCsv(List<Journey> journeys) {
    AdService.showRewardedAdGate(
      context: context,
      ref: ref,
      benefit: 'Monthly Register CSV',
      onRewardEarned: () => _executeExportCsv(journeys),
    );
  }

  void _executeExportCsv(List<Journey> journeys) async {
    final buffer = StringBuffer();
    final headers = <String>[];

    if (_columns['date'] == true) headers.add('Date');
    if (_columns['driver'] == true) headers.add('Driver');
    if (_columns['officer_signature'] == true) {
      headers.add('Signature of Traveling Officer');
    }
    if (_columns['from_to'] == true) {
      headers.add('Start Location');
      headers.add('Destination');
    }
    if (_columns['purpose'] == true) headers.add('Purpose');
    if (_columns['opening'] == true) headers.add('Opening KM');
    if (_columns['closing'] == true) headers.add('Closing KM');
    if (_columns['distance'] == true) headers.add('Distance KM');
    if (_columns['status'] == true) headers.add('Status');

    buffer.writeln(headers.map((h) => '"$h"').join(','));

    for (final j in journeys) {
      final row = <String>[];
      if (_columns['date'] == true) {
        row.add(DateFormat('yyyy-MM-dd').format(j.journeyDate));
      }
      if (_columns['driver'] == true) row.add(j.driverName);
      if (_columns['officer_signature'] == true) {
        row.add('${j.userOfficerName} (${j.userOfficerDesignation})');
      }
      if (_columns['from_to'] == true) {
        row.add(j.startLocation);
        row.add(j.destination);
      }
      if (_columns['purpose'] == true) row.add(j.purpose);
      if (_columns['opening'] == true) {
        row.add(j.openingOdometer.toStringAsFixed(1));
      }
      if (_columns['closing'] == true) {
        row.add(j.closingOdometer?.toStringAsFixed(1) ?? '');
      }
      if (_columns['distance'] == true) {
        row.add(j.calculatedDistance.toStringAsFixed(1));
      }
      if (_columns['status'] == true) row.add(j.status.label);

      buffer.writeln(row.map((val) => '"$val"').join(','));
    }

    final reg = _selectedVehicle?.registrationNumber.replaceAll(' ', '_') ?? 'Fleet';
    final monthStr = DateFormat('yyyy_MM').format(_selectedMonth);
    final filename = 'Monthly_LogBook_${reg}_$monthStr.csv';

    await FileDownloadHelper.downloadTextFile(
      context: context,
      content: buffer.toString(),
      filename: filename,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded $filename (${headers.length} columns, ${journeys.length} rows).',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showEditJourneyModal(Journey j) {
    final authState = ref.read(authProvider);
    final currentUser = authState.currentUser;

    final isJourneyUser = currentUser != null &&
        (j.officerId == currentUser.id ||
            j.userOfficerName.trim().toLowerCase() ==
                currentUser.name.trim().toLowerCase() ||
            j.officerName.trim().toLowerCase() ==
                currentUser.name.trim().toLowerCase() ||
            (currentUser.role == UserRole.driver &&
                (j.driverId == currentUser.id ||
                    j.driverName.trim().toLowerCase() ==
                        currentUser.name.trim().toLowerCase())));

    if (!isJourneyUser) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.error),
              SizedBox(width: 8),
              Text('Permission Restricted'),
            ],
          ),
          content: Text(
            'Only the officer or user who completed this journey (${j.userOfficerName}) has the rights to edit this record.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final isSelfApprover =
        !j.requiresApproval || (currentUser.isSelfApprover);

    DateTime editDate = j.journeyDate;
    TimeOfDay editStartTime = TimeOfDay.fromDateTime(j.startTime);
    TimeOfDay editEndTime = TimeOfDay.fromDateTime(j.endTime ?? j.startTime.add(const Duration(hours: 3)));

    bool editIsSubordinate = j.isSubordinateJourney;
    bool editRequiresApproval = j.requiresApproval;

    final startLocController = TextEditingController(text: j.startLocation);
    final destController = TextEditingController(text: j.destination);
    final purposeController = TextEditingController(text: j.purpose);
    final openOdoController =
        TextEditingController(text: j.openingOdometer.toStringAsFixed(1));
    final closeOdoController = TextEditingController(
        text: j.closingOdometer?.toStringAsFixed(1) ?? '');
    final driverController = TextEditingController(text: j.driverName);
    final officerController = TextEditingController(text: j.userOfficerName);
    final designationController =
        TextEditingController(text: j.userOfficerDesignation);
    final accompanyingController =
        TextEditingController(text: j.accompanyingOfficers ?? '');
    final remarksController = TextEditingController(text: j.remarks ?? '');
    final revisionReasonController = TextEditingController(
      text: j.status == JourneyStatus.approved
          ? (isSelfApprover
              ? 'Self-certified data update by officer'
              : 'Official data correction / revision')
          : 'Update journey details',
    );

    final formKey = GlobalKey<FormState>();
    final isApproved = j.status == JourneyStatus.approved;

    final purposeOptions = [
      'Highway & Drainage Site Inspection',
      'Official Duty / Court Appearance',
      'Collectorate / District Meeting',
      'Field Survey & Land Demarcation',
      'VIP / Dignitary Movement Escort',
      'General Administrative Duty',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final openVal =
              double.tryParse(openOdoController.text.trim()) ?? j.openingOdometer;
          final closeVal = double.tryParse(closeOdoController.text.trim());
          final previewDist = (closeVal != null && closeVal >= openVal)
              ? (closeVal - openVal)
              : (j.calculatedDistance);

          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                    decoration: const BoxDecoration(
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
                                color: isSelfApprover
                                    ? AppColors.successContainer
                                    : (isApproved
                                        ? AppColors.warningContainer
                                        : AppColors.primaryFixed),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isSelfApprover
                                    ? Icons.verified_user_rounded
                                    : (isApproved
                                        ? Icons.history_edu_rounded
                                        : Icons.edit_note_rounded),
                                color: isSelfApprover
                                    ? AppColors.success
                                    : (isApproved
                                        ? AppColors.warning
                                        : AppColors.primary),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSelfApprover
                                      ? 'Edit Journey (Self-Approver)'
                                      : (isApproved
                                          ? 'Edit Approved Journey'
                                          : 'Edit Journey Record'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  'Vehicle: ${j.vehicleRegistration} • ID: ${j.id}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bctx),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Form(
                      key: formKey,
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (isSelfApprover) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd),
                                border:
                                    Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.verified_user_outlined,
                                      color: AppColors.success, size: 22),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '⚡ Self-Approving Authority Mode',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'You are an approving authority for this journey. Any edits will be updated and self-certified immediately without secondary approval delay.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF166534),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else if (isApproved) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd),
                                border:
                                    Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Color(0xFFD97706), size: 22),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Re-Approval Required Upon Saving',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'This journey was previously approved. Editing route, distance, or officials will reset its status to Pending Approval and route it back for official re-approval.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF92400E),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 1. DATE & TIME SECTION
                          const Text(
                            'JOURNEY DATE & SCHEDULE',
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
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: editDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setModalState(() => editDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.borderSubtle),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('dd MMM yyyy')
                                              .format(editDate),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
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
                                    final t = await showTimePicker(
                                      context: context,
                                      initialTime: editStartTime,
                                    );
                                    if (t != null) {
                                      setModalState(() => editStartTime = t);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.borderSubtle),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          editStartTime.format(context),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 2. ROUTE & DESTINATION
                          const Text(
                            'ROUTE & DESTINATION',
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
                            controller: startLocController,
                            isRequired: true,
                            prefixIcon: const Icon(Icons.trip_origin, size: 20),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Final Destination',
                            controller: destController,
                            isRequired: true,
                            prefixIcon: const Icon(Icons.location_on, size: 20),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 18),

                          // 3. PURPOSE OF TRAVEL
                          const Text(
                            'PURPOSE OF TRAVEL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: purposeOptions.map((opt) {
                              final isSel = purposeController.text.trim() == opt;
                              return ChoiceChip(
                                label: Text(opt,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    )),
                                selected: isSel,
                                onSelected: (sel) {
                                  if (sel) {
                                    setModalState(() {
                                      purposeController.text = opt;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            label: 'Travel Purpose (Text)',
                            controller: purposeController,
                            isRequired: true,
                            prefixIcon: const Icon(Icons.work_outline, size: 20),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 18),

                          // 4. ODOMETER & DISTANCES
                          const Text(
                            'ODOMETER & OFFICIAL DISTANCE',
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
                                  controller: openOdoController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  isRequired: true,
                                  onChanged: (_) => setModalState(() {}),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    if (double.tryParse(v) == null) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Closing KM',
                                  controller: closeOdoController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  isRequired: true,
                                  onChanged: (_) => setModalState(() {}),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    final val = double.tryParse(v);
                                    if (val == null) return 'Invalid';
                                    final o = double.tryParse(
                                            openOdoController.text.trim()) ??
                                        0;
                                    if (val < o) return 'Must be >= Opening';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMd),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recalculated Distance:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                Text(
                                  '${previewDist.toStringAsFixed(1)} KM',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 5. OFFICIAL TRAVELER & ROW SIGNATURE (Other Employee Duty Support)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: editIsSubordinate
                                  ? const Color(0xFFEFF6FF)
                                  : AppColors.surfaceContainerLow,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMd),
                              border: Border.all(
                                color: editIsSubordinate
                                    ? const Color(0xFFBFDBFE)
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.badge_outlined,
                                            size: 18, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text(
                                          'Used by Other Employee / Subordinate?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: editIsSubordinate,
                                      onChanged: (val) {
                                        setModalState(() {
                                          editIsSubordinate = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (editIsSubordinate)
                                  const Text(
                                    'Tag this trip as performed by another employee on behalf of the vehicle controlling officer. Row-level signature will capture the actual traveler.',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.secondary),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: editIsSubordinate
                                      ? 'Actual Traveling Employee'
                                      : 'Traveling Officer',
                                  controller: officerController,
                                  isRequired: true,
                                  prefixIcon: const Icon(Icons.person, size: 20),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Designation',
                                  controller: designationController,
                                  isRequired: true,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Assigned Driver',
                            controller: driverController,
                            isRequired: true,
                            prefixIcon: const Icon(
                                Icons.person_pin_circle_outlined,
                                size: 20),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Accompanying Staff',
                            hint: 'e.g. A. K. Gupta (AE), R. S. Negi (JE)',
                            controller: accompanyingController,
                            prefixIcon:
                                const Icon(Icons.group_outlined, size: 20),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: 'Remarks / Revision Reason',
                            hint: 'Reason for modifying this journey record...',
                            controller: revisionReasonController,
                            maxLines: 2,
                            prefixIcon:
                                const Icon(Icons.notes_outlined, size: 20),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: isSelfApprover
                                ? 'Save Changes (Self-Certified)'
                                : (isApproved
                                    ? 'Save & Resubmit for Re-Approval'
                                    : 'Save Changes'),
                            icon: isSelfApprover
                                ? Icons.verified_rounded
                                : (isApproved
                                    ? Icons.send_rounded
                                    : Icons.check_circle_outline),
                            backgroundColor: isSelfApprover
                                ? AppColors.success
                                : (isApproved
                                    ? AppColors.warning
                                    : AppColors.primary),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              Navigator.pop(bctx);

                              final startDT = DateTime(
                                editDate.year,
                                editDate.month,
                                editDate.day,
                                editStartTime.hour,
                                editStartTime.minute,
                              );
                              final endDT = DateTime(
                                editDate.year,
                                editDate.month,
                                editDate.day,
                                editEndTime.hour,
                                editEndTime.minute,
                              );

                              await ref
                                  .read(journeyProvider.notifier)
                                  .editJourney(
                                    journeyId: j.id,
                                    journeyDate: editDate,
                                    startTime: startDT,
                                    endTime: endDT,
                                    startLocation:
                                        startLocController.text.trim(),
                                    destination: destController.text.trim(),
                                    purpose: purposeController.text.trim(),
                                    openingOdometer: double.tryParse(
                                        openOdoController.text.trim()),
                                    closingOdometer: double.tryParse(
                                        closeOdoController.text.trim()),
                                    driverName: driverController.text.trim(),
                                    userOfficerName:
                                        officerController.text.trim(),
                                    userOfficerDesignation:
                                        designationController.text.trim(),
                                    isSubordinateJourney: editIsSubordinate,
                                    officerSignatureText:
                                        officerController.text.trim(),
                                    requiresApproval: editRequiresApproval,
                                    accompanyingOfficers:
                                        accompanyingController.text.trim(),
                                    remarks: remarksController.text.trim(),
                                    editReason:
                                        revisionReasonController.text.trim(),
                                  );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isSelfApprover
                                        ? 'Journey ${j.id} updated and self-certified.'
                                        : (isApproved
                                            ? 'Journey ${j.id} updated! Previous approval revoked; queued for re-approval.'
                                            : 'Journey ${j.id} updated successfully.')),
                                    backgroundColor: isSelfApprover
                                        ? AppColors.success
                                        : (isApproved
                                            ? AppColors.warning
                                            : AppColors.primary),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          SecondaryButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.pop(bctx),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleDeleteJourney(Journey j) {
    final authState = ref.read(authProvider);
    final currentUser = authState.currentUser;

    final isJourneyUser = currentUser != null &&
        (j.officerId == currentUser.id ||
            j.userOfficerName.trim().toLowerCase() ==
                currentUser.name.trim().toLowerCase() ||
            j.officerName.trim().toLowerCase() ==
                currentUser.name.trim().toLowerCase() ||
            (currentUser.role == UserRole.driver &&
                (j.driverId == currentUser.id ||
                    j.driverName.trim().toLowerCase() ==
                        currentUser.name.trim().toLowerCase())));

    if (!isJourneyUser) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.error),
              SizedBox(width: 8),
              Text('Permission Restricted'),
            ],
          ),
          content: Text(
            'Only the officer who completed this journey (${j.userOfficerName}) has permission to delete this record.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final isSelfApprover =
        !j.requiresApproval || (currentUser.isSelfApprover);

    if (j.status != JourneyStatus.approved || isSelfApprover) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Journey Record'),
          content: Text(
            'Are you sure you want to permanently delete journey ${j.id} (${j.startLocation.split(',').first} → ${j.destination.split(',').first}, ${j.calculatedDistance.toStringAsFixed(1)} KM)?',
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
              onPressed: () async {
                Navigator.pop(ctx);
                await ref
                    .read(journeyProvider.notifier)
                    .deleteJourney(j.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Journey ${j.id} deleted successfully.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      );
    } else {
      final reasonController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text('Deletion Approval Required'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journey ${j.id} is already approved. Deleting an approved official journey requires secondary approval from your approving officer.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Reason for Deletion *',
                  hint: 'e.g. Duplicate entry created in error',
                  controller: reasonController,
                  maxLines: 2,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please provide a valid reason'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final reason = reasonController.text.trim();
                Navigator.pop(ctx);
                await ref
                    .read(journeyProvider.notifier)
                    .deleteJourney(j.id, reason: reason);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Deletion request submitted for Journey ${j.id} and routed for re-approval.'),
                      backgroundColor: const Color(0xFFD97706),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text('Submit Deletion Request'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final vehicleState = ref.watch(vehicleProvider);
    final journeyState = ref.watch(journeyProvider);

    final currentUser = authState.currentUser;
    final vehicles = vehicleState.vehicles;
    if (_selectedVehicle == null && vehicles.isNotEmpty) {
      _selectedVehicle = vehicles.first;
    }

    final monthlyJourneys = journeyState.journeys.where((j) {
      final matchMonth = j.journeyDate.year == _selectedMonth.year &&
          j.journeyDate.month == _selectedMonth.month;
      final matchVehicle = _selectedVehicle == null ||
          j.vehicleId == _selectedVehicle!.id ||
          j.vehicleRegistration == _selectedVehicle!.registrationNumber;
      return matchMonth && matchVehicle;
    }).toList();

    final totalDistance = monthlyJourneys.fold(
        0.0, (sum, j) => sum + j.calculatedDistance);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Official Monthly Log Book'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded),
            tooltip: 'Multi-Journey / Monthly Log Entry',
            onPressed: () => context.push('/journeys/batch-create', extra: {
              'month': _selectedMonth,
              'vehicleId': _selectedVehicle?.id,
            }),
          ),
          IconButton(
            icon: const Icon(Icons.assignment_ind_outlined),
            tooltip: 'Signatory Persons',
            onPressed: _showSignatoryCustomizerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.view_column_outlined),
            tooltip: 'Customize Columns',
            onPressed: _showColumnCustomizerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download PDF',
            onPressed: () => _handleDownloadPdf(monthlyJourneys),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: () => _handleExportCsv(monthlyJourneys),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.marginMobile,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter & Selector Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Vehicle>(
                            isExpanded: true,
                            initialValue: _selectedVehicle,
                            decoration: const InputDecoration(
                              labelText: 'Select Vehicle',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: vehicles.map((v) {
                              return DropdownMenuItem(
                                value: v,
                                child: Text(
                                  v.registrationNumber,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedVehicle = v;
                                if (v != null) {
                                  _signatoryConfig = _signatoryConfig.copyWith(
                                    signatory1Name: v.assignedDriverName,
                                  );
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                                      DateTime(picked.year, picked.month);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusMd),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat('MMM yyyy')
                                          .format(_selectedMonth),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_month,
                                      size: 18, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Quick Action Link Row & Create Button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSm),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text(
                              '+ Create / Quick Fill Log Book',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            onPressed: () => context.push(
                              '/journeys/batch-create',
                              extra: {
                                'month': _selectedMonth,
                                'vehicleId': _selectedVehicle?.id,
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        InkWell(
                          onTap: _showSignatoryCustomizerDialog,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_document,
                                  size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Signatories Config',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _showColumnCustomizerDialog,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tune,
                                  size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                'Columns (${_columns.values.where((v) => v).length}/${_columns.length})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Official Register Card Preview
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Official Header Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppDimensions.radiusLg - 1)),
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.borderSubtle, width: 1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(currentUser?.organizationName ?? "Government of Uttar Pradesh").toUpperCase()} • ${(currentUser?.department ?? "Public Works Department").toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'MONTHLY VEHICLE LOG BOOK REGISTER',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Vehicle: ${_selectedVehicle?.registrationNumber ?? ""} (${_selectedVehicle?.make} ${_selectedVehicle?.model})',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600),
                              ),
                              if (_columns['driver'] == true)
                                Text(
                                  'Driver: ${_selectedVehicle?.assignedDriverName ?? ""}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Log Register Table or Empty State
                    if (monthlyJourneys.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryFixed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.menu_book_rounded,
                                  size: 38, color: AppColors.primary),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No Log Book Entries for ${DateFormat("MMMM yyyy").format(_selectedMonth)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No journeys recorded for vehicle ${_selectedVehicle?.registrationNumber ?? ""}. You can batch create or auto-fill date-wise entries for this month.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            PrimaryButton(
                              label:
                                  '🚀 Create Monthly Log Book for ${DateFormat("MMMM yyyy").format(_selectedMonth)}',
                              icon: Icons.add_circle_outline,
                              onPressed: () => context.push(
                                '/journeys/batch-create',
                                extra: {
                                  'month': _selectedMonth,
                                  'vehicleId': _selectedVehicle?.id,
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              AppColors.surfaceContainer),
                          columnSpacing: 16,
                          horizontalMargin: 16,
                          columns: [
                            if (_columns['date'] == true)
                              const DataColumn(
                                  label: Text('Date',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            if (_columns['driver'] == true)
                              const DataColumn(
                                  label: Text('Driver',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            if (_columns['from_to'] == true)
                              const DataColumn(
                                  label: Text('From → To',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            if (_columns['purpose'] == true)
                              const DataColumn(
                                  label: Text('Purpose',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            if (_columns['opening'] == true)
                              const DataColumn(
                                  label: Text('Opening',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            if (_columns['closing'] == true)
                              const DataColumn(
                                  label: Text('Closing',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            if (_columns['distance'] == true)
                              const DataColumn(
                                  label: Text('Dist (KM)',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            if (_columns['status'] == true)
                              const DataColumn(
                                  label: Text('Status',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            if (_columns['officer_signature'] == true)
                              const DataColumn(
                                  label: Text('Signature of Traveling Officer',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                            if (_columns['actions'] == true)
                              const DataColumn(
                                  label: Text('Actions',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                          ],
                          rows: monthlyJourneys.map((j) {
                            return DataRow(
                              cells: [
                                if (_columns['date'] == true)
                                  DataCell(Text(
                                      DateFormat('dd/MM').format(j.journeyDate),
                                      style: const TextStyle(fontSize: 12))),
                                if (_columns['driver'] == true)
                                  DataCell(Text(j.driverName.split(' ')[0],
                                      style: const TextStyle(fontSize: 12))),
                                if (_columns['from_to'] == true)
                                  DataCell(
                                    Text(
                                      '${j.startLocation.split(',').first} → ${j.destination.split(',').first}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                if (_columns['purpose'] == true)
                                  DataCell(Text(j.purpose,
                                      style: const TextStyle(fontSize: 11))),
                                if (_columns['opening'] == true)
                                  DataCell(Text(
                                      j.openingOdometer.toStringAsFixed(0),
                                      style: const TextStyle(fontSize: 12))),
                                if (_columns['closing'] == true)
                                  DataCell(Text(
                                      j.closingOdometer?.toStringAsFixed(0) ?? '-',
                                      style: const TextStyle(fontSize: 12))),
                                if (_columns['distance'] == true)
                                  DataCell(
                                    Text(
                                      j.calculatedDistance.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                if (_columns['status'] == true)
                                  DataCell(StatusBadge.fromJourneyStatus(j.status)),
                                if (_columns['officer_signature'] == true)
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '✍️ ${j.userOfficerName}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          j.userOfficerDesignation,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_columns['actions'] == true)
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 18, color: AppColors.primary),
                                          tooltip: 'Edit Journey',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showEditJourneyModal(j),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppColors.error),
                                          tooltip: 'Delete Journey',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () =>
                                              _handleDeleteJourney(j),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                    // Total Distance Footer
                    if (_columns['distance'] == true)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryFixed,
                          border: Border(
                            top: BorderSide(
                                color: AppColors.borderSubtle, width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL MONTHLY DISTANCE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Official verified logbook distance',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.secondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${totalDistance.toStringAsFixed(1)} KM',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Certification & Signatures Box (Customizable)
                    if (_columns['signatures'] == true)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                const Text(
                                  'Official Certification',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                InkWell(
                                  onTap: _showSignatoryCustomizerDialog,
                                  child: const Text(
                                    'Edit Signatories',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'I hereby certify that the journeys recorded above were performed solely in discharge of official duties for public interest.',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 8,
                              runSpacing: 12,
                              children: [
                                if (_signatoryConfig.enableSignatory1 &&
                                    _signatoryConfig.signatory1Title.trim().isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                          width: 90,
                                          height: 1,
                                          color: AppColors.outline),
                                      const SizedBox(height: 4),
                                      Text(_signatoryConfig.signatory1Title,
                                          style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700)),
                                      if (_signatoryConfig
                                          .signatory1Name.trim().isNotEmpty)
                                        Text('(${_signatoryConfig.signatory1Name})',
                                            style: const TextStyle(
                                                fontSize: 9,
                                                color: AppColors.secondary)),
                                    ],
                                  ),
                                if (_signatoryConfig.enableSignatory3 &&
                                    _signatoryConfig.signatory3Title != null &&
                                    _signatoryConfig.signatory3Title!.trim().isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                          width: 90,
                                          height: 1,
                                          color: AppColors.outline),
                                      const SizedBox(height: 4),
                                      Text(_signatoryConfig.signatory3Title!,
                                          style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700)),
                                      if (_signatoryConfig.signatory3Name !=
                                              null &&
                                          _signatoryConfig
                                              .signatory3Name!.trim().isNotEmpty)
                                        Text(
                                            '(${_signatoryConfig.signatory3Name!})',
                                            style: const TextStyle(
                                                fontSize: 9,
                                                color: AppColors.secondary)),
                                    ],
                                  ),
                                if (_signatoryConfig.enableSignatory2 &&
                                    _signatoryConfig.signatory2Title.trim().isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                          width: 90,
                                          height: 1,
                                          color: AppColors.outline),
                                      const SizedBox(height: 4),
                                      Text(_signatoryConfig.signatory2Title,
                                          style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700)),
                                      if (_signatoryConfig
                                          .signatory2Name.trim().isNotEmpty)
                                        Text('(${_signatoryConfig.signatory2Name})',
                                            style: const TextStyle(
                                                fontSize: 9,
                                                color: AppColors.secondary)),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Export Actions
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Download PDF Register',
                      icon: Icons.picture_as_pdf,
                      onPressed: () => _handleDownloadPdf(monthlyJourneys),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Export Excel (CSV)',
                      icon: Icons.table_chart_outlined,
                      onPressed: () => _handleExportCsv(monthlyJourneys),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
