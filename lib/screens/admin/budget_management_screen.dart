import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/currency_formatter.dart';
import '../../models/budget_line.dart';
import '../../services/budget_validation_service.dart';
import '../../services/firebase_service.dart';
import '../../services/navigation_provider.dart';
import '../../widgets/skeleton_loading.dart';

class BudgetManagementScreen extends StatefulWidget {
  final bool isActive;
  const BudgetManagementScreen({super.key, this.isActive = true});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');

  Stream<List<BudgetLine>>? _budgetLinesStream;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _budgetLinesStream = context.read<FirebaseService>().streamBudgetLines();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final navProvider = context.read<NavigationProvider>();

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFF8FAFC),
      child: StreamBuilder<List<BudgetLine>>(
        stream: _budgetLinesStream,
        builder: (context, snapshot) {
          if (widget.isActive && snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              navProvider.updateLayout(
                actions: [
                  IconButton(
                    icon: const Icon(Icons.sync_alt),
                    onPressed: () =>
                        _showSyncMenu(context, snapshot.data ?? []),
                    tooltip: 'Export/Import/Copy Paste',
                  ),
                ],
                fab: FloatingActionButton.extended(
                  onPressed: () => _showAddBudgetDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Budget Line'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  tooltip:
                      'Create a new budgetary ceiling for an object of expenditure.',
                ),
              );
            });
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const SkeletonDashboard();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final budgetLines = snapshot.data ?? [];
          final query = _searchController.text.toLowerCase();

          final filteredLines = budgetLines.where((l) {
            if (query.isEmpty) return true;
            return l.objectOfExpenditure.toLowerCase().contains(query) ||
                l.subCategory.toLowerCase().contains(query) ||
                l.fundSource.toLowerCase().contains(query) ||
                l.accountCode.toLowerCase().contains(query);
          }).toList();

          final cmoLines = filteredLines.where((l) => l.isCMO).toList();
          final regularLines = filteredLines.where((l) => !l.isCMO).toList();

          if (budgetLines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No budget data available for ${SystemConfig.targetBudgetYearStr}.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _generateDefaultBudgetLines(context),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Load Default Templates'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildGlobalSummary(budgetLines),
                  const SizedBox(height: 40),
                  if (cmoLines.isNotEmpty) ...[
                    _buildCMOSection(context, cmoLines.first),
                    const SizedBox(height: 40),
                  ],
                  _buildRegularBudgetSection(context, regularLines),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateDefaultBudgetLines(BuildContext context) async {
    final fsService = context.read<FirebaseService>();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      for (var entry in AppConstants.budgetSubCategories.entries) {
        final oe = entry.key;
        final subcats = entry.value;

        if (subcats.isEmpty) {
          final docId = fsService.db
              .collection(AppConstants.colBudgetLines)
              .doc()
              .id;
          await fsService.updateBudgetLine(
            BudgetLine(
              id: docId,
              accountCode: '',
              fundSource: 'General Fund ${SystemConfig.targetBudgetYearStr}',
              objectOfExpenditure: oe,
              subCategory: '',
            ),
          );
        } else {
          for (var sub in subcats) {
            final docId = fsService.db
                .collection(AppConstants.colBudgetLines)
                .doc()
                .id;
            await fsService.updateBudgetLine(
              BudgetLine(
                id: docId,
                accountCode: '',
                fundSource: 'General Fund ${SystemConfig.targetBudgetYearStr}',
                objectOfExpenditure: oe,
                subCategory: sub,
              ),
            );
          }
        }
      }

      final defaultSingles = [
        'Travelling Expenses',
        'Fuel, Oil & Lubricants (Plus Backhoe use)',
        '3 Sets Desktop Office Computer with Printer',
        '6 units Laptop (AMD Ryzen 7)',
        'Furniture & Fixture',
        'Fabrication of Office Cubicle',
        'Purchase of Diesel Silent Type Generator Set',
        '1 Unit Risographing Machine',
        '200 Pcs Monoblock Chairs',
      ];

      for (var oe in defaultSingles) {
        final docId = fsService.db
            .collection(AppConstants.colBudgetLines)
            .doc()
            .id;
        await fsService.updateBudgetLine(
          BudgetLine(
            id: docId,
            accountCode: '',
            fundSource: 'General Fund ${SystemConfig.targetBudgetYearStr}',
            objectOfExpenditure: oe,
            subCategory: '',
          ),
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default budget lines loaded successfully.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading defaults: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGlobalSummary(List<BudgetLine> lines) {
    final summary = BudgetValidationService.getConsolidatedSummary(lines);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Appropriation',
                  formatCurrency.format(summary['totalAppropriation']),
                  Colors.blue.shade700,
                  Icons.account_balance_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade100),
              Expanded(
                child: _buildSummaryItem(
                  'Total Obligated (PR)',
                  formatCurrency.format(summary['totalObligated']),
                  Colors.green.shade700,
                  Icons.assignment_turned_in_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade100),
              Expanded(
                child: _buildSummaryItem(
                  'Unobligated Balance',
                  formatCurrency.format(summary['unobligatedBalance']),
                  Colors.orange.shade800,
                  Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Disbursed (PO)',
                  formatCurrency.format(summary['totalDisbursed']),
                  Colors.indigo.shade700,
                  Icons.shopping_cart_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade100),
              Expanded(
                child: _buildSummaryItem(
                  'Utilization Rate',
                  '${summary['utilizationRate']?.toStringAsFixed(1)}%',
                  summary['utilizationRate']! > 90
                      ? Colors.red.shade700
                      : Colors.teal.shade700,
                  Icons.speed_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recalculating ledger balances...'),
                  ),
                );
                await context
                    .read<FirebaseService>()
                    .syncBudgetLinesWithActivities();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ledger balances synchronized.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.sync, size: 14),
              label: const Text(
                'RECALCULATE LEDGER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.blueGrey.shade400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FISCAL ARCHITECTURE 2026',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Strategic oversight of budgetary ceilings, multi-source funding, and dynamic balance tracking.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.blueGrey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search allocations, funds, or codes...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCMOSection(BuildContext context, BudgetLine cmoLine) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'CMO Operational Pool',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Central Management Office Consolidated Funds',
                    style: TextStyle(
                      color: Colors.blueGrey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCMOAdjustmentDialog(context, cmoLine),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('ADJUST ALLOCATION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              _buildMetric(
                'Office Control (P)',
                formatCurrency.format(cmoLine.proposedBudget),
                Colors.blueAccent,
                large: true,
              ),
              const SizedBox(width: 48),
              _buildMetric(
                'Annual Budget (A)',
                formatCurrency.format(cmoLine.approvedAmount),
                Colors.greenAccent,
                large: true,
              ),
              const SizedBox(width: 48),
              _buildMetric(
                'Balance',
                formatCurrency.format(cmoLine.currentBalance),
                Colors.white.withValues(alpha: 0.7),
                large: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegularBudgetSection(
    BuildContext context,
    List<BudgetLine> lines,
  ) {
    final fundGroups = <String, Map<String, List<BudgetLine>>>{};
    for (final line in lines) {
      final fundMap = fundGroups.putIfAbsent(line.fundSource, () => {});
      fundMap.putIfAbsent(line.objectOfExpenditure, () => []).add(line);
    }

    final sortedFundSources = fundGroups.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.list_alt, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Text(
              'Budgetary Ceilings (Layer A)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text(
              'No budget lines defined yet.',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          )
        else
          ...sortedFundSources.map((fundSource) {
            final expenditureGroups = fundGroups[fundSource]!;

            final sortedOeKeys = expenditureGroups.keys.toList()
              ..sort((a, b) {
                final indexA = AppConstants.objectsOfExpenditure.indexOf(a);
                final indexB = AppConstants.objectsOfExpenditure.indexOf(b);
                if (indexA == -1 && indexB == -1) return a.compareTo(b);
                if (indexA == -1) return 1;
                if (indexB == -1) return -1;
                return indexA.compareTo(indexB);
              });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    fundSource,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 600,
                    mainAxisExtent: 450,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: sortedOeKeys.length,
                  itemBuilder: (context, index) {
                    final oe = sortedOeKeys[index];
                    final groupLines = expenditureGroups[oe]!;
                    return _buildBudgetCard(context, groupLines);
                  },
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildBudgetCard(BuildContext context, List<BudgetLine> lines) {
    final firstLine = lines.first;
    final isAgriMooe = lines.any((l) => l.isAgriMooe);

    final totalProposed = lines.fold(0.0, (sum, l) => sum + l.proposedBudget);
    final totalLimit = lines.fold(0.0, (sum, l) => sum + l.budgetLimit);
    final totalAppropriation = lines.fold(
      0.0,
      (sum, l) => sum + l.appropriation,
    );
    final totalApproved = lines.fold(0.0, (sum, l) => sum + l.approvedAmount);
    final totalPRs = lines.fold(0.0, (sum, l) => sum + l.totalActualPRs);
    final totalBalance = lines.fold(0.0, (sum, l) => sum + l.currentBalance);

    final isLow = totalBalance < (totalApproved * 0.1);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (lines.length == 1) {
            _showBudgetDialog(context, lines.first);
          } else {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                final sortedLines = List<BudgetLine>.from(lines)
                  ..sort((a, b) {
                    final subList =
                        AppConstants.budgetSubCategories[firstLine
                            .objectOfExpenditure] ??
                        [];
                    final indexA = subList.indexOf(a.subCategory);
                    final indexB = subList.indexOf(b.subCategory);
                    if (indexA != -1 && indexB != -1)
                      return indexA.compareTo(indexB);
                    if (indexA != -1) return -1;
                    if (indexB != -1) return 1;
                    return a.subCategory.compareTo(b.subCategory);
                  });

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Text(
                          'Select Sub-Category to Edit',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: sortedLines
                                .map(
                                  (l) => ListTile(
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.blueGrey.shade50,
                                      child: Icon(
                                        Icons.edit_note,
                                        size: 20,
                                        color: Colors.blueGrey.shade700,
                                      ),
                                    ),
                                    title: Text(
                                      l.subCategory.isEmpty
                                          ? l.objectOfExpenditure
                                          : l.subCategory,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Balance: ${formatCurrency.format(l.currentBalance)}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showBudgetDialog(context, l);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isAgriMooe)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AGRI MOOE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        Text(
                          firstLine.objectOfExpenditure,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 12, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric(
                          'Office Control (P)',
                          formatCurrency.format(totalProposed),
                          Colors.blueGrey,
                          small: true,
                        ),
                        const SizedBox(height: 8),
                        _buildMetric(
                          'Limit',
                          formatCurrency.format(totalLimit),
                          Colors.red.shade700,
                          small: true,
                        ),
                        const SizedBox(height: 8),
                        _buildMetric(
                          'Appropriation',
                          formatCurrency.format(totalAppropriation),
                          Colors.indigo.shade400,
                          small: true,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 100,
                    color: Colors.grey.shade100,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric(
                          'Annual Budget (A)',
                          formatCurrency.format(totalApproved),
                          Colors.green.shade600,
                          small: true,
                        ),
                        const SizedBox(height: 8),
                        _buildMetric(
                          'Actual PRs',
                          formatCurrency.format(totalPRs),
                          Colors.orange.shade700,
                          small: true,
                        ),
                        const SizedBox(height: 8),
                        _buildMetric(
                          'Balance',
                          formatCurrency.format(totalBalance),
                          isLow ? Colors.red : Colors.blue.shade700,
                          small: true,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (lines.any((l) => l.subCategory.isNotEmpty)) ...[
                const SizedBox(height: 16),
                Text(
                  'SUB-CATEGORIES',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 0.5,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  child: Builder(
                    builder: (context) {
                      final sortedLines = List<BudgetLine>.from(lines)
                        ..sort((a, b) {
                          final subList =
                              AppConstants.budgetSubCategories[firstLine
                                  .objectOfExpenditure] ??
                              [];
                          final indexA = subList.indexOf(a.subCategory);
                          final indexB = subList.indexOf(b.subCategory);
                          if (indexA != -1 && indexB != -1)
                            return indexA.compareTo(indexB);
                          if (indexA != -1) return -1;
                          if (indexB != -1) return 1;
                          return a.subCategory.compareTo(b.subCategory);
                        });
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedLines.length,
                        itemBuilder: (context, idx) {
                          final l = sortedLines[idx];
                          if (l.subCategory.isEmpty)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    l.subCategory,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'Proposed: ${formatCurrency.format(l.proposedBudget)}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Annual: ${formatCurrency.format(l.approvedAmount)}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: l.approvedAmount > 0
                                        ? Colors.green.shade800
                                        : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isLow
                      ? Colors.red.withValues(alpha: 0.05)
                      : Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLow
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL BALANCE',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      formatCurrency.format(totalBalance),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: isLow ? Colors.red : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
    String label,
    String value,
    Color color, {
    bool small = false,
    bool large = false,
    bool isBold = false,
  }) {
    double labelSize = small ? 10 : (large ? 14 : 12);
    double valueSize = small ? 14 : (large ? 32 : 24);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: color.withValues(alpha: 0.7),
            fontSize: labelSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: valueSize,
            fontWeight: isBold || large ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    _showBudgetDialog(context, null);
  }

  void _showBudgetDialog(BuildContext context, BudgetLine? line) {
    final isEditing = line != null;
    final fundSourceCtl = TextEditingController(
      text:
          line?.fundSource ??
          'General Fund ${SystemConfig.targetBudgetYearStr}',
    );
    String? selectedOE = line?.objectOfExpenditure;
    bool isAgriMooe = line?.isAgriMooe ?? false;

    final List<_BudgetSubRow> subRows = [];
    if (isEditing) {
      subRows.add(
        _BudgetSubRow(
          id: line.id,
          subCategory: line.subCategory,
          accountCode: line.accountCode,
          proposedBudget: line.proposedBudget,
          annualBudget: line.approvedAmount,
        ),
      );
    } else {
      subRows.add(
        _BudgetSubRow(id: 'row_${DateTime.now().millisecondsSinceEpoch}'),
      );
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final subOptions = AppConstants.budgetSubCategories[selectedOE] ?? [];

          return Dialog(
            backgroundColor: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: 950,
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Icon(
                            isEditing
                                ? Icons.edit_note_rounded
                                : Icons.add_chart_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (isEditing
                                        ? 'REVISE FISCAL ALLOCATION'
                                        : 'NEW BUDGETARY CEILING')
                                    .toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'STRATEGIC FINANCIAL PLANNING — FISCAL YEAR ${SystemConfig.targetBudgetYearStr}',
                                style: GoogleFonts.inter(
                                  color: Colors.blueGrey.shade300,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FUNDING SOURCE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blueGrey.shade400,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: fundSourceCtl,
                                decoration: InputDecoration(
                                  hintText: 'e.g., General Fund 2026',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CLASSIFICATION',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.blueGrey.shade400,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildToggleOption(
                                  label: 'GENERAL',
                                  isSelected: !isAgriMooe,
                                  onTap: () =>
                                      setState(() => isAgriMooe = false),
                                  activeColor: const Color(0xFF334155),
                                ),
                                _buildToggleOption(
                                  label: 'AGRI MOOE',
                                  isSelected: isAgriMooe,
                                  onTap: () =>
                                      setState(() => isAgriMooe = true),
                                  activeColor: const Color(0xFF1B5E20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OBJECT OF EXPENDITURE',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) =>
                                DropdownMenu<String>(
                                  initialSelection: selectedOE,
                                  width: constraints.maxWidth,
                                  hintText:
                                      'Search or select expenditure category...',
                                  enableSearch: true,
                                  enableFilter: true,
                                  menuStyle: MenuStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                      Colors.white,
                                    ),
                                    elevation: WidgetStateProperty.all(10),
                                    shape: WidgetStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  inputDecorationTheme: InputDecorationTheme(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.blueGrey.shade100,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.blueGrey.shade100,
                                      ),
                                    ),
                                  ),
                                  dropdownMenuEntries: AppConstants
                                      .objectsOfExpenditure
                                      .map(
                                        (oe) => DropdownMenuEntry(
                                          value: oe,
                                          label: oe,
                                        ),
                                      )
                                      .toList(),
                                  onSelected: (val) {
                                    setState(() {
                                      selectedOE = val;
                                    });
                                  },
                                ),
                          ),
                          const SizedBox(height: 32),
                          Divider(color: Colors.grey.shade200),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SUB-CATEGORIES / PROGRAMS',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: 1,
                                ),
                              ),
                              if (!isEditing)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      subRows.add(
                                        _BudgetSubRow(
                                          id: 'row_${DateTime.now().millisecondsSinceEpoch}',
                                        ),
                                      );
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Add Row'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF1B5E20),
                                    textStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFF334155),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _tableHeader(
                                    'ITEM NAME / SUB-CATEGORY',
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _tableHeader('ACCOUNT CODE'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _tableHeader('PROPOSED (OFFICE)'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _tableHeader('ANNUAL BUDGET'),
                                ),
                                if (!isEditing) const SizedBox(width: 48),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: subRows.asMap().entries.map((entry) {
                                final index = entry.key;
                                final row = entry.value;
                                final isLast = index == subRows.length - 1;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: isLast
                                        ? null
                                        : Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade100,
                                            ),
                                          ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: subOptions.isEmpty
                                            ? _tableTextField(
                                                row.subCategoryCtl,
                                                'e.g. Office Supplies',
                                              )
                                            : LayoutBuilder(
                                                builder:
                                                    (
                                                      context,
                                                      constraints,
                                                    ) => DropdownMenu<String>(
                                                      initialSelection:
                                                          row
                                                              .subCategoryCtl
                                                              .text
                                                              .isEmpty
                                                          ? null
                                                          : row
                                                                .subCategoryCtl
                                                                .text,
                                                      width:
                                                          constraints.maxWidth,
                                                      enableSearch: true,
                                                      inputDecorationTheme:
                                                          const InputDecorationTheme(
                                                            border: InputBorder
                                                                .none,
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                          ),
                                                      dropdownMenuEntries:
                                                          subOptions
                                                              .map(
                                                                (s) =>
                                                                    DropdownMenuEntry(
                                                                      value: s,
                                                                      label: s,
                                                                    ),
                                                              )
                                                              .toList(),
                                                      onSelected: (val) =>
                                                          row
                                                                  .subCategoryCtl
                                                                  .text =
                                                              val ?? '',
                                                    ),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: _tableTextField(
                                          row.accountCodeCtl,
                                          'Code',
                                          mono: true,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: _tableAmountField(
                                          row.proposedCtl,
                                          '0.00',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: _tableAmountField(
                                          row.annualCtl,
                                          '0.00',
                                        ),
                                      ),
                                      if (!isEditing)
                                        IconButton(
                                          onPressed: subRows.length > 1
                                              ? () => setState(
                                                  () => subRows.removeAt(index),
                                                )
                                              : null,
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Remove row',
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                          ),
                          child: Text(
                            'Discard Changes',
                            style: GoogleFonts.inter(
                              color: Colors.blueGrey.shade400,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (selectedOE == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select an Object of Expenditure.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final fsService = context.read<FirebaseService>();

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              for (var row in subRows) {
                                final proposedVal =
                                    CurrencyInputFormatter.parse(
                                      row.proposedCtl.text,
                                    );
                                final annualVal = CurrencyInputFormatter.parse(
                                  row.annualCtl.text,
                                );

                                final budgetLine = BudgetLine(
                                  id: isEditing
                                      ? row.id
                                      : fsService.db
                                            .collection(
                                              AppConstants.colBudgetLines,
                                            )
                                            .doc()
                                            .id,
                                  accountCode: row.accountCodeCtl.text,
                                  fundSource: fundSourceCtl.text,
                                  objectOfExpenditure: selectedOE!,
                                  subCategory: row.subCategoryCtl.text,
                                  proposedBudget: proposedVal,
                                  approvedAmount: annualVal,
                                  currentBalance: isEditing
                                      ? (line!.currentBalance +
                                            (annualVal - line.approvedAmount))
                                      : annualVal,
                                  isAgriMooe: isAgriMooe,
                                  isCMO:
                                      selectedOE!.contains('CMO') ||
                                      selectedOE!.contains('Consolidated'),
                                );

                                await fsService.updateBudgetLine(budgetLine);
                              }

                              if (context.mounted) {
                                for (var r in subRows) {
                                  r.dispose();
                                }
                                fundSourceCtl.dispose();

                                Navigator.pop(context);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Budget allocation saved successfully.',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(
                            isEditing
                                ? Icons.save_rounded
                                : Icons.check_circle_rounded,
                            size: 20,
                          ),
                          label: Text(
                            isEditing
                                ? 'Commit Changes'
                                : 'Initialize Allocation',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tableHeader(String label) => Text(
    label,
    style: GoogleFonts.inter(
      fontSize: 9,
      fontWeight: FontWeight.w900,
      color: Colors.white.withValues(alpha: 0.8),
      letterSpacing: 0.5,
    ),
  );

  Widget _tableTextField(
    TextEditingController controller,
    String hint, {
    bool mono = false,
  }) => TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      border: InputBorder.none,
      isDense: true,
    ),
    style: mono
        ? GoogleFonts.robotoMono(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          )
        : GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
  );

  Widget _tableAmountField(TextEditingController controller, String hint) =>
      TextField(
        controller: controller,
        textAlign: TextAlign.right,
        inputFormatters: [CurrencyInputFormatter()],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          isDense: true,
        ),
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1B5E20),
        ),
      );

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey.shade100,
          borderRadius: label == 'GENERAL'
              ? const BorderRadius.horizontal(left: Radius.circular(8))
              : const BorderRadius.horizontal(right: Radius.circular(8)),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.white : Colors.blueGrey.shade600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  void _showCMOAdjustmentDialog(BuildContext context, BudgetLine line) {
    final amountCtl = TextEditingController();
    final remarksCtl = TextEditingController();
    bool isAdd = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(Icons.swap_vert, color: Colors.blue.shade800),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'CMO Budget Adjustment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current Balance: ${formatCurrency.format(line.currentBalance)}',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Adjustment Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 4),
                            Text('Addition'),
                          ],
                        ),
                        selected: isAdd,
                        onSelected: (v) => setState(() => isAdd = true),
                        selectedColor: Colors.green.shade50,
                        labelStyle: TextStyle(
                          color: isAdd ? Colors.green.shade800 : Colors.grey,
                        ),
                        side: BorderSide(
                          color: isAdd ? Colors.green : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove, size: 16),
                            SizedBox(width: 4),
                            Text('Subtraction'),
                          ],
                        ),
                        selected: !isAdd,
                        onSelected: (v) => setState(() => isAdd = false),
                        selectedColor: Colors.red.shade50,
                        labelStyle: TextStyle(
                          color: !isAdd ? Colors.red.shade800 : Colors.grey,
                        ),
                        side: BorderSide(
                          color: !isAdd ? Colors.red : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Adjustment Amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtl,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [CurrencyInputFormatter()],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Reason / Remarks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: remarksCtl,
                  decoration: InputDecoration(
                    hintText: 'Provide justification for this adjustment',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final amount = CurrencyInputFormatter.parse(
                          amountCtl.text,
                        );
                        if (amount == 0) return;
                        final adjustment = isAdd ? amount : -amount;
                        context.read<FirebaseService>().adjustCMOBudget(
                          adjustment,
                          remarksCtl.text,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Apply Adjustment'),
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

  void _showSyncMenu(BuildContext context, List<BudgetLine> lines) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy as Spreadsheet (TSV)'),
            onTap: () {
              Navigator.pop(context);
              _exportToClipboard(lines);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _exportToClipboard(List<BudgetLine> lines) async {
    String output =
        "Account Code\tObject of Expenditure\tSub-Category\tFund Source\tProposed Budget\tAnnual Budget\n";
    for (var line in lines) {
      output +=
          "${line.accountCode}\t${line.objectOfExpenditure}\t${line.subCategory}\t${line.fundSource}\t${line.proposedBudget}\t${line.approvedAmount}\n";
    }
    await Clipboard.setData(ClipboardData(text: output));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Budget data copied to clipboard in spreadsheet format.',
          ),
        ),
      );
    }
  }
}

class _BudgetSubRow {
  final String id;
  final TextEditingController subCategoryCtl = TextEditingController();
  final TextEditingController accountCodeCtl = TextEditingController();
  final TextEditingController proposedCtl = TextEditingController();
  final TextEditingController annualCtl = TextEditingController();

  _BudgetSubRow({
    String? id,
    String subCategory = '',
    String accountCode = '',
    double proposedBudget = 0,
    double annualBudget = 0,
  }) : id = id ?? 'row_${DateTime.now().microsecondsSinceEpoch}' {
    subCategoryCtl.text = subCategory;
    accountCodeCtl.text = accountCode;
    proposedCtl.text = proposedBudget.toString();
    annualCtl.text = annualBudget.toString();
  }

  void dispose() {
    subCategoryCtl.dispose();
    accountCodeCtl.dispose();
    proposedCtl.dispose();
    annualCtl.dispose();
  }
}
