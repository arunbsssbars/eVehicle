import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/saas_api_client.dart';
import '../../core/storage/local_database.dart';
import '../../core/theme/app_colors.dart';

/// Screen allowing Tenant Admins to customize white-label branding, currency, and distance metrics.
class TenantSettingsScreen extends ConsumerStatefulWidget {
  const TenantSettingsScreen({super.key});

  @override
  ConsumerState<TenantSettingsScreen> createState() => _TenantSettingsScreenState();
}

class _TenantSettingsScreenState extends ConsumerState<TenantSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _taxIdController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactMobileController;

  late String _currencyCode;
  late String _distanceUnit;
  late bool _driverSelfApproval;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    final orgId = user?.organizationId ?? 'ORG-PWD-01';
    final org = LocalDatabase.instance.getOrganizationById(orgId) ??
        LocalDatabase.instance.organizations.first;

    _nameController = TextEditingController(text: org.name);
    _taxIdController = TextEditingController(text: org.taxId ?? org.settings.taxId ?? '');
    _contactEmailController = TextEditingController(text: org.contactEmail);
    _contactMobileController = TextEditingController(text: org.contactMobile);

    _currencyCode = org.settings.currencyCode;
    _distanceUnit = org.settings.distanceUnit;
    _driverSelfApproval = org.settings.enableDriverSelfApproval;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _contactEmailController.dispose();
    _contactMobileController.dispose();
    super.dispose();
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
      default:
        return '₹';
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final user = ref.read(authProvider).currentUser;
    final orgId = user?.organizationId ?? 'ORG-PWD-01';
    final org = LocalDatabase.instance.getOrganizationById(orgId) ??
        LocalDatabase.instance.organizations.first;

    final updatedSettings = org.settings.copyWith(
      currencyCode: _currencyCode,
      currencySymbol: _getCurrencySymbol(_currencyCode),
      distanceUnit: _distanceUnit,
      taxId: _taxIdController.text.trim().isEmpty ? null : _taxIdController.text.trim(),
      enableDriverSelfApproval: _driverSelfApproval,
    );

    final updatedOrg = org.copyWith(
      name: _nameController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      contactMobile: _contactMobileController.text.trim(),
      taxId: _taxIdController.text.trim().isEmpty ? null : _taxIdController.text.trim(),
      settings: updatedSettings,
    );

    await LocalDatabase.instance.updateOrganization(updatedOrg);
    final client = SaasApiClient();
    await client.updateTenantSettings(updatedSettings);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workspace preferences updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final orgId = user?.organizationId ?? 'ORG-PWD-01';
    final org = LocalDatabase.instance.getOrganizationById(orgId) ??
        LocalDatabase.instance.organizations.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          'Workspace & Tenant Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workspace Header Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              org.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tenant ID: ${org.id} • Join Code: ${org.code}',
                              style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          org.subscriptionTier.label.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 1: Regional & Units Configuration
                const Text(
                  'Regional & Measurement Units',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      // Currency Selector
                      DropdownButtonFormField<String>(
                        initialValue: _currencyCode,
                        decoration: const InputDecoration(
                          labelText: 'Operational Currency',
                          prefixIcon: Icon(Icons.payments_rounded, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'INR', child: Text('Indian Rupee (INR - ₹)')),
                          DropdownMenuItem(value: 'USD', child: Text('US Dollar (USD - \$)')),
                          DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR - €)')),
                          DropdownMenuItem(value: 'GBP', child: Text('British Pound (GBP - £)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _currencyCode = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Distance Unit Selector
                      DropdownButtonFormField<String>(
                        initialValue: _distanceUnit,
                        decoration: const InputDecoration(
                          labelText: 'Odometer & Distance Units',
                          prefixIcon: Icon(Icons.speed_rounded, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'km', child: Text('Metric (Kilometers - km)')),
                          DropdownMenuItem(value: 'mi', child: Text('Imperial (Miles - mi)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _distanceUnit = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 2: Organization Profile
                const Text(
                  'Organization Profile & Tax Identity',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Company / Department Legal Name',
                          prefixIcon: Icon(Icons.badge_rounded, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _taxIdController,
                        decoration: const InputDecoration(
                          labelText: 'Tax Registration Number / GSTIN / VAT',
                          prefixIcon: Icon(Icons.receipt_rounded, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _contactEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Workspace Contact Email',
                          prefixIcon: Icon(Icons.email_rounded, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _contactMobileController,
                        decoration: const InputDecoration(
                          labelText: 'Fleet Support Mobile',
                          prefixIcon: Icon(Icons.phone_rounded, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 3: Workflow Policy
                const Text(
                  'Trip Governance & Approval Policy',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: SwitchListTile(
                    title: const Text('Allow Driver Self-Approval', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: const Text('Drivers can self-authorize standard operational trips without officer approval', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                    value: _driverSelfApproval,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _driverSelfApproval = val),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Changes Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      _isSaving ? 'Saving Changes...' : 'Save Workspace Preferences',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
