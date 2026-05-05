import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/design_system.dart';
import '../../models/activity.dart';
import '../../services/firebase_service.dart';
import 'activity_details_dialog.dart';
import 'edit_activity_dialog.dart';
import '../../widgets/skeleton_loading.dart';
import '../../services/navigation_provider.dart';
import '../../services/settings_provider.dart';


class ApprovalsScreen extends StatefulWidget {
  final bool isActive;
  const ApprovalsScreen({super.key, this.isActive = false});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSector = 'All Sectors';
  String _selectedQuarter = 'All Quarters';
  String _sortBy = 'Date (Asc)';
  Stream<List<Activity>>? _activitiesStream;

  @override
  void initState() {
    super.initState();
    _activitiesStream = context.read<FirebaseService>().streamActivities();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) _updateNav();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ApprovalsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateNav();
      });
    }
  }

  void _updateNav() {
    if (!mounted) return;
    final navProvider = context.read<NavigationProvider>();
    final l10n = context.read<SettingsProvider>().l10n;
    
    navProvider.updateLayout(
      title: l10n.translate('approvals_review'),
      actions: [],
      fab: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final fbService = Provider.of<FirebaseService>(context, listen: false);
    return StreamBuilder<List<Activity>>(
        stream: _activitiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const SkeletonList();
          }


          final activities = snapshot.data ?? [];
          
          // Filter for pending approvals
          // Only show items that are NOT Completed and NOT Obligated
          // These are the items that likely need administrative action
          var pendingActivities = activities.where((a) => 
            a.status != 'Completed' && 
            a.status != 'Obligated' &&
            a.status != 'PO Prepared' &&
            a.status != 'IAR'
          ).toList();

          // Apply Sector Filter
          if (_selectedSector != 'All Sectors') {
            pendingActivities = pendingActivities.where((a) => a.sector == _selectedSector).toList();
          }

          // Apply Quarter Filter
          if (_selectedQuarter != 'All Quarters') {
            pendingActivities = pendingActivities.where((a) => a.quarter == _selectedQuarter).toList();
          }

          // Apply Sorting
          if (_sortBy == 'Date (Asc)') {
            // Very basic date sorting assumption
            pendingActivities.sort((a, b) => a.targetDate.compareTo(b.targetDate));
          } else if (_sortBy == 'Budget (Desc)') {
            pendingActivities.sort((a, b) => b.approvedBudget.compareTo(a.approvedBudget));
          }

          // Apply Search Query
          if (_searchQuery.isNotEmpty) {
            pendingActivities = pendingActivities.where((a) => a.matchesSearch(_searchQuery)).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterBar(),
              Expanded(
                child: pendingActivities.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: pendingActivities.length,
                        itemBuilder: (context, index) {
                          final activity = pendingActivities[index];
                          return _buildApprovalCard(context, activity, fbService);
                        },
                      ),
              ),
            ],
          );
        },
    );
  }



  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Tooltip(
              message: 'Filter pending activities by name, sector, or responsible personnel.',
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by activity name, sector, or person...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Dropdown Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDropdownFilter(
                  label: 'Sector',
                  value: _selectedSector,
                  items: ['All Sectors', 'Administrative Support Services Unit', 'Agriculture Logistics Section', 'Crop Section', 'Inland Fisheries Section', 'Institutional Development Section', 'Integrated Agricultural Laboratory', 'Monitoring and Evaluation Section', 'Project Development Section'],
                  onChanged: (val) => setState(() => _selectedSector = val!),
                ),
                const SizedBox(width: 12),
                _buildDropdownFilter(
                  label: 'Quarter',
                  value: _selectedQuarter,
                  items: ['All Quarters', 'Q1', 'Q2', 'Q3', 'Q4'],
                  onChanged: (val) => setState(() => _selectedQuarter = val!),
                ),
                const SizedBox(width: 12),
                _buildDropdownFilter(
                  label: 'Sort By',
                  value: _sortBy,
                  items: ['Date (Asc)', 'Budget (Desc)'],
                  onChanged: (val) => setState(() => _sortBy = val!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item.length > 20 ? '${item.substring(0, 17)}...' : item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, Activity activity, FirebaseService fbService) {
    final formatCurrency = NumberFormat.simpleCurrency(name: '₱ ');
    final bool isCritical = activity.approvedBudget > 50000;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetails(context, activity, fbService),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon / Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isCritical ? Colors.orange.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isCritical ? Icons.priority_high_rounded : Icons.pending_actions_rounded,
                    color: isCritical ? Colors.orange.shade700 : Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 20),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildMiniTag(activity.sector, Colors.grey.shade100, Colors.grey.shade700),
                          const SizedBox(width: 8),
                          _buildMiniTag(activity.quarter, Colors.blue.shade50, Colors.blue.shade700),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.activityName,
                        style: AppDesignSystem.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            activity.responsiblePerson,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            activity.targetDate,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency.format(activity.approvedBudget),
                      style: AppDesignSystem.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.emeraldPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Tooltip(
                      message: 'Open the administrative editor to review and update this activity.',
                      child: ElevatedButton(
                        onPressed: () => _openReview(context, activity, fbService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Review',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
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

  Widget _buildMiniTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text(
            'All Clear!',
            style: AppDesignSystem.headingSmall.copyWith(color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending activities require review at this time.',
            style: AppDesignSystem.bodyMedium.copyWith(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, Activity activity, FirebaseService fbService) {
    showDialog(
      context: context,
      builder: (context) => ActivityDetailsDialog(
        activity: activity,
        fbService: fbService,
        onEdit: () => _openReview(context, activity, fbService),
      ),
    );
  }

  void _openReview(BuildContext context, Activity activity, FirebaseService fbService) {
    showDialog(
      context: context,
      builder: (context) => EditActivityDialog(
        activity: activity,
        fbService: fbService,
      ),
    );
  }
}
