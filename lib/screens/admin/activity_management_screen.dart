import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:open_file/open_file.dart';

import '../../core/responsive_utils.dart';
import '../../core/app_colors.dart';
import '../../core/design_system.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../services/navigation_provider.dart';
import '../../services/settings_provider.dart';
import '../../services/activity_form_provider.dart';
import '../../models/activity.dart';
import '../../widgets/agri_ui.dart';
import '../../services/seed_data_loader.dart';
import 'widgets/activity_filters_bar.dart';
import 'widgets/activity_table.dart';
import 'widgets/activity_card_list.dart';
import 'activity_details_dialog.dart';
import 'monthly_aggregation.dart';
import '../../widgets/skeleton_loading.dart';


class ActivityManagementScreen extends StatefulWidget {
  final bool isActive;
  const ActivityManagementScreen({super.key, this.isActive = true});

  @override
  State<ActivityManagementScreen> createState() =>
      _ActivityManagementScreenState();
}

class _ActivityManagementScreenState extends State<ActivityManagementScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
  bool _isLoading = true;
  final Set<String> _selectedActivityIds = {};


  Stream<List<Activity>>? _activitiesStream;
  StreamSubscription<List<Activity>>? _activitiesSub;
  String? _lastSector;
  String? _lastStaff;

  final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
  Timer? _searchDebounce;
  List<Activity> _filteredActivities = [];
  double _totalPPMPBalance = 0;
  double _totalPR = 0;
  double _totalPOAmount = 0;

  @override
  void dispose() {
    _activitiesSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(ActivityManagementScreen oldWidget) {
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
      title: 'Activity Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppColors.emeraldPrimary),
          tooltip: l10n.translate('new_activity'),
          onPressed: () => _showAddActivityDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.download, color: AppColors.emeraldPrimary),
          tooltip: l10n.translate('export_data'),
          onPressed: () =>
              _showExportOptions(context, _activities, authService),
        ),
        IconButton(
          icon: const Icon(
            Icons.data_exploration_outlined,
            color: AppColors.emeraldPrimary,
          ),
          tooltip: 'Seed Data',
          onPressed: () => _seedData(context, fbService),
        ),
      ],
      fab: null,
    );
  }

  void _seedData(BuildContext context, FirebaseService fbService) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Seeding data from seed_data.json...')),
      );
      await SeedDataLoader.load(fbService, force: true);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Seed data loaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Seeding error: $e')));
      }
    }
  }

  void _onFiltersChanged() {
    setState(() {
      _activitiesStream = null;
      _activitiesSub?.cancel();
      _activitiesSub = null;
      _filteredActivities = [];
      _totalPPMPBalance = 0;
      _totalPR = 0;
      _totalPOAmount = 0;
      _isLoading = true;
    });
  }

  void _applyFiltersAndSort() {
    final allActivities = _activities;
    
    String normalize(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final filtered = allActivities.where((a) {
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

    if (_sortColumnIndex != null) {
      filtered.sort((a, b) {
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
            vA = a.effectivePOAmount;
            vB = b.effectivePOAmount;
            break;
          case 15:
            vA = a.statusDate?.toLowerCase() ?? '';
            vB = b.statusDate?.toLowerCase() ?? '';
            break;
          default:
            return 0;
        }
        return _sortAscending ? vA.compareTo(vB) : vB.compareTo(vA);
      });
    }

    // Calculate totals for footer
    double totalPPMP = 0;
    double totalPR = 0;
    double totalPO = 0;
    
    for (var a in filtered) {
      totalPPMP += a.totalBudget;
      totalPR += a.effectivePRAmount;
      totalPO += a.effectivePOAmount;
    }

    _filteredActivities = filtered;
    _totalPPMPBalance = totalPPMP;
    _totalPR = totalPR;
    _totalPOAmount = totalPO;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fbService = context.read<FirebaseService>();
    final currentSector = _selectedSector.isEmpty ? null : _selectedSector;
    final currentStaff = _selectedStaff.isEmpty ? null : _selectedStaff;

    if (_activitiesStream == null ||
        _lastSector != currentSector ||
        _lastStaff != currentStaff) {
      _lastSector = currentSector;
      _lastStaff = currentStaff;

      _activitiesSub?.cancel();
      // Only show full loading if we don't have data yet
      if (_activities.isEmpty) {
        setState(() => _isLoading = true);
      }
      
      _activitiesStream = fbService.streamActivities(
        sector: currentSector,
        responsiblePerson: currentStaff,
      );
      
      _activitiesSub = _activitiesStream!.listen((data) {
        if (mounted) {
          setState(() {
            _activities = data;
            _applyFiltersAndSort();
            _isLoading = false;
          });

          if (widget.isActive) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _updateNav());
          }
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final fbService = context.read<FirebaseService>();
    final l10n = context.watch<SettingsProvider>().l10n;
    final theme = Theme.of(context);

    final activities = _filteredActivities;
    final isAnyFilterActive =
        _searchQuery.isNotEmpty ||
        _selectedSector.isNotEmpty ||
        _selectedStaff.isNotEmpty ||
        _selectedFundingSource.isNotEmpty ||
        _selectedSubSector.isNotEmpty ||
        _selectedMonth.isNotEmpty;

    if (_isLoading) {
      return const SkeletonList();
    }

    return Container(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      padding: const EdgeInsets.fromLTRB(24, 32, 64, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedActivityIds.isNotEmpty) _buildBulkActionBar(context, activities),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.emeraldPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Manage Activities',
                      style: AppDesignSystem.headingMedium.copyWith(color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    'Filter and track agricultural activity records across all sectors.',
                    style: AppDesignSystem.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ActivityFiltersBar(
              activities: _activities,
              searchQuery: _searchQuery,
              selectedSector: _selectedSector,
              selectedSubSector: _selectedSubSector,
              selectedStaff: _selectedStaff,
              selectedFundingSource: _selectedFundingSource,
              selectedMonth: _selectedMonth,
              selectedYear: _selectedYear,
              onSearchChanged: (val) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _searchQuery = val;
                      _applyFiltersAndSort();
                    });
                  }
                });
              },
              onSectorChanged: (val) => setState(() {
                _selectedSector = val ?? '';
                _onFiltersChanged();
              }),
              onSubSectorChanged: (val) =>
                  setState(() {
                    _selectedSubSector = val ?? '';
                    _applyFiltersAndSort();
                  }),
              onStaffChanged: (val) => setState(() {
                _selectedStaff = val ?? '';
                _onFiltersChanged();
              }),
              onFundingSourceChanged: (val) =>
                  setState(() {
                    _selectedFundingSource = val ?? '';
                    _applyFiltersAndSort();
                  }),
              onMonthChanged: (val) =>
                  setState(() {
                    _selectedMonth = val ?? '';
                    _applyFiltersAndSort();
                  }),
              onYearChanged: (val) => setState(() {
                _selectedYear = val ?? '';
                _applyFiltersAndSort();
              }),
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
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60.0),
                      child: AgriUI.emptyState(
                        icon: Icons.agriculture,
                        title: l10n.translate('no_activities'),
                        message: l10n.translate('no_activities_msg'),
                        onAction: () => _showAddActivityDialog(context),
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
                        _showActivityDetails(context, activity),
                  );
                }
                return ActivityTable(
                  activities: activities,
                  fbService: fbService,
                  formatCurrency: formatCurrency,
                  totalPPMPBalance: _totalPPMPBalance,
                  totalPR: _totalPR,
                  totalPOAmount: _totalPOAmount,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  onSort: (idx, asc) => setState(() {
                    _sortColumnIndex = idx;
                    _sortAscending = asc;
                    _applyFiltersAndSort();
                  }),
                  onActionTap: (activity) =>
                      _showActivityDetails(context, activity),
                  selectedIds: _selectedActivityIds,
                  onSelectionChanged: (id, selected) {
                    setState(() {
                      if (selected) {
                        _selectedActivityIds.add(id);
                      } else {
                        _selectedActivityIds.remove(id);
                      }
                    });
                  },
                  onSelectAll: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedActivityIds.addAll(activities.map((a) => a.id));
                      } else {
                        _selectedActivityIds.clear();
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showActivityDetails(BuildContext context, Activity activity) {
    final fbService = context.read<FirebaseService>();
    showDialog(
      context: context,
      builder: (ctx) => ActivityDetailsDialog(
        activity: activity,
        fbService: fbService,
        onEdit: () {
          Navigator.pop(ctx);
          _showEditActivityDialog(context, activity);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDelete(context, activity);
        },
      ),
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    context.read<ActivityFormProvider>().openForm();
  }

  void _showEditActivityDialog(BuildContext context, Activity activity) {
    context.read<ActivityFormProvider>().openForm(activity: activity);
  }

  Future<void> _confirmDelete(BuildContext context, Activity activity) async {
    final fbService = context.read<FirebaseService>();
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
                leading: const Icon(Icons.table_chart_rounded, color: AppColors.emeraldPrimary),
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
                leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.emeraldPrimary),
                title: Text(l10n.translate('export_pdf')),
                onTap: () {
                  Navigator.pop(context);
                  _exportData(context, activities, authService, format: 'pdf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet_rounded, color: AppColors.emeraldPrimary),
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

  Widget _buildBulkActionBar(BuildContext context, List<Activity> activities) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedActivityIds.length} items selected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _selectedActivityIds.clear()),
            icon: const Icon(Icons.close),
            label: const Text('Clear'),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _showBulkStatusDialog(context),
            icon: const Icon(Icons.edit_note),
            label: const Text('Update Status'),
          ),
        ],
      ),
    );
  }

  void _showBulkStatusDialog(BuildContext context) {
    final fbService = context.read<FirebaseService>();
    final statuses = ['Planned', 'Ongoing', 'Completed', 'Cancelled'];
    String? selectedStatus = statuses.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update ${_selectedActivityIds.length} activities to:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => selectedStatus = val,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final status = selectedStatus;
              if (status != null) {
                final ids = _selectedActivityIds.toList();
                Navigator.pop(context);
                
                // Show loading snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Updating activities...')),
                );

                try {
                  for (final id in ids) {
                    await fbService.updateActivityStatus(id, status);
                  }
                  
                  if (context.mounted) {
                    setState(() => _selectedActivityIds.clear());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Updated ${ids.length} activities to $status'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Update All'),
          ),
        ],
      ),
    );
  }
}

