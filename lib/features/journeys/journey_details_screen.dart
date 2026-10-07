import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/journey.dart';
import '../../core/models/user.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/odometer_display.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/storage/local_database.dart';
import '../reports/pdf_report_generator.dart';

class JourneyDetailsScreen extends ConsumerStatefulWidget {
  final String journeyId;

  const JourneyDetailsScreen({super.key, required this.journeyId});

  @override
  ConsumerState<JourneyDetailsScreen> createState() =>
      _JourneyDetailsScreenState();
}

class _JourneyDetailsScreenState extends ConsumerState<JourneyDetailsScreen> {
  void _handleDuplicateJourney(Journey j) async {
    final newJourney = await LocalDatabase.instance.duplicateJourney(j.id);
    ref.read(journeyProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicated journey as draft #${newJourney.id}'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => context.push('/journeys/${newJourney.id}'),
          ),
        ),
      );
    }
  }

  void _showLogExpenseDialog(Journey j) {
    final amountCtrl = TextEditingController(
      text: j.expenseAmount != null && j.expenseAmount! > 0
          ? j.expenseAmount!.toStringAsFixed(2)
          : '',
    );
    final noteCtrl = TextEditingController(text: j.expenseReceiptUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Trip Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Record or modify out-of-pocket fuel, toll, or parking expenses for this journey.',
              style: TextStyle(fontSize: 12, color: AppColors.secondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Expense Amount (₹) *',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Expense Note / Bill Ref',
                hintText: 'e.g. Fastag toll receipt #4892',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              Navigator.pop(ctx);
              await LocalDatabase.instance.updateJourneyExpense(
                j.id,
                expenseAmount: amt,
                expenseReceiptUrl: noteCtrl.text.trim(),
              );
              ref.read(journeyProvider.notifier).refresh();
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expense logged: ₹${amt.toStringAsFixed(2)}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }

  void _handleSubmitDraft(Journey j) async {
    await ref.read(journeyProvider.notifier).submitDraftJourney(j.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Journey ${j.id} submitted for approval successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _handleApprove(Journey j) async {
    final auth = ref.read(authProvider);
    final approverName = auth.currentUser?.name ?? 'Approving Officer';
    await ref
        .read(journeyProvider.notifier)
        .approveJourney(j.id, approverName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Journey ${j.id} approved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showRejectDialog(Journey j) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error),
            SizedBox(width: 8),
            Text('Reject Journey Record'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a mandatory reason for rejecting this official record:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Odometer reading mismatch or unauthorized route...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final auth = ref.read(authProvider);
              final rejectorName = auth.currentUser?.name ?? 'Approver';
              await ref.read(journeyProvider.notifier).rejectJourney(
                    j.id,
                    rejectorName,
                    reasonController.text.trim(),
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Journey has been rejected.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  void _handleLock(Journey j) async {
    final auth = ref.read(authProvider);
    final lockerName = auth.currentUser?.name ?? 'Admin';
    await ref.read(journeyProvider.notifier).lockJourney(j.id, lockerName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Journey ${j.id} has been locked and archived.'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  void _handleExportPdf(Journey j) async {
    await PdfReportGenerator.generateJourneySlip(context: context, journey: j);
  }

  void _handleDeleteJourney(Journey j) {
    final authState = ref.read(authProvider);
    final currentUser = authState.currentUser;

    // Strict validation: Only the user who completed the journey can delete it
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
            'Only the officer or user who completed this journey (${j.userOfficerName}) has the rights to delete this record.',
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
        !j.requiresApproval || currentUser.isSelfApprover;

    if (j.status != JourneyStatus.approved || isSelfApprover) {
      // Direct deletion confirmation
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.delete_forever_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Text(isSelfApprover && j.status == JourneyStatus.approved
                  ? 'Delete Approved Journey'
                  : 'Delete Journey Record'),
            ],
          ),
          content: Text(
            isSelfApprover && j.status == JourneyStatus.approved
                ? 'As you are the approving authority, this approved journey (${j.id}) will be permanently deleted and removed from the official register.'
                : 'Are you sure you want to delete journey ${j.id} (${j.calculatedDistance.toStringAsFixed(1)} KM)? This action cannot be undone.',
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
                await ref.read(journeyProvider.notifier).deleteJourney(j.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Journey ${j.id} deleted successfully.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      );
    } else {
      // Approved journey requires re-approval for deletion
      final reasonController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text('Re-Approval for Deletion', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This journey is currently APPROVED. Deleting an approved record requires official review and re-approval from your Approving Officer.',
                  style: TextStyle(fontSize: 12, color: AppColors.secondary),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Reason for Deletion *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Duplicate entry created in error, incorrect route logged...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
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

  void _showEditJourneyModal(Journey j) {
    final authState = ref.read(authProvider);
    final currentUser = authState.currentUser;

    // Strict validation: Only the user who completed the journey has rights to edit it
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
        !j.requiresApproval || currentUser.isSelfApprover;

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
                        Expanded(
                          child: Row(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSelfApprover
                                          ? 'Edit Journey (Self-Approver)'
                                          : (isApproved
                                              ? 'Edit Approved Journey'
                                              : 'Edit Journey Record'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Vehicle: ${j.vehicleRegistration} • ID: ${j.id}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.secondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

                          // 5. OFFICIAL TRAVELER & ROW SIGNATURE
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
                                    const Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.badge_outlined,
                                              size: 18, color: AppColors.primary),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Used by Other Employee / Subordinate?',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyProvider);
    final authState = ref.watch(authProvider);
    final currentUser = authState.currentUser;

    final match = journeyState.journeys.where(
        (j) => j.id == widget.journeyId || j.localId == widget.journeyId);
    if (match.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Journey Details')),
        body: const Center(child: Text('Journey record not found')),
      );
    }

    final j = match.first;

    // Strict ownership check: Only the user who performed/completed the journey can edit it
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

    final isSelfApprover =
        !j.requiresApproval || (currentUser?.isSelfApprover ?? false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                j.id,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const Text(
              'Official Journey Details',
              style: TextStyle(fontSize: 10, color: AppColors.secondary),
            ),
          ],
        ),
        actions: [
          if (isJourneyUser &&
              j.status != JourneyStatus.locked &&
              j.status != JourneyStatus.active)
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: isSelfApprover
                  ? 'Edit Journey (Self-Certified)'
                  : (j.status == JourneyStatus.approved
                      ? 'Edit Approved Record (Re-Approval Required)'
                      : 'Edit Journey Record'),
              onPressed: () => _showEditJourneyModal(j),
            ),
          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.copy_all_rounded, size: 20),
            tooltip: 'Duplicate Journey (Clone Route & Vehicle)',
            onPressed: () => _handleDuplicateJourney(j),
          ),
          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
            tooltip: 'Download Official PDF Slip',
            onPressed: () => _handleExportPdf(j),
          ),
          if (isJourneyUser && j.status != JourneyStatus.locked)
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
              tooltip: isSelfApprover || j.status != JourneyStatus.approved
                  ? 'Delete Journey'
                  : 'Request Deletion (Re-Approval Required)',
              onPressed: () => _handleDeleteJourney(j),
            ),
          const SizedBox(width: 4),
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
              // Header Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryFixed,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'OFFICIAL RECORD',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SelectableText(
                                  j.id,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge.fromJourneyStatus(j.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        StatusBadge.fromSyncStatus(j.syncStatus),
                        Text(
                          'Recorded: ${DateFormat('dd MMM yyyy, hh:mm a').format(j.createdAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Odometer & Official Distance Card (Compact Executive Dashboard)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.speed_rounded,
                                  size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Odometer & Official Distance',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Text(
                            'OFFICIAL TELEMETRY',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Distance Summary Result (Compact & Prominent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OFFICIAL LOG-BOOK DISTANCE',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Formula: Closing KM − Opening KM',
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
                            '${j.calculatedDistance.toStringAsFixed(1)} KM',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Dual Odometer Column (Slim, Prominent & Low Height)
                    Column(
                      children: [
                        OdometerDisplay(
                          reading: j.openingOdometer,
                          label: 'OPENING KM',
                          isSlim: true,
                        ),
                        const SizedBox(height: 8),
                        OdometerDisplay(
                          reading: j.closingOdometer ?? j.openingOdometer,
                          label: 'CLOSING KM',
                          previousReading: j.openingOdometer,
                          isSlim: true,
                        ),
                      ],
                    ),
                    if (j.gpsDistance != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'GPS Verification Distance: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.secondary,
                            ),
                          ),
                          Text(
                            '${j.gpsDistance!.toStringAsFixed(1)} KM (Supporting)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Trip Details (Origin, Destination, Purpose, Vehicle, Driver)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip Information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Starting Location', j.startLocation, icon: Icons.trip_origin),
                    const Divider(height: 16),
                    _buildInfoRow('Final Destination', j.destination.isEmpty ? 'In Transit' : j.destination, icon: Icons.location_on),
                    const Divider(height: 16),
                    _buildInfoRow('Official Purpose', j.purpose, icon: Icons.work_outline),
                    const Divider(height: 16),
                    _buildInfoRow('Vehicle', '${j.vehicleRegistration} (${j.vehicleModel})', icon: Icons.directions_car_outlined),
                    const Divider(height: 16),
                    _buildInfoRow('Assigned Driver', j.driverName, icon: Icons.person_pin_outlined),
                    const Divider(height: 16),
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(top: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.people_outline,
                                size: 18, color: AppColors.primary),
                          ),
                          title: const Text(
                            'Traveling Officer, Staff & Remarks',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          subtitle: const Text(
                            'Tap to view signed officer, accompanying staff & remarks',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.secondary,
                            ),
                          ),
                          children: [
                            const Divider(height: 16),
                            _buildInfoRow(
                              'Traveling Officer (Signed)',
                              '✍️ ${j.userOfficerName} (${j.userOfficerDesignation})',
                              icon: Icons.person_outline,
                            ),
                            // Deduplicate: only show dedicated officer if clearly distinct from userOfficerName
                            if (j.officerName.trim().toLowerCase() !=
                                    j.userOfficerName.trim().toLowerCase() &&
                                j.isSubordinateJourney) ...[
                              const Divider(height: 16),
                              _buildInfoRow('Dedicated Vehicle Officer',
                                  '${j.officerName} (${j.department})',
                                  icon: Icons.badge_outlined),
                            ],
                            if (j.accompanyingOfficers != null &&
                                j.accompanyingOfficers!.trim().isNotEmpty) ...[
                              const Divider(height: 16),
                              _buildInfoRow('Accompanying Staff',
                                  j.accompanyingOfficers!,
                                  icon: Icons.group_outlined),
                            ],
                            if (j.remarks != null &&
                                j.remarks!.trim().isNotEmpty) ...[
                              const Divider(height: 16),
                              _buildInfoRow(
                                  'Official Remarks', j.remarks!,
                                  icon: Icons.notes_outlined),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Expense & Classification Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Expenses & Reimbursement',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showLogExpenseDialog(j),
                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                          label: Text(j.expenseAmount != null && j.expenseAmount! > 0 ? 'Edit Expense' : 'Log Expense'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            'Classification',
                            j.tripCategory.label,
                            icon: Icons.category_outlined,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoRow(
                            'Expense Logged',
                            j.expenseAmount != null && j.expenseAmount! > 0
                                ? '₹${j.expenseAmount!.toStringAsFixed(2)}'
                                : 'None',
                            icon: Icons.currency_rupee_rounded,
                          ),
                        ),
                      ],
                    ),
                    if (j.expenseReceiptUrl != null && j.expenseReceiptUrl!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildInfoRow(
                        'Receipt / Note',
                        j.expenseReceiptUrl!,
                        icon: Icons.description_outlined,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Collapsible Approval & Audit Trail
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                    title: const Text(
                      'Approval & Audit History',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      j.status == JourneyStatus.approved
                          ? 'Approved • Tap to view details'
                          : (j.status == JourneyStatus.rejected
                              ? 'Rejected • Tap to view reason'
                              : 'Created • Tap to view log'),
                      style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                    ),
                    children: [
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),
                      if (j.status == JourneyStatus.approved && j.approvedBy != null) ...[
                        _buildAuditItem(
                          icon: Icons.verified,
                          color: AppColors.success,
                          title: 'Approved by ${j.approvedBy}',
                          time: j.approvedAt != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(j.approvedAt!)
                              : 'Approved',
                        ),
                      ],
                      if (j.status == JourneyStatus.rejected && j.rejectedBy != null) ...[
                        _buildAuditItem(
                          icon: Icons.cancel,
                          color: AppColors.error,
                          title: 'Rejected by ${j.rejectedBy}',
                          subtitle: 'Reason: ${j.rejectionReason ?? "None provided"}',
                          time: j.rejectedAt != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(j.rejectedAt!)
                              : 'Rejected',
                        ),
                      ],
                      if (j.status == JourneyStatus.locked && j.lockedBy != null) ...[
                        _buildAuditItem(
                          icon: Icons.lock,
                          color: AppColors.gray700,
                          title: 'Locked & Archived by ${j.lockedBy}',
                          time: j.lockedAt != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(j.lockedAt!)
                              : 'Locked',
                        ),
                      ],
                      _buildAuditItem(
                        icon: Icons.create,
                        color: AppColors.primary,
                        title: 'Created by ${j.officerName}',
                        time: DateFormat('dd MMM yyyy, hh:mm a').format(j.createdAt),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Draft Actions (Submit for Approval or Complete Journey)
              if (j.status == JourneyStatus.draft) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This record is currently saved as DRAFT. Submit it to send it for official verification & approval.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (j.closingOdometer != null) ...[
                  PrimaryButton(
                    label: 'Submit for Official Approval',
                    icon: Icons.send_rounded,
                    onPressed: () => _handleSubmitDraft(j),
                  ),
                ] else ...[
                  PrimaryButton(
                    label: 'Complete Journey (Enter Closing KM)',
                    icon: Icons.flag_outlined,
                    onPressed: () => context.push('/journeys/end', extra: j),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Officer Approval Actions (if Approving Officer/Admin and Status is Pending)
              if (currentUser?.isApprover ?? false) ...[
                if (j.status == JourneyStatus.pendingApproval || j.status == JourneyStatus.submitted) ...[
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Approve Journey',
                          icon: Icons.check_circle_outline,
                          backgroundColor: AppColors.success,
                          onPressed: () => _handleApprove(j),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SecondaryButton(
                          label: 'Reject...',
                          icon: Icons.cancel_outlined,
                          textColor: AppColors.error,
                          borderColor: AppColors.error,
                          onPressed: () => _showRejectDialog(j),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (j.status == JourneyStatus.approved && currentUser?.isAdmin == true) ...[
                  SecondaryButton(
                    label: 'Lock Monthly Record',
                    icon: Icons.lock_outline,
                    onPressed: () => _handleLock(j),
                  ),
                  const SizedBox(height: 12),
                ],
              ],

              // Export PDF Button
              PrimaryButton(
                label: 'Generate Official PDF Slip',
                icon: Icons.print_outlined,
                onPressed: () => _handleExportPdf(j),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.outline),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditItem({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: AppColors.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
