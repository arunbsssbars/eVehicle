import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/vehicle.dart';
import '../../core/models/vehicle_document.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/services/saas_entitlement_service.dart';
import '../../core/widgets/quota_usage_meter_card.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/storage/local_database.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final vehicles = vehicleState.filteredVehicles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vehicles & Fleet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Vehicle',
            onPressed: () => _showAddVehicleDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surfaceWhite,
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(vehicleProvider.notifier).setSearchQuery(val);
                },
                decoration: InputDecoration(
                  hintText: 'Search by registration, model, driver...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(vehicleProvider.notifier)
                                .setSearchQuery('');
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                ),
              ),
            ),

            // Vehicle count & fleet summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceContainerLow,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${vehicles.length} Vehicles in Fleet',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (vehicleState.serviceDueCount > 0 ||
                      vehicleState.expiringDocsCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (vehicleState.serviceDueCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warningContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${vehicleState.serviceDueCount} Service Due',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                ],
              ),
            ),

            // Vehicle List & SaaS Quota Meter
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vehicles.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final user = ref.watch(authProvider).currentUser;
                    final orgId = user?.organizationId ?? 'ORG-PWD-01';
                    final org = LocalDatabase.instance.getOrganizationById(orgId) ??
                        LocalDatabase.instance.organizations.first;
                    const entitlement = SaasEntitlementService();
                    final summary = entitlement.getQuotaUsage(
                      organization: org,
                      vehicleCount: vehicles.length,
                      monthlyJourneyCount: LocalDatabase.instance.journeys.length,
                    );
                    return QuotaUsageMeterCard(
                      organization: org,
                      quotaSummary: summary,
                    );
                  }
                  final v = vehicles[index - 1];
                  return _buildVehicleCard(context, v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle v) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () {
          ref.read(vehicleProvider.notifier).selectVehicle(v);
          context.push('/vehicles/details');
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                          child: Icon(
                            v.fuelType == 'Electric'
                                ? Icons.electric_car_outlined
                                : Icons.directions_car_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.registrationNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${v.make} ${v.model} (${v.fuelType})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
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
                  const SizedBox(width: 8),
                  StatusBadge.fromVehicleStatus(v.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT ODOMETER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.outline,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${NumberFormat('#,##0.0').format(v.currentOdometer)} KM',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'ASSIGNED DRIVER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.outline,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v.assignedDriverName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (v.isServiceDue || v.expiringSoonDocumentsCount > 0 || v.expiredDocumentsCount > 0) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (v.isServiceDue)
                      _buildAlertPill(
                        'Service Due (${NumberFormat('#,##0').format(v.nextServiceKm)} KM)',
                        AppColors.warning,
                        AppColors.warningContainer,
                      ),
                    if (v.expiredDocumentsCount > 0)
                      _buildAlertPill(
                        '${v.expiredDocumentsCount} Document Expired',
                        AppColors.error,
                        AppColors.errorContainer,
                      ),
                    if (v.expiringSoonDocumentsCount > 0)
                      _buildAlertPill(
                        '${v.expiringSoonDocumentsCount} Doc Expiring Soon',
                        AppColors.warning,
                        AppColors.warningContainer,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Vehicle Log & Diagnostics',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Vehicle',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded,
                            size: 16, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertPill(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> _showAddVehicleDialog(BuildContext context) async {
    final user = ref.read(authProvider).currentUser;
    final orgId = user?.organizationId ?? 'ORG-PWD-01';
    final org = LocalDatabase.instance.getOrganizationById(orgId) ??
        LocalDatabase.instance.organizations.first;
    const entitlement = SaasEntitlementService();
    final canAdd = entitlement.canAddVehicle(
      currentVehicleCount: LocalDatabase.instance.vehicles.length,
      tier: org.subscriptionTier,
    );

    if (!canAdd) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(child: Text('Vehicle Quota Reached', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            ],
          ),
          content: Text(
            'Your current ${org.subscriptionTier.label} plan allows up to ${org.subscriptionTier.maxVehicles} vehicles. Upgrade to Pro Fleet or Enterprise Commercial to add more fleet vehicles.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/plans');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Plan'),
            ),
          ],
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final regController = TextEditingController();
    final makeController = TextEditingController(text: 'Maruti Suzuki');
    final modelController = TextEditingController(text: 'Ertiga');
    final yearController = TextEditingController(text: DateTime.now().year.toString());
    final odoController = TextEditingController(text: '0.0');
    final driverController = TextEditingController(
      text: LocalDatabase.instance.currentUser?.name ?? 'Rajesh Kumar',
    );
    final officeController = TextEditingController(
      text: LocalDatabase.instance.currentUser?.office ?? 'District Division 1',
    );
    final targetKmController = TextEditingController(text: '2500');
    final insNumberController = TextEditingController(text: 'INS-${DateTime.now().year}-1092');
    final pucNumberController = TextEditingController(text: 'PUC-${DateTime.now().year}-8841');

    String selectedFuel = 'Diesel';
    String selectedType = 'SUV';
    DateTime insExpiry = DateTime.now().add(const Duration(days: 365));
    DateTime pucExpiry = DateTime.now().add(const Duration(days: 180));

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_car, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Register New Vehicle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: regController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number *',
                        hintText: 'e.g. UP16 AB 1234',
                        prefixIcon: Icon(Icons.pin, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter registration number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: makeController,
                            decoration: const InputDecoration(labelText: 'Make *'),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: modelController,
                            decoration: const InputDecoration(labelText: 'Model *'),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedFuel,
                            decoration: const InputDecoration(labelText: 'Fuel Type'),
                            items: const [
                              DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                              DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                              DropdownMenuItem(value: 'CNG', child: Text('CNG')),
                              DropdownMenuItem(value: 'Electric', child: Text('Electric')),
                              DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedFuel = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            decoration: const InputDecoration(labelText: 'Vehicle Type'),
                            items: const [
                              DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                              DropdownMenuItem(value: 'Sedan', child: Text('Sedan')),
                              DropdownMenuItem(value: 'Hatchback', child: Text('Hatchback')),
                              DropdownMenuItem(value: 'Truck', child: Text('Truck')),
                              DropdownMenuItem(value: 'Jeep', child: Text('Jeep')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: odoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Initial Odometer (KM) *',
                              prefixIcon: Icon(Icons.speed, size: 20),
                            ),
                            validator: (val) {
                              if (val == null || double.tryParse(val.trim()) == null) {
                                return 'Enter valid KM';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Year'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: driverController,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Driver / Officer',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: officeController,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Office / Department',
                        prefixIcon: Icon(Icons.business_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Mandatory Documents',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.security, color: AppColors.primary, size: 20),
                      title: const Text('Insurance Expiry'),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(insExpiry)),
                      trailing: TextButton(
                        child: const Text('Change'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: insExpiry,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) {
                            setDialogState(() => insExpiry = picked);
                          }
                        },
                      ),
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.eco, color: AppColors.success, size: 20),
                      title: const Text('PUC Expiry'),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(pucExpiry)),
                      trailing: TextButton(
                        child: const Text('Change'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: pucExpiry,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            setDialogState(() => pucExpiry = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save Vehicle'),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newId = 'VEH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                  final odo = double.tryParse(odoController.text.trim()) ?? 0.0;
                  final year = int.tryParse(yearController.text.trim()) ?? DateTime.now().year;
                  final targetKm = double.tryParse(targetKmController.text.trim()) ?? 2500.0;

                  final docIns = VehicleDocument(
                    id: 'DOC-INS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    vehicleId: newId,
                    type: DocumentType.insurance,
                    documentNumber: insNumberController.text.trim().isNotEmpty
                        ? insNumberController.text.trim()
                        : 'INS-${DateTime.now().year}-${newId.substring(4)}',
                    issueDate: DateTime.now(),
                    expiryDate: insExpiry,
                  );

                  final docPuc = VehicleDocument(
                    id: 'DOC-PUC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    vehicleId: newId,
                    type: DocumentType.puc,
                    documentNumber: pucNumberController.text.trim().isNotEmpty
                        ? pucNumberController.text.trim()
                        : 'PUC-${DateTime.now().year}-${newId.substring(4)}',
                    issueDate: DateTime.now(),
                    expiryDate: pucExpiry,
                  );

                  final newVehicle = Vehicle(
                    id: newId,
                    registrationNumber: regController.text.trim().toUpperCase(),
                    make: makeController.text.trim(),
                    model: modelController.text.trim(),
                    vehicleType: selectedType,
                    fuelType: selectedFuel,
                    manufacturingYear: year,
                    currentOdometer: odo,
                    assignedOffice: officeController.text.trim().isNotEmpty
                        ? officeController.text.trim()
                        : 'District Division 1',
                    assignedDriverId: LocalDatabase.instance.currentUser?.id ?? 'USR-001',
                    assignedDriverName: driverController.text.trim().isNotEmpty
                        ? driverController.text.trim()
                        : 'Assigned Driver',
                    documents: [docIns, docPuc],
                    monthlyTargetKm: targetKm,
                    nextServiceKm: odo + 10000.0,
                    nextServiceDate: DateTime.now().add(const Duration(days: 90)),
                    fuelEfficiencyAvg: selectedFuel == 'Electric' ? 7.5 : 14.5,
                  );

                  Navigator.pop(dialogCtx);
                  await ref.read(vehicleProvider.notifier).addVehicle(newVehicle);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Vehicle ${newVehicle.registrationNumber} added successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
