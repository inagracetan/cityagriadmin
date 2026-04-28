import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart';
import '../services/file_saver.dart';
import 'agri_ui.dart';
import '../core/constants.dart';

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
        await saveFile(buffer, 'budget_allocation_chart', '.png');
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
    final formatCurrency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
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
      child: AgriHoverCard(
        padding: const EdgeInsets.all(24.0),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Theme.of(context).cardColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sector Budget Distribution',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: PieChart(
                          PieChartData(
                            sections: sections
                                .map(
                                  (s) => s.copyWith(
                                    radius: 100,
                                    titleStyle: s.titleStyle?.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                                .toList(),
                            centerSpaceRadius: 80,
                            sectionsSpace: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: List.generate(sortedSectors.length, (index) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${sortedSectors[index]}: ${formatCurrency.format(sectorBudgets[sortedSectors[index]]!)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Appropriation by Section/Unit',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Opacity(
                  opacity: _isExporting ? 0.0 : 1.0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 20,
                      color: Color(0xFF1976D2),
                    ),
                    tooltip: 'Download Chart Image',
                    onPressed: _isExporting ? null : _exportChart,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 50,
                  sectionsSpace: 4,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(sortedSectors.length, (index) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${abbreviate(sortedSectors[index])}: ${sortedSectors[index]}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }),
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
