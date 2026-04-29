import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:open_file/open_file.dart';
import '../../core/responsive_utils.dart';

// Services
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../services/navigation_provider.dart';
import '../../services/settings_provider.dart';
import '../../services/activity_form_provider.dart';
import '../../services/import_service.dart';

// Models
import '../../models/activity.dart';

// Dialogs
import 'monthly_aggregation.dart';
import '../../widgets/dashboard_modules.dart';
import '../../widgets/agri_ui.dart';
import 'widgets/summary_cards.dart';
import 'widgets/activity_filters_bar.dart';
import 'widgets/activity_table.dart';
import 'widgets/activity_card_list.dart';
import 'activity_details_dialog.dart';

class AdminDashboard extends StatefulWidget {
  final bool isActive;
  const AdminDashboard({super.key, this.isActive = true});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedSector = '';
  String _selectedSubSector = '';
  String _selectedStaff = '';
  String _selectedFundingSource = '';
  String _selectedMonth = '';
  String _selectedYear = DateTime.now().year.toString();
  String _searchQuery = '';
  List<Activity> _activities = [];
  int? _sortColumnIndex;
  bool _sortAscending = true;

  Stream<List<Activity>>? _activitiesStream;

  StreamSubscription<List<Activity>>? _activitiesSub;
  String? _lastSector;
  String? _lastStaff;

  final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');

  @override
  void dispose() {
    _activitiesSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdminDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateNav();
      });
    }
  }

  void _updateNav() {
    final fbService = context.read<FirebaseService>();
    final authService = context.read<AuthService>();
    final navProvider = context.read<NavigationProvider>();
    final l10n = context.read<SettingsProvider>().l10n;

    navProvider.updateLayout(
      title: l10n.translate('dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37)),
          tooltip: l10n.translate('new_activity'),
          onPressed: () => _showAddActivityDialog(context, fbService),
        ),
        IconButton(
          icon: const Icon(Icons.upload_file, color: Color(0xFFD4AF37)),
          tooltip: l10n.translate('import_excel'),
          onPressed: () => _importData(context, fbService),
        ),
        IconButton(
          icon: const Icon(Icons.download, color: Color(0xFFD4AF37)),
          tooltip: l10n.translate('export_data'),
          onPressed: () =>
              _showExportOptions(context, _activities, authService, fbService),
        ),
      ],
      fab: null,
    );
  }

  void _onFiltersChanged() {
    setState(() {
      _activitiesStream = null;
      _activitiesSub?.cancel();
      _activitiesSub = null;
      _activities = [];
    });
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
    final fbService = context.read<FirebaseService>();
    final l10n = context.watch<SettingsProvider>().l10n;
    final theme = Theme.of(context);

    // Only recreate activity stream if filter parameters changed
    final currentSector = _selectedSector.isEmpty ? null : _selectedSector;
    final currentStaff = _selectedStaff.isEmpty ? null : _selectedStaff;

    if (_activitiesStream == null ||
        _lastSector != currentSector ||
        _lastStaff != currentStaff) {
      _lastSector = currentSector;
      _lastStaff = currentStaff;

      _activitiesStream = fbService.streamActivities(
        sector: currentSector,
        responsiblePerson: currentStaff,
      );
      _activitiesSub?.cancel();
      _activitiesSub = _activitiesStream!.listen((data) {
        if (mounted) {
          setState(() {
            _activities = data;
          });
          // Refresh Nav with fresh list for Export
          _updateNav();
        }
      });
    }

    if (_activities.isEmpty &&
        _activitiesStream != null &&
        (_activitiesSub == null || _activities.isEmpty)) {
      // If we're waiting for data or it's empty, show loading or actual empty state
      // We'll handle this refined in the UI below to allow showing the filter bar even when loading.
    }

    final allActivities = _activities;
    final isAnyFilterActive =
        _searchQuery.isNotEmpty ||
        _selectedSector.isNotEmpty ||
        _selectedStaff.isNotEmpty ||
        _selectedFundingSource.isNotEmpty ||
        _selectedSubSector.isNotEmpty ||
        _selectedMonth.isNotEmpty;

    // Show blank loading screen ONLY on first load (when we don't even have a stream yet or data hasn't arrived)
    if (_activitiesStream == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Normalize whitespace to handle minor spacing differences in names
    String normalize(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final activities = allActivities.where((a) {
      if (_selectedStaff.isNotEmpty) {
        final match =
            normalize(a.responsiblePerson) == normalize(_selectedStaff);
        if (!match) return false;
      }

      if (_selectedMonth.isNotEmpty &&
          !a.targetDate.toLowerCase().contains(_selectedMonth.toLowerCase())) {
        return false;
      }

      if (_selectedYear.isNotEmpty && !a.targetDate.contains(_selectedYear)) {
        return false;
      }

      if (_selectedSubSector.isNotEmpty && a.subSector != _selectedSubSector) {
        return false;
      }

      final matchesSearch = a.matchesSearch(_searchQuery);

      final matchesFund =
          _selectedFundingSource.isEmpty ||
          a.fundingSource == _selectedFundingSource;

      return matchesSearch && matchesFund;
    }).toList();

    // ── Apply Sorting ────────────────────────────────────────────────────
    if (_sortColumnIndex != null) {
      activities.sort((a, b) {
        dynamic vA, vB;
        switch (_sortColumnIndex) {
          case 0:
            vA = a.sector.toLowerCase();
            vB = b.sector.toLowerCase();
            break;
          case 2:
            vA = a.activityName.toLowerCase();
            vB = b.activityName.toLowerCase();
            break;
          case 8:
            vA = a.prBalance;
            vB = b.prBalance;
            break;
          case 11:
            vA = a.responsiblePerson.toLowerCase();
            vB = b.responsiblePerson.toLowerCase();
            break;
          case 12:
            vA = a.ppmpBalance;
            vB = b.ppmpBalance;
            break;
          case 13:
            vA = a.prAmount;
            vB = b.prAmount;
            break;
          case 14:
            vA = a.actualExpenditure;
            vB = b.actualExpenditure;
            break;
          default:
            return 0;
        }
        if (vA is String) {
          return _sortAscending ? vA.compareTo(vB) : vB.compareTo(vA);
        }
        return _sortAscending ? vA.compareTo(vB) : vB.compareTo(vA);
      });
    }

    // Sync filtered list for summary cards and table
    // (We formerly overwrote _activities here, which caused permanent truncation.
    // We now just use the local `activities` variable for rendering.)

    // to keep the ActivityFiltersBar stable.

    return Container(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Greeting Header ---
            Container(
              margin: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Color(0xFF1B5E20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B5E20),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hello, ${context.watch<AuthService>().currentUser?.name ?? "Admin"}',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track and manage agricultural activities and finances.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1B5E20), Color(0xFF064E3B)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          l10n.translate('executive_summary'),
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Text(
                      l10n.translate('executive_summary_subtitle'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SummaryCardsRow(
              activities: activities,
              formatCurrency: formatCurrency,
              onFundSelected: (fund) =>
                  setState(() => _selectedFundingSource = fund),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          l10n.translate('financial_insights'),
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < ResponsiveUtils.tabletBreakpoint) {
                    return Column(
                      children: [
                        BudgetSectionUnitChart(activities: activities),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: BudgetSectionUnitChart(activities: activities),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.translate('activity_management'),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ActivityFiltersBar(
              activities: allActivities,
              searchQuery: _searchQuery,
              selectedSector: _selectedSector,
              selectedSubSector: _selectedSubSector,
              selectedStaff: _selectedStaff,
              selectedFundingSource: _selectedFundingSource,
              selectedMonth: _selectedMonth,
              selectedYear: _selectedYear,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onSectorChanged: (val) => setState(() {
                _selectedSector = val ?? '';
                _onFiltersChanged();
              }),
              onSubSectorChanged: (val) =>
                  setState(() => _selectedSubSector = val ?? ''),
              onStaffChanged: (val) => setState(() {
                _selectedStaff = val ?? '';
                _onFiltersChanged();
              }),
              onFundingSourceChanged: (val) =>
                  setState(() => _selectedFundingSource = val ?? ''),
              onMonthChanged: (val) =>
                  setState(() => _selectedMonth = val ?? ''),
              onYearChanged: (val) => setState(() => _selectedYear = val ?? ''),
              onClearFilters: () => setState(() {
                _searchQuery = '';
                _selectedSector = '';
                _selectedSubSector = '';
                _selectedStaff = '';
                _selectedFundingSource = '';
                _selectedMonth = '';
                _selectedYear = DateTime.now().year.toString();
                _onFiltersChanged();
              }),
              onWfpMonthlyViewPressed: () => showDialog(
                context: context,
                builder: (_) =>
                    MonthlyAggregationViewer(activities: activities),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (activities.isEmpty) {
                  if (isAnyFilterActive) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60.0),
                      child: AgriUI.emptyState(
                        icon: Icons.search_off,
                        title: l10n.translate('no_results'),
                        message: l10n.translate('no_results_msg'),
                        onAction: () => setState(() {
                          _searchQuery = '';
                          _selectedSector = '';
                          _selectedSubSector = '';
                          _selectedStaff = '';
                          _selectedFundingSource = '';
                          _selectedMonth = '';
                        }),
                        actionLabel: l10n.translate('clear_all_filters'),
                      ),
                    );
                  } else if (_activities.isEmpty) {
                    // Truly empty database
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60.0),
                      child: AgriUI.emptyState(
                        icon: Icons.agriculture,
                        title: l10n.translate('no_activities'),
                        message: l10n.translate('no_activities_msg'),
                        onAction: () =>
                            _showAddActivityDialog(context, fbService),
                        actionLabel: l10n.translate('add_first_activity'),
                      ),
                    );
                  }
                }

                final isNarrow =
                    constraints.maxWidth < ResponsiveUtils.tabletBreakpoint;

                if (isNarrow) {
                  return ActivityCardList(
                    activities: activities,
                    fbService: fbService,
                    formatCurrency: formatCurrency,
                    onActionTap: (activity) =>
                        _showActivityDetails(context, activity, fbService),
                  );
                }
                return ActivityTable(
                  activities: activities,
                  fbService: fbService,
                  formatCurrency: formatCurrency,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  onSort: (idx, asc) => setState(() {
                    _sortColumnIndex = idx;
                    _sortAscending = asc;
                  }),
                  onActionTap: (activity) =>
                      _showActivityDetails(context, activity, fbService),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
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

  void _showAddActivityDialog(BuildContext context, FirebaseService fbService) {
    context.read<ActivityFormProvider>().openForm();
  }

  void _showEditActivityDialog(
    BuildContext context,
    Activity activity,
    FirebaseService fbService,
  ) {
    context.read<ActivityFormProvider>().openForm(activity: activity);
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

  void _showExportOptions(
    BuildContext context,
    List<Activity> activities,
    AuthService authService,
    FirebaseService fbService,
  ) {
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
                  _exportData(
                    context,
                    activities,
                    authService,
                    format: 'excel',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(l10n.translate('export_pdf')),
                onTap: () {
                  Navigator.pop(context);
                  _exportData(context, activities, authService, format: 'pdf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet, color: Colors.blue),
                title: Text(l10n.translate('export_csv')),
                onTap: () {
                  Navigator.pop(context);
                  _exportData(context, activities, authService, format: 'csv');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportData(
    BuildContext context,
    List<Activity> activities,
    AuthService authService, {
    required String format,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.read<SettingsProvider>().l10n;
    try {
      final exportedBy = authService.currentUser?.name ?? 'Admin';
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.translate('exporting_to')} $format...')),
      );

      String? path;
      if (format == 'excel') {
        path = await ExportService.exportActivitiesToExcel(
          activities,
          exportedBy: exportedBy,
        );
      } else if (format == 'pdf') {
        path = await ExportService.exportActivitiesToPdf(
          activities,
          exportedBy: exportedBy,
        );
      } else {
        path = await ExportService.exportActivitiesToCSV(
          activities,
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

  void _importData(BuildContext context, FirebaseService fbService) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Opening file picker...')),
      );

      await ImportService.importActivitiesFromExcel(fbService);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Import successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Import error: $e')));
      }
    }
  }
}
