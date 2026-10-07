import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/models/journey.dart';
import '../../core/widgets/journey_card.dart';
import '../../core/providers/journey_provider.dart';

class JourneyHistoryScreen extends ConsumerStatefulWidget {
  const JourneyHistoryScreen({super.key});

  @override
  ConsumerState<JourneyHistoryScreen> createState() =>
      _JourneyHistoryScreenState();
}

class _JourneyHistoryScreenState extends ConsumerState<JourneyHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      ref.read(journeyProvider.notifier).setDateFilter(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyProvider);
    final filtered = journeyState.filteredJourneys;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          'Journey Log Book',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.playlist_add_rounded),
            tooltip: 'Multi-Journey / Monthly Log Entry',
            onPressed: () => context.push('/journeys/batch-create'),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Calendar View',
            onPressed: () => context.push('/journeys/calendar'),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_road_rounded),
            tooltip: 'Start Journey',
            onPressed: () => context.push('/journeys/start'),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF003E99), Color(0xFF0052CC)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0052CC).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => context.push('/journeys/batch-create'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_add_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 7),
                  Text(
                    'Multi-Journey Log',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surfaceWhite,
              child: Column(
                children: [
                  // Search Input
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(journeyProvider.notifier).setSearchQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by vehicle, destination, driver, purpose...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(journeyProvider.notifier)
                                    .setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', null, journeyState.statusFilter),
                        const SizedBox(width: 6),
                        _buildFilterChip('Pending',
                            JourneyStatus.pendingApproval, journeyState.statusFilter),
                        const SizedBox(width: 6),
                        _buildFilterChip('Approved',
                            JourneyStatus.approved, journeyState.statusFilter),
                        const SizedBox(width: 6),
                        _buildFilterChip('Draft',
                            JourneyStatus.draft, journeyState.statusFilter),
                        const SizedBox(width: 6),
                        _buildFilterChip('Locked',
                            JourneyStatus.locked, journeyState.statusFilter),
                        const SizedBox(width: 8),
                        // Date Filter Chip
                        ActionChip(
                          avatar: Icon(
                            Icons.calendar_today,
                            size: 13,
                            color: journeyState.dateFilter != null
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                          label: Text(
                            journeyState.dateFilter != null
                                ? DateFormat('dd MMM')
                                    .format(journeyState.dateFilter!)
                                : 'Date',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: journeyState.dateFilter != null
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                            ),
                          ),
                          backgroundColor: journeyState.dateFilter != null
                              ? AppColors.primaryFixed
                              : AppColors.surfaceContainerLow,
                          onPressed: _selectDateFilter,
                        ),
                        if (journeyState.dateFilter != null ||
                            journeyState.statusFilter != null ||
                            journeyState.vehicleFilter != null) ...[
                          const SizedBox(width: 6),
                          ActionChip(
                            avatar: const Icon(Icons.close, size: 13),
                            label: const Text('Clear',
                                style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              ref
                                  .read(journeyProvider.notifier)
                                  .setStatusFilter(null);
                              ref
                                  .read(journeyProvider.notifier)
                                  .setVehicleFilter(null);
                              ref
                                  .read(journeyProvider.notifier)
                                  .setDateFilter(null);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Journey Count Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceContainerLow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Showing ${filtered.length} Journey Records',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${filtered.fold(0.0, (sum, j) => sum + j.calculatedDistance).toStringAsFixed(1)} KM',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Journeys List grouped datewise (today unfolded, others folded)
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_outlined,
                              size: 48, color: AppColors.outline.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No Journeys Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try clearing your search or filters.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.outline),
                          ),
                        ],
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final Map<String, List<Journey>> groupedJourneys = {};
                        for (final j in filtered) {
                          final key = DateFormat('yyyy-MM-dd').format(j.journeyDate);
                          groupedJourneys.putIfAbsent(key, () => []).add(j);
                        }
                        final sortedDateKeys = groupedJourneys.keys.toList();
                        final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

                        return ListView.builder(
                          padding: const EdgeInsets.all(AppDimensions.marginMobile),
                          itemCount: sortedDateKeys.length,
                          itemBuilder: (context, i) {
                            final dateKey = sortedDateKeys[i];
                            final dayJourneys = groupedJourneys[dateKey]!;
                            final isToday = dateKey == todayKey;
                            final firstDate = dayJourneys.first.journeyDate;
                            final dayDistance = dayJourneys.fold(
                                0.0, (sum, j) => sum + j.calculatedDistance);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWhite,
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusLg),
                                border: Border.all(
                                  color: isToday
                                      ? AppColors.primary.withValues(alpha: 0.35)
                                      : AppColors.borderSubtle,
                                  width: isToday ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isToday
                                        ? AppColors.primary.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: ExpansionTile(
                                    key: PageStorageKey('date_group_$dateKey'),
                                  initiallyExpanded: isToday ||
                                      journeyState.statusFilter != null ||
                                      journeyState.searchQuery.isNotEmpty,
                                  tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                      10, 4, 10, 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: isToday
                                        ? AppColors.primaryFixed
                                        : AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isToday
                                          ? Icons.today_rounded
                                          : Icons.calendar_today_outlined,
                                      size: 17,
                                      color: isToday
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                    ),
                                  ),
                                  title: Text(
                                    isToday
                                        ? 'Today (${DateFormat('dd MMM yyyy').format(firstDate)})'
                                        : DateFormat('EEEE, dd MMM yyyy')
                                            .format(firstDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isToday
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: isToday
                                          ? AppColors.primary
                                          : AppColors.onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${dayJourneys.length} ${dayJourneys.length == 1 ? 'Journey' : 'Journeys'} • ${dayDistance.toStringAsFixed(1)} KM',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isToday
                                          ? AppColors.primary.withValues(alpha: 0.8)
                                          : AppColors.secondary,
                                    ),
                                  ),
                                  children: [
                                    for (final j in dayJourneys)
                                      _buildHistoryCard(context, j),
                                    if (isToday)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: () => context.push('/journeys/start'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 11, horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryFixed.withValues(alpha: 0.4),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.primary.withValues(alpha: 0.5),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_road_rounded,
                                                      size: 18,
                                                      color: AppColors.primary,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      '+ Add Journey',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.primary,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, JourneyStatus? status, JourneyStatus? activeStatus) {
    final isSelected = activeStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerLow,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.onSurface,
      ),
      onSelected: (selected) {
        ref
            .read(journeyProvider.notifier)
            .setStatusFilter(selected ? status : null);
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, dynamic j) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: JourneyCard(
        journey: j,
        showDate: false,
      ),
    );
  }
}
