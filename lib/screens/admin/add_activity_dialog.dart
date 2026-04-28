import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barcode_widget/barcode_widget.dart';

import '../../core/constants.dart';
import '../../core/currency_formatter.dart';
import '../../core/date_formatter.dart';
import '../../core/responsive_utils.dart';
import '../../models/activity.dart';
import '../../models/pr_log.dart';
import '../../services/activity_form_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';

// ── Modern design constants ─────────────────────────────────────────────
const modernGreen = Color(0xFF1B5E20);
const modernDark = Color(0xFF064E3B);
const headerBg = Color(0xFFF1F8E9);
const rowOdd = Color(0xFFFFFFFF);
const rowEven = Color(0xFFF9FBF7);
const border = Color(0xFFE2E8F0); // Softer border
const textMain = Color(0xFF1E293B);
const labelBg = Color(0xFFF8FAFC);
const labelText = Color(0xFF475569);

// ── Breakdown entry helper ────────────────────────────────────────────────────
class BreakdownEntry {
  final TextEditingController nameCtl;
  final TextEditingController amountCtl;
  final TextEditingController supplierCtl;
  final TextEditingController statusCtl;

  BreakdownEntry({
    required String name,
    double amount = 0.0,
    String? supplier,
    String? status,
  }) : nameCtl = TextEditingController(text: name),
       amountCtl = TextEditingController(
         text: amount > 0 ? CurrencyInputFormatter.formatDouble(amount) : '',
       ),
       supplierCtl = TextEditingController(text: supplier ?? ''),
       statusCtl = TextEditingController(text: status ?? '');

  void dispose() {
    nameCtl.dispose();
    amountCtl.dispose();
    supplierCtl.dispose();
    statusCtl.dispose();
  }
}

class FundSourceEntry {
  String fundingSource = 'Agri MOOE';
  String? objectOfExpenditure = 'Other-MOE Expenses';
  final TextEditingController amountCtl;
  final TextEditingController customFundingSourceCtl;
  final TextEditingController customObjectOfExpenditureCtl;
  final List<BreakdownEntry> breakdownItems = [];

  FundSourceEntry({
    String amount = '',
    String? initialSource,
    String? initialOE,
  }) : fundingSource = initialSource ?? 'Agri MOOE',
       objectOfExpenditure = initialOE ?? 'Other-MOE Expenses',
       amountCtl = TextEditingController(text: amount),
       customFundingSourceCtl = TextEditingController(),
       customObjectOfExpenditureCtl = TextEditingController();

  void dispose() {
    amountCtl.dispose();
    customFundingSourceCtl.dispose();
    customObjectOfExpenditureCtl.dispose();
    for (var e in breakdownItems) {
      e.dispose();
    }
  }
}

// =============================================================================
// AddActivityDialog
// =============================================================================
class AddActivityDialog extends StatefulWidget {
  final FirebaseService fbService;
  final List<String>? initialResponsiblePersons;
  const AddActivityDialog({
    super.key,
    required this.fbService,
    this.initialResponsiblePersons,
  });

  @override
  State<AddActivityDialog> createState() => AddActivityDialogState();
}

class AddActivityDialogState extends State<AddActivityDialog> {
  final formKey = GlobalKey<FormState>();

  String sector = AppConstants.sectors.first;
  String? subSector;
  final activityNameCtl = TextEditingController();
  final unitHeadCtl = TextEditingController();
  final performanceIndicatorCtl = TextEditingController();
  final locationCtl = TextEditingController();
  final targetNoCtl = TextEditingController();
  final budgetCtl = TextEditingController();
  final ppmpAmountCtl = TextEditingController();
  final ppmpCtl = TextEditingController();

  final prAmountCtl = TextEditingController();
  final prBalanceCtl = TextEditingController();
  final prNumberCtl = TextEditingController();
  final supplierAppropCtl = TextEditingController();
  final barcodeAppropCtl = TextEditingController();
  final statusAppropCtl = TextEditingController();
  final targetParticipantsCtl = TextEditingController();
  final remarksCtl = TextEditingController();
  final customSectorCtl = TextEditingController();
  final customSubSectorCtl = TextEditingController();
  final customResponsiblePersonCtl = TextEditingController();
  final customStatusCtl = TextEditingController();
  final customStatusDateCtl = TextEditingController();
  final otherMoeSuppliersCtl = TextEditingController();
  final statusAppropDateCtl = TextEditingController();

  String selectedStatus = AppConstants.activityStatuses.first;
  String selectedMonth = AppConstants.months[DateTime.now().month - 1];
  String? selectedToMonth;
  String selectedYear = DateTime.now().year.toString();
  String responsiblePerson = '';

  List<String> availableStaff = AppConstants.staffList;
  List<String> availableSuppliers = [];
  bool saving = false;
  final bool canPop = false;
  final List<FundSourceEntry> fundSourceEntries = [];

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final List<String> years = AppConstants.years;

  int rowIndex = 0;
  Color get nextRowColor {
    final c = rowIndex.isOdd ? rowEven : rowOdd;
    rowIndex++;
    return c;
  }

  @override
  void initState() {
    super.initState();
    final formProvider = Provider.of<ActivityFormProvider>(context, listen: false);
    
    // Initialize from persistent provider state
    sector = formProvider.sector;
    subSector = formProvider.subSector;
    selectedStatus = formProvider.selectedStatus;
    selectedMonth = formProvider.selectedMonth;
    selectedToMonth = formProvider.selectedToMonth;
    selectedYear = formProvider.selectedYear;
    responsiblePerson = formProvider.responsiblePerson;
    supplierAppropCtl.text = formProvider.supplierAppropCtl.text;
    statusAppropCtl.text = formProvider.statusAppropCtl.text;

    if (widget.initialResponsiblePersons != null &&
        widget.initialResponsiblePersons!.isNotEmpty) {
      responsiblePerson = widget.initialResponsiblePersons!.first;
    }
    
    fundSourceEntries.add(FundSourceEntry(
      initialSource: formProvider.lastFundingSource,
      initialOE: formProvider.lastObjectOfExpenditure,
    ));

    // PR Balance = Approved Budget - PR Amount
    prAmountCtl.addListener(updatePRBalance);
    // PPMP Balance = PPMP Amount - Approved Budget
    ppmpAmountCtl.addListener(updatePPMPBalance);

    // Only fund sources are linked to Approved Budget (not PO/breakdown items)
    for (var entry in fundSourceEntries) {
      entry.amountCtl.addListener(updateTotalBudget);
      entry.customFundingSourceCtl.addListener(() => setState(() {}));
      entry.customObjectOfExpenditureCtl.addListener(() => setState(() {}));
    }

    loadData();
  }

  // PPMP Balance = PPMP Amount - Approved Budget
  void updatePPMPBalance() {
    final ppmpAmount = CurrencyInputFormatter.parse(ppmpAmountCtl.text);
    final budget = CurrencyInputFormatter.parse(budgetCtl.text);
    final balance = ppmpAmount - budget;
    final newText = CurrencyInputFormatter.formatDouble(balance);
    if (ppmpCtl.text != newText) {
      setState(() => ppmpCtl.text = newText);
    }
  }

  // PR Balance = Approved Budget - PR Amount
  void updatePRBalance() {
    final budget = CurrencyInputFormatter.parse(budgetCtl.text);
    final prAmount = CurrencyInputFormatter.parse(prAmountCtl.text);
    final balance = budget - prAmount;
    setState(() {
      prBalanceCtl.text = CurrencyInputFormatter.formatDouble(balance);
    });
  }


  void updateTotalBudget() {
    double grandTotal = 0;
    for (var entry in fundSourceEntries) {
      if (entry.breakdownItems.isNotEmpty) {
        double entryTotal = 0;
        for (var b in entry.breakdownItems) {
          entryTotal += CurrencyInputFormatter.parse(b.amountCtl.text);
        }
        final formattedEntryTotal =
            CurrencyInputFormatter.formatDouble(entryTotal);
        if (entry.amountCtl.text != formattedEntryTotal) {
          entry.amountCtl.text = formattedEntryTotal;
        }
        grandTotal += entryTotal;
      } else {
        grandTotal += CurrencyInputFormatter.parse(entry.amountCtl.text);
      }
    }

    final formattedTotal = CurrencyInputFormatter.formatDouble(grandTotal);
    if (budgetCtl.text != formattedTotal) {
      setState(() {
        budgetCtl.text = formattedTotal;
      });
    }
    // We no longer automatically force PPMP Amount to match Approved Budget.
    // This allows users to track PPMP allocation vs actual approved budget.
    updatePPMPBalance();
    updatePRBalance();
  }

  int calculateQuartersInRange() {
    final quarters = <int>{};
    int getQ(String m) {
      if (['January', 'February', 'March'].contains(m)) return 1;
      if (['April', 'May', 'June'].contains(m)) return 2;
      if (['July', 'August', 'September'].contains(m)) return 3;
      if (['October', 'November', 'December'].contains(m)) return 4;
      return 1;
    }
    
    quarters.add(getQ(selectedMonth));
    if (selectedToMonth != null) {
      int qF = getQ(selectedMonth);
      int qT = getQ(selectedToMonth!);
      for (int i = qF; i <= qT; i++) {
        quarters.add(i);
      }
    }
    return quarters.length.clamp(1, 4);
  }

  Future<void> loadData() async {
    try {
      final staff = await widget.fbService.getAvailableStaff();
      final actSnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .get();

      final suppSet = <String>{...AppConstants.commonSuppliers};
      for (var doc in actSnapshot.docs) {
        final data = doc.data();
        final supp = data['other_moe_suppliers'];
        if (supp != null && supp is String && supp.trim().isNotEmpty) {
          suppSet.add(supp.trim());
        }
      }

      setState(() {
        availableStaff = staff.where((s) => s != 'Other').toList();

        if (responsiblePerson.isNotEmpty &&
            !availableStaff.contains(responsiblePerson)) {
          availableStaff.insert(0, responsiblePerson);
        }
        if (responsiblePerson.isEmpty && availableStaff.isNotEmpty) {
          responsiblePerson = availableStaff.first;
        }

        availableSuppliers = suppSet.toList()..sort();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    activityNameCtl.dispose();
    unitHeadCtl.dispose();
    performanceIndicatorCtl.dispose();
    locationCtl.dispose();
    targetNoCtl.dispose();
    budgetCtl.dispose();
    ppmpAmountCtl.dispose();
    ppmpCtl.dispose();

    prAmountCtl.dispose();
    prBalanceCtl.dispose();
    prNumberCtl.dispose();
    supplierAppropCtl.dispose();
    barcodeAppropCtl.dispose();
    statusAppropCtl.dispose();
    targetParticipantsCtl.dispose();
    remarksCtl.dispose();
    customSectorCtl.dispose();
    customSubSectorCtl.dispose();
    customResponsiblePersonCtl.dispose();
    customStatusCtl.dispose();
    otherMoeSuppliersCtl.dispose();
    customStatusDateCtl.dispose();
    statusAppropDateCtl.dispose();

    super.dispose();
  }

  bool get isEdited {
    // Only check fields that the user directly interacts with and that should count as an edit
    final hasBasicInfo = activityNameCtl.text.trim().isNotEmpty ||
        unitHeadCtl.text.trim().isNotEmpty ||
        performanceIndicatorCtl.text.trim().isNotEmpty ||
        locationCtl.text.trim().isNotEmpty ||
        targetParticipantsCtl.text.trim().isNotEmpty ||
        remarksCtl.text.trim().isNotEmpty;

    final hasNumericChanges = (targetNoCtl.text.trim().isNotEmpty && targetNoCtl.text.trim() != '1') ||
        (budgetCtl.text.trim().isNotEmpty && budgetCtl.text.trim() != '0.00') ||
        (ppmpCtl.text.trim().isNotEmpty && ppmpCtl.text.trim() != '0.00') ||
        (prAmountCtl.text.trim().isNotEmpty && prAmountCtl.text.trim() != '0.00');

    final hasDropdownChanges = sector != AppConstants.sectors.first ||
        selectedStatus != AppConstants.activityStatuses.first ||
        (responsiblePerson.isNotEmpty && responsiblePerson != 'Admin');

    final hasFundChanges = fundSourceEntries.length > 1 ||
        fundSourceEntries.any((e) =>
            (e.amountCtl.text.isNotEmpty && e.amountCtl.text != '0.00') ||
            (e.fundingSource != 'Agri MOOE') ||
            (e.objectOfExpenditure != 'Other-MOE Expenses') ||
            (e.fundingSource == 'Other' && e.customFundingSourceCtl.text.trim().isNotEmpty));

    final hasOtherChanges = otherMoeSuppliersCtl.text.trim().isNotEmpty ||
        customStatusDateCtl.text.trim().isNotEmpty ||
        customSectorCtl.text.trim().isNotEmpty ||
        customSubSectorCtl.text.trim().isNotEmpty ||
        customResponsiblePersonCtl.text.trim().isNotEmpty;

    return hasBasicInfo ||
        hasNumericChanges ||
        hasDropdownChanges ||
        hasFundChanges ||
        hasOtherChanges;
  }

  Future<void> handleClose() async {
    if (!isEdited) {
      if (mounted) {
        context.read<ActivityFormProvider>().closeForm();
      }
      return;
    }

    final shouldClose = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (shouldClose == true && mounted) {
      context.read<ActivityFormProvider>().closeForm();
    }
  }

  Widget buildRowPair(Widget left, Widget right) {
    final width = MediaQuery.of(context).size.width;
    // The dialog is approx 95% of screen width. Use 700 as a more comfortable breakpoint for side-by-side rows
    if (width < 700) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          left,
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        Container(width: 1, color: border),
        Expanded(child: right),
      ],
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    rowIndex = 0; // reset before every build

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await handleClose();
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildTitleBar(),
                buildMenuBar(),
                Flexible(
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildRowPair(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  buildSectionHeader('A', 'CLASSIFICATION'),
                                  xlRow(
                                    'A1',
                                    'Section / Unit',
                                    buildSectorCell(),
                                  ),
                                  if (sector == 'Other')
                                    xlRow(
                                      'A2',
                                      'Custom Sector',
                                      textCell(customSectorCtl),
                                    ),
                                  if (sector == 'Crop Section') ...[
                                    xlRow(
                                      'A2',
                                      'Crop Program',
                                      buildSubSectorCell(),
                                    ),
                                    if (subSector == 'Other')
                                      xlRow(
                                        'A3',
                                        'Custom Program',
                                        textCell(customSubSectorCtl),
                                      ),
                                  ],
                                  xlRow(
                                    'A$rowIndex',
                                    'Section / Unit Head',
                                    textCell(unitHeadCtl),
                                  ),
                                  xlRow(
                                    'A$rowIndex',
                                    'PPA / Activity Name',
                                    textCell(activityNameCtl),
                                  ),
                                  xlRow(
                                    'A$rowIndex',
                                    'Location',
                                    textCell(locationCtl),
                                  ),
                                  xlRow(
                                    'A$rowIndex',
                                    'Performance Indicator',
                                    textCell(performanceIndicatorCtl),
                                  ),
                                  Container(height: 1, color: border),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  buildSectionHeader('B', 'TARGETS & BUDGET'),
                                  xlRow(
                                    'B1',
                                    'Target No.',
                                    numberCell(targetNoCtl),
                                  ),
                                  xlRow(
                                    'B2',
                                    'Approved Budget',
                                    currencyCell(budgetCtl, readOnly: true),
                                  ),
                                  xlRow(
                                    'B3',
                                    'PPMP Amount',
                                    currencyCell(ppmpAmountCtl), // Changed to editable
                                  ),
                                  xlRow(
                                    'B4',
                                    'PPMP Balance',
                                    currencyCell(ppmpCtl, readOnly: true),
                                  ),

                                  xlRow(
                                    'B5',
                                    'Target Participants',
                                    textCell(targetParticipantsCtl),
                                  ),
                                  Container(height: 1, color: border),
                                ],
                              ),
                            ),
                            buildRowPair(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  buildSectionHeader(
                                    'PR',
                                    'PURCHASE REQUEST DETAILS',
                                  ),
                                  xlRow(
                                    'PR1',
                                    'PR Number',
                                    textCell(prNumberCtl),
                                  ),
                                  xlRow(
                                    'PR2',
                                    'PR',
                                    currencyCell(prAmountCtl),
                                  ),
                                  xlRow(
                                    'PR3',
                                    'PR Balance',
                                    currencyCell(prBalanceCtl, readOnly: true),
                                  ),
                                  xlRow(
                                    'PR4',
                                    'Supplier',
                                    supplierCell(supplierAppropCtl),
                                  ),
                                  xlRow(
                                    'PR5',
                                    'Barcode',
                                    barcodeCell(barcodeAppropCtl),
                                  ),
                                  xlRow(
                                    'PR6',
                                    'PR Status',
                                    prStatusCell(statusAppropCtl),
                                  ),
                                  Container(height: 1, color: border),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  buildSectionHeader('D', 'ASSIGNMENT'),
                                  xlRow(
                                    'D1',
                                    'Responsible Person',
                                    buildResponsiblePersonCell(),
                                  ),
                                  if (responsiblePerson == 'Other')
                                    xlRow(
                                      'D2',
                                      'Custom Person',
                                      textCell(customResponsiblePersonCtl),
                                    ),
                                  Container(height: 1, color: border),
                                  buildSectionHeader('E', 'SCHEDULE & STATUS'),
                                  xlRow(
                                    'E1',
                                    'Date / Status',
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: dateCell(
                                            customStatusDateCtl,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 7,
                                          child: buildStatusCell(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selectedStatus.contains('Other'))
                                    xlRow(
                                      'E2',
                                      'Custom Status',
                                      textCell(customStatusCtl),
                                    ),
                                  xlRow(
                                    'E$rowIndex',
                                    'Month (From)',
                                    buildMonthCell(),
                                  ),
                                  xlRow(
                                    'E$rowIndex',
                                    'Month (To)',
                                    buildToMonthCell(),
                                  ),
                                  xlRow(
                                    'E$rowIndex',
                                    'Year',
                                    buildYearCell(),
                                  ),
                                  xlRow(
                                    'E$rowIndex',
                                    'Remarks',
                                    textCell(remarksCtl, maxLines: 2),
                                  ),
                                  Container(height: 1, color: border),
                                ],
                              ),
                            ),
                            buildRowPair(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  buildSectionHeader(
                                    'C',
                                    'FUNDING SOURCE & EXPENDITURES',
                                  ),
                                  buildFundSourcesSection(),
                                  xlRow(
                                    'C',
                                    'Other MOE Suppliers',
                                    supplierCell(
                                      otherMoeSuppliersCtl,
                                      allowsMultiple: true,
                                    ),
                                  ),
                                  Container(height: 1, color: border),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  buildSectionHeader(
                                    'F',
                                    'FINANCIAL BREAKDOWN',
                                  ),
                                  buildBreakdownsSection(),
                                  Container(height: 1, color: border),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                buildFooter(),
              ],
            ),
          ),
      );
  }

  // ── Modern Title Bar ─────────────────────────────────────────────────────────
  Widget buildTitleBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: modernDark,
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Activity',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'AgriWork & Financial Planning System (AWFPS)',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Provider.of<ActivityFormProvider>(
              context,
              listen: false,
            ).minimizeForm(),
            icon: const Icon(Icons.remove_rounded, color: Colors.white),
            tooltip: 'Minimize',
          ),
          IconButton(
            onPressed: handleClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: isEdited ? 'Discard' : 'Close',
          ),
        ],
      ),
    );
  }

  // ── Quick Info Bar ───────────────────────────────────────────────────
  Widget buildMenuBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: modernGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Text(
            'Please fill out the form naturally. Fields scale to fit content.',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header (accent bar + bold text) ──────────────────
  Widget buildSectionHeader(String col, String title) {
    rowIndex = 0; // reset row counter per section
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border(
          left: BorderSide(color: modernGreen, width: 4),
          bottom: const BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            alignment: Alignment.center,
            child: Text(
              col,
              style: GoogleFonts.inter(
                color: modernGreen,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: modernDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Modern Row View ───────────────────────────────────────────────────────────────
  Widget xlRow(String rowLabel, String fieldLabel, Widget cell) {
    final bg = nextRowColor;
    final bool isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          border: const Border(bottom: BorderSide(color: border, width: 0.8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: modernGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rowLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: modernGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fieldLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textMain,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            cell,
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: const Border(bottom: BorderSide(color: border, width: 0.8)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row identifier
            Container(
              width: 42,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: labelBg,
                border: Border(right: BorderSide(color: border, width: 0.8)),
              ),
              child: Text(
                rowLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: labelText.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Label
            Container(
              width: 180,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: labelBg,
                border: Border(right: BorderSide(color: border, width: 0.8)),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                fieldLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: textMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Input widget
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: cell,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cell builders ───────────────────────────────────────────────────────────
  InputDecoration cellDec([String? hint]) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black26),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: modernGreen, width: 1.5),
    ),
    errorStyle: const TextStyle(height: 0),
  );

  InputDecoration compactDec([String? hint]) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.black26),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: modernGreen, width: 1.5),
    ),
    errorStyle: const TextStyle(height: 0),
  );

  InputDecorationTheme cellTheme() => InputDecorationTheme(
    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black26),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: modernGreen, width: 1.5),
    ),
    errorStyle: const TextStyle(height: 0),
  );

  InputDecorationTheme compactTheme() => InputDecorationTheme(
    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.black26),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: modernGreen, width: 1.5),
    ),
    errorStyle: const TextStyle(height: 0),
  );

  Widget textCell(
    TextEditingController ctl, {
    int maxLines = 1,
    String? hint,
  }) => TextFormField(
    controller: ctl,
    maxLines: maxLines,
    style: GoogleFonts.inter(
      fontSize: 14,
      color: textMain,
      fontWeight: FontWeight.w500,
    ),
    decoration: cellDec(
      hint ?? (maxLines > 1 ? 'Enter text details...' : null),
    ),
  );

  Widget barcodeCell(TextEditingController ctl) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        textCell(ctl),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: ctl,
          builder: (context, value, child) {
            final data = value.text.trim();
            if (data.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: data,
                height: 60,
                errorBuilder: (context, error) => const Center(
                  child: Text(
                    'Invalid barcode data',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget supplierCell(
    TextEditingController ctl, {
    bool allowsMultiple = false,
  }) {
    return DropdownMenu<String>(
      initialSelection: ctl.text.isEmpty || !availableSuppliers.contains(ctl.text)
          ? ''
          : ctl.text,
      controller: ctl,
      enableSearch: true,
      enableFilter: true,
      menuHeight: 250,
      expandedInsets: EdgeInsets.zero,
      hintText: 'Select or type supplier...',
      textStyle: const TextStyle(fontSize: 13, color: textMain, fontWeight: FontWeight.w500),
      inputDecorationTheme: cellTheme(),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      dropdownMenuEntries: [
        const DropdownMenuEntry(value: '', label: 'Choose a supplier'),
        ...availableSuppliers.map((s) => DropdownMenuEntry(value: s, label: s)),
      ],
      onSelected: (val) {
        if (val != null && val.isNotEmpty) {
          if (allowsMultiple) {
            // If it already contains the value, don't add it again
            if (!ctl.text.contains(val)) {
              if (ctl.text.isEmpty) {
                ctl.text = val;
              } else {
                ctl.text = "${ctl.text.trim()}, $val";
              }
            }
          } else {
            ctl.text = val;
          }
        }
      },
    );
  }

  Widget prStatusCell(TextEditingController ctl) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: dateCell(statusAppropDateCtl)),
            const SizedBox(width: 8),
            Expanded(
              flex: 7,
              child: DropdownMenu<String>(
                initialSelection:
                    ctl.text.isEmpty ||
                        !AppConstants.activityStatuses.contains(ctl.text)
                    ? ''
                    : ctl.text,
                expandedInsets: EdgeInsets.zero,
                enableSearch: true,
                enableFilter: true,
                menuHeight: 250,
                hintText: 'Select PR status...',
                inputDecorationTheme: cellTheme(),
                dropdownMenuEntries: [
                  const DropdownMenuEntry(
                    value: '',
                    label: 'Choose PR status',
                  ),
                  ...AppConstants.activityStatuses.map(
                    (s) => DropdownMenuEntry(
                      value: s,
                      label: s,
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val != null) {
                    setState(() {
                      ctl.text = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        textCell(ctl, hint: 'Or type custom PR status...'),
      ],
    );
  }

  Widget numberCell(TextEditingController ctl) => TextFormField(
    controller: ctl,
    keyboardType: TextInputType.number,
    style: const TextStyle(
      fontSize: 13,
      color: textMain,
      fontWeight: FontWeight.w600,
    ),
    decoration: cellDec('0'),
  );

  Widget currencyCell(
    TextEditingController ctl, {
    bool readOnly = false,
    String? hint,
    bool isPO = false,
  }) =>
      TextFormField(
        controller: ctl,
        readOnly: readOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [CurrencyInputFormatter()],
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isPO ? const Color(0xFF1565C0) : (readOnly ? Colors.grey[700] : modernDark),
          fontWeight: FontWeight.bold,
        ),
        decoration: cellDec(hint ?? '0.00').copyWith(
          filled: true,
          fillColor: readOnly ? Colors.grey[100] : Colors.white,
          prefixIcon: isPO ? const Icon(Icons.shopping_cart_outlined, size: 14, color: Color(0xFF1565C0)) : null,
        ),
        onTapOutside: (_) {
          if (ctl.text.isNotEmpty) {
            ctl.text = CurrencyInputFormatter.formatDouble(
              CurrencyInputFormatter.parse(ctl.text),
            );
          }
        },
        onFieldSubmitted: (val) {
          if (val.isNotEmpty) {
            ctl.text = CurrencyInputFormatter.formatDouble(
              CurrencyInputFormatter.parse(val),
            );
          }
        },
      );

  Widget dateCell(TextEditingController ctl) => TextFormField(
    controller: ctl,
    readOnly: true,
    style: const TextStyle(fontSize: 12, color: textMain),
    decoration: cellDec(
      'Select Date',
    ).copyWith(suffixIcon: const Icon(Icons.calendar_today, size: 14)),
    onTap: () async {
      final currentText = ctl.text;
      final initialDate = AppDateFormatter.parse(currentText) ?? DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        ctl.text = AppDateFormatter.format(date);
      }
    },
  );
  Widget dropdownCell<T>({
    required T? value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return DropdownMenu<T>(
      initialSelection: value,
      enableSearch: true,
      enableFilter: true,
      menuHeight: 250,
      expandedInsets: EdgeInsets.zero,
      hintText: hint,
      textStyle: const TextStyle(fontSize: 14, color: textMain, fontWeight: FontWeight.w500),
      inputDecorationTheme: cellTheme(),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      dropdownMenuEntries: options.map((opt) {
        return DropdownMenuEntry<T>(
          value: opt,
          label: opt.toString(),
        );
      }).toList(),
      onSelected: onChanged,
    );
  }

  Widget buildSectorCell() {
    return dropdownCell<String>(
      value: sector,
      options: [
        ...AppConstants.sectors,
        'Other',
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            sector = val;
            subSector = null;
            // Update default OE for existing fund sources
            for (var e in fundSourceEntries) {
              if (e.fundingSource == 'Agri MOOE') {
                final specificApprop = '$sector Appropriation';
                if (AppConstants.objectsOfExpenditure.contains(
                  specificApprop,
                )) {
                  e.objectOfExpenditure = specificApprop;
                } else {
                  e.objectOfExpenditure = 'Other-MOE Expenses';
                }
              }
            }
          });
        }
      },
    );
  }

  Widget buildSubSectorCell() {
    return dropdownCell<String?>(
      value: subSector,
      options: [
        null,
        ...AppConstants.subSectors,
      ],
      onChanged: (val) => setState(() {
        subSector = val;

        // Update fund sources objectsOfExpenditure for the newly selected sub-sector
        for (var e in fundSourceEntries) {
          if (sector == 'Crop Section') {
            final specificApprop = val != null && val != 'Other'
                ? '$val Appropriation'
                : '$sector Appropriation';
            if (AppConstants.objectsOfExpenditure.contains(specificApprop)) {
              e.objectOfExpenditure = specificApprop;
            } else {
              e.objectOfExpenditure = 'Other-MOE Expenses';
            }
          }
        }
      }),
    );
  }

  Widget buildStatusCell() {
    final List<String> statusOptions = [
      ...AppConstants.activityStatuses,
      'Other',
    ];

    if (selectedStatus.isNotEmpty &&
        !statusOptions.contains(selectedStatus)) {
      statusOptions.insert(0, selectedStatus);
    }

    return dropdownCell<String>(
      value: selectedStatus.isEmpty ? statusOptions.first : selectedStatus,
      options: statusOptions,
      hint: 'Select status...',
      onChanged: (val) {
        if (val != null) {
          setState(() => selectedStatus = val);
        }
      },
    );
  }

  void addFundSourceEntry() {
    setState(() {
      final e = FundSourceEntry();
      e.amountCtl.addListener(updateTotalBudget);
      e.customFundingSourceCtl.addListener(() => setState(() {}));
      e.customObjectOfExpenditureCtl.addListener(() => setState(() {}));
      fundSourceEntries.add(e);
      updateTotalBudget();
    });
  }

  Widget buildFundSourcesSection() {
    return Column(
      children: [
        ...fundSourceEntries.asMap().entries.map((entry) {
          final idx = entry.key;
          final e = entry.value;
          final bg = idx.isEven ? rowOdd : rowEven;

          return Container(
            decoration: BoxDecoration(
              color: bg,
              border: const Border(
                bottom: BorderSide(color: border, width: 0.8),
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'C${idx + 1}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: labelText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: buildSourceDropdownForFundSource(e),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: currencyCell(
                                    e.amountCtl,
                                    hint: 'Amount (PHP)',
                                    readOnly: e.breakdownItems.isNotEmpty,
                                  ),
                                ),
                                if (fundSourceEntries.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() {
                                      final removed =
                                          fundSourceEntries.removeAt(idx);
                                      removed.dispose();
                                      updateTotalBudget();
                                    }),
                                  ),
                              ],
                            ),
                            if (e.fundingSource == 'Other')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: textCell(
                                  e.customFundingSourceCtl,
                                  hint: 'Custom Funding Source Name',
                                ),
                              ),
                            if (e.fundingSource == 'Agri MOOE') ...[
                              const Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 4),
                                child: Row(
                                  children: [
                                    SizedBox(width: 2),
                                    Icon(
                                      Icons.subdirectory_arrow_right,
                                      size: 12,
                                      color: Color(0xFF4CAF50),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'OBJECT OF EXPENDITURE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF4CAF50),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFB2DFDB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              buildObjOfExpenditureDropdownForFundSource(e),
                            ],
                            if (e.fundingSource == 'Agri MOOE' &&
                                (e.objectOfExpenditure == 'Other' ||
                                    e.objectOfExpenditure ==
                                        'Other-MOE Expenses'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: textCell(
                                  e.customObjectOfExpenditureCtl,
                                  hint: 'Custom Object of Expenditure',
                                ),
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
        }),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OutlinedButton.icon(
            onPressed: addFundSourceEntry,
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Add Funding Source',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBreakdownsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: fundSourceEntries.asMap().entries.map((entry) {
        final idx = entry.key;
        final fe = entry.value;
        // Resolve the display name for this funding source
        final fsLabel = fe.fundingSource == 'Other'
            ? (fe.customFundingSourceCtl.text.trim().isNotEmpty
                  ? fe.customFundingSourceCtl.text.trim()
                  : 'Other')
            : fe.fundingSource;

        final resolvedOE =
            (fe.objectOfExpenditure == 'Other' ||
                fe.objectOfExpenditure == 'Other-MOE Expenses')
            ? (fe.customObjectOfExpenditureCtl.text.trim().isNotEmpty
                  ? fe.customObjectOfExpenditureCtl.text.trim()
                  : fe.objectOfExpenditure)
            : fe.objectOfExpenditure;

        final oeLabel =
            (fsLabel == 'Agri MOOE' &&
                resolvedOE != null &&
                resolvedOE.isNotEmpty)
            ? ' — $resolvedOE'
            : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Always-visible funding source divider header
            Container(
              decoration: BoxDecoration(
                color: modernGreen.withValues(alpha: 0.08),
                border: Border(left: BorderSide(color: modernGreen, width: 3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 13,
                    color: modernGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fundSourceEntries.length > 1
                          ? 'Source ${idx + 1}: $fsLabel$oeLabel'
                          : '$fsLabel$oeLabel',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: modernGreen,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            buildNestedBreakdown(fe),
          ],
        );
      }).toList(),
    );
  }

  Widget buildSourceDropdownForFundSource(FundSourceEntry e) {
    return breakdownDropdown<String>(
      value: e.fundingSource,
      options: AppConstants.fundingSources,
      onChanged: (val) {
        setState(() {
          e.fundingSource = val!;
          if (e.fundingSource == 'Agri MOOE') {
            final specificApprop =
                (sector == 'Crop Section' &&
                    subSector != null &&
                    subSector != 'Other')
                ? '$subSector Appropriation'
                : '$sector Appropriation';
            if (AppConstants.objectsOfExpenditure.contains(specificApprop)) {
              e.objectOfExpenditure = specificApprop;
            } else {
              e.objectOfExpenditure = 'Other-MOE Expenses';
            }
          } else {
            e.objectOfExpenditure = null;
          }
        });
      },
    );
  }

  Widget buildObjOfExpenditureDropdownForFundSource(FundSourceEntry e) {
    return breakdownDropdown<String>(
      value: e.objectOfExpenditure,
      options: AppConstants.getFilteredObjectsOfExpenditure(
        sector,
        subSector: subSector,
        fundingSource: e.fundingSource,
      ),
      onChanged: (val) => setState(() => e.objectOfExpenditure = val),
    );
  }

  Widget buildResponsiblePersonCell() {
    if (availableStaff.isEmpty) {
      return Row(
        children: const [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: modernGreen,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Loading staff...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }
    return dropdownCell<String>(
      value: (availableStaff.contains(responsiblePerson) ||
              responsiblePerson == 'Other')
          ? responsiblePerson
          : null,
      options: [
        ...availableStaff,
        'Other',
      ],
      onChanged: (val) => setState(() => responsiblePerson = val!),
    );
  }

  Widget buildMonthCell() => dropdownCell<String>(
    value: selectedMonth,
    options: months,
    onChanged: (val) => setState(() => selectedMonth = val!),
  );

  Widget buildToMonthCell() => dropdownCell<String?>(
    value: selectedToMonth,
    options: [
      null,
      ...months,
    ],
    onChanged: (val) => setState(() => selectedToMonth = val),
  );

  Widget buildYearCell() => dropdownCell<String>(
    value: selectedYear,
    options: years,
    onChanged: (val) => setState(() => selectedYear = val!),
  );
  // ── Breakdown Table ─────────────────────────────────────────────────────────
  Widget buildNestedBreakdown(FundSourceEntry fe) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: modernGreen.withValues(alpha: 0.05),
              child: Row(
                children: [
                  const Icon(Icons.list_alt_rounded, size: 16, color: modernDark),
                  const SizedBox(width: 8),
                  Text(
                    'EXPENDITURE BREAKDOWN',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: modernDark,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            // Column headers - Only for Desktop
            if (fe.breakdownItems.isNotEmpty && !isMobile)
              Container(
                color: const Color(0xFFF0F4EF),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  children: const [
                    SizedBox(width: 20), // item badge
                    SizedBox(width: 6),
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: labelText,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'PO Amount',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: modernGreen,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Supplier',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: labelText,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: labelText,
                        ),
                      ),
                    ),
                    SizedBox(width: 24), // delete button space
                  ],
                ),
              ),

            if (fe.breakdownItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(
                  'No breakdown items added.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                ),
              ),

            ...fe.breakdownItems.asMap().entries.map((entry) {
              final bIdx = entry.key;
              final be = entry.value;
              final bg = bIdx.isEven ? Colors.white : const Color(0xFFF8FAF7);

              if (isMobile) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: modernGreen.withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: modernGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${bIdx + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Item Details',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: modernDark,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              onPressed: () => setState(() {
                                final removed = fe.breakdownItems.removeAt(bIdx);
                                removed.amountCtl.removeListener(updateTotalBudget);
                                removed.dispose();
                                updateTotalBudget();
                              }),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            mobileBreakdownField('Description',
                                TextFormField(
                                  controller: be.nameCtl,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: compactDec('Description...'),
                                )),
                            const SizedBox(height: 8),
                            mobileBreakdownField('Amount',
                                currencyCell(
                                  be.amountCtl,
                                  hint: '0.00',
                                ),
                            ),
                            const SizedBox(height: 8),
                            mobileBreakdownField('Supplier',
                                TextFormField(
                                  controller: be.supplierCtl,
                                  style: const TextStyle(fontSize: 12),
                                  decoration:
                                      compactDec('Supplier...').copyWith(
                                    suffixIcon: availableSuppliers.isEmpty
                                        ? null
                                        : PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              size: 20,
                                            ),
                                            onSelected: (v) => setState(() =>
                                                be.supplierCtl.text = v),
                                            itemBuilder: (ctx) =>
                                                availableSuppliers
                                                    .map((s) => PopupMenuItem(
                                                          value: s,
                                                          child: Text(s,
                                                              style: const TextStyle(
                                                                  fontSize:
                                                                      12)),
                                                        ))
                                                    .toList(),
                                          ),
                                  ),
                                )),
                            const SizedBox(height: 8),
                            mobileBreakdownField('Status',
                                breakdownDropdown<String>(
                                  value: be.statusCtl.text.isEmpty
                                      ? ''
                                      : (AppConstants.activityStatuses.contains(be.statusCtl.text)
                                          ? be.statusCtl.text
                                          : ''),
                                  options: ['', ...AppConstants.activityStatuses],
                                  onChanged: (v) => setState(() => be.statusCtl.text = v ?? ''),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                color: bg,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Item badge
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: modernGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${bIdx + 1}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: modernGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Description
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: be.nameCtl,
                        style: const TextStyle(fontSize: 11),
                        decoration: compactDec('Description...'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Amount
                    Expanded(
                      flex: 3,
                      child: currencyCell(
                        be.amountCtl,
                        hint: '0.00',
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Supplier (Combo Box: Input + Dropdown)
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: be.supplierCtl,
                        style: const TextStyle(fontSize: 11),
                        decoration: compactDec('Supplier...').copyWith(
                          suffixIcon: availableSuppliers.isEmpty
                              ? null
                              : PopupMenuButton<String>(
                                  constraints: const BoxConstraints(
                                    maxHeight: 250,
                                    maxWidth: 300,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onSelected: (val) {
                                    setState(() {
                                      be.supplierCtl.text = val;
                                    });
                                  },
                                  itemBuilder: (context) => availableSuppliers
                                      .map(
                                        (s) => PopupMenuItem(
                                          value: s,
                                          height: 32,
                                          child: Text(
                                            s,
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                          suffixIconConstraints: const BoxConstraints(
                            maxWidth: 24,
                            maxHeight: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 3,
                        child: breakdownDropdown<String>(
                        value: be.statusCtl.text.isEmpty
                            ? ''
                            : (AppConstants.activityStatuses.contains(be.statusCtl.text)
                                ? be.statusCtl.text
                                : ''),
                        options: ['', ...AppConstants.activityStatuses],
                        onChanged: (v) => setState(() => be.statusCtl.text = v ?? ''),
                        useCompact: true,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Delete button
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 16),
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(() {
                          final removed = fe.breakdownItems.removeAt(bIdx);
                          removed.amountCtl.removeListener(updateTotalBudget);
                          removed.dispose();
                          updateTotalBudget();
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Total Row
              if (fe.breakdownItems.isNotEmpty)
                Container(
                  color: headerBg.withValues(alpha: 0.3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 20), // item badge space
                      const SizedBox(width: 6),
                      const Expanded(
                        flex: 5,
                        child: Text(
                          'TOTAL PO AMOUNT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: modernDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 3,
                        child: Text(
                          CurrencyInputFormatter.formatDouble(
                            fe.breakdownItems.fold<double>(
                              0,
                              (sum, item) =>
                                  sum +
                                  CurrencyInputFormatter.parse(
                                      item.amountCtl.text),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: modernGreen,
                          ),
                        ),
                      ),
                      const Expanded(
                          flex: 7,
                          child: SizedBox()), // spacer for supplier/status
                      const SizedBox(width: 24),
                    ],
                  ),
                ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: InkWell(
            onTap: () => setState(() {
              final lastEntry = fe.breakdownItems.isNotEmpty ? fe.breakdownItems.last : null;
              final newEntry = BreakdownEntry(
                name: '',
                supplier: lastEntry?.supplierCtl.text,
                status: lastEntry?.statusCtl.text,
              );
              newEntry.amountCtl.addListener(updateTotalBudget);
              fe.breakdownItems.add(newEntry);
              updateTotalBudget();
            }),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_circle_outline, size: 13, color: modernGreen),
                SizedBox(width: 4),
                Text(
                  'Add Item',
                  style: TextStyle(
                    fontSize: 11,
                    color: modernGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget mobileBreakdownField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget breakdownDropdown<T>({
    required T? value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
    bool useCompact = false,
  }) => DropdownMenu<T>(
    initialSelection: value,
    enableSearch: true,
    enableFilter: true,
    menuHeight: 250,
    expandedInsets: EdgeInsets.zero,
    textStyle: const TextStyle(fontSize: 14, color: textMain, fontWeight: FontWeight.w500),
    inputDecorationTheme: useCompact ? compactTheme() : cellTheme(),
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(Colors.white),
      elevation: WidgetStateProperty.all(8),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    dropdownMenuEntries: options.map((opt) {
        return DropdownMenuEntry<T>(
          value: opt,
          label: opt.toString(),
        );
      }).toList(),
    onSelected: onChanged,
  );

  // ── Footer ──────────────────────────────────────────────────────────────────
  Widget buildFooter() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: border.withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: modernGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 16, color: modernGreen),
                const SizedBox(width: 8),
                Text(
                  'Activity Details',
                  style: GoogleFonts.inter(
                    color: modernGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: handleClose,
            style: TextButton.styleFrom(
              foregroundColor: labelText,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          saving
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: modernGreen,
                  ),
                )
              : Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onSave(true),
                      icon: const Icon(Icons.drafts_outlined, size: 18),
                      label: Text(
                        'Save as Draft',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: modernGreen,
                        side: const BorderSide(color: modernGreen, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF064E3B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => onSave(false),
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          'Save Activity',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────────
  void onSave(bool asDraft) async {
    if (saving) return;
    final authService = context.read<AuthService>();
    final userName = authService.currentUser?.name ?? 'Admin';

    // For drafts, we can skip full validation if we want, but let's at least keep the form key state
    if (!asDraft && !formKey.currentState!.validate()) return;

    formKey.currentState!.save();
    // Force re-calculation before saving to ensure controllers are in sync
    updateTotalBudget();
    setState(() => saving = true);

    try {
      final resolvedSector = (sector == 'Other' ? customSectorCtl.text : sector)
          .trim();
      final resolvedSubSector =
          (subSector == 'Other'
                  ? customSubSectorCtl.text
                  : (subSector ?? ''))
              .trim();
      
      final activityName = activityNameCtl.text.trim();
      final targetDateStr = selectedToMonth != null
          ? '$selectedMonth - $selectedToMonth $selectedYear'
          : '$selectedMonth $selectedYear';

      // Check for duplicates
      final isDuplicate = await widget.fbService.checkDuplicateActivity(
        activityName,
        resolvedSector,
        targetDateStr,
      );

      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An activity with this name, sector, and target date already exists.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => saving = false);
        }
        return;
      }
      final budget = CurrencyInputFormatter.parse(budgetCtl.text);
      final month = selectedMonth;

      final fundSources = fundSourceEntries
          .map(
            (e) => FundSourceItem(
              fundingSource:
                  (e.fundingSource == 'Other'
                          ? e.customFundingSourceCtl.text
                          : e.fundingSource)
                      .trim(),
              objectOfExpenditure: (e.objectOfExpenditure == 'Other'
                  ? e.customObjectOfExpenditureCtl.text
                  : e.objectOfExpenditure),
              amount: CurrencyInputFormatter.parse(e.amountCtl.text),
            ),
          )
          .where((e) => e.fundingSource.isNotEmpty && e.amount > 0)
          .toList();

      final breakdownList = fundSourceEntries
          .expand((fe) {
            final fSource =
                (fe.fundingSource == 'Other'
                        ? fe.customFundingSourceCtl.text
                        : fe.fundingSource)
                    .trim();
            final oExp = (fe.objectOfExpenditure == 'Other'
                ? fe.customObjectOfExpenditureCtl.text
                : fe.objectOfExpenditure);

            return fe.breakdownItems.map(
              (be) => BreakdownItem(
                name: be.nameCtl.text.trim(),
                amount: CurrencyInputFormatter.parse(be.amountCtl.text),
                fundingSource: fSource,
                objectOfExpenditure: oExp,
                supplier: be.supplierCtl.text.trim().isNotEmpty
                    ? be.supplierCtl.text.trim()
                    : '',
                status: be.statusCtl.text.trim().isNotEmpty
                    ? be.statusCtl.text.trim()
                    : '',
              ),
            );
          })
          .where((e) => e.name.isNotEmpty || e.amount > 0)
          .toList();

      final totalPOAmount =
          breakdownList.fold<double>(0, (sum, item) => sum + item.amount);

      final newActivity = Activity(
        id: '',
        sector: resolvedSector,
        subSector: resolvedSubSector,
        activityName: activityNameCtl.text.trim(),
        unitHead: unitHeadCtl.text.trim(),
        performanceIndicator: performanceIndicatorCtl.text.trim(),
        targetNo: int.tryParse(targetNoCtl.text) ?? 0,
        fundingSource: fundSources.isNotEmpty
            ? fundSources.first.fundingSource
            : 'Agri MOOE',
        objectOfExpenditure: fundSources.isNotEmpty
            ? fundSources.first.objectOfExpenditure
            : 'Other-MOE Expenses',
        q1Budget: (month == 'January' || month == 'February' || month == 'March' || 
                    (selectedToMonth != null && ['January', 'February', 'March'].any((m) => 
                      months.indexOf(m) >= months.indexOf(selectedMonth) && 
                      months.indexOf(m) <= months.indexOf(selectedToMonth!))))
            ? budget / (selectedToMonth == null ? 1 : calculateQuartersInRange())
            : 0,
        q2Budget: (month == 'April' || month == 'May' || month == 'June' ||
                    (selectedToMonth != null && ['April', 'May', 'June'].any((m) => 
                      months.indexOf(m) >= months.indexOf(selectedMonth) && 
                      months.indexOf(m) <= months.indexOf(selectedToMonth!))))
            ? budget / (selectedToMonth == null ? 1 : calculateQuartersInRange())
            : 0,
        q3Budget: (month == 'July' || month == 'August' || month == 'September' ||
                    (selectedToMonth != null && ['July', 'August', 'September'].any((m) => 
                      months.indexOf(m) >= months.indexOf(selectedMonth) && 
                      months.indexOf(m) <= months.indexOf(selectedToMonth!))))
            ? budget / (selectedToMonth == null ? 1 : calculateQuartersInRange())
            : 0,
        q4Budget: (month == 'October' || month == 'November' || month == 'December' ||
                    (selectedToMonth != null && ['October', 'November', 'December'].any((m) => 
                      months.indexOf(m) >= months.indexOf(selectedMonth) && 
                      months.indexOf(m) <= months.indexOf(selectedToMonth!))))
            ? budget / (selectedToMonth == null ? 1 : calculateQuartersInRange())
            : 0,
        actualExpenditure: totalPOAmount,
        ppmpAmount: CurrencyInputFormatter.parse(ppmpAmountCtl.text),
        ppmpBalance: CurrencyInputFormatter.parse(ppmpCtl.text),
        prAmount: CurrencyInputFormatter.parse(prAmountCtl.text),
        prBalance: CurrencyInputFormatter.parse(prBalanceCtl.text),
        prNumber: prNumberCtl.text.trim(),
        supplierApprop: supplierAppropCtl.text.trim(),
        barcodeApprop: barcodeAppropCtl.text.trim(),
        statusApprop: statusAppropCtl.text.trim(),
        statusAppropDate: statusAppropDateCtl.text.trim(),
        responsiblePerson:
            (responsiblePerson == 'Other'
                    ? customResponsiblePersonCtl.text
                    : responsiblePerson)
                .trim(),
        status: selectedStatus.contains('Other')
            ? selectedStatus.replaceAll('Other', customStatusCtl.text.trim())
            : selectedStatus,
        statusDate: customStatusDateCtl.text.trim(),
        targetDate: selectedToMonth != null
            ? '$selectedMonth - $selectedToMonth $selectedYear'
            : '$selectedMonth $selectedYear',
        targetParticipants: targetParticipantsCtl.text.trim(),
        location: locationCtl.text.trim(),
        fundingInputtedBy: userName.trim(),
        statusInputtedBy: userName.trim(),
        otherMoeSuppliers: otherMoeSuppliersCtl.text.trim(),
        remarks: remarksCtl.text.trim(),
        isDraft: asDraft,
        breakdown: breakdownList,
        fundSources: fundSources,
      );

      final newId = await widget.fbService.addActivity(newActivity);

      // Create initial PR log if PR info exists
      if (newActivity.prNumber.isNotEmpty ||
          newActivity.prAmount > 0 ||
          newActivity.statusApprop.isNotEmpty) {
        await widget.fbService.addPRLog(
          PRLog(
            id: '',
            activityId: newId,
            status: newActivity.statusApprop.isNotEmpty
                ? newActivity.statusApprop
                : 'Pending',
            prNumber: newActivity.prNumber,
            amount: newActivity.prAmount,
            remarks: 'Activity created with initial PR details.',
            timestamp: DateTime.now(),
            updatedBy: userName,
          ),
        );
      }
      if (mounted) {
        final formProvider = context.read<ActivityFormProvider>();
        
        // Persist dropdown values for the next "Add Activity" action
        formProvider.sector = sector;
        formProvider.subSector = subSector;
        formProvider.selectedStatus = selectedStatus;
        formProvider.selectedMonth = selectedMonth;
        formProvider.selectedToMonth = selectedToMonth;
        formProvider.selectedYear = selectedYear;
        formProvider.responsiblePerson = responsiblePerson;
        
        if (fundSourceEntries.isNotEmpty) {
          formProvider.lastFundingSource = fundSourceEntries.first.fundingSource;
          formProvider.lastObjectOfExpenditure = fundSourceEntries.first.objectOfExpenditure;
        }
        
        formProvider.supplierAppropCtl.text = supplierAppropCtl.text;
        formProvider.statusAppropCtl.text = statusAppropCtl.text;

        formProvider.closeForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              asDraft ? 'Saved as Draft' : 'Activity Saved Successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
