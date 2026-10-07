import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/journey_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/sync_indicator.dart';

class MainLayoutScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({
    super.key,
    required this.navigationShell,
  });

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final journeyState = ref.watch(journeyProvider);
    final authState = ref.watch(authProvider);
    final currentUser = authState.currentUser;
    final selectedIndex = navigationShell.currentIndex;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 840;

    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedIndex != 0) {
          _onItemTapped(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: isDesktop
              ? Row(
                  children: [
                    // Desktop Navigation Rail / Sidebar
                    _buildDesktopSidebar(
                      context,
                      ref,
                      selectedIndex: selectedIndex,
                      currentUser: currentUser,
                      hasActiveJourney: journeyState.activeJourney != null,
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.borderSubtle,
                    ),
                    // Main Content Area (Bounded for Wide Screens)
                    Expanded(
                      child: Column(
                        children: [
                          SyncIndicator(
                            isOffline: appState.isOffline,
                            pendingCount: appState.pendingSyncCount,
                            isSyncing: appState.isSyncing,
                            onSyncTap: () => ref
                                .read(appStateProvider.notifier)
                                .triggerSync(),
                          ),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 1320),
                                child: navigationShell,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Top Offline & Sync Banner
                    SyncIndicator(
                      isOffline: appState.isOffline,
                      pendingCount: appState.pendingSyncCount,
                      isSyncing: appState.isSyncing,
                      onSyncTap: () =>
                          ref.read(appStateProvider.notifier).triggerSync(),
                    ),
                    // Active Tab Content
                    Expanded(child: navigationShell),
                  ],
                ),
        ),
        bottomNavigationBar: isDesktop
            ? null
            : Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle, width: 1),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: _onItemTapped,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.secondary,
                  selectedFontSize: 11,
                  unselectedFontSize: 11,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home_filled),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.alt_route_outlined),
                          if (journeyState.activeJourney != null)
                            Positioned(
                              right: -3,
                              top: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      activeIcon: const Icon(Icons.alt_route_rounded),
                      label: 'Journeys',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.directions_car_outlined),
                      activeIcon: Icon(Icons.directions_car_filled),
                      label: 'Vehicles',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.assessment_outlined),
                      activeIcon: Icon(Icons.assessment_rounded),
                      label: 'Reports',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      activeIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    WidgetRef ref, {
    required int selectedIndex,
    required dynamic currentUser,
    required bool hasActiveJourney,
  }) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform Brand Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'eVehicle LogBook',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Enterprise Web Console',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),

          // User Persona Card
          if (currentUser != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryFixed,
                    child: Text(
                      currentUser.name.isNotEmpty
                          ? currentUser.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentUser.organizationName,
                          style: const TextStyle(
                            fontSize: 10,
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

          // Main Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
                _buildSidebarTile(
                  title: 'Dashboard',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_filled,
                  isSelected: selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                _buildSidebarTile(
                  title: 'Journeys',
                  icon: Icons.alt_route_outlined,
                  activeIcon: Icons.alt_route_rounded,
                  isSelected: selectedIndex == 1,
                  hasBadge: hasActiveJourney,
                  onTap: () => _onItemTapped(1),
                ),
                _buildSidebarTile(
                  title: 'Fleet Vehicles',
                  icon: Icons.directions_car_outlined,
                  activeIcon: Icons.directions_car_filled,
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
                _buildSidebarTile(
                  title: 'Reports & Audits',
                  icon: Icons.assessment_outlined,
                  activeIcon: Icons.assessment_rounded,
                  isSelected: selectedIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
                _buildSidebarTile(
                  title: 'My Profile',
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  isSelected: selectedIndex == 4,
                  onTap: () => _onItemTapped(4),
                ),

                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Text(
                    'CONTROL CENTERS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                if (currentUser?.isSuperAdmin == true)
                  _buildAdminShortcutTile(
                    title: 'Super Admin',
                    subtitle: 'Global platform telemetry',
                    icon: Icons.admin_panel_settings_rounded,
                    iconColor: Colors.deepPurple,
                    onTap: () => context.push('/super-admin'),
                  ),

                if (currentUser?.isCompanyAdmin == true ||
                    currentUser?.isSuperAdmin == true)
                  _buildAdminShortcutTile(
                    title: 'Company Admin',
                    subtitle: 'Fleet & team join codes',
                    icon: Icons.business_center_rounded,
                    iconColor: Colors.indigo,
                    onTap: () => context.push('/company-admin'),
                  ),

                _buildAdminShortcutTile(
                  title: 'Subscription Plans',
                  subtitle: 'Pricing, tiers & billing',
                  icon: Icons.workspace_premium_rounded,
                  iconColor: Colors.amber.shade900,
                  onTap: () => context.push('/plans'),
                ),

                _buildAdminShortcutTile(
                  title: 'System Settings',
                  subtitle: 'Sync queue & preferences',
                  icon: Icons.settings_outlined,
                  iconColor: AppColors.primary,
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),

          // Bottom version tag
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'v1.0.0 Enterprise • Flutter Web',
              style: TextStyle(fontSize: 10, color: AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile({
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryFixed : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          leading: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.primary : AppColors.secondary,
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.onSurface,
            ),
          ),
          trailing: hasBadge
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildAdminShortcutTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.secondary),
          ),
          trailing: const Icon(Icons.chevron_right, size: 16, color: AppColors.secondary),
          onTap: onTap,
        ),
      ),
    );
  }
}
