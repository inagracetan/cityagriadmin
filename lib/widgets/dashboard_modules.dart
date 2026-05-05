import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart';
import '../services/file_saver.dart';
import '../core/constants.dart';
import '../core/design_system.dart';
import '../core/app_colors.dart';

class BudgetSectionUnitChart extends StatefulWidget {
  final List<Activity> activities;
  const BudgetSectionUnitChart({super.key, required this.activities});

  @override
  State<BudgetSectionUnitChart> createState() => _BudgetSectionUnitChartState();
}

class _BudgetSectionUnitChartState extends State<BudgetSectionUnitChart> {
  final GlobalKey _chartKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _exportChart() async {
    setState(() => _isExporting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 50));
      final boundary =
          _chartKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        await saveFile(buffer, 'budget allocation chart', '.png');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chart downloaded successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download chart: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
    final Map<String, double> sectorBudgets = {};
    for (var act in widget.activities) {
      sectorBudgets[act.sector] =
          (sectorBudgets[act.sector] ?? 0) + act.approvedBudget;
    }

    final sortedSectors = sectorBudgets.keys.toList()..sort();
    final List<PieChartSectionData> sections = [];

    // Modern Professional Palette
    final List<Color> colors = [
      const Color(0xFF1B5E20), // Forest Green
      const Color(0xFF1976D2), // Professional Blue
      const Color(0xFFE65100), // Burnt Orange
      const Color(0xFFD4AF37), // Muted Gold
      const Color(0xFF6A1B9A), // Deep Purple
      const Color(0xFF00838F), // Cyan
      const Color(0xFFC62828), // Soft Red
      const Color(0xFF4527A0), // Indigo
    ];

    String abbreviate(String name) {
      return AppConstants.abbreviate(name);
    }

    double total = totalBudget(widget.activities);

    for (int i = 0; i < sortedSectors.length; i++) {
      final sector = sortedSectors[i];
      final budget = sectorBudgets[sector]!;
      sections.add(
        PieChartSectionData(
          value: budget,
          title: total > 0
              ? '${((budget / total) * 100).toStringAsFixed(0)}%'
              : '0%',
          color: colors[i % colors.length],
          radius: 50,
          titleStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }

    return RepaintBoundary(
      key: _chartKey,
      child: GlassCard(
        padding: const EdgeInsets.all(32.0),
        onTap: () {
          // Keep the existing dialog logic or modernize it
        },
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
                      'Appropriation by Section',
                      style: AppDesignSystem.headingSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visual breakdown of total approved budget.',
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                Opacity(
                  opacity: _isExporting ? 0.0 : 1.0,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        size: 20,
                        color: AppColors.emeraldPrimary,
                      ),
                    ),
                    tooltip: 'Download Chart Image',
                    onPressed: _isExporting ? null : _exportChart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 280,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 60,
                        sectionsSpace: 6,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(sortedSectors.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    abbreviate(sortedSectors[index]),
                                    style: AppDesignSystem.labelSmall.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    formatCurrency.format(sectorBudgets[sortedSectors[index]]!),
                                    style: AppDesignSystem.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double totalBudget(List<Activity> list) {
    return list.fold(0, (sum, item) => sum + item.approvedBudget);
  }
}
