import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/app_colors.dart';
import '../../../core/design_system.dart';
import '../../../models/activity.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: activeColor),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                if (trend != null) ...[
                  const SizedBox(width: 8),
                  trend!,
                ],
              ],
            ),
          ),
          if (subtitle != null || percentage != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (percentage != null)
                  Text(
                    '${(percentage! * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                    ),
                  ),
                if (percentage != null && subtitle != null)
                  const SizedBox(width: 6),
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget vs. Actual (M)',
                style: AppDesignSystem.headingSmall,
              ),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: activities.isEmpty 
              ? const Center(child: Text('No data available'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxVal * 1.2).ceilToDouble(),
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= topSectors.length) return const SizedBox();
                            final sector = topSectors[idx];
                            // Abbreviate sector names if too long
                            String text = sector;
                            if (text.length > 8) {
                              text = text.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join();
                            }
                            return SideTitleWidget(
                              meta: meta, 
                              child: Text(text, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10))
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text('${value.toInt()}M', style: const TextStyle(color: Colors.grey, fontSize: 10)),
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
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: const Color(0xFF3B82F6), width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
        BarChartRodData(toY: y2, color: const Color(0xFF10B981), width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
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
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
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
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Allocation by Source', style: AppDesignSystem.headingSmall),
          const SizedBox(height: 32),
          activities.isEmpty 
            ? const SizedBox(height: 200, child: Center(child: Text('No data available')))
            : Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: List.generate(sortedSources.length, (index) {
                            final source = sortedSources[index];
                            final value = sourceTotals[source]!;
                            return PieChartSectionData(
                              color: colors[index % colors.length], 
                              value: value, 
                              title: '', 
                              radius: 20
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black),
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
  final formatCurrency = NumberFormat.simpleCurrency(name: '₱ ');

  @override
  Widget build(BuildContext context) {
    final filteredActivities = widget.activities.where((a) => a.matchesSearch(searchQuery)).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.list_alt_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text('Project List & Line Items', style: AppDesignSystem.headingSmall, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              horizontalMargin: 0,
              columns: const [
                DataColumn(label: Text('PROJECT NAME / LINE ITEM')),
                DataColumn(label: Text('BUDGET')),
                DataColumn(label: Text('PR AMOUNT')),
                DataColumn(label: Text('PO AMOUNT')),
                DataColumn(label: Text('BALANCE')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: filteredActivities.map((activity) {
                final balance = activity.unexpendedBalance;
                Color statusColor = Colors.blue;
                if (activity.status.toLowerCase() == 'completed') statusColor = Colors.green;
                if (activity.status.toLowerCase() == 'planned') statusColor = Colors.grey;
                if (activity.status.toLowerCase().contains('no budget')) statusColor = Colors.red;

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
        ],
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Activity activity, String title, String budget, String pr, String po, String balance, String status, Color statusColor) {
    return DataRow(cells: [
      DataCell(SizedBox(width: 180, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)))),
      DataCell(Text(budget)),
      DataCell(Text(pr)),
      DataCell(Text(po)),
      DataCell(Text(balance)),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
        child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
      )),
      DataCell(IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {
        context.read<ActivityFormProvider>().openForm(activity: activity);
      })),
    ]);
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search projects or line items...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        _filterDropdown('All Departments'),
        const SizedBox(width: 12),
        _filterDropdown('2025'),
        const SizedBox(width: 12),
        _filterDropdown('Status'),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => context.read<ActivityFormProvider>().openForm(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Project'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _filterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

/// WFP Heatmap View
class PPMPHeatmapView extends StatelessWidget {
  const PPMPHeatmapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WFP Heatmap View', style: AppDesignSystem.headingSmall),
          const SizedBox(height: 24),
          _buildHeatmapFilters(),
          const SizedBox(height: 24),
          _buildHeatmapGrid(),
          const SizedBox(height: 16),
          Text('All amounts in Philippine Peso (₱)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
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
            foregroundColor: Colors.grey.shade700,
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
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    // Minimum width: 150 (title) + 60 (total) + 12*35 (month cols) = 630
    const double minHeatmapWidth = 700;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: minHeatmapWidth),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const SizedBox(width: 150, child: Text('Project Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                const SizedBox(width: 60, child: Center(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                ...months.map((m) => SizedBox(width: 40, child: Center(child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))))),
              ],
            ),
            const SizedBox(height: 12),
            _buildHeatmapRow('CAFC Quarterly Meeting', '₱ 67,010', [0, 20000, 0, 0, 20000, 0, 0, 20000, 0, 0, 7010, 0]),
            _buildHeatmapRow('Procurement of Common Office Supplies', '₱ 250,000', [0, 50000, 50000, 50000, 50000, 50000, 0, 0, 0, 0, 0, 0]),
            _buildHeatmapRow('Procurement of IT Equipment', '₱ 1,500,000', [0, 300000, 300000, 300000, 300000, 300000, 0, 0, 0, 0, 0, 0]),
            _buildHeatmapRow('Conduct of Training - CHEDS', '₱ 120,000', [0, 0, 0, 60000, 0, 0, 60000, 0, 0, 0, 0, 0]),
            const Divider(),
            _buildHeatmapRow('Total', '₱ 1,937,010', [0, 370000, 350000, 410000, 370000, 350000, 60000, 20000, 0, 0, 7010, 0], isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapRow(String title, String total, List<int> values, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal))),
          SizedBox(width: 60, child: Center(child: Text(total, style: TextStyle(fontSize: 10, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600)))),
          ...values.map((v) => SizedBox(
            width: 40,
            child: Container(
              height: 30,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: _getHeatmapColor(v, isTotal),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Text(
                  v == 0 ? '0' : _formatValue(v),
                  style: TextStyle(fontSize: 9, color: v > 100000 ? Colors.white : Colors.black87),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  String _formatValue(int v) {
    if (v >= 1000) return '${(v/1000).toStringAsFixed(0)}k';
    return v.toString();
  }

  Color _getHeatmapColor(int value, bool isTotal) {
    if (value == 0) return Colors.grey.shade100;
    if (isTotal) return Colors.grey.shade300;
    
    // Gradient based on value
    if (value < 50000) return const Color(0xFFD1FAE5);
    if (value < 100000) return const Color(0xFF6EE7B7);
    if (value < 300000) return const Color(0xFF10B981);
    return const Color(0xFF059669);
  }
}
