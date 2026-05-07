import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:open_file/open_file.dart';
import '../../core/design_system.dart';
import '../../core/app_colors.dart';

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
import '../../widgets/dashboard_modules.dart';
import 'widgets/summary_cards.dart';
import '../../widgets/skeleton_loading.dart';


class AdminDashboard extends StatefulWidget {
  final bool isActive;
  const AdminDashboard({super.key, this.isActive = true});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final String _selectedSector = '';
  final String _selectedStaff = '';
  List<Activity> _activities = [];
  bool _isLoading = true;


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
          onPressed: () => _importData(fbService),
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
    
    // Only recreate activity stream if filter parameters changed
    final currentSector = _selectedSector.isEmpty ? null : _selectedSector;
    final currentStaff = _selectedStaff.isEmpty ? null : _selectedStaff;

    if (_activitiesStream == null ||
        _lastSector != currentSector ||
        _lastStaff != currentStaff) {
      _lastSector = currentSector;
      _lastStaff = currentStaff;

      _activitiesSub?.cancel();
      setState(() => _isLoading = true);
      _activitiesStream = fbService.streamActivities(

        sector: currentSector,
        responsiblePerson: currentStaff,
      );
      _activitiesSub = _activitiesStream!.listen((data) {
        if (mounted) {
          setState(() {
            _activities = data;
            _isLoading = false;
          });

          // Use postFrameCallback to update navigation without interrupting the build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.isActive) _updateNav();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final fbService = context.read<FirebaseService>();
    final l10n = context.watch<SettingsProvider>().l10n;
    final theme = Theme.of(context);

    // Show premium skeleton loading screen
    if (_isLoading) {
      return const Scaffold(body: SkeletonDashboard());
    }

    final activities = _activities;

    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth > 1000;
        final horizontalPadding = screenWidth > 1200 ? 40.0 : 24.0;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Greeting Header ---
              _buildHeader(theme),
              
              if (activities.isEmpty) 
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: _buildEmptyState(context, fbService, theme),
                )
              else ...[
                const SizedBox(height: 40),
                _buildSectionHeader(l10n.translate('executive_summary'), l10n.translate('executive_summary_subtitle'), theme),
                const SizedBox(height: 20),
                SummaryCardsRow(
                  activities: activities,
                  formatCurrency: formatCurrency,
                  onFundSelected: (fund) {},
                ),
                
                const SizedBox(height: 48),
                
                // Responsive Content Grid
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(l10n.translate('financial_insights'), 'Visualize budget distribution across sectors.', theme),
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
                            _buildSectionHeader('Management', 'Quick access to records.', theme),
                            const SizedBox(height: 24),
                            _buildQuickActionCard(theme),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildSectionHeader(l10n.translate('financial_insights'), 'Visualize budget distribution across sectors.', theme),
                  const SizedBox(height: 24),
                  BudgetSectionUnitChart(activities: activities),
                  const SizedBox(height: 48),
                  _buildSectionHeader('Management', 'Quick access to records.', theme),
                  const SizedBox(height: 24),
                  _buildQuickActionCard(theme),
                ],
              ],
              const SizedBox(height: 80),
            ],
          ),
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
                  'ADMIN DASHBOARD',
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
            'Hello, ${context.watch<AuthService>().currentUser?.name ?? "Admin"}',
            style: AppDesignSystem.headingLarge.copyWith(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome back to the City Agriculture Management System. Here is an overview of the current operations and financial status.',
            style: AppDesignSystem.bodyLarge.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
            'Detailed view of all agricultural programs, procurement logs, and status tracking.',
            style: AppDesignSystem.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'View All Records',
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
                style: AppDesignSystem.headingMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
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

  Widget _buildEmptyState(BuildContext context, FirebaseService fbService, ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emeraldPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppColors.emeraldPrimary, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Getting Started with City Agriculture Admin',
                      style: AppDesignSystem.headingSmall.copyWith(color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'It looks like there are no activities recorded yet for the current filters. Here is how you can get started.',
                      style: AppDesignSystem.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildGuideItem(
            context,
            icon: Icons.add_circle_outline,
            color: const Color(0xFFD4AF37),
            title: '1. Add a New Activity',
            description: 'Use the "+" icon in the top right corner to manually add a new agricultural activity, training, or procurement request.',
            onTap: () => _showAddActivityDialog(context, fbService),
          ),
          const SizedBox(height: 16),
          _buildGuideItem(
            context,
            icon: Icons.upload_file_rounded,
            color: AppColors.emeraldPrimary,
            title: '2. Import PPMP Excel Data',
            description: 'If you have an existing PPMP in Excel format, you can import it directly to populate the system instantly.',
            onTap: () => _importData(fbService),
          ),
        ],
      ),
    );
  }


  Widget _buildGuideItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppDesignSystem.headingSmall.copyWith(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppDesignSystem.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }


  void _showAddActivityDialog(BuildContext context, FirebaseService fbService) {
    context.read<ActivityFormProvider>().openForm();
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
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description, color: Color(0xFF1B5E20)),
                title: const Text('Rice & Corn Program Report (PPMP)'),
                subtitle: const Text('Standardized format with Q1-Q4 distribution'),
                onTap: () async {
                  Navigator.pop(context);
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(const SnackBar(content: Text('Generating specialized report...')));
                  String? path = await ExportService.exportRiceAndCornProgramReport(activities);
                  if (path != null) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Saved to: $path'),
                        action: SnackBarAction(
                          label: 'OPEN',
                          onPressed: () => OpenFile.open(path),
                        ),
                      ),
                    );
                  }
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

  void _importData(FirebaseService fbService) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Opening file picker...')),
      );

      final result = await ImportService.importAgriPPMPFromExcel(fbService);

      if (mounted) {
        if (result['status'] == 'success') {
          int count = result['imported'] ?? 0;
          List<String> errors = List<String>.from(result['errors'] ?? []);
          
          if (errors.isNotEmpty) {
          if (mounted) {
            _showImportErrors(context, count, errors);
          }
          } else {
            messenger.showSnackBar(
              SnackBar(content: Text('Successfully imported $count activities!')),
            );
          }
        } else if (result['status'] == 'error') {
          messenger.showSnackBar(
            SnackBar(content: Text('Import failed: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Import error: $e')));
      }
    }
  }

  void _showImportErrors(BuildContext context, int successCount, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Text('Import Results (${errors.length} Rejected)'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Successfully imported $successCount records.'),
              const SizedBox(height: 16),
              const Text('Rejected Records:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: errors.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '• ${errors[index]}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }
}

