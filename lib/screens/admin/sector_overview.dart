import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../models/activity.dart';
import 'package:intl/intl.dart';
import '../../services/navigation_provider.dart';
import '../../services/settings_provider.dart';
import '../../widgets/agri_ui.dart';
import '../../core/constants.dart';
import 'activity_details_dialog.dart';
import 'edit_activity_dialog.dart';
import '../../core/responsive_utils.dart';
import '../../core/app_colors.dart';

class SectionUnitOverviewScreen extends StatefulWidget {
  final bool isActive;
  const SectionUnitOverviewScreen({super.key, this.isActive = true});

  @override
  State<SectionUnitOverviewScreen> createState() =>
      _SectionUnitOverviewScreenState();
}

class _SectionUnitOverviewScreenState extends State<SectionUnitOverviewScreen> {
  final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
  Stream<List<Activity>>? _activitiesStream;
  String _searchQuery = '';
  String _selectedMonth = '';
  String _selectedYear = DateTime.now().year.toString();

  @override
  void didUpdateWidget(SectionUnitOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateNav();
      });
    }
  }

  void _updateNav() {
    final navProvider = context.read<NavigationProvider>();
    final l10n = context.read<SettingsProvider>().l10n;
    navProvider.updateLayout(
      title: l10n.translate('section_unit_allocation'),
      actions: [],
      fab: null,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isActive) _updateNav();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fbService = context.read<FirebaseService>();
    _activitiesStream ??= fbService.streamActivities();

    return StreamBuilder<List<Activity>>(
      stream: _activitiesStream!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: AgriUI.tableShimmer(),
          );
        }

        final rawActivities = snapshot.data ?? [];
        final activities = rawActivities.where((a) {
          if (_selectedMonth.isNotEmpty &&
              !a.targetDate.toLowerCase().contains(_selectedMonth.toLowerCase())) {
            return false;
          }
          if (_selectedYear.isNotEmpty && !a.targetDate.contains(_selectedYear)) {
            return false;
          }
          return a.matchesSearch(_searchQuery);
        }).toList();

        if (activities.isEmpty && _searchQuery.isEmpty) {
          return AgriUI.emptyState(
            icon: Icons.pie_chart_outline,
            title: 'No Data Available',
            message:
                'There are no activities to display in the sector overview yet.',
          );
        }
        final Map<String, List<Activity>> sectorGroups = {};

        // Pre-populate with all known sectors to ensure they're always shown
        for (final s in AppConstants.sectors) {
          sectorGroups[s] = [];
        }

        for (var act in activities) {
          sectorGroups.putIfAbsent(act.sector, () => []).add(act);
        }

        final sectors = sectorGroups.keys.toList()..sort();

        final grandTotal = activities.fold(0.0, (s, a) => s + a.approvedBudget);
        final grandSpent = activities.fold(
          0.0,
          (s, a) => s + a.actualExpenditure,
        );
        final grandUtilRate = grandTotal > 0 ? grandSpent / grandTotal : 0.0;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText:
                          'Search sectors by activity, staff, or details (abbreviations allowed)...',
                      hintStyle: GoogleFonts.inter(
                        color: Slate.shade400,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.search_rounded,
                          color: Color(0xFF1B5E20),
                          size: 22,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : Slate.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Slate.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF1B5E20),
                          width: 2.0,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final monthDropdown = DropdownMenu<String>(
                    initialSelection:
                        _selectedMonth.isEmpty ? null : _selectedMonth,
                    enableSearch: true,
                    enableFilter: true,
                    menuHeight: 250,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Target Month'),
                    dropdownMenuEntries: AppConstants.months
                        .map((s) => DropdownMenuEntry(value: s, label: s))
                        .toList(),
                    onSelected:
                        (val) => setState(() => _selectedMonth = val ?? ''),
                  );

                  final yearDropdown = DropdownMenu<String>(
                    initialSelection:
                        _selectedYear.isEmpty ? null : _selectedYear,
                    enableSearch: true,
                    enableFilter: true,
                    menuHeight: 250,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Target Year'),
                    dropdownMenuEntries: AppConstants.years
                        .map((s) => DropdownMenuEntry(value: s, label: s))
                        .toList(),
                    onSelected:
                        (val) => setState(() => _selectedYear = val ?? ''),
                  );

                  final clearBtn = IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF9CA3AF),
                    ),
                    onPressed: () => setState(() {
                      _selectedMonth = '';
                      _selectedYear = DateTime.now().year.toString();
                    }),
                  );

                  if (constraints.maxWidth < ResponsiveUtils.mobileBreakpoint) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        monthDropdown,
                        const SizedBox(height: 12),
                        yearDropdown,
                        const SizedBox(height: 4),
                        Align(alignment: Alignment.centerRight, child: clearBtn),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: monthDropdown),
                      const SizedBox(width: 12),
                      Expanded(child: yearDropdown),
                      const SizedBox(width: 4),
                      clearBtn,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: activities.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No matching activities found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: ResponsiveUtils.screenPadding(context),
                      children: [
                        // ── Summary header card ───────────────────────────────────────
                        _buildGrandSummaryCard(
                          grandTotal: grandTotal,
                          grandSpent: grandSpent,
                          grandUtilRate: grandUtilRate,
                          sectorCount: sectors.length,
                          activityCount: activities.length,
                        ),
                        const SizedBox(height: 16),
                        // ── Sector cards ─────────────────────────────────────────────
                        ...sectors.map((sector) {
                          final acts = sectorGroups[sector]!;
                          if (acts.isEmpty && _searchQuery.isNotEmpty) {
                            return const SizedBox.shrink();
                          }
                          return _buildSectorCard(sector, acts, fbService);
                        }),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  // ── Grand Summary ────────────────────────────────────────────────────────

  Widget _buildGrandSummaryCard({
    required double grandTotal,
    required double grandSpent,
    required double grandUtilRate,
    required int sectorCount,
    required int activityCount,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF064E3B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.donut_large_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OVERALL UTILIZATION',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sectorCount Section/Units · $activityCount Activities',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(grandUtilRate * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatCurrency.format(grandSpent),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: isMobile ? 32 : 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Spent out of ${formatCurrency.format(grandTotal)} Total Budget',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: grandUtilRate.clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF9D423)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sector Card ──────────────────────────────────────────────────────────

  Widget _buildSectorCard(
    String sector,
    List<Activity> acts,
    FirebaseService fbService,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final total = acts.fold(0.0, (sum, a) => sum + a.approvedBudget);
    final spent = acts.fold(0.0, (sum, a) => sum + a.actualExpenditure);
    final balance = total - spent;
    final utilRate = total > 0 ? spent / total : 0.0;

    final Map<String, int> statusCount = {};
    for (final a in acts) {
      statusCount[a.status] = (statusCount[a.status] ?? 0) + 1;
    }

    final isOverspent = spent > total && total > 0;
    final headerColor = isOverspent
        ? Colors.red.shade700
        : _sectorColor(sector);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                sector.isNotEmpty ? sector[0] : '?',
                style: TextStyle(
                  color: headerColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sector,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 15 : 17,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              if (acts.any((a) => a.unitHead != null && a.unitHead!.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Head: ${acts.firstWhere((a) => a.unitHead != null && a.unitHead!.isNotEmpty).unitHead}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: utilRate.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverspent ? Colors.red : headerColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(utilRate * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isOverspent ? Colors.red : headerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Allocation: ${formatCurrency.format(total)}  ·  Spent: ${formatCurrency.format(spent)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatCurrency.format(balance),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile ? 14 : 16,
                    letterSpacing: -0.5,
                    color: isOverspent
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF059669),
                  ),
                ),
              ),
              Text(
                isOverspent ? 'OVERSPENT' : 'REMAINING',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: isOverspent
                      ? const Color(0xFFE11D48).withValues(alpha: 0.7)
                      : Slate.shade400,
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            ...acts.map((a) => _buildActivityRow(a, fbService)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(Activity a, FirebaseService fbService) {
    final theme = Theme.of(context);
    final utilRate = a.approvedBudget > 0
        ? a.actualExpenditure / a.approvedBudget
        : 0.0;
    final isLowBalance = a.isLowBalance;
    final isOverspent = a.actualExpenditure > a.approvedBudget;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.02)
              : Slate.shade50.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.03),
          ),
        ),
        child: InkWell(
          onTap: () => _showActivityDetails(context, a, fbService),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.activityName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: -0.2,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (a.targetDate.isNotEmpty ||
                              (a.location?.isNotEmpty ?? false))
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 10,
                                    color: Slate.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    a.targetDate,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Slate.shade500,
                                    ),
                                  ),
                                  if (a.location != null && a.location!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 10,
                                      color: Slate.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      a.location!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Slate.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isLowBalance || isOverspent)
                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: (isOverspent ? Colors.red : Colors.orange)
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOverspent ? Icons.priority_high_rounded : Icons.warning_amber_rounded,
                          size: 14,
                          color: isOverspent ? Colors.red : Colors.orange,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Slate.shade100,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: utilRate.clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOverspent
                              ? Colors.red
                              : isLowBalance
                                  ? Colors.orange
                                  : Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      context,
                      'Budget',
                      formatCurrency.format(a.approvedBudget),
                      Slate.shade500,
                    ),
                    _buildInfoChip(
                      context,
                      'Spent',
                      formatCurrency.format(a.actualExpenditure),
                      isOverspent ? Colors.red : Colors.orange.shade700,
                      isBold: true,
                    ),
                    _buildInfoChip(
                      context,
                      'Balance',
                      formatCurrency.format(a.unexpendedPPMP),
                      a.unexpendedPPMP < 0 ? Colors.red : Colors.green.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Slate.shade400,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────


  Color _sectorColor(String sector) {
    const colors = [
      Color(0xFF1B5E20), // Deep Forest
      Color(0xFFD4AF37), // Metallic Gold
      Color(0xFF166534), // Hunter Green
      Color(0xFFA18219), // Antique Gold
      Color(0xFF2E7D32), // Success Green
      Color(0xFF4B5563), // Slate Gray
      Color(0xFF374151), // Dark Slate
      Color(0xFF064E3B), // Emerald Black
    ];
    final idx = sector.hashCode.abs() % colors.length;
    return colors[idx];
  }

  // ── dialog launchers ─────────────────────────────────────────────────────

  void _showActivityDetails(
    BuildContext context,
    Activity activity,
    FirebaseService fbService,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => ActivityDetailsDialog(
        activity: activity,
        fbService: fbService,
        onEdit: () {
          Navigator.pop(ctx);
          _showEditActivityDialog(context, activity, fbService);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDelete(context, activity, fbService);
        },
      ),
    );
  }

  void _showEditActivityDialog(
    BuildContext context,
    Activity activity,
    FirebaseService fbService,
  ) {
    showDialog(
      context: context,
      builder: (_) =>
          EditActivityDialog(fbService: fbService, activity: activity),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Activity activity,
    FirebaseService fbService,
  ) async {
    final l10n = context.read<SettingsProvider>().l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.translate('delete_activity')),
          ],
        ),
        content: Text(
          '${l10n.translate('delete_confirm_msg')} "${activity.activityName}"?\n\n${l10n.translate('delete_associated_msg')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await fbService.deleteActivity(activity.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"${activity.activityName}" ${l10n.translate('delete_success')}',
              ),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete error: $e')));
        }
      }
    }
  }
}
