import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/design_system.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../models/activity.dart';
import '../../services/export_service.dart';
import '../../services/import_service.dart';
import 'package:open_file/open_file.dart';
import '../../widgets/dashboard_modules.dart';
import '../../services/navigation_provider.dart';
import '../../services/settings_provider.dart';
import '../../widgets/agri_ui.dart';
import '../../core/app_colors.dart';
import '../../services/activity_form_provider.dart';
import '../../services/seed_data_loader.dart';
import '../../widgets/skeleton_loading.dart';


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
  final bool _showAll = false;
  final String _selectedSector = '';
  final String _selectedStaff = '';
  final List<Activity> _activities = [];
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
        IconButton(
          icon: const Icon(Icons.data_usage, color: Color(0xFFD4AF37)),
          tooltip: 'Seed Data',
          onPressed: () => _seedData(context, fbService),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fbService = context.read<FirebaseService>();
    final currentSector = _selectedSector.isEmpty ? null : _selectedSector;

    if (_activitiesStream == null ||
        _lastSector != currentSector ||
        _lastShowAll != _showAll) {
      _activitiesStream = fbService.streamActivities(
        sector: currentSector,
        responsiblePerson: null,
      );
      _lastSector = currentSector;
      _lastShowAll = _showAll;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<SettingsProvider>().l10n;
    final theme = Theme.of(context);

    return StreamBuilder<List<Activity>>(
      stream: _activitiesStream!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _activities.isEmpty) {
          return const SkeletonDashboard();
        }


        if (snapshot.hasError) {
          return AgriUI.emptyState(
            icon: Icons.error_outline_rounded,
            title: 'Something Went Wrong',
            message: 'We could not load your activities. Please check your connection.',
            onAction: () => setState(() {}),
            actionLabel: 'Retry',
          );
        }

        final rawActivities = snapshot.hasData ? snapshot.data! : _activities;

        String normalize(String s) =>
            s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

        final activities = rawActivities.where((a) {
          final targetStaff = _showAll ? _selectedStaff : widget.staffName;
          if (targetStaff.isNotEmpty) {
            final match = normalize(a.responsiblePerson) == normalize(targetStaff);
            if (!match) return false;
          }
          return true;
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 1000;
            final horizontalPadding = constraints.maxWidth > 1200 ? 40.0 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 40, horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader(
                    _showAll ? 'TOTAL WFP BUDGET' : 'MY ASSIGNED BUDGET', 
                    'Financial overview of agricultural programs assigned to you.', 
                    theme
                  ),
                  const SizedBox(height: 20),
                  
                  _buildStaffSummary(activities, theme),

                  const SizedBox(height: 48),
                  
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(l10n.translate('financial_insights'), 'Budget distribution visualization.', theme),
                              const SizedBox(height: 24),
                              BudgetSectionUnitChart(activities: activities),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('Navigation', 'Quick access to tools.', theme),
                              const SizedBox(height: 24),
                              _buildQuickActionCard(theme),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildSectionHeader(l10n.translate('financial_insights'), 'Budget distribution visualization.', theme),
                    const SizedBox(height: 24),
                    BudgetSectionUnitChart(activities: activities),
                    const SizedBox(height: 48),
                    _buildSectionHeader('Navigation', 'Quick access to tools.', theme),
                    const SizedBox(height: 24),
                    _buildQuickActionCard(theme),
                  ],
                  
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.emeraldPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.emeraldPrimary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.emeraldPrimary),
                const SizedBox(width: 8),
                Text(
                  'STAFF PORTAL',
                  style: AppDesignSystem.labelSmall.copyWith(
                    color: AppColors.emeraldPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hello, ${widget.staffName}',
            style: AppDesignSystem.headingLarge.copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            'Manage your assigned activities and track budget utilization efficiently.',
            style: AppDesignSystem.bodyLarge.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, ThemeData theme) {
    return Padding(
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
                title,
                style: AppDesignSystem.headingMedium.copyWith(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              subtitle,
              style: AppDesignSystem.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(ThemeData theme) {
    return GlassCard(
      onTap: () {
        context.read<NavigationProvider>().updateLayout(
          title: 'Activity Management',
          selectedIndex: 1,
        );
      },
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.emeraldPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.list_alt_rounded, color: AppColors.emeraldPrimary, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            'Activity Management',
            style: AppDesignSystem.headingSmall.copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'View and track all agricultural activities assigned to you.',
            style: AppDesignSystem.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Open Records',
                style: AppDesignSystem.labelMedium.copyWith(
                  color: AppColors.emeraldPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.emeraldPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSummary(List<Activity> activities, ThemeData theme) {
    double myTotal = 0;
    double mySpent = 0;
    for (var a in activities) {
      myTotal += a.approvedBudget;
      mySpent += a.effectivePOAmount;
    }
    double myRemaining = myTotal - mySpent;

    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              if (isNarrow) {
                return Column(
                  children: [
                    _summaryItem('Total Budget', myTotal, AppColors.emeraldPrimary, Icons.account_balance_wallet_rounded, theme),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),
                    _summaryItem('Spent', mySpent, const Color(0xFFF59E0B), Icons.shopping_cart_rounded, theme),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),
                    _summaryItem('Remaining', myRemaining, const Color(0xFF3B82F6), Icons.account_balance_rounded, theme),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _summaryItem('Total Budget', myTotal, AppColors.emeraldPrimary, Icons.account_balance_wallet_rounded, theme)),
                  Container(width: 1, height: 60, color: theme.dividerColor.withValues(alpha: 0.1)),
                  Expanded(child: _summaryItem('Spent', mySpent, const Color(0xFFF59E0B), Icons.shopping_cart_rounded, theme)),
                  Container(width: 1, height: 60, color: theme.dividerColor.withValues(alpha: 0.1)),
                  Expanded(child: _summaryItem('Remaining', myRemaining, const Color(0xFF3B82F6), Icons.account_balance_rounded, theme)),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          _buildQuarterlyRow(activities, theme),
        ],
      ),
    );
  }



  Widget _buildQuarterlyRow(List<Activity> activities, ThemeData theme) {
    double q1 = 0, q2 = 0, q3 = 0, q4 = 0;
    for (var a in activities) {
      q1 += a.q1Budget;
      q2 += a.q2Budget;
      q3 += a.q3Budget;
      q4 += a.q4Budget;
    }

    return Wrap(
      spacing: 12,
      runSpacing: 24,
      alignment: WrapAlignment.spaceAround,
      children: [
        _quarterStat('Q1', q1, theme),
        _quarterStat('Q2', q2, theme),
        _quarterStat('Mid-Year', q1 + q2, theme),
        _quarterStat('Q3', q3, theme),
        _quarterStat('Q4', q4, theme),
        _quarterStat('Whole Year', q1 + q2 + q3 + q4, theme),
      ],
    );
  }

  Widget _quarterStat(String label, double amount, ThemeData theme) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Text(
            label,
            style: AppDesignSystem.labelSmall.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCurrency.format(amount),
              style: AppDesignSystem.headingSmall.copyWith(
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color, IconData icon, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppDesignSystem.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatCurrency.format(amount),
            style: AppDesignSystem.headingMedium.copyWith(
              fontSize: 24,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }



  void _showAddActivityDialog(BuildContext context, FirebaseService fbService) {
    Provider.of<ActivityFormProvider>(
      context,
      listen: false,
    ).openForm(initialResponsiblePersons: [widget.staffName]);
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

  void _seedData(BuildContext context, FirebaseService fbService) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Starting data seed...')),
      );

      await SeedDataLoader.load(fbService, force: true);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Seed data loaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error loading seed data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
