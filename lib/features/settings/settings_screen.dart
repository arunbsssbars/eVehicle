import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/ad_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _enableGpsHighAccuracy = true;
  bool _enablePushNotifications = true;
  bool _enableOdometerPrompts = true;
  String _selectedLanguage = 'English (Official)';

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final currentUser = ref.watch(authProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Settings & Sync'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Offline First & Data Synchronization',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Offline Mode (Simulated)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Record journeys without active internet. Auto-queues for sync.',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: appState.isOffline,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          ref
                              .read(appStateProvider.notifier)
                              .toggleOfflineMode();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text(
                          'Pending Sync Queue',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${appState.pendingSyncCount} records waiting to be pushed to PostgreSQL.',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: ElevatedButton(
                          onPressed: appState.isOffline ||
                                  appState.pendingSyncCount == 0
                              ? null
                              : () => ref
                                  .read(appStateProvider.notifier)
                                  .triggerSync(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: const Size(60, 32),
                          ),
                          child: const Text('Sync Now',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Location & Odometer Rules',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'High-Accuracy GPS Tracking',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Record trajectory coordinates for audit cross-verification.',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _enableGpsHighAccuracy,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) =>
                            setState(() => _enableGpsHighAccuracy = val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'Odometer Rollback Warning Modal',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Warn before submitting readings lower than previous accepted KM.',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _enableOdometerPrompts,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) =>
                            setState(() => _enableOdometerPrompts = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Notifications & Preferences',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Push Alerts & Expiry Reminders',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Receive reminders for pending approvals & vehicle document renewals.',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _enablePushNotifications,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) =>
                            setState(() => _enablePushNotifications = val),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text(
                          'Language / भाषा',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        trailing: Text(
                          _selectedLanguage,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedLanguage = _selectedLanguage.contains('English')
                                ? 'हिन्दी (Hindi)'
                                : 'English (Official)';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Subscription & Monetization Section
              const Text(
                'Subscription & Billing Plans',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: currentUser?.isProTier == true
                              ? Colors.deepPurple.withValues(alpha: 0.12)
                              : (currentUser?.isEnterpriseTier == true
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : Colors.amber.withValues(alpha: 0.15)),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            color: currentUser?.isProTier == true
                                ? Colors.deepPurple
                                : (currentUser?.isEnterpriseTier == true
                                    ? AppColors.primary
                                    : Colors.amber.shade900),
                          ),
                        ),
                        title: const Text(
                          'Active Plan',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          currentUser?.effectiveTier.label ?? 'Free Starter',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentUser?.isProTier == true
                                ? Colors.deepPurple
                                : (currentUser?.isEnterpriseTier == true
                                    ? AppColors.primary
                                    : Colors.amber.shade800),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentUser?.effectiveTier.label
                                    .toUpperCase()
                                    .split(' ')
                                    .first ??
                                'FREE',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.secondaryContainer,
                          child: Icon(Icons.price_change_outlined,
                              color: AppColors.primary),
                        ),
                        title: const Text(
                          'View All Pricing Plans',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Explore Free vs Pro (\$2.99) vs Enterprise Fleet features.',
                          style: TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/plans'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Compliance & About Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'eVehicle LogBook v1.0.0 (Enterprise)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Official Digital Vehicle Journey & Log Book Management System.\nFully compliant with government vehicle audit regulations.',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Non-intrusive sponsor banner for Free Tier
              const AdBannerWidget(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
