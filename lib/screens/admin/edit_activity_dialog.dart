import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/currency_formatter.dart';
import '../../widgets/skeleton_loading.dart';
import '../../models/activity.dart';
import '../../models/pr_log.dart';
import '../../services/activity_form_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/grid_form_fields.dart';
import '../../widgets/enhanced_buttons_dialogs.dart';

// ── Modern design constants ─────────────────────────────────────────────
const modernGreen = Color(0xFF1B5E20);
const modernDark = Color(0xFF064E3B);
const headerBg = Color(0xFFF1F8E9);
const rowOdd = Color(0xFFFFFFFF);
const rowEven = Color(0xFFF9FBF7);
const border = Color(0xFFE2E8F0);
const textMain = Color(0xFF1E293B);
const labelBg = Color(0xFFF8FAFC);
const labelText = Color(0xFF475569);

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
  final targetParticipantsCtl = TextEditingController();
  final remarksCtl = TextEditingController();
  final customSectorCtl = TextEditingController();
  final customSubSectorCtl = TextEditingController();
  final customResponsiblePersonCtl = TextEditingController();
  final customStatusCtl = TextEditingController();
  final customStatusDateCtl = TextEditingController();
  final otherMoeSuppliersCtl = TextEditingController();
  final statusAppropDateCtl = TextEditingController();
  final accountCodeCtl = TextEditingController();
  final inputtedAmountCtl = TextEditingController();
  final totalProcurementCtl = TextEditingController();
  List<PRLog> prLogs = [];

  // Accomplishment fields
  final actualConductCtl = TextEditingController();
  final accommRemarksCtl = TextEditingController();

  late String selectedMonth;
  String? selectedToMonth;
  late String selectedYear;
  late String responsiblePerson;
  late String selectedStatus;

  List<String> availableStaff = AppConstants.staffList;
  List<String> availableSuppliers = [];
  bool saving = false;
  final bool canPop = false;
  final List<FundSourceEntry> fundSourceEntries = [];

  final List<String> months = AppConstants.months;
  final List<String> years = AppConstants.years;

  int rowIndex = 0;
  Color get nextRowColor {
    final c = rowIndex.isOdd ? rowEven : rowOdd;
    rowIndex++;
    return c;
  }

  // ── UI Helper Methods (Grid Wrappers) ───────────────────────────────────────
  Widget textCell(
    TextEditingController ctl, {
    int maxLines = 1,
    String? hint,
  }) => GridTextField(controller: ctl, maxLines: maxLines, hint: hint);

  Widget numberCell(TextEditingController ctl, {String? hint}) => GridTextField(
    controller: ctl,
    keyboardType: TextInputType.number,
    hint: hint,
  );

  Widget currencyCell(
    TextEditingController ctl, {
    bool readOnly = false,
    String? hint,
  }) => GridCurrencyField(controller: ctl, readOnly: readOnly, hint: hint);

  Widget dropdownCell<T>({
    required T? value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) => GridDropdown<T>(
    value: value,
    options: options,
    onChanged: onChanged,
    hint: hint,
  );

  Widget unitCell(TextEditingController ctl, {bool isCompact = true}) =>
      GridAutocompleteField(
        controller: ctl,
        options: AppConstants.commonUnits,
        hint: 'unit',
        isCompact: isCompact,
      );

  Widget supplierCell(
    TextEditingController ctl, {
    bool allowsMultiple = false,
  }) => GridSupplierField(
    controller: ctl,
    availableSuppliers: availableSuppliers,
    allowsMultiple: allowsMultiple,
  );

  Widget barcodeCell(TextEditingController ctl) => GridBarcodeField(
    controller: ctl,
    barcodeBuilder: (data) => BarcodeWidget(
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

  Widget breakdownDropdown<T>({
    required T? value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) => GridBreakdownDropdown<T>(
    value: value,
    options: options,
    onChanged: onChanged,
    hint: hint,
  );

  InputDecorationTheme cellTheme() => InputDecorationTheme(
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
  );

  @override
  void initState() {
    super.initState();
    initializeData();
    loadData();

    // Listeners for financial calculations
    prAmountCtl.addListener(() {
      updatePPMPBalance();
      updatePRBalance();
    });

    for (var entry in fundSourceEntries) {
      entry.amountCtl.addListener(updateTotalBudget);
      entry.customFundingSourceCtl.addListener(() => setState(() {}));
      entry.customObjectOfExpenditureCtl.addListener(() => setState(() {}));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) updateTotalBudget();
    });
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
    ppmpCtl.text = CurrencyInputFormatter.formatDouble(a.ppmpBalance);

    prAmountCtl.text = CurrencyInputFormatter.formatDouble(a.prAmount);
    prBalanceCtl.text = CurrencyInputFormatter.formatDouble(a.prBalance);
    prNumberCtl.text = a.prNumber;
    inputtedAmountCtl.text = a.inputtedAmount > 0
        ? CurrencyInputFormatter.formatDouble(a.inputtedAmount)
        : '';
    prLogs = List.from(a.prLogs);
    _updateTotalProcurement();
    supplierAppropCtl.text = a.supplierApprop;
    barcodeAppropCtl.text = a.barcodeApprop;
    targetParticipantsCtl.text = a.targetParticipants;
    remarksCtl.text = a.remarks;
    actualConductCtl.text = a.actualConduct;
    accommRemarksCtl.text = a.accommRemarks;
    accountCodeCtl.text = a.accountCode ?? '';
    otherMoeSuppliersCtl.text = a.otherMoeSuppliers;

    final isStaff = AppConstants.staffList.contains(a.responsiblePerson);
    responsiblePerson = isStaff ? a.responsiblePerson : 'Other';
    if (!isStaff) {
      customResponsiblePersonCtl.text = a.responsiblePerson;
    }

    selectedStatus = AppConstants.activityStatuses.contains(a.status)
        ? a.status
        : 'Other';
    if (selectedStatus == 'Other') customStatusCtl.text = a.status;

    // Target Date Parsing
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

    // Fund Sources Initialization
    if (a.fundSources.isNotEmpty) {
      for (var fs in a.fundSources) {
        final entry = FundSourceEntry(
          amount: CurrencyInputFormatter.formatDouble(fs.amount),
        );
        String fsKey = fs.fundingSource;
        if (!AppConstants.fundingSources.contains(fsKey) && fsKey != 'Other') {
          entry.customFundingSourceCtl.text = fsKey;
          fsKey = 'Other';
        }
        entry.fundingSource = fsKey;

        String? oe = fs.objectOfExpenditure;
        if (!AppConstants.objectsOfExpenditure.contains(oe) &&
            oe != 'Other' &&
            oe != 'Other-MOE Expenses') {
          entry.customObjectOfExpenditureCtl.text = oe ?? '';
          oe = 'Other';
        }
        entry.objectOfExpenditure = oe ?? 'Other-MOE Expenses';
        fundSourceEntries.add(entry);
      }
    } else {
      final entry = FundSourceEntry(amount: budgetCtl.text);
      entry.fundingSource =
          AppConstants.fundingSources.contains(a.fundingSource)
          ? a.fundingSource
          : 'Other';
      if (entry.fundingSource == 'Other') {
        entry.customFundingSourceCtl.text = a.fundingSource;
      }
      entry.objectOfExpenditure = a.objectOfExpenditure ?? 'Other-MOE Expenses';
      fundSourceEntries.add(entry);
    }

    // Breakdown Initialization
    if (a.breakdown.isNotEmpty) {
      for (var item in a.breakdown) {
        FundSourceEntry? targetFe;
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
            targetFe = fe;
            break;
          }
        }
        targetFe ??= fundSourceEntries.isNotEmpty
            ? fundSourceEntries.first
            : null;
        if (targetFe != null) {
          final entry = BreakdownEntry(
            name: item.name,
            amount: item.amount,
            unit: item.unit,
            quantity: item.quantity ?? 0.0,
            price: item.price ?? 0.0,
            q1Qty: item.q1Qty ?? 0.0,
            q2Qty: item.q2Qty ?? 0.0,
            q3Qty: item.q3Qty ?? 0.0,
            q4Qty: item.q4Qty ?? 0.0,
            supplier: item.supplier ?? '',
            status: item.status ?? '',
            statusDate: item.statusDate ?? '',
          );
          entry.amountCtl.addListener(updateTotalBudget);
          targetFe.breakdownItems.add(entry);
        }
      }
    }
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
        if (supp is String && supp.trim().isNotEmpty) {
          suppSet.addAll(supp.split(',').map((s) => s.trim()));
        }
      }
      if (mounted) {
        setState(() {
          availableStaff = staff.where((s) => s != 'Other').toList();
          availableSuppliers = suppSet.toList()..sort();
        });
      }
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
    targetParticipantsCtl.dispose();
    remarksCtl.dispose();
    customSectorCtl.dispose();
    customSubSectorCtl.dispose();
    customResponsiblePersonCtl.dispose();
    otherMoeSuppliersCtl.dispose();
    accountCodeCtl.dispose();
    customStatusCtl.dispose();
    customStatusDateCtl.dispose();
    statusAppropDateCtl.dispose();
    inputtedAmountCtl.dispose();
    totalProcurementCtl.dispose();
    actualConductCtl.dispose();
    accommRemarksCtl.dispose();
    for (var e in fundSourceEntries) {
      e.dispose();
    }
    super.dispose();
  }

  double get totalBreakdownAmount {
    double total = 0;
    for (var fe in fundSourceEntries) {
      for (var b in fe.breakdownItems) {
        total += CurrencyInputFormatter.parse(b.amountCtl.text);
      }
    }
    return total;
  }

  void _updateTotalProcurement() {
    double total = 0;
    for (var log in prLogs) {
      total += log.prAmount;
    }
    totalProcurementCtl.text = CurrencyInputFormatter.formatDouble(total);
    updatePPMPBalance();
  }

  void updatePPMPBalance() {
    final budget = CurrencyInputFormatter.parse(
      inputtedAmountCtl.text.isNotEmpty
          ? inputtedAmountCtl.text
          : budgetCtl.text,
    );
    final prAmount = CurrencyInputFormatter.parse(totalProcurementCtl.text);
    final balance = budget - prAmount;
    ppmpCtl.text = CurrencyInputFormatter.formatDouble(balance);
  }

  void updatePRBalance() {
    // Legacy support or internal balance check
    final prAmount = CurrencyInputFormatter.parse(totalProcurementCtl.text);
    final poAmount = totalBreakdownAmount;
    prBalanceCtl.text = CurrencyInputFormatter.formatDouble(
      prAmount - poAmount,
    );
  }

  void updateTotalBudget() {
    double grandTotal = 0;
    for (var entry in fundSourceEntries) {
      if (entry.breakdownItems.isNotEmpty) {
        double entryTotal = 0;
        for (var b in entry.breakdownItems) {
          entryTotal += CurrencyInputFormatter.parse(b.amountCtl.text);
        }
        entry.amountCtl.text = CurrencyInputFormatter.formatDouble(entryTotal);
        grandTotal += entryTotal;
      } else {
        grandTotal += CurrencyInputFormatter.parse(entry.amountCtl.text);
      }
    }
    budgetCtl.text = CurrencyInputFormatter.formatDouble(grandTotal);
    updatePPMPBalance();
    updatePRBalance();
  }

  bool get isEdited {
    final a = widget.activity;
    return activityNameCtl.text.trim() != a.activityName ||
        sector != a.sector ||
        subSector != a.subSector ||
        CurrencyInputFormatter.parse(budgetCtl.text) != a.totalBudget;
  }

  Future<void> handleClose() async {
    if (!isEdited ||
        (await showDialog<bool>(
              context: context,
              barrierColor: Colors.transparent,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
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
            ) ==
            true)) {
      if (mounted) context.read<ActivityFormProvider>().closeForm();
    }
  }

  // ── UI Builders ───────────────────────────────────────────────────────────

  Widget buildRowPair(Widget left, Widget right) {
    if (MediaQuery.of(context).size.width < 700) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [left, right],
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
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await handleClose();
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            buildTitleBar(),
            buildMenuBar(),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      buildRowPair(
                        Column(
                          children: [
                            const GridSectionHeader(
                              label: 'A',
                              title: 'CLASSIFICATION',
                            ),
                            GridRow(
                              label: 'A1',
                              fieldLabel: 'Section / Unit',
                              child: buildSectorCell(),
                            ),
                            if (sector == 'Other')
                              GridRow(
                                label: 'A2',
                                fieldLabel: 'Custom Sector',
                                child: GridTextField(
                                  controller: customSectorCtl,
                                  tooltip: 'Enter the custom section or unit name.',
                                ),
                              ),
                            if (sector == 'Crop Section') ...[
                              GridRow(
                                label: 'A2',
                                fieldLabel: 'Crop Program',
                                child: buildSubSectorCell(),
                              ),
                              if (subSector == 'Other')
                                GridRow(
                                  label: 'A3',
                                  fieldLabel: 'Custom Program',
                                  child: GridTextField(
                                    controller: customSubSectorCtl,
                                    tooltip: 'Enter the custom crop program name.',
                                  ),
                                ),
                            ],
                            GridRow(
                              label: 'A4',
                              fieldLabel: 'Unit Head',
                              child: GridTextField(
                                controller: unitHeadCtl,
                                tooltip: 'Name of the unit head responsible.',
                              ),
                            ),
                            GridRow(
                              label: 'A5',
                              fieldLabel: 'Activity Name',
                              child: GridTextField(
                                controller: activityNameCtl,
                                tooltip: 'The official name of this activity.',
                              ),
                            ),
                            GridRow(
                              label: 'A6',
                              fieldLabel: 'Account Code',
                              child: GridTextField(
                                controller: accountCodeCtl,
                                tooltip: 'Primary accounting code for the whole activity.',
                              ),
                            ),
                            GridRow(
                              label: 'A7',
                              fieldLabel: 'Location',
                              child: GridTextField(
                                controller: locationCtl,
                                tooltip: 'Venue or implementation site.',
                              ),
                            ),
                            GridRow(
                              label: 'A8',
                              fieldLabel: 'Indicator',
                              child: GridTextField(
                                controller: performanceIndicatorCtl,
                                tooltip: 'How success or output is measured.',
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const GridSectionHeader(
                              label: 'B',
                              title: 'TARGETS & BUDGET',
                            ),
                            GridRow(
                              label: 'B1',
                              fieldLabel: 'Target No.',
                              child: GridTextField(
                                controller: targetNoCtl,
                                keyboardType: TextInputType.number,
                                tooltip: 'Number of units, participants, or targets.',
                              ),
                            ),
                            GridRow(
                              label: 'B2',
                              fieldLabel: 'Approved Budget (Ref)',
                              child: GridCurrencyField(
                                controller: budgetCtl,
                                readOnly: true,
                                tooltip: 'Reference budget calculated from breakdowns.',
                              ),
                            ),
                            GridRow(
                              label: 'B3',
                              fieldLabel: 'PPMP Amount',
                              child: GridCurrencyField(
                                controller: ppmpAmountCtl,
                                tooltip: 'Allocated amount in the PPMP.',
                              ),
                            ),
                            GridRow(
                              label: 'B4',
                              fieldLabel: 'Inputted Amount (Override)',
                              helpText:
                                  'Manually set the approved budget if needed.',
                              child: GridCurrencyField(
                                controller: inputtedAmountCtl,
                                onChanged: (v) => updatePPMPBalance(),
                                tooltip: 'Override the calculated budget with this manual value.',
                              ),
                            ),
                            GridRow(
                              label: 'B5',
                              fieldLabel: 'PPMP Balance (Auto)',
                              child: GridCurrencyField(
                                controller: ppmpCtl,
                                readOnly: true,
                                tooltip: 'Remaining balance after procurement logs.',
                              ),
                            ),
                            GridRow(
                              label: 'B6',
                              fieldLabel: 'Participants',
                              child: GridTextField(
                                controller: targetParticipantsCtl,
                                tooltip: 'Detailed description of target participants.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      buildRowPair(
                        Column(
                          children: [
                            const GridSectionHeader(
                              label: 'C',
                              title: 'PROCUREMENT TRACKING',
                            ),
                            ...prLogs.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final log = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: 12,
                                  left: 16,
                                  right: 16,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: border),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'PR #${idx + 1}',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: modernGreen,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Tooltip(
                                          message: 'Delete this PR log.',
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            onPressed: () => setState(() {
                                              prLogs.removeAt(idx);
                                              _updateTotalProcurement();
                                            }),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    GridDualRow(
                                      label: '',
                                      fieldLabel1: 'PR Number',
                                      child1: GridTextField(
                                        initialValue: log.prNumber,
                                        onChanged: (v) => log.prNumber = v,
                                        isCompact: true,
                                      ),
                                      fieldLabel2: 'PR Amount',
                                      child2: GridCurrencyField(
                                        initialValue: log.prAmount,
                                        onChanged: (v) {
                                          log.prAmount = v;
                                          _updateTotalProcurement();
                                        },
                                        isCompact: true,
                                      ),
                                    ),
                                    GridDualRow(
                                      label: '',
                                      fieldLabel1: 'Status',
                                      child1: GridDropdown<String>(
                                        value:
                                            AppConstants.prStatuses.contains(
                                              log.status,
                                            )
                                            ? log.status
                                            : AppConstants.statusPRStage,
                                        options: AppConstants.prStatuses,
                                        onChanged: (v) =>
                                            setState(() => log.status = v!),
                                        isCompact: true,
                                      ),
                                      fieldLabel2: 'Status Date',
                                      child2: GridDateField(
                                        initialValue: log.statusDate,
                                        onChanged: (v) => log.statusDate = v,
                                        isCompact: true,
                                      ),
                                    ),
                                    GridDualRow(
                                      label: '',
                                      fieldLabel1: 'PO Number',
                                      child1: GridTextField(
                                        initialValue: log.poNumber,
                                        onChanged: (v) => log.poNumber = v,
                                        isCompact: true,
                                      ),
                                      fieldLabel2: 'PO Amount',
                                      child2: GridCurrencyField(
                                        initialValue: log.poAmount,
                                        onChanged: (v) {
                                          log.poAmount = v;
                                          _updateTotalProcurement();
                                        },
                                        isCompact: true,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: EnhancedButton(
                                onPressed: () => setState(() {
                                  prLogs.add(
                                    PRLog(
                                      id: DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                      activityId: widget.activity.id,
                                      status: AppConstants.statusPRStage,
                                      prNumber: '',
                                      prAmount: 0,
                                      statusDate: DateTime.now()
                                          .toString()
                                          .split(' ')
                                          .first,
                                      timestamp: DateTime.now(),
                                      updatedBy:
                                          context
                                              .read<AuthService>()
                                              .currentUser
                                              ?.name ??
                                          'Admin',
                                    ),
                                  );
                                  _updateTotalProcurement();
                                }),
                                icon: const Icon(Icons.add_circle_outline),
                                label: 'Add Purchase Request',
                                variant: ButtonVariant.secondary,
                                tooltip: 'Add a new Purchase Request log to track procurement.',
                              ),
                            ),
                            GridRow(
                              label: 'C3',
                              fieldLabel: 'Total Procurement',
                              child: GridCurrencyField(
                                controller: totalProcurementCtl,
                                readOnly: true,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const GridSectionHeader(
                              label: 'D',
                              title: 'ASSIGNMENT & STATUS',
                            ),
                            GridRow(
                              label: 'D1',
                              fieldLabel: 'Responsible',
                              child: buildResponsiblePersonCell(),
                            ),
                            if (responsiblePerson == 'Other')
                              GridRow(
                                label: 'D2',
                                fieldLabel: 'Custom Person',
                                child: GridTextField(
                                  controller: customResponsiblePersonCtl,
                                ),
                              ),
                            GridRow(
                              label: 'D3',
                              fieldLabel: 'Activity Status',
                              helpText: 'Overall status of the activity.',
                              child: buildStatusCell(),
                            ),
                            if (selectedStatus == 'Other')
                              GridRow(
                                label: 'D4',
                                fieldLabel: 'Custom Status',
                                child: GridTextField(
                                  controller: customStatusCtl,
                                ),
                              ),
                            GridRow(
                              label: 'D5',
                              fieldLabel: 'Month (From)',
                              child: buildMonthCell(),
                            ),
                            GridRow(
                              label: 'D6',
                              fieldLabel: 'Month (To)',
                              child: buildToMonthCell(),
                            ),
                            GridRow(
                              label: 'D7',
                              fieldLabel: 'Year',
                              child: buildYearCell(),
                            ),
                            GridRow(
                              label: 'D8',
                              fieldLabel: 'Remarks',
                              child: GridTextField(
                                controller: remarksCtl,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const GridSectionHeader(
                        label: 'E',
                        title: 'FUNDING SOURCES',
                      ),
                      buildFundSourcesSection(),
                      GridRow(
                        label: 'E',
                        fieldLabel: 'Other Suppliers',
                        child: GridSupplierField(
                          controller: otherMoeSuppliersCtl,
                          availableSuppliers: availableSuppliers,
                          allowsMultiple: true,
                        ),
                      ),
                      const GridSectionHeader(
                        label: 'F',
                        title: 'EXPENDITURE BREAKDOWN',
                      ),
                      buildBreakdownsSection(),
                      const GridSectionHeader(
                        label: 'G',
                        title: 'ACCOMPLISHMENT',
                      ),
                      GridRow(
                        label: 'G1',
                        fieldLabel: 'Actual Conduct',
                        child: GridTextField(
                          controller: actualConductCtl,
                          maxLines: 2,
                        ),
                      ),
                      GridRow(
                        label: 'G2',
                        fieldLabel: 'Remarks',
                        child: GridTextField(
                          controller: accommRemarksCtl,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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

  Widget buildTitleBar() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [GridFormTheme.accentGreen, GridFormTheme.darkGreen],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.edit_document, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Edit Activity',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          EnhancedButton(
            onPressed: () =>
                context.read<ActivityFormProvider>().minimizeForm(),
            icon: const Icon(Icons.remove_rounded, color: Colors.white),
            label: 'Minimize',
            variant: ButtonVariant.tertiary,
            tooltip: 'Minimize this dialog to continue other tasks.',
          ),
          const SizedBox(width: 8),
          EnhancedButton(
            onPressed: handleClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            label: 'Close',
            variant: ButtonVariant.tertiary,
            tooltip: 'Close the editor. Unsaved changes will be lost.',
          ),
        ],
      ),
    );
  }

  Widget buildMenuBar() {
    return Container(
      height: 40,
      color: GridFormTheme.accentGreen,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          Icon(Icons.info_outline, size: 16, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Modify activity details below. Calculations update automatically.',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget buildSectorCell() => GridDropdown<String>(
    value: sector,
    options: [...AppConstants.sectors, 'Other'],
    onChanged: (val) => setState(() {
      sector = val!;
      if (val != 'Crop Section') subSector = null;
    }),
  );

  Widget buildSubSectorCell() => GridDropdown<String?>(
    value: subSector,
    options: [null, ...AppConstants.subSectors],
    onChanged: (val) => setState(() => subSector = val),
  );

  Widget buildResponsiblePersonCell() {
    if (availableStaff.isEmpty) {
      return Row(
        children: const [
          SkeletonLoading(width: 80, height: 14),
          SizedBox(width: 8),
          Text(
            'Loading staff...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }
    return GridDropdown<String>(
      value:
          (availableStaff.contains(responsiblePerson) ||
              responsiblePerson == 'Other')
          ? responsiblePerson
          : null,
      options: [...availableStaff, 'Other'],
      onChanged: (val) => setState(() => responsiblePerson = val!),
    );
  }

  Widget buildStatusCell() => GridDropdown<String>(
    value: selectedStatus,
    options: [...AppConstants.prStatuses, 'Other'],
    onChanged: (val) => setState(() => selectedStatus = val!),
  );

  Widget buildMonthCell() => GridDropdown<String>(
    value: selectedMonth,
    options: months,
    onChanged: (val) => setState(() => selectedMonth = val!),
  );
  Widget buildToMonthCell() => GridDropdown<String?>(
    value: selectedToMonth,
    options: [null, ...months],
    onChanged: (val) => setState(() => selectedToMonth = val),
  );
  Widget buildYearCell() => GridDropdown<String>(
    value: selectedYear,
    options: years,
    onChanged: (val) => setState(() => selectedYear = val!),
  );

  Widget buildFundSourcesSection() {
    return Column(
      children: [
        ...fundSourceEntries.asMap().entries.map((entry) {
          final idx = entry.key;
          final e = entry.value;
          return Container(
            decoration: BoxDecoration(
              color: idx.isEven ? rowOdd : rowEven,
              border: const Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  alignment: Alignment.center,
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
                              child: GridDropdown<String>(
                                value: e.fundingSource,
                                options: AppConstants.fundingSources,
                                onChanged: (v) =>
                                    setState(() => e.fundingSource = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: GridCurrencyField(
                                controller: e.amountCtl,
                                readOnly: e.breakdownItems.isNotEmpty,
                              ),
                            ),
                            if (fundSourceEntries.length > 1)
                              Tooltip(
                                message: 'Remove this fund source.',
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() {
                                    fundSourceEntries.removeAt(idx).dispose();
                                    updateTotalBudget();
                                  }),
                                ),
                              ),
                          ],
                        ),
                        if (e.fundingSource == 'Other')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GridTextField(
                              controller: e.customFundingSourceCtl,
                              hint: 'Custom Source',
                            ),
                          ),
                        if (e.fundingSource == 'Agri MOOE') ...[
                          const SizedBox(height: 8),
                          GridDropdown<String>(
                            value: e.objectOfExpenditure,
                            options:
                                AppConstants.getFilteredObjectsOfExpenditure(
                                  sector,
                                  subSector: subSector,
                                  fundingSource: e.fundingSource,
                                ),
                            onChanged: (v) =>
                                setState(() => e.objectOfExpenditure = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() {
            fundSourceEntries.add(
              FundSourceEntry()..amountCtl.addListener(updateTotalBudget),
            );
          }),
          icon: const Icon(Icons.add),
          label: const Text('Add Source'),
        ),
      ],
    );
  }

  Widget buildBreakdownsSection() {
    return Column(
      children: fundSourceEntries.asMap().entries.map((entry) {
        final fe = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: GridFormTheme.accentGreen.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(8),
              child: Text(
                'Source ${entry.key + 1}: ${fe.fundingSource}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: GridFormTheme.darkGreen,
                ),
              ),
            ),
            buildNestedBreakdown(fe),
          ],
        );
      }).toList(),
    );
  }

  Widget buildNestedBreakdown(FundSourceEntry fe) {
    return Column(
      children: [
        ...fe.breakdownItems.asMap().entries.map((e) {
          final be = e.value;
          return Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GridTextField(
                        controller: be.nameCtl,
                        hint: 'Description',
                        tooltip: 'Detailed description of the item or expense.',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: unitCell(be.unitCtl, isCompact: false)),
                      Tooltip(
                        message: 'Remove this item from the breakdown.',
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () => setState(() {
                            fe.breakdownItems.removeAt(e.key).dispose();
                            updateTotalBudget();
                          }),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: GridTextField(
                        controller: be.q1QtyCtl,
                        hint: 'Q1',
                        keyboardType: TextInputType.number,
                        tooltip: 'First Quarter target quantity.',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GridTextField(
                        controller: be.q2QtyCtl,
                        hint: 'Q2',
                        keyboardType: TextInputType.number,
                        tooltip: 'Second Quarter target quantity.',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GridTextField(
                        controller: be.q3QtyCtl,
                        hint: 'Q3',
                        keyboardType: TextInputType.number,
                        tooltip: 'Third Quarter target quantity.',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GridTextField(
                        controller: be.q4QtyCtl,
                        hint: 'Q4',
                        keyboardType: TextInputType.number,
                        tooltip: 'Fourth Quarter target quantity.',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: GridCurrencyField(
                        controller: be.priceCtl,
                        hint: 'Price',
                        tooltip: 'Unit price of the item.',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: GridCurrencyField(
                        controller: be.amountCtl,
                        readOnly: true,
                        tooltip: 'Total calculated amount (Qty * Price).',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(flex: 3, child: supplierCell(be.supplierCtl)),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: GridAutocompleteField(
                        controller: be.statusCtl,
                        options: AppConstants.prStatuses,
                        hint: 'Status',
                        isCompact: true,
                        tooltip: 'Current procurement status of this item.',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: GridAccountCodePicker(
                        controller: be.accountCodeCtl,
                        isCompact: true,
                        hint: 'Account Code',
                        tooltip: 'Specific accounting code for this item.',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: GridDateField(
                        controller: be.statusDateCtl,
                        hint: 'Date',
                        tooltip: 'Date associated with the current status.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        EnhancedButton(
          onPressed: () => setState(() {
            fe.breakdownItems.add(
              BreakdownEntry()..amountCtl.addListener(updateTotalBudget),
            );
          }),
          icon: const Icon(Icons.add_rounded),
          label: 'Add Item',
          variant: ButtonVariant.tertiary,
          tooltip: 'Add a new breakdown item to this funding source.',
        ),
      ],
    );
  }

  Widget buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          EnhancedButton(
            onPressed: delete,
            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
            label: 'DELETE',
            variant: ButtonVariant.secondary,
            tooltip: 'Permanently delete this activity from the system.',
          ),
          const Spacer(),
          EnhancedButton(
            onPressed: handleClose,
            label: 'CANCEL',
            variant: ButtonVariant.tertiary,
            tooltip: 'Discard changes and close.',
          ),
          const SizedBox(width: 12),
          EnhancedButton(
            onPressed: () => save(false),
            label: 'SAVE CHANGES',
            variant: ButtonVariant.primary,
            isLoading: saving,
            tooltip: 'Apply and save all modifications made to this activity.',
          ),
        ],
      ),
    );
  }

  Future<void> save(bool asDraft) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final a = widget.activity;

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

      final List<BreakdownItem> breakdownList = [];
      final List<FundSourceItem> fundSources = [];

      for (var fe in fundSourceEntries) {
        final fs =
            (fe.fundingSource == 'Other'
                    ? fe.customFundingSourceCtl.text.trim()
                    : fe.fundingSource)
                .trim();
        final oe = (fe.objectOfExpenditure == 'Other'
            ? fe.customObjectOfExpenditureCtl.text.trim()
            : fe.objectOfExpenditure);
        final fAmount = CurrencyInputFormatter.parse(fe.amountCtl.text);

        if (fs.isNotEmpty && fAmount > 0) {
          fundSources.add(
            FundSourceItem(
              fundingSource: fs,
              objectOfExpenditure: oe,
              amount: fAmount,
            ),
          );
        }

        for (var b in fe.breakdownItems) {
          final bName = b.nameCtl.text.trim();
          final bAmount = CurrencyInputFormatter.parse(b.amountCtl.text);
          if (bName.isNotEmpty || bAmount > 0) {
            breakdownList.add(
              BreakdownItem(
                name: bName,
                amount: bAmount,
                unit: b.unitCtl.text.trim(),
                quantity: double.tryParse(b.quantityCtl.text) ?? 0.0,
                price: CurrencyInputFormatter.parse(b.priceCtl.text),
                q1Qty: double.tryParse(b.q1QtyCtl.text) ?? 0.0,
                q2Qty: double.tryParse(b.q2QtyCtl.text) ?? 0.0,
                q3Qty: double.tryParse(b.q3QtyCtl.text) ?? 0.0,
                q4Qty: double.tryParse(b.q4QtyCtl.text) ?? 0.0,
                fundingSource: fs,
                objectOfExpenditure: oe,
                supplier: b.supplierCtl.text.trim(),
                status: b.statusCtl.text.trim(),
                statusDate: b.statusDateCtl.text.trim(),
                accountCode: b.accountCodeCtl.text.trim(),
              ),
            );
          }
        }
      }

      final updated = a.copyWith(
        sector: finalSector,
        subSector: finalSubSector,
        activityName: activityNameCtl.text.trim(),
        unitHead: unitHeadCtl.text.trim(),
        performanceIndicator: performanceIndicatorCtl.text.trim(),
        location: locationCtl.text.trim(),
        targetNo: int.tryParse(targetNoCtl.text) ?? 1,
        targetParticipants: targetParticipantsCtl.text.trim(),
        targetDate: targetDateStr,
        responsiblePerson: finalResponsible,
        ppmpAmount: CurrencyInputFormatter.parse(ppmpAmountCtl.text),
        ppmpBalance: CurrencyInputFormatter.parse(ppmpCtl.text),
        prAmount: CurrencyInputFormatter.parse(totalProcurementCtl.text),
        prBalance: CurrencyInputFormatter.parse(prBalanceCtl.text),
        prNumber: prLogs.isNotEmpty
            ? prLogs.last.prNumber
            : prNumberCtl.text.trim(),
        supplierApprop: supplierAppropCtl.text.trim(),
        barcodeApprop: barcodeAppropCtl.text.trim(),
        actualConduct: actualConductCtl.text.trim(),
        accommRemarks: accommRemarksCtl.text.trim(),
        remarks: remarksCtl.text.trim(),
        accountCode: accountCodeCtl.text.trim(),
        fundingSource: fundSources.isNotEmpty
            ? fundSources.first.fundingSource
            : 'Agri MOOE',
        objectOfExpenditure: fundSources.isNotEmpty
            ? fundSources.first.objectOfExpenditure
            : '',
        otherMoeSuppliers: otherMoeSuppliersCtl.text.trim(),
        effectivePOAmount: prLogs.isNotEmpty
            ? prLogs.fold<double>(0, (prev, log) => prev + log.poAmount)
            : totalBreakdownAmount,
        status: finalStatusStr,
        breakdown: breakdownList,
        fundSources: fundSources,
        isDraft: asDraft,
        prLogs: prLogs,
        inputtedAmount: CurrencyInputFormatter.parse(inputtedAmountCtl.text),
      );

      await widget.fbService.updateActivity(updated);

      if (mounted) {
        context.read<ActivityFormProvider>().closeForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes Saved Successfully')),
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
    if (await showDialog<bool>(
          context: context,
          barrierColor: Colors.transparent,
          builder: (ctx) => AlertDialog(
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
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ==
        true) {
      try {
        await widget.fbService.deleteActivity(widget.activity.id);
        if (mounted) context.read<ActivityFormProvider>().closeForm();
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
