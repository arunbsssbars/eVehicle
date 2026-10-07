import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../providers/auth_provider.dart';

/// Service managing AdMob and sponsored rewarded ad gating.
class AdService {
  AdService._();

  /// Prompts Free tier users to watch a short sponsor ad to unlock a premium export.
  /// If the user is on Pro or Enterprise tier, [onRewardEarned] is executed immediately.
  static void showRewardedAdGate({
    required BuildContext context,
    required WidgetRef ref,
    required String benefit,
    required VoidCallback onRewardEarned,
  }) {
    final user = ref.read(authProvider).currentUser;
    final isFree = user?.isFreeTier ?? true;

    // Pro and Enterprise tiers bypass all ads
    if (!isFree) {
      onRewardEarned();
      return;
    }

    // Show rewarded ad gate dialog for Free tier users
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RewardedAdGateSheet(
        benefit: benefit,
        onWatchAd: () {
          Navigator.pop(ctx);
          _playSponsoredAd(context, benefit: benefit, onRewardEarned: onRewardEarned);
        },
        onUpgrade: () {
          Navigator.pop(ctx);
          context.push('/plans');
        },
      ),
    );
  }

  /// Displays an interactive simulated sponsored video ad overlay with countdown.
  static void _playSponsoredAd(
    BuildContext context, {
    required String benefit,
    required VoidCallback onRewardEarned,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _SponsoredVideoDialog(
        benefit: benefit,
        onComplete: () {
          Navigator.pop(dialogCtx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sponsor reward unlocked! Generating $benefit...',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          onRewardEarned();
        },
      ),
    );
  }
}

/// Modal bottom sheet prompting the user before watching an ad.
class _RewardedAdGateSheet extends StatelessWidget {
  final String benefit;
  final VoidCallback onWatchAd;
  final VoidCallback onUpgrade;

  const _RewardedAdGateSheet({
    required this.benefit,
    required this.onWatchAd,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_display_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Unlock $benefit',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Explanation
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'You are currently on the Free Starter Plan. Watch a short 5-second sponsor video to download this export for free, or upgrade to Pro to remove all ads permanently.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Option 1: Watch Ad (Free)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onWatchAd,
                icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                label: const Text(
                  'Watch Short Video (5s Free)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Upgrade to Pro
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.workspace_premium_rounded,
                    size: 20, color: Colors.deepPurple),
                label: const Text(
                  'Upgrade to Pro • \$2.99/mo (Ad-Free)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.deepPurple,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepPurple, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simulated full-featured sponsor video ad with a 5-second countdown timer.
class _SponsoredVideoDialog extends StatefulWidget {
  final String benefit;
  final VoidCallback onComplete;

  const _SponsoredVideoDialog({
    required this.benefit,
    required this.onComplete,
  });

  @override
  State<_SponsoredVideoDialog> createState() => _SponsoredVideoDialogState();
}

class _SponsoredVideoDialogState extends State<_SponsoredVideoDialog> {
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
        setState(() => _secondsLeft = 0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 480),
          child: Column(
            children: [
              // Ad Header with countdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: Colors.black87,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AD',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      _secondsLeft > 0
                          ? 'Reward in ${_secondsLeft}s'
                          : 'Reward Ready!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Simulated Video Player Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.amberAccent,
                        size: 56,
                      ),
                      const SizedBox(height: 14),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'FleetSync AI Telematics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Automate fleet inspections, fuel tracking, and maintenance with real-time AI sensors.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_secondsLeft > 0)
                        SizedBox(
                          width: 140,
                          child: LinearProgressIndicator(
                            value: (5 - _secondsLeft) / 5.0,
                            backgroundColor: Colors.white24,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Colors.amber),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Ad Footer / Complete Button
              Container(
                padding: const EdgeInsets.all(14),
                color: Colors.black87,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _secondsLeft == 0 ? widget.onComplete : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          disabledBackgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _secondsLeft == 0
                              ? 'Claim Reward & Download'
                              : 'Watching Sponsor (${_secondsLeft}s)...',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A native banner ad widget displayed only for Free tier users.
/// Pro and Enterprise users see nothing (SizedBox.shrink).
class AdBannerWidget extends ConsumerWidget {
  final EdgeInsetsGeometry? margin;

  const AdBannerWidget({super.key, this.margin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final isFree = user?.isFreeTier ?? true;

    if (!isFree) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          // Ad Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey.shade400, width: 0.8),
            ),
            child: const Text(
              'Ad',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sponsor Text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FleetSync AI • Real-Time Fuel & GPS Tracking',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Sponsored • Upgrade to Pro to remove all ads',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Upgrade Shortcut Icon
          InkWell(
            onTap: () => context.push('/plans'),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
