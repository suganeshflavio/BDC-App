import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants/app_colors.dart';

/// Base Shimmer Configuration
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEBE6DD),
      highlightColor: const Color(0xFFFAF7F2),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Generic Skeleton Box placeholder
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    if (shape != null) {
      return Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: shape!,
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer placeholder for a single Song Card
class SongCardSkeleton extends StatelessWidget {
  const SongCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: Row(
        children: [
          // Song Number badge placeholder
          const SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: 14,
          ),
          const SizedBox(width: 14),

          // Title and Subtitle lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                SkeletonBox(
                  width: 180,
                  height: 15,
                  borderRadius: 6,
                ),
                SizedBox(height: 8),
                SkeletonBox(
                  width: 120,
                  height: 11,
                  borderRadius: 5,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Favorite button placeholder
          const SkeletonBox(
            width: 32,
            height: 32,
            shape: CircleBorder(),
          ),
        ],
      ),
    );
  }
}

/// Shimmer list of Song Cards
class SongListSkeleton extends StatelessWidget {
  final int count;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const SongListSkeleton({
    super.key,
    this.count = 6,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final list = ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.symmetric(vertical: 6),
      itemCount: count,
      itemBuilder: (_, _) => const SongCardSkeleton(),
    );

    return AppShimmer(child: list);
  }
}

/// Shimmer placeholder for a Notification Card
class NotificationCardSkeleton extends StatelessWidget {
  const NotificationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date chip & Status pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonBox(width: 85, height: 20, borderRadius: 10),
              SkeletonBox(width: 65, height: 20, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          const SkeletonBox(width: 220, height: 16, borderRadius: 6),
          const SizedBox(height: 10),

          // Preacher chip
          const SkeletonBox(width: 150, height: 13, borderRadius: 6),
          const SizedBox(height: 12),

          // Description lines
          const SkeletonBox(width: double.infinity, height: 11, borderRadius: 5),
          const SizedBox(height: 6),
          const SkeletonBox(width: 200, height: 11, borderRadius: 5),
          const SizedBox(height: 14),

          // YouTube button placeholder
          const SkeletonBox(width: 140, height: 32, borderRadius: 10),
        ],
      ),
    );
  }
}

/// Shimmer list of Notifications
class NotificationListSkeleton extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry? padding;

  const NotificationListSkeleton({
    super.key,
    this.count = 5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ?? const EdgeInsets.only(top: 12, bottom: 90),
        itemCount: count,
        itemBuilder: (_, _) => const NotificationCardSkeleton(),
      ),
    );
  }
}

/// Shimmer placeholder for Song Lyrics Screen
class LyricsScreenSkeleton extends StatelessWidget {
  const LyricsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card Placeholder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonBox(width: 60, height: 26, borderRadius: 8),
                      SkeletonBox(width: 80, height: 26, borderRadius: 13),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const SkeletonBox(width: 240, height: 22, borderRadius: 6),
                  const SizedBox(height: 8),
                  const SkeletonBox(width: 170, height: 14, borderRadius: 5),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stanza 1 Placeholder (Chorus)
            _buildVerseBlock(lineCount: 4, hasBadge: true),
            const SizedBox(height: 16),

            // Stanza 2 Placeholder (Verse 1)
            _buildVerseBlock(lineCount: 4, hasBadge: true),
            const SizedBox(height: 16),

            // Stanza 3 Placeholder (Verse 2)
            _buildVerseBlock(lineCount: 4, hasBadge: true),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseBlock({required int lineCount, bool hasBadge = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBadge) ...[
            const SkeletonBox(width: 80, height: 18, borderRadius: 6),
            const SizedBox(height: 12),
          ],
          const SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
          const SizedBox(height: 8),
          const SkeletonBox(width: 260, height: 14, borderRadius: 6),
          const SizedBox(height: 8),
          const SkeletonBox(width: 300, height: 14, borderRadius: 6),
          const SizedBox(height: 8),
          const SkeletonBox(width: 190, height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for About Us Screen
class AboutUsSkeleton extends StatelessWidget {
  const AboutUsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Church Image / Banner Header
            const SkeletonBox(
              width: double.infinity,
              height: 170,
              borderRadius: 20,
            ),
            const SizedBox(height: 18),

            // Church Details Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonBox(width: 200, height: 20, borderRadius: 6),
                      SkeletonBox(width: 90, height: 22, borderRadius: 11),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SkeletonBox(width: 160, height: 14, borderRadius: 5),
                  const SizedBox(height: 14),
                  const SkeletonBox(width: double.infinity, height: 12, borderRadius: 5),
                  const SizedBox(height: 6),
                  const SkeletonBox(width: double.infinity, height: 12, borderRadius: 5),
                  const SizedBox(height: 6),
                  const SkeletonBox(width: 220, height: 12, borderRadius: 5),
                  const SizedBox(height: 18),
                  const SkeletonBox(width: double.infinity, height: 44, borderRadius: 14),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Additional Info Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 140, height: 16, borderRadius: 6),
                  SizedBox(height: 12),
                  SkeletonBox(width: double.infinity, height: 12, borderRadius: 5),
                  SizedBox(height: 6),
                  SkeletonBox(width: 260, height: 12, borderRadius: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for Carousel Banner on HomeScreen
class BannerCarouselSkeleton extends StatelessWidget {
  const BannerCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        height: 155,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder, width: 0.8),
        ),
      ),
    );
  }
}
