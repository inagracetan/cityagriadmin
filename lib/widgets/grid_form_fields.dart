import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
export 'grid_section_header.dart';
import '../core/design_system.dart';
import '../core/responsive_utils.dart';
import '../core/currency_formatter.dart';
import '../core/date_formatter.dart';

/// A set of components designed for high-density, "Excel-style" grid forms.
/// These components provide a premium feel with interactive feedback.

class GridFormTheme {
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFFCBD5E1);
  static const Color labelBg = Color(0xFFF8FAFC);
  static const Color textMain = Color(0xFF1E293B);
  static const Color labelText = Color(0xFF475569);
  static const Color rowOdd = Colors.white;
  static const Color rowEven = Color(0xFFF9FBF7);
  static const Color accentGreen = Color(0xFF1B5E20);
  static const Color darkGreen = Color(0xFF064E3B);
  static const Color highlightGreen = Color(0xFFF0FDF4);
  static const Color warningRed = Color(0xFFEF4444);
  static const Color warningBg = Color(0xFFFEF2F2);

  static const Map<String, String> accountCodes = {
    '5-02-01-010': 'Traveling Expenses',
    '5-02-02-010': 'Training Expenses',
    '5-02-03-010': 'Office Supplies Expenses',
    '5-02-03-100': 'Agricultural Supplies Expenses',
    '5-02-99-990': 'Laboratory Supplies Expenses',
    '5-02-03-090': 'Fuel, Oil & Lubricants',
    '5-02-05-020': 'Communication Expenses',
    '5-02-13-030': 'Repairs - Building/Structures',
    '5-02-13-060': 'Repairs - Transportation Equipment',
    '5-02-99-991': 'Other Maintenance and Operating Expenses',
    '5-02-99-992': 'Personnel Development',
    '5-02-99-993': 'Meetings',
  };

  static InputDecoration cellDecoration({
    String? hint,
    bool isCompact = false,
    bool readOnly = false,
    bool hasError = false,
    Widget? prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: isCompact ? 11 : 13,
          color: Colors.black26,
        ),
        isDense: true,
        filled: true,
        fillColor: hasError ? warningBg : (readOnly ? Colors.grey[50] : Colors.white),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 6 : 12,
        ),
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: BorderSide(color: hasError ? warningRed : border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: BorderSide(color: hasError ? warningRed : border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: BorderSide(color: hasError ? warningRed : accentGreen, width: 1.5),
        ),
        errorStyle: const TextStyle(height: 0),
      );
}

class GridStatusBreadcrumbs extends StatelessWidget {
  final String currentStatus;
  final List<String> statuses;
  final ValueChanged<String> onStatusChanged;

  const GridStatusBreadcrumbs({
    super.key,
    required this.currentStatus,
    required this.statuses,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: GridFormTheme.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = currentStatus == status;
            final index = statuses.indexOf(status);
            return Row(
              children: [
                if (index > 0)
                  Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade300),
                GestureDetector(
                  onTap: () => onStatusChanged(status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? GridFormTheme.accentGreen.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? GridFormTheme.accentGreen : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? GridFormTheme.accentGreen : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class GridStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  final List<IconData> icons;

  const GridStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(
        color: GridFormTheme.labelBg,
        border: Border(bottom: BorderSide(color: GridFormTheme.border)),
      ),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final label = entry.value;
          final isCompleted = idx < currentStep;
          final isActive = idx == currentStep;
          final color = isActive ? GridFormTheme.accentGreen : (isCompleted ? GridFormTheme.darkGreen : Colors.grey.shade400);

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive ? GridFormTheme.accentGreen : (isCompleted ? GridFormTheme.accentGreen.withValues(alpha: 0.1) : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : icons[idx],
                        size: 16,
                        color: isActive ? Colors.white : color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (idx < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 18),
                      color: isCompleted ? GridFormTheme.accentGreen : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class GridRow extends StatefulWidget {
  final String label;
  final String fieldLabel;
  final Widget child;
  final bool isOdd;
  final double labelWidth;
  final bool showBottomBorder;

  final Widget? icon;
  final String? helpText;

  const GridRow({
    super.key,
    required this.label,
    required this.fieldLabel,
    required this.child,
    this.isOdd = true,
    this.labelWidth = 200,
    this.showBottomBorder = true,
    this.icon,
    this.helpText,
  });

  @override
  State<GridRow> createState() => _GridRowState();
}

class _GridRowState extends State<GridRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveUtils.isMobile(context);
    final bg = widget.isOdd ? GridFormTheme.rowOdd : GridFormTheme.rowEven;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          border: widget.showBottomBorder
              ? const Border(
                  bottom: BorderSide(color: GridFormTheme.border, width: 0.8),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GridFormTheme.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: GridFormTheme.accentGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.fieldLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: GridFormTheme.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            widget.child,
          ],
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDesignSystem.durationQuick,
        decoration: BoxDecoration(
          color: _isHovered
              ? GridFormTheme.highlightGreen
              : bg,
          border: widget.showBottomBorder
              ? const Border(
                  bottom: BorderSide(color: GridFormTheme.border, width: 0.8),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Change from stretch to center to avoid IntrinsicHeight if possible, but actually we want it to look good.
          // Let's keep the Row structure but consider removing IntrinsicHeight if children have viewports.
          children: [
            // Row identifier (Excel style header)
            Container(
              width: 42,
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isHovered ? GridFormTheme.accentGreen.withValues(alpha: 0.1) : GridFormTheme.labelBg,
                border: const Border(
                  right: BorderSide(color: GridFormTheme.border, width: 0.8),
                ),
              ),
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _isHovered ? GridFormTheme.accentGreen : GridFormTheme.labelText.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Label
            Container(
              width: widget.labelWidth,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  right: BorderSide(color: GridFormTheme.border, width: 0.8),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.fieldLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: GridFormTheme.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.helpText != null)
                    Tooltip(
                      message: widget.helpText!,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: GridFormTheme.textMain.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.info_outline, size: 14, color: GridFormTheme.labelText),
                      ),
                    ),
                ],
              ),
            ),
            // Input widget
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridDualRow extends StatefulWidget {
  final String label;
  final String fieldLabel1;
  final Widget child1;
  final String fieldLabel2;
  final Widget child2;
  final bool isOdd;
  final double labelWidth;
  final bool showBottomBorder;
  final Widget? icon;
  final String? helpText1;
  final String? helpText2;

  const GridDualRow({
    super.key,
    required this.label,
    required this.fieldLabel1,
    required this.child1,
    required this.fieldLabel2,
    required this.child2,
    this.isOdd = true,
    this.labelWidth = 140,
    this.showBottomBorder = true,
    this.icon,
    this.helpText1,
    this.helpText2,
  });

  @override
  State<GridDualRow> createState() => _GridDualRowState();
}

class _GridDualRowState extends State<GridDualRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveUtils.isMobile(context);
    final bg = widget.isOdd ? GridFormTheme.rowOdd : GridFormTheme.rowEven;

    if (isMobile) {
      return Column(
        children: [
          GridRow(
            label: widget.label,
            fieldLabel: widget.fieldLabel1,
            isOdd: widget.isOdd,
            showBottomBorder: false,
            child: widget.child1,
          ),
          GridRow(
            label: '',
            fieldLabel: widget.fieldLabel2,
            isOdd: widget.isOdd,
            showBottomBorder: widget.showBottomBorder,
            child: widget.child2,
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDesignSystem.durationQuick,
        decoration: BoxDecoration(
          color: _isHovered ? GridFormTheme.highlightGreen : bg,
          border: widget.showBottomBorder
              ? const Border(
                  bottom: BorderSide(color: GridFormTheme.border, width: 0.8),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Row identifier
            Container(
              width: 42,
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isHovered ? GridFormTheme.accentGreen.withValues(alpha: 0.1) : GridFormTheme.labelBg,
                border: const Border(
                  right: BorderSide(color: GridFormTheme.border, width: 0.8),
                ),
              ),
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _isHovered ? GridFormTheme.accentGreen : GridFormTheme.labelText.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Field 1 Label
            Container(
              width: widget.labelWidth,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: GridFormTheme.border, width: 0.8)),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.fieldLabel1,
                      style: GoogleFonts.inter(fontSize: 13, color: GridFormTheme.textMain, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (widget.helpText1 != null)
                    Tooltip(
                      message: widget.helpText1!,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.info_outline, size: 12, color: GridFormTheme.labelText),
                      ),
                    ),
                ],
              ),
            ),
            // Field 1 Input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: GridFormTheme.border, width: 0.8)),
                ),
                child: widget.child1,
              ),
            ),
            // Field 2 Label
            Container(
              width: widget.labelWidth,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: GridFormTheme.border, width: 0.8)),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.fieldLabel2,
                      style: GoogleFonts.inter(fontSize: 13, color: GridFormTheme.textMain, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (widget.helpText2 != null)
                    Tooltip(
                      message: widget.helpText2!,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.info_outline, size: 12, color: GridFormTheme.labelText),
                      ),
                    ),
                ],
              ),
            ),
            // Field 2 Input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: widget.child2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final int maxLines;
  final bool readOnly;
  final bool isCompact;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool hasError;
  final String? tooltip;

  const GridTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.hint,
    this.maxLines = 1,
    this.readOnly = false,
    this.isCompact = false,
    this.hasError = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.tooltip,
  });

  @override
  State<GridTextField> createState() => _GridTextFieldState();
}

class _GridTextFieldState extends State<GridTextField> {
  late TextEditingController _effectiveController;
  bool _isLocalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _effectiveController = widget.controller!;
    } else {
      _effectiveController = TextEditingController(text: widget.initialValue ?? '');
      _isLocalController = true;
    }
  }

  @override
  void didUpdateWidget(GridTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_isLocalController) {
        _effectiveController.dispose();
      }
      if (widget.controller != null) {
        _effectiveController = widget.controller!;
        _isLocalController = false;
      } else {
        _effectiveController = TextEditingController(text: widget.initialValue ?? '');
        _isLocalController = true;
      }
    } else if (_isLocalController && widget.initialValue != oldWidget.initialValue) {
      if (widget.initialValue != null && widget.initialValue != _effectiveController.text) {
        _effectiveController.text = widget.initialValue!;
      }
    }
  }

  @override
  void dispose() {
    if (_isLocalController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textField = TextFormField(
      controller: _effectiveController,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      style: GoogleFonts.inter(
        fontSize: widget.isCompact ? 12 : 14,
        color: GridFormTheme.textMain,
        fontWeight: FontWeight.w500,
      ),
      decoration: GridFormTheme.cellDecoration(
        hint: widget.hint,
        readOnly: widget.readOnly,
        isCompact: widget.isCompact,
        hasError: widget.hasError,
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

class GridCurrencyField extends StatefulWidget {
  final TextEditingController? controller;
  final double? initialValue;
  final String? hint;
  final bool readOnly;
  final bool isPO;
  final bool isCompact;
  final void Function(double)? onChanged;
  final void Function(String)? onSubmitted;

  final bool hasError;
  final String? tooltip;

  const GridCurrencyField({
    super.key,
    this.controller,
    this.initialValue,
    this.hint,
    this.readOnly = false,
    this.isPO = false,
    this.isCompact = false,
    this.hasError = false,
    this.onChanged,
    this.onSubmitted,
    this.tooltip,
  });

  @override
  State<GridCurrencyField> createState() => _GridCurrencyFieldState();
}

class _GridCurrencyFieldState extends State<GridCurrencyField> {
  late TextEditingController _effectiveController;
  bool _isLocalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _effectiveController = widget.controller!;
    } else {
      final initialText = widget.initialValue != null
          ? CurrencyInputFormatter.formatDouble(widget.initialValue!)
          : '';
      _effectiveController = TextEditingController(text: initialText);
      _isLocalController = true;
    }
  }

  @override
  void didUpdateWidget(GridCurrencyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_isLocalController) {
        _effectiveController.dispose();
      }
      if (widget.controller != null) {
        _effectiveController = widget.controller!;
        _isLocalController = false;
      } else {
        final initialText = widget.initialValue != null
            ? CurrencyInputFormatter.formatDouble(widget.initialValue!)
            : '';
        _effectiveController = TextEditingController(text: initialText);
        _isLocalController = true;
      }
    } else if (_isLocalController && widget.initialValue != oldWidget.initialValue) {
      if (widget.initialValue != null) {
        final newText = CurrencyInputFormatter.formatDouble(widget.initialValue!);
        if (newText != _effectiveController.text) {
          _effectiveController.text = newText;
        }
      }
    }
  }

  @override
  void dispose() {
    if (_isLocalController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textField = TextFormField(
      controller: _effectiveController,
      readOnly: widget.readOnly,
      textAlign: TextAlign.end,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [CurrencyInputFormatter()],
      onChanged: (v) {
        if (widget.onChanged != null) {
          widget.onChanged!(CurrencyInputFormatter.parse(v));
        }
      },
      style: GoogleFonts.inter(
        fontSize: widget.isCompact ? 12 : 14,
        color: widget.isPO
            ? const Color(0xFF1565C0)
            : (widget.readOnly ? Colors.grey[700] : GridFormTheme.darkGreen),
        fontWeight: FontWeight.bold,
      ),
      decoration: GridFormTheme.cellDecoration(
        hint: widget.hint ?? '0.00',
        readOnly: widget.readOnly,
        isCompact: widget.isCompact,
        hasError: widget.hasError,
        prefix: Padding(
          padding: EdgeInsets.only(
            left: widget.isCompact ? 8 : 12,
            right: widget.isCompact ? 4 : 8,
            top: widget.isCompact ? 6 : 10,
            bottom: widget.isCompact ? 6 : 10,
          ),
          child: Text(
            'PHP',
            style: TextStyle(
              color: widget.hasError ? GridFormTheme.warningRed : GridFormTheme.accentGreen.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              fontSize: widget.isCompact ? 10 : 11,
            ),
          ),
        ),
      ).copyWith(
        prefixIcon: widget.isPO
            ? Icon(
                Icons.shopping_cart_outlined,
                size: widget.isCompact ? 12 : 14,
                color: const Color(0xFF1565C0),
              )
            : null,
      ),
      onTapOutside: (_) {
        if (_effectiveController.text.isNotEmpty) {
          _effectiveController.text = CurrencyInputFormatter.formatDouble(
            CurrencyInputFormatter.parse(_effectiveController.text),
          );
        }
      },
      onFieldSubmitted: (val) {
        if (val.isNotEmpty) {
          _effectiveController.text = CurrencyInputFormatter.formatDouble(
            CurrencyInputFormatter.parse(val),
          );
        }
        if (widget.onSubmitted != null) widget.onSubmitted!(val);
      },
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

class GridDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> options;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String Function(T)? labelBuilder;
  final bool isCompact;
  final String? tooltip;

  const GridDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.labelBuilder,
    this.isCompact = false,
    this.tooltip,
  });

  @override
  State<GridDropdown<T>> createState() => _GridDropdownState<T>();
}

class _GridDropdownState<T> extends State<GridDropdown<T>> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getLabel(widget.value));
  }

  String _getLabel(T? value) {
    if (value == null) return '';
    return widget.labelBuilder?.call(value) ?? value.toString();
  }

  @override
  void didUpdateWidget(GridDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final newLabel = _getLabel(widget.value);
      if (_controller.text != newLabel) {
        _controller.text = newLabel;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownMenu<T>(
      controller: _controller,
      initialSelection: widget.value,
      enableSearch: true,
      enableFilter: true,
      menuHeight: 300,
      expandedInsets: EdgeInsets.zero,
      hintText: widget.hint,
      textStyle: GoogleFonts.inter(
        fontSize: widget.isCompact ? 12 : 14,
        color: GridFormTheme.textMain,
        fontWeight: FontWeight.w500,
      ),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 10 : 12,
          vertical: widget.isCompact ? 8 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.accentGreen, width: 1.5),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dropdownMenuEntries: widget.options.map((opt) {
        return DropdownMenuEntry<T>(
          value: opt,
          label: widget.labelBuilder?.call(opt) ?? (opt?.toString() ?? ''),
        );
      }).toList(),
      onSelected: widget.onChanged,
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

class GridDateField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final bool isCompact;
  final void Function(String)? onChanged;
  final String? tooltip;

  const GridDateField({
    super.key,
    this.controller,
    this.initialValue,
    this.hint,
    this.isCompact = false,
    this.onChanged,
    this.tooltip,
  });

  @override
  State<GridDateField> createState() => _GridDateFieldState();
}

class _GridDateFieldState extends State<GridDateField> {
  late TextEditingController _effectiveController;
  bool _isLocalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _effectiveController = widget.controller!;
    } else {
      _effectiveController = TextEditingController(text: widget.initialValue ?? '');
      _isLocalController = true;
    }
  }

  @override
  void didUpdateWidget(GridDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_isLocalController) {
        _effectiveController.dispose();
      }
      if (widget.controller != null) {
        _effectiveController = widget.controller!;
        _isLocalController = false;
      } else {
        _effectiveController = TextEditingController(text: widget.initialValue ?? '');
        _isLocalController = true;
      }
    } else if (_isLocalController && widget.initialValue != oldWidget.initialValue) {
      if (widget.initialValue != null && widget.initialValue != _effectiveController.text) {
        _effectiveController.text = widget.initialValue!;
      }
    }
  }

  @override
  void dispose() {
    if (_isLocalController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textField = TextFormField(
      controller: _effectiveController,
      readOnly: true,
      style: GoogleFonts.inter(
        fontSize: widget.isCompact ? 12 : 14,
        color: GridFormTheme.textMain,
        fontWeight: FontWeight.w500,
      ),
      decoration: GridFormTheme.cellDecoration(
        hint: widget.hint ?? (widget.isCompact ? 'Date...' : 'Select Date'),
        isCompact: widget.isCompact,
        suffix: Icon(
          Icons.calendar_today_rounded,
          size: widget.isCompact ? 14 : 16,
          color: GridFormTheme.accentGreen.withValues(alpha: 0.6),
        ),
      ),
      onTap: () async {
        final currentText = _effectiveController.text;
        final initialDate = DateFormatter.parse(currentText) ?? DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: GridFormTheme.accentGreen,
                  onPrimary: Colors.white,
                  onSurface: GridFormTheme.darkGreen,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          final formatted = DateFormatter.format(date);
          setState(() {
            _effectiveController.text = formatted;
          });
          if (widget.onChanged != null) {
            widget.onChanged!(formatted);
          }
        }
      },
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

class GridSupplierField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> availableSuppliers;
  final bool allowsMultiple;
  final bool isCompact;
  final String? tooltip;

  const GridSupplierField({
    super.key,
    required this.controller,
    required this.availableSuppliers,
    this.allowsMultiple = false,
    this.isCompact = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownMenu<String>(
      initialSelection:
          controller.text.isEmpty || !availableSuppliers.contains(controller.text)
          ? ''
          : controller.text,
      controller: controller,
      enableSearch: true,
      enableFilter: true,
      menuHeight: 300,
      expandedInsets: EdgeInsets.zero,
      hintText: 'Select or type supplier...',
      textStyle: GoogleFonts.inter(
        fontSize: isCompact ? 12 : 13,
        color: GridFormTheme.textMain,
        fontWeight: FontWeight.w500,
      ),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 12,
          vertical: isCompact ? 8 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.accentGreen, width: 1.5),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dropdownMenuEntries: [
        const DropdownMenuEntry(value: '', label: 'Choose a supplier'),
        ...availableSuppliers.map((s) => DropdownMenuEntry(value: s, label: s)),
      ],
      onSelected: (val) {
        if (val != null && val.isNotEmpty) {
          if (allowsMultiple) {
            if (!controller.text.contains(val)) {
              if (controller.text.isEmpty) {
                controller.text = val;
              } else {
                controller.text = "${controller.text.trim()}, $val";
              }
            }
          } else {
            controller.text = val;
          }
        }
      },
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: dropdown,
      );
    }
    return dropdown;
  }
}

class GridBreakdownDropdown<T> extends StatefulWidget {
  final T? value;
  final List<T> options;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String? tooltip;

  const GridBreakdownDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.tooltip,
  });

  @override
  State<GridBreakdownDropdown<T>> createState() => _GridBreakdownDropdownState<T>();
}

class _GridBreakdownDropdownState<T> extends State<GridBreakdownDropdown<T>> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(GridBreakdownDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final newLabel = widget.value?.toString() ?? '';
      if (_controller.text != newLabel) {
        _controller.text = newLabel;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownMenu<T>(
      controller: _controller,
      initialSelection: widget.value,
      enableSearch: true,
      enableFilter: true,
      menuHeight: 250,
      expandedInsets: EdgeInsets.zero,
      hintText: widget.hint,
      textStyle: GoogleFonts.inter(
        fontSize: 12,
        color: GridFormTheme.textMain,
        fontWeight: FontWeight.w500,
      ),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: GridFormTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: GridFormTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: GridFormTheme.accentGreen, width: 1.5),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      dropdownMenuEntries: widget.options.map((opt) {
        return DropdownMenuEntry<T>(value: opt, label: opt?.toString() ?? '');
      }).toList(),
      onSelected: widget.onChanged,
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

class GridBarcodeField extends StatelessWidget {
  final TextEditingController controller;
  final Widget Function(String)? barcodeBuilder;
  final bool isCompact;
  final String? tooltip;

  const GridBarcodeField({
    super.key,
    required this.controller,
    this.barcodeBuilder,
    this.isCompact = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridTextField(
          controller: controller,
          isCompact: isCompact,
          tooltip: tooltip,
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            final data = value.text.trim();
            if (data.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: GridFormTheme.border),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              child: barcodeBuilder?.call(data) ?? const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }
}

/// A specialized field that allows selecting from a list or typing a custom value.
class GridAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> options;
  final String? hint;
  final bool isCompact;
  final String? tooltip;

  const GridAutocompleteField({
    super.key,
    required this.controller,
    required this.options,
    this.hint,
    this.isCompact = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownMenu<String>(
      initialSelection:
          controller.text.isEmpty || !options.contains(controller.text)
              ? null
              : controller.text,
      controller: controller,
      enableSearch: true,
      enableFilter: true,
      menuHeight: 300,
      expandedInsets: EdgeInsets.zero,
      hintText: hint,
      textStyle: GoogleFonts.inter(
        fontSize: isCompact ? 12 : 14,
        color: GridFormTheme.textMain,
        fontWeight: FontWeight.w500,
      ),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 12,
          vertical: isCompact ? 8 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.accentGreen, width: 1.5),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dropdownMenuEntries: options.map((s) => DropdownMenuEntry(value: s, label: s)).toList(),
      onSelected: (val) {
        if (val != null) {
          controller.text = val;
        }
      },
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: dropdown,
      );
    }
    return dropdown;
  }
}

class GridAccountCodePicker extends StatelessWidget {
  final TextEditingController controller;
  final bool isCompact;
  final String hint;
  final String? tooltip;

  const GridAccountCodePicker({
    super.key,
    required this.controller,
    required this.hint,
    this.isCompact = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final options = GridFormTheme.accountCodes.entries.toList();

    final dropdown = DropdownMenu<String>(
      initialSelection: controller.text.isEmpty ? null : controller.text,
      controller: controller,
      enableSearch: true,
      enableFilter: true,
      menuHeight: 300,
      expandedInsets: EdgeInsets.zero,
      hintText: hint,
      textStyle: GoogleFonts.inter(
        fontSize: isCompact ? 12 : 13,
        color: GridFormTheme.textMain,
        fontWeight: FontWeight.w500,
      ),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 12,
          vertical: isCompact ? 8 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
          borderSide: const BorderSide(color: GridFormTheme.accentGreen, width: 1.5),
        ),
      ),
      dropdownMenuEntries: options.map((entry) {
        return DropdownMenuEntry<String>(
          value: entry.key,
          label: '${entry.key} - ${entry.value}',
        );
      }).toList(),
      onSelected: (val) {
        if (val != null) controller.text = val;
      },
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: dropdown,
      );
    }
    return dropdown;
  }
}

class GridMonthGrid extends StatelessWidget {
  final Set<String> selectedMonths;
  final ValueChanged<String> onToggle;

  const GridMonthGrid({
    super.key,
    required this.selectedMonths,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec'
    ];

    const fullMonths = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridFormTheme.border),
      ),
      child: Table(
        children: List.generate(2, (rowIdx) {
          return TableRow(
            children: List.generate(6, (colIdx) {
              final idx = rowIdx * 6 + colIdx;
              final isSelected = selectedMonths.contains(fullMonths[idx]);
              return Padding(
                padding: const EdgeInsets.all(2.0),
                child: GestureDetector(
                  onTap: () => onToggle(fullMonths[idx]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? GridFormTheme.accentGreen : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? GridFormTheme.accentGreen : GridFormTheme.border,
                      ),
                    ),
                    child: Text(
                      months[idx],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? Colors.white : GridFormTheme.textMain,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}


