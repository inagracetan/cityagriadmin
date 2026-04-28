import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/app_colors.dart';

class AgriUI {
  /// Custom success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Custom error snackbar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Beautiful empty state widget
  static Widget emptyState({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 64,
                      color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      inherit: true,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      inherit: true,
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  if (onAction != null && actionLabel != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: onAction,
                      child: Text(actionLabel),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shimmer loading for cards
  static Widget cardShimmer({int count = 3}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade200,
            highlightColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade50,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Skeleton for Table
  static Widget tableShimmer() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Shimmer.fromColors(
          baseColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade200,
          highlightColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          child: Column(
            children: List.generate(
              5,
              (index) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AgriHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final BoxBorder? border;
  final double hoverScale;

  const AgriHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.padding,
    this.color,
    this.boxShadow,
    this.border,
    this.hoverScale = 1.015,
  });

  @override
  State<AgriHoverCard> createState() => _AgriHoverCardState();
}

class _AgriHoverCardState extends State<AgriHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        transform: Matrix4.diagonal3Values(
          _isHovered ? widget.hoverScale : 1.0,
          _isHovered ? widget.hoverScale : 1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          color: widget.color ?? theme.cardColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: _isHovered && widget.color == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.cardColor,
                    isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : theme.colorScheme.primary.withValues(alpha: 0.02),
                  ],
                )
              : null,
          boxShadow:
              widget.boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark
                        ? (_isHovered ? 0.4 : 0.25)
                        : (_isHovered ? 0.08 : 0.04),
                  ),
                  blurRadius: _isHovered ? 30 : 20,
                  offset: Offset(0, _isHovered ? 12 : 8),
                  spreadRadius: _isHovered ? -2 : -4,
                ),
              ],
          border:
              widget.border ??
              Border.all(
                color: _isHovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade100,
                width: 1,
              ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovering) {
              if (mounted) setState(() => _isHovered = hovering);
            },
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.05),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
