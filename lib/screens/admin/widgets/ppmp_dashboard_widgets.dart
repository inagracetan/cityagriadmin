import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/design_system.dart';
import '../../../models/activity.dart';
import '../../../services/activity_form_provider.dart';

/// Premium Summary Card as seen in the PPMP Dashboard
class PPMPSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Widget? trend;
  final Color? trendColor;
  final double? percentage;
  final bool isLarge;
  final IconData? icon;

  const PPMPSummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.trend,
    this.trendColor,
    this.percentage,
    this.isLarge = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = trendColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced vertical padding
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: activeColor.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon ?? Icons.analytics_outlined, size: 22, color: activeColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withValues(alpha: 0.9),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (percentage != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activeColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${(percentage! * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: activeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Budget vs Actual Bar Chart
class PPMPBudgetVsActualChart extends StatelessWidget {
  final List<Activity> activities;
  const PPMPBudgetVsActualChart({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    // Group activities by sector
    final Map<String, List<Activity>> sectorGroups = {};
    for (var a in activities) {
      final sector = a.sector.isEmpty ? 'Other' : a.sector;
      sectorGroups.putIfAbsent(sector, () => []).add(a);
    }

    // Sort by budget and take top 5
    final sortedSectors = sectorGroups.keys.toList()
      ..sort((a, b) {
        final budgetA = sectorGroups[a]!.fold<double>(0, (sum, act) => sum + act.approvedBudget);
        final budgetB = sectorGroups[b]!.fold<double>(0, (sum, act) => sum + act.approvedBudget);
        return budgetB.compareTo(budgetA);
      });
    
    final topSectors = sortedSectors.take(5).toList();

    double maxVal = 0;
    final barGroups = List.generate(topSectors.length, (index) {
      final sector = topSectors[index];
      final acts = sectorGroups[sector]!;
      final budget = acts.fold<double>(0, (sum, a) => sum + a.approvedBudget) / 1000000;
      final actual = acts.fold<double>(0, (sum, a) => sum + a.effectivePOAmount) / 1000000;
      
      if (budget > maxVal) maxVal = budget;
      if (actual > maxVal) maxVal = actual;
      
      return _makeGroupData(index, budget, actual);
    });

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget vs. Actual',
                    style: AppDesignSystem.headingSmall.copyWith(letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Values in Millions (₱)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: activities.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      Text(
                        'No data available',
                        style: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxVal * 1.2).ceilToDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey.shade900,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rodIndex == 0 ? 'Budget' : 'Actual'}: ₱${rod.toY.toStringAsFixed(1)}M',
                            GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= topSectors.length) return const SizedBox();
                            final sector = topSectors[idx];
                            String text = sector;
                            if (text.length > 8) {
                              text = text.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join();
                            }
                            return SideTitleWidget(
                              meta: meta, 
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  text, 
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade500, 
                                    fontWeight: FontWeight.w700, 
                                    fontSize: 10
                                  )
                                ),
                              )
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox();
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                '${value.toInt()}M', 
                                style: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 10)
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 6,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1, 
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
          ), 
          width: 14, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6))
        ),
        BarChartRodData(
          toY: y2, 
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFF059669), Color(0xFF34D399)],
          ), 
          width: 14, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6))
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendItem('Budget', const Color(0xFF3B82F6)),
        const SizedBox(width: 16),
        _legendItem('Actual', const Color(0xFF10B981)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8, 
          height: 8, 
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle,
          )
        ),
        const SizedBox(width: 6),
        Text(
          label, 
          style: GoogleFonts.inter(
            fontSize: 11, 
            fontWeight: FontWeight.w700, 
            color: Colors.grey.shade600
          )
        ),
      ],
    );
  }
}

/// Budget Allocation by Source Donut Chart
class PPMPAllocationSourceChart extends StatelessWidget {
  final List<Activity> activities;
  const PPMPAllocationSourceChart({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    // Group by funding source
    final Map<String, double> sourceTotals = {};
    double totalAll = 0;
    for (var a in activities) {
      final source = a.fundingSource.isEmpty ? 'Other' : a.fundingSource;
      sourceTotals[source] = (sourceTotals[source] ?? 0) + a.approvedBudget;
      totalAll += a.approvedBudget;
    }

    final sortedSources = sourceTotals.keys.toList()
      ..sort((a, b) => sourceTotals[b]!.compareTo(sourceTotals[a]!));
    
    final List<Color> colors = [
      const Color(0xFF2563EB),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
      const Color(0xFFDB2777),
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget by Source', 
            style: AppDesignSystem.headingSmall.copyWith(letterSpacing: -0.5),
          ),
          const SizedBox(height: 32),
          activities.isEmpty 
            ? SizedBox(
                height: 200, 
                child: Center(
                  child: Icon(Icons.donut_large_rounded, size: 48, color: Colors.grey.shade200),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          sections: List.generate(sortedSources.length, (index) {
                            final source = sortedSources[index];
                            final value = sourceTotals[source]!;
                            return PieChartSectionData(
                              color: colors[index % colors.length], 
                              value: value, 
                              title: '', 
                              radius: 18,
                              badgeWidget: null,
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(sortedSources.length, (index) {
                        final source = sortedSources[index];
                        final value = sourceTotals[source]!;
                        final percentage = totalAll > 0 ? (value / totalAll * 100) : 0;
                        return _sourceLegendItem(
                          source, 
                          '${percentage.toStringAsFixed(1)}%', 
                          colors[index % colors.length]
                        );
                      }),
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _sourceLegendItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 8, 
            height: 8, 
            decoration: BoxDecoration(
              color: color, 
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12, 
                fontWeight: FontWeight.w600, 
                color: Colors.grey.shade600
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12, 
              fontWeight: FontWeight.w800, 
              color: Colors.black.withValues(alpha: 0.8)
            ),
          ),
        ],
      ),
    );
  }
}

class PPMPProjectListTable extends StatefulWidget {
  final List<Activity> activities;
  const PPMPProjectListTable({super.key, required this.activities});

  @override
  State<PPMPProjectListTable> createState() => _PPMPProjectListTableState();
}

class _PPMPProjectListTableState extends State<PPMPProjectListTable> {
  String searchQuery = '';
  int _currentPage = 1;
  final int _rowsPerPage = 10;
  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }
  final formatCurrency = NumberFormat.simpleCurrency(name: '₱ ');

  @override
  Widget build(BuildContext context) {
    final filteredActivities = widget.activities.where((a) => a.matchesSearch(searchQuery)).toList();
    
    // Pagination logic
    final totalItems = filteredActivities.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage) > totalItems ? totalItems : (startIndex + _rowsPerPage);
    final paginatedActivities = totalItems > 0 ? filteredActivities.sublist(startIndex, endIndex) : <Activity>[];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.list_alt_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project List & Line Items', 
                      style: AppDesignSystem.headingSmall.copyWith(letterSpacing: -0.5)
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage and track all procurement activities for the fiscal year.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.read<ActivityFormProvider>().openForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  elevation: 0,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildFilters(),
          const SizedBox(height: 24),
          Theme(
            data: Theme.of(context).copyWith(
              dividerTheme: const DividerThemeData(thickness: 1, color: Color(0xFFF1F5F9)),
            ),
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 0,
                    headingRowHeight: 56,
                    dataRowMaxHeight: 72,
                    headingTextStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                    columns: const [
                      DataColumn(label: SizedBox(width: 200, child: Text('PROJECT NAME / LINE ITEM', overflow: TextOverflow.ellipsis))),
                      DataColumn(label: SizedBox(width: 100, child: Text('BUDGET', overflow: TextOverflow.ellipsis))),
                      DataColumn(label: SizedBox(width: 100, child: Text('PR AMOUNT', overflow: TextOverflow.ellipsis))),
                      DataColumn(label: SizedBox(width: 100, child: Text('PO AMOUNT', overflow: TextOverflow.ellipsis))),
                      DataColumn(label: SizedBox(width: 100, child: Text('BALANCE', overflow: TextOverflow.ellipsis))),
                      DataColumn(label: SizedBox(width: 80, child: Text('STATUS', overflow: TextOverflow.ellipsis))),
                      DataColumn(label: SizedBox(width: 60, child: Text(''))),
                    ],
                    rows: paginatedActivities.map((activity) {
                      final balance = activity.unexpendedBalance;
                      Color statusColor = Colors.blue;
                      if (activity.status.toLowerCase() == 'completed') statusColor = const Color(0xFF10B981);
                      if (activity.status.toLowerCase() == 'planned') statusColor = Colors.grey.shade400;
                      if (activity.status.toLowerCase().contains('no budget')) statusColor = const Color(0xFFEF4444);
  
                      return _buildRow(
                        context,
                        activity,
                        activity.activityName,
                        formatCurrency.format(activity.approvedBudget),
                        formatCurrency.format(activity.effectivePRAmount),
                        formatCurrency.format(activity.effectivePOAmount),
                        formatCurrency.format(balance),
                        activity.status,
                        statusColor,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildPagination(totalItems, totalPages),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalItems, int totalPages) {
    if (totalItems == 0) return const SizedBox();

    final startIndex = (_currentPage - 1) * _rowsPerPage + 1;
    final endIndex = (startIndex + _rowsPerPage - 1) > totalItems ? totalItems : (startIndex + _rowsPerPage - 1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startIndex to $endIndex of $totalItems entries',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          Row(
            children: [
              _paginationButton(
                icon: Icons.chevron_left_rounded,
                isEnabled: _currentPage > 1,
                onTap: () {
                  if (_currentPage > 1) {
                    setState(() {
                      _currentPage--;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(totalPages),
              const SizedBox(width: 8),
              _paginationButton(
                icon: Icons.chevron_right_rounded,
                isEnabled: _currentPage < totalPages,
                onTap: () {
                  if (_currentPage < totalPages) {
                    setState(() {
                      _currentPage++;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    List<Widget> widgets = [];
    
    // Logic to show limited page numbers if there are too many
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        widgets.add(_pageNumberButton(i));
        if (i < totalPages) widgets.add(const SizedBox(width: 4));
      }
    } else {
      // Show first, current-1, current, current+1, last with dots
      if (_currentPage <= 3) {
        for (int i = 1; i <= 4; i++) {
          widgets.add(_pageNumberButton(i));
          widgets.add(const SizedBox(width: 4));
        }
        widgets.add(_pageDots());
        widgets.add(const SizedBox(width: 4));
        widgets.add(_pageNumberButton(totalPages));
      } else if (_currentPage >= totalPages - 2) {
        widgets.add(_pageNumberButton(1));
        widgets.add(const SizedBox(width: 4));
        widgets.add(_pageDots());
        widgets.add(const SizedBox(width: 4));
        for (int i = totalPages - 3; i <= totalPages; i++) {
          widgets.add(_pageNumberButton(i));
          if (i < totalPages) widgets.add(const SizedBox(width: 4));
        }
      } else {
        widgets.add(_pageNumberButton(1));
        widgets.add(const SizedBox(width: 4));
        widgets.add(_pageDots());
        widgets.add(const SizedBox(width: 4));
        widgets.add(_pageNumberButton(_currentPage - 1));
        widgets.add(const SizedBox(width: 4));
        widgets.add(_pageNumberButton(_currentPage));
        widgets.add(const SizedBox(width: 4));
        widgets.add(_pageNumberButton(_currentPage + 1));
        widgets.add(const SizedBox(width: 4));
        widgets.add(_pageDots());
        widgets.add(const SizedBox(width: 4));
        widgets.add(_pageNumberButton(totalPages));
      }
    }
    return widgets;
  }

  Widget _pageNumberButton(int page) {
    final bool isSelected = _currentPage == page;
    return InkWell(
      onTap: () {
        setState(() {
          _currentPage = page;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
          ),
        ),
        child: Text(
          page.toString(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _pageDots() {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      child: Text(
        '...',
        style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _paginationButton({required IconData icon, required bool isEnabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Activity activity, String title, String budget, String pr, String po, String balance, String status, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 200, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title, 
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, 
                    color: Colors.black.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity.sector,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            )
          )
        ),
        DataCell(SizedBox(width: 100, child: Text(budget, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 100, child: Text(pr, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 100, child: Text(po, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis))),
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              balance, 
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, 
                fontSize: 13,
                color: activity.unexpendedBalance < 0 ? Colors.red : AppColors.emeraldPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            )
          )
        ),
        DataCell(
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1), 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                status.toUpperCase(), 
                style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        ),
        DataCell(
          SizedBox(
            width: 60,
            child: IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.grey), 
              onPressed: () {
                context.read<ActivityFormProvider>().openForm(activity: activity);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: AppDesignSystem.iconSizeSmall, color: Colors.grey.shade400),                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _currentPage = 1; // Reset to first page on search
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search projects or line items...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        _filterDropdown('All Departments'),
        const SizedBox(width: 12),
        _filterDropdown('Status'),
        const Spacer(),
        Text(
          'Showing ${widget.activities.length} Projects',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _filterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text(
            label, 
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)
          ),
          const SizedBox(width: 10),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}

/// WFP Heatmap View
class PPMPHeatmapView extends StatefulWidget {
  final List<Activity> activities;
  const PPMPHeatmapView({super.key, required this.activities});

  @override
  State<PPMPHeatmapView> createState() => _PPMPHeatmapViewState();
}

class _PPMPHeatmapViewState extends State<PPMPHeatmapView> {
  late final ScrollController _heatmapScrollController;

  @override
  void initState() {
    super.initState();
    _heatmapScrollController = ScrollController();
  }

  @override
  void dispose() {
    _heatmapScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WFP Heatmap View', style: AppDesignSystem.headingSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Monthly budget distribution for top line items.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _buildHeatmapLegend(),
            ],
          ),
          const SizedBox(height: 32),
          _buildHeatmapFilters(),
          const SizedBox(height: 24),
          _buildHeatmapGrid(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All amounts are shown in Philippine Peso (₱). Darker shades indicate higher budget allocations for that month.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      children: [
        _legendSquare('0', Colors.grey.shade100),
        _legendSquare('<50k', const Color(0xFFD1FAE5)),
        _legendSquare('<100k', const Color(0xFF6EE7B7)),
        _legendSquare('<300k', const Color(0xFF10B981)),
        _legendSquare('>300k', const Color(0xFF059669)),
      ],
    );
  }

  Widget _legendSquare(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapFilters() {
    return Row(
      children: [
        _heatmapFilterDropdown('All Categories'),
        const SizedBox(width: 12),
        _heatmapFilterDropdown('Monthly View'),
        const Spacer(),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Export Data'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.emeraldPrimary,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _heatmapFilterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Aggregate data from activities
    final displayActivities = widget.activities.take(10).toList(); // Show top 10 for readability
    
    final List<double> totals = List.generate(12, (_) => 0.0);
    double grandTotal = 0;

    for (var a in widget.activities) {
      if (a.monthlyDistribution != null && a.monthlyDistribution!.length == 12) {
        for (int i = 0; i < 12; i++) {
          totals[i] += a.monthlyDistribution![i];
          grandTotal += a.monthlyDistribution![i];
        }
      } else {
        // Fallback: distribute quarterly budget evenly across months
        final qBudgets = [a.q1Budget, a.q2Budget, a.q3Budget, a.q4Budget];
        for (int q = 0; q < 4; q++) {
          final monthly = qBudgets[q] / 3;
          for (int m = 0; m < 3; m++) {
            totals[q * 3 + m] += monthly;
            grandTotal += monthly;
          }
        }
      }
    }

    final formatCurrency = NumberFormat.compactSimpleCurrency(name: '₱ ');

    return Scrollbar(
      controller: _heatmapScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _heatmapScrollController, // Independent controller
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const SizedBox(width: 200, child: Text('Line Item', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.grey))),
                  const SizedBox(width: 80, child: Center(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.grey)))),
                  ...months.map((m) => SizedBox(width: 50, child: Center(child: Text(m, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.grey))))),
                ],
              ),
              const SizedBox(height: 16),
              ...displayActivities.map((a) {
                final List<double> monthlyValues = List.generate(12, (_) => 0.0);
                if (a.monthlyDistribution != null && a.monthlyDistribution!.length == 12) {
                  for (int i = 0; i < 12; i++) {
                    monthlyValues[i] = a.monthlyDistribution![i];
                  }
                } else {
                  final qBudgets = [a.q1Budget, a.q2Budget, a.q3Budget, a.q4Budget];
                  for (int q = 0; q < 4; q++) {
                    final monthly = qBudgets[q] / 3;
                    for (int m = 0; m < 3; m++) {
                      monthlyValues[q * 3 + m] = monthly;
                    }
                  }
                }
                return _buildHeatmapRow(a.activityName, formatCurrency.format(a.approvedBudget), monthlyValues.map((e) => e.toInt()).toList());
              }),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              _buildHeatmapRow('TOTAL', formatCurrency.format(grandTotal), totals.map((e) => e.toInt()).toList(), isTotal: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapRow(String title, String total, List<int> values, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 200, 
            child: Text(
              title, 
              overflow: TextOverflow.ellipsis, 
              style: TextStyle(
                fontSize: 11, 
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal ? Colors.black : Colors.black87,
              )
            )
          ),
          SizedBox(
            width: 80, 
            child: Center(
              child: Text(
                total, 
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w800,
                  color: isTotal ? AppColors.emeraldPrimary : Colors.black54,
                )
              )
            )
          ),
          ...values.map((v) => SizedBox(
            width: 50,
            child: Container(
              height: 32,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _getHeatmapColor(v, isTotal),
                borderRadius: BorderRadius.circular(6),
                boxShadow: v > 0 && !isTotal ? [
                  BoxShadow(
                    color: _getHeatmapColor(v, isTotal).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ] : null,
              ),
              child: Center(
                child: Text(
                  v == 0 ? '-' : _formatValue(v),
                  style: TextStyle(
                    fontSize: 9, 
                    fontWeight: FontWeight.w700,
                    color: v > 100000 ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  String _formatValue(int v) {
    if (v >= 1000000) return '${(v/1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v/1000).toStringAsFixed(0)}k';
    return v.toString();
  }

  Color _getHeatmapColor(int value, bool isTotal) {
    if (value == 0) return Colors.grey.shade50;
    if (isTotal) return AppColors.emeraldPrimary.withValues(alpha: 0.1);
    
    // Gradient based on value
    if (value < 50000) return const Color(0xFFD1FAE5);
    if (value < 100000) return const Color(0xFF6EE7B7);
    if (value < 300000) return const Color(0xFF10B981);
    return const Color(0xFF059669);
  }
}

