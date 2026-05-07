import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/activity.dart';
import '../../core/constants.dart';
import '../../core/responsive_utils.dart';

class MonthlyAggregationViewer extends StatelessWidget {
  final List<Activity> activities;

  const MonthlyAggregationViewer({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    Map<String, double> monthlyTargets = {};

    for (var act in activities) {
      String monthKey = 'Unspecified';
      if (act.targetDate.isNotEmpty) {
        final lower = act.targetDate.toLowerCase();
        // Check for month names
        bool found = false;
        for (final m in AppConstants.months) {
          if (lower.contains(m.toLowerCase())) {
            // Found a month name. Now look for a year.
            final yearMatch = RegExp(r'\d{4}').firstMatch(act.targetDate);
            final year = yearMatch != null ? yearMatch.group(0) : DateTime.now().year.toString();
            monthKey = '$m $year';
            found = true;
            break;
          }
        }
        
        if (!found) {
          // Try parsing as date MM/DD/YYYY
          try {
            final parts = act.targetDate.split('/');
            if (parts.length == 3) {
              final m = int.tryParse(parts[0]);
              final y = int.tryParse(parts[2]);
              if (m != null && m >= 1 && m <= 12) {
                monthKey = '${AppConstants.months[m - 1]} ${y ?? DateTime.now().year}';
                found = true;
              }
            }
          } catch (_) {}
        }
        
        if (!found) monthKey = act.targetDate;
      }
      
      if (!monthlyTargets.containsKey(monthKey)) {
        monthlyTargets[monthKey] = 0.0;
      }
      monthlyTargets[monthKey] = monthlyTargets[monthKey]! + act.totalBudget;
    }

    final sortedMonths = monthlyTargets.keys.toList()
      ..sort((a, b) {
        if (a == 'Unspecified') return 1;
        if (b == 'Unspecified') return -1;

        int getMonthIndex(String key) {
          final parts = key.split(' ');
          final monthPart = parts[0].split('-')[0];
          return AppConstants.months.indexOf(monthPart);
        }

        int getYear(String key) {
          final parts = key.split(' ');
          if (parts.length >= 2) return int.tryParse(parts.last) ?? 0;
          return 0;
        }

        final yearA = getYear(a);
        final yearB = getYear(b);
        if (yearA != yearB) return yearA.compareTo(yearB);

        final indexA = getMonthIndex(a);
        final indexB = getMonthIndex(b);
        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isMobile = ResponsiveUtils.isMobile(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 0 : 24),
      ),
      elevation: 24,
      insetPadding: isMobile
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: isMobile ? double.infinity : 600,
        ),
        child: Column(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // --- Header ---
            Container(
              padding: const EdgeInsets.fromLTRB(28, 32, 20, 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF064E3B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isMobile ? 0 : 24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Aggregation',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Total Appropriation by Month',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // --- List ---
            Flexible(
              child: monthlyTargets.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No allocations found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount: sortedMonths.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.05),
                      ),
                      itemBuilder: (context, index) {
                        final monthKey = sortedMonths[index];
                        final value = monthlyTargets[monthKey]!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  monthKey.substring(0, 3).toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              monthKey,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatCurrency.format(value),
                                  style: GoogleFonts.inter(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Total Budget',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // --- Footer ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'CLOSE REPORT',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

