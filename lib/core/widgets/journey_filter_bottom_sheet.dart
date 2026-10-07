import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../services/journey_export_filter_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Modal bottom sheet allowing users and administrators to filter and sort journeys
class JourneyFilterBottomSheet extends StatefulWidget {
  final JourneyFilterCriteria initialCriteria;
  final ValueChanged<JourneyFilterCriteria> onApply;
  final VoidCallback? onReset;

  const JourneyFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
    this.onReset,
  });

  @override
  State<JourneyFilterBottomSheet> createState() => _JourneyFilterBottomSheetState();
}

class _JourneyFilterBottomSheetState extends State<JourneyFilterBottomSheet> {
  late JourneySortField _sortBy;
  late bool _sortAscending;
  JourneyStatus? _status;
  TripCategory? _category;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialCriteria.sortBy;
    _sortAscending = widget.initialCriteria.sortAscending;
    _status = widget.initialCriteria.status;
    _category = widget.initialCriteria.category;
    _searchController = TextEditingController(text: widget.initialCriteria.searchQuery ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title & Reset Row
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter & Sort Journeys',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _sortBy = JourneySortField.date;
                      _sortAscending = false;
                      _status = null;
                      _category = null;
                      _searchController.clear();
                    });
                    widget.onReset?.call();
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 36),
                  ),
                  child: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search location, driver, vehicle...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.secondary),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.secondary),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sort By Chips
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: JourneySortField.values.map((field) {
                final isSelected = _sortBy == field;
                return ChoiceChip(
                  label: Text(field.label, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        if (_sortBy == field) {
                          _sortAscending = !_sortAscending;
                        } else {
                          _sortBy = field;
                          _sortAscending = false;
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Status Filter Chips
            const Text(
              'Journey Status',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                JourneyStatus.approved,
                JourneyStatus.pendingApproval,
                JourneyStatus.active,
                JourneyStatus.completed,
                JourneyStatus.rejected,
              ].map((st) {
                final isSelected = _status == st;
                return FilterChip(
                  label: Text(st.label, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _status = selected ? st : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final updated = widget.initialCriteria.copyWith(
                        sortBy: _sortBy,
                        sortAscending: _sortAscending,
                        status: _status,
                        category: _category,
                        searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
                      );
                      widget.onApply(updated);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surfaceWhite,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
