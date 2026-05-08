import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';

class BudgetPlanReport extends StatefulWidget {
  final List<Activity> activities;
  final bool isDark;

  const BudgetPlanReport({
    super.key,
    required this.activities,
    required this.isDark,
  });

  @override
  State<BudgetPlanReport> createState() => _BudgetPlanReportState();
}

class _BudgetPlanReportState extends State<BudgetPlanReport> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(
      name: 'PHP ',
      decimalDigits: 2,
    );

    // Pre-compute filtered lists for the hierarchy
    final travExpenses = _filter(widget.activities, oe: 'Travelling Expenses');

    final trainingAll = _filter(
      widget.activities,
      oe: 'Training Expenses',
    );
    final trainRice = _filter(
      widget.activities,
      oe: 'Training Expenses',
      sub: 'Rice Program',
    );
    final trainCorn = _filter(
      widget.activities,
      oe: 'Training Expenses',
      sub: 'Corn Program',
    );
    final trainHVCD = _filter(
      widget.activities,
      oe: 'Training Expenses',
      sub: 'HVCD Program',
    );
    final trainOrganic = _filter(
      widget.activities,
      oe: 'Training Expenses',
      sub: 'Organic Program',
    );
    final trainFish = _filter(
      widget.activities,
      oe: 'Training Expenses',
      sub: 'Inland Fisheries Program',
    );

    final officeSupp = _filter(
      widget.activities,
      oe: 'Office Supplies Expenses',
    );
    final agriSupp = _filter(
      widget.activities,
      oe: 'Agricultural Supplies Expenses',
    );
    final labSupp = _filter(
      widget.activities,
      oe: 'Laboratory Supplies Expenses',
    );
    final fuel = _filter(widget.activities, oe: 'Fuel, Oil & Lubricants (Plus Backhoe use)');
    final otherSupp = _filter(
      widget.activities,
      oe: 'Other Supplies and Materials Expenses',
    );
    final suppAll = [
      ...officeSupp,
      ...agriSupp,
      ...labSupp,
      ...fuel,
      ...otherSupp,
    ];

    final commsAll = _filter(widget.activities, oe: 'Communication Expenses');
    final repairsAll = _filter(
      widget.activities,
      oe: 'Repairs and Maintenance',
    );

    final personnel = _filter(
      widget.activities,
      oe: 'Other Maintenance and Operating Expenses',
      sub: 'Personnel Development',
    );
    final meetingsAll = _filter(
      widget.activities,
      oe: 'Other Maintenance and Operating Expenses',
      sub: 'Meetings',
    );
    final otherMoeAll = _filter(
      widget.activities,
      oe: 'Other Maintenance and Operating Expenses',
    );
    final moeSectionAll = [...personnel, ...meetingsAll, ...otherMoeAll];

    final capOutlay = _filter(widget.activities, fs: 'Capital Outlay');

    final rows = [
      // a) Travelling Expenses
      _RowDef(
        '5-02-01-010',
        'a) Travelling Expenses',
        travExpenses,
        isHeader: true,
      ),

      // b) Training Expenses
      _RowDef(
        '5-02-02-010',
        'b) Training Expenses',
        trainingAll,
        isHeader: true,
      ),
      _RowDef('', '    1) Rice Program', trainRice, isDetail: true),
      _RowDef('', '    2) Corn Program', trainCorn, isDetail: true),
      _RowDef('', '    3) HVCD Program', trainHVCD, isDetail: true),
      _RowDef(
        '',
        '    4) Organic Program',
        trainOrganic,
        isDetail: true,
      ),
      _RowDef(
        '',
        '    5) Inland Fisheries Program',
        trainFish,
        isDetail: true,
      ),

      // c) Supplies & Materials
      _RowDef(
        '5-02-03',
        'c) Supplies & Materials',
        suppAll,
        isHeader: true,
      ),

      _RowDef(
        '5-02-03-010',
        '    1) Office Supplies Expenses',
        officeSupp,
      ),

      _RowDef(
        '5-02-03-100',
        '    2) Agricultural Supplies Expenses',
        agriSupp,
      ),
      _RowDef(
        '',
        '         1) City Nursery Supplies',
        _filter(agriSupp, namePattern: 'Nursery'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         2) Organic Fertilizer',
        _filter(agriSupp, namePattern: 'Fertilizer'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         3) Rodenticide',
        _filter(agriSupp, namePattern: 'Rodenticide'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         4) Insecticide',
        _filter(agriSupp, namePattern: 'Insecticide'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         5) Fungicide',
        _filter(agriSupp, namePattern: 'Fungicide'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         6) High Valued Commercial Crop Techno Demo Supplies',
        _filter(agriSupp, namePattern: 'Techno Demo'),
        isDetail: true,
      ),

      _RowDef(
        '5-02-99-990',
        '    3) Laboratory Supplies Expenses',
        labSupp,
      ),
      _RowDef(
        '',
        '         1) City Soils Testing Laboratory',
        _filter(labSupp, namePattern: 'Soils'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         2) Plant Tissue Culture Laboratory',
        _filter(labSupp, namePattern: 'Tissue Culture'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         3) Bio-Con Laboratory',
        _filter(labSupp, namePattern: 'Bio-Con'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         4) NFTS Concoction Production Project',
        _filter(labSupp, namePattern: 'NFTS'),
        isDetail: true,
      ),

      _RowDef(
        '5-02-03-090',
        '    4) Fuel, Oil & Lubricants (Plus Backhoe use)',
        fuel,
      ),

      _RowDef(
        '',
        '    5) Other Supplies and Materials Expenses',
        otherSupp,
      ),
      _RowDef(
        '',
        '         1) 20 Pcs Folding Tables',
        _filter(otherSupp, namePattern: 'Folding Tables'),
        isDetail: true,
      ),

      // d) Communication Expenses
      _RowDef(
        '5-02-05-020',
        'd) Communication Expenses',
        commsAll,
        isHeader: true,
      ),
      _RowDef(
        '',
        '    1) Postage & Courier Services',
        _filter(commsAll, namePattern: 'Postage'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '    2) Telephone Expenses',
        _filter(commsAll, namePattern: 'Telephone'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '    3) Internet Subscription Expenses',
        _filter(commsAll, namePattern: 'Internet'),
        isDetail: true,
      ),

      // e) Repairs and Maintenance
      _RowDef(
        '5-02-13',
        'e) Repairs and Maintenance',
        repairsAll,
        isHeader: true,
      ),
      _RowDef(
        '5-02-13-030',
        '    1) Repairs and Maintenance - Building and Other Structures',
        _filter(repairsAll, namePattern: 'Building'),
      ),
      _RowDef(
        '5-02-13-050',
        '    2) Repairs and Maintenance - Machinery and Equipment',
        _filter(repairsAll, namePattern: 'Machinery'),
      ),
      _RowDef(
        '5-02-13-060',
        '    3) Repairs and Maintenance - Transportation Equipment',
        _filter(repairsAll, namePattern: 'Transportation'),
      ),

      // f) Other Maintenance and Operating Expenses
      _RowDef(
        '5-02-99-990',
        'f) Other Maintenance and Operating Expenses',
        moeSectionAll,
        isHeader: true,
      ),
      _RowDef(
        '',
        '    1. Personnel Development',
        personnel,
        isDetail: true,
      ),
      _RowDef(
        '',
        '    2. Agriculture & Fisheries Congress',
        _filter(otherMoeAll, namePattern: 'Congress'),
        isDetail: true,
      ),
      _RowDef('', '    3. Meetings', meetingsAll, isDetail: true),
      _RowDef(
        '',
        '         Rural Improvement Club Meetings',
        _filter(meetingsAll, namePattern: 'Rural Improvement'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         4-H Club Meetings',
        _filter(meetingsAll, namePattern: '4-H'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         CAFC Meetings',
        _filter(meetingsAll, namePattern: 'CAFC'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         Fisherfolks Meetings',
        _filter(meetingsAll, namePattern: 'Fisherfolk'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         Organic Farmers Meetings',
        _filter(meetingsAll, namePattern: 'Organic Farmer'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         Vegetable Farmers Meetings',
        _filter(meetingsAll, namePattern: 'Vegetable'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         Corn Farmers Meetings',
        _filter(meetingsAll, namePattern: 'Corn Farmer'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         Rice Farmers Meetings',
        _filter(meetingsAll, namePattern: 'Rice Farmer'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '         Strengthening of Farmers Meetings',
        _filter(meetingsAll, namePattern: 'Strengthening'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '    4. Project Development',
        _filter(otherMoeAll, namePattern: 'Project Development'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '    5. Monitoring and Evaluation',
        _filter(otherMoeAll, namePattern: 'Monitoring'),
        isDetail: true,
      ),
      _RowDef(
        '',
        '    6. CAFC Capability Building',
        _filter(otherMoeAll, namePattern: 'CAFC Capability'),
        isDetail: true,
      ),

      // Capital Outlay
      _RowDef('', 'Capital Outlay', capOutlay, isHeader: true),
    ];

    // Detailed grouping logic with Account Codes
    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalController,
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildBudgetTable(context, formatCurrency, rows),
            const SizedBox(height: 32),
            _buildMonthlyWFPTable(context, formatCurrency, rows),
            const SizedBox(height: 32),
            _buildSummaryFooter(widget.activities, formatCurrency),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyWFPTable(
    BuildContext context,
    NumberFormat fmt,
    List<_RowDef> rows,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MONTHLY WFP DISTRIBUTION',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: widget.isDark ? Colors.white : Slate.shade900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border.all(
              color: widget.isDark ? Colors.white10 : Slate.shade300,
            ),
          ),
          child: Scrollbar(
            controller: ScrollController(),
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  widget.isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade200,
                ),
                horizontalMargin: 12,
                columnSpacing: 16,
                border: TableBorder.all(
                  color: widget.isDark ? Colors.white10 : Colors.black54,
                  width: 1,
                ),
                columns: [
                  _headerCell('OBJECT OF EXPENDITURE'),
                  ...AppConstants.months.map((m) => _headerCell(m.substring(0, 3).toUpperCase())),
                  _headerCell('TOTAL'),
                ],
                rows: rows.where((r) => r.isHeader || !r.isDetail).map((row) {
                  final distribution = List<double>.filled(12, 0.0);
                  for (var act in row.items) {
                    if (act.monthlyDistribution != null) {
                      for (int i = 0; i < 12; i++) {
                        distribution[i] += act.monthlyDistribution![i];
                      }
                    }
                  }
                  final total = distribution.reduce((a, b) => a + b);

                  return DataRow(
                    color: WidgetStateProperty.all(
                      row.isHeader
                          ? (widget.isDark
                                ? Colors.white.withOpacity(0.02)
                                : Colors.grey.shade100)
                          : Colors.transparent,
                    ),
                    cells: [
                      DataCell(
                        Text(
                          row.label,
                          style: GoogleFonts.inter(
                            fontWeight: row.isHeader ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                            color: widget.isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      ...distribution.map((val) => DataCell(
                        Container(
                          alignment: Alignment.centerRight,
                          child: _amountText(fmt, val, true, hideZero: true),
                        ),
                      )),
                      DataCell(
                        Container(
                          alignment: Alignment.centerRight,
                          child: _amountText(fmt, total, false, hideZero: true),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Activity> _filter(
    List<Activity> list, {
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
      if (oePattern != null &&
          !(a.objectOfExpenditure?.contains(oePattern) ?? false)) {
        return false;
      }
      if (namePattern != null &&
          !a.activityName.toLowerCase().contains(namePattern.toLowerCase())) {
        // Also check breakdown items
        if (!a.breakdown.any(
          (item) => item.name.toLowerCase().contains(namePattern.toLowerCase()),
        )) {
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
            color: widget.isDark ? Colors.white : Slate.shade900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'CITY AGRICULTURE ADMINISTRATION - ${SystemConfig.currentFiscalYearStr}/${SystemConfig.nextFiscalYearStr} Budget Plan',
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

  Widget _buildBudgetTable(
    BuildContext context,
    NumberFormat fmt,
    List<_RowDef> rows,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: widget.isDark ? Colors.white10 : Slate.shade300,
        ),
      ),
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalController,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade200,
            ),
            horizontalMargin: 12,
            columnSpacing: 16,
            border: TableBorder.all(
              color: widget.isDark ? Colors.white10 : Colors.black54,
              width: 1,
            ),
            columns: [
              _headerCell('OBJECT OF EXPENDITURES'),
              _headerCell('ACCOUNT\nCODE'),
              _headerCell(
                'Proposed Budget\nin Details (Office\nControl)',
                isYellow: true,
              ),
              _headerCell(
                'PPMP\nAmount',
              ),
              _headerCell(
                'PR\nObligated',
              ),
              _headerCell(
                'PR\nBalance',
              ),
              _headerCell(
                'Savings',
              ),
              _headerCell(
                'PROPOSED\nEXPENDITURES ${SystemConfig.nextFiscalYearStr}\nANNUAL BUDGET',
              ),
            ],
            rows: rows.map((row) {
              final isHeader = row.isHeader;
              final totalProposed = row.items.fold(
                0.0,
                (sum, a) =>
                    sum +
                    (a.targetDate == SystemConfig.nextFiscalYearStr
                        ? a.approvedBudget
                        : 0),
              );

              final totalPPMP = row.items.fold(0.0, (s, a) => s + a.ppmpAmount);
              final totalPR = row.items.fold(0.0, (s, a) => s + a.effectivePRAmount);
              final totalPO = row.items.fold(0.0, (s, a) => s + a.effectivePOAmount);
              final prBalance = totalPPMP - totalPR;
              final savings = totalPR - totalPO;

              return DataRow(
                color: WidgetStateProperty.all(
                  isHeader
                      ? (widget.isDark
                            ? Colors.white.withOpacity(0.02)
                            : Colors.grey.shade100)
                      : Colors.transparent,
                ),
                cells: [
                  DataCell(
                    Padding(
                      padding: EdgeInsets.only(left: row.isDetail ? 16.0 : 0.0),
                      child: Text(
                        row.label,
                        style: GoogleFonts.inter(
                          fontWeight: isHeader ? FontWeight.w900 : FontWeight.w500,
                          fontSize: isHeader ? 14 : 13,
                          color: widget.isDark ? Colors.white : Colors.black,
                          decoration: isHeader
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      row.code,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: widget.isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: row.isDetail
                          ? Colors.yellow.withOpacity(widget.isDark ? 0.2 : 1.0)
                          : Colors.transparent,
                      child: _amountText(
                        fmt,
                        row.isDetail ? totalProposed : 0,
                        !row.isDetail,
                        hideZero: true,
                      ),
                    ),
                  ),
                  // PPMP Amount
                  DataCell(
                    Container(
                      alignment: Alignment.centerRight,
                      child: _amountText(fmt, totalPPMP, true, hideZero: true),
                    ),
                  ),
                  // PR Obligated
                  DataCell(
                    Container(
                      alignment: Alignment.centerRight,
                      child: _amountText(fmt, totalPR, true, color: Colors.orange.shade800, hideZero: true),
                    ),
                  ),
                  // PR Balance
                  DataCell(
                    Container(
                      alignment: Alignment.centerRight,
                      child: _amountText(
                        fmt, 
                        prBalance, 
                        false, 
                        color: prBalance < 0 ? Colors.red : Colors.green.shade700,
                        hideZero: true,
                      ),
                    ),
                  ),
                  // Savings
                  DataCell(
                    Container(
                      alignment: Alignment.centerRight,
                      child: _amountText(fmt, savings, true, color: Colors.blue.shade700, hideZero: true),
                    ),
                  ),
                  DataCell(
                    Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: _amountText(
                        fmt,
                        !isHeader ? totalProposed : 0,
                        false,
                        color: Colors.red.shade700,
                        hideZero: true,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryFooter(List<Activity> activities, NumberFormat fmt) {
    final totalCurrent = activities
        .where((a) => a.targetDate != SystemConfig.nextFiscalYearStr)
        .fold(0.0, (s, a) => s + a.approvedBudget);
    final totalNext = activities
        .where((a) => a.targetDate == SystemConfig.nextFiscalYearStr)
        .fold(0.0, (s, a) => s + a.approvedBudget);

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
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark ? Colors.white10 : Slate.shade200,
            ),
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
              colors: widget.isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Slate.shade50, Colors.white],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark ? Colors.white10 : Slate.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryMetric(
                'TOTAL ${SystemConfig.currentFiscalYearStr} BUDGET',
                fmt.format(totalCurrent),
                Colors.grey,
              ),
              _summaryMetric(
                'PROPOSED ${SystemConfig.nextFiscalYearStr} TOTAL',
                fmt.format(totalNext),
                Colors.blue,
              ),
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
            color: color.withOpacity(0.1),
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
            color: widget.isDark ? Colors.white : Slate.shade900,
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
            color: widget.isDark ? Colors.white38 : Slate.shade500,
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

  DataColumn _headerCell(String label, {bool isYellow = false}) {
    return DataColumn(
      label: Container(
        padding: isYellow
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: isYellow
              ? Colors.yellow.withOpacity(widget.isDark ? 0.2 : 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: isYellow
                ? (widget.isDark ? Colors.white : Colors.black87)
                : (widget.isDark ? Colors.white30 : Slate.shade400),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _amountText(
    NumberFormat fmt,
    double val,
    bool isLight, {
    Color? color,
    bool hideZero = false,
  }) {
    if (val == 0) {
      if (hideZero) return const SizedBox();
      return const Text('-', style: TextStyle(color: Colors.grey));
    }
    return Text(
      fmt.format(val),
      style: GoogleFonts.jetBrainsMono(
        fontWeight: isLight ? FontWeight.normal : FontWeight.bold,
        fontSize: isLight ? 12 : 13,
        color: color ?? (widget.isDark ? Colors.white : Slate.shade800),
      ),
    );
  }
}

class _RowDef {
  final String code;
  final String label;
  final List<Activity> items;
  final bool isHeader;
  final bool isDetail;

  _RowDef(
    this.code,
    this.label,
    this.items, {
    this.isHeader = false,
    this.isDetail = false,
  });
}
