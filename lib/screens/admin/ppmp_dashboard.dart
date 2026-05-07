import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../core/design_system.dart';
import '../../models/activity.dart';
import '../../services/firebase_service.dart';
import '../../widgets/skeleton_loading.dart';
import 'widgets/ppmp_dashboard_widgets.dart';


class PPMPDashboard extends StatefulWidget {
  final bool isActive;
  const PPMPDashboard({super.key, this.isActive = true});

  @override
  State<PPMPDashboard> createState() => _PPMPDashboardState();
}

class _PPMPDashboardState extends State<PPMPDashboard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final formatCurrency = NumberFormat.simpleCurrency(name: '₱ ');
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedYear = DateTime.now().year.toString();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Activity>>? _activitiesStream;

  @override
  void initState() {
    super.initState();
    _activitiesStream = context.read<FirebaseService>().streamActivities();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      color: const Color(0xFFF8FAFC),
      child: StreamBuilder<List<Activity>>(
        stream: _activitiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const SkeletonDashboard();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }


          
          var activities = snapshot.data ?? [];
          
          // Filter by Year
          activities = activities.where((a) => a.selectedYear == _selectedYear).toList();
          
          if (_searchQuery.isNotEmpty) {
            activities = activities.where((a) => a.matchesSearch(_searchQuery)).toList();
          }
          
          // Calculate Totals
          double totalBudget = 0;
          double totalSpent = 0;
          for (var a in activities) {
            totalBudget += a.approvedBudget;
            totalSpent += a.effectivePOAmount;
          }
          double budgetBalance = totalBudget - totalSpent;
          double spentPercentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0;
          double balancePercentage = totalBudget > 0 ? (budgetBalance / totalBudget) : 0;

          return SingleChildScrollView(
            primary: false, // Avoid conflicts with shell scroll controller
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 32),
                _buildSummaryCards(
                  totalBudget: totalBudget,
                  budgetBalance: budgetBalance,
                  totalSpent: totalSpent,
                  totalProjects: activities.length,
                  spentPercentage: spentPercentage,
                  balancePercentage: balancePercentage,
                ),
                const SizedBox(height: 32),
                Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    if (screenWidth < 1100) {
                      return Column(
                        children: [
                          PPMPBudgetVsActualChart(activities: activities),
                          const SizedBox(height: 24),
                          PPMPAllocationSourceChart(activities: activities),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: PPMPBudgetVsActualChart(activities: activities)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: PPMPAllocationSourceChart(activities: activities)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                PPMPProjectListTable(activities: activities),
                const SizedBox(height: 32),
                PPMPHeatmapView(activities: activities),
                const SizedBox(height: 32),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search PPMP activities, sectors, or sources...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: AppDesignSystem.iconSizeSmall, color: Colors.grey.shade500),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, size: AppDesignSystem.iconSizeSmall, color: Colors.grey.shade500),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 14),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'PPMP - FY $_selectedYear',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Approved',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Project Procurement Management Plan',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            _buildHeaderAction(
              _isSearching ? Icons.close : Icons.search,
              onTap: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            _buildYearSelector(),


          ],
        ),
      ],
    );
  }

  Widget _buildHeaderAction(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Icon(icon, size: 20, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedYear,
          items: AppConstants.years.map((y) {
            return DropdownMenuItem(
              value: y,
              child: Text(
                y,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedYear = val;
              });
            }
          },
          icon: Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildSummaryCards({
    required double totalBudget,
    required double budgetBalance,
    required double totalSpent,
    required int totalProjects,
    required double spentPercentage,
    required double balancePercentage,
  }) {
    final cards = [
      PPMPSummaryCard(
        title: 'Total Budget (FY $_selectedYear)',
        value: formatCurrency.format(totalBudget),
        subtitle: 'Annual Allocation',
        icon: Icons.account_balance_wallet_outlined,
        trendColor: Colors.blue,
      ),
      PPMPSummaryCard(
        title: 'Budget Balance',
        value: formatCurrency.format(budgetBalance),
        percentage: balancePercentage,
        subtitle: 'Remaining Funds',
        icon: Icons.pie_chart_outline,
        trendColor: Colors.green,
      ),
      PPMPSummaryCard(
        title: 'Total Spent',
        value: formatCurrency.format(totalSpent),
        percentage: spentPercentage,
        subtitle: 'Actual Expenditures',
        icon: Icons.trending_up,
        trendColor: Colors.orange,
      ),
      PPMPSummaryCard(
        title: 'Total Projects',
        value: totalProjects.toString(),
        subtitle: 'PPMP Line Items',
        icon: Icons.list_alt_rounded,
        trendColor: Colors.purple,
      ),
    ];

    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final int crossAxisCount = screenWidth < 600
            ? 2
            : screenWidth < 900
                ? 2
                : 4;
        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 110, // Adjusted for horizontal layout
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }


}

