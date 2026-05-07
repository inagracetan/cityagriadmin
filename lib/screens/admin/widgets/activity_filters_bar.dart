import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/activity.dart';
import '../../../models/user_model.dart';
import '../../../services/firebase_service.dart';
import '../../../core/constants.dart';
import '../../../core/responsive_utils.dart';
import '../../../core/app_colors.dart';
import '../../../core/design_system.dart';


class ActivityFiltersBar extends StatefulWidget {
  final List<Activity> activities;
  final String searchQuery;
  final String selectedSector;
  final String selectedStaff;
  final String selectedFundingSource;
  final String selectedSubSector;
  final String selectedMonth;
  final String selectedYear;
  final Function(String) onSearchChanged;
  final Function(String?) onSectorChanged;
  final Function(String?) onSubSectorChanged;
  final Function(String?) onStaffChanged;
  final Function(String?) onFundingSourceChanged;
  final Function(String?) onMonthChanged;
  final Function(String?) onYearChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onWfpMonthlyViewPressed;

  const ActivityFiltersBar({
    super.key,
    required this.activities,
    required this.searchQuery,
    required this.selectedSector,
    required this.selectedStaff,
    required this.selectedFundingSource,
    required this.selectedSubSector,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onSearchChanged,
    required this.onSectorChanged,
    required this.onSubSectorChanged,
    required this.onStaffChanged,
    required this.onFundingSourceChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onClearFilters,
    required this.onWfpMonthlyViewPressed,
  });

  @override
  State<ActivityFiltersBar> createState() => _ActivityFiltersBarState();
}

class _ActivityFiltersBarState extends State<ActivityFiltersBar> {
  late TextEditingController _searchController;
  bool _showFilters = false;
  Stream<List<UserModel>>? _usersStream;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _usersStream = context.read<FirebaseService>().streamUsers();
  }

  @override
  void didUpdateWidget(ActivityFiltersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveUtils.isMobile(context);
    return GlassCard(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 0,
        vertical: 0,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Builder(
            builder: (context) {
              final isSmall = MediaQuery.of(context).size.width < ResponsiveUtils.mobileBreakpoint;
              
              final searchField = TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, PR, staff...',
                  hintStyle: AppDesignSystem.bodyMedium.copyWith(color: AppColors.textMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : Slate.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Slate.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                ),
                style: AppDesignSystem.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface),
                onChanged: widget.onSearchChanged,
              );

              if (isSmall) {
                return Column(
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: _headerActions()),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 12),
                  _headerActions(),
                ],
              );
            },
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !_showFilters
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final isSmall = MediaQuery.of(context).size.width < ResponsiveUtils.mobileBreakpoint;
                          final crossAxisCount = ResponsiveUtils.gridCrossAxisCount(
                            context, 
                            mobile: 1, 
                            tablet: 2, 
                            desktop: 3,
                          );

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: isSmall ? 8 : 12,
                            mainAxisSpacing: isSmall ? 8 : 12,
                            childAspectRatio: crossAxisCount == 1
                                ? 5.0
                                : (crossAxisCount == 2 ? 4.5 : 5.5),
                            children: [
                              _filterDropdown(
                                label: 'Sector',
                                initialValue: widget.selectedSector,
                                items: AppConstants.sectors,
                                onChanged: (val) => widget.onSectorChanged(val ?? ''),
                                icon: Icons.category_outlined,
                              ),
                              _filterDropdown(
                                label: 'Sub-sector',
                                initialValue: widget.selectedSubSector,
                                items: AppConstants.subSectors,
                                onChanged: (val) => widget.onSubSectorChanged(val ?? ''),
                                icon: Icons.grid_view_outlined,
                              ),
                              _filterDropdown(
                                label: 'Funding Source',
                                initialValue: widget.selectedFundingSource,
                                items: AppConstants.fundingSources,
                                onChanged: (val) => widget.onFundingSourceChanged(val),
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                              _filterDropdown(
                                label: 'Target Month',
                                initialValue: widget.selectedMonth,
                                items: AppConstants.months,
                                onChanged: (val) => widget.onMonthChanged(val ?? ''),
                                icon: Icons.calendar_month_outlined,
                              ),
                              _filterDropdown(
                                label: 'Target Year',
                                initialValue: widget.selectedYear,
                                items: AppConstants.years,
                                onChanged: (val) => widget.onYearChanged(val ?? ''),
                                icon: Icons.event_available_outlined,
                              ),
                              _buildStaffDropdown(context),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffDropdown(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _usersStream,
      builder: (context, userSnap) {
        final users = userSnap.data ?? [];
        final userNames = users.map((u) => u.name).toSet();

        // Also get names from the activities list being displayed
        final activityNames = widget.activities
            .map((a) => a.responsiblePerson)
            .where((name) => name.isNotEmpty)
            .toSet();

        // Combine both sets and sort
        final allNames = (userNames.union(activityNames)).toList()..sort();

        return _filterDropdown(
          label: 'Staff',
          initialValue: widget.selectedStaff,
          items: allNames,
          onChanged: (val) => widget.onStaffChanged(val ?? ''),
          icon: Icons.person_outline,
        );
      },
    );
  }

  Widget _filterDropdown({
    required String label,
    required String? initialValue,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      enableSearch: true,
      enableFilter: true,
      menuHeight: 250,
      initialSelection: (initialValue == null || initialValue.isEmpty)
          ? null
          : initialValue,
      label: Text(label, style: AppDesignSystem.labelMedium),
      leadingIcon: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Slate.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Slate.shade100),
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
      ),
      dropdownMenuEntries: [
        DropdownMenuEntry(
          value: '',
          label: label == 'Staff'
              ? 'All Staff'
              : 'All ${label}s',
        ),
        ...items.map(
          (s) => DropdownMenuEntry(
            value: s,
            label: s,
          ),
        ),
      ],
      onSelected: onChanged,
    );
  }

  Widget _headerActions() {
    final activeFiltersCount = [
      widget.selectedSector,
      widget.selectedSubSector,
      widget.selectedStaff,
      widget.selectedFundingSource,
      widget.selectedMonth,
    ].where((f) => f.isNotEmpty).length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          icon: Icon(
            _showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
            size: 18,
          ),
          label: Text(
            _showFilters 
                ? 'Hide Filters' 
                : (activeFiltersCount > 0 ? 'Filters ($activeFiltersCount)' : 'Filters')
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _showFilters || activeFiltersCount > 0 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).textTheme.bodyMedium?.color,
            side: BorderSide(
              color: _showFilters || activeFiltersCount > 0
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                  : Theme.of(context).dividerColor,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          icon: const Icon(Icons.calendar_month_rounded, size: 18),
          label: const Text('Monthly View'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.5),
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: widget.onWfpMonthlyViewPressed,
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reset'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade100),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: widget.onClearFilters,
        ),
      ],
    );
  }
}

