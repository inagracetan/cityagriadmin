import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../core/app_colors.dart';

class BudgetPlanReport extends StatelessWidget {
  final List<Activity> activities;
  final bool isDark;

  const BudgetPlanReport({
    super.key,
    required this.activities,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ', decimalDigits: 2);
    
    // Detailed grouping logic with Account Codes
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildBudgetTable(context, formatCurrency, [
            _RowDef('5-02-01-010', 'Traveling Expenses', _filter(activities, oe: 'Travelling Expenses')),
            _RowDef('5-02-02-010', 'Training Expenses', _filter(activities, oe: 'Trainings and Seminar Expenses')),
            _RowDef('', '  - Rice Program', _filter(activities, oe: 'Trainings and Seminar Expenses', sub: 'Rice')),
            _RowDef('', '  - Corn Program', _filter(activities, oe: 'Trainings and Seminar Expenses', sub: 'Corn')),
            _RowDef('', '  - HVCD Program', _filter(activities, oe: 'Trainings and Seminar Expenses', sub: 'HVCDP')),
            _RowDef('', '  - Organic Program', _filter(activities, oe: 'Trainings and Seminar Expenses', sub: 'Organic Program')),
            _RowDef('', '  - Inland Fisheries Program', _filter(activities, oe: 'Trainings and Seminar Expenses', sec: 'Inland Fisheries Section')),
            
            _RowDef('', 'Supplies & Materials', _filter(activities, oePattern: 'Supplies')),
            _RowDef('5-02-03-010', '  - Office Supplies Expenses', _filter(activities, oe: 'Office Supplies Expenses')),
            _RowDef('5-02-03-100', '  - Agricultural Supplies Expenses', _filter(activities, oe: 'Agricultural Supplies Expenses')),
            _RowDef('', '    * City Nursery Supplies', _filter(activities, namePattern: 'Nursery')),
            _RowDef('', '    * Organic Fertilizer', _filter(activities, namePattern: 'Fertilizer')),
            _RowDef('', '    * Rodenticide/Insecticide', _filter(activities, namePattern: 'Rodenticide')),
            
            _RowDef('5-02-99-990', '  - Laboratory Supplies Expenses', _filter(activities, oe: 'Laboratory Supplies Expenses')),
            _RowDef('', '    * Soils Testing', _filter(activities, namePattern: 'Soils')),
            _RowDef('', '    * Plant Tissue Culture', _filter(activities, namePattern: 'Tissue Culture')),
            
            _RowDef('5-02-03-090', '  - Fuel, Oil & Lubricants', _filter(activities, oe: 'Fuel/Oil Expenses')),
            
            _RowDef('5-02-05-020', 'Communication Expenses', _filter(activities, oe: 'Communication Expenses')),
            _RowDef('', '  - Telephone/Internet', _filter(activities, oe: 'Communication Expenses')),
            
            _RowDef('', 'Repairs and Maintenance', _filter(activities, oe: 'Repair/Maintenance Expenses')),
            _RowDef('5-02-13-030', '  - Building/Structures', _filter(activities, namePattern: 'Building')),
            _RowDef('5-02-13-060', '  - Transportation Equipment', _filter(activities, namePattern: 'Transportation')),
            
            _RowDef('5-02-99-990', 'Other Maintenance and Operating Expenses', _filter(activities, oe: 'Other-MOE Expenses')),
            _RowDef('', '  - Personnel Development', _filter(activities, oe: 'Personnel Development Expenses')),
            _RowDef('', '  - Meetings', _filter(activities, oe: 'Meetings Expenses')),
            
            _RowDef('', 'Capital Outlay', _filter(activities, fs: 'Capital Outlay')),
          ]),
          const SizedBox(height: 32),
          _buildSummaryFooter(activities, formatCurrency),
        ],
      ),
    );
  }

  List<Activity> _filter(List<Activity> list, {
    String? oe, 
    String? sub, 
    String? sec, 
    String? fs,
    String? oePattern,
    String? namePattern,
  }) {
    return list.where((a) {
      if (oe != null && a.objectOfExpenditure != oe) return false;
      if (sub != null && a.subSector != sub) return false;
      if (sec != null && a.sector != sec) return false;
      if (fs != null && a.fundingSource != fs) return false;
      if (oePattern != null && !(a.objectOfExpenditure?.contains(oePattern) ?? false)) return false;
      if (namePattern != null && !a.activityName.toLowerCase().contains(namePattern.toLowerCase())) {
        // Also check breakdown items
        if (!a.breakdown.any((item) => item.name.toLowerCase().contains(namePattern.toLowerCase()))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OBJECT OF EXPENDITURES',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Slate.shade900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'CITY AGRICULTURE ADMINISTRATION - 2025/2026 Budget Plan',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetTable(BuildContext context, NumberFormat fmt, List<_RowDef> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Slate.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.02) : Slate.shade50),
          horizontalMargin: 20,
          columnSpacing: 24,
          columns: [
            _headerCell('ACCOUNT CODE'),
            _headerCell('OBJECT OF EXPENDITURES'),
            _headerCell('2025 BUDGET'),
            _headerCell('PROPOSED 2026'),
            _headerCell('ACTUAL (PO)'),
          ],
          rows: rows.map((row) {
            final isSub = row.label.startsWith('  ');
            final isSubSub = row.label.startsWith('    ');
            final total2025 = row.items.fold(0.0, (sum, a) => sum + (a.targetDate != '2026' ? a.approvedBudget : 0));
            final totalProposed = row.items.fold(0.0, (sum, a) => sum + (a.targetDate == '2026' ? a.approvedBudget : 0));
            final totalActual = row.items.fold(0.0, (sum, a) => sum + a.effectivePOAmount);

            return DataRow(
              cells: [
                DataCell(Text(
                  row.code,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Slate.shade400,
                  ),
                )),
                DataCell(Text(
                  row.label,
                  style: GoogleFonts.inter(
                    fontWeight: (isSub || isSubSub) ? FontWeight.normal : FontWeight.bold,
                    fontSize: isSubSub ? 12 : (isSub ? 13 : 14),
                    color: isSubSub ? (isDark ? Colors.white38 : Slate.shade400) : (isSub ? (isDark ? Colors.white70 : Slate.shade600) : (isDark ? Colors.white : Slate.shade900)),
                  ),
                )),
                DataCell(_amountText(fmt, total2025, isSub || isSubSub)),
                DataCell(_amountText(fmt, totalProposed, isSub || isSubSub, color: Colors.blue)),
                DataCell(_amountText(fmt, totalActual, isSub || isSubSub, color: Colors.green)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryFooter(List<Activity> activities, NumberFormat fmt) {
    final total2025 = activities.where((a) => a.targetDate != '2026').fold(0.0, (s, a) => s + a.approvedBudget);
    final total2026 = activities.where((a) => a.targetDate == '2026').fold(0.0, (s, a) => s + a.approvedBudget);

    // Quarterly Consolidation Logic
    double q1Total = 0, q2Total = 0, q3Total = 0, q4Total = 0;
    for (var a in activities) {
      for (var b in a.breakdown) {
        q1Total += b.q1Qty ?? 0;
        q2Total += b.q2Qty ?? 0;
        q3Total += b.q3Qty ?? 0;
        q4Total += b.q4Qty ?? 0;
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Slate.shade200),
          ),
          child: Column(
            children: [
              Text(
                'CONSOLIDATED QUARTERLY DISTRIBUTION (ALL ITEMS)',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _quarterMetric('Q1', q1Total, Colors.orange),
                  _quarterMetric('Q2', q2Total, Colors.blue),
                  _quarterMetric('Q3', q3Total, Colors.green),
                  _quarterMetric('Q4', q4Total, Colors.purple),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [Slate.shade50, Colors.white],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Slate.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryMetric('TOTAL 2025 BUDGET', fmt.format(total2025), Colors.grey),
              _summaryMetric('PROPOSED 2026 TOTAL', fmt.format(total2026), Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quarterMetric(String label, double val, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          val.toStringAsFixed(0),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Slate.shade900,
          ),
        ),
      ],
    );
  }

  Widget _summaryMetric(String label, String val, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white38 : Slate.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          val,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  DataColumn _headerCell(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: isDark ? Colors.white30 : Slate.shade400,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _amountText(NumberFormat fmt, double val, bool isLight, {Color? color}) {
    if (val == 0) return const Text('-', style: TextStyle(color: Colors.grey));
    return Text(
      fmt.format(val),
      style: GoogleFonts.jetBrainsMono(
        fontWeight: isLight ? FontWeight.normal : FontWeight.bold,
        fontSize: isLight ? 12 : 13,
        color: color ?? (isDark ? Colors.white : Slate.shade800),
      ),
    );
  }
}

class _RowDef {
  final String code;
  final String label;
  final List<Activity> items;

  _RowDef(this.code, this.label, this.items);
}
