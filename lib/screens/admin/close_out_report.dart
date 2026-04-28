import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/activity.dart';
import 'package:intl/intl.dart';

class CloseOutReport extends StatelessWidget {
  final Activity activity;
  const CloseOutReport({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
    final double utilizationRate = activity.approvedBudget > 0
        ? (activity.actualExpenditure / activity.approvedBudget) * 100
        : 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Official Header ---
            Container(
              padding: const EdgeInsets.fromLTRB(32, 40, 24, 32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF064E3B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROJECT CLOSE-OUT',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'OFFICIAL REPORT',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Activity ID: ${activity.id.toUpperCase()}',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),

            // --- Report Content ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _reportSection(context, 'Basic Information', [
                      _infoRow(
                        context,
                        'Activity Name',
                        activity.activityName,
                        isTitle: true,
                      ),
                      _infoRow(context, 'Section / Unit', activity.sector),
                      _infoRow(
                        context,
                        'Responsible Personnel',
                        activity.responsiblePerson,
                      ),
                    ]),
                    const SizedBox(height: 32),
                    _reportSection(context, 'Financial Analytics', [
                      _infoRow(
                        context,
                        'Total Appropriation',
                        formatCurrency.format(activity.approvedBudget),
                      ),
                      _infoRow(
                        context,
                        'Actual Disbursement',
                        formatCurrency.format(activity.actualExpenditure),
                      ),
                      _infoRow(
                        context,
                        'Unexpended Balance',
                        formatCurrency.format(activity.unexpendedBalance),
                        highlighted: true,
                      ),
                      const SizedBox(height: 12),
                      _utilizationIndicator(context, utilizationRate),
                    ]),
                    const SizedBox(height: 32),
                    _reportSection(context, 'Accomplishment Review', [
                      _infoRow(
                        context,
                        'Indicator Unit',
                        activity.performanceIndicator,
                      ),
                      _infoRow(
                        context,
                        'Target Quantitative',
                        activity.targetNo.toString(),
                      ),
                      _infoRow(
                        context,
                        'Factual Conduct',
                        activity.actualConduct.isEmpty
                            ? 'Pending documentation'
                            : activity.actualConduct,
                      ),
                      _infoRow(
                        context,
                        'Performance Remarks',
                        activity.accommRemarks.isEmpty
                            ? 'No significant variance reported.'
                            : activity.accommRemarks,
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            // --- Action Footer ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF064E3B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.print_rounded),
                        label: Text(
                          'GENERATE OFFICIAL PDF',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.0),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Compiling Official Document...'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'DISMISS',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 2,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    bool highlighted = false,
    bool isTitle = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            SizedBox(
            width: 200,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: isTitle || highlighted
                    ? FontWeight.w900
                    : FontWeight.w700,
                fontSize: isTitle ? 18 : 14,
                color: highlighted
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _utilizationIndicator(BuildContext context, double rate) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            const Text(
                'RESOURCE UTILIZATION EFFICIENCY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
