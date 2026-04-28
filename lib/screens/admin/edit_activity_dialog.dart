import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive_utils.dart';

import '../../core/constants.dart';
import '../../core/currency_formatter.dart';
import '../../core/date_formatter.dart';
import '../../models/activity.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../models/pr_log.dart';
import 'package:cityagriadmin/services/activity_form_provider.dart';

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
    String? name,
    String? amount,
    String? supplier,
    String? status,
  }) : nameCtl = TextEditingController(text: name),
       amountCtl = TextEditingController(text: amount),
       supplierCtl = TextEditingController(text: supplier),
       statusCtl = TextEditingController(text: status);

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
  final TextEditingController customFundingSourceCtl = TextEditingController();
  final TextEditingController customObjectOfExpenditureCtl =
      TextEditingController();
  final TextEditingController amountCtl;
  final List<BreakdownEntry> breakdownItems = [];

  FundSourceEntry({String? amount})
    : amountCtl = TextEditingController(text: amount ?? '₱ 0.00');

  void dispose() {
    customFundingSourceCtl.dispose();
    customObjectOfExpenditureCtl.dispose();
    amountCtl.dispose();
    for (var b in breakdownItems) {
      b.dispose();
    }
  }
}

class EditActivityDialog extends StatefulWidget {
  final FirebaseService fbService;
  final Activity activity;
  const EditActivityDialog({
    super.key,
    required this.fbService,
    required this.activity,
  });

  @override
  State<EditActivityDialog> createState() => EditActivityDialogState();
}

class EditActivityDialogState extends State<EditActivityDialog> {
  final formKey = GlobalKey<FormState>();

  late String sector;
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

  // Accomplishment fields
  final actualConductCtl = TextEditingController();
  final accommRemarksCtl = TextEditingController();

  late String selectedStatus;
  late String selectedMonth;
  String? selectedToMonth;
  late String selectedYear;
  late String responsiblePerson;

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
  final List<String> years = [
    '2023',
    '2024',
    '2025',
    '2026',
    '2027',
    '2028',
    '2029',
    '2030',
  ];

  int rowIndex = 0;
  Color get nextRowColor {
    final c = rowIndex.isOdd ? rowEven : rowOdd;
    rowIndex++;
    return c;
  }

  bool get isEdited {
    final a = widget.activity;
    final budgetVal = CurrencyInputFormatter.parse(budgetCtl.text);
    final ppmpVal = CurrencyInputFormatter.parse(ppmpCtl.text);
    final prAmountVal = CurrencyInputFormatter.parse(prAmountCtl.text);
    final prBalanceVal = CurrencyInputFormatter.parse(prBalanceCtl.text);

    final String currentStatus = selectedStatus == 'Other'
        ? customStatusCtl.text.trim()
        : selectedStatus;

    final String currentResponsible = responsiblePerson == 'Other'
        ? customResponsiblePersonCtl.text.trim()
        : responsiblePerson;

    final String currentSector = sector == 'Other'
        ? customSectorCtl.text.trim()
        : sector;

    return activityNameCtl.text.trim() != a.activityName ||
        unitHeadCtl.text.trim() != (a.unitHead ?? '') ||
        performanceIndicatorCtl.text.trim() != a.performanceIndicator ||
        locationCtl.text.trim() != (a.location ?? '') ||
        targetNoCtl.text.trim() != a.targetNo.toString() ||
        budgetVal != a.totalBudget ||
        ppmpVal != a.ppmpBalance ||
        prAmountVal != a.prAmount ||
        prBalanceVal != a.prBalance ||
        prNumberCtl.text.trim() != a.prNumber ||
        supplierAppropCtl.text.trim() != a.supplierApprop ||
        barcodeAppropCtl.text.trim() != a.barcodeApprop ||
        statusAppropCtl.text.trim() != a.statusApprop ||
        targetParticipantsCtl.text.trim() != a.targetParticipants ||
        remarksCtl.text.trim() != a.remarks ||
        currentSector != a.sector ||
        subSector != a.subSector ||
        currentStatus != a.status ||
        currentResponsible != a.responsiblePerson;
  }

  @override
  void initState() {
    super.initState();
    initializeData();
    loadData();

    // PR Balance = Approved Budget - PR Amount
    prAmountCtl.addListener(updatePRBalance);
    // PPMP Balance = PPMP Amount - Approved Budget
    ppmpAmountCtl.addListener(updatePPMPBalance);

    // Wire listeners for fund source amounts only (not PO/breakdown items)
    for (var entry in fundSourceEntries) {
      entry.amountCtl.addListener(updateTotalBudget);
      entry.customFundingSourceCtl.addListener(() => setState(() {}));
      entry.customObjectOfExpenditureCtl.addListener(() => setState(() {}));
    }

    // Recalculate Approved Budget from the pre-loaded fund sources on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) updateTotalBudget();
    });

    // Compute PO total from pre-loaded breakdown items
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
    final double budget = CurrencyInputFormatter.parse(budgetCtl.text);
    final double prAmount = CurrencyInputFormatter.parse(prAmountCtl.text);
    final double balance = budget - prAmount;
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
    // We no longer force PPMP Amount to match Approved Budget here.
    // This allows users to track the actual PPMP allocation vs the Approved Budget.
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

  void initializeData() {
    final a = widget.activity;
    sector = AppConstants.sectors.contains(a.sector) ? a.sector : 'Other';
    if (sector == 'Other') customSectorCtl.text = a.sector;
    subSector = a.subSector;
    activityNameCtl.text = a.activityName;
    unitHeadCtl.text = a.unitHead ?? '';
    performanceIndicatorCtl.text = a.performanceIndicator;
    locationCtl.text = a.location ?? '';
    targetNoCtl.text = a.targetNo.toString();
    budgetCtl.text = CurrencyInputFormatter.formatDouble(a.totalBudget);
    ppmpAmountCtl.text = CurrencyInputFormatter.formatDouble(
      a.ppmpAmount > 0 ? a.ppmpAmount : a.totalBudget,
    );
    ppmpCtl.text = CurrencyInputFormatter.formatDouble(
      a.ppmpBalance > 0 ? a.ppmpBalance : (a.ppmpAmount - a.totalBudget),
    );

    prAmountCtl.text = CurrencyInputFormatter.formatDouble(
      widget.activity.prAmount,
    );
    prBalanceCtl.text = CurrencyInputFormatter.formatDouble(a.prBalance);
    prNumberCtl.text = a.prNumber;
    supplierAppropCtl.text = a.supplierApprop;
    barcodeAppropCtl.text = a.barcodeApprop;
    statusAppropCtl.text = a.statusApprop;
    statusAppropDateCtl.text = a.statusAppropDate ?? '';
    targetParticipantsCtl.text = a.targetParticipants;
    remarksCtl.text = a.remarks;
    actualConductCtl.text = a.actualConduct;
    accommRemarksCtl.text = a.accommRemarks;
    selectedStatus = AppConstants.activityStatuses.contains(a.status)
        ? a.status
        : 'Other';
    if (selectedStatus == 'Other') customStatusCtl.text = a.status;
    customStatusDateCtl.text = a.statusDate ?? '';
    // Load responsible person and handle "Other" logic
    final isStaff = AppConstants.staffList.contains(a.responsiblePerson);
    responsiblePerson = isStaff ? a.responsiblePerson : 'Other';
    if (!isStaff) {
      customResponsiblePersonCtl.text = a.responsiblePerson;
    }

    // Parse targetDate (e.g., "January 2024" or "Jan-Feb 2024")
    final parts = a.targetDate.split(' ');
    if (parts.length >= 2) {
      final monthPart = parts[0];
      selectedYear = parts.last;
      if (monthPart.contains('-')) {
        final ms = monthPart.split('-');
        selectedMonth = ms[0];
        selectedToMonth = ms[1];
      } else {
        selectedMonth = monthPart;
        selectedToMonth = null;
      }
    } else {
      selectedMonth = 'January';
      selectedYear = '2025';
    }

    // Initialize fund source entries from existing fundSources or legacy fundingSource
    if (a.fundSources.isNotEmpty) {
      for (var fs in a.fundSources) {
        String fsKey = fs.fundingSource;
        String cfs = '';
        if (!AppConstants.fundingSources.contains(fsKey) && fsKey != 'Other') {
          cfs = fsKey;
          fsKey = 'Other';
        }
        String? oe = fs.objectOfExpenditure;
        String coe = '';
        if (oe != null &&
            !AppConstants.objectsOfExpenditure.contains(oe) &&
            oe != 'Other' &&
            oe != 'Other-MOE Expenses') {
          coe = oe;
          oe = 'Other';
        }
        final entry = FundSourceEntry(
          amount: CurrencyInputFormatter.formatDouble(fs.amount),
        );
        entry.fundingSource = fsKey;
        entry.objectOfExpenditure = oe ?? 'Other-MOE Expenses';
        entry.customFundingSourceCtl.text = cfs;
        entry.customObjectOfExpenditureCtl.text = coe;
        fundSourceEntries.add(entry);
      }
    } else {
      // Fallback: create one entry from legacy single funding source
      final entry = FundSourceEntry(
        amount: CurrencyInputFormatter.formatDouble(a.totalBudget),
      );
      String fsKey = AppConstants.fundingSources.contains(a.fundingSource)
          ? a.fundingSource
          : 'Other';
      if (fsKey == 'Other') {
        entry.customFundingSourceCtl.text = a.fundingSource;
      }
      entry.fundingSource = fsKey;
      final oe = a.objectOfExpenditure;
      if (oe != null && AppConstants.objectsOfExpenditure.contains(oe)) {
        entry.objectOfExpenditure = oe;
      } else {
        entry.objectOfExpenditure = 'Other-MOE Expenses';
        if (oe != null && oe.isNotEmpty) {
          entry.customObjectOfExpenditureCtl.text = oe;
        }
      }
      fundSourceEntries.add(entry);
    }

    if (a.breakdown.isNotEmpty) {
      for (var item in a.breakdown) {
        // Find which fund source this belongs to
        FundSourceEntry? matchingFe;
        for (var fe in fundSourceEntries) {
          final feSource =
              (fe.fundingSource == 'Other'
                      ? fe.customFundingSourceCtl.text
                      : fe.fundingSource)
                  .trim();
          final feOE =
              (fe.objectOfExpenditure == 'Other'
                      ? fe.customObjectOfExpenditureCtl.text
                      : fe.objectOfExpenditure)
                  ?.trim();

          if (feSource == item.fundingSource?.trim() &&
              feOE == item.objectOfExpenditure?.trim()) {
            matchingFe = fe;
            break;
          }
        }

        final targetFe =
            matchingFe ??
            (fundSourceEntries.isNotEmpty ? fundSourceEntries.first : null);
        if (targetFe != null) {
          final entry = BreakdownEntry(
            name: item.name,
            amount: item.amount > 0
                ? CurrencyInputFormatter.formatDouble(item.amount)
                : '',
            supplier: item.supplier ?? '',
            status: item.status ?? '',
          );
          entry.amountCtl.addListener(updateTotalBudget);
          targetFe.breakdownItems.add(entry);
        }
      }
    }

    // Recalculate Approved Budget from fund sources so it's always in sync
    // This runs after initializeData, wiring happens in initState.
    // We call a post-frame callback to let listeners be registered first.
  }

  Future<void> loadData() async {
    try {
      final staff = await widget.fbService.getAvailableStaff();
      // Also fetch suppliers for autocomplete
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

      if (mounted) {
        setState(() {
          availableStaff = staff.where((s) => s != 'Other').toList();
          availableSuppliers = suppSet.toList()..sort();
          final a = widget.activity;
          responsiblePerson = staff.contains(a.responsiblePerson)
              ? a.responsiblePerson
              : 'Other';
          if (responsiblePerson == 'Other') {
            customResponsiblePersonCtl.text = a.responsiblePerson;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
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
    customStatusDateCtl.dispose();
    otherMoeSuppliersCtl.dispose();
    statusAppropDateCtl.dispose();
    actualConductCtl.dispose();
    accommRemarksCtl.dispose();

    for (var e in fundSourceEntries) {
      e.dispose();
    }
    super.dispose();
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

  // ── Modern Title Bar ─────────────────────────────────────────────────────────
  Widget buildTitleBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [modernGreen, modernDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: modernGreen.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_document, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Activity',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'AgriWork & Financial Planning System (AWFPS)',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                context.read<ActivityFormProvider>().minimizeForm(),
            icon: const Icon(Icons.remove_rounded, color: Colors.white70),
            tooltip: 'Minimize',
          ),
          IconButton(
            onPressed: handleClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            tooltip: isEdited ? 'Discard' : 'Close',
          ),
        ],
      ),
    );
  }

  // ── Section Header (accent bar + bold text) ──────────────────
  Widget buildSectionHeader(String col, String title) {
    rowIndex = 0; // reset row counter per section
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: labelBg,
        border: Border(left: BorderSide(color: modernGreen, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: modernGreen,
              shape: BoxShape.circle,
            ),
            child: Text(
              col,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: modernDark,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
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
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: labelBg,
                border: Border(right: BorderSide(color: border, width: 0.8)),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                fieldLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: labelText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Input widget
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: cell,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration cellDec([String? hint]) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.black26),
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

  InputDecorationTheme cellTheme() => InputDecorationTheme(
    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.black26),
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
      fontSize: 13,
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

  Widget numberCell(TextEditingController c) => TextFormField(
    controller: c,
    keyboardType: TextInputType.number,
    style: const TextStyle(
      fontSize: 13,
      color: textMain,
      fontWeight: FontWeight.w600,
    ),
    decoration: cellDec('0'),
  );

  Widget currencyCell(
    TextEditingController c, {
    bool readOnly = false,
    String? hint,
    bool isPO = false,
  }) => TextFormField(
    controller: c,
    readOnly: readOnly,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [CurrencyInputFormatter()],
    style: TextStyle(
      fontSize: 13,
      color: isPO
          ? const Color(0xFF1565C0)
          : (readOnly ? Colors.grey[700] : modernDark),
      fontWeight: FontWeight.bold,
    ),
    decoration: cellDec(hint ?? '0.00').copyWith(
      filled: true,
      fillColor: readOnly ? Colors.grey[100] : Colors.white,
      prefixIcon: isPO
          ? const Icon(
              Icons.shopping_cart_outlined,
              size: 14,
              color: Color(0xFF1565C0),
            )
          : null,
    ),
    onTapOutside: (_) {
      if (c.text.isNotEmpty) {
        c.text = CurrencyInputFormatter.formatDouble(
          CurrencyInputFormatter.parse(c.text),
        );
      }
    },
    onFieldSubmitted: (val) {
      if (val.isNotEmpty) {
        c.text = CurrencyInputFormatter.formatDouble(
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
                    (s) => DropdownMenuEntry(value: s, label: s),
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
      label: hint != null ? Text(hint) : null,
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
          label: opt?.toString() ?? 'N/A',
        );
      }).toList(),
      onSelected: onChanged,
    );
  }

  Widget buildSectorCell() {
    return dropdownCell<String>(
      value: AppConstants.sectors.contains(sector) ? sector : null,
      options: AppConstants.sectors,
      onChanged: (val) {
        if (val == null) return;
        final oldSector = sector;
        setState(() {
          sector = val;
          if (val != 'Crop Section') subSector = null;

          final oldApprop = '$oldSector Appropriation';
          final newApprop = '$val Appropriation';

          // Update Fund Source entries
          for (var e in fundSourceEntries) {
            if (e.objectOfExpenditure == oldApprop ||
                e.objectOfExpenditure == 'Other-MOE Expenses') {
              if (AppConstants.objectsOfExpenditure.contains(newApprop)) {
                e.objectOfExpenditure = newApprop;
              } else {
                e.objectOfExpenditure = 'Other-MOE Expenses';
              }
            }
          }
        });
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
      value: selectedStatus.isEmpty ? null : selectedStatus,
      options: statusOptions,
      hint: 'Select Status',
      onChanged: (val) {
        if (val != null) {
          setState(() {
            selectedStatus = val;
          });
        }
      },
    );
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
                      width: 42,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'C${idx + 1}',
                          style: const TextStyle(
                            fontSize: 11,
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
                                const SizedBox(width: 8),
                                if (fundSourceEntries.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() {
                                      final removed = fundSourceEntries
                                          .removeAt(idx);
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
      value:
          (availableStaff.contains(responsiblePerson) ||
              responsiblePerson == 'Other')
          ? responsiblePerson
          : null,
      options: [
        ...availableStaff,
        'Other',
      ],
      onChanged: (val) => setState(() {
        if (val != null) responsiblePerson = val;
      }),
    );
  }

  Widget buildMonthCell() => dropdownCell<String>(
    value: selectedMonth,
    options: months,
    onChanged: (val) => setState(() {
      if (val != null) selectedMonth = val;
    }),
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
    onChanged: (val) => setState(() {
      if (val != null) selectedYear = val;
    }),
  );

  // ── Breakdown Table ─────────────────────────────────────────────────────────
  Widget buildNestedBreakdown(FundSourceEntry fe) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: modernGreen.withValues(alpha: 0.05),
          child: Row(
            children: [
              const Icon(Icons.list_alt, size: 13, color: modernGreen),
              const SizedBox(width: 5),
              const Text(
                'EXPENDITURE BREAKDOWN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: modernGreen,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
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
                SizedBox(width: 20),
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
                SizedBox(width: 4),
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
                SizedBox(width: 24),
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
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
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
                            be.amountCtl.removeListener(updateTotalBudget);
                            be.dispose();
                            fe.breakdownItems.removeAt(bIdx);
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
                        mobileBreakdownField(
                          'Description',
                          TextFormField(
                            controller: be.nameCtl,
                            style: const TextStyle(fontSize: 12),
                            decoration: compactDec('Description...'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        mobileBreakdownField(
                          'PO Amount',
                          currencyCell(be.amountCtl, hint: '0.00'),
                        ),
                        const SizedBox(height: 8),
                        mobileBreakdownField(
                          'Supplier',
                          TextFormField(
                            controller: be.supplierCtl,
                            style: const TextStyle(fontSize: 12),
                            decoration: compactDec('Supplier...').copyWith(
                              suffixIcon: availableSuppliers.isEmpty
                                  ? null
                                  : PopupMenuButton<String>(
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 20,
                                      ),
                                      onSelected: (v) => setState(
                                        () => be.supplierCtl.text = v,
                                      ),
                                      itemBuilder: (ctx) => availableSuppliers
                                          .map(
                                            (s) => PopupMenuItem(
                                              value: s,
                                              child: Text(
                                                s,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        mobileBreakdownField(
                          'Status',
                          breakdownDropdown<String>(
                            value: be.statusCtl.text.isEmpty
                                ? ''
                                : (AppConstants.activityStatuses.contains(be.statusCtl.text)
                                    ? be.statusCtl.text
                                    : ''),
                            options: ['', ...AppConstants.activityStatuses],
                            onChanged: (v) => setState(() => be.statusCtl.text = v ?? ''),
                          ),
                        ),
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
                  child: currencyCell(be.amountCtl, hint: '0.00'),
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
                                        style: const TextStyle(fontSize: 11),
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
                    onChanged: (val) => setState(() => be.statusCtl.text = val ?? ''),
                    useCompact: true,
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 14, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() {
                      be.amountCtl.removeListener(updateTotalBudget);
                      be.dispose();
                      fe.breakdownItems.removeAt(bIdx);
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
                            CurrencyInputFormatter.parse(item.amountCtl.text),
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
                  child: SizedBox(),
                ), // spacer for supplier/status
                const SizedBox(width: 24),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => setState(() {
              final lastEntry = fe.breakdownItems.isNotEmpty ? fe.breakdownItems.last : null;
              final newEntry = BreakdownEntry(
                supplier: lastEntry?.supplierCtl.text,
                status: lastEntry?.statusCtl.text,
              );
              newEntry.amountCtl.addListener(updateTotalBudget);
              fe.breakdownItems.add(newEntry);
              updateTotalBudget();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: modernGreen.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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
          label: opt?.toString() ?? '—',
        );
      }).toList(),
    onSelected: onChanged,
  );

  InputDecoration compactDec([String? hint]) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 10, color: Colors.black26),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      borderSide: const BorderSide(color: modernGreen, width: 1.2),
    ),
    errorStyle: const TextStyle(height: 0),
  );

  // ── Footer ──────────────────────────────────────────────────────────────────
  Widget buildFooter() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: delete,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            label: Text(
              'Delete Activity',
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: handleClose,
            child: Text(
              'Discard',
              style: GoogleFonts.inter(
                color: labelText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (saving)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: modernGreen),
            )
          else
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => onSave(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: modernGreen,
                    side: const BorderSide(color: modernGreen, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Save Draft',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [modernGreen, modernDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: modernGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => onSave(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Update Activity',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void onSave(bool asDraft) {
    if (!asDraft && !formKey.currentState!.validate()) return;
    save(asDraft);
  }

  Widget buildRowPair(Widget left, Widget right) {
    final width = MediaQuery.of(context).size.width;
    // The dialog is approx 95% of screen width. Use 700 as a more comfortable breakpoint for side-by-side rows
    if (width < 700) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          Container(height: 1, color: border),
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

  @override
  Widget build(BuildContext context) {
    rowIndex = 0;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await handleClose();
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: const BoxConstraints(maxWidth: 1200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            buildTitleBar(),
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
                                  currencyCell(ppmpAmountCtl),
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
                            ],
                          ),
                        ),
                        Container(height: 1, color: border),
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
                              xlRow('PR2', 'PR', currencyCell(prAmountCtl)),
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
                              buildSectionHeader('E', 'SCHEDULE & STATUS'),
                              xlRow(
                                'E1',
                                'Date / Status',
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: dateCell(customStatusDateCtl),
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
                              xlRow('E$rowIndex', 'Year', buildYearCell()),
                              xlRow(
                                'E$rowIndex',
                                'Remarks',
                                textCell(remarksCtl, maxLines: 2),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 1, color: border),
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
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildSectionHeader('F', 'FINANCIAL BREAKDOWN'),
                              buildBreakdownsSection(),
                            ],
                          ),
                        ),
                        Container(height: 1, color: border),
                        buildRowPair(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildSectionHeader('G', 'ACCOMPLISHMENT'),
                              xlRow(
                                'G1',
                                'Actual Conduct',
                                textCell(actualConductCtl, maxLines: 2),
                              ),
                              xlRow(
                                'G2',
                                'Remarks (ACCOM)',
                                textCell(accommRemarksCtl, maxLines: 2),
                              ),
                            ],
                          ),
                          const SizedBox.shrink(),
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

  Future<void> handleClose() async {
    if (!isEdited) {
      if (mounted) {
        context.read<ActivityFormProvider>().closeForm();
      }
      return;
    }
    final confirmed = await showDialog<bool>(
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
    if (confirmed == true && mounted) {
      context.read<ActivityFormProvider>().closeForm();
    }
  }

  Future<void> save(bool asDraft) async {
    if (saving) return;

    // Force re-calculation before saving to ensure controllers are in sync
    updateTotalBudget();
    final authService = context.read<AuthService>();
    final userName = authService.currentUser?.name ?? 'Admin';
    setState(() => saving = true);
    try {
      final a = widget.activity;
      final budgetValue = CurrencyInputFormatter.parse(budgetCtl.text);

      String finalSector = sector == 'Other'
          ? customSectorCtl.text.trim()
          : sector;
      String finalSubSector = sector == 'Crop Section'
          ? (subSector == 'Other'
                ? customSubSectorCtl.text.trim()
                : subSector ?? '')
          : '';
      String finalResponsible = responsiblePerson == 'Other'
          ? customResponsiblePersonCtl.text.trim()
          : responsiblePerson;

      String finalStatusStr = selectedStatus == 'Other'
          ? customStatusCtl.text.trim()
          : selectedStatus;

      String targetDateStr = selectedMonth;
      if (selectedToMonth != null) targetDateStr += '-$selectedToMonth';
      targetDateStr += ' $selectedYear';

      final activityName = activityNameCtl.text.trim();

      // Check for duplicates
      final isDuplicate = await widget.fbService.checkDuplicateActivity(
        activityName,
        finalSector,
        targetDateStr,
        excludeId: widget.activity.id,
      );

      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Another activity with this name, sector, and target date already exists.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => saving = false);
        }
        return;
      }

      final List<BreakdownItem> breakdownList = [];
      for (var fe in fundSourceEntries) {
        final fs =
            (fe.fundingSource == 'Other'
                    ? fe.customFundingSourceCtl.text.trim()
                    : fe.fundingSource)
                .trim();
        final oe = (fe.objectOfExpenditure == 'Other'
            ? fe.customObjectOfExpenditureCtl.text.trim()
            : fe.objectOfExpenditure);

        for (var b in fe.breakdownItems) {
          final bName = b.nameCtl.text.trim();
          final bAmount = CurrencyInputFormatter.parse(b.amountCtl.text);
          if (bName.isNotEmpty || bAmount > 0) {
            breakdownList.add(
              BreakdownItem(
                name: bName,
                amount: bAmount,
                fundingSource: fs,
                objectOfExpenditure: oe,
                supplier: b.supplierCtl.text.trim().isNotEmpty
                    ? b.supplierCtl.text.trim()
                    : '',
                status: b.statusCtl.text.trim().isNotEmpty
                    ? b.statusCtl.text.trim()
                    : '',
              ),
            );
          }
        }
      }

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

      // Determine quarterly allocation based on selected month range
      final divisor = selectedToMonth == null
          ? 1
          : calculateQuartersInRange();
      final share = budgetValue / divisor;

      final ms = [
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
      bool inRange(List<String> months) {
        return months.contains(selectedMonth) ||
            (selectedToMonth != null &&
                months.any(
                  (m) =>
                      ms.indexOf(m) >= ms.indexOf(selectedMonth) &&
                      ms.indexOf(m) <= ms.indexOf(selectedToMonth!),
                ));
      }

      double q1 = inRange(['January', 'February', 'March']) ? share : 0;
      double q2 = inRange(['April', 'May', 'June']) ? share : 0;
      double q3 = inRange(['July', 'August', 'September']) ? share : 0;
      double q4 = inRange(['October', 'November', 'December']) ? share : 0;

      // Derive primary funding source from fund sources list
      final primaryFs = fundSources.isNotEmpty
          ? fundSources.first.fundingSource
          : (fundSourceEntries.isNotEmpty
                ? (fundSourceEntries.first.fundingSource == 'Other'
                      ? fundSourceEntries.first.customFundingSourceCtl.text
                            .trim()
                      : fundSourceEntries.first.fundingSource)
                : 'Agri MOOE');
      final primaryOe = fundSources.isNotEmpty
          ? fundSources.first.objectOfExpenditure
          : '';

      final totalPOAmount = breakdownList.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );

      final updated = a.copyWith(
        sector: finalSector,
        subSector: finalSubSector,
        activityName: activityNameCtl.text.trim(),
        unitHead: unitHeadCtl.text.trim(),
        performanceIndicator: performanceIndicatorCtl.text.trim(),
        location: locationCtl.text.trim(),
        targetNo: int.tryParse(targetNoCtl.text) ?? 1,
        targetParticipants: targetParticipantsCtl.text.trim(),
        status: finalStatusStr,
        statusDate: customStatusDateCtl.text.trim(),
        targetDate: targetDateStr,
        responsiblePerson: finalResponsible,
        q1Budget: q1,
        q2Budget: q2,
        q3Budget: q3,
        q4Budget: q4,
        ppmpAmount: CurrencyInputFormatter.parse(ppmpAmountCtl.text),
        ppmpBalance: CurrencyInputFormatter.parse(ppmpCtl.text),
        prAmount: CurrencyInputFormatter.parse(prAmountCtl.text),
        prBalance: CurrencyInputFormatter.parse(prBalanceCtl.text),
        prNumber: prNumberCtl.text.trim(),
        supplierApprop: supplierAppropCtl.text.trim(),
        barcodeApprop: barcodeAppropCtl.text.trim(),
        statusApprop: statusAppropCtl.text.trim(),
        statusAppropDate: statusAppropDateCtl.text.trim(),
        actualConduct: actualConductCtl.text.trim(),
        accommRemarks: accommRemarksCtl.text.trim(),
        remarks: remarksCtl.text.trim(),
        fundingSource: primaryFs,
        objectOfExpenditure: primaryOe,
        otherMoeSuppliers: otherMoeSuppliersCtl.text.trim(),
        actualExpenditure: totalPOAmount,
        breakdown: breakdownList,
        fundSources: fundSources,
        fundingInputtedBy: primaryFs != a.fundingSource
            ? userName
            : a.fundingInputtedBy,
        statusInputtedBy: finalStatusStr != a.status
            ? userName
            : a.statusInputtedBy,
        isDraft: asDraft,
      );

      await widget.fbService.updateActivity(updated);

      // Create PR log if changes occurred
      final newPrNumber = prNumberCtl.text.trim();
      final newPrAmount = CurrencyInputFormatter.parse(prAmountCtl.text);
      final newPrStatus = statusAppropCtl.text.trim();

      if (newPrNumber != a.prNumber ||
          newPrAmount != a.prAmount ||
          newPrStatus != a.statusApprop) {
        String remarks = '';
        if (newPrStatus != a.statusApprop && a.statusApprop.isNotEmpty) {
          remarks = 'Status: ${a.statusApprop} ➔ $newPrStatus. ';
        } else if (newPrStatus != a.statusApprop) {
          remarks = 'Initial Status: $newPrStatus. ';
        }

        if (newPrNumber != a.prNumber && a.prNumber.isNotEmpty) {
          remarks += 'PR# changed from ${a.prNumber} ➔ $newPrNumber. ';
        }

        await widget.fbService.addPRLog(
          PRLog(
            id: '',
            activityId: a.id,
            status: newPrStatus,
            prNumber: newPrNumber,
            amount: newPrAmount,
            remarks: remarks.trim(),
            timestamp: DateTime.now(),
            updatedBy: userName,
          ),
        );
      }
      if (mounted) {
        context.read<ActivityFormProvider>().closeForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              asDraft ? 'Saved as Draft' : 'Changes Saved Successfully',
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

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Delete Activity'),
        content: Text(
          'Are you sure you want to delete "${widget.activity.activityName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await widget.fbService.deleteActivity(widget.activity.id);
        if (mounted) {
          context.read<ActivityFormProvider>().closeForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete error: $e')));
        }
      }
    }
  }
}
