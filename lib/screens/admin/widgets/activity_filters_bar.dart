import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/activity.dart';
import '../../../models/user_model.dart';
import '../../../services/firebase_service.dart';
import '../../../core/constants.dart';
import '../../../core/responsive_utils.dart';
import '../../../core/app_colors.dart';


class ActivityFiltersBar extends StatefulWidget {
  final List<Activity> activities;
  final String searchQuery;
  final String selectedSector;
  final String? selectedStatus;
  final String selectedStaff;
  final String selectedFundingSource;
  final String selectedSubSector;
  final String selectedMonth;
  final String selectedYear;
  final Function(String) onSearchChanged;
  final Function(String?) onSectorChanged;
  final Function(String?) onSubSectorChanged;
  final Function(String?) onStatusChanged;
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
    this.selectedStatus,
    required this.selectedStaff,
    required this.selectedFundingSource,
    required this.selectedSubSector,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onSearchChanged,
    required this.onSectorChanged,
    required this.onSubSectorChanged,
    required this.onStatusChanged,
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
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
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 8 : 16,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -10,
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < ResponsiveUtils.mobileBreakpoint;
              final headerContent = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isSmall)
                    Text(
                      'Search & Filters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  const Spacer(),
                  if (!isSmall) _headerActions(),
                ],
              );

              if (isSmall) {
                return Column(
                  children: [
                    headerContent,
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: _headerActions()),
                  ],
                );
              }
              return headerContent;
            },
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  'Search by name, PR, staff, or any details (abbreviations allowed)...',
              hintStyle: const TextStyle(color: Slate.shade400, fontSize: 15),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
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
            onChanged: widget.onSearchChanged,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < ResponsiveUtils.mobileBreakpoint;
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
                crossAxisSpacing: isSmall ? 12 : 24,
                mainAxisSpacing: isSmall ? 16 : 20,
                childAspectRatio: crossAxisCount == 1
                    ? 3.8
                    : (crossAxisCount == 2 ? 3.2 : 4),
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
                    label: 'Status',
                    initialValue: widget.selectedStatus,
                    items: AppConstants.activityStatuses,
                    onChanged: (val) => widget.onStatusChanged(val),
                    icon: Icons.flag_outlined,
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
    );
  }

  Widget _buildStaffDropdown(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: Provider.of<FirebaseService>(
        context,
        listen: false,
      ).streamUsers(),
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
      label: Text(label),
      leadingIcon: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          label: label == 'Status'
              ? 'All Status'
              : label == 'Staff'
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.calendar_month_rounded, size: 18),
          label: const Text('Monthly View'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.5),
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
