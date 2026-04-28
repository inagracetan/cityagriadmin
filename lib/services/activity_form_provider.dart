import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/activity.dart';
import '../core/currency_formatter.dart';

class BreakdownEntry {
  final TextEditingController nameCtl;
  final TextEditingController amountCtl;
  final TextEditingController supplierCtl;
  final TextEditingController statusCtl;

  BreakdownEntry({
    String name = '',
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
  final TextEditingController customFundingSourceCtl = TextEditingController();
  final TextEditingController customObjectOfExpenditureCtl =
      TextEditingController();
  final TextEditingController amountCtl;
  final List<BreakdownEntry> breakdownItems = [];

  FundSourceEntry({String amount = ''})
    : amountCtl = TextEditingController(text: amount);

  void dispose() {
    customFundingSourceCtl.dispose();
    customObjectOfExpenditureCtl.dispose();
    amountCtl.dispose();
    for (var b in breakdownItems) {
      b.dispose();
    }
  }
}

class ActivityFormProvider extends ChangeNotifier {
  bool isOpen = false;
  bool isMinimized = false;
  bool isEditing = false;
  Activity? editingActivity;
  List<String>? initialResponsiblePersons;

  // Form State
  String sector = AppConstants.sectors.first;
  String? subSector;
  String selectedStatus = AppConstants.activityStatuses.first;
  String selectedMonth = AppConstants.months[DateTime.now().month - 1];
  String? selectedToMonth;
  String selectedYear = DateTime.now().year.toString();
  String responsiblePerson = '';

  final activityNameCtl = TextEditingController();
  final unitHeadCtl = TextEditingController();
  final performanceIndicatorCtl = TextEditingController();
  final locationCtl = TextEditingController();
  final targetNoCtl = TextEditingController();
  final budgetCtl = TextEditingController();
  final q1BudgetCtl = TextEditingController();
  final q2BudgetCtl = TextEditingController();
  final q3BudgetCtl = TextEditingController();
  final q4BudgetCtl = TextEditingController();
  final ppmpCtl = TextEditingController();
  final prAmountCtl = TextEditingController();
  final targetParticipantsCtl = TextEditingController();
  final remarksCtl = TextEditingController();
  final customSectorCtl = TextEditingController();
  final customSubSectorCtl = TextEditingController();
  final customResponsiblePersonCtl = TextEditingController();
  final customFundingSourceCtl = TextEditingController();
  final customStatusCtl = TextEditingController();
  final customStatusDateCtl = TextEditingController();
  final otherMoeSuppliersCtl = TextEditingController();
  final customObjectOfExpenditureCtl = TextEditingController();

  // Accomplishment Fields
  final actualConductCtl = TextEditingController();
  final accommRemarksCtl = TextEditingController();

  // Appropriations
  final appropCtl = TextEditingController();
  final trainingSeminarCtl = TextEditingController();
  final meetingsCtl = TextEditingController();
  final df20Ctl = TextEditingController();
  final cpocCtl = TextEditingController();
  final gadCtl = TextEditingController();
  final ppmpBalanceCtl = TextEditingController();
  final prNumberCtl = TextEditingController();
  final prBalanceCtl = TextEditingController();
  final supplierAppropCtl = TextEditingController();
  final barcodeAppropCtl = TextEditingController();
  final statusAppropCtl = TextEditingController();
  final statusAppropDateCtl = TextEditingController();

  final List<FundSourceEntry> fundSourceEntries = [];

  // Persistent dropdown values for "Add Activity"
  String? lastFundingSource;
  String? lastObjectOfExpenditure;

  ActivityFormProvider() {
    ppmpCtl.addListener(updatePRBalance);
    prAmountCtl.addListener(updatePRBalance);
    budgetCtl.addListener(syncPPMPWithBudget);
  }

  void syncPPMPWithBudget() {
    final budgetVal = budgetCtl.text;
    if (ppmpCtl.text != budgetVal) {
      ppmpCtl.text = budgetVal;
    }
  }

  void updatePRBalance() {
    final double ppmp = CurrencyInputFormatter.parse(ppmpCtl.text);
    final double prAmount = CurrencyInputFormatter.parse(prAmountCtl.text);
    final double balance = ppmp - prAmount;
    prBalanceCtl.text = CurrencyInputFormatter.formatDouble(balance);
  }

  void updateTotalBudget() {
    double grandTotal = 0;
    bool hasAnyBreakdown = false;
    for (var entry in fundSourceEntries) {
      if (entry.breakdownItems.isNotEmpty) {
        hasAnyBreakdown = true;
        double fundTotal = 0;
        for (var be in entry.breakdownItems) {
          fundTotal += CurrencyInputFormatter.parse(be.amountCtl.text);
        }
        
        final fundTotalStr = CurrencyInputFormatter.formatDouble(fundTotal);
        if (entry.amountCtl.text != fundTotalStr) {
          entry.amountCtl.text = fundTotalStr;
        }
        grandTotal += fundTotal;
      } else {
        grandTotal += CurrencyInputFormatter.parse(entry.amountCtl.text);
      }
    }

    if (hasAnyBreakdown) {
      budgetCtl.text = CurrencyInputFormatter.formatDouble(grandTotal);
    }
    updatePRBalance();
  }




  void addFundSource() {
    final entry = FundSourceEntry();
    entry.amountCtl.addListener(updateTotalBudget);
    fundSourceEntries.add(entry);
    notifyListeners();
  }

  void removeFundSource(FundSourceEntry entry) {
    entry.amountCtl.removeListener(updateTotalBudget);
    entry.dispose();
    fundSourceEntries.remove(entry);
    updateTotalBudget();
    notifyListeners();
  }

  void addBreakdownItem(FundSourceEntry fs) {
    final lastEntry = fs.breakdownItems.isNotEmpty ? fs.breakdownItems.last : null;
    final item = BreakdownEntry(
      supplier: lastEntry?.supplierCtl.text,
      status: lastEntry?.statusCtl.text,
    );
    item.amountCtl.addListener(updateTotalBudget);
    fs.breakdownItems.add(item);
    notifyListeners();
  }

  void removeBreakdownItem(FundSourceEntry fs, int bIndex) {
    fs.breakdownItems[bIndex].amountCtl.removeListener(updateTotalBudget);
    fs.breakdownItems[bIndex].dispose();
    fs.breakdownItems.removeAt(bIndex);
    updateTotalBudget();
    notifyListeners();
  }

  void openForm({Activity? activity, List<String>? initialResponsiblePersons}) {
    initialResponsiblePersons = initialResponsiblePersons;
    if (activity != null) {
      isEditing = true;
      editingActivity = activity;
      populateForm(activity);
    } else {
      isEditing = false;
      editingActivity = null;
      resetForm();
    }
    isOpen = true;
    isMinimized = true;
    notifyListeners();
  }

  void populateForm(Activity activity) {
    sector = AppConstants.sectors.contains(activity.sector)
        ? activity.sector
        : AppConstants.sectors.last; // 'Other'
    if (sector == 'Other') customSectorCtl.text = activity.sector;

    subSector = activity.subSector;
    selectedStatus = AppConstants.activityStatuses.contains(activity.status)
        ? activity.status
        : AppConstants.activityStatuses.last; // 'Other'
    if (selectedStatus == 'Other') customStatusCtl.text = activity.status;

    // Handle Target Date and Year
    final dateStr = activity.targetDate;
    final parts = dateStr.split(' ');
    if (parts.length >= 2) {
      selectedYear = parts.last;
      String monthPart = parts[0];
      if (monthPart.contains('-')) {
        final ms = monthPart.split('-');
        selectedMonth = ms[0];
        selectedToMonth = ms[1];
      } else {
        selectedMonth = monthPart;
        selectedToMonth = null;
      }
    } else {
      // Fallback
      if (AppConstants.months.contains(dateStr)) {
        selectedMonth = dateStr;
      } else if (dateStr.contains('-')) {
        final ms = dateStr.split('-');
        if (ms.length == 2 && AppConstants.months.contains(ms[0])) {
          selectedMonth = ms[0];
          selectedToMonth = AppConstants.months.contains(ms[1]) ? ms[1] : null;
        }
      }
    }

    responsiblePerson = activity.responsiblePerson;
    activityNameCtl.text = activity.activityName;
    performanceIndicatorCtl.text = activity.performanceIndicator;
    targetNoCtl.text = activity.targetNo.toString();
    locationCtl.text = activity.location ?? '';
    unitHeadCtl.text = activity.unitHead ?? '';
    remarksCtl.text = activity.remarks;

    q1BudgetCtl.text = activity.q1Budget > 0
        ? CurrencyInputFormatter.formatDouble(activity.q1Budget)
        : '';
    q2BudgetCtl.text = activity.q2Budget > 0
        ? CurrencyInputFormatter.formatDouble(activity.q2Budget)
        : '';
    q3BudgetCtl.text = activity.q3Budget > 0
        ? CurrencyInputFormatter.formatDouble(activity.q3Budget)
        : '';
    q4BudgetCtl.text = activity.q4Budget > 0
        ? CurrencyInputFormatter.formatDouble(activity.q4Budget)
        : '';
    ppmpCtl.text = activity.ppmpAmount > 0
        ? CurrencyInputFormatter.formatDouble(activity.ppmpAmount)
        : '';
    prAmountCtl.text = activity.prAmount > 0
        ? CurrencyInputFormatter.formatDouble(activity.prAmount)
        : '';
    prBalanceCtl.text = activity.prBalance > 0
        ? CurrencyInputFormatter.formatDouble(activity.prBalance)
        : '';
    budgetCtl.text = activity.totalBudget > 0
        ? CurrencyInputFormatter.formatDouble(activity.totalBudget)
        : '';

    // Accomplishment fields
    actualConductCtl.text = activity.actualConduct;
    accommRemarksCtl.text = activity.accommRemarks;

    // Appropriations
    appropCtl.text = activity.appropriation.toString();
    trainingSeminarCtl.text = activity.trainingSeminarAmount.toString();
    meetingsCtl.text = activity.meetingsAmount.toString();
    df20Ctl.text = activity.df20Amount.toString();
    cpocCtl.text = activity.cpocAmount.toString();
    gadCtl.text = activity.gadAmount.toString();
    ppmpBalanceCtl.text = activity.ppmpBalance.toString();
    prNumberCtl.text = activity.prNumber;
    prBalanceCtl.text = activity.prBalance.toString();
    supplierAppropCtl.text = activity.supplierApprop;
    barcodeAppropCtl.text = activity.barcodeApprop;
    statusAppropCtl.text = activity.statusApprop;
    statusAppropDateCtl.text = activity.statusAppropDate ?? '';

    // Populate fund sources and breakdowns
    for (var fs in fundSourceEntries) {
      fs.dispose();
    }
    fundSourceEntries.clear();

    if (activity.fundSources.isNotEmpty) {
      for (var fsItem in activity.fundSources) {
        final entry = FundSourceEntry(
          amount: CurrencyInputFormatter.formatDouble(fsItem.amount),
        );
        entry.fundingSource =
            AppConstants.fundingSources.contains(fsItem.fundingSource)
            ? fsItem.fundingSource
            : 'Other';
        if (entry.fundingSource == 'Other') {
          entry.customFundingSourceCtl.text = fsItem.fundingSource;
        }
        entry.objectOfExpenditure =
            AppConstants.objectsOfExpenditure.contains(
              fsItem.objectOfExpenditure,
            )
            ? fsItem.objectOfExpenditure
            : 'Other-MOE Expenses';
        if (entry.objectOfExpenditure == 'Other' ||
            entry.objectOfExpenditure == 'Other-MOE Expenses') {
          // check if actually 'Other'
          if (fsItem.objectOfExpenditure != 'Other-MOE Expenses' &&
              !AppConstants.objectsOfExpenditure.contains(
                fsItem.objectOfExpenditure,
              )) {
            entry.objectOfExpenditure = 'Other';
            entry.customObjectOfExpenditureCtl.text =
                fsItem.objectOfExpenditure ?? '';
          }
        }

        entry.amountCtl.addListener(updateTotalBudget);

        if (activity.breakdown.isNotEmpty) {
          final items = activity.breakdown
              .where(
                (b) =>
                    b.fundingSource == fsItem.fundingSource &&
                    b.objectOfExpenditure == fsItem.objectOfExpenditure,
              )
              .toList();

          for (var item in items) {
            final be = BreakdownEntry(
              name: item.name,
              amount: item.amount,
              supplier: item.supplier,
              status: item.status,
            );
            be.amountCtl.addListener(updateTotalBudget);
            entry.breakdownItems.add(be);
          }
        }
        fundSourceEntries.add(entry);
      }
    } else {
      // Legacy fallback
      final entry = FundSourceEntry(
        amount: CurrencyInputFormatter.formatDouble(activity.totalBudget),
      );
      entry.fundingSource =
          AppConstants.fundingSources.contains(activity.fundingSource)
          ? activity.fundingSource
          : 'Other';
      if (entry.fundingSource == 'Other') {
        entry.customFundingSourceCtl.text = activity.fundingSource;
      }

      final oe = activity.objectOfExpenditure;
      if (oe != null && AppConstants.objectsOfExpenditure.contains(oe)) {
        entry.objectOfExpenditure = oe;
      } else {
        entry.objectOfExpenditure = 'Other-MOE Expenses';
        if (oe != null && oe.isNotEmpty && oe != 'Other-MOE Expenses') {
          entry.objectOfExpenditure = 'Other';
          entry.customObjectOfExpenditureCtl.text = oe;
        }
      }
      entry.amountCtl.addListener(updateTotalBudget);

      // Also check if any breakdown items belong to this legacy source
      if (activity.breakdown.isNotEmpty) {
        for (var item in activity.breakdown) {
          final be = BreakdownEntry(
            name: item.name,
            amount: item.amount,
            supplier: item.supplier,
            status: item.status,
          );
          be.amountCtl.addListener(updateTotalBudget);
          entry.breakdownItems.add(be);
        }
      }

      fundSourceEntries.add(entry);
    }
    if (fundSourceEntries.isEmpty) {
      addFundSource();
    }

    updateTotalBudget();
  }

  void minimizeForm() {
    isMinimized = true;
    notifyListeners();
  }

  void restoreForm() {
    isMinimized = false;
    notifyListeners();
  }

  void closeForm() {
    isOpen = false;
    isMinimized = false;
    resetForm();
    notifyListeners();
  }

  void resetForm() {
    // These fields are now persistent across "Add Activity" sessions
    // sector, subSector, selectedStatus, selectedMonth, selectedToMonth, selectedYear, responsiblePerson
    // are NOT reset here.

    activityNameCtl.clear();
    unitHeadCtl.clear();
    performanceIndicatorCtl.clear();
    locationCtl.clear();
    targetNoCtl.clear();
    budgetCtl.clear();
    q1BudgetCtl.clear();
    q2BudgetCtl.clear();
    q3BudgetCtl.clear();
    q4BudgetCtl.clear();
    ppmpCtl.clear();
    prAmountCtl.clear();
    targetParticipantsCtl.clear();
    remarksCtl.clear();
    customSectorCtl.clear();
    customSubSectorCtl.clear();
    customResponsiblePersonCtl.clear();
    customFundingSourceCtl.clear();
    customStatusCtl.clear();
    customStatusDateCtl.clear();
    otherMoeSuppliersCtl.clear();
    customObjectOfExpenditureCtl.clear();
    actualConductCtl.clear();
    accommRemarksCtl.clear();
    appropCtl.clear();
    trainingSeminarCtl.clear();
    meetingsCtl.clear();
    df20Ctl.clear();
    cpocCtl.clear();
    gadCtl.clear();
    ppmpBalanceCtl.clear();
    prNumberCtl.clear();
    prBalanceCtl.clear();
    // supplierAppropCtl and statusAppropCtl are now persistent
    barcodeAppropCtl.clear();
    statusAppropDateCtl.clear();

    for (var fs in fundSourceEntries) {
      fs.amountCtl.removeListener(updateTotalBudget);
      fs.dispose();
    }
    fundSourceEntries.clear();
  }

  @override
  void dispose() {
    activityNameCtl.dispose();
    unitHeadCtl.dispose();
    performanceIndicatorCtl.dispose();
    locationCtl.dispose();
    targetNoCtl.dispose();
    budgetCtl.dispose();
    q1BudgetCtl.dispose();
    q2BudgetCtl.dispose();
    q3BudgetCtl.dispose();
    q4BudgetCtl.dispose();
    ppmpCtl.dispose();
    prAmountCtl.dispose();
    targetParticipantsCtl.dispose();
    remarksCtl.dispose();
    customSectorCtl.dispose();
    customSubSectorCtl.dispose();
    customResponsiblePersonCtl.dispose();
    customFundingSourceCtl.dispose();
    customStatusCtl.dispose();
    customStatusDateCtl.dispose();
    otherMoeSuppliersCtl.dispose();
    customObjectOfExpenditureCtl.dispose();
    actualConductCtl.dispose();
    accommRemarksCtl.dispose();
    appropCtl.dispose();
    trainingSeminarCtl.dispose();
    meetingsCtl.dispose();
    df20Ctl.dispose();
    cpocCtl.dispose();
    gadCtl.dispose();
    ppmpBalanceCtl.dispose();
    prNumberCtl.dispose();
    prBalanceCtl.dispose();
    supplierAppropCtl.dispose();
    barcodeAppropCtl.dispose();
    statusAppropCtl.dispose();
    statusAppropDateCtl.dispose();
    for (var fs in fundSourceEntries) {
      fs.dispose();
    }
    super.dispose();
  }
}
