import 'package:flutter/material.dart';
import '../services/journey_playback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Interactive playback controller bar for journey route replay
class JourneyPlaybackController extends StatelessWidget {
  final RoutePlaybackState state;
  final bool isPlaying;
  final double playbackSpeed;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSpeedChanged;

  const JourneyPlaybackController({
    super.key,
    required this.state,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final elapsedMinutes = state.elapsedTime.inMinutes;
    final totalMinutes = state.totalDuration.inMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Telemetry readout row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${state.speedKmH.toStringAsFixed(0)} km/h',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${state.distanceTraveledKm.toStringAsFixed(1)} / ${state.totalDistanceKm.toStringAsFixed(1)} km • ${state.bearingDegrees.toStringAsFixed(0)}°',
                  style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$elapsedMinutes / $totalMinutes min',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Slider Scrubber
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceContainerHigh,
              thumbColor: AppColors.primary,
            ),
            child: Slider(
              value: state.progress.clamp(0.0, 1.0),
              onChanged: onSeek,
            ),
          ),

          // Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Play/Pause button
              IconButton(
                onPressed: onPlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),

              // Speed selector
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [1.0, 2.0, 5.0].map((speed) {
                  final isCurrent = playbackSpeed == speed;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () => onSpeedChanged(speed),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.primary : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${speed.toInt()}x',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? AppColors.surfaceWhite : AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
