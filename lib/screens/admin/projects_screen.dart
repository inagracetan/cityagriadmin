import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../models/activity.dart';
import '../../services/firebase_service.dart';
import '../../services/navigation_provider.dart';
import '../../services/activity_form_provider.dart';
import '../../core/constants.dart';
import '../../widgets/skeleton_loading.dart';



class ProjectsScreen extends StatefulWidget {
  final bool isActive;
  const ProjectsScreen({super.key, this.isActive = false});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();

  static Color getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('complete') || s.contains('iar')) {
      return const Color(0xFF10B981);
    }
    if (s.contains('obligated') || s.contains('po prepared')) {
      return const Color(0xFF6366F1);
    }
    if (s.contains('no budget')) {
      return const Color(0xFFEF4444);
    }
    if (s.contains('preparation') || 
        s.contains('processing') || 
        s.contains('sig') || 
        s.contains('bac') ||
        s.contains('recanvas')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF3B82F6);
  }
}

class _ProjectsScreenState extends State<ProjectsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _horizontalController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSector;
  String? _selectedYear;
  String? _selectedPerson;
  String _sortBy = 'alphabetical';

  Stream<List<Activity>>? _activitiesStream;

  @override
  void initState() {
    super.initState();
    _activitiesStream = context.read<FirebaseService>().streamActivities();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) _updateNav();
    });
  }

  @override
  void didUpdateWidget(ProjectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateNav();
      });
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateNav() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    context.read<NavigationProvider>().updateLayout(
      title: 'Projects (PPMP)',
      actions: [
        // Premium Glassmorphic Search Bar
        Focus(
          onFocusChange: (hasFocus) => setState(() {}),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuint,
            width: _searchQuery.isNotEmpty || _searchController.text.isNotEmpty ? 280 : 200,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark 
                ? Colors.white.withValues(alpha: 0.05) 
                : Slate.shade100.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Slate.shade200,
                width: 1.5,
              ),
              boxShadow: [
                if (isDark)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.outfit(
                fontSize: 14, 
                color: isDark ? Colors.white : Slate.shade900,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search projects...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 14, 
                  color: isDark ? Colors.white38 : Slate.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded, 
                  size: 20, 
                  color: _searchQuery.isNotEmpty ? AppColors.primary : (isDark ? Colors.white38 : Slate.shade400)
                ),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter Button in AppBar
        _buildNavAction(
          icon: Icons.tune_rounded,
          tooltip: 'Filters',
          onPressed: () => _showFilterDialog(context),
          hasBadge: _selectedSector != null || _selectedYear != null || _selectedPerson != null,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () => context.read<ActivityFormProvider>().openForm(),
        label: Text('New Project', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        icon: const Icon(Icons.add_task_rounded, size: 20),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        extendedIconLabelSpacing: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildNavAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool hasBadge,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasBadge ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.1) : Slate.shade200),
                width: hasBadge ? 1.5 : 1,
              ),
              boxShadow: [
                if (hasBadge)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon, 
                  size: 22, 
                  color: hasBadge ? AppColors.primary : (isDark ? Colors.white70 : Slate.shade700)
                ),
                if (hasBadge)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Slate.shade900 : Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 400,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Filter Projects',
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'By Sector',
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFilterChip(
                                  label: 'All Sectors',
                                  isSelected: _selectedSector == null,
                                  onSelected: () {
                                    setDialogState(() => _selectedSector = null);
                                    setState(() {});
                                  },
                                  isDark: isDark,
                                ),
                                ...AppConstants.sectors.map((sector) => _buildFilterChip(
                                  label: sector,
                                  isSelected: _selectedSector == sector,
                                  onSelected: () {
                                    setDialogState(() => _selectedSector = sector);
                                    setState(() {});
                                  },
                                  isDark: isDark,
                                )),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Text(
                              'By Year',
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFilterChip(
                                  label: 'All Years',
                                  isSelected: _selectedYear == null,
                                  onSelected: () {
                                    setDialogState(() => _selectedYear = null);
                                    setState(() {});
                                  },
                                  isDark: isDark,
                                ),
                                ...AppConstants.years.map((year) => _buildFilterChip(
                                  label: year,
                                  isSelected: _selectedYear == year,
                                  onSelected: () {
                                    setDialogState(() => _selectedYear = year);
                                    setState(() {});
                                  },
                                  isDark: isDark,
                                )),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Text(
                              'By Responsible Person',
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildFilterChip(
                                  label: 'All Staff',
                                  isSelected: _selectedPerson == null,
                                  onSelected: () {
                                    setDialogState(() => _selectedPerson = null);
                                    setState(() {});
                                  },
                                  isDark: isDark,
                                ),
                                ...AppConstants.staffList.map((person) => _buildFilterChip(
                                  label: person,
                                  isSelected: _selectedPerson == person,
                                  onSelected: () {
                                    setDialogState(() => _selectedPerson = person);
                                    setState(() {});
                                  },
                                  isDark: isDark,
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedSector = null;
                                _selectedYear = null;
                                _selectedPerson = null;
                                _searchQuery = '';
                                _searchController.clear();
                              });
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Reset All',
                              style: GoogleFonts.outfit(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
              // Sort Button
              PopupMenuButton<String>(
                onSelected: (val) => setState(() => _sortBy = val),
                offset: const Offset(0, 56),
                itemBuilder: (context) => [
                  _buildSortItem('alphabetical', 'Alphabetical (A-Z)', Icons.sort_by_alpha_rounded),
                  _buildSortItem('budget_high', 'Budget (High to Low)', Icons.trending_down_rounded),
                  _buildSortItem('budget_low', 'Budget (Low to High)', Icons.trending_up_rounded),
                  _buildSortItem('newest', 'By Target Date', Icons.calendar_today_rounded),
                ],
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Apply Filters',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppColors.primary 
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? AppColors.primary 
              : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected 
              ? Colors.white 
              : (isDark ? Colors.white70 : const Color(0xFF475569)),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _sortBy == value;
    
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon, 
            size: 18, 
            color: isSelected ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54)
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? AppColors.primary : (isDark ? Colors.white : const Color(0xFF0F172A)),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check_rounded, color: AppColors.primary, size: 16),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fbService = Provider.of<FirebaseService>(context, listen: false);

    return Container(
      color: isDark ? AppColors.premiumNavy : const Color(0xFFF8FAFC),
      child: StreamBuilder<List<Activity>>(
        stream: _activitiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const SkeletonKanban();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }


          var activities = snapshot.data ?? [];
          
          // Filter by search query, sector, and year
          if (_searchQuery.isNotEmpty) {
            activities = activities.where((a) => 
              a.activityName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              a.sector.toLowerCase().contains(_searchQuery.toLowerCase())
            ).toList();
          }

          if (_selectedSector != null) {
            activities = activities.where((a) => a.sector == _selectedSector).toList();
          }

          if (_selectedYear != null) {
            activities = activities.where((a) => a.selectedYear == _selectedYear).toList();
          }

          if (_selectedPerson != null) {
            activities = activities.where((a) => a.responsiblePerson == _selectedPerson).toList();
          }

          // Sort activities
          switch (_sortBy) {
            case 'alphabetical':
              activities.sort((a, b) => a.activityName.compareTo(b.activityName));
              break;
            case 'budget_high':
              activities.sort((a, b) => b.totalBudget.compareTo(a.totalBudget));
              break;
            case 'budget_low':
              activities.sort((a, b) => a.totalBudget.compareTo(b.totalBudget));
              break;
            case 'newest':
              activities.sort((a, b) => b.targetDate.compareTo(a.targetDate));
              break;
          }
          
          // Categorize activities into columns - Synchronized with centralized constants
          final Map<String, List<Activity>> columns = {
            'Planned': activities.where((a) => 
              [
                AppConstants.statusPlanned,
                AppConstants.statusPRPreparation,
                AppConstants.statusPRPrepared,
                AppConstants.statusPRStage,
                AppConstants.statusBacOffice,
                AppConstants.statusBacForPRNumber,
                AppConstants.statusDraft,
                'Pending PR',
              ].contains(a.status)
            ).toList(),
            'Processing': activities.where((a) => 
              [
                AppConstants.statusBACProcessing,
                AppConstants.statusBACBidding,
                AppConstants.statusBACShopping,
                AppConstants.statusRecanvas,
                AppConstants.statusBACApprovedOBRE,
                AppConstants.statusObreAbstractSig,
                AppConstants.statusAbstractSigned,
                'For Signature',
              ].contains(a.status)
            ).toList(),
            'Obligated': activities.where((a) => 
              [
                AppConstants.statusPOStage,
                AppConstants.statusPOPrepared,
                AppConstants.statusPOSigned,
                AppConstants.statusObligated,
                AppConstants.statusPending,
                'For PO',
              ].contains(a.status)
            ).toList(),
            'Completed': activities.where((a) => 
              [
                AppConstants.statusCompleted,
                AppConstants.statusDelivered,
                AppConstants.statusIAR,
                AppConstants.statusPaid,
              ].contains(a.status)
            ).toList(),
          };

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutQuart,
            switchOutCurve: Curves.easeInQuart,
            child: Column(
              key: ValueKey('${activities.length}-$_searchQuery-$_selectedSector-$_selectedYear-$_selectedPerson'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: (activities.isEmpty && (_searchQuery.isNotEmpty || _selectedSector != null || _selectedYear != null || _selectedPerson != null))
                    ? _buildEmptyState(context)
                    : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPipelineInfo(context),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 180,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              scrollbarTheme: ScrollbarThemeData(
                                thumbColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return AppColors.primary.withValues(alpha: 0.4);
                                  }
                                  return isDark ? Colors.white.withValues(alpha: 0.1) : Slate.shade300;
                                }),
                                radius: const Radius.circular(12),
                                thickness: WidgetStateProperty.all(8),
                                minThumbLength: 100,
                              ),
                            ),
                            child: Scrollbar(
                              controller: _horizontalController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                controller: _horizontalController,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.fromLTRB(24, 0, 96, 24),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: columns.entries.map((entry) {
                                    return _buildKanbanColumn(
                                      context, 
                                      entry.key, 
                                      entry.value, 
                                      fbService,
                                      activities.length,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }



  Widget _buildPipelineInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return StreamBuilder<List<Activity>>(
      stream: _activitiesStream,
      builder: (context, snapshot) {
        final totalActivities = snapshot.data?.length ?? 0;
        final totalBudget = snapshot.data?.fold<double>(0, (p, a) => p + a.approvedBudget) ?? 0;
        
        return Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [Slate.shade800, Slate.shade900]
                : [Colors.white, Slate.shade50],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade200,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.auto_graph_rounded,
                    size: 140,
                    color: AppColors.primary.withValues(alpha: 0.03),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Project Pipeline & Logistics',
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white : Slate.shade900,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildStatTag(
                                  label: '$totalActivities Active Projects',
                                  icon: Icons.assignment_turned_in_rounded,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 12),
                                _buildStatTag(
                                  label: NumberFormat.compactCurrency(symbol: '₱').format(totalBudget),
                                  icon: Icons.account_balance_wallet_rounded,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatTag({required String label, required IconData icon, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Slate.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : Slate.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Slate.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 100,
              color: isDark ? Colors.white10 : Slate.shade200,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No matching projects found',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Slate.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your search or filters to find what you\'re looking for.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: isDark ? Colors.white38 : Slate.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
                _selectedSector = null;
                _selectedYear = null;
                _selectedPerson = null;
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset All Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context, 
    String title, 
    List<Activity> activities,
    FirebaseService fbService,
    int totalActivities,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color columnColor;
    IconData columnIcon;
    List<Color> headerGradient;
    
    switch (title) {
      case 'Planned':
        columnColor = const Color(0xFF3B82F6);
        columnIcon = Icons.inventory_2_rounded;
        headerGradient = [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
        break;
      case 'Processing':
        columnColor = const Color(0xFFF59E0B);
        columnIcon = Icons.sync_rounded;
        headerGradient = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
        break;
      case 'Obligated':
        columnColor = const Color(0xFF6366F1);
        columnIcon = Icons.verified_user_rounded;
        headerGradient = [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
        break;
      case 'Completed':
        columnColor = const Color(0xFF10B981);
        columnIcon = Icons.check_circle_outline_rounded;
        headerGradient = [const Color(0xFF10B981), const Color(0xFF059669)];
        break;
      default:
        columnColor = Colors.grey;
        columnIcon = Icons.help_outline;
        headerGradient = [Colors.grey, Colors.blueGrey];
    }

    return DragTarget<Activity>(
      onWillAcceptWithDetails: (details) => !_isInColumn(details.data, title),
      onAcceptWithDetails: (details) {
        _updateActivityStatus(fbService, details.data, title);
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 380,
          margin: const EdgeInsets.only(right: 28),
          decoration: BoxDecoration(
            color: isDark ? Slate.shade900.withValues(alpha: 0.4) : Slate.shade50.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isOver 
                ? columnColor 
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade200),
              width: isOver ? 2.5 : 1,
            ),
            boxShadow: isOver ? [
              BoxShadow(
                color: columnColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: Column(
            children: [
              // Premium Column Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [Slate.shade800, Slate.shade900]
                      : [Colors.white, Slate.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: headerGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: columnColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(columnIcon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    title.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : Slate.shade900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${activities.length}',
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white54 : Slate.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    height: 4,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade100,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 1000),
                                    curve: Curves.easeOutCubic,
                                    height: 4,
                                    width: totalActivities > 0 ? (activities.length / totalActivities) * 300 : 0, // 300 is max width approx
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: headerGradient),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isOver)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 200),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: columnColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: columnColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Column Budget Summary
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.02) : Slate.shade100.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'STAGE BUDGET',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white24 : Slate.shade400,
                            ),
                          ),
                          Text(
                            NumberFormat.compactCurrency(symbol: '₱').format(
                              activities.fold<double>(0, (prev, a) => prev + a.approvedBudget)
                            ),
                            style: GoogleFonts.robotoMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: columnColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  physics: const BouncingScrollPhysics(),
                  itemCount: activities.isEmpty ? 1 : activities.length,
                  itemBuilder: (context, index) {
                    if (activities.isEmpty) {
                      return _buildColumnEmptyState(title, columnIcon, isDark);
                    }
                    return _buildProjectCard(context, activities[index], fbService);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnEmptyState(String title, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.01) : Slate.shade100.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Slate.shade200, 
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Icon(
                icon, 
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade200, 
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Pipeline Empty',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white24 : Slate.shade300,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Drag projects to this column\nto update their workflow status.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDark ? Colors.white10 : Slate.shade400,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _isInColumn(Activity activity, String columnTitle) {
    final s = activity.status;
    if (columnTitle == 'Planned') {
      return [AppConstants.statusPlanned, AppConstants.statusNoBudget, AppConstants.statusNoBudgetYet, AppConstants.statusDraft].contains(s);
    }
    if (columnTitle == 'Processing') {
      return [
        AppConstants.statusPRStage, 
        AppConstants.statusPRPrepared,
        AppConstants.statusBACProcessing, 
        AppConstants.statusObreAbstractSig, 
        AppConstants.statusBACShopping, 
        AppConstants.statusBacOffice, 
        AppConstants.statusBacForPRNumber, 
        AppConstants.statusBACBidding, 
        AppConstants.statusRecanvas, 
        AppConstants.statusBACApprovedOBRE, 
      ].contains(s);
    }
    if (columnTitle == 'Obligated') {
      return s == AppConstants.statusPOStage || s == AppConstants.statusPOSigned || s == AppConstants.statusObligated || s == AppConstants.statusPOPrepared;
    }
    if (columnTitle == 'Completed') {
      return s == AppConstants.statusCompleted || s == AppConstants.statusDelivered || s == AppConstants.statusIAR;
    }
    return false;
  }

  void _updateActivityStatus(FirebaseService fbService, Activity activity, String columnTitle) {
    String newStatus;
    switch (columnTitle) {
      case 'Planned': newStatus = AppConstants.statusPlanned; break;
      case 'Processing': newStatus = AppConstants.statusPRStage; break;
      case 'Obligated': newStatus = AppConstants.statusPOStage; break;
      case 'Completed': newStatus = AppConstants.statusCompleted; break;
      default: newStatus = activity.status;
    }
    
    fbService.updateActivityStatus(activity.id, newStatus).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Moved "${activity.activityName}" to $columnTitle',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  Widget _buildProjectCard(BuildContext context, Activity activity, FirebaseService fbService) {
    return _HoverableProjectCard(
      activity: activity,
      fbService: fbService,
      onTap: () => _showDetails(context, activity, fbService),
    );
  }
  void _showDetails(BuildContext context, Activity activity, FirebaseService fbService) {
    context.read<ActivityFormProvider>().openForm(activity: activity);
  }
}

class _HoverableProjectCard extends StatefulWidget {
  final Activity activity;
  final FirebaseService fbService;
  final VoidCallback onTap;

  const _HoverableProjectCard({
    required this.activity,
    required this.fbService,
    required this.onTap,
  });

  @override
  State<_HoverableProjectCard> createState() => _HoverableProjectCardState();
}

class _HoverableProjectCardState extends State<_HoverableProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(name: '₱ ');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = ProjectsScreen.getStatusColor(widget.activity.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.grab,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _isHovered ? 1.02 : 1.0,
        child: LongPressDraggable<Activity>(
          data: widget.activity,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 360,
              decoration: BoxDecoration(
                color: isDark ? Slate.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Slate.shade700 : Slate.shade200,
                ),
              ),
              child: _StaticCardContent(
                activity: widget.activity,
                format: formatCurrency,
                isDragging: true,
                statusColor: statusColor,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.2,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Slate.shade100,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Slate.shade800 : Slate.shade200,
                  width: 2,
                ),
              ),
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(28),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark ? AppColors.premiumCard : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _isHovered 
                    ? statusColor.withValues(alpha: 0.5) 
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade200),
                  width: _isHovered ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered 
                      ? statusColor.withValues(alpha: 0.2) 
                      : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: _isHovered ? 20 : 12,
                    offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
                  ),
                ],
              ),
              child: _StaticCardContent(
                activity: widget.activity,
                format: formatCurrency,
                isDragging: false,
                statusColor: statusColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticCardContent extends StatelessWidget {
  final Activity activity;
  final NumberFormat format;
  final bool isDragging;
  final Color statusColor;

  const _StaticCardContent({
    required this.activity,
    required this.format,
    required this.isDragging,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [statusColor, statusColor.withValues(alpha: 0.6)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                bottomLeft: Radius.circular(28),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          activity.activityName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Slate.shade900,
                            height: 1.3,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _SectorTag(sector: activity.sector),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : Slate.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : Slate.shade100,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'APPROVED BUDGET',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: isDark ? Colors.white30 : Slate.shade400,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                format.format(activity.approvedBudget),
                                style: GoogleFonts.robotoMono(
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Slate.shade900,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade200,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TARGET DATE',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: isDark ? Colors.white30 : Slate.shade400,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                activity.targetDate,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FUND UTILIZATION',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: isDark ? Colors.white30 : Slate.shade400,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${activity.approvedBudget > 0 ? ((activity.effectivePOAmount / activity.approvedBudget) * 100).toStringAsFixed(1) : 0}%',
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final percent = activity.approvedBudget > 0 ? (activity.effectivePOAmount / activity.approvedBudget).clamp(0.0, 1.0) : 0.0;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.fastOutSlowIn,
                            height: 8,
                            width: constraints.maxWidth * percent,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Slate.shade200,
                            width: 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: isDark ? Slate.shade800 : Slate.shade50,
                          child: Text(
                            activity.responsiblePerson.isNotEmpty 
                              ? activity.responsiblePerson.substring(0, 1).toUpperCase()
                              : '?',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white54 : Slate.shade500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ASSIGNED TO',
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white24 : Slate.shade400,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              activity.responsiblePerson.isEmpty ? 'Unassigned' : activity.responsiblePerson,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13, 
                                color: isDark ? Colors.white70 : Slate.shade700, 
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.drag_indicator_rounded,
                        size: 20,
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Slate.shade200,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectorTag extends StatelessWidget {
  final String sector;

  const _SectorTag({required this.sector});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String label = AppConstants.abbreviate(sector);
    Color tagColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);
    Color textColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B);

    if (label == 'ASSU') {
      tagColor = const Color(0xFF6366F1).withValues(alpha: 0.15);
      textColor = const Color(0xFF818CF8);
    } else if (label == 'CS') {
      tagColor = const Color(0xFF10B981).withValues(alpha: 0.15);
      textColor = const Color(0xFF34D399);
    } else if (label == 'IDS') {
      tagColor = const Color(0xFF8B5CF6).withValues(alpha: 0.15);
      textColor = const Color(0xFFA78BFA);
    } else if (label == 'IAL') {
      tagColor = const Color(0xFF0EA5E9).withValues(alpha: 0.15);
      textColor = const Color(0xFF38BDF8);
    } else if (label == 'M&E') {
      tagColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      textColor = const Color(0xFFFBBF24);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}



