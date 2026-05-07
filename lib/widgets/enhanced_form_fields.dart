import 'package:flutter/material.dart';
import '../core/design_system.dart';

/// Enhanced text form field with validation feedback
class EnhancedTextFormField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool required;
  final String? errorText;
  final bool showCounter;
  final void Function()? onEditingComplete;
  final String? tooltip;

  const EnhancedTextFormField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.required = false,
    this.errorText,
    this.showCounter = false,
    this.onEditingComplete,
    this.tooltip,
  });

  @override
  State<EnhancedTextFormField> createState() => _EnhancedTextFormFieldState();
}

class _EnhancedTextFormFieldState extends State<EnhancedTextFormField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Padding(
          padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing8),
          child: Row(
            children: [
              Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              if (widget.required)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDesignSystem.spacing4,
                  ),
                  child: Text(
                    '*',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Text form field with enhanced styling
        _buildTextField(theme, isDark),
      ],
    );
  }

  Widget _buildTextField(ThemeData theme, bool isDark) {
    final textField = TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      focusNode: _focusNode,
      onEditingComplete: widget.onEditingComplete,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.all(AppDesignSystem.spacing12),
                child: widget.prefixIcon,
              )
            : null,
        suffixIcon: widget.suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.all(AppDesignSystem.spacing12),
                child: widget.suffixIcon,
              )
            : null,
        counterText: widget.showCounter ? null : '',
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
          borderSide: const BorderSide(
            color: Color(0xFFDC2626),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
          borderSide: const BorderSide(
            color: Color(0xFFDC2626),
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing16,
          vertical: AppDesignSystem.spacing14,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: textField,
      );
    }
    return textField;
  }
}

/// Enhanced dropdown field
class EnhancedDropdownField<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? hint;
  final bool required;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final String? tooltip;

  const EnhancedDropdownField({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.required = false,
    this.validator,
    this.prefixIcon,
    this.tooltip,
  });

  @override
  State<EnhancedDropdownField<T>> createState() =>
      _EnhancedDropdownFieldState<T>();
}

class _EnhancedDropdownFieldState<T> extends State<EnhancedDropdownField<T>> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing8),
          child: Row(
            children: [
              Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              if (widget.required)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDesignSystem.spacing4,
                  ),
                  child: Text(
                    '*',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildDropdownField(theme, isDark),
      ],
    );
  }

  Widget _buildDropdownField(ThemeData theme, bool isDark) {
    final dropdown = DropdownButtonFormField<T>(
      initialValue: widget.value,
      items: widget.items,
      onChanged: widget.onChanged,
      validator: widget.validator,
      focusNode: _focusNode,
      menuMaxHeight: 250,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.all(AppDesignSystem.spacing12),
                child: widget.prefixIcon,
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing16,
          vertical: AppDesignSystem.spacing14,
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: dropdown,
      );
    }
    return dropdown;
  }
}

/// Enhanced searchable dropdown field that supports typing to filter and search
class EnhancedSearchableDropdownField<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<DropdownMenuEntry<T>> entries;
  final void Function(T?)? onSelected;
  final String? hint;
  final bool required;
  final String? errorText;
  final Widget? prefixIcon;
  final bool enableSearch;
  final bool enableFilter;
  final double? width;
  final TextEditingController? controller;
  final String? tooltip;

  const EnhancedSearchableDropdownField({
    super.key,
    required this.label,
    required this.entries,
    this.value,
    this.onSelected,
    this.hint,
    this.required = false,
    this.errorText,
    this.prefixIcon,
    this.enableSearch = true,
    this.enableFilter = true,
    this.width,
    this.controller,
    this.tooltip,
  });

  @override
  State<EnhancedSearchableDropdownField<T>> createState() =>
      _EnhancedSearchableDropdownFieldState<T>();
}

class _EnhancedSearchableDropdownFieldState<T>
    extends State<EnhancedSearchableDropdownField<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Padding(
          padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing8),
          child: Row(
            children: [
              Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              if (widget.required)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppDesignSystem.spacing4,
                  ),
                  child: Text(
                    '*',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildDropdownMenu(theme, isDark),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              widget.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownMenu(ThemeData theme, bool isDark) {
    final dropdownMenu = Builder(
      builder: (context) {
        final double menuWidth = widget.width ?? MediaQuery.of(context).size.width - 64; // Fallback with some padding

        return DropdownMenu<T>(
          controller: widget.controller,
          initialSelection: widget.value,
          dropdownMenuEntries: widget.entries,
          onSelected: widget.onSelected,
          hintText: widget.hint,
          enableSearch: widget.enableSearch,
          enableFilter: widget.enableFilter,
          width: menuWidth,
          menuHeight: 250,
          leadingIcon: widget.prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing8,
                  ),
                  child: widget.prefixIcon,
                )
              : null,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacing16,
              vertical: AppDesignSystem.spacing14,
            ),
            constraints: BoxConstraints(
              maxHeight: 56,
              minWidth: menuWidth,
            ),
          ),
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF1E293B) : Colors.white,
            ),
            elevation: WidgetStateProperty.all(8),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusLarge),
              ),
            ),
          ),
        );
      },
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: dropdownMenu,
      );
    }
    return dropdownMenu;
  }
}

