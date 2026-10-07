import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/storage/local_database.dart';
import '../../core/models/user.dart';
import '../../core/models/vehicle.dart';
import '../../core/models/membership_request.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/status_badge.dart';

class CompanyAdminScreen extends ConsumerStatefulWidget {
  const CompanyAdminScreen({super.key});

  @override
  ConsumerState<CompanyAdminScreen> createState() => _CompanyAdminScreenState();
}

class _CompanyAdminScreenState extends ConsumerState<CompanyAdminScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final orgId = user?.organizationId ?? '';
    final org = LocalDatabase.instance.getOrganizationById(orgId) ??
        LocalDatabase.instance.organizations.first;

    final allUsers = LocalDatabase.instance.users;
    final orgMembers = allUsers
        .where((u) => u.organizationId == org.id || u.department == user?.department)
        .toList();
    final orgVehicles = LocalDatabase.instance.vehicles;
    final pendingRequests = LocalDatabase.instance.getPendingMembershipRequests(org.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          org.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'COMPANY ADMIN',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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
            // 1. Prominent Company Join Code Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003E99), Color(0xFF0052CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0052CC).withValues(alpha: 0.35),
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
                      Icon(Icons.vpn_key_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Company Driver / Officer Join Code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share this 6-digit code with your drivers and officers. When they sign up with this code, they will automatically join your company fleet.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Join Code Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          org.code,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: Color(0xFF0040A8),
                          ),
                        ),
                      ),
                      // Copy Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: org.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Company Join Code ${org.code} copied to clipboard!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.white38),
                          ),
                        ),
                      ),
                      // Regenerate Button
                      ElevatedButton.icon(
                        onPressed: () => _confirmRegenerateCode(org.id, org.name),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Regenerate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.white38),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Company Stats Overview
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    'Enrolled Staff',
                    '${orgMembers.length}',
                    Icons.people_alt_rounded,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatTile(
                    'Fleet Vehicles',
                    '${orgVehicles.length}',
                    Icons.directions_car_rounded,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Vehicle Compliance & Document Expiry Monitor
            _buildComplianceMonitorCard(context, orgVehicles),
            const SizedBox(height: 18),

            // 4. Pending Member Join Requests Queue
            _buildPendingRequestsSection(context, pendingRequests),
            const SizedBox(height: 24),

            // 5. Enrolled Staff / Drivers Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enrolled Drivers & Officers',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${orgMembers.length} Active Personnel',
                        style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddMemberDialog(org.id, org.name),
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('Add Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            for (final m in orgMembers)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: m.role == UserRole.driver
                          ? AppColors.secondaryContainer
                          : AppColors.primaryFixed,
                      child: Icon(
                        m.role == UserRole.driver
                            ? Icons.directions_car
                            : Icons.person_pin,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      m.name,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${m.designation} • ${m.mobile}${m.assignedVehicleId != null ? ' • Assigned: ${m.assignedVehicleId}' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            m.role.label,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.secondary),
                          padding: EdgeInsets.zero,
                          onSelected: (action) {
                            if (action == 'role') {
                              _showChangeRoleDialog(m);
                            } else if (action == 'vehicle') {
                              _showAssignVehicleDialog(m, orgVehicles);
                            } else if (action == 'remove') {
                              _showRemoveMemberDialog(m);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'role',
                              child: Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Change Role / Dept'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'vehicle',
                              child: Row(
                                children: [
                                  Icon(Icons.directions_car_outlined, size: 18, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Assign Vehicle'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(Icons.person_remove_outlined, size: 18, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Remove Member', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 4. Fleet Vehicles Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Company Fleet Vehicles',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.push('/vehicles'),
                  child: const Text('Manage Fleet >'),
                ),
              ],
            ),
            for (final v in orgVehicles.take(3))
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    leading: const Icon(Icons.directions_car_rounded, color: AppColors.primary),
                    title: Text(
                      v.registrationNumber,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${v.make} ${v.model} • Driver: ${v.assignedDriverName}',
                      style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                    ),
                    trailing: StatusBadge.fromVehicleStatus(v.status),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 6. Bulk Fleet Ledger Export
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderSubtle),
              ),
              tileColor: AppColors.surfaceWhite,
              leading: const CircleAvatar(
                backgroundColor: AppColors.successContainer,
                child: Icon(Icons.table_chart_rounded, color: AppColors.success),
              ),
              title: const Text(
                'Export Bulk Fleet Ledger (.xlsx / .csv)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Comprehensive raw multi-vehicle mileage & audit register for payroll & accounts',
                style: TextStyle(fontSize: 11, color: AppColors.secondary),
              ),
              trailing: const Icon(Icons.download_rounded, color: AppColors.primary),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exporting Fleet Ledger summary... Report ready!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceMonitorCard(BuildContext context, List<Vehicle> vehicles) {
    int totalExpired = 0;
    int totalExpiringSoon = 0;
    for (final v in vehicles) {
      totalExpired += v.expiredDocumentsCount;
      totalExpiringSoon += v.expiringSoonDocumentsCount;
    }

    final hasIssues = totalExpired > 0 || totalExpiringSoon > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: totalExpired > 0
              ? AppColors.error.withValues(alpha: 0.4)
              : (totalExpiringSoon > 0
                  ? Colors.amber.shade700.withValues(alpha: 0.4)
                  : AppColors.success.withValues(alpha: 0.4)),
        ),
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
                    Icon(
                      hasIssues
                          ? Icons.notification_important_rounded
                          : Icons.check_circle_outline_rounded,
                      color: totalExpired > 0
                          ? AppColors.error
                          : (totalExpiringSoon > 0
                              ? Colors.amber.shade800
                              : AppColors.success),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Fleet Compliance & Expiry Monitor',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push('/vehicles'),
                child: const Text('View All >',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: totalExpired > 0
                        ? AppColors.error.withValues(alpha: 0.08)
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel_rounded,
                          size: 16,
                          color: totalExpired > 0
                              ? AppColors.error
                              : AppColors.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$totalExpired Expired',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: totalExpired > 0
                                ? AppColors.error
                                : AppColors.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: totalExpiringSoon > 0
                        ? Colors.amber.withValues(alpha: 0.12)
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16,
                          color: totalExpiringSoon > 0
                              ? Colors.amber.shade900
                              : AppColors.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$totalExpiringSoon Expiring (<30d)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: totalExpiringSoon > 0
                                ? Colors.amber.shade900
                                : AppColors.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSection(
      BuildContext context, List<MembershipRequest> requests) {
    if (requests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Row(
          children: [
            Icon(Icons.how_to_reg_rounded, color: AppColors.success, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No pending join requests. Drivers entering your 6-digit Join Code will appear here for approval.',
                style: TextStyle(fontSize: 11.5, color: AppColors.secondary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.person_add_rounded, size: 18, color: AppColors.warning),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Join Code Approval Queue',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${requests.length} PENDING',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final req in requests)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      req.userName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Requested: ${req.requestedRole.label}',
                      style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${req.userEmail} • ${req.userMobile}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.secondary),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.error,
                      ),
                      onPressed: () async {
                        await LocalDatabase.instance.rejectMembershipRequest(
                          req.id,
                          rejectedBy: 'Company Admin',
                        );
                        setState(() {});
                      },
                      child:
                          const Text('Reject', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () => _showApproveRequestDialog(context, req),
                      child: const Text('Review & Approve',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showApproveRequestDialog(BuildContext context, MembershipRequest req) {
    UserRole selectedRole = req.requestedRole;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Approve Member: ${req.userName}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign organizational role for ${req.userName}:',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.secondary)),
              const SizedBox(height: 12),
              for (final role in [
                UserRole.driver,
                UserRole.user,
                UserRole.approvingOfficer
              ])
                RadioListTile<UserRole>(
                  dense: true,
                  title: Text(role.label, style: const TextStyle(fontSize: 13)),
                  value: role,
                  groupValue: selectedRole,
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRole = val);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () async {
                Navigator.pop(ctx);
                await LocalDatabase.instance.approveMembershipRequest(
                  req.id,
                  assignedRole: selectedRole,
                  approvedBy: 'Company Admin',
                );
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Approved ${req.userName} as ${selectedRole.label}!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Confirm Approval'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRegenerateCode(String orgId, String orgName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate Join Code?'),
        content: Text(
          'Are you sure you want to generate a new join code for $orgName? Any driver using the old code will need the new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              final newCode = await LocalDatabase.instance.regenerateOrganizationCode(orgId);
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New Join Code: $newCode'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Regenerate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(String orgId, String orgName) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final designationCtrl = TextEditingController(text: 'Fleet Driver');
    final departmentCtrl = TextEditingController(text: 'Operations');
    UserRole selectedRole = UserRole.driver;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Enroll New Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Ramesh Kumar',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: 'e.g. +91 9876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: designationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Designation',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: departmentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                  items: [
                    DropdownMenuItem(value: UserRole.driver, child: Text(UserRole.driver.label)),
                    DropdownMenuItem(value: UserRole.user, child: Text(UserRole.user.label)),
                    DropdownMenuItem(value: UserRole.approvingOfficer, child: Text(UserRole.approvingOfficer.label)),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRole = val);
                  },
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
                final name = nameCtrl.text.trim();
                final mobile = mobileCtrl.text.trim();
                if (name.isEmpty || mobile.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all mandatory fields.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await LocalDatabase.instance.addOrganizationMember(
                  orgId: orgId,
                  orgName: orgName,
                  name: name,
                  mobile: mobile,
                  designation: designationCtrl.text.trim().isEmpty ? 'Staff' : designationCtrl.text.trim(),
                  department: departmentCtrl.text.trim().isEmpty ? 'Operations' : departmentCtrl.text.trim(),
                  role: selectedRole,
                );
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Enrolled $name into $orgName'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Enroll Member'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(User member) {
    UserRole selectedRole = member.role;
    final desigCtrl = TextEditingController(text: member.designation);
    final deptCtrl = TextEditingController(text: member.department);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Edit ${member.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<UserRole>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.shield_outlined)),
                  items: [
                    DropdownMenuItem(value: UserRole.driver, child: Text(UserRole.driver.label)),
                    DropdownMenuItem(value: UserRole.user, child: Text(UserRole.user.label)),
                    DropdownMenuItem(value: UserRole.approvingOfficer, child: Text(UserRole.approvingOfficer.label)),
                    DropdownMenuItem(value: UserRole.companyAdmin, child: Text(UserRole.companyAdmin.label)),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: desigCtrl,
                  decoration: const InputDecoration(labelText: 'Designation', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined)),
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
                Navigator.pop(ctx);
                await LocalDatabase.instance.updateMemberRole(
                  member.id,
                  newRole: selectedRole,
                  designation: desigCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                );
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated ${member.name} successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignVehicleDialog(User member, List<Vehicle> vehicles) {
    String? selectedVehicleId = member.assignedVehicleId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Assign Vehicle: ${member.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select fleet vehicle assigned to this driver:', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: selectedVehicleId,
                decoration: const InputDecoration(
                  labelText: 'Vehicle',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None (Unassigned)'),
                  ),
                  for (final v in vehicles)
                    DropdownMenuItem<String?>(
                      value: v.id,
                      child: Text('${v.registrationNumber} (${v.make} ${v.model})', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (val) {
                  setModalState(() => selectedVehicleId = val);
                },
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
                Navigator.pop(ctx);
                await LocalDatabase.instance.updateMemberRole(
                  member.id,
                  assignedVehicleId: selectedVehicleId,
                  clearVehicleAssignment: selectedVehicleId == null,
                );
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vehicle assignment updated for ${member.name}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Confirm Assignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(User member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text(
          'Are you sure you want to remove ${member.name} from the organization? Their account will become an individual user and their personal journey records will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalDatabase.instance.removeMemberFromOrganization(member.id);
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${member.name} removed from organization'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            child: const Text('Remove Member', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
