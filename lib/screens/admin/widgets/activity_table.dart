import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/activity.dart';
import '../../../core/date_formatter.dart';
import '../../../services/firebase_service.dart';
import '../../../core/design_system.dart';
import '../../../core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityTable extends StatelessWidget {
  final List<Activity> activities;
  final FirebaseService fbService;
  final NumberFormat formatCurrency;
  final Function(Activity) onActionTap;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int, bool)? onSort;
  final Set<String> selectedIds;
  final Function(String, bool) onSelectionChanged;
  final Function(bool) onSelectAll;
  final double totalPPMPBalance;
  final double totalPR;
  final double totalPOAmount;


  const ActivityTable({
    super.key,
    required this.activities,
    required this.fbService,
    required this.formatCurrency,
    required this.onActionTap,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onSelectAll,
    required this.totalPPMPBalance,
    required this.totalPR,
    required this.totalPOAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final minTableWidth = 1100.0;
    final shouldScroll = screenWidth < minTableWidth;

    Widget tableContent = Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isEven = index % 2 == 0;
              return Container(
                decoration: BoxDecoration(
                  color: isEven
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.transparent)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF9FAFB)),
                ),
                child: _buildRow(context, activity),
              );
            },
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.05),
            ),
          ),
        ),
        _buildFooter(context),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: isDark ? Slate.shade800 : Slate.shade200,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: shouldScroll
          ? LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: minTableWidth,
                        minHeight: constraints.maxHeight,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: tableContent,
                    ),
                  ),
                );
              },
            )
          : tableContent,
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalPRBalance = totalPPMPBalance - totalPR;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Slate.shade900
            : Slate.shade50,
        border: Border(
          top: BorderSide(color: isDark ? Slate.shade800 : Slate.shade200),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 48), // Checkbox spacer
          Expanded(
            flex: 6,
            child: Text(
              'GRAND TOTALS',
              style: AppDesignSystem.labelMedium.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isDark ? Colors.white70 : Slate.shade700,
              ),
            ),
          ),
          // PPMP Balance Total
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency.format(totalPPMPBalance),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white60 : Slate.shade600,
              ),
            ),
          ),
          // PR Total
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency.format(totalPR),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          // PR Balance Total
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency.format(totalPRBalance),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
          ),
          // PO Amount Total
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency.format(totalPOAmount),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.teal.shade700,
              ),
            ),
          ),
          // Spacer for Status, Staff, and Actions
          const Expanded(flex: 4, child: SizedBox()),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? Slate.shade900 : Slate.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Checkbox(
              value: activities.isNotEmpty && selectedIds.length == activities.length,
              onChanged: (val) => onSelectAll(val ?? false),
              activeColor: AppColors.primary,
              side: const BorderSide(color: Colors.white54, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          _headerCell(
            context,
            'UNIT',
            flex: 2,
            sortIndex: 0,
            alignment: MainAxisAlignment.center,
            isHeader: true,
          ),
          _headerCell(
            context,
            'ACTIVITY NAME',
            flex: 4,
            sortIndex: 2,
            alignment: MainAxisAlignment.center,
            isHeader: true,
          ),
          _headerCell(
            context,
            'PPMP BUDGET',
            flex: 2,
            sortIndex: 12,
            isNumeric: true,
            alignment: MainAxisAlignment.end,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            isHeader: true,
          ),
          _headerCell(
            context,
            'PR AMOUNT',
            flex: 2,
            sortIndex: 13,
            isNumeric: true,
            alignment: MainAxisAlignment.end,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            isHeader: true,
          ),
          _headerCell(
            context,
            'BALANCE',
            flex: 2,
            sortIndex: 8,
            isNumeric: true,
            alignment: MainAxisAlignment.end,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            isHeader: true,
          ),
          _headerCell(
            context,
            'PO AMOUNT',
            flex: 2,
            sortIndex: 14,
            isNumeric: true,
            alignment: MainAxisAlignment.end,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            isHeader: true,
          ),
          _headerCell(
            context,
            'DATE',
            flex: 2,
            sortIndex: 15,
            alignment: MainAxisAlignment.center,
            isHeader: true,
          ),
          _headerCell(
            context,
            'RESPONSIBLE',
            flex: 2,
            sortIndex: 11,
            alignment: MainAxisAlignment.center,
            isHeader: true,
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _headerCell(
    BuildContext context,
    String label, {
    int flex = 1,
    int? sortIndex,
    bool isNumeric = false,
    MainAxisAlignment alignment = MainAxisAlignment.center,
    EdgeInsets? padding,
    bool isHeader = false,
  }) {
    final isSorted = sortColumnIndex == sortIndex;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: sortIndex != null
            ? () => onSort?.call(sortIndex, !sortAscending)
            : null,
        child: Container(
          padding: padding,
          child: Align(
            alignment: alignment == MainAxisAlignment.center
                ? Alignment.center
                : (alignment == MainAxisAlignment.start
                    ? Alignment.centerLeft
                    : Alignment.centerRight),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: alignment == MainAxisAlignment.start
                        ? TextAlign.left
                        : (alignment == MainAxisAlignment.end
                            ? TextAlign.right
                            : TextAlign.center),
                    style: AppDesignSystem.labelSmall.copyWith(
                      color: isHeader ? Colors.white : Slate.shade500,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (isSorted) ...[
                  const SizedBox(width: 4),
                  Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: isHeader ? Colors.white : AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, Activity activity) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLowBalance = activity.isLowBalance;

    final now = DateTime.now();
    final currentMonthStr = DateFormat('MMMM').format(now);
    final isDelayed =
        activity.status == 'Planned' &&
        now.day >= 15 &&
        activity.targetDate.contains(currentMonthStr);

    return InkWell(
      onTap: () => onActionTap(activity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: isLowBalance
              ? Colors.red.withValues(alpha: 0.04)
              : isDelayed
              ? Colors.orange.withValues(alpha: 0.04)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isLowBalance 
                ? Colors.red 
                : (isDelayed ? Colors.orange : Colors.transparent),
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Checkbox(
                value: selectedIds.contains(activity.id),
                onChanged: (val) => onSelectionChanged(activity.id, val ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            // Section
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDark ? Colors.white10 : Slate.shade200),
                    ),
                    child: Text(
                      activity.sector,
                      textAlign: TextAlign.center,
                      style: AppDesignSystem.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Slate.shade700,
                      ),
                    ),
                  ),
                  if (activity.subSector != null && activity.subSector!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        activity.subSector!,
                        textAlign: TextAlign.center,
                        style: AppDesignSystem.bodySmall.copyWith(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Slate.shade400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Activity
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    activity.activityName,
                    textAlign: TextAlign.center,
                    style: AppDesignSystem.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Slate.shade800,
                      height: 1.2,
                    ),
                  ),
                  _buildValidationBadges(activity),

                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: isDark ? Colors.white24 : Slate.shade400,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          activity.location ?? 'No location',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white30 : Slate.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // PPMP Balance
            Expanded(
              flex: 2,
              child: Text(
                formatCurrency.format(activity.totalBudget),
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Slate.shade500,
                ),
              ),
            ),
            // PR
            Expanded(
              flex: 2,
              child: Text(
                formatCurrency.format(activity.effectivePRAmount),
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
            // PR Balance
            Expanded(
              flex: 2,
              child: Text(
                formatCurrency.format(activity.ppmpBalanceCalculated),
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            // PO Amount
            Expanded(
              flex: 2,
              child: Text(
                formatCurrency.format(activity.effectivePOAmount),
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (activity.statusDate != null &&
                        activity.statusDate!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormatter.format(
                            DateFormatter.parse(activity.statusDate!) ??
                                DateTime.now(),
                          ),
                          textAlign: TextAlign.center,
                          style: AppDesignSystem.labelSmall.copyWith(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Staff
            Expanded(
              flex: 2,
              child: Text(
                activity.responsiblePerson,
                textAlign: TextAlign.center,
                style: AppDesignSystem.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Slate.shade700,
                ),
              ),
            ),
            // Actions
            SizedBox(
              width: 48,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark ? Colors.white54 : Slate.shade500,
                  ),
                ),
                onPressed: () => onActionTap(activity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationBadges(Activity activity) {
    final List<Widget> badges = [];
    if (activity.hasNoBudget || activity.isRodenticideWarning) {
      badges.add(_badge('NO BUDGET', Colors.red));
    }
    if (activity.isRecanvasWarning) {
      badges.add(_badge('RECANVAS', Colors.orange));
    }
    if (activity.isOverObligated) {
      badges.add(_badge('OVER-OBLIGATED', Colors.orange));
    }
    if (activity.isTimelineVariance) {
      badges.add(_badge('TIMELINE VARIANCE', Colors.purple));
    }
    if (badges.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: badges,
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

}
