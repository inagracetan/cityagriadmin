import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';

class SkeletonLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = AppDesignSystem.radiusSmall,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final baseColor = isDark ? Slate.shade800 : Slate.shade200;
    final highlightColor = isDark ? Slate.shade700 : Slate.shade100;

    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  const SkeletonCard({super.key, this.height = 200, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(AppDesignSystem.spacing16), // Reduced from spacing24
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Slate.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusXLarge),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark ? Slate.shade800 : Slate.shade100,
        ),
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonLoading(
                width: height > 140 ? 40 : 32, 
                height: height > 140 ? 40 : 32, 
                borderRadius: AppDesignSystem.radiusRound
              ),
              SizedBox(height: height > 140 ? AppDesignSystem.spacing16 : AppDesignSystem.spacing8),
              SkeletonLoading(width: 150, height: height > 140 ? 20 : 16),
              if (height > 135) ...[
                const SizedBox(height: AppDesignSystem.spacing12),
                const SkeletonLoading(width: double.infinity, height: 14),
              ],
              if (height > 170) ...[
                const SizedBox(height: AppDesignSystem.spacing8),
                const SkeletonLoading(width: 200, height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDesignSystem.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          const SkeletonLoading(height: 120, borderRadius: AppDesignSystem.radiusXLarge),
          const SizedBox(height: 40),
          
          // Section Title
          const SkeletonLoading(width: 200, height: 28),
          const SizedBox(height: 20),
          
          // Summary Cards Row
          Row(
            children: [
              Expanded(child: const SkeletonCard(height: 150)),
              const SizedBox(width: 16),
              Expanded(child: const SkeletonCard(height: 150)),
              const SizedBox(width: 16),
              Expanded(child: const SkeletonCard(height: 150)),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Large Chart Skeleton
          const SkeletonLoading(height: 300, borderRadius: AppDesignSystem.radiusXLarge),
          
          const SizedBox(height: 40),
          
          // Grid of Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => const SkeletonCard(),
          ),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  const SkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacing16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Slate.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark ? Slate.shade800 : Slate.shade100,
          ),
        ),
        child: Row(
          children: [
            const SkeletonLoading(width: 48, height: 48, borderRadius: 8),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoading(width: 120, height: 18),
                  const SizedBox(height: 8),
                  const SkeletonLoading(width: 200, height: 14),
                ],
              ),
            ),
            const SkeletonLoading(width: 60, height: 24, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}

class SkeletonKanban extends StatelessWidget {
  const SkeletonKanban({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Row(
        children: List.generate(3, (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Slate.shade900.withOpacity(0.5) : Slate.shade50,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoading(width: 100, height: 24),
                  const SizedBox(height: 20),
                  ...List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: const SkeletonCard(height: 120),
                  )),
                ],
              ),
            ),
          ),
        )),
      ),
    );
  }
}

