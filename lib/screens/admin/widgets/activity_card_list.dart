import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/activity.dart';
import '../../../services/firebase_service.dart';
import '../../../widgets/agri_ui.dart';

class ActivityCardList extends StatelessWidget {
  final List<Activity> activities;
  final FirebaseService fbService;
  final NumberFormat formatCurrency;
  final Function(Activity) onActionTap;

  const ActivityCardList({
    super.key,
    required this.activities,
    required this.fbService,
    required this.formatCurrency,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isLowBalance =
            activity.approvedBudget > 0 && activity.unexpendedBalance < 1000;

        final now = DateTime.now();
        final currentMonthStr = DateFormat('MMMM').format(now);
        final isDelayed =
            activity.status == 'Planned' &&
            now.day >= 15 &&
            activity.targetDate.contains(currentMonthStr);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AgriHoverCard(
            onTap: () => onActionTap(activity),
            borderRadius: 20,
            padding: EdgeInsets.zero,
            border: Border.all(
              color: isDelayed
                  ? Colors.orange.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: 0.05),
              width: isDelayed ? 1.5 : 1,
            ),
            child: ExpansionTile(
              shape: const Border(),
              backgroundColor: isDelayed
                  ? Colors.orange.withValues(alpha: 0.02)
                  : Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              tilePadding: const EdgeInsets.all(20),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statusBadge(activity.status),
                      const Spacer(),
                      if (activity.isDraft)
                        _miniBadge('DRAFT', Colors.blueGrey),
                      if (isDelayed) _miniBadge('DELAYED', Colors.orange),
                      if (isLowBalance) _miniBadge('LOW BALANCE', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 12),
                    Text(
                      activity.activityName,
                      style: TextStyle(
                        inherit: true,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: theme.textTheme.titleLarge?.color,
                        height: 1.2,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activity.sector,
                        style: TextStyle(
                          inherit: true,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 450) {
                        return Column(
                          children: [
                            _metricRow(
                              context,
                              'PPMP BALANCE',
                              formatCurrency.format(activity.ppmpBalance),
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                              fullWidth: true,
                            ),
                            const SizedBox(height: 12),
                            _metricRow(
                              context,
                              'PR',
                              formatCurrency.format(activity.prAmount),
                              color: Colors.orange.shade700,
                              fullWidth: true,
                            ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final breakdownTotal = activity.breakdown.fold<double>(0, (sum, item) => sum + item.amount);
                                final displayAmt = breakdownTotal > 0 ? breakdownTotal : activity.actualExpenditure;
                                return _metricRow(
                                  context,
                                  'PO AMOUNT',
                                  formatCurrency.format(displayAmt),
                                  color: Colors.teal.shade700,
                                  fullWidth: true,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _metricRow(
                              context,
                              'BALANCE',
                              formatCurrency.format(activity.unexpendedBalance),
                              color: isLowBalance ? Colors.red : theme.colorScheme.primary,
                              fullWidth: true,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _metricRow(
                              context,
                              'PPMP BALANCE',
                              formatCurrency.format(activity.ppmpBalance),
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                          Expanded(
                            child: _metricRow(
                              context,
                              'PR',
                              formatCurrency.format(activity.prAmount),
                              color: Colors.orange.shade700,
                            ),
                          ),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final breakdownTotal = activity.breakdown.fold<double>(0, (sum, item) => sum + item.amount);
                                final displayAmt = breakdownTotal > 0 ? breakdownTotal : activity.actualExpenditure;
                                return _metricRow(
                                  context,
                                  'PO AMOUNT',
                                  formatCurrency.format(displayAmt),
                                  color: Colors.teal.shade700,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _metricRow(
                              context,
                              'BALANCE',
                              formatCurrency.format(activity.unexpendedBalance),
                              color: isLowBalance ? Colors.red : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                ],
              ),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 32),
                      _detailTile(
                        context,
                        Icons.location_on_outlined,
                        'Location',
                        activity.location ?? 'Global',
                      ),
                      _detailTile(
                        context,
                        Icons.person_outline,
                        'Responsible',
                        activity.responsiblePerson,
                      ),
                      _detailTile(
                        context,
                        Icons.payments_outlined,
                        'Funding',
                        activity.fundingSource,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => onActionTap(activity),
                          child: const Text('View Full Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metricRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool fullWidth = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: fullWidth
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            inherit: true,
            fontSize: 10,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: fullWidth ? double.infinity : null,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: fullWidth ? Alignment.center : Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                inherit: true,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color ?? theme.textTheme.titleMedium?.color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          inherit: true,
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          inherit: true,
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _detailTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              inherit: true,
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              inherit: true,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
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
