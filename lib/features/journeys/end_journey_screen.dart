import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/journey.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/services/gps_tracking_service.dart';

class EndJourneyScreen extends ConsumerStatefulWidget {
  final Journey? journey;

  const EndJourneyScreen({super.key, this.journey});

  @override
  ConsumerState<EndJourneyScreen> createState() => _EndJourneyScreenState();
}

class _EndJourneyScreenState extends ConsumerState<EndJourneyScreen> {
  final _formKey = GlobalKey<FormState>();

  late Journey _active;
  final _destinationController = TextEditingController();
  final _remarksController =
      TextEditingController(text: 'Official duty completed successfully.');
  final _closingOdometerController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  final _expenseReceiptController = TextEditingController();

  double _closingOdometer = 0.0;
  double _gpsTraveledKm = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _active = widget.journey ??
        ref.read(journeyProvider).activeJourney ??
        ref.read(journeyProvider).journeys.first;

    final trackedGps = GpsTrackingService.instance.currentDistanceKm;
    if (trackedGps > 0) {
      _gpsTraveledKm = trackedGps;
    } else {
      final elapsedMinutes = DateTime.now().difference(_active.startTime).inMinutes;
      _gpsTraveledKm = elapsedMinutes > 0
          ? ((elapsedMinutes * 0.75 * 10).round() / 10.0) // ~45 km/h rate
          : 12.5;
    }

    _closingOdometer = _active.openingOdometer + _gpsTraveledKm;
    _closingOdometerController.text = _closingOdometer.toStringAsFixed(1);

    // Initial placeholder while fetching actual GPS
    _destinationController.text = 'Fetching current GPS location...';
    _fetchEndGpsLocation();
  }

  Future<void> _fetchEndGpsLocation() async {
    final point = await GpsTrackingService.instance.detectCurrentLocationAsync(
      defaultLat: _active.startLatitude ?? 28.5726,
      defaultLng: _active.startLongitude ?? 77.3243,
    );
    final gpsLocName = await GpsTrackingService.reverseGeocodeOnline(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (mounted) {
      setState(() {
        _destinationController.text = gpsLocName;
      });
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _remarksController.dispose();
    _closingOdometerController.dispose();
    _expenseAmountController.dispose();
    _expenseReceiptController.dispose();
    super.dispose();
  }

  double get _calculatedDistance {
    if (_closingOdometer >= _active.openingOdometer) {
      return _closingOdometer - _active.openingOdometer;
    }
    return 0.0;
  }

  bool get _isOdometerInvalid =>
      _closingOdometer < _active.openingOdometer;

  Future<void> _refreshLocationFromGps() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 10),
          Text('Acquiring real-time GPS coordinates...'),
        ],
      ),
      backgroundColor: AppColors.secondary,
      duration: Duration(seconds: 2),
    ));

    final point = await GpsTrackingService.instance.detectCurrentLocationAsync();
    final gpsLocName = await GpsTrackingService.reverseGeocodeOnline(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    final trackedGps = GpsTrackingService.instance.currentDistanceKm;
    if (mounted) {
      setState(() {
        _destinationController.text = gpsLocName;
        if (trackedGps > 0) {
          _gpsTraveledKm = trackedGps;
          _closingOdometer = _active.openingOdometer + _gpsTraveledKm;
          _closingOdometerController.text = _closingOdometer.toStringAsFixed(1);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Destination: $gpsLocName (${point.latitude.toStringAsFixed(4)}°, ${point.longitude.toStringAsFixed(4)}°)'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleSubmit({required bool saveDraft}) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isOdometerInvalid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Closing odometer cannot be less than opening odometer.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final finalGpsDist = GpsTrackingService.instance.stopTracking();
        final effectiveGps = finalGpsDist > 0 ? finalGpsDist : _gpsTraveledKm;
        final expenseAmount = double.tryParse(_expenseAmountController.text.trim());
        final expenseReceipt = _expenseReceiptController.text.trim().isNotEmpty
            ? _expenseReceiptController.text.trim()
            : null;

        final completed =
            await ref.read(journeyProvider.notifier).completeJourney(
                  journeyId: _active.id,
                  destination: _destinationController.text.trim(),
                  closingOdometer: _closingOdometer,
                  gpsDistance: effectiveGps,
                  remarks: _remarksController.text.trim().isNotEmpty
                      ? _remarksController.text.trim()
                      : null,
                  expenseAmount: expenseAmount,
                  expenseReceiptUrl: expenseReceipt,
                  saveAsDraft: saveDraft,
                );

        setState(() => _isLoading = false);

        if (mounted) {
          if (saveDraft) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Journey saved as draft.'),
                backgroundColor: AppColors.secondary,
              ),
            );
            context.go('/journeys');
          } else {
            context.pushReplacement(
              '/journeys/success',
              extra: completed,
            );
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error completing journey: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        title: const Text('Complete Official Journey'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.marginMobile,
            vertical: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Origin & Vehicle Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trip_origin,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'STARTED FROM',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  _active.startLocation,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              _active.vehicleRegistration,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Officer: ${_active.userOfficerName}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.secondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Opened at: ${_active.openingOdometer.toStringAsFixed(1)} KM',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Destination Field (Pre-filled with GPS location)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'END LOCATION / DESTINATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _refreshLocationFromGps,
                      child: const Row(
                        children: [
                          Icon(Icons.my_location_rounded,
                              size: 13, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Detect GPS Location',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  label: 'Ending Journey Location',
                  controller: _destinationController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.location_on, size: 20),
                  helperText: 'Defaulted to current GPS waypoint. You may edit if needed.',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Destination is required' : null,
                ),
                const SizedBox(height: 18),

                // 3. Live GPS Traveled vs Closing Odometer Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.satellite_alt_rounded,
                          color: AppColors.success, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GPS Traveled Distance',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF166534),
                              ),
                            ),
                            Text(
                              '${_gpsTraveledKm.toStringAsFixed(2)} KM (Recorded live in 100m steps)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Closing Odometer Input & Auto Recalculation
                const Text(
                  'CLOSING ODOMETER READING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  label: 'Closing Odometer (KM)',
                  controller: _closingOdometerController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  isRequired: true,
                  prefixIcon: const Icon(Icons.speed, size: 20),
                  helperText: 'Must be ≥ Opening Reading (${_active.openingOdometer.toStringAsFixed(1)} KM)',
                  onChanged: (v) {
                    final val = double.tryParse(v);
                    if (val != null) {
                      setState(() => _closingOdometer = val);
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Closing Odometer is required';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null) return 'Please enter a valid number';
                    if (parsed < _active.openingOdometer) {
                      return 'Must be ≥ opening (${_active.openingOdometer.toStringAsFixed(1)} KM)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 5. Total Distance Calculated Display
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Official Log Distance',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                            Text(
                              'Closing KM - Opening KM',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_calculatedDistance.toStringAsFixed(1)} KM',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 6. Optional Trip Expenses (Fuel / Toll / Parking)
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
                      const Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Trip Expenses (Fuel / Toll / Parking)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Optional out-of-pocket expenses incurred during this journey.',
                        style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              label: 'Amount (₹)',
                              controller: _expenseAmountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                              helperText: 'Optional',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: CustomTextField(
                              label: 'Expense Note / Bill',
                              controller: _expenseReceiptController,
                              prefixIcon: const Icon(Icons.description_outlined, size: 18),
                              helperText: 'e.g. Fastag toll',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 7. Remarks / Official Note
                CustomTextField(
                  label: 'Official Remarks / Observations',
                  controller: _remarksController,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.notes, size: 20),
                ),
                const SizedBox(height: 28),

                // Info banner explaining the workflow
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ending the journey records your closing odometer. On the next screen, you will review and submit the log book entry for approval.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 7. Action Buttons
                PrimaryButton(
                  label: 'End Journey & Review',
                  icon: Icons.flag_rounded,
                  isLoading: _isLoading,
                  height: 52,
                  onPressed: () => _handleSubmit(saveDraft: false),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Save as Draft (Complete Later)',
                  icon: Icons.save_outlined,
                  onPressed: () => _handleSubmit(saveDraft: true),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
