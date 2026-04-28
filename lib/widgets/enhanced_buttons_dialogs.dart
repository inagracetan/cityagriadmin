import 'package:flutter/material.dart';

import '../core/design_system.dart';

/// Enhanced button with better accessibility and variants
class EnhancedButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? icon;
  final double? width;
  final double? height;

  const EnhancedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.width,
    this.height,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton> {
  bool _isHovered = false;



  double get _padding {
    return switch (widget.size) {
      ButtonSize.small => AppDesignSystem.spacing12,
      ButtonSize.medium => AppDesignSystem.spacing16,
      ButtonSize.large => AppDesignSystem.spacing20,
    };
  }

  double get _fontSize {
    return switch (widget.size) {
      ButtonSize.small => 13,
      ButtonSize.medium => 15,
      ButtonSize.large => 16,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null && !widget.isLoading) ...[
          widget.icon!,
          const SizedBox(width: AppDesignSystem.spacing8),
        ],
        if (widget.isLoading)
          SizedBox(
            width: _fontSize,
            height: _fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.variant == ButtonVariant.primary
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF2E7D32)),
              ),
            ),
          ),
        if (!widget.isLoading)
          Text(
            widget.label,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
      ],
    );

    if (widget.width != null) {
      buttonContent = SizedBox(width: widget.width, child: buttonContent);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isEnabled && !widget.isLoading
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: AppDesignSystem.durationQuick,
        decoration: BoxDecoration(
          boxShadow: _isHovered && widget.isEnabled && !widget.isLoading
              ? [
                  BoxShadow(
                    color:
                        (widget.variant == ButtonVariant.primary
                                ? (isDark
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF2E7D32))
                                : Colors.black)
                            .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: switch (widget.variant) {
          ButtonVariant.primary => ElevatedButton(
            onPressed: widget.isEnabled && !widget.isLoading
                ? widget.onPressed
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB),
              disabledForegroundColor: isDark
                  ? Colors.white30
                  : const Color(0xFFA1A5B0),
              padding: EdgeInsets.symmetric(
                horizontal: _padding,
                vertical: _padding * 0.75,
              ),
              elevation: _isHovered && widget.isEnabled ? 8 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.radiusLarge,
                ),
              ),
            ),
            child: buttonContent,
          ),
          ButtonVariant.secondary => OutlinedButton(
            onPressed: widget.isEnabled && !widget.isLoading
                ? widget.onPressed
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : const Color(0xFF2E7D32),
              disabledForegroundColor: isDark
                  ? Colors.white30
                  : const Color(0xFFA1A5B0),
              side: BorderSide(
                color: _isHovered && widget.isEnabled && !widget.isLoading
                    ? (isDark
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF2E7D32))
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFE5E7EB)),
                width: 2,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: _padding,
                vertical: _padding * 0.75,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.radiusLarge,
                ),
              ),
            ),
            child: buttonContent,
          ),
          ButtonVariant.tertiary => TextButton(
            onPressed: widget.isEnabled && !widget.isLoading
                ? widget.onPressed
                : null,
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white : const Color(0xFF2E7D32),
              disabledForegroundColor: isDark
                  ? Colors.white30
                  : const Color(0xFFA1A5B0),
              padding: EdgeInsets.symmetric(
                horizontal: _padding * 0.75,
                vertical: _padding * 0.5,
              ),
            ),
            child: buttonContent,
          ),
        },
      ),
    );
  }
}

enum ButtonVariant { primary, secondary, tertiary }

enum ButtonSize { small, medium, large }

/// Enhanced dialog widget
class EnhancedDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<EnhancedButton>? actions;
  final bool dismissible;
  final double? width;
  final VoidCallback? onDismiss;

  const EnhancedDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.dismissible = true,
    this.width,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusXLarge),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width ?? 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDesignSystem.spacing24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.headlineSmall),
                  ),
                  if (dismissible)
                    IconButton(
                      onPressed: () {
                        onDismiss?.call();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFF3F4F6),
                        foregroundColor: isDark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spacing24,
                ),
                child: content,
              ),
            ),
            // Footer with actions
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppDesignSystem.spacing24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(
                            left: entry.key > 0 ? AppDesignSystem.spacing12 : 0,
                          ),
                          child: entry.value,
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<EnhancedButton>? actions,
    bool dismissible = true,
    double? width,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => EnhancedDialog(
        title: title,
        content: content,
        actions: actions,
        dismissible: dismissible,
        width: width,
      ),
    );
  }
}

/// Enhanced snackbar with better styling
class EnhancedSnackBar {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacing8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.radiusSmall,
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacing12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
        ),
        margin: const EdgeInsets.all(AppDesignSystem.spacing16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacing8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.radiusSmall,
                ),
              ),
              child: const Icon(Icons.error, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppDesignSystem.spacing12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
        ),
        margin: const EdgeInsets.all(AppDesignSystem.spacing16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacing8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  AppDesignSystem.radiusSmall,
                ),
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppDesignSystem.spacing12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
        ),
        margin: const EdgeInsets.all(AppDesignSystem.spacing16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
