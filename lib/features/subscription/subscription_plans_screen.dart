import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/organization.dart';
import '../../core/providers/auth_provider.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState
    extends ConsumerState<SubscriptionPlansScreen> {
  bool _isAnnual = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final currentTier = user?.effectiveTier ?? SubscriptionTier.free;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          'Subscription & Pricing Plans',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.marginMobile),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          size: 14, color: Colors.deepPurple),
                      SizedBox(width: 4),
                      Text(
                        'TRANSPARENT PRICING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.deepPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scale from Individual to Fleet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Start free with sponsor-ad unlocks. Upgrade anytime for unlimited vehicles, team collaboration, and automated audit logs.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Billing Cycle Toggle (Monthly vs Annual -20%)
                Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildToggleOption(
                          title: 'Monthly',
                          isSelected: !_isAnnual,
                          onTap: () => setState(() => _isAnnual = false),
                        ),
                      ),
                      Expanded(
                        child: _buildToggleOption(
                          title: 'Annual (Save 20%)',
                          isSelected: _isAnnual,
                          onTap: () => setState(() => _isAnnual = true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Pricing Cards: Side-by-Side on Desktop, Vertical Stack on Mobile
                Builder(
                  builder: (context) {
                    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
                    if (isDesktop) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildFreeCard(context, currentTier)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildProCard(context, currentTier)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildEnterpriseCard(context, currentTier)),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        _buildFreeCard(context, currentTier),
                        const SizedBox(height: 16),
                        _buildProCard(context, currentTier),
                        const SizedBox(height: 16),
                        _buildEnterpriseCard(context, currentTier),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // FAQ Section
                _buildFaqSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeCard(BuildContext context, SubscriptionTier currentTier) {
    return _buildPlanCard(
      context,
      tier: SubscriptionTier.free,
      isCurrentPlan: currentTier == SubscriptionTier.free,
      title: 'Free Starter',
      subtitle: 'For individual drivers testing the app',
      priceText: '\$0',
      periodText: '/ forever',
      accentColor: AppColors.primary,
      features: const [
        'Up to 2 Active Vehicles',
        '50 Journeys per month',
        'Standard GPS & manual odometer logging',
        'Standard PDF & CSV register exports (Ad-supported)',
        '100% Offline logging support',
      ],
      buttonLabel: currentTier == SubscriptionTier.free
          ? 'Current Plan'
          : 'Downgrade to Free',
      isButtonActive: currentTier != SubscriptionTier.free,
      onButtonTap: () => _handleTierChange(SubscriptionTier.free),
    );
  }

  Widget _buildProCard(BuildContext context, SubscriptionTier currentTier) {
    return _buildPlanCard(
      context,
      tier: SubscriptionTier.pro,
      isCurrentPlan: currentTier == SubscriptionTier.pro,
      badge: 'MOST POPULAR',
      badgeColor: Colors.deepPurple,
      title: 'Pro Individual',
      subtitle: 'For power drivers, consultants & small owners',
      priceText: _isAnnual ? '\$24.99' : '\$2.99',
      periodText: _isAnnual ? '/ year' : '/ month',
      subPriceNote: _isAnnual ? '(approx. \$2.08/mo)' : null,
      accentColor: Colors.deepPurple,
      features: const [
        'Unlimited Vehicles & Journeys',
        '100% Ad-Free Experience',
        'Instant Official PDF & CSV Exports (No ads)',
        'Tax & Expense mileage audit summaries',
        'Priority Cloud Backup & Multi-device Sync',
        'Customizable Logbook columns & signatories',
      ],
      buttonLabel: currentTier == SubscriptionTier.pro
          ? 'Current Plan'
          : 'Activate Pro Plan (Test Mode)',
      isButtonActive: currentTier != SubscriptionTier.pro,
      onButtonTap: () => _handleTierChange(SubscriptionTier.pro),
    );
  }

  Widget _buildEnterpriseCard(BuildContext context, SubscriptionTier currentTier) {
    return _buildPlanCard(
      context,
      tier: SubscriptionTier.enterprise,
      isCurrentPlan: currentTier == SubscriptionTier.enterprise,
      badge: 'ORGANIZATION & FLEET',
      badgeColor: AppColors.primary,
      title: 'Enterprise Fleet',
      subtitle: 'For companies, logistics & government contractors',
      priceText: _isAnnual ? '\$34.99' : '\$3.99',
      periodText: _isAnnual ? '/ vehicle / yr' : '/ vehicle / mo',
      subPriceNote: 'Billed per active vehicle',
      accentColor: AppColors.primary,
      features: const [
        'Multi-Tenant Roles (Admin, Approvers, Drivers)',
        'Centralized Company Admin Console & Join Codes',
        'Digital Signatures & Multi-Level Approvals',
        'Automated Compliance & Fraud/Rollback Flags',
        'Custom Organization Logo & Header on PDFs',
        'Bulk Monthly Fleet Excel & Government Audits',
        'Dedicated 24/7 Priority Support',
      ],
      buttonLabel: currentTier == SubscriptionTier.enterprise
          ? 'Current Plan'
          : 'Activate Enterprise (Test Mode)',
      isButtonActive: currentTier != SubscriptionTier.enterprise,
      onButtonTap: () => _handleTierChange(SubscriptionTier.enterprise),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.onSurface : AppColors.secondary,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required SubscriptionTier tier,
    required bool isCurrentPlan,
    String? badge,
    Color? badgeColor,
    required String title,
    required String subtitle,
    required String priceText,
    required String periodText,
    String? subPriceNote,
    required Color accentColor,
    required List<String> features,
    required String buttonLabel,
    required bool isButtonActive,
    required VoidCallback onButtonTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isCurrentPlan
              ? accentColor
              : (badge != null ? accentColor.withValues(alpha: 0.5) : AppColors.borderSubtle),
          width: isCurrentPlan || badge != null ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (badge != null ? accentColor : Colors.black).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null) const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentPlan)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 12, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pricing Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      priceText,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        periodText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (subPriceNote != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subPriceNote,
                    style: TextStyle(
                      fontSize: 11,
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const Divider(height: 24, thickness: 1, color: AppColors.surfaceContainerLow),

                // Features list
                for (final feat in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feat,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.onSurface,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: isButtonActive ? onButtonTap : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Badge (e.g. MOST POPULAR)
          if (badge != null)
            Positioned(
              top: -10,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor ?? accentColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (badgeColor ?? accentColor).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _buildFaqItem(
          'Can I switch or cancel plans anytime?',
          'Yes! You can upgrade, downgrade, or switch between monthly and annual plans at any point with zero penalties.',
        ),
        _buildFaqItem(
          'How does the Free Plan ad-supported export work?',
          'Free users can record journeys and vehicles 100% free forever. When generating formal PDF or CSV audit registers, watching a 5-second sponsor ad grants immediate export access.',
        ),
        _buildFaqItem(
          'How does Enterprise Join Code work?',
          'Company Admins receive a 6-digit Join Code. Drivers and staff simply enter this code upon signup to automatically join the company fleet with assigned permissions.',
        ),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.secondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTierChange(SubscriptionTier newTier) async {
    final success = await ref
        .read(authProvider.notifier)
        .upgradeSubscriptionTier(newTier);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plan updated to ${newTier.label} successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    }
  }
}
