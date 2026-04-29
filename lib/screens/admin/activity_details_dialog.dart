import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/activity.dart';
import '../../core/date_formatter.dart';
import '../../models/pr_log.dart';
import '../../services/firebase_service.dart';
import '../../core/responsive_utils.dart';

class ActivityDetailsDialog extends StatefulWidget {
  final Activity activity;
  final FirebaseService fbService;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ActivityDetailsDialog({
    super.key,
    required this.activity,
    required this.fbService,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ActivityDetailsDialog> createState() => _ActivityDetailsDialogState();
}

class _ActivityDetailsDialogState extends State<ActivityDetailsDialog> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _historyKey = GlobalKey();

  Activity get activity => widget.activity;
  FirebaseService get fbService => widget.fbService;
  VoidCallback? get onEdit => widget.onEdit;
  VoidCallback? get onDelete => widget.onDelete;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHistory() {
    Scrollable.ensureVisible(
      _historyKey.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
    final activity = widget.activity;

    final isLowBalance = activity.isLowBalance;

    final isMobile = ResponsiveUtils.isMobile(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 0 : 24),
      ),
      clipBehavior: Clip.antiAlias,
      insetPadding: isMobile
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      backgroundColor: theme.colorScheme.surface,
      child: Container(
        width: double.infinity,
        height: isMobile ? double.infinity : null,
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: isMobile ? double.infinity : 900,
        ),
        child: Column(
          children: [
            // Header (Premium Gradient + Elegant Title)
            Container(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 28,
                isMobile ? 32 : 28,
                16,
                isMobile ? 20 : 28,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF064E3B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (isMobile)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.activityName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        if (activity.sector.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.business_center_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  activity.sector,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 24,
                    ),
                  ),
                ],
              ),
            ),

            if (onEdit != null || onDelete != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (onEdit != null)
                        _actionButton(
                          context,
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: theme.primaryColor,
                          onPressed: onEdit!,
                        ),

                      const SizedBox(width: 12),
                      _actionButton(
                        context,
                        icon: Icons.receipt_long_outlined,
                        label: 'PR Logs',
                        color: Colors.orange.shade800,
                        onPressed: _scrollToHistory,
                      ),

                      if (onDelete != null) ...[
                        const SizedBox(width: 12),
                        _actionButton(
                          context,
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          color: Colors.red,
                          onPressed: onDelete!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      context,
                      Icons.info_outline,
                      'Overview',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: _buildInfoGrid([
                        _buildInfoItem(
                          context,
                          'Section/Unit Head',
                          activity.unitHead ?? 'N/A',
                        ),
                        _buildInfoItem(
                          context,
                          'Sub-Sector',
                          activity.subSector ?? 'N/A',
                        ),
                        _buildInfoItem(
                          context,
                          'Performance Indicator',
                          activity.performanceIndicator,
                          isFullWidth: true,
                        ),
                        _buildInfoItem(
                          context,
                          'Target Number',
                          activity.targetNo.toString(),
                        ),
                        _buildInfoItem(
                          context,
                          'Location',
                          activity.location ?? 'N/A',
                        ),
                        _buildInfoItem(
                          context,
                          'Responsible Person',
                          activity.responsiblePerson,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      context,
                      Icons.account_balance_wallet_outlined,
                      'Financial Details',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (activity.fundSources.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                                child: Text(
                                'Funding Source & Expenditures',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  color: theme.primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(2),
                                2: FlexColumnWidth(1.2),
                              },
                              children: [
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        'Expenditure / Program',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: theme.disabledColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        'Funding Source',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: theme.disabledColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        'Allocated',
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: theme.disabledColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ...activity.fundSources.map(
                                  (fs) => TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          fs.objectOfExpenditure ?? 'N/A',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          fs.fundingSource,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          formatCurrency.format(fs.amount),
                                          textAlign: TextAlign.right,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],
                          _buildInfoGrid([
                            if (activity.fundSources.isEmpty) ...[
                              _buildInfoItem(
                                context,
                                'Funding Source',
                                activity.fundingSource,
                              ),
                              _buildInfoItem(
                                context,
                                'Object of Expenditure',
                                _getObjectOfExpenditureStr(),
                              ),
                            ],
                            _buildInfoItem(
                              context,
                              'Other MOE Suppliers',
                              activity.otherMoeSuppliers.isNotEmpty
                                  ? activity.otherMoeSuppliers
                                  : 'N/A',
                            ),
                            _buildInfoItem(
                              context,
                              'Unexpended Balance',
                              formatCurrency.format(activity.unexpendedBalance),
                              valueColor: isLowBalance
                                  ? Colors.red
                                  : theme.primaryColor,
                              isBold: true,
                              highlight: true,
                            ),
                            if (activity.fundingInputtedBy != null)
                              _buildInfoItem(
                                context,
                                'Funding Source Inputted By',
                                activity.fundingInputtedBy!,
                              ),
                          ]),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(),
                          ),
                          _buildInfoGrid([
                            _buildInfoItem(
                              context,
                              'ALLOCATED BUDGET',
                              formatCurrency.format(activity.totalBudget),
                            ),
                            _buildInfoItem(
                              context,
                              'MID-YEAR BUDGET',
                              formatCurrency.format(activity.midYearBudget),
                            ),
                            _buildInfoItem(
                              context,
                              'TOTAL PO AMOUNT',
                              formatCurrency.format(activity.effectivePOAmount),
                              valueColor: Colors.orange.shade800,
                            ),
                            _buildInfoItem(
                              context,
                              'PPMP BALANCE',
                              formatCurrency.format(activity.ppmpBalance),
                            ),
                          ]),
                        ],
                      ),
                    ),

                    if (activity.breakdown.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        Icons.list_alt_outlined,
                        'Budget Breakdown (TOTAL PO AMOUNT)',
                      ),
                      const SizedBox(height: 12),
                      _buildBreakdownSection(context, activity),
                    ],
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      context,
                      Icons.event_note_outlined,
                      'Status & Timeline',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: _buildInfoGrid([

                        _buildInfoItem(
                          context,
                          'Target Date',
                          activity.targetDate,
                        ),
                        _buildInfoItem(
                          context,
                          'Fiscal Quarter',
                          activity.quarter,
                        ),
                        _buildInfoItem(
                          context,
                          'Target Participants',
                          activity.targetParticipants.isNotEmpty
                              ? activity.targetParticipants
                              : 'N/A',
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoGrid([
                      _buildInfoItem(
                        context,
                        'Actual Conduct',
                        activity.actualConduct.isNotEmpty
                            ? activity.actualConduct
                            : 'N/A',
                        isFullWidth: true,
                      ),
                      _buildInfoItem(
                        context,
                        'ACCOM Remarks',
                        activity.accommRemarks.isNotEmpty
                            ? activity.accommRemarks
                            : 'N/A',
                        isFullWidth: true,
                      ),
                    ]),
                    const Divider(height: 48),

                    _buildSectionHeader(
                      context,
                      Icons.history_outlined,
                      'Purchase Request History',
                      key: _historyKey,
                    ),
                    const SizedBox(height: 20),
                    _buildPRHistory(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        backgroundColor: color.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildBreakdownSection(BuildContext context, Activity activity) {
    final theme = Theme.of(context);
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
    final total = activity.breakdown.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final colors = [
      const Color(0xFF1B5E20),
      const Color(0xFF1976D2),
      const Color(0xFFE65100),
      const Color(0xFFD4AF37),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
      const Color(0xFFC62828),
      const Color(0xFF4527A0),
    ];

    final sections = List.generate(activity.breakdown.length, (i) {
      final item = activity.breakdown[i];
      final percentage = total > 0 ? (item.amount / total) * 100 : 0.0;
      return PieChartSectionData(
        value: item.amount,
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[i % colors.length],
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });

    final Map<String, List<BreakdownItem>> grouped = {};
    for (final item in activity.breakdown) {
      final fs = (item.fundingSource != null && item.fundingSource!.isNotEmpty)
          ? item.fundingSource!
          : activity.fundingSource;
      grouped.putIfAbsent(fs, () => []).add(item);
    }

    final groupWidgets = <Widget>[];
    var groupIndex = 0;
    grouped.forEach((fsLabel, items) {
      final groupColor = colors[groupIndex % colors.length];

      groupWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: groupColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: groupColor, width: 3)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 14, color: groupColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fsLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: groupColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      groupWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.list_alt, size: 14, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Text(
                'DETAILED BREAKDOWN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey[700],
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );

      groupWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Description',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.primaryColor),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Unit/Qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.primaryColor),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Qtr',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.primaryColor),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'PO Amount',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.primaryColor),
                ),
              ),
            ],
          ),
        ),
      );

      for (final item in items) {
        groupWidgets.add(_buildBreakdownItem(context, item));
      }

      final groupTotal = items.fold(0.0, (sum, e) => sum + e.amount);
      groupWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ),
              Text(
                formatCurrency.format(groupTotal),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: groupColor,
                ),
              ),
            ],
          ),
        ),
      );

      if (groupIndex < grouped.length - 1) {
        groupWidgets.add(const Divider(height: 12));
      }
      groupIndex++;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _showFullBreakdownChart(context, activity),
              child: Container(
                width: 180,
                height: 180,
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                    const Center(child: Icon(Icons.zoom_in, color: Colors.black26, size: 20)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...groupWidgets,
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'GRAND TOTAL',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  formatCurrency.format(total),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullBreakdownChart(BuildContext context, Activity activity) {
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
    final total = activity.breakdown.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final colors = [
      const Color(0xFF1B5E20),
      const Color(0xFF1976D2),
      const Color(0xFFE65100),
      const Color(0xFFD4AF37),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
      const Color(0xFFC62828),
      const Color(0xFF4527A0),
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF111111).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget Breakdown Analysis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: List.generate(activity.breakdown.length, (i) {
                      final item = activity.breakdown[i];
                      final percentage = total > 0
                          ? (item.amount / total) * 100
                          : 0.0;
                      return PieChartSectionData(
                        value: item.amount,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        title: '${percentage.toStringAsFixed(1)}%',
                        color: colors[i % colors.length],
                        radius: 100,
                        badgeWidget: _buildChartBadge(
                          item.name,
                          colors[i % colors.length],
                        ),
                        badgePositionPercentageOffset: 1.1,
                      );
                    }),
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(activity.breakdown.length, (i) {
                  final item = activity.breakdown[i];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: colors[i % colors.length],
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${item.fullDisplayNameWithFallback(activity.fundingSource, activity.objectOfExpenditure)}: ${formatCurrency.format(item.amount)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
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
      ),
    );
  }

  Widget _buildChartBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context,
    BreakdownItem e,
  ) {
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
    final isMobile = ResponsiveUtils.isMobile(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (e.supplier != null && e.supplier!.isNotEmpty)
                      Text(
                        'Supplier: ${e.supplier}',
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${e.unit ?? "pcs"} / ${e.quantity ?? 0}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Q${e.quarter ?? 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency.format(e.amount),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    if (e.price != null && e.price! > 0)
                      Text(
                        '@ ${formatCurrency.format(e.price)}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (e.status != null && e.status!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'STATUS: ${e.status}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                  if (e.statusDate != null && e.statusDate!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${e.statusDate})',
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title, {
    Key? key,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Row(
        key: key,
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<Widget> items) {
    return Wrap(spacing: 32, runSpacing: 24, children: items);
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    Color? badgeColor,
    bool isFullWidth = false,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: isFullWidth ? double.infinity : 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          if (badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Text(
                value,
                style: GoogleFonts.inter(
                  color: badgeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: highlight ? 24 : 16,
                fontWeight: (isBold || highlight)
                    ? FontWeight.w900
                    : FontWeight.w700,
                color: valueColor ?? theme.textTheme.titleMedium?.color,
                letterSpacing: highlight ? -0.8 : 0,
                height: 1.2,
              ),
            ),
        ],
      ),
    );
  }

  String _getObjectOfExpenditureStr() {
    return activity.objectOfExpenditure ?? 'N/A';
  }


  Widget _buildPRHistory(BuildContext context) {
    return StreamBuilder<List<PRLog>>(
      stream: fbService.streamPRLogs(activity.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_toggle_off_outlined,
                  size: 32,
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'No PR history recorded yet.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final log = logs[index];
            return _buildLogItem(context, log);
          },
        );
      },
    );
  }

  Widget _buildLogItem(BuildContext context, PRLog log) {
    final theme = Theme.of(context);
    final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
    final formatDate = DateFormat('MMM dd, yyyy • hh:mm a');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              Text(
                formatDate.format(log.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: theme.disabledColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: 16,
                          color: theme.primaryColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PR #: ${log.prNumber.isNotEmpty ? log.prNumber : "N/A"}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    if (log.amount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          formatCurrency.format(log.amount),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (log.updatedBy != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'UPDATED BY',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: theme.primaryColor.withValues(alpha: 0.5),
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        log.updatedBy!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (log.remarks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
              ),
              child: Text(
                log.remarks,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
