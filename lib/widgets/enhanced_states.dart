import 'package:flutter/material.dart';

import '../core/design_system.dart';
import 'skeleton_loading.dart';

/// Enhanced empty state widget
class EnhancedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const EnhancedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          compact ? AppDesignSystem.spacing16 : AppDesignSystem.spacing32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              padding: EdgeInsets.all(
                compact ? AppDesignSystem.spacing16 : AppDesignSystem.spacing24,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 48 : 64,
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(
              height: compact
                  ? AppDesignSystem.spacing12
                  : AppDesignSystem.spacing24,
            ),
            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: compact
                  ? AppDesignSystem.spacing6
                  : AppDesignSystem.spacing8,
            ),
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6,
                ),
              ),
            ),
            // Action button
            if (onAction != null && actionLabel != null) ...[
              SizedBox(
                height: compact
                    ? AppDesignSystem.spacing12
                    : AppDesignSystem.spacing24,
              ),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing24,
                    vertical: AppDesignSystem.spacing12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Enhanced error state widget
class EnhancedErrorState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const EnhancedErrorState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.actionLabel = 'Retry',
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          compact ? AppDesignSystem.spacing16 : AppDesignSystem.spacing32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with background
            Container(
              padding: EdgeInsets.all(
                compact ? AppDesignSystem.spacing16 : AppDesignSystem.spacing24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 48 : 64,
                color: const Color(0xFFDC2626),
              ),
            ),
            SizedBox(
              height: compact
                  ? AppDesignSystem.spacing12
                  : AppDesignSystem.spacing24,
            ),
            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: compact
                  ? AppDesignSystem.spacing6
                  : AppDesignSystem.spacing8,
            ),
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6,
                ),
              ),
            ),
            // Retry button
            if (onAction != null && actionLabel != null) ...[
              SizedBox(
                height: compact
                    ? AppDesignSystem.spacing12
                    : AppDesignSystem.spacing24,
              ),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing24,
                    vertical: AppDesignSystem.spacing12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Enhanced loading state widget
class EnhancedLoadingState extends StatelessWidget {
  final String? message;
  final bool showBackground;
  final double size;

  const EnhancedLoadingState({
    super.key,
    this.message,
    this.showBackground = false,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(AppDesignSystem.spacing16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
          ),
          child: SkeletonLoading(
            width: size * 2,
            height: size / 2,
            borderRadius: AppDesignSystem.radiusSmall,
          ),
        ),
        if (message != null) ...[
          SizedBox(height: AppDesignSystem.spacing16),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (showBackground) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spacing32),
          child: content,
        ),
      );
    }

    return Center(child: content);
  }
}

/// Enhanced skeleton loader
class EnhancedSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final bool animated;

  const EnhancedSkeleton({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final skeleton = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFE5E7EB),
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDesignSystem.radiusSmall),
      ),
    );

    if (!animated) {
      return skeleton;
    }

    return ShimmerLoading(child: skeleton);
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              colors: [
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFE5E7EB),
                isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.grey.shade100,
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFE5E7EB),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton list builder for loading states
class EnhancedSkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const EnhancedSkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 100,
    this.padding = const EdgeInsets.all(AppDesignSystem.spacing16),
    this.spacing = AppDesignSystem.spacing12,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => EnhancedSkeleton(
        height: itemHeight,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
      ),
    );
  }
}

