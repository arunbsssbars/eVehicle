import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/storage/local_database.dart';
import '../../core/models/organization.dart';
import '../../core/services/fraud_detection_service.dart';

class SuperAdminScreen extends ConsumerStatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  ConsumerState<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends ConsumerState<SuperAdminScreen> {
  @override
  Widget build(BuildContext context) {
    final orgs = LocalDatabase.instance.organizations;
    final allUsers = LocalDatabase.instance.users;
    final allVehicles = LocalDatabase.instance.vehicles;
    final allJourneys = LocalDatabase.instance.journeys;
    final fraudAlerts = FraudDetectionService.instance.scanJourneys(allJourneys);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          'Super Admin Console',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, size: 14, color: AppColors.error),
                SizedBox(width: 4),
                Text(
                  'SUPER ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Global Platform Metrics Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.public, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Global Platform Telemetry',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildMetricBox(
                        'Organizations',
                        '${orgs.length}',
                        Icons.business_rounded,
                        Colors.blueAccent,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricBox(
                        'Fleet Vehicles',
                        '${allVehicles.length}',
                        Icons.directions_car_rounded,
                        Colors.tealAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMetricBox(
                        'Total Trips',
                        '${allJourneys.length}',
                        Icons.route_rounded,
                        Colors.amberAccent,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricBox(
                        'Active Users',
                        '${allUsers.length}',
                        Icons.people_alt_rounded,
                        Colors.purpleAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Monetization & Growth Status Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.monetization_on_outlined, color: AppColors.success, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phase 1: Free Viral Growth Mode Active',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'All companies currently have 100% free access to build user adoption. Freemium and AdMob monetization gates are ready for Phase 2.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Fraud & Anomaly Detection Center
            _buildFraudDetectionSection(context, fraudAlerts),
            const SizedBox(height: 24),

            // 4. Registered Organizations List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Registered Organizations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  '${orgs.length} Total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            for (final org in orgs) _buildOrgCard(context, org),

            const SizedBox(height: 20),

            // 4. Quick Actions
            const Text(
              'Super Admin Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              tileColor: AppColors.surfaceWhite,
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryFixed,
                child: Icon(Icons.domain_add_rounded, color: AppColors.primary),
              ),
              title: const Text(
                'Register New Organization',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Provision a dedicated company tenant with join code',
                style: TextStyle(fontSize: 11, color: AppColors.secondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showCreateOrgDialog(context),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              tileColor: AppColors.surfaceWhite,
              leading: CircleAvatar(
                backgroundColor: Colors.amber.withValues(alpha: 0.15),
                child: const Icon(Icons.campaign_rounded, color: Colors.amber),
              ),
              title: const Text(
                'Broadcast Announcement',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Push system alerts to all companies or specific tenants',
                style: TextStyle(fontSize: 11, color: AppColors.secondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showBroadcastDialog(context),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              tileColor: AppColors.surfaceWhite,
              leading: CircleAvatar(
                backgroundColor: Colors.purple.withValues(alpha: 0.15),
                child: const Icon(Icons.history_edu_rounded, color: Colors.purple),
              ),
              title: const Text(
                'Global System Audit Logs',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Searchable audit trail of all lifecycle, trip, and fleet changes',
                style: TextStyle(fontSize: 11, color: AppColors.secondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showAuditLogSheet(context),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              tileColor: AppColors.surfaceWhite,
              leading: CircleAvatar(
                backgroundColor: Colors.teal.withValues(alpha: 0.15),
                child: const Icon(Icons.cloud_download_rounded, color: Colors.teal),
              ),
              title: const Text(
                'Export Platform Data Backup',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Download full JSON backup of all organizations, trips, and fleets',
                style: TextStyle(fontSize: 11, color: AppColors.secondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showExportDataDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgCard(BuildContext context, Organization org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.apartment_rounded,
                            size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              org.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Admin: ${org.adminName}',
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Join Code Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.vpn_key_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            org.code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                    PopupMenuButton<String>(
                      tooltip: 'Organization Options',
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.secondary),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showEditOrgDialog(context, org);
                        } else if (val == 'regenerate') {
                          _showRegenerateCodeConfirm(context, org);
                        } else if (val == 'status') {
                          _showChangeStatusDialog(context, org);
                        } else if (val == 'tier') {
                          _showChangeTierDialog(context, org);
                        } else if (val == 'archive') {
                          _showArchiveOrgDialog(context, org);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Org Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'regenerate',
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('Regenerate Join Code'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Change Status'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'tier',
                          child: Row(
                            children: [
                              Icon(Icons.workspace_premium_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Change Plan Tier'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined, color: AppColors.error, size: 16),
                              SizedBox(width: 8),
                              Text('Archive / Delete Org', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 18, thickness: 1, color: AppColors.surfaceContainerLow),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car, size: 13, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${org.activeVehiclesCount} Vehicles',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.people, size: 13, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${org.activeMembersCount} Staff',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status Lifecycle Chip
                    InkWell(
                      onTap: () => _showChangeStatusDialog(context, org),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(org.status.colorValue).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Color(org.status.colorValue),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(org.status.colorValue),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              org.status.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w800,
                                color: Color(org.status.colorValue),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 14,
                              color: Color(org.status.colorValue),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Tier Chip
                    InkWell(
                      onTap: () => _showChangeTierDialog(context, org),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: org.subscriptionTier == SubscriptionTier.enterprise
                              ? Colors.deepPurple.withValues(alpha: 0.12)
                              : (org.subscriptionTier == SubscriptionTier.pro
                                  ? AppColors.primaryFixed
                                  : AppColors.successContainer),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: org.subscriptionTier == SubscriptionTier.enterprise
                                ? Colors.deepPurple
                                : (org.subscriptionTier == SubscriptionTier.pro
                                    ? AppColors.primary
                                    : AppColors.success),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              org.subscriptionTier.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w800,
                                color: org.subscriptionTier == SubscriptionTier.enterprise
                                    ? Colors.deepPurple
                                    : (org.subscriptionTier == SubscriptionTier.pro
                                        ? AppColors.primary
                                        : AppColors.success),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 14,
                              color: org.subscriptionTier == SubscriptionTier.enterprise
                                  ? Colors.deepPurple
                                  : (org.subscriptionTier == SubscriptionTier.pro
                                      ? AppColors.primary
                                      : AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOrgDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final adminCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.domain_add, color: AppColors.primary),
            SizedBox(width: 8),
            Text('New Organization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company / Organization Name',
                  hintText: 'e.g. Acme Transport Ltd',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: adminCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company Admin Name',
                  hintText: 'e.g. Ramesh Chandra',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Admin Email',
                  hintText: 'admin@acme.com',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Admin Mobile',
                  hintText: '+91 98765 00000',
                ),
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
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final newOrg = await LocalDatabase.instance.createOrganization(
                name: nameCtrl.text.trim(),
                adminId: 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                adminName: adminCtrl.text.trim().isNotEmpty ? adminCtrl.text.trim() : 'Company Admin',
                contactEmail: emailCtrl.text.trim(),
                contactMobile: mobileCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Created ${newOrg.name} with Join Code: ${newOrg.code}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Create & Generate Code'),
          ),
        ],
      ),
    );
  }

  void _showChangeTierDialog(BuildContext context, Organization org) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.deepPurple, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Change Tier: ${org.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the subscription tier for this organization. This immediately affects feature gating, vehicle quotas, and ad presence.',
              style: TextStyle(fontSize: 12, color: AppColors.secondary),
            ),
            const SizedBox(height: 14),
            for (final tier in SubscriptionTier.values)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: org.subscriptionTier == tier
                        ? AppColors.primary
                        : AppColors.borderSubtle,
                    width: org.subscriptionTier == tier ? 1.5 : 1.0,
                  ),
                  color: org.subscriptionTier == tier
                      ? AppColors.primaryFixed.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      org.subscriptionTier == tier
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: org.subscriptionTier == tier
                          ? AppColors.primary
                          : AppColors.secondary,
                      size: 18,
                    ),
                    title: Text(
                      tier.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: org.subscriptionTier == tier
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${tier.maxVehicles} Vehicles • ${tier.maxMonthlyJourneys} Monthly Journeys',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await LocalDatabase.instance
                          .updateOrganizationTier(org.id, tier);
                      setState(() {});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Updated ${org.name} tier to ${tier.label}!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudDetectionSection(BuildContext context, List<FraudAlert> alerts) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: alerts.isNotEmpty ? AppColors.error.withValues(alpha: 0.4) : AppColors.success.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                          color: alerts.isNotEmpty
                              ? AppColors.error.withValues(alpha: 0.12)
                              : AppColors.successContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          alerts.isNotEmpty
                              ? Icons.security_update_warning_rounded
                              : Icons.verified_user_rounded,
                          size: 20,
                          color: alerts.isNotEmpty ? AppColors.error : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fraud & Anomaly Detection Center',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              alerts.isNotEmpty
                                  ? '${alerts.length} Audit Anomalies Detected'
                                  : 'All Fleets Clean (0 Rollbacks / Variances)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: alerts.isNotEmpty ? AppColors.error : AppColors.success,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: alerts.isNotEmpty
                        ? AppColors.error.withValues(alpha: 0.12)
                        : AppColors.successContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    alerts.isNotEmpty ? 'ATTENTION' : 'COMPLIANT',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: alerts.isNotEmpty ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.surfaceContainerLow),
              const SizedBox(height: 10),
              for (final alert in alerts)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(alert.type.colorValue).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(alert.type.colorValue).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        alert.severity == AnomalySeverity.critical
                            ? Icons.error_rounded
                            : Icons.warning_amber_rounded,
                        color: Color(alert.type.colorValue),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(alert.type.colorValue),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${alert.vehicleRegistration} • Driver: ${alert.driverName}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.description,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showFraudAlertDetailsDialog(context, alert),
                        child: const Text('Review', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChangeStatusDialog(BuildContext context, Organization org) {
    final reasonCtrl = TextEditingController(text: org.statusReason ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(org.status.colorValue), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lifecycle: ${org.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set organization operational status. Suspending an organization halts driver journey submissions until reinstated.',
              style: TextStyle(fontSize: 12, color: AppColors.secondary),
            ),
            const SizedBox(height: 14),
            for (final status in OrganizationStatus.values)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: org.status == status ? Color(status.colorValue) : AppColors.borderSubtle,
                    width: org.status == status ? 1.5 : 1.0,
                  ),
                  color: org.status == status
                      ? Color(status.colorValue).withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      org.status == status ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: Color(status.colorValue),
                      size: 18,
                    ),
                    title: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: org.status == status ? FontWeight.w700 : FontWeight.w500,
                        color: Color(status.colorValue),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await LocalDatabase.instance.updateOrganizationStatus(
                        org.id,
                        status,
                        reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
                      );
                      setState(() {});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated ${org.name} status to ${status.label}!'),
                            backgroundColor: Color(status.colorValue),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Lifecycle Reason / Note (Optional)',
                hintText: 'e.g. KYC Verified, Billing Overdue, etc.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFraudAlertDetailsDialog(BuildContext context, FraudAlert alert) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(alert.type.colorValue)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alert.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Trip ID', alert.journeyId),
            _buildDetailRow('Vehicle', alert.vehicleRegistration),
            _buildDetailRow('Driver', alert.driverName),
            _buildDetailRow('Severity', alert.severity.label),
            const SizedBox(height: 10),
            const Text(
              'Audit Finding Details:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              alert.description,
              style: const TextStyle(fontSize: 12, color: AppColors.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Marked ${alert.journeyId} as reviewed with notice.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Mark Reviewed'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showEditOrgDialog(BuildContext context, Organization org) {
    final nameCtrl = TextEditingController(text: org.name);
    final adminCtrl = TextEditingController(text: org.adminName);
    final emailCtrl = TextEditingController(text: org.contactEmail);
    final mobileCtrl = TextEditingController(text: org.contactMobile);
    final taxIdCtrl = TextEditingController(text: org.taxId ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit ${org.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Organization Name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: adminCtrl,
                decoration: const InputDecoration(labelText: 'Admin In-Charge Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Contact Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mobileCtrl,
                decoration: const InputDecoration(labelText: 'Contact Mobile'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: taxIdCtrl,
                decoration: const InputDecoration(labelText: 'Tax ID / GSTIN (Optional)'),
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
            child: const Text('Save Details'),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final updated = org.copyWith(
                name: nameCtrl.text.trim(),
                adminName: adminCtrl.text.trim(),
                contactEmail: emailCtrl.text.trim(),
                contactMobile: mobileCtrl.text.trim(),
                taxId: taxIdCtrl.text.trim().isNotEmpty ? taxIdCtrl.text.trim() : null,
              );
              Navigator.pop(ctx);
              await LocalDatabase.instance.updateOrganization(updated);
              setState(() {});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Organization ${updated.name} updated successfully.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRegenerateCodeConfirm(BuildContext context, Organization org) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Regenerate Join Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to regenerate the join code for ${org.name}? The previous code (${org.code}) will be invalidated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            child: const Text('Regenerate Code'),
            onPressed: () async {
              Navigator.pop(ctx);
              final newCode = await LocalDatabase.instance.regenerateOrganizationCode(org.id);
              setState(() {});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New join code for ${org.name}: $newCode'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showArchiveOrgDialog(BuildContext context, Organization org) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.archive_outlined, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Archive ${org.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Archiving this organization will safely disconnect all ${org.activeMembersCount} enrolled staff back to individual personal accounts without deleting their past trip records.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason for Archival (Optional)',
                hintText: 'e.g. Contract ended, company dissolved',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Archive Organization'),
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalDatabase.instance.deleteOrganization(
                org.id,
                reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
              );
              setState(() {});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Organization ${org.name} archived and members unlinked.'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String? selectedOrgId;
    final orgs = LocalDatabase.instance.organizations;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text('Broadcast Announcement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: selectedOrgId,
                  decoration: const InputDecoration(labelText: 'Target Audience'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Users & Companies (Global)')),
                    for (final o in orgs)
                      DropdownMenuItem(value: o.id, child: Text(o.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    setDialogState(() => selectedOrgId = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Title *',
                    hintText: 'e.g. Scheduled System Maintenance',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Broadcast Message *',
                    hintText: 'Enter details of the announcement...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Broadcast Now'),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) return;
                LocalDatabase.instance.broadcastSystemNotification(
                  titleCtrl.text.trim(),
                  msgCtrl.text.trim(),
                  targetOrgId: selectedOrgId,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement successfully broadcasted!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAuditLogSheet(BuildContext context) {
    final allLogs = LocalDatabase.instance.allAuditLogs;
    String filterEntity = 'ALL';
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = allLogs.where((l) {
            if (filterEntity != 'ALL' && l.entity != filterEntity) return false;
            if (searchQuery.isNotEmpty) {
              final q = searchQuery.toLowerCase();
              return l.action.toLowerCase().contains(q) ||
                  l.userName.toLowerCase().contains(q) ||
                  l.entityId.toLowerCase().contains(q) ||
                  (l.reason?.toLowerCase().contains(q) ?? false) ||
                  (l.newValue?.toLowerCase().contains(q) ?? false);
            }
            return true;
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_edu_rounded, color: Colors.purple, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Global Audit Trail (${allLogs.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search audit logs by actor, action, ID...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      setSheetState(() => searchQuery = val);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['ALL', 'JOURNEY', 'VEHICLE', 'ORGANIZATION', 'USER', 'SYSTEM'].map((cat) {
                      final selected = filterEntity == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                          selected: selected,
                          onSelected: (_) {
                            setSheetState(() => filterEntity = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No audit logs match current filters.'))
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final log = filtered[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          log.action,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.purple),
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd MMM HH:mm').format(log.timestamp),
                                        style: const TextStyle(fontSize: 10, color: AppColors.outline),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 13, color: AppColors.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${log.userName} (${log.userId})',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${log.entity} #${log.entityId}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                                      ),
                                    ],
                                  ),
                                  if (log.newValue != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Result: ${log.newValue}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.onSurface),
                                    ),
                                  ],
                                  if (log.reason != null && log.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Note: ${log.reason}',
                                      style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.secondary),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    final jsonStr = LocalDatabase.instance.exportPlatformDataJson();
    final orgs = LocalDatabase.instance.organizations.length;
    final users = LocalDatabase.instance.users.length;
    final vehicles = LocalDatabase.instance.vehicles.length;
    final journeys = LocalDatabase.instance.journeys.length;
    final audits = LocalDatabase.instance.allAuditLogs.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: Colors.teal, size: 24),
            SizedBox(width: 8),
            Text('Platform Backup Export', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A complete snapshot of all multi-tenant databases has been compiled into standard JSON format.',
              style: TextStyle(fontSize: 12.5, color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Organizations', '$orgs active'),
                  _buildDetailRow('Registered Users', '$users accounts'),
                  _buildDetailRow('Fleet Vehicles', '$vehicles registered'),
                  _buildDetailRow('Total Journeys', '$journeys logs'),
                  _buildDetailRow('Audit Logs', '$audits entries'),
                  _buildDetailRow('Backup Size', '${(jsonStr.length / 1024).toStringAsFixed(1)} KB'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy JSON to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Platform database backup copied to clipboard!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
