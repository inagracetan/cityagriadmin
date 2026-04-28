import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/activity.dart';
import '../../../core/date_formatter.dart';
import '../../../services/firebase_service.dart';

class ActivityTable extends StatelessWidget {
  final List<Activity> activities;
  final FirebaseService fbService;
  final NumberFormat formatCurrency;
  final Function(Activity) onActionTap;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int, bool)? onSort;

  const ActivityTable({
    super.key,
    required this.activities,
    required this.fbService,
    required this.formatCurrency,
    required this.onActionTap,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
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
        ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final isEven = index % 2 == 0;
            return Container(
              color: isEven
                  ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.transparent)
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB)),
              child: _buildRow(context, activity),
            );
          },
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.05),
          ),
        ),
        _buildFooter(context),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: shouldScroll
          ? Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minTableWidth,
                  child: tableContent,
                ),
              ),
            )
          : tableContent,
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double totalPPMPBalance = 0;
    double totalPR = 0;
    double totalPRBalance = 0;
    double totalPOAmount = 0;

    for (var a in activities) {
      final budget = a.totalBudget;
      totalPPMPBalance += budget;
      totalPR += a.prAmount;
      totalPOAmount += a.effectivePOAmount;
    }
    totalPRBalance = totalPPMPBalance - totalPR;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF3F4F6),
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Text(
              'TOTAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                inherit: true,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.5,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
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
                inherit: true,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
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
                inherit: true,
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
                inherit: true,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.colorScheme.primary,
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
                inherit: true,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: isDark
          ? Colors.white.withValues(alpha: 0.02)
          : const Color(0xFFF9FAFB),
      child: Row(
        children: [
          _headerCell(
            context,
            'SECTION/UNIT',
            flex: 2,
            sortIndex: 0,
            alignment: MainAxisAlignment.center,
          ),
          _headerCell(
            context,
            'ACTIVITY',
            flex: 4,
            sortIndex: 2,
            alignment: MainAxisAlignment.center,
          ),
          _headerCell(
            context,
            'PPMP BALANCE',
            flex: 2,
            sortIndex: 12,
            isNumeric: true,
            alignment: MainAxisAlignment.center,
          ),
          _headerCell(
            context,
            'PR',
            flex: 2,
            sortIndex: 13,
            isNumeric: true,
            alignment: MainAxisAlignment.center,
          ),
          _headerCell(
            context,
            'PR BALANCE',
            flex: 2,
            sortIndex: 8,
            isNumeric: true,
            alignment: MainAxisAlignment.center,
          ),
          _headerCell(
            context,
            'PO AMOUNT',
            flex: 2,
            sortIndex: 14,
            isNumeric: true,
            alignment: MainAxisAlignment.center,
          ),
          _headerCell(
            context,
            'STATUS',
            flex: 2,
            sortIndex: 9,
            alignment: MainAxisAlignment.center,
          ),
          _headerCell(
            context,
            'STAFF',
            flex: 2,
            sortIndex: 11,
            alignment: MainAxisAlignment.center,
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
  }) {
    final isSorted = sortColumnIndex == sortIndex;
    final theme = Theme.of(context);

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap:
            sortIndex != null
                ? () => onSort?.call(sortIndex, !sortAscending)
                : null,
        child: Container(
          padding: padding,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: alignment == MainAxisAlignment.center
                    ? Alignment.center
                    : (alignment == MainAxisAlignment.start
                        ? Alignment.centerLeft
                        : Alignment.centerRight),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    inherit: true,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (isSorted)
                Positioned(
                  right: 0,
                  child: Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, Activity activity) {
    final theme = Theme.of(context);
    final isLowBalance =
        activity.approvedBudget > 0 && activity.unexpendedBalance < 1000;

    final now = DateTime.now();
    final currentMonthStr = DateFormat('MMMM').format(now);
    final isDelayed =
        activity.status == 'Planned' &&
        now.day >= 15 &&
        activity.targetDate.contains(currentMonthStr);

    return InkWell(
      onTap: () => onActionTap(activity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isLowBalance
              ? Colors.red.withValues(alpha: 0.02)
              : isDelayed
              ? Colors.orange.withValues(alpha: 0.02)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Section
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    activity.sector,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      inherit: true,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.textTheme.titleSmall?.color,
                    ),
                  ),
                  if (activity.subSector != null)
                    Text(
                      activity.subSector!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        inherit: true,
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.5,
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
                    style: TextStyle(
                      inherit: true,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          activity.location ?? 'No location',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            inherit: true,
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.5,
                            ),
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
                style: TextStyle(
                  inherit: true,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
            // PR
            Expanded(
              flex: 2,
              child: Text(
                formatCurrency.format(activity.prAmount),
                textAlign: TextAlign.right,
                style: TextStyle(
                  inherit: true,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
            // PR Balance
            Expanded(
              flex: 2,
              child: Text(
                formatCurrency.format(activity.totalBudget - activity.prAmount),
                textAlign: TextAlign.right,
                style: TextStyle(
                  inherit: true,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            // PO Amount
            Expanded(
              flex: 2,
              child: Builder(
                builder: (context) {
                  return Text(
                    formatCurrency.format(activity.effectivePOAmount),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      inherit: true,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  );
                },
              ),
            ),
            // Date/Status
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (activity.statusDate != null &&
                        activity.statusDate!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          AppDateFormatter.format(AppDateFormatter.parse(activity.statusDate!) ?? DateTime.now()),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.6,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (activity.isDraft)
                          _statusBadge('DRAFT', isDraft: true),
                        _statusBadge(activity.status),
                      ],
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
                style: TextStyle(
                  inherit: true,
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
            ),
            // Actions
            SizedBox(
              width: 48,
              child: IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
                onPressed: () => onActionTap(activity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, {bool isDraft = false}) {
    final color = isDraft ? Colors.blueGrey.shade600 : _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        status.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          inherit: true,
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Planned':
        return Colors.blue.shade700;
      case 'PR Prepared':
        return Colors.orange.shade700;
      case 'Obre & Abstract Signature':
        return Colors.purple.shade700;
      case 'Obligated':
        return Colors.teal.shade700;
      case 'Completed':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }
}
