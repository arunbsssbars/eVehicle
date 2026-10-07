import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/organization.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/saas_entitlement_service.dart';
import '../../core/storage/local_database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/quota_usage_meter_card.dart';

/// Full-featured SaaS Workspace Billing, Plan Quotas, and Invoices Portal.
class TenantBillingScreen extends ConsumerStatefulWidget {
  const TenantBillingScreen({super.key});

  @override
  ConsumerState<TenantBillingScreen> createState() => _TenantBillingScreenState();
}

class _TenantBillingScreenState extends ConsumerState<TenantBillingScreen> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final orgId = user?.organizationId ?? 'ORG-PWD-01';

    final org = LocalDatabase.instance.getOrganizationById(orgId) ??
        LocalDatabase.instance.organizations.first;

    final vehiclesCount = LocalDatabase.instance.vehicles.length;
    final journeysCount = LocalDatabase.instance.journeys.length;

    const entitlementService = SaasEntitlementService();
    final quotaSummary = entitlementService.getQuotaUsage(
      organization: org,
      vehicleCount: vehiclesCount,
      monthlyJourneyCount: journeysCount,
    );

    final currencySymbol = org.settings.currencySymbol;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          'Workspace Billing & Plans',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quota Meter Card
                      QuotaUsageMeterCard(
                        organization: org,
                        quotaSummary: quotaSummary,
                        onUpgradeTapped: () => context.push('/plans'),
                      ),
                      const SizedBox(height: 20),

                      // Current Plan Details Card
                      _buildCurrentPlanDetailsCard(org, currencySymbol),
                      const SizedBox(height: 20),

                      // Payment Method Card
                      _buildPaymentMethodCard(),
                      const SizedBox(height: 20),

                      // Billing Invoices Table
                      _buildInvoicesCard(dateFormat, currencySymbol),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanDetailsCard(Organization org, String currencySymbol) {
    final tier = org.subscriptionTier;
    final priceLabel = tier == SubscriptionTier.enterprise
        ? '$currencySymbol 2,499 / mo'
        : (tier == SubscriptionTier.pro ? '$currencySymbol 249 / mo' : 'Free Forever');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Plan Tier',
                    style: TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tier.label,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                  ),
                ],
              ),
              Text(
                priceLabel,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailTile('Status', org.status.label, AppColors.success),
              ),
              Expanded(
                child: _buildDetailTile('Billing Cycle', 'Monthly Auto-Renew', AppColors.onSurface),
              ),
              Expanded(
                child: _buildDetailTile('Renewal Date', '01 Nov 2026', AppColors.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/plans'),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Change Subscription Plan', style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Primary Payment Method',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Corporate Visa Card ending in •••• 4242',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Expires 12/28 • Default Payment Method',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment gateway configuration is active.')),
                  );
                },
                child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesCard(DateFormat dateFormat, String currencySymbol) {
    final mockInvoices = [
      {'id': 'INV-2026-10-01', 'date': '01 Oct 2026', 'amount': '$currencySymbol 2,499', 'status': 'PAID'},
      {'id': 'INV-2026-09-01', 'date': '01 Sep 2026', 'amount': '$currencySymbol 2,499', 'status': 'PAID'},
      {'id': 'INV-2026-08-01', 'date': '01 Aug 2026', 'amount': '$currencySymbol 2,499', 'status': 'PAID'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Billing Invoices & Receipts',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockInvoices.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final inv = mockInvoices[index];
              return Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv['id']!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          inv['date']!,
                          style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    inv['amount']!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      inv['status']!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloaded ${inv['id']} receipt.')),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
