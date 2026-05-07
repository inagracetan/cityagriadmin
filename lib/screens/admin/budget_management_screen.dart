import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../models/budget_line.dart';
import 'package:intl/intl.dart';
import '../../widgets/grid_form_fields.dart';
import '../../core/currency_formatter.dart';
import '../../core/constants.dart';
import '../../widgets/skeleton_loading.dart';
import '../../services/navigation_provider.dart';





class BudgetManagementScreen extends StatefulWidget {
  final bool isActive;
  const BudgetManagementScreen({super.key, this.isActive = true});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');

  Stream<List<BudgetLine>>? _budgetLinesStream;

  @override
  void initState() {
    super.initState();
    _budgetLinesStream = context.read<FirebaseService>().streamBudgetLines();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final navProvider = context.read<NavigationProvider>();
    
    // Update the FAB in the parent scaffold via NavigationProvider
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navProvider.updateLayout(
          fab: FloatingActionButton.extended(
            onPressed: () => _showAddBudgetDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Budget Line'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            tooltip: 'Create a new budgetary ceiling for an object of expenditure.',
          ),
        );
      });
    }

    return Container(
      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : const Color(0xFFF8FAFC),
      child: StreamBuilder<List<BudgetLine>>(
        stream: _budgetLinesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const SkeletonDashboard();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final budgetLines = snapshot.data ?? [];
          final cmoLines = budgetLines.where((l) => l.isCMO).toList();
          final regularLines = budgetLines.where((l) => !l.isCMO).toList();

          if (budgetLines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No budget data available for ${SystemConfig.nextFiscalYearStr}.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  if (cmoLines.isNotEmpty) ...[
                    _buildCMOSection(context, cmoLines.first),
                    const SizedBox(height: 32),
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Architecture',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage budgetary ceilings, fund sources, and real-time balances.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildCMOSection(BuildContext context, BudgetLine cmoLine) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'CMO Budget Module',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Tooltip(
                message: 'Add or subtract funds from the CMO budget pool.',
                child: ElevatedButton.icon(
                  onPressed: () => _showCMOAdjustmentDialog(context, cmoLine),
                  icon: const Icon(Icons.swap_vert, size: 20),
                  label: const Text('Adjust Funds'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMetric(
                'Current Balance',
                formatCurrency.format(cmoLine.currentBalance),
                Colors.white,
              ),
              const SizedBox(width: 48),
              _buildMetric(
                'Total Approved',
                formatCurrency.format(cmoLine.approvedAmount),
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegularBudgetSection(BuildContext context, List<BudgetLine> lines) {
    // Group lines by fund source
    final grouped = <String, List<BudgetLine>>{};
    for (final line in lines) {
      grouped.putIfAbsent(line.fundSource, () => []).add(line);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.list_alt, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Text(
              'Budgetary Ceilings (Layer A)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (lines.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Text(
                'No budget lines defined yet.',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          )
        else
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    entry.key,
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
                    mainAxisExtent: 280, // Increased height for more data
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final line = entry.value[index];
                    return _buildBudgetCard(context, line);
                  },
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildBudgetCard(BuildContext context, BudgetLine line) {
    final isLow = line.currentBalance < (line.approvedAmount * 0.1);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (line.isAgriMooe)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Agri MOOE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    Text(
                      line.objectOfExpenditure,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Edit this budget line configuration.',
                  onPressed: () => _showEditBudgetDialog(context, line),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetric('Proposed Budget', formatCurrency.format(line.proposedBudget), Colors.blueGrey, small: true),
                        _buildMetric('Budget Limit', formatCurrency.format(line.budgetLimit), Colors.red.shade900, small: true),
                        _buildMetric('Appropriation', formatCurrency.format(line.appropriation), Colors.indigo, small: true),
                      ],
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetric('Approved Budget', formatCurrency.format(line.approvedAmount), Colors.green, small: true),
                        _buildMetric('PPMP Amount', formatCurrency.format(line.ppmpAmount), Colors.orange, small: true),
                        Row(
                          children: [
                            Expanded(child: _buildMetric('PR Amount', formatCurrency.format(line.prAmount), Colors.teal, small: true)),
                            Expanded(child: _buildMetric('PO Amount', formatCurrency.format(line.poAmount), Colors.deepPurple, small: true)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLow ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Balance:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  Text(
                    formatCurrency.format(line.currentBalance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isLow ? Colors.red : Colors.green.shade700,
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


  Widget _buildMetric(String label, String value, Color color, {bool small = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: small ? 10 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: small ? 14 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    _showBudgetDialog(context, null);
  }

  void _showEditBudgetDialog(BuildContext context, BudgetLine line) {
    _showBudgetDialog(context, line);
  }

  void _showBudgetDialog(BuildContext context, BudgetLine? line) {
    final isEditing = line != null;
    final accountCodeCtl = TextEditingController(text: line?.accountCode ?? '');
    final fundSourceCtl = TextEditingController(text: line?.fundSource ?? '');
    final objectOfExpenditureCtl = TextEditingController(text: line?.objectOfExpenditure ?? '');
    final proposedBudgetCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.proposedBudget) : '');
    final proposedExpenditureCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.proposedExpenditure) : '');
    final approvedAmountCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.approvedAmount) : '');
    final appropriationCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.appropriation) : '');
    final ppmpAmountCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.ppmpAmount) : '');
    final prAmountCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.prAmount) : '');
    final poAmountCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.poAmount) : '');
    final budgetLimitCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.budgetLimit) : '');
    final q1PpmpCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.q1Ppmp) : '');
    final q2PpmpCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.q2Ppmp) : '');
    final q3PpmpCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.q3Ppmp) : '');
    final q4PpmpCtl = TextEditingController(
        text: line != null ? CurrencyInputFormatter.formatDouble(line.q4Ppmp) : '');
    bool isAgriMooe = line?.isAgriMooe ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 800,
            constraints: const BoxConstraints(maxHeight: 900),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(isEditing ? Icons.edit_note : Icons.add_chart,
                          color: Theme.of(context).colorScheme.primary, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Budget Line' : 'Create Budget Line',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'Update parameters for account ${line.accountCode}'
                                : 'Define a new budgetary ceiling for a specific object of expenditure',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Basic Configuration Section
                        const GridSectionHeader(label: 'A', title: 'Account Identification'),
                        GridRow(
                          label: 'A1',
                          fieldLabel: 'Is Agri MOOE?',
                          isOdd: true,
                          child: Tooltip(
                            message: 'Toggle if this budget item is part of the Agricultural Maintenance and Other Operating Expenses.',
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Categorize under Agri MOOE', style: TextStyle(fontSize: 14)),
                              value: isAgriMooe,
                              onChanged: (v) => setState(() => isAgriMooe = v),
                              activeThumbColor: Colors.green,
                              activeTrackColor: Colors.green.withOpacity(0.5),
                            ),
                          ),
                        ),
                        GridRow(
                          label: 'A2',
                          fieldLabel: 'Account Code',
                          isOdd: false,
                          child: GridAccountCodePicker(
                            controller: accountCodeCtl,
                            hint: 'Search account code...',
                            tooltip: 'The official accounting code for this expenditure item.',
                          ),
                        ),
                        GridRow(
                          label: 'A3',
                          fieldLabel: 'Fund Source',
                          isOdd: true,
                          child: GridAutocompleteField(
                            controller: fundSourceCtl,
                            options: AppConstants.fundingSources,
                            hint: 'e.g. General Fund ${SystemConfig.nextFiscalYearStr}',
                            tooltip: 'The specific fund source (e.g., General Fund, Special Project).',
                          ),
                        ),
                        GridRow(
                          label: 'A4',
                          fieldLabel: 'Object of Exp.',
                          isOdd: false,
                          child: GridAutocompleteField(
                            controller: objectOfExpenditureCtl,
                            options: AppConstants.objectsOfExpenditure,
                            hint: 'Description of the expenditure item',
                            tooltip: 'The descriptive name of what is being funded (e.g., Office Supplies).',
                          ),
                        ),


                        const SizedBox(height: 32),

                        // Financial Benchmarks Section
                        const GridSectionHeader(label: 'B', title: 'Financial Benchmarks'),
                        GridRow(
                          label: 'B1',
                          fieldLabel: 'Proposed Budget',
                          isOdd: true,
                          child: GridCurrencyField(
                            controller: proposedBudgetCtl,
                            tooltip: 'The initial budget amount proposed for this item.',
                          ),
                        ),
                        GridRow(
                          label: 'B2',
                          fieldLabel: 'Proposed Exp.',
                          isOdd: false,
                          child: GridCurrencyField(
                            controller: proposedExpenditureCtl,
                            tooltip: 'The projected total expenditure based on current plans.',
                          ),
                        ),
                        GridRow(
                          label: 'B3',
                          fieldLabel: 'Appropriation',
                          isOdd: true,
                          child: GridCurrencyField(
                            controller: appropriationCtl,
                            tooltip: 'The official appropriated amount set by legislation or board.',
                          ),
                        ),
                        GridRow(
                          label: 'B4',
                          fieldLabel: 'Approved Budget',
                          isOdd: false,
                          child: GridCurrencyField(
                            controller: approvedAmountCtl,
                            tooltip: 'The final approved budget amount available for use.',
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Procurement Status Section
                        const GridSectionHeader(label: 'C', title: 'Procurement Tracking'),
                        GridRow(
                          label: 'C1',
                          fieldLabel: 'PPMP Amount',
                          isOdd: true,
                          child: GridCurrencyField(
                            controller: ppmpAmountCtl,
                            tooltip: 'Total amount allocated in the Project Procurement Management Plan.',
                          ),
                        ),
                        GridRow(
                          label: 'C2',
                          fieldLabel: 'PR Amount',
                          isOdd: false,
                          child: GridCurrencyField(
                            controller: prAmountCtl,
                            tooltip: 'Total amount tied to issued Purchase Requests.',
                          ),
                        ),
                        GridRow(
                          label: 'C3',
                          fieldLabel: 'PO Amount',
                          isOdd: true,
                          child: GridCurrencyField(
                            controller: poAmountCtl,
                            tooltip: 'Total amount committed in Purchase Orders.',
                          ),
                        ),

                        const SizedBox(height: 32),

                        // System Controls
                        const GridSectionHeader(label: 'D', title: 'System Controls & Targets'),
                        GridRow(
                          label: 'D1',
                          fieldLabel: 'Hard Budget Ceiling',
                          isOdd: true,
                          child: GridCurrencyField(
                            controller: budgetLimitCtl,
                            hint: '${SystemConfig.nextFiscalYearStr} Hard Limit',
                            tooltip: 'The strict maximum ceiling that cannot be exceeded.',
                          ),
                        ),
                        GridRow(
                          label: 'D2',
                          fieldLabel: 'Q1 Target',
                          isOdd: false,
                          child: GridCurrencyField(
                            controller: q1PpmpCtl,
                            tooltip: 'Procurement target for the first quarter.',
                          ),
                        ),
                        GridRow(
                          label: 'D3',
                          fieldLabel: 'Q2 Target',
                          isOdd: true,
                          child: GridCurrencyField(
                            controller: q2PpmpCtl,
                            tooltip: 'Procurement target for the second quarter.',
                          ),
                        ),
                        GridRow(
                          label: 'D4',
                          fieldLabel: 'Q3 Target',
                          isOdd: false,
                          child: GridCurrencyField(
                            controller: q3PpmpCtl,
                            tooltip: 'Procurement target for the third quarter.',
                          ),
                        ),
                        GridRow(
                          label: 'D5',
                          fieldLabel: 'Q4 Target',
                          isOdd: true,
                          child: GridCurrencyField(
                            controller: q4PpmpCtl,
                            tooltip: 'Procurement target for the fourth quarter.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: Text('Discard Changes', style: TextStyle(color: Colors.grey.shade600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final fbService = context.read<FirebaseService>();
                          final newLine = BudgetLine(
                            id: line?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            accountCode: accountCodeCtl.text,
                            fundSource: fundSourceCtl.text,
                            objectOfExpenditure: objectOfExpenditureCtl.text,
                            proposedBudget: CurrencyInputFormatter.parse(proposedBudgetCtl.text),
                            proposedExpenditure: CurrencyInputFormatter.parse(proposedExpenditureCtl.text),
                            approvedAmount: CurrencyInputFormatter.parse(approvedAmountCtl.text),
                            appropriation: CurrencyInputFormatter.parse(appropriationCtl.text),
                            ppmpAmount: CurrencyInputFormatter.parse(ppmpAmountCtl.text),
                            prAmount: CurrencyInputFormatter.parse(prAmountCtl.text),
                            poAmount: CurrencyInputFormatter.parse(poAmountCtl.text),
                            budgetLimit: CurrencyInputFormatter.parse(budgetLimitCtl.text),
                            q1Ppmp: CurrencyInputFormatter.parse(q1PpmpCtl.text),
                            q2Ppmp: CurrencyInputFormatter.parse(q2PpmpCtl.text),
                            q3Ppmp: CurrencyInputFormatter.parse(q3PpmpCtl.text),
                            q4Ppmp: CurrencyInputFormatter.parse(q4PpmpCtl.text),
                            currentBalance: isEditing
                                ? line.currentBalance
                                : CurrencyInputFormatter.parse(approvedAmountCtl.text),
                            isAgriMooe: isAgriMooe,
                          );
                          fbService.updateBudgetLine(newLine);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isEditing ? 'Update Line' : 'Create Line'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current Balance: ${formatCurrency.format(line.currentBalance)}',
                          style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Adjustment Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.add, size: 16), SizedBox(width: 4), Text('Addition')],
                        ),
                        selected: isAdd,
                        onSelected: (v) => setState(() => isAdd = true),
                        selectedColor: Colors.green.shade50,
                        labelStyle: TextStyle(color: isAdd ? Colors.green.shade800 : Colors.grey),
                        side: BorderSide(color: isAdd ? Colors.green : Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.remove, size: 16), SizedBox(width: 4), Text('Subtraction')],
                        ),
                        selected: !isAdd,
                        onSelected: (v) => setState(() => isAdd = false),
                        selectedColor: Colors.red.shade50,
                        labelStyle: TextStyle(color: !isAdd ? Colors.red.shade800 : Colors.grey),
                        side: BorderSide(color: !isAdd ? Colors.red : Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Adjustment Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                GridCurrencyField(
                  controller: amountCtl,
                  hint: '0.00',
                  tooltip: 'The monetary value to be added to or subtracted from the balance.',
                ),
                const SizedBox(height: 24),
                const Text('Reason / Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                GridTextField(
                  controller: remarksCtl,
                  hint: 'Provide justification for this adjustment',
                  tooltip: 'Mandatory explanation for why this budget adjustment is necessary.',
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final amount = CurrencyInputFormatter.parse(amountCtl.text);
                        if (amount == 0) return;
                        final adjustment = isAdd ? amount : -amount;
                        context.read<FirebaseService>().adjustCMOBudget(adjustment, remarksCtl.text);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Tooltip(
                        message: 'Commit the adjustment and update the real-time balance.',
                        child: Text('Apply Adjustment'),
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
}

