import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import 'package:intl/intl.dart';
import '../../services/navigation_provider.dart';
import '../../services/settings_provider.dart';
import '../../widgets/agri_ui.dart';
import 'procurement_details_dialog.dart';
import 'procurement_form_dialog.dart';
import '../../core/responsive_utils.dart';
import '../../core/app_colors.dart';
import '../../models/program.dart';
import '../../models/procurement.dart';
import '../../services/auth_service.dart';

class SectionUnitOverviewScreen extends StatefulWidget {
  final bool isActive;
  const SectionUnitOverviewScreen({super.key, this.isActive = true});

  @override
  State<SectionUnitOverviewScreen> createState() =>
      _SectionUnitOverviewScreenState();
}

class _SectionUnitOverviewScreenState extends State<SectionUnitOverviewScreen> with TickerProviderStateMixin {
  final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');
  late TabController _tabController;
  List<Program> _currentPrograms = [];
  Stream<List<Program>>? _programsStream;
  Stream<List<Procurement>>? _procurementsStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    final fbService = context.read<FirebaseService>();
    _programsStream = fbService.streamPrograms();
    _procurementsStream = fbService.streamAllProcurements();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.isActive) _updateNav();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initTabController(int length) {
    if (_tabController.length != length) {
      final user = context.read<AuthService>().currentUser;
      int initialIndex = 0;
      
      if (user?.isProgramHead == true && user?.assignedProgramId != null) {
        final assignedIndex = _currentPrograms.indexWhere((p) => p.id == user!.assignedProgramId);
        if (assignedIndex != -1) initialIndex = assignedIndex;
      }

      _tabController.dispose();
      _tabController = TabController(length: length, vsync: this, initialIndex: initialIndex);
      _tabController.addListener(() {
        if (mounted) _updateNav();
      });
      
      // Update nav immediately to reflect correct permissions for initial tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateNav();
      });
    }
  }

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
    final user = context.read<AuthService>().currentUser;
    
    bool canAdd = false;
    if (user != null) {
      if (user.isAdmin) {
        canAdd = true;
      } else if (_currentPrograms.isNotEmpty && _tabController.index < _currentPrograms.length) {
        final currentProgramId = _currentPrograms[_tabController.index].id;
        canAdd = user.canEditProgram(currentProgramId);
      }
    }

    navProvider.updateLayout(
      title: l10n.translate('section_unit_allocation'),
      actions: [],
      fab: canAdd ? FloatingActionButton.extended(
        onPressed: () => _showAddProcurementDialog(context),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('New PR'),
      ) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<Program>>(
      stream: _programsStream!,
      builder: (context, programSnapshot) {
        if (programSnapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: AgriUI.tableShimmer(),
          );
        }

        final programs = programSnapshot.data ?? [];
        _currentPrograms = programs;
        if (programs.isEmpty) {
          return AgriUI.emptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No Programs Found',
            message: 'Initialize agricultural programs to start tracking.',
          );
        }

        _initTabController(programs.length);

        return StreamBuilder<List<Procurement>>(
          stream: _procurementsStream!,
          builder: (context, procurementSnapshot) {
            final rawProcurements = procurementSnapshot.data ?? [];
            
            return Column(
              children: [
                // Search and Filters
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 96, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Search by PR #, Supplier, or Details...',
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
                
                // Program Tabs
                Container(
                   margin: const EdgeInsets.fromLTRB(24, 0, 96, 0),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark 
                      ? Colors.white.withValues(alpha: 0.05) 
                      : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: theme.brightness == Brightness.dark ? Colors.white60 : Colors.black54,
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    tabs: programs.map((p) => Tab(text: p.name)).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: programs.map((program) {
                      final filteredProcurements = rawProcurements.where((p) {
                        if (p.programId != program.id) return false;
                        
                        if (_searchQuery.isNotEmpty) {
                          final query = _searchQuery.toLowerCase();
                          if (!p.prNumber.toLowerCase().contains(query) &&
                              !p.supplier.toLowerCase().contains(query) &&
                              !p.objectOfExpenditure.toLowerCase().contains(query)) {
                            return false;
                          }
                        }
                        return true;
                      }).toList();

                      if (filteredProcurements.isEmpty) {
                        return AgriUI.emptyState(
                          icon: Icons.assignment_outlined,
                          title: 'No Procurements',
                          message: 'No procurement records found for ${program.name}.',
                        );
                      }

                      final grandTotal = program.totalAllocation;
                      final grandSpent = grandTotal - program.currentPpmpBalance;
                      final grandUtilRate = grandTotal > 0 ? grandSpent / grandTotal : 0.0;

                      return ListView(
                        padding: ResponsiveUtils.screenPadding(context),
                        children: [
                          _buildGrandSummaryCard(
                            grandTotal: grandTotal,
                            grandSpent: grandSpent,
                            grandUtilRate: grandUtilRate,
                            activityCount: filteredProcurements.length,
                            programName: program.name,
                          ),
                          const SizedBox(height: 16),
                          ...filteredProcurements.map((p) => _buildProcurementRow(p)),
                           const SizedBox(height: 120),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGrandSummaryCard({
    required double grandTotal,
    required double grandSpent,
    required double grandUtilRate,
    required int activityCount,
    required String programName,
  }) {
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
                      'PROGRAM UTILIZATION',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$programName · $activityCount Procurements',
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
          Row( crossAxisAlignment: CrossAxisAlignment.end,
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
                      'Spent out of ${formatCurrency.format(grandTotal)} Total Allocation',
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

  Widget _buildProcurementRow(Procurement p) {
    final theme = Theme.of(context);
    final fbService = context.read<FirebaseService>();
    final hasPO = p.poNumber.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.02)
              : Slate.shade50.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.03),
          ),
        ),
        child: InkWell(
          onTap: () {
            final user = context.read<AuthService>().currentUser;
            final canEdit = user?.canEditProgram(p.programId) ?? false;
            _showProcurementDetails(context, p, fbService, canEdit);
          },
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
                            'PR #: ${p.prNumber}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: -0.2,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (hasPO ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  hasPO ? 'PO #: ${p.poNumber}' : 'Awaiting PO',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: hasPO ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                p.status,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Slate.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency.format(p.prAmount),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'PR AMOUNT',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Slate.shade400,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        'Supplier',
                        p.supplier.isEmpty ? 'TBD' : p.supplier,
                        Slate.shade500,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        'Fund Source',
                        p.fundSource,
                        Slate.shade500,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoChip(
                        context,
                        'Object of Expenditure',
                        p.objectOfExpenditure,
                        Slate.shade500,
                      ),
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

  void _showProcurementDetails(
    BuildContext context,
    Procurement procurement,
    FirebaseService fbService,
    bool canEdit,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => ProcurementDetailsDialog(
        procurement: procurement,
        fbService: fbService,
        canEdit: canEdit,
        onEdit: () {
          Navigator.pop(ctx);
          _showEditProcurementDialog(context, procurement, fbService);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDeleteProcurement(context, procurement, fbService);
        },
      ),
    );
  }

  void _showAddProcurementDialog(BuildContext context) {
    final fbService = context.read<FirebaseService>();
    Program? currentProgram;
    if (_currentPrograms.isNotEmpty && _tabController.index < _currentPrograms.length) {
      currentProgram = _currentPrograms[_tabController.index];
    }
    
    showDialog(
      context: context,
      builder: (ctx) => ProcurementFormDialog(
        fbService: fbService,
        initialProgram: currentProgram,
      ),
    );
  }

  void _showEditProcurementDialog(
    BuildContext context,
    Procurement procurement,
    FirebaseService fbService,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => ProcurementFormDialog(
        procurement: procurement,
        fbService: fbService,
      ),
    );
  }

  Future<void> _confirmDeleteProcurement(
    BuildContext context,
    Procurement procurement,
    FirebaseService fbService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Procurement'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete PR #${procurement.prNumber}?\nThis will revert the PPMP balance for the program.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await fbService.deleteProcurement(procurement);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PR #${procurement.prNumber} deleted successfully'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete error: $e')),
          );
        }
      }
    }
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
            letterSpacing: 1.2,
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
}
