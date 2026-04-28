import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../models/activity.dart';
import '../../core/date_formatter.dart';
import '../../models/user_model.dart';
import '../../services/navigation_provider.dart';
import '../../services/settings_provider.dart';
import '../../core/localization.dart';
import '../../widgets/agri_ui.dart';
import '../../core/constants.dart';
import '../../core/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_file/open_file.dart';
import '../../services/export_service.dart';
import 'activity_details_dialog.dart';
import 'edit_activity_dialog.dart';
import '../../core/responsive_utils.dart';

class FinancialReportsScreen extends StatefulWidget {
  final bool isActive;
  const FinancialReportsScreen({super.key, this.isActive = true});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');

  // Sorting state
  ReportSortType _sectorSort = ReportSortType.name;
  bool _sectorAsc = true;
  ReportSortType _staffSort = ReportSortType.name;
  bool _staffAsc = true;
  Stream<List<Activity>>? _activitiesStream;
  String _searchQuery = '';

  @override
  void didUpdateWidget(FinancialReportsScreen oldWidget) {
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
      title: l10n.translate('financial_reports'),
      actions: [
        IconButton(
          icon: const Icon(Icons.download, color: Color(0xFFD4AF37)),
          tooltip: l10n.translate('export_data'),
          onPressed: () => _showExportOptions(),
        ),
        IconButton(
          icon: const Icon(Icons.sort, color: Color(0xFFD4AF37)),
          tooltip: l10n.translate('sort_breakdown'),
          onPressed: () => _showSortOptions(),
        ),
      ],
      fab: null,
    );
  }

  void _showExportOptions() {
    final l10n = context.read<SettingsProvider>().l10n;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: Text(l10n.translate('export_excel')),
                onTap: () {
                  Navigator.pop(context);
                  _exportData(format: 'excel');
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(l10n.translate('export_pdf')),
                onTap: () {
                  Navigator.pop(context);
                  _exportData(format: 'pdf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet, color: Colors.blue),
                title: Text(l10n.translate('export_csv')),
                onTap: () {
                  Navigator.pop(context);
                  _exportData(format: 'csv');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportData({required String format}) async {
    final authService = context.read<AuthService>();
    final fbService = context.read<FirebaseService>();
    final l10n = context.read<SettingsProvider>().l10n;
    final messenger = ScaffoldMessenger.of(context);

    // Get latest activities for export
    final activities = await fbService.streamActivities().first;
    final user = authService.currentUser;
    final filteredActivities = user?.role == 'admin'
        ? activities
        : activities.where((a) => a.responsiblePerson == user?.name).toList();

    try {
      final exportedBy = user?.name ?? 'Reporter';
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.translate('exporting_to')} $format...')),
      );

      String? path;
      if (format == 'excel') {
        path = await ExportService.exportActivitiesToExcel(
          filteredActivities,
          exportedBy: exportedBy,
        );
      } else if (format == 'pdf') {
        path = await ExportService.exportActivitiesToPdf(
          filteredActivities,
          exportedBy: exportedBy,
        );
      } else {
        path = await ExportService.exportActivitiesToCSV(
          filteredActivities,
          exportedBy: exportedBy,
        );
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              path != null
                  ? '${l10n.translate('saved_to')}: $path'
                  : l10n.translate('export_success'),
            ),
            duration: const Duration(seconds: 5),
            action: path != null
                ? SnackBarAction(
                    label: 'OPEN',
                    onPressed: () => OpenFile.open(path),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isActive) _updateNav();
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final l10n = context.watch<SettingsProvider>().l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.translate('sort_lists_by'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: Text(l10n.translate('name')),
                onTap: () {
                  setState(() {
                    _sectorSort = ReportSortType.name;
                    _staffSort = ReportSortType.name;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments),
                title: Text(l10n.translate('budget_amount')),
                onTap: () {
                  setState(() {
                    _sectorSort = ReportSortType.budget;
                    _staffSort = ReportSortType.budget;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed),
                title: Text(l10n.translate('utilization_rate')),
                onTap: () {
                  setState(() {
                    _sectorSort = ReportSortType.utilization;
                    _staffSort = ReportSortType.utilization;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_vert),
                title: Text(l10n.translate('toggle_asc_desc')),
                onTap: () {
                  setState(() {
                    _sectorAsc = !_sectorAsc;
                    _staffAsc = !_staffAsc;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fbService = context.read<FirebaseService>();
    _activitiesStream ??= fbService.streamActivities();

    final l10n = context.watch<SettingsProvider>().l10n;
    return Column(
      children: [
        Padding(
          padding: ResponsiveUtils.screenPadding(
            context,
          ).copyWith(bottom: 8, top: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText:
                      'Search reports by activity, PR, supplier, or any details (abbreviations allowed)...',
                  hintStyle: const TextStyle(
                    color: Slate.shade400,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Slate.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Slate.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: ResponsiveUtils.screenPadding(
            context,
          ).copyWith(top: 8, bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Slate.shade500,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.04);
                }
                return null;
              }),
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                ),
              ),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              tabs: [
                Tab(
                  icon: const Icon(Icons.summarize_rounded, size: 20),
                  text: l10n.translate('summary'),
                ),
                Tab(
                  icon: const Icon(Icons.pie_chart_rounded, size: 20),
                  text: l10n.translate('by_section_unit'),
                ),
                Tab(
                  icon: const Icon(Icons.people_alt_rounded, size: 20),
                  text: l10n.translate('by_staff'),
                ),
                Tab(
                  icon: const Icon(Icons.category_rounded, size: 20),
                  text: l10n.translate('by_status'),
                ),
                Tab(
                  icon: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 20,
                  ),
                  text: l10n.translate('by_expenditure'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Activity>>(
            stream: _activitiesStream!,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AgriUI.tableShimmer(),
                );
              }
              final rawActivities = snapshot.data ?? [];
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              final user = authService.currentUser;

              // Filter activities if user is staff
              final activitiesByRole = user?.role == 'admin'
                  ? rawActivities
                  : rawActivities
                        .where((a) => a.responsiblePerson == user?.name)
                        .toList();

              final activities = activitiesByRole.where((a) {
                final matchesSearch = a.matchesSearch(_searchQuery);
                return matchesSearch;
              }).toList();
              return StreamBuilder<List<UserModel>>(
                stream: fbService.streamUsers(),
                builder: (context, userSnapshot) {
                  final users = userSnapshot.data ?? [];
                  final staffIdMap = {for (var u in users) u.name: u.staffId};

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(activities),
                      _buildSectorTab(activities),
                      _buildStaffTab(activities, staffIdMap),
                      _buildStatusTab(activities),
                      _buildExpenditureTab(activities),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── TAB 1: OVERALL SUMMARY ─────────────────────────────────────────────────
  Widget _buildSummaryTab(List<Activity> activities) {
    final overallTotalB = activities.fold(0.0, (s, a) => s + a.approvedBudget);
    final overallTotalS = activities.fold(
      0.0,
      (s, a) => s + a.actualExpenditure,
    );
    final overallTotalBalance = overallTotalB - overallTotalS;
    final overallUtilizationRate = overallTotalB > 0
        ? (overallTotalS / overallTotalB)
        : 0.0;

    final overallPPMP = activities.fold(0.0, (s, a) => s + a.ppmpBalance);
    final overallPR = activities.fold(0.0, (s, a) => s + a.prBalance);
    final overallPRTotal = activities.fold(0.0, (s, a) => s + a.prAmount);
    final overallPO = activities.fold(0.0, (s, a) => s + 0.0);
    final overallCategories = _getCategoryTotals(activities);

    final completed = activities
        .where((a) => a.status == AppConstants.statusCompleted)
        .length;
    final planned = activities
        .where((a) => a.status == AppConstants.statusPlanned)
        .length;
    final prPrepared = activities
        .where((a) => a.status == AppConstants.statusPRPrepared)
        .length;
    final bacApproved = activities
        .where((a) => a.status == AppConstants.statusBACApprovedOBRE)
        .length;
    final obreAbstract = activities
        .where((a) => a.status == AppConstants.statusObreAbstract)
        .length;
    final poPrepared = activities
        .where((a) => a.status == AppConstants.statusPOPrepared)
        .length;
    final obligated = activities
        .where((a) => a.status == AppConstants.statusObligated)
        .length;
    final iar = activities
        .where((a) => a.status == AppConstants.statusIAR)
        .length;

    final stalePRs = activities
        .where(
          (a) =>
              a.status == AppConstants.statusPRPrepared &&
              a.statusDate != null &&
              AppDateFormatter.parse(a.statusDate!)?.isBefore(
                    DateTime.now().subtract(const Duration(days: 5)),
                  ) ==
                  true,
        )
        .length;

    // Low balance activities
    final lowBalance = activities
        .where((a) => a.unexpendedBalance < 1000 && a.approvedBudget > 0)
        .length;

    final l10n = context.watch<SettingsProvider>().l10n;
    return SingleChildScrollView(
      padding: ResponsiveUtils.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGrandTotalCard(
            overallTotalB,
            overallTotalS,
            overallTotalBalance,
            overallPPMP,
            overallPO,
            overallPRTotal,
            overallPR,
            overallUtilizationRate,
            activities.length,
            l10n,
          ),
          const SizedBox(height: 16),

          _buildAnalyticsChart(activities),
          const SizedBox(height: 24),

          _buildDetailedSummaryCard(
            l10n,
            overallPR,
            overallPRTotal,
            overallPPMP,
            overallPO,
          ),

          const _SectionHeader(title: 'Activity Expenditure Summary'),
          const SizedBox(height: 8),
          _buildBreakdownSummaryTable(
            categories: overallCategories,
            ppmp: overallPPMP,
            pr: overallPR,
            prTotal: overallPRTotal,
            po: overallPO,
            l10n: l10n,
          ),
          const SizedBox(height: 16),

          _SectionHeader(title: l10n.translate('status_breakdown')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statusChip(
                _translateStatus(AppConstants.statusPlanned, l10n),
                planned,
                Colors.blue,
              ),
              _statusChip(
                _translateStatus(AppConstants.statusPRPrepared, l10n),
                prPrepared,
                Colors.orange,
              ),
              _statusChip(
                _translateStatus(AppConstants.statusBACApprovedOBRE, l10n),
                bacApproved,
                const Color(0xFFC0CA33),
              ),
              _statusChip(
                _translateStatus(AppConstants.statusObreAbstract, l10n),
                obreAbstract,
                const Color(0xFF6A1B9A),
              ),
              _statusChip(
                _translateStatus(AppConstants.statusPOPrepared, l10n),
                poPrepared,
                Colors.teal,
              ),
              _statusChip(
                _translateStatus(AppConstants.statusObligated, l10n),
                obligated,
                AppColors.warning,
              ),
              _statusChip(
                _translateStatus(AppConstants.statusIAR, l10n),
                iar,
                Colors.cyan,
              ),
              _statusChip(
                _translateStatus(AppConstants.statusCompleted, l10n),
                completed,
                AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alert summary
          if (stalePRs > 0 || lowBalance > 0) ...[
            _SectionHeader(title: l10n.translate('alerts_attention')),
            const SizedBox(height: 8),
            if (stalePRs > 0)
              _alertCard(
                Icons.timer_off,
                '$stalePRs ${l10n.translate('stale_pr_alert')}',
                Colors.orange,
              ),
            if (lowBalance > 0) ...[
              const SizedBox(height: 8),
              _alertCard(
                Icons.account_balance_wallet,
                '$lowBalance ${l10n.translate('low_balance_alert')}',
                Colors.red,
              ),
            ],
            const SizedBox(height: 16),
          ],

          // Funding source breakdown
          _SectionHeader(title: l10n.translate('funding_source_breakdown')),
          const SizedBox(height: 8),
          _buildFundingTable(activities),
        ],
      ),
    );
  }

  // ── TAB 2: BY SECTOR ───────────────────────────────────────────────────────
  Widget _buildSectorTab(List<Activity> activities) {
    final l10n = context.watch<SettingsProvider>().l10n;
    final Map<String, List<Activity>> sectorMap = {};
    for (var a in activities) {
      sectorMap.putIfAbsent(a.sector, () => []).add(a);
    }
    final sectors = sectorMap.keys.toList();
    _sortKeys(sectors, sectorMap, _sectorSort, _sectorAsc);
    return _buildGroupingTab(sectors, sectorMap, l10n, AppColors.primary);
  }

  // ── TAB 3: BY STAFF ────────────────────────────────────────────────────────
  Widget _buildStaffTab(
    List<Activity> activities,
    Map<String, String?> staffIdMap,
  ) {
    final l10n = context.watch<SettingsProvider>().l10n;
    final Map<String, List<Activity>> staffMap = {};
    for (var a in activities) {
      staffMap.putIfAbsent(a.responsiblePerson, () => []).add(a);
    }
    final staff = staffMap.keys.toList();
    _sortKeys(staff, staffMap, _staffSort, _staffAsc);
    return _buildGroupingTab(
      staff,
      staffMap,
      l10n,
      AppColors.secondary,
      staffIdMap: staffIdMap,
    );
  }

  // ── TAB 4: BY STATUS ───────────────────────────────────────────────────────
  Widget _buildStatusTab(List<Activity> activities) {
    final l10n = context.watch<SettingsProvider>().l10n;
    final Map<String, List<Activity>> statusMap = {};
    for (var a in activities) {
      statusMap.putIfAbsent(a.status, () => []).add(a);
    }
    final statuses = statusMap.keys.toList();
    // Default alphabetical for status for now
    statuses.sort();
    return _buildGroupingTab(
      statuses,
      statusMap,
      l10n,
      AppColors.tertiary,
      isStatus: true,
    );
  }

  Widget _buildGroupingTab(
    List<String> keys,
    Map<String, List<Activity>> groupMap,
    AppLocalization l10n,
    Color themeColor, {
    bool isStatus = false,
    Map<String, String?>? staffIdMap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: keys.length + 1,
      itemBuilder: (context, i) {
        if (i == keys.length) {
          final allActs = groupMap.values.expand((e) => e).toList();
          return Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
            child: _buildDetailedTotalSummaryCard(
              title: l10n.translate('overall_wfp_total'),
              budget: allActs.fold(0.0, (s, a) => s + a.approvedBudget),
              spent: allActs.fold(0.0, (s, a) => s + a.actualExpenditure),
              categories: _getCategoryTotals(allActs),
              ppmp: allActs.fold(0.0, (s, a) => s + a.ppmpBalance),
              pr: allActs.fold(0.0, (s, a) => s + a.prBalance),
              prTotal: allActs.fold(0.0, (s, a) => s + a.prAmount),
              po: allActs.fold(0.0, (s, a) => s + 0.0),
              count: allActs.length,
              l10n: l10n,
              color: themeColor,
            ),
          );
        }

        final key = keys[i];
        final acts = groupMap[key]!;
        final totalB = acts.fold(0.0, (s, a) => s + a.approvedBudget);
        final totalS = acts.fold(0.0, (s, a) => s + a.actualExpenditure);
        final rate = totalB > 0 ? totalS / totalB : 0.0;

        String displayName = isStatus ? _translateStatus(key, l10n) : key;
        if (staffIdMap != null && staffIdMap[key] != null) {
          displayName = '$displayName (${staffIdMap[key]})';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashColor: themeColor.withValues(alpha: 0.05),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              iconColor: themeColor,
              collapsedIconColor: Colors.grey,
              title: Text(
                displayName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Slate.shade800,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: rate.clamp(0.0, 1.0),
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              rate > 0.9 ? Colors.red : themeColor,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(rate * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: rate > 0.9 ? Colors.red : themeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _expStatModern(
                        l10n.translate('budget'),
                        formatCurrency.format(totalB),
                        Icons.account_balance_wallet_rounded,
                        isDark,
                      ),
                      _expStatModern(
                        l10n.translate('spent'),
                        formatCurrency.format(totalS),
                        Icons.payments_rounded,
                        isDark,
                      ),
                      _expStatModern(
                        l10n.translate('activities'),
                        '${acts.length}',
                        Icons.assignment_rounded,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Slate.shade50.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildBreakdownSummaryTable(
                        categories: _getCategoryTotals(acts),
                        ppmp: acts.fold(0.0, (s, a) => s + a.ppmpBalance),
                        pr: acts.fold(0.0, (s, a) => s + a.prBalance),
                        prTotal: acts.fold(0.0, (s, a) => s + a.prAmount),
                        po: acts.fold(0.0, (s, a) => s + 0.0),
                        l10n: l10n,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.translate('activity_breakdown'),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Slate.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...acts.map((a) => _buildActivityBreakdownRow(a)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sortKeys(
    List<String> keys,
    Map<String, List<Activity>> groupMap,
    ReportSortType sortType,
    bool asc,
  ) {
    keys.sort((a, b) {
      final listA = groupMap[a]!;
      final listB = groupMap[b]!;

      int result;
      switch (sortType) {
        case ReportSortType.name:
          result = a.compareTo(b);
          break;
        case ReportSortType.budget:
          final totalA = listA.fold(
            0.0,
            (sum, item) => sum + item.approvedBudget,
          );
          final totalB = listB.fold(
            0.0,
            (sum, item) => sum + item.approvedBudget,
          );
          result = totalA.compareTo(totalB);
          break;
        case ReportSortType.utilization:
          final budgetA = listA.fold(
            0.0,
            (sum, item) => sum + item.approvedBudget,
          );
          final spentA = listA.fold(
            0.0,
            (sum, item) => sum + item.actualExpenditure,
          );
          final budgetB = listB.fold(
            0.0,
            (sum, item) => sum + item.approvedBudget,
          );
          final spentB = listB.fold(
            0.0,
            (sum, item) => sum + item.actualExpenditure,
          );
          final utilA = budgetA > 0 ? spentA / budgetA : 0.0;
          final utilB = budgetB > 0 ? spentB / budgetB : 0.0;
          result = utilA.compareTo(utilB);
          break;
      }
      return asc ? result : -result;
    });
  }

  Widget _statusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                color: color.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(IconData icon, String message, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: isDark
                    ? color.withValues(alpha: 0.9)
                    : color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundingTable(List<Activity> activities) {
    final formatCurrency = NumberFormat.simpleCurrency(
      name: 'PHP ',
      decimalDigits: 2,
    );

    // Group by sourceText
    final Map<String, double> sources = {};
    for (var a in activities) {
      if (a.breakdown.isNotEmpty) {
        for (var item in a.breakdown) {
          final s = item.sourceText;
          if (s.isNotEmpty) {
            sources[s] = (sources[s] ?? 0) + item.amount;
          }
        }
      } else {
        final s = a.formattedSource;
        sources[s] = (sources[s] ?? 0) + a.approvedBudget;
      }
    }

    final sorted = sources.keys.toList()..sort();

    return Column(
      children: sorted
          .map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(s, style: const TextStyle(fontSize: 13)),
                  ),
                  Text(
                    formatCurrency.format(sources[s]),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDetailedTotalSummaryCard({
    required String title,
    required double budget,
    required double spent,
    required Map<String, double> categories,
    required double ppmp,
    required double pr,
    required double prTotal,
    required double po,
    required int count,
    required AppLocalization l10n,
    required Color color,
  }) {
    final rate = budget > 0 ? spent / budget : 0.0;
    final isWarning = rate > 0.9;
    final effectiveColor = isWarning ? Colors.red : color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: effectiveColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count ${l10n.translate('activities').toUpperCase()}',
                        style: TextStyle(
                          color: effectiveColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        (rate * 100).toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: effectiveColor,
                        ),
                      ),
                      Text(
                        '%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: effectiveColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'UTILIZATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Slate.shade400,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 12,
                width:
                    (MediaQuery.of(context).size.width - 80) *
                    rate.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      effectiveColor,
                      effectiveColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildDetailedSummaryCard(l10n, pr, prTotal, ppmp, po),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildBreakdownSummaryTable(
            categories: categories,
            ppmp: ppmp,
            pr: pr,
            prTotal: prTotal,
            po: po,
            l10n: l10n,
          ),
        ],
      ),
    );
  }

  Map<String, double> _getCategoryTotals(List<Activity> activities) {
    final Map<String, double> totals = {};
    for (var a in activities) {
      final actTotals = _getTotalsForActivity(a);
      actTotals.forEach((key, value) {
        totals[key] = (totals[key] ?? 0) + value;
      });
    }
    return totals;
  }

  Map<String, double> _getTotalsForActivity(Activity a) {
    final Map<String, double> totals = {};

    // Use actualExpenditure logic from Activity model but for categorical breakdown
    if (a.breakdown.isNotEmpty) {
      // If we have breakdown items, they are the source of truth for categories
      for (var item in a.breakdown) {
        final category = item.fullDisplayNameWithFallback(
          a.fundingSource,
          a.objectOfExpenditure,
        );
        totals[category] = (totals[category] ?? 0) + item.amount;
      }
    } else {
      // Fallback to legacy fields ONLY if breakdown is empty,
      // matching Activity.actualExpenditure logic to avoid double counting.
      if (a.trainingSeminarAmount > 0) {
        totals['Trainings and Seminar Expenses'] = a.trainingSeminarAmount;
      }
      if (a.meetingsAmount > 0) {
        totals['Meetings Expenses'] = a.meetingsAmount;
      }
      if (a.df20Amount > 0) {
        totals['20% DF'] = a.df20Amount;
      }
      // Optional: handle other legacy fields if they exist (CPOC, GAD etc.)
      if (a.cpocAmount > 0) totals['CPOC'] = a.cpocAmount;
      if (a.gadAmount > 0) totals['GAD'] = a.gadAmount;
    }
    return totals;
  }

  Widget _buildGrandTotalCard(
    double b,
    double s,
    double bal,
    double ppmp,
    double po,
    double prTotal,
    double prBalance,
    double rate,
    int count,
    AppLocalization l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
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
                    l10n.translate('overall_utilization').toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        (rate * 100).toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      l10n.translate('activities').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // OVERALL TOTAL SECTION
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Color(0xFFD4AF37),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'FINANCIAL OVERVIEW',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = ResponsiveUtils.valueByScreen(
                      context,
                      mobile: 1,
                      tablet: 2,
                      desktop: 4,
                    );
                    final itemWidth =
                        (constraints.maxWidth - (16 * (crossAxisCount - 1))) /
                        crossAxisCount;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 20,
                      children: [
                        _buildGrandTotalMetric(
                          'PPMP BALANCE',
                          ppmp,
                          Icons.account_balance_wallet_rounded,
                          itemWidth,
                        ),
                        _buildGrandTotalMetric(
                          'PR AMOUNT',
                          prTotal,
                          Icons.receipt_long_rounded,
                          itemWidth,
                        ),
                        _buildGrandTotalMetric(
                          'PR BALANCE',
                          prBalance,
                          Icons.pending_actions_rounded,
                          itemWidth,
                        ),
                        _buildGrandTotalMetric(
                          'PO AMOUNT',
                          po,
                          Icons.shopping_cart_rounded,
                          itemWidth,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSecondaryMetric(
                    l10n.translate('total_budget'),
                    b,
                    Icons.payments_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: _buildSecondaryMetric(
                    l10n.translate('total_spent'),
                    s,
                    Icons.shopping_bag_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: _buildSecondaryMetric(
                    l10n.translate('remaining'),
                    bal,
                    Icons.savings_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalMetric(
    String label,
    double value,
    IconData icon,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatCurrency.format(value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
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

  Widget _buildSecondaryMetric(String label, double value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.7),
            size: 18,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatCurrency.format(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedSummaryCard(
    AppLocalization l10n,
    double pr,
    double prTotal,
    double ppmp,
    double po,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Slate.shade900.withValues(alpha: 0.3)
            : Slate.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.summarize_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                l10n.translate('summary_details'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = ResponsiveUtils.valueByScreen(
                context,
                mobile: 2,
                tablet: 4,
                desktop: 4,
              );
              final itemWidth =
                  (constraints.maxWidth - (16 * (crossAxisCount - 1))) /
                  crossAxisCount;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildDetailedMetric(
                    'PPMP BALANCE',
                    ppmp,
                    Colors.blue.shade600,
                    Icons.account_balance_wallet_rounded,
                    width: itemWidth,
                  ),
                  _buildDetailedMetric(
                    'PR AMOUNT',
                    prTotal,
                    Colors.orange.shade600,
                    Icons.receipt_long_rounded,
                    width: itemWidth,
                  ),
                  _buildDetailedMetric(
                    'PR BALANCE',
                    pr,
                    Colors.amber.shade600,
                    Icons.pending_actions_rounded,
                    width: itemWidth,
                  ),
                  _buildDetailedMetric(
                    'PO AMOUNT',
                    po,
                    Colors.purple.shade600,
                    Icons.shopping_cart_rounded,
                    width: itemWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetric(
    String label,
    double value,
    Color color,
    IconData icon, {
    double? width,
  }) {
    return Container(
      width: width ?? 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCurrency.format(value),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSummaryTable({
    required Map<String, double> categories,
    required double ppmp,
    required double pr,
    required double prTotal,
    required double po,
    required AppLocalization l10n,
  }) {
    final formatCurrency = NumberFormat.simpleCurrency(
      name: 'PHP ',
      decimalDigits: 2,
    );

    final List<Widget> items = [];

    // Add dynamic categories from breakdown
    final sortedCategories = categories.keys.toList()..sort();
    for (var cat in sortedCategories) {
      final amount = categories[cat] ?? 0;
      if (amount != 0) {
        items.add(
          _buildSummaryItem(cat, formatCurrency.format(amount), Slate.shade600),
        );
      }
    }

    if (ppmp != 0) {
      items.add(
        _buildSummaryItem(
          'PPMP Balance',
          formatCurrency.format(ppmp),
          Colors.blue.shade700,
        ),
      );
    }
    if (prTotal != 0) {
      items.add(
        _buildSummaryItem(
          'PR Total',
          formatCurrency.format(prTotal),
          Colors.orange.shade700,
        ),
      );
    }
    if (pr != 0) {
      items.add(
        _buildSummaryItem(
          'Balance',
          formatCurrency.format(pr),
          Colors.green.shade700,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(children: items);
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white60 : Slate.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Slate.shade800,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  TableRow _buildSummaryRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ── TAB 5: BY EXPENDITURE TYPE ─────────────────────────────────────────────
  Widget _buildExpenditureTab(List<Activity> activities) {
    final l10n = context.watch<SettingsProvider>().l10n;
    final Map<String, List<Activity>> expMap = {};

    for (var a in activities) {
      if (a.breakdown.isNotEmpty &&
          a.breakdown.any(
            (item) =>
                (item.fundingSource != null &&
                    item.fundingSource!.isNotEmpty) ||
                (item.objectOfExpenditure != null &&
                    item.objectOfExpenditure!.isNotEmpty),
          )) {
        final usedTypes = <String>{};
        for (var item in a.breakdown) {
          final type = item.fullDisplayNameWithFallback(
            a.fundingSource,
            a.objectOfExpenditure,
          );
          if (usedTypes.add(type)) {
            expMap.putIfAbsent(type, () => []).add(a);
          }
        }
      } else {
        final type = a.formattedSource;
        expMap.putIfAbsent(type, () => []).add(a);
      }
    }

    final types = expMap.keys.toList()..sort();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: types.length + 1,
      itemBuilder: (context, i) {
        if (i == types.length) {
          final totalB = activities.fold(0.0, (s, a) => s + a.approvedBudget);
          final totalS = activities.fold(
            0.0,
            (s, a) => s + a.actualExpenditure,
          );

          return Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
            child: _buildDetailedTotalSummaryCard(
              title: l10n.translate('overall_wfp_total'),
              budget: totalB,
              spent: totalS,
              categories: _getCategoryTotals(activities),
              ppmp: activities.fold(0.0, (s, a) => s + a.ppmpBalance),
              pr: activities.fold(0.0, (s, a) => s + a.unexpendedBalance),
              prTotal: activities.fold(0.0, (s, a) => s + a.prAmount),
              po: 0.0,
              count: activities.length,
              l10n: l10n,
              color: AppColors.secondary,
            ),
          );
        }
        final type = types[i];
        final acts = expMap[type]!;

        double totalB = 0,
            totalS = 0,
            totalPP = 0,
            totalPR = 0,
            totalPRT = 0,
            totalPO = 0;
        for (var a in acts) {
          if (a.breakdown.isNotEmpty &&
              a.breakdown.any(
                (item) =>
                    (item.fundingSource != null &&
                        item.fundingSource!.isNotEmpty) ||
                    (item.objectOfExpenditure != null &&
                        item.objectOfExpenditure!.isNotEmpty),
              )) {
            final totalBreakdown = a.breakdown.fold(
              0.0,
              (sum, item) => sum + item.amount,
            );
            for (var item in a.breakdown) {
              final itemType = item.fullDisplayNameWithFallback(
                a.fundingSource,
                a.objectOfExpenditure,
              );

              if (itemType == type) {
                final ratio = totalBreakdown > 0
                    ? item.amount / totalBreakdown
                    : 0.0;
                totalB += item.amount;
                totalS += a.actualExpenditure * ratio;
                totalPP += a.ppmpBalance * ratio;
                totalPR += a.prBalance * ratio;
                totalPRT += a.prAmount * ratio;
                totalPO += 0.0;
              }
            }
          } else {
            totalB += a.approvedBudget;
            totalS += a.actualExpenditure;
            totalPP += a.ppmpBalance;
            totalPR += a.prBalance;
            totalPRT += a.prAmount;
            totalPO += 0.0;
          }
        }

        final rate = totalB > 0 ? totalS / totalB : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashColor: AppColors.primary.withValues(alpha: 0.05),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              iconColor: AppColors.primary,
              collapsedIconColor: Colors.grey,
              title: Text(
                type,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Slate.shade800,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: rate.clamp(0.0, 1.0),
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              rate > 0.9 ? Colors.red : AppColors.primary,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(rate * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: rate > 0.9 ? Colors.red : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _expStatModern(
                        l10n.translate('budget'),
                        formatCurrency.format(totalB),
                        Icons.account_balance_wallet_rounded,
                        isDark,
                      ),
                      _expStatModern(
                        l10n.translate('spent'),
                        formatCurrency.format(totalS),
                        Icons.payments_rounded,
                        isDark,
                      ),
                      _expStatModern(
                        l10n.translate('activities'),
                        '${acts.length}',
                        Icons.assignment_rounded,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Slate.shade50.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildBreakdownSummaryTable(
                        categories: {type: totalB},
                        ppmp: totalPP,
                        pr: totalPR,
                        prTotal: totalPRT,
                        po: totalPO,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.translate('activity_breakdown'),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Slate.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...acts.map((a) => _buildActivityBreakdownRow(a)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityBreakdownRow(Activity a) {
    final l10n = context.watch<SettingsProvider>().l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final fbService = context.read<FirebaseService>();
            _showActivityDetails(context, a, fbService);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        a.activityName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Slate.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(a.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _translateStatus(a.status, l10n),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(a.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _breakdownStatModern(
                      l10n.translate('budget'),
                      formatCurrency.format(a.approvedBudget),
                      Icons.account_balance_wallet_outlined,
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _breakdownStatModern(
                      'UNEXPENDED',
                      formatCurrency.format(a.unexpendedPPMP),
                      Icons.savings_outlined,
                      isDark,
                      textColor: a.unexpendedPPMP < 0
                          ? Colors.red
                          : Colors.green,
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

  Widget _expStatModern(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isDark ? Colors.white38 : Slate.shade300,
            ),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isDark ? Colors.white38 : Slate.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Slate.shade700,
          ),
        ),
      ],
    );
  }

  Widget _breakdownStatModern(
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.02) : Slate.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Slate.shade400,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? (isDark ? Colors.white : Slate.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  String _translateStatus(String status, AppLocalization l10n) {
    if (status.contains(',')) {
      return status
          .split(',')
          .map((s) => _translateSingleStatus(s.trim(), l10n))
          .join(', ');
    }
    return _translateSingleStatus(status, l10n);
  }

  String _translateSingleStatus(String status, AppLocalization l10n) {
    if (status == AppConstants.statusPlanned) {
      return l10n.translate('status_planned');
    }
    if (status == AppConstants.statusPRPrepared) {
      return l10n.translate('status_pr_prepared');
    }
    if (status == AppConstants.statusBACApprovedOBRE) {
      return l10n.translate('status_bac_approved_obre');
    }
    if (status == AppConstants.statusObreAbstract) {
      return l10n.translate('status_obre_abstract');
    }
    if (status == AppConstants.statusPOPrepared) {
      return l10n.translate('status_po_prepared');
    }
    if (status == AppConstants.statusObligated) {
      return l10n.translate('status_obligated');
    }
    if (status == AppConstants.statusIAR) return l10n.translate('status_iar');
    if (status == AppConstants.statusCompleted) {
      return l10n.translate('status_completed');
    }
    if (status == AppConstants.statusNoBudget) {
      return l10n.translate('status_no_budget');
    }
    if (status == AppConstants.statusNoBudgetYet) {
      return l10n.translate('status_no_budget_yet');
    }
    if (status == AppConstants.statusBACShopping) {
      return l10n.translate('status_bac_shopping');
    }
    if (status == AppConstants.statusBacOffice) {
      return l10n.translate('status_bac_office');
    }
    if (status == AppConstants.statusBacForPRNumber) {
      return l10n.translate('status_bac_for_pr_number');
    }
    if (status == AppConstants.statusBACBidding) {
      return l10n.translate('status_bac_bidding');
    }
    if (status == AppConstants.statusRecanvas) {
      return l10n.translate('status_recanvas');
    }
    return status;
  }

  Widget _buildAnalyticsChart(List<Activity> activities) {
    final l10n = context.watch<SettingsProvider>().l10n;
    // Group by sector for chart
    final Map<String, double> sectorBudgets = {};
    final Map<String, double> sectorSpent = {};

    for (var a in activities) {
      sectorBudgets[a.sector] =
          (sectorBudgets[a.sector] ?? 0) + a.approvedBudget;
      sectorSpent[a.sector] =
          (sectorSpent[a.sector] ?? 0) + a.actualExpenditure;
    }

    final sectors = sectorBudgets.keys.toList()..sort();
    if (sectors.isEmpty) return const SizedBox.shrink();

    String abbreviate(String name) {
      return AppConstants.abbreviate(name);
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.white10 : Slate.shade100,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.bar_chart_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate('budget_vs_spending'),
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : Slate.shade800,
                                  ),
                                ),
                                Text(
                                  l10n.translate('sector_breakdown_detail'),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Slate.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : Slate.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 24, 24),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY:
                                sectorBudgets.values.reduce(
                                  (a, b) => a > b ? a : b,
                                ) *
                                1.15,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => isDark
                                    ? const Color(0xFF334155)
                                    : Slate.shade800,
                                tooltipPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                tooltipBorderRadius: BorderRadius.circular(12),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${sectors[group.x]}\n',
                                    GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            '${rodIndex == 0 ? l10n.translate('budget') : l10n.translate('spent')}: ${formatCurrency.format(rod.toY)}',
                                        style: GoogleFonts.inter(
                                          color: rodIndex == 0
                                              ? Colors.blue.shade200
                                              : AppColors.tertiary.withValues(
                                                  alpha: 0.8,
                                                ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
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
                                    if (value.toInt() >= sectors.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: RotatedBox(
                                        quarterTurns: 0,
                                        child: Text(
                                          abbreviate(sectors[value.toInt()]),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white54
                                                : Slate.shade500,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  reservedSize: 40,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      NumberFormat.compactCurrency(
                                        symbol: '₱',
                                      ).format(value),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white38
                                            : Slate.shade400,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Slate.shade100,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: sectors.asMap().entries.map((e) {
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: sectorBudgets[e.value]!,
                                    color: Colors.blue.withValues(
                                      alpha: isDark ? 0.4 : 0.3,
                                    ),
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY:
                                          sectorBudgets.values.reduce(
                                            (a, b) => a > b ? a : b,
                                          ) *
                                          1.15,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.02)
                                          : Slate.shade50,
                                    ),
                                  ),
                                  BarChartRodData(
                                    toY: sectorSpent[e.value]!,
                                    color: AppColors.tertiary,
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.tertiary,
                                        AppColors.tertiary.withValues(
                                          alpha: 0.7,
                                        ),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
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
                ),
              ),
            );
          },
        );
      },
      child: Container(
        height: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.2
                    : 0.03,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('sector_spending_analysis'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.5,
                  ),
                ),
                Icon(
                  Icons.fullscreen_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      sectorBudgets.values.reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= sectors.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              abbreviate(sectors[value.toInt()]),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Slate.shade400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Slate.shade400,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: sectors.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: sectorBudgets[e.value]!,
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 10,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: sectorSpent[e.value]!,
                          color: AppColors.tertiary,
                          width: 10,
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.tertiary,
                              AppColors.tertiary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Planned':
        return const Color(0xFF94A3B8);
      case 'PR Prepared':
        return const Color(0xFFEAB308);
      case 'Obre & Abstract Signature':
        return const Color(0xFF1B5E20);
      case 'Obligated':
        return const Color(0xFF15803D);
      case 'Completed':
        return const Color(0xFF065F46);
      default:
        return Colors.blueGrey;
    }
  }
}

enum ReportSortType { name, budget, utilization }

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
