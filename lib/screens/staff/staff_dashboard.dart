import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/responsive_utils.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../models/activity.dart';
import '../../models/user_model.dart';
import '../../services/export_service.dart';
import '../../services/import_service.dart';
import 'package:open_file/open_file.dart';
import '../../widgets/dashboard_modules.dart';
import '../../services/navigation_provider.dart';
import '../../services/settings_provider.dart';
import '../../widgets/agri_ui.dart';
import '../../core/constants.dart';
import '../../core/app_colors.dart';
import '../admin/activity_details_dialog.dart';
import '../admin/monthly_aggregation.dart';
import '../admin/edit_activity_dialog.dart';
import '../admin/widgets/activity_card_list.dart';
import '../../services/activity_form_provider.dart';

class StaffDashboard extends StatefulWidget {
  final String staffName;
  final String? title;
  final bool isActive;
  const StaffDashboard({
    super.key,
    required this.staffName,
    this.title,
    this.isActive = true,
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
  bool _showAll = false;
  String _searchQuery = '';
  String _selectedSector = '';
  String _selectedStaff = '';
  String _selectedMonth = '';
  String _selectedYear = DateTime.now().year.toString();
  List<Activity> _activities = [];
  Stream<List<Activity>>? _activitiesStream;

  // Track filter values to know when to recreate the stream
  String? _lastSector;
  bool? _lastShowAll;

  @override
  void didUpdateWidget(StaffDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateNav();
      });
    }
  }

  void _updateNav() {
    final authService = context.read<AuthService>();
    final fbService = context.read<FirebaseService>();
    final navProvider = context.read<NavigationProvider>();
    final l10n = context.read<SettingsProvider>().l10n;

    navProvider.updateLayout(
      title: l10n.translate('dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37)),
          tooltip: 'New Activity',
          onPressed: () => _showAddActivityDialog(context, fbService),
        ),
        IconButton(
          icon: const Icon(Icons.upload_file, color: Color(0xFFD4AF37)),
          tooltip: 'Import Excel',
          onPressed: () => _importData(context, fbService),
        ),
        IconButton(
          icon: const Icon(Icons.download, color: Color(0xFFD4AF37)),
          tooltip: 'Export Data',
          onPressed: () =>
              _showExportOptions(context, _activities, authService),
        ),
      ],
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
    final fbService = context.read<FirebaseService>();
    final authService = context.read<AuthService>();
    final isAdmin = authService.currentUser?.role == 'admin';

    // Only recreate activity stream if filter parameters changed
    final currentSector = _selectedSector.isEmpty ? null : _selectedSector;

    if (_activitiesStream == null ||
        _lastSector != currentSector ||
        _lastShowAll != _showAll) {
      // We no longer pass currentStaff to the stream.
      // We fetch all relevant activities and filter by staff name in the UI
      // to handle cases with extra spaces or different casing.
      _activitiesStream = fbService.streamActivities(
        sector: currentSector,
        responsiblePerson: null,
      );
      _lastSector = currentSector;
      _lastShowAll = _showAll;
    }

    return StreamBuilder<List<Activity>>(
      stream: _activitiesStream!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _activities.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [AgriUI.cardShimmer(count: 3)]),
          );
        }

        if (snapshot.hasError) {
          return AgriUI.emptyState(
            icon: Icons.error_outline,
            title: 'Something Went Wrong',
            message:
                'We could not load your activities. Please check your connection and try again.',
            onAction: () => setState(() {}),
            actionLabel: 'Retry',
          );
        }

        final rawActivities = snapshot.hasData ? snapshot.data! : _activities;

        // Normalize whitespace helper: collapse multiple spaces to one
        String normalize(String s) =>
            s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

        final activities = rawActivities.where((a) {
          final targetStaff = _showAll ? _selectedStaff : widget.staffName;

          if (targetStaff.isNotEmpty) {
            final match =
                normalize(a.responsiblePerson) == normalize(targetStaff);
            if (!match) return false;
          }

          if (_selectedMonth.isNotEmpty &&
              !a.targetDate.toLowerCase().contains(_selectedMonth.toLowerCase())) {
            return false;
          }

          if (_selectedYear.isNotEmpty && !a.targetDate.contains(_selectedYear)) {
            return false;
          }

          final matchesSearch = a.matchesSearch(_searchQuery);

          return matchesSearch;
        }).toList();

        // Sync filtered list to state for use in AppBar actions (no setState to avoid rebuild loop)
        _activities = activities;

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildStaffSummary(activities),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: BudgetSectionUnitChart(activities: activities),
              ),
              _buildFilters(rawActivities),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _showAll ? 'All Activities' : 'Assigned Tasks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Monthly View'),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) =>
                            MonthlyAggregationViewer(activities: activities),
                      ),
                    ),
                  ],
                ),
              ),
              if (activities.isEmpty)
                AgriUI.emptyState(
                  icon: _showAll
                      ? Icons.search_off
                      : Icons.assignment_turned_in,
                  title: _showAll ? 'No Activities Found' : 'No Tasks Yet',
                  message: _showAll
                      ? 'No activities match your current filters.'
                      : 'You don\'t have any activities assigned to you yet.',
                  onAction: !_showAll
                      ? () => setState(() => _showAll = true)
                      : null,
                  actionLabel: 'View All Activities',
                )
              else
                ActivityCardList(
                  activities: activities,
                  fbService: fbService,
                  formatCurrency: formatCurrency,
                  onActionTap: (act) =>
                      _showActivityDetails(context, act, fbService, isAdmin),
                ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(List<Activity> activities) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Activities',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'All Activities',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: _showAll,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) => setState(() => _showAll = val),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search (abbreviations allowed)...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final sectorDropdown = DropdownMenu<String>(
                initialSelection: _selectedSector.isEmpty ? null : _selectedSector,
                enableSearch: true,
                enableFilter: true,
                menuHeight: 250,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Section/Unit'),
                dropdownMenuEntries: AppConstants.sectors
                    .map((s) => DropdownMenuEntry(value: s, label: s))
                    .toList(),
                onSelected: (val) => setState(() => _selectedSector = val ?? ''),
              );


              final clearBtn = IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF9CA3AF),
                ),
                onPressed: () => setState(() {
                  _selectedSector = '';
                }),
              );

              if (constraints.maxWidth < ResponsiveUtils.mobileBreakpoint) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    sectorDropdown,
                    if (!_showAll) ...[
                      const SizedBox(height: 4),
                      Align(alignment: Alignment.centerRight, child: clearBtn),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: sectorDropdown),
                  if (!_showAll) ...[const SizedBox(width: 4), clearBtn],
                ],
              );
            },
          ),
          if (_showAll) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final staffDropdown = StreamBuilder<List<UserModel>>(
                  stream: Provider.of<FirebaseService>(
                    context,
                    listen: false,
                  ).streamUsers(),
                  builder: (context, userSnap) {
                    final users = userSnap.data ?? [];
                    final userNames = users.map((u) => u.name).toSet();

                    final activityNames = activities
                        .map((a) => a.responsiblePerson)
                        .where((name) => name.isNotEmpty)
                        .toSet();

                    final allNames = (userNames.union(activityNames)).toList()
                      ..sort();

                    return DropdownMenu<String>(
                      initialSelection: _selectedStaff.isEmpty ? null : _selectedStaff,
                      enableSearch: true,
                      enableFilter: true,
                      menuHeight: 250,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Staff'),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry(value: '', label: 'All Staff'),
                        ...allNames.map((s) => DropdownMenuEntry(value: s, label: s)),
                      ],
                      onSelected: (val) => setState(() => _selectedStaff = val ?? ''),
                    );
                  },
                );

                final clearBtn = IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF9CA3AF),
                  ),
                  onPressed: () => setState(() {
                    _selectedStaff = '';
                  }),
                );

                if (constraints.maxWidth < ResponsiveUtils.mobileBreakpoint) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      staffDropdown,
                      const SizedBox(height: 4),
                      Align(alignment: Alignment.centerRight, child: clearBtn),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: staffDropdown),
                    const SizedBox(width: 4),
                    clearBtn,
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final monthDropdown = DropdownMenu<String>(
                initialSelection: _selectedMonth.isEmpty ? null : _selectedMonth,
                enableSearch: true,
                enableFilter: true,
                menuHeight: 250,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Target Month'),
                dropdownMenuEntries: AppConstants.months
                    .map((s) => DropdownMenuEntry(value: s, label: s))
                    .toList(),
                onSelected: (val) => setState(() => _selectedMonth = val ?? ''),
              );

              final yearDropdown = DropdownMenu<String>(
                initialSelection: _selectedYear.isEmpty ? null : _selectedYear,
                enableSearch: true,
                enableFilter: true,
                menuHeight: 250,
                expandedInsets: EdgeInsets.zero,
                label: const Text('Target Year'),
                dropdownMenuEntries: AppConstants.years
                    .map((s) => DropdownMenuEntry(value: s, label: s))
                    .toList(),
                onSelected: (val) => setState(() => _selectedYear = val ?? ''),
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
        ],
      ),
    );
  }

  Widget _buildStaffSummary(List<Activity> activities) {
    double myTotal = 0;
    double mySpent = 0;
    for (var a in activities) {
      myTotal += a.approvedBudget;
      mySpent += a.actualExpenditure;
    }
    double myRemaining = myTotal - mySpent;

    return Container(
      margin: ResponsiveUtils.screenPadding(context).copyWith(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _showAll ? 'TOTAL WFP BUDGET' : 'ASSIGNED BUDGET',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              if (isNarrow) {
                return Column(
                  children: [
                    _summaryItem(
                      'Total Budget',
                      myTotal,
                      AppColors.primary,
                      Icons.account_balance_wallet,
                    ),
                    const Divider(height: 32),
                    _summaryItem(
                      'Spent',
                      mySpent,
                      const Color(0xFFE65100),
                      Icons.shopping_cart,
                    ),
                    const Divider(height: 32),
                    _summaryItem(
                      'Remaining',
                      myRemaining,
                      const Color(0xFF1976D2),
                      Icons.account_balance,
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _summaryItem(
                      'Total Budget',
                      myTotal,
                      AppColors.primary,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: _summaryItem(
                      'Spent',
                      mySpent,
                      const Color(0xFFE65100),
                      Icons.shopping_cart,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  Expanded(
                    child: _summaryItem(
                      'Remaining',
                      myRemaining,
                      const Color(0xFF1976D2),
                      Icons.account_balance,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 20),
          _buildQuarterlyRow(activities),
        ],
      ),
    );
  }

  Widget _buildQuarterlyRow(List<Activity> activities) {
    double q1 = 0, q2 = 0, q3 = 0, q4 = 0;
    for (var a in activities) {
      q1 += a.q1Budget;
      q2 += a.q2Budget;
      q3 += a.q3Budget;
      q4 += a.q4Budget;
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceAround,
      children: [
        _quarterStat('Q1', q1),
        _quarterStat('Q2', q2),
        _quarterStat('Mid-Year', q1 + q2),
        _quarterStat('Q3', q3),
        _quarterStat('Q4', q4),
        _quarterStat('Whole Year', q1 + q2 + q3 + q4),
      ],
    );
  }

  Widget _quarterStat(String label, double amount) {
    return SizedBox(
      width: 100, // Fixed width for wrap items
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCurrency.format(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatCurrency.format(amount),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Activity activity,
    FirebaseService fbService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text(
          'Are you sure you want to permanently delete "${activity.activityName}"?\n\nThis will also delete associated PR logs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await fbService.deleteActivity(activity.id);
        if (context.mounted) {
          AgriUI.showSuccess(
            context,
            '"${activity.activityName}" deleted successfully.',
          );
        }
      } catch (e) {
        if (context.mounted) {
          AgriUI.showError(context, 'Delete error: $e');
        }
      }
    }
  }

  void _showAddActivityDialog(BuildContext context, FirebaseService fbService) {
    Provider.of<ActivityFormProvider>(
      context,
      listen: false,
    ).openForm(initialResponsiblePersons: [widget.staffName]);
  }

  void _showActivityDetails(
    BuildContext context,
    Activity activity,
    FirebaseService fbService,
    bool isAdmin,
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
        onDelete: isAdmin
            ? () {
                Navigator.pop(ctx);
                _confirmDelete(context, activity, fbService);
              }
            : null,
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
          EditActivityDialog(activity: activity, fbService: fbService),
    );
  }

  void _showExportOptions(
    BuildContext context,
    List<Activity> activities,
    AuthService authService,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Export to Excel (.xlsx)'),
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
                title: const Text('Export to PDF (.pdf)'),
                onTap: () {
                  Navigator.pop(context);
                  _exportData(context, activities, authService, format: 'pdf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet, color: Colors.blue),
                title: const Text('Export to CSV (.csv)'),
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
    try {
      final exportedBy = authService.currentUser?.name ?? widget.staffName;
      messenger.showSnackBar(
        SnackBar(content: Text('Exporting to $format...')),
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
              path != null ? 'Saved to: $path' : 'Export successful!',
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

        // The file is already available via the SnackBar action,
        // removing automatic open to prevent double-opening.
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
