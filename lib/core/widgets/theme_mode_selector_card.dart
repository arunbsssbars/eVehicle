import 'package:flutter/material.dart';
import '../theme/accessible_theme_engine.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Interactive card allowing users to switch between Light, Dark, and High Contrast accessibility themes
class ThemeModeSelectorCard extends StatelessWidget {
  final AccessibleThemeMode currentMode;
  final ValueChanged<AccessibleThemeMode> onModeChanged;

  const ThemeModeSelectorCard({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          const Row(
            children: [
              Icon(Icons.palette_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display Theme & Contrast',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Light • Dark • High Contrast (WCAG AAA)',
                      style: TextStyle(fontSize: 11, color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Presets wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AccessibleThemeMode.values.map((mode) {
              final isSelected = currentMode == mode;
              return ChoiceChip(
                avatar: Icon(
                  mode.icon,
                  size: 14,
                  color: isSelected ? AppColors.surfaceWhite : AppColors.secondary,
                ),
                label: Text(
                  mode.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.surfaceWhite : AppColors.onSurface,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceContainerLow,
                onSelected: (selected) {
                  if (selected) {
                    onModeChanged(mode);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
