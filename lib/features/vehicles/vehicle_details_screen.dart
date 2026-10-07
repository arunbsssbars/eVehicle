import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/vehicle.dart';
import '../../core/models/vehicle_document.dart';
import '../../core/models/fuel_and_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/odometer_display.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/providers/vehicle_provider.dart';

class VehicleDetailsScreen extends ConsumerStatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  ConsumerState<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddFuelModal(Vehicle vehicle) {
    if (vehicle.isElectric) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          title: const Row(
            children: [
              Icon(Icons.electric_car_rounded, color: AppColors.success, size: 24),
              SizedBox(width: 8),
              Text(
                'Electric Vehicle (EV)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.eco_rounded, color: AppColors.success, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '100% Zero-Emission Electric Fleet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSuccessContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Refueling is not applicable for this vehicle because it is powered entirely by battery electricity.',
                style: TextStyle(fontSize: 13, color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              const Text(
                'Energy consumption is tracked in kWh and charging logs are recorded via EV charging stations.',
                style: TextStyle(fontSize: 12, color: AppColors.secondary),
              ),
            ],
          ),
          actions: [
            PrimaryButton(
              label: 'Understood',
              height: 40,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    final fuelTypes = [
      'Diesel',
      'Petrol',
      'CNG',
      'Premium Petrol',
      'Bio-Diesel',
      'Auto LPG',
    ];

    String selectedFuelType = vehicle.fuelType.isNotEmpty &&
            fuelTypes.contains(vehicle.fuelType)
        ? vehicle.fuelType
        : 'Diesel';

    final defaultRates = {
      'Diesel': '89.60',
      'Petrol': '96.72',
      'CNG': '78.50',
      'Premium Petrol': '102.50',
      'Bio-Diesel': '84.00',
      'Auto LPG': '58.20',
    };

    final qtyController = TextEditingController(
        text: selectedFuelType == 'CNG' ? '12.5' : '45.0');
    final rateController =
        TextEditingController(text: defaultRates[selectedFuelType] ?? '89.60');
    final stationController =
        TextEditingController(text: 'Indian Oil Retail Outlet');
    final odoController = TextEditingController(
        text: (vehicle.currentOdometer + 15).toStringAsFixed(1));
    final receiptController = TextEditingController(
        text: 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    String paymentMode = 'Fleet Fuel Card';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final qty = double.tryParse(qtyController.text) ?? 0.0;
          final rate = double.tryParse(rateController.text) ?? 0.0;
          final totalCost = qty * rate;
          final isCng = selectedFuelType == 'CNG';
          final unit = isCng ? 'Kg' : 'Liters';

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_gas_station_rounded,
                              color: AppColors.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Add Fuel Refill Record',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vehicle: ${vehicle.registrationNumber} (${vehicle.make} ${vehicle.model})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Fuel Type Selector
                  const Text(
                    'Select Fuel Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fuelTypes.map((type) {
                      final isSelected = selectedFuelType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceContainerLow,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.onSurface,
                        ),
                        avatar: Icon(
                          type == 'CNG'
                              ? Icons.propane_tank_outlined
                              : Icons.local_gas_station_outlined,
                          size: 14,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedFuelType = type;
                              rateController.text =
                                  defaultRates[type] ?? rateController.text;
                              if (type == 'CNG' &&
                                  (qtyController.text == '45.0' ||
                                      qtyController.text.isEmpty)) {
                                qtyController.text = '12.5';
                              } else if (type != 'CNG' &&
                                  qtyController.text == '12.5') {
                                qtyController.text = '45.0';
                              }
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 2. Fuel Station Name & Quick Chips
                  CustomTextField(
                    label: 'Fuel Station / Outlet',
                    controller: stationController,
                    prefixIcon:
                        const Icon(Icons.location_city_rounded, size: 20),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Indian Oil (IOCL)',
                        'Bharat Petroleum (BPCL)',
                        'HPCL Outlet',
                        'Govt PWD Depot',
                        'Shell',
                      ].map((st) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(st,
                                style: const TextStyle(fontSize: 10)),
                            backgroundColor: AppColors.surfaceContainerLow,
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setModalState(() {
                                stationController.text = st;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Quantity & Rate (Live Calculation)
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Quantity ($unit)',
                          controller: qtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Rate / $unit (₹)',
                          controller: rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Live Total Cost Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calculate_outlined,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Total Fuel Cost ($selectedFuelType):',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹ ${NumberFormat('#,##0.00').format(totalCost)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Odometer & Receipt
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Odometer at Refill (KM)',
                          controller: odoController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Receipt / Bill No.',
                          controller: receiptController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Payment Mode Selector
                  const Text(
                    'Payment Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Fleet Fuel Card',
                        'Petrocash Voucher',
                        'Govt Imprest Cash',
                        'UPI / Bank Card',
                      ].map((pm) {
                        final isSel = paymentMode == pm;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(pm,
                                style: const TextStyle(fontSize: 11)),
                            selected: isSel,
                            selectedColor: AppColors.secondaryContainer,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => paymentMode = pm);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  PrimaryButton(
                    label: 'Save $selectedFuelType Refill Record',
                    icon: Icons.check_circle_outline,
                    onPressed: () async {
                      final q = double.tryParse(qtyController.text) ?? 40.0;
                      final r = double.tryParse(rateController.text) ?? 89.60;
                      final odo = double.tryParse(odoController.text) ??
                          vehicle.currentOdometer;

                      if (q <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please enter a valid fuel quantity.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      final entry = FuelEntry(
                        id: 'FUEL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                        vehicleId: vehicle.id,
                        date: DateTime.now(),
                        fuelStation: stationController.text.trim().isNotEmpty
                            ? stationController.text.trim()
                            : 'Indian Oil Retail Outlet',
                        fuelType: selectedFuelType,
                        quantityLiters: q,
                        ratePerLiter: r,
                        totalAmount: q * r,
                        odometerKm: odo,
                        receiptNumber: receiptController.text.trim().isNotEmpty
                            ? receiptController.text.trim()
                            : 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                        remarks: 'Paid via $paymentMode',
                      );

                      await ref.read(vehicleProvider.notifier).addFuel(entry);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '$selectedFuelType refill of ${q.toStringAsFixed(1)} $unit recorded successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddMaintenanceModal(Vehicle vehicle) {
    final typeController =
        TextEditingController(text: 'Periodic Scheduled Service');
    final workController = TextEditingController(
        text: 'Engine oil replacement, filters & multi-point inspection.');
    final costController = TextEditingController(text: '6500.00');
    final vendorController =
        TextEditingController(text: 'Authorized Service Center');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Maintenance Record',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Service Type',
              controller: typeController,
              prefixIcon: const Icon(Icons.build_outlined, size: 20),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Work Performed',
              controller: workController,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Cost (₹)',
                    controller: costController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Vendor / Garage',
                    controller: vendorController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save Service Record',
              onPressed: () async {
                final cost = double.tryParse(costController.text) ?? 5000.0;
                final rec = MaintenanceRecord(
                  id: 'MAINT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  vehicleId: vehicle.id,
                  serviceDate: DateTime.now(),
                  odometerKm: vehicle.currentOdometer,
                  serviceType: typeController.text.trim(),
                  workPerformed: workController.text.trim(),
                  cost: cost,
                  vendor: vendorController.text.trim(),
                  nextServiceKm: vehicle.currentOdometer + 5000.0,
                  nextServiceDate: DateTime.now().add(const Duration(days: 90)),
                  invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                );

                await ref.read(vehicleProvider.notifier).addMaintenance(rec);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Maintenance record logged successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final vehicle = vehicleState.selectedVehicle ??
        (vehicleState.vehicles.isNotEmpty ? vehicleState.vehicles.first : null);

    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vehicle Details')),
        body: const Center(child: Text('No vehicle selected')),
      );
    }

    final vehicleFuel =
        vehicleState.fuelEntries.where((f) => f.vehicleId == vehicle.id).toList();
    final vehicleMaint = vehicleState.maintenanceRecords
        .where((m) => m.vehicleId == vehicle.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(vehicle.registrationNumber),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Vehicle',
            onPressed: () => _showEditVehicleDialog(vehicle),
          ),
          PopupMenuButton<String>(
            tooltip: 'More Vehicle Actions',
            onSelected: (val) {
              if (val == 'edit') {
                _showEditVehicleDialog(vehicle);
              } else if (val == 'delete') {
                _showDeleteVehicleDialog(vehicle);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Vehicle Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('Decommission Vehicle', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Vehicle Hero Header Card
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surfaceWhite,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.registrationNumber,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${vehicle.make} ${vehicle.model} • ${vehicle.manufacturingYear}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge.fromVehicleStatus(vehicle.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OdometerDisplay(
                    reading: vehicle.currentOdometer,
                    label: 'LIVE ODOMETER READING',
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: AppColors.surfaceWhite,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.secondary,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle:
                    const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                tabs: [
                  const Tab(text: 'Overview'),
                  const Tab(text: 'Documents'),
                  const Tab(text: 'Service'),
                  Tab(text: vehicle.isElectric ? 'Energy (EV)' : 'Fuel'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Overview
                  _buildOverviewTab(vehicle),

                  // Tab 2: Documents
                  _buildDocumentsTab(vehicle),

                  // Tab 3: Service & Maintenance
                  _buildServiceTab(vehicle, vehicleMaint),

                  // Tab 4: Fuel / Energy Logs
                  _buildFuelTab(vehicle, vehicleFuel),
                ],
              ),
            ),

            // Bottom CTA Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(
                    top: BorderSide(color: AppColors.borderSubtle, width: 1)),
              ),
              child: PrimaryButton(
                label: 'Start Journey with this Vehicle',
                icon: Icons.navigation_rounded,
                onPressed: () {
                  context.push('/journeys/start');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Vehicle v) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                  'Vehicle Specification',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Vehicle Type', v.vehicleType),
                const Divider(height: 16),
                _buildDetailRow('Fuel Type', v.fuelType),
                const Divider(height: 16),
                _buildDetailRow('Manufacturing Year', '${v.manufacturingYear}'),
                const Divider(height: 16),
                _buildDetailRow('Assigned Driver', v.assignedDriverName),
                const Divider(height: 16),
                _buildDetailRow('Assigned Division', v.assignedOffice),
                const Divider(height: 16),
                _buildDetailRow(
                    'Average Fuel Efficiency', '${v.fuelEfficiencyAvg} KM/L'),
                const Divider(height: 16),
                _buildDetailRow('Monthly Target KM',
                    '${NumberFormat('#,##0').format(v.monthlyTargetKm)} KM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(Vehicle v) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: v.documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final doc = v.documents[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: doc.isExpired
                  ? AppColors.error
                  : (doc.isExpiringSoon
                      ? AppColors.warning
                      : AppColors.borderSubtle),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        doc.type == DocumentType.rc
                            ? Icons.description_outlined
                            : (doc.type == DocumentType.insurance
                                ? Icons.health_and_safety_outlined
                                : Icons.verified_outlined),
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        doc.type.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (doc.isExpired)
                    _buildDocBadge('EXPIRED', AppColors.error, AppColors.errorContainer)
                  else if (doc.isExpiringSoon)
                    _buildDocBadge('${doc.daysRemaining}d REMAINING',
                        AppColors.warning, AppColors.warningContainer)
                  else
                    _buildDocBadge(
                        'VALID', AppColors.success, AppColors.successContainer),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Doc No: ${doc.documentNumber}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Issued: ${DateFormat('dd MMM yyyy').format(doc.issueDate)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.outline),
                  ),
                  Text(
                    'Expires: ${DateFormat('dd MMM yyyy').format(doc.expiryDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: doc.isExpired
                          ? AppColors.error
                          : (doc.isExpiringSoon
                              ? AppColors.warning
                              : AppColors.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.autorenew_rounded, size: 15),
                  label: const Text(
                    'Renew Document',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _showRenewDocumentDialog(v, doc),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceTab(
      Vehicle v, List<MaintenanceRecord> records) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Service Due Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: v.isServiceDue
                  ? AppColors.warningContainer.withValues(alpha: 0.4)
                  : (v.isServiceDueSoon ? const Color(0xFFFFF7ED) : AppColors.surfaceContainerLow),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: Color(v.serviceUrgencyColorValue),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.build_circle_outlined,
                      color: Color(v.serviceUrgencyColorValue),
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  v.isServiceDue
                                      ? 'Periodic Service Overdue'
                                      : (v.isServiceDueSoon ? 'Service Due Soon' : 'Next Service Milestone'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(v.serviceUrgencyColorValue),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(v.serviceUrgencyColorValue).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Color(v.serviceUrgencyColorValue), width: 0.8),
                                ),
                                child: Text(
                                  v.serviceUrgencyLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(v.serviceUrgencyColorValue),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Target: ${NumberFormat('#,##0').format(v.nextServiceKm)} KM (${DateFormat('dd MMM yyyy').format(v.nextServiceDate)})',
                            style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      v.remainingKmToService >= 0
                          ? '• ${NumberFormat('#,##0').format(v.remainingKmToService)} KM remaining'
                          : '• ${NumberFormat('#,##0').format(v.remainingKmToService.abs())} KM overdue',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(v.serviceUrgencyColorValue),
                      ),
                    ),
                    Text(
                      v.remainingDaysToService >= 0
                          ? '• ${v.remainingDaysToService} days remaining'
                          : '• ${v.remainingDaysToService.abs()} days overdue',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(v.serviceUrgencyColorValue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Maintenance History',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Service'),
                onPressed: () => _showAddMaintenanceModal(v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No maintenance records logged yet.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = records[index];
                return Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              r.serviceType,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${NumberFormat('#,##0').format(r.cost)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.workPerformed,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Vendor: ${r.vendor}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.outline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy').format(r.serviceDate),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFuelTab(Vehicle v, List<FuelEntry> entries) {
    if (v.isElectric) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // EV Energy Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              color: AppColors.success, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Electric Vehicle (EV)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ZERO EMISSION',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSuccessContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Refueling is not applicable for this vehicle because it is 100% Electric (EV). Electrical energy is supplied via EV battery charging stations.',
                    style: TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),

                  // EV Spec Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Powertrain', 'Permanent Magnet Synchronous'),
                        const Divider(height: 14),
                        _buildDetailRow(
                            'Average Consumption', '${v.fuelEfficiencyAvg} KM/kWh'),
                        const Divider(height: 14),
                        _buildDetailRow('Battery Capacity', '50.3 kWh NMC Lithium-Ion'),
                        const Divider(height: 14),
                        _buildDetailRow('Certified Range', '~385 KM (Full Charge)'),
                        const Divider(height: 14),
                        _buildDetailRow('Fast Charging Port', 'CCS Type 2 (DC 50 kW)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Refueling Disabled Notice Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block_rounded,
                      color: AppColors.secondary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refueling Disabled for EV',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'This vehicle does not accept petrol, diesel, or gas. Charging logs are managed by department EV charging point management.',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final totalSpent = entries.fold(0.0, (sum, f) => sum + f.totalAmount);
    final totalLiters = entries.fold(0.0, (sum, f) => sum + f.quantityLiters);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Fuel Summary Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('TOTAL FUEL',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('${totalLiters.toStringAsFixed(0)} L',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.outlineVariant),
                Expanded(
                  child: Column(
                    children: [
                      const Text('EXPENDITURE',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('₹${NumberFormat('#,##0').format(totalSpent)}',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.outlineVariant),
                Expanded(
                  child: Column(
                    children: [
                      const Text('AVG EFFICIENCY',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('${v.fuelEfficiencyAvg} KM/L',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Fuel Fill Records',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.local_gas_station_outlined, size: 16),
                label: const Text('Add Fuel Refill'),
                onPressed: () => _showAddFuelModal(v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No fuel records logged yet.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final f = entries[index];
                final isCng = f.fuelType.toUpperCase() == 'CNG';
                final unit = isCng ? 'Kg' : 'L';

                Color badgeColor = AppColors.primary;
                if (f.fuelType.toLowerCase().contains('diesel')) {
                  badgeColor = const Color(0xFF1E40AF);
                } else if (f.fuelType.toLowerCase().contains('petrol')) {
                  badgeColor = const Color(0xFFB45309);
                } else if (f.fuelType.toLowerCase().contains('cng')) {
                  badgeColor = const Color(0xFF15803D);
                } else if (f.fuelType.toLowerCase().contains('bio')) {
                  badgeColor = const Color(0xFF0F766E);
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    f.fuelStation,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: badgeColor.withValues(alpha: 0.3),
                                        width: 0.8),
                                  ),
                                  child: Text(
                                    f.fuelType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${f.quantityLiters}$unit @ ₹${f.ratePerLiter}/$unit • ${f.odometerKm.toStringAsFixed(0)} KM',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.secondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(f.date)}${f.receiptNumber != null ? " • Bill: ${f.receiptNumber!}" : ""}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.outline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${NumberFormat('#,##0.00').format(f.totalAmount)}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.secondary),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDocBadge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  Future<void> _showEditVehicleDialog(Vehicle vehicle) async {
    final formKey = GlobalKey<FormState>();
    final makeController = TextEditingController(text: vehicle.make);
    final modelController = TextEditingController(text: vehicle.model);
    final yearController = TextEditingController(text: vehicle.manufacturingYear.toString());
    final driverController = TextEditingController(text: vehicle.assignedDriverName);
    final officeController = TextEditingController(text: vehicle.assignedOffice);
    final targetKmController = TextEditingController(text: vehicle.monthlyTargetKm.toStringAsFixed(0));

    String selectedFuel = vehicle.fuelType;
    String selectedType = vehicle.vehicleType;
    VehicleStatus selectedStatus = vehicle.status;

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
                child: const Icon(Icons.edit_road_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Edit ${vehicle.registrationNumber}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
                  children: [
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
                            decoration: const InputDecoration(labelText: 'Fuel'),
                            items: ['Petrol', 'Diesel', 'CNG', 'Electric']
                                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedFuel = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: ['Sedan', 'SUV', 'Hatchback', 'Bus', 'Truck'].contains(selectedType) ? selectedType : 'Sedan',
                            decoration: const InputDecoration(labelText: 'Type'),
                            items: ['Sedan', 'SUV', 'Hatchback', 'Bus', 'Truck']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<VehicleStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: VehicleStatus.values
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: driverController,
                            decoration: const InputDecoration(
                              labelText: 'Assigned Driver',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                            ),
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
                      controller: officeController,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Office / Department',
                        prefixIcon: Icon(Icons.business_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: targetKmController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Target (KM)',
                        prefixIcon: Icon(Icons.speed, size: 20),
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
            ElevatedButton(
              child: const Text('Save Changes'),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final year = int.tryParse(yearController.text.trim()) ?? vehicle.manufacturingYear;
                  final targetKm = double.tryParse(targetKmController.text.trim()) ?? vehicle.monthlyTargetKm;

                  final updated = vehicle.copyWith(
                    make: makeController.text.trim(),
                    model: modelController.text.trim(),
                    manufacturingYear: year,
                    fuelType: selectedFuel,
                    vehicleType: selectedType,
                    status: selectedStatus,
                    assignedDriverName: driverController.text.trim(),
                    assignedOffice: officeController.text.trim(),
                    monthlyTargetKm: targetKm,
                  );

                  Navigator.pop(dialogCtx);
                  await ref.read(vehicleProvider.notifier).updateVehicle(updated);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Vehicle ${vehicle.registrationNumber} updated successfully.'),
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

  Future<void> _showDeleteVehicleDialog(Vehicle vehicle) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Decommission Vehicle',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.error),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to decommission ${vehicle.registrationNumber} (${vehicle.displayName}) from the fleet?',
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for removal (Optional)',
                hintText: 'e.g. Scrapped, sold, transferred',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Decommission Vehicle'),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(vehicleProvider.notifier).deleteVehicle(
                    vehicle.id,
                    reason: reasonController.text.trim().isNotEmpty
                        ? reasonController.text.trim()
                        : null,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vehicle ${vehicle.registrationNumber} decommissioned.'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
                context.pop(); // Return to vehicle list
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showRenewDocumentDialog(Vehicle vehicle, VehicleDocument doc) async {
    final formKey = GlobalKey<FormState>();
    final docNumController = TextEditingController(text: doc.documentNumber);
    DateTime newExpiry = doc.expiryDate.isAfter(DateTime.now())
        ? doc.expiryDate.add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 365));

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
                child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Renew ${doc.type.label}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle: ${vehicle.registrationNumber} (${vehicle.displayName})',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: docNumController,
                  decoration: const InputDecoration(
                    labelText: 'New Certificate / Policy Number *',
                    prefixIcon: Icon(Icons.receipt_long, size: 20),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter certificate/policy number' : null,
                ),
                const SizedBox(height: 14),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: AppColors.primary),
                  title: const Text('New Expiry Date', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(DateFormat('dd MMMM yyyy').format(newExpiry)),
                  trailing: OutlinedButton(
                    child: const Text('Change Date'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: newExpiry,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) {
                        setDialogState(() => newExpiry = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirm Renewal'),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final renewedDoc = VehicleDocument(
                    id: doc.id,
                    vehicleId: vehicle.id,
                    type: doc.type,
                    documentNumber: docNumController.text.trim(),
                    issueDate: DateTime.now(),
                    expiryDate: newExpiry,
                    isVerified: true,
                  );

                  Navigator.pop(dialogCtx);
                  await ref.read(vehicleProvider.notifier).renewDocument(vehicle.id, renewedDoc);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${doc.type.label} renewed successfully! Valid till ${DateFormat("dd MMM yyyy").format(newExpiry)}'),
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
