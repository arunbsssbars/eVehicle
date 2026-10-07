import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/vehicle.dart';
import '../../core/models/journey.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/gps_tracking_service.dart';

class StartJourneyScreen extends ConsumerStatefulWidget {
  const StartJourneyScreen({super.key});

  @override
  ConsumerState<StartJourneyScreen> createState() =>
      _StartJourneyScreenState();
}

class _StartJourneyScreenState extends ConsumerState<StartJourneyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Core
  Vehicle? _selectedVehicle;
  TripCategory _tripCategory = TripCategory.business;
  final _driverCtrl = TextEditingController();
  String get _driverName => _driverCtrl.text.trim();
  double _openingOdometer = 0.0;
  final _odometerCtrl = TextEditingController();
  final _startLocCtrl = TextEditingController();
  String _purpose = '';
  final _purposeCtrl = TextEditingController();

  // GPS
  bool _useGps = true;
  double _startLat = 28.5726;
  double _startLng = 77.3243;

  // Additional (hidden by default)
  bool _showAdditional = false;
  bool _isSubordinate = false;
  final _accompCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _subNameCtrl = TextEditingController();
  final _subDesigCtrl = TextEditingController(text: 'Assistant Engineer');

  bool _isLoading = false;

  // Preset purposes (loaded from prefs)
  final List<String> _presets = [
    'Site Inspection',
    'Official Meeting / Headquarters',
    'Court Hearing & Legal Duty',
    'Field Survey & Assessment',
    'VIP / Dignitary Escort',
    'Emergency Response',
    'Administrative Duty',
  ];

  @override
  void initState() {
    super.initState();
    _loadPresets();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupDefaults());
  }

  void _setupDefaults() {
    final vehicles = ref.read(vehicleProvider).vehicles;
    final user = ref.read(authProvider).currentUser;

    if (vehicles.isNotEmpty) {
      _selectedVehicle = vehicles.first;
      _openingOdometer = _selectedVehicle!.currentOdometer;
      _driverCtrl.text = _selectedVehicle!.assignedDriverName;
      _odometerCtrl.text = _openingOdometer.toStringAsFixed(1);
    }

    if (user != null) {
      _subNameCtrl.text = user.name;
      _subDesigCtrl.text = user.designation;
    }

    // Auto-detect GPS start location via actual GPS hardware / browser
    _fetchGpsLocation();
  }

  Future<void> _fetchGpsLocation() async {
    final loc = await GpsTrackingService.instance.detectCurrentLocationAsync();
    _startLat = loc.latitude;
    _startLng = loc.longitude;
    final name = await GpsTrackingService.reverseGeocodeOnline(
      latitude: _startLat,
      longitude: _startLng,
    );
    if (mounted) {
      setState(() {
        _startLocCtrl.text = name;
      });
    }
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('journey_purpose_presets') ?? [];
    if (saved.isNotEmpty) {
      setState(() {
        for (final s in saved) {
          if (!_presets.contains(s)) _presets.add(s);
        }
      });
    }
  }

  Future<void> _saveNewPreset(String preset) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_presets.contains(preset)) {
      _presets.add(preset);
      await prefs.setStringList('journey_purpose_presets', _presets);
    }
  }

  @override
  void dispose() {
    _driverCtrl.dispose();
    _odometerCtrl.dispose();
    _startLocCtrl.dispose();
    _purposeCtrl.dispose();
    _accompCtrl.dispose();
    _remarksCtrl.dispose();
    _subNameCtrl.dispose();
    _subDesigCtrl.dispose();
    super.dispose();
  }

  void _onVehicleChanged(Vehicle v) {
    setState(() {
      _selectedVehicle = v;
      _openingOdometer = v.currentOdometer;
      _driverCtrl.text = v.assignedDriverName;
      _odometerCtrl.text = _openingOdometer.toStringAsFixed(1);
    });
  }

  Future<void> _refreshGps() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 10),
          Text('Acquiring real-time GPS signal...'),
        ],
      ),
      backgroundColor: AppColors.secondary,
      duration: Duration(seconds: 2),
    ));

    final loc = await GpsTrackingService.instance.detectCurrentLocationAsync();
    _startLat = loc.latitude;
    _startLng = loc.longitude;
    final name = await GpsTrackingService.reverseGeocodeOnline(
      latitude: _startLat,
      longitude: _startLng,
    );
    if (mounted) {
      setState(() => _startLocCtrl.text = name);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📍 Real GPS Location: $name (${_startLat.toStringAsFixed(4)}°, ${_startLng.toStringAsFixed(4)}°)'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Future<void> _handleStart() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedVehicle == null) return;
    if (_purpose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select or enter a purpose of travel.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    // Odometer rollback warning
    final odo = double.tryParse(_odometerCtrl.text) ?? _openingOdometer;
    if (odo < _selectedVehicle!.currentOdometer) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Odometer Warning', style: TextStyle(fontSize: 16)),
          ]),
          content: Text(
            'Entered reading (${odo.toStringAsFixed(1)} KM) is lower than '
            'last recorded (${_selectedVehicle!.currentOdometer.toStringAsFixed(1)} KM). Continue?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      if (_useGps) {
        GpsTrackingService.instance.startTracking(
          initialLat: _startLat,
          initialLng: _startLng,
        );
      }

      final user = ref.read(authProvider).currentUser;
      final officerName = _isSubordinate
          ? _subNameCtrl.text.trim()
          : (user?.name ?? 'Dr. S. K. Verma');
      final officerDesig = _isSubordinate
          ? _subDesigCtrl.text.trim()
          : (user?.designation ?? 'Executive Engineer');

      await ref.read(journeyProvider.notifier).startJourney(
            vehicle: _selectedVehicle!,
            driverId: 'DRV-001',
            driverName: _driverName,
            startLocation: _startLocCtrl.text.trim(),
            purpose: _purpose,
            openingOdometer: odo,
            tripCategory: _tripCategory,
            startLat: _useGps ? _startLat : null,
            startLng: _useGps ? _startLng : null,
            accompanyingOfficers: _accompCtrl.text.trim().isNotEmpty
                ? _accompCtrl.text.trim()
                : null,
            remarks: _remarksCtrl.text.trim().isNotEmpty
                ? _remarksCtrl.text.trim()
                : null,
            userOfficerName: officerName,
            userOfficerDesignation: officerDesig,
            isSubordinateJourney: _isSubordinate,
          );

      setState(() => _isLoading = false);
      if (mounted) context.pushReplacement('/journeys/active');
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider).vehicles;
    final uniqueVehicles = <String, Vehicle>{};
    for (final v in vehicles) { uniqueVehicles[v.id] = v; }
    final vList = uniqueVehicles.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Start Journey',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ── SECTION 1: Vehicle ──────────────────────────────────
            _sectionLabel('🚗  Vehicle & Driver'),
            const SizedBox(height: 8),
            _vehicleCard(vList),
            const SizedBox(height: 20),

            // ── SECTION 2: Opening Odometer ─────────────────────────
            _sectionLabel('🔢  Opening Odometer Reading'),
            const SizedBox(height: 8),
            _odometerCard(),
            const SizedBox(height: 20),

            // ── SECTION 3: Start Location ───────────────────────────
            _sectionLabel('📍  Starting Location'),
            const SizedBox(height: 8),
            _locationCard(),
            const SizedBox(height: 20),

            // ── SECTION 4: Purpose ──────────────────────────────────
            _sectionLabel('📋  Purpose of Travel *'),
            const SizedBox(height: 8),
            _purposeSection(),
            const SizedBox(height: 20),

            // ── SECTION 5: Trip Classification ──────────────────────
            _sectionLabel('🏷️  Trip Classification'),
            const SizedBox(height: 8),
            _categorySection(),
            const SizedBox(height: 20),

            // ── SECTION 6: Additional Info (collapsible) ────────────
            _additionalInfoToggle(),
            if (_showAdditional) ...[
              const SizedBox(height: 12),
              _additionalInfoSection(),
            ],
            const SizedBox(height: 28),

            // ── CTA ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleStart,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(Icons.navigation_rounded),
                label: Text(
                  _isLoading ? 'Starting...' : 'Start Journey Now',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ──
  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
            letterSpacing: 0.3));
  }

  // ── White card wrapper ──
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  // ── Vehicle & Driver card ──
  Widget _vehicleCard(List<Vehicle> vList) {
    if (vList.isEmpty) {
      return _card(const Text('No vehicles assigned.',
          style: TextStyle(color: AppColors.secondary, fontSize: 13)));
    }

    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle selector as chips
        if (vList.length == 1)
          Row(children: [
            const Icon(Icons.directions_car_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${vList.first.registrationNumber} — ${vList.first.make} ${vList.first.model}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ])
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Vehicle',
                  style: TextStyle(fontSize: 12, color: AppColors.secondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: vList.map((v) {
                  final sel = _selectedVehicle?.id == v.id;
                  return GestureDetector(
                    onTap: () => _onVehicleChanged(v),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color:
                            sel ? AppColors.primary : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sel
                                ? AppColors.primary
                                : const Color(0xFFCBD5E1)),
                      ),
                      child: Text(v.registrationNumber,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : AppColors.onSurface)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),

        // Driver name
        Row(children: [
          const Icon(Icons.person_outline, size: 17, color: AppColors.secondary),
          const SizedBox(width: 6),
          const Text('Driver: ',
              style: TextStyle(fontSize: 12, color: AppColors.secondary)),
          Expanded(
            child: TextFormField(
              controller: _driverCtrl,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ]),
      ],
    ));
  }

  // ── Odometer card ──
  Widget _odometerCard() {
    final lastRecorded = _selectedVehicle?.currentOdometer ?? _openingOdometer;
    return _card(Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last recorded',
                  style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  lastRecorded > 0 ? '${lastRecorded.toStringAsFixed(1)} KM' : '— KM',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.secondary),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Opening reading *',
                  style:
                      TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              TextFormField(
                controller: _odometerCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  suffixText: 'KM',
                  suffixStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid';
                  return null;
                },
                onChanged: (v) {
                  final d = double.tryParse(v);
                  if (d != null) _openingOdometer = d;
                },
              ),
            ],
          ),
        ),
      ],
    ));
  }

  // ── Location card ──
  Widget _locationCard() {
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GPS toggle row
        Row(children: [
          Icon(Icons.gps_fixed,
              size: 17,
              color: _useGps ? AppColors.success : AppColors.secondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _useGps ? 'GPS Tracking Active' : 'GPS Off',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _useGps
                      ? const Color(0xFF15803D)
                      : AppColors.secondary),
            ),
          ),
          if (_useGps)
            TextButton.icon(
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(60, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: const Icon(Icons.refresh_rounded,
                  size: 14, color: AppColors.primary),
              label: const Text('Detect',
                  style: TextStyle(fontSize: 11, color: AppColors.primary)),
              onPressed: _refreshGps,
            ),
          Switch.adaptive(
            value: _useGps,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) {
              setState(() => _useGps = v);
              if (v) _refreshGps();
            },
          ),
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: _startLocCtrl,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Starting Location *',
            prefixIcon: const Icon(Icons.trip_origin,
                size: 18, color: AppColors.primary),
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Enter starting location' : null,
        ),
      ],
    ));
  }

  // ── Purpose section with Search & Dropdown & Manual Input ──
  Widget _purposeSection() {
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Searchable Autocomplete Dropdown / Text Field
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _purpose),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _presets;
            }
            return _presets.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            setState(() {
              _purpose = selection;
              _purposeCtrl.text = selection;
            });
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            // Keep controller text synced if modified from outside
            if (_purposeCtrl.text != textEditingController.text &&
                _purpose.isNotEmpty &&
                textEditingController.text.isEmpty) {
              textEditingController.text = _purpose;
            }
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Select or Type Travel Purpose *',
                hintText: 'Search or enter purpose...',
                prefixIcon: const Icon(Icons.travel_explore_rounded,
                    size: 18, color: AppColors.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (textEditingController.text.trim().isNotEmpty &&
                        !_presets.contains(textEditingController.text.trim()))
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            size: 20, color: AppColors.primary),
                        tooltip: 'Save to Preset List',
                        onPressed: () async {
                          final newP = textEditingController.text.trim();
                          if (newP.isNotEmpty) {
                            await _saveNewPreset(newP);
                            setState(() => _purpose = newP);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added "$newP" to purpose list!'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    const Icon(Icons.arrow_drop_down,
                        color: AppColors.secondary),
                    const SizedBox(width: 4),
                  ],
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) {
                setState(() => _purpose = v.trim());
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: MediaQuery.of(context).size.width - 60,
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      final isSelected = _purpose == option;
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          color: isSelected
                              ? AppColors.primaryFixed.withValues(alpha: 0.5)
                              : null,
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 14,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ));
  }

  // ── Trip Category selector ──
  Widget _categorySection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorize this journey for tax deduction & fleet log reporting:',
            style: TextStyle(fontSize: 12, color: AppColors.secondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final cat in TripCategory.values) ...[
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _tripCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _tripCategory == cat
                            ? AppColors.primary
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _tripCategory == cat
                              ? AppColors.primary
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            cat == TripCategory.business
                                ? Icons.business_center_rounded
                                : cat == TripCategory.personal
                                    ? Icons.person_rounded
                                    : Icons.directions_bus_rounded,
                            size: 18,
                            color: _tripCategory == cat
                                ? Colors.white
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _tripCategory == cat
                                  ? Colors.white
                                  : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (cat != TripCategory.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Additional info toggle ──
  Widget _additionalInfoToggle() {
    return InkWell(
      onTap: () => setState(() => _showAdditional = !_showAdditional),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _showAdditional
                ? AppColors.primary.withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(children: [
          Icon(
            _showAdditional
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Additional Information',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface)),
                Text(
                  'Accompanying staff, remarks, subordinate officer details',
                  style: TextStyle(fontSize: 11, color: AppColors.secondary),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _showAdditional ? 'Hide' : 'Show',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Additional info section ──
  Widget _additionalInfoSection() {
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accompanying officers
        TextFormField(
          controller: _accompCtrl,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Accompanying Staff (Optional)',
            hintText: 'e.g. A. K. Gupta (AE), R. S. Negi (JE)',
            prefixIcon: Icon(Icons.group_outlined, size: 18),
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Remarks
        TextFormField(
          controller: _remarksCtrl,
          maxLines: 2,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Remarks (Optional)',
            hintText: 'Any specific instructions or notes',
            prefixIcon: Icon(Icons.notes_outlined, size: 18),
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),

        // Subordinate usage toggle
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.badge_outlined,
              size: 17, color: AppColors.secondary),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subordinate / Other Officer using vehicle?',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                Text('Toggle if someone other than dedicated officer is travelling',
                    style:
                        TextStyle(fontSize: 10, color: AppColors.secondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isSubordinate,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => setState(() => _isSubordinate = v),
          ),
        ]),

        if (_isSubordinate) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _subNameCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Officer Name *',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _isSubordinate && (v == null || v.isEmpty)
                    ? 'Required'
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _subDesigCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Designation *',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _isSubordinate && (v == null || v.isEmpty)
                    ? 'Required'
                    : null,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          // Quick subordinate presets
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _subChip('Er. A. K. Gupta', 'Assistant Engineer'),
              _subChip('Er. R. S. Negi', 'Junior Engineer'),
              _subChip('P. Verma', 'Surveyor'),
            ],
          ),
        ],
      ],
    ));
  }

  Widget _subChip(String name, String desig) {
    return ActionChip(
      label: Text('$name ($desig)',
          style: const TextStyle(fontSize: 10)),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFCBD5E1)),
      onPressed: () => setState(() {
        _subNameCtrl.text = name;
        _subDesigCtrl.text = desig;
      }),
    );
  }
}

