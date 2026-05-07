import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/activity.dart';
import '../models/pr_log.dart';
import '../core/currency_formatter.dart';
import '../core/activity_templates.dart';
import 'firebase_service.dart';
import 'package:provider/provider.dart';


class BreakdownEntry {
  final TextEditingController nameCtl;
  final TextEditingController unitCtl;
  final TextEditingController quantityCtl;
  final TextEditingController priceCtl;
  final TextEditingController amountCtl;
  final TextEditingController q1QtyCtl;
  final TextEditingController q2QtyCtl;
  final TextEditingController q3QtyCtl;
  final TextEditingController q4QtyCtl;
  final TextEditingController supplierCtl;
  final TextEditingController statusCtl;
  final TextEditingController statusDateCtl;
  final TextEditingController accountCodeCtl; // Added
  int quarter = 1;

  BreakdownEntry({
    String name = '',
    double amount = 0.0,
    String? unit,
    double quantity = 0.0,
    double price = 0.0,
    this.quarter = 1,
    double q1Qty = 0.0,
    double q2Qty = 0.0,
    double q3Qty = 0.0,
    double q4Qty = 0.0,
    String? supplier,
    String? status,
    String? statusDate,
    String? accountCode,
  }) : nameCtl = TextEditingController(text: name),
       unitCtl = TextEditingController(text: unit ?? ''),
       quantityCtl = TextEditingController(text: quantity > 0 ? quantity.toString() : ''),
       priceCtl = TextEditingController(text: price > 0 ? CurrencyInputFormatter.formatDouble(price) : ''),
       amountCtl = TextEditingController(
         text: amount > 0 ? CurrencyInputFormatter.formatDouble(amount) : '',
       ),
       q1QtyCtl = TextEditingController(text: q1Qty > 0 ? q1Qty.toString() : ''),
       q2QtyCtl = TextEditingController(text: q2Qty > 0 ? q2Qty.toString() : ''),
       q3QtyCtl = TextEditingController(text: q3Qty > 0 ? q3Qty.toString() : ''),
       q4QtyCtl = TextEditingController(text: q4Qty > 0 ? q4Qty.toString() : ''),
       supplierCtl = TextEditingController(text: supplier ?? ''),
       statusCtl = TextEditingController(text: status ?? ''),
       statusDateCtl = TextEditingController(text: statusDate ?? ''),
       accountCodeCtl = TextEditingController(text: accountCode ?? '');

  void dispose() {
    nameCtl.dispose();
    unitCtl.dispose();
    quantityCtl.dispose();
    priceCtl.dispose();
    amountCtl.dispose();
    q1QtyCtl.dispose();
    q2QtyCtl.dispose();
    q3QtyCtl.dispose();
    q4QtyCtl.dispose();
    supplierCtl.dispose();
    statusCtl.dispose();
    statusDateCtl.dispose();
    accountCodeCtl.dispose();
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

  FundSourceEntry({
    String amount = '',
    String? initialSource,
    String? initialOE,
  }) : fundingSource = initialSource ?? 'Agri MOOE',
       objectOfExpenditure = initialOE ?? 'Other-MOE Expenses',
       amountCtl = TextEditingController(text: amount);

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
  List<PRLog> prLogs = [];

  // Form State
  String sector = 'Administrative Support Services Unit';
  String? subSector;
  String selectedStatus = AppConstants.statusPRPreparation;
  String selectedMonth = 'January';
  String? selectedToMonth;
  String selectedYear = '2026';
  String responsiblePerson = '';

  List<String> availableStaff = AppConstants.staffList;
  List<String> availableSuppliers = [];


  void setSector(String v) {
    sector = v;
    if (sector != 'Other') customSectorCtl.clear();
    notifyListeners();
  }

  void setSubSector(String? v) {
    subSector = v;
    if (subSector != 'Other') customSubSectorCtl.clear();
    notifyListeners();
  }

  void setStatus(String v) {
    selectedStatus = v;
    if (selectedStatus != 'Other') customStatusCtl.clear();
    notifyListeners();
  }

  void setMonth(String v) {
    selectedMonth = v;
    notifyListeners();
  }

  void setToMonth(String? v) {
    selectedToMonth = v;
    notifyListeners();
  }

  void setYear(String v) {
    selectedYear = v;
    notifyListeners();
  }

  void setResponsiblePerson(String v) {
    responsiblePerson = v;
    if (responsiblePerson != 'Other') customResponsiblePersonCtl.clear();
    notifyListeners();
  }

  void setFundingSource(FundSourceEntry entry, String v) {
    entry.fundingSource = v;
    if (v != 'Other') entry.customFundingSourceCtl.clear();
    if (v == 'Agri MOOE') {
      entry.objectOfExpenditure = '$sector Appropriation';
    } else {
      entry.objectOfExpenditure = null;
    }
    notifyListeners();
  }

  void setObjectOfExpenditure(FundSourceEntry entry, String? v) {
    entry.objectOfExpenditure = v;
    if (v != 'Other') entry.customObjectOfExpenditureCtl.clear();
    notifyListeners();
  }

  bool isEdited(Activity original) {
    if (activityNameCtl.text != original.activityName) return true;
    if (sector != original.sector) return true;
    if (subSector != original.subSector) return true;
    if (targetDateString != original.targetDate) return true;
    if (responsiblePerson != original.responsiblePerson) return true;
    // Add other field comparisons as needed
    return false;
  }

  bool isSaving = false;

  String get targetDateString {
    if (selectedToMonth != null) {
      return '$selectedMonth-$selectedToMonth $selectedYear';
    }
    return '$selectedMonth $selectedYear';
  }

  bool get isSaveDisabled {
    return activityNameCtl.text.trim().isEmpty || sector == 'Select Sector';
  }


  Future<void> loadStaffAndSuppliers(FirebaseService fbService) async {
    try {
      final staff = await fbService.getAvailableStaff();
      availableStaff = staff.where((s) => s != 'Other').toList();
      if (responsiblePerson.isNotEmpty && !availableStaff.contains(responsiblePerson)) {
        availableStaff.insert(0, responsiblePerson);
      }
      
      // Load suppliers from activities (simple cache/list)
      // For now we just keep the default list if it's too expensive to query every time
      availableSuppliers = AppConstants.commonSuppliers;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<bool> saveForm(BuildContext context, {String? activityId, bool isEdit = false}) async {
    isSaving = true;
    notifyListeners();
    try {
      final fbService = context.read<FirebaseService>();
      
      // Check for duplicates if adding
      if (!isEdit) {
        final isDuplicate = await fbService.checkDuplicateActivity(
          activityNameCtl.text.trim(),
          sector,
          targetDateString,
        );
        if (isDuplicate && context.mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Duplicate Activity'),
              content: const Text('An activity with the same name, sector, and date already exists. Do you want to proceed anyway?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceed')),
              ],
            ),
          );
          if (proceed != true) return false;
        }
      }

      final activity = toActivity(activityId);
      if (isEdit && activityId != null) {
        await fbService.updateActivity(activity);
      } else {
        await fbService.addActivity(activity);
      }
      closeForm();
      return true;
    } catch (e) {
      debugPrint('Error saving form: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void closeForm() {
    isOpen = false;
    isEditing = false;
    editingActivity = null;
    resetForm();
    notifyListeners();
  }

  void minimizeForm() {
    isMinimized = true;
    notifyListeners();
  }

  void restoreForm() {
    isMinimized = false;
    notifyListeners();
  }

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
  final accountCodeCtl = TextEditingController();

  // Accomplishment Fields
  final actualConductCtl = TextEditingController();
  final accommRemarksCtl = TextEditingController();

  // Financial Oversight Fields
  final inputtedAmountCtl = TextEditingController();
  final totalProcurementCtl = TextEditingController();
  final ppmpAmountCtl = TextEditingController();

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
    ppmpCtl.addListener(updateAllFinancials);
    prAmountCtl.addListener(updateAllFinancials);
    budgetCtl.addListener(updateAllFinancials);
    inputtedAmountCtl.addListener(updateAllFinancials);
  }

  void _addBreakdownListeners(BreakdownEntry be) {
    be.priceCtl.addListener(updateAllFinancials);
    be.q1QtyCtl.addListener(updateAllFinancials);
    be.q2QtyCtl.addListener(updateAllFinancials);
    be.q3QtyCtl.addListener(updateAllFinancials);
    be.q4QtyCtl.addListener(updateAllFinancials);
    be.amountCtl.addListener(updateAllFinancials);
  }

  void updateAllFinancials() {
    double grandPlannedTotal = 0;
    double q1Total = 0;
    double q2Total = 0;
    double q3Total = 0;
    double q4Total = 0;

    // 1. Process Fund Sources and Breakdown Items
    for (var entry in fundSourceEntries) {
      double fundSourceTotal = 0;
      if (entry.breakdownItems.isNotEmpty) {
        for (var be in entry.breakdownItems) {
          final double q1 = double.tryParse(be.q1QtyCtl.text) ?? 0;
          final double q2 = double.tryParse(be.q2QtyCtl.text) ?? 0;
          final double q3 = double.tryParse(be.q3QtyCtl.text) ?? 0;
          final double q4 = double.tryParse(be.q4QtyCtl.text) ?? 0;
          final double price = CurrencyInputFormatter.parse(be.priceCtl.text);
          
          final double totalQty = q1 + q2 + q3 + q4;
          final double amount = totalQty * price;

          // Sync internal controllers of the breakdown item
          final totalQtyStr = totalQty.toString();
          if (be.quantityCtl.text != totalQtyStr) {
            be.quantityCtl.text = totalQtyStr;
          }

          final amountStr = CurrencyInputFormatter.formatDouble(amount);
          if (be.amountCtl.text != amountStr) {
            be.amountCtl.text = amountStr;
          }

          fundSourceTotal += amount;
          q1Total += q1 * price;
          q2Total += q2 * price;
          q3Total += q3 * price;
          q4Total += q4 * price;
        }
        
        final fundTotalStr = CurrencyInputFormatter.formatDouble(fundSourceTotal);
        if (entry.amountCtl.text != fundTotalStr) {
          entry.amountCtl.text = fundTotalStr;
        }
      } else {
        fundSourceTotal = CurrencyInputFormatter.parse(entry.amountCtl.text);
      }
      grandPlannedTotal += fundSourceTotal;
    }

    // 2. Determine Budget Allocation (The "Approved Budget")
    final double inputted = CurrencyInputFormatter.parse(inputtedAmountCtl.text);
    final double manual = CurrencyInputFormatter.parse(budgetCtl.text);
    double budgetAllocation = inputted > 0 ? inputted : manual;
    
    // Sync Approved Budget field if override is set or if no budget is set yet
    if (inputted > 0 || (budgetAllocation == 0 && grandPlannedTotal > 0)) {
      if (inputted > 0) {
        budgetAllocation = inputted;
      } else if (budgetAllocation == 0) {
        budgetAllocation = grandPlannedTotal;
      }

      final allocationStr = CurrencyInputFormatter.formatDouble(budgetAllocation);
      if (budgetCtl.text != allocationStr) {
        budgetCtl.text = allocationStr;
      }
    }

    // 3. Update Planned Amount (PPMP Amount)
    final plannedStr = CurrencyInputFormatter.formatDouble(grandPlannedTotal);
    if (ppmpAmountCtl.text != plannedStr) {
      ppmpAmountCtl.text = plannedStr;
    }

    // 4. Update Quarterly Distributions
    q1BudgetCtl.text = q1Total > 0 ? CurrencyInputFormatter.formatDouble(q1Total) : '';
    q2BudgetCtl.text = q2Total > 0 ? CurrencyInputFormatter.formatDouble(q2Total) : '';
    q3BudgetCtl.text = q3Total > 0 ? CurrencyInputFormatter.formatDouble(q3Total) : '';
    q4BudgetCtl.text = q4Total > 0 ? CurrencyInputFormatter.formatDouble(q4Total) : '';

    // 5. Calculate total procurement from PR logs
    double totalPRs = 0;
    for (var log in prLogs) {
      totalPRs += log.prAmount;
    }
    final totalPRsStr = CurrencyInputFormatter.formatDouble(totalPRs);
    if (totalProcurementCtl.text != totalPRsStr) {
      totalProcurementCtl.text = totalPRsStr;
    }
    if (prAmountCtl.text != totalPRsStr) {
      prAmountCtl.text = totalPRsStr;
    }

    // 6. Calculate Balances
    // PPMP Balance = Budget Allocation - PPMP Amount (Planned)
    final double ppmpBalance = budgetAllocation - grandPlannedTotal;
    final ppmpBalanceStr = CurrencyInputFormatter.formatDouble(ppmpBalance);
    if (ppmpBalanceCtl.text != ppmpBalanceStr) {
      ppmpBalanceCtl.text = ppmpBalanceStr;
    }
    // Legacy support for ppmpCtl (which is often bound to balance in UI)
    if (ppmpCtl.text != ppmpBalanceStr) {
      ppmpCtl.text = ppmpBalanceStr;
    }

    // PR Balance = PPMP Amount (Planned) - Actual PRs
    final double prBalance = grandPlannedTotal - totalPRs;
    final prBalanceStr = CurrencyInputFormatter.formatDouble(prBalance);
    if (prBalanceCtl.text != prBalanceStr) {
      prBalanceCtl.text = prBalanceStr;
    }

    // ── Hard Stop Logic ──────────────────────────────────────────────
    // If Requested PR > Remaining PR Balance, Then set Status = "No Budget"
    // Note: remainingPRBalance here is prBalance before adding the latest PR, 
    // but totalPRs already includes all logs. 
    // So if prBalance < 0, it means we've exceeded the allocation.
    if (prBalance < -0.01) { // small epsilon for double precision
      if (selectedStatus != 'No Budget') {
        selectedStatus = 'No Budget';
      }
    } else if (selectedStatus == 'No Budget') {
      // Revert to a default status if balance is restored, or leave it to user?
      // Typically, we revert to 'PR Preparation' or 'Planned'
      selectedStatus = AppConstants.statusPRPreparation;
    }

    notifyListeners();
  }

  void addPRLog(String? activityId, String userName) {
    prLogs.add(PRLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityId: activityId ?? '',
      status: AppConstants.statusPRStage,
      prNumber: '',
      prAmount: 0,
      statusDate: DateTime.now().toString().split(' ').first,
      timestamp: DateTime.now(),
      updatedBy: userName,
    ));
    updateAllFinancials();
    notifyListeners();
  }

  void removePRLog(int index) {
    prLogs.removeAt(index);
    updateAllFinancials();
    notifyListeners();
  }




  void addFundSource() {
    final entry = FundSourceEntry();
    entry.amountCtl.addListener(updateAllFinancials);
    fundSourceEntries.add(entry);
    notifyListeners();
  }

  void removeFundSource(FundSourceEntry entry) {
    entry.amountCtl.removeListener(updateAllFinancials);
    entry.dispose();
    fundSourceEntries.remove(entry);
    updateAllFinancials();
    notifyListeners();
  }

  void addBreakdownItem(FundSourceEntry fs) {
    final lastEntry = fs.breakdownItems.isNotEmpty ? fs.breakdownItems.last : null;
    final item = BreakdownEntry(
      supplier: lastEntry?.supplierCtl.text,
      status: lastEntry?.statusCtl.text,
      accountCode: lastEntry?.accountCodeCtl.text ?? accountCodeCtl.text,
    );
    _addBreakdownListeners(item);
    fs.breakdownItems.add(item);
    notifyListeners();
  }

  void pasteBreakdownItems(FundSourceEntry fs, String tsvData) {
    final rows = tsvData.split(RegExp(r'\r?\n'));
    for (var row in rows) {
      if (row.trim().isEmpty) continue;
      final columns = row.split('\t');
      if (columns.length < 2) continue; // Must have at least name and unit or qty

      // Expected format: Description, Unit, Q1, Q2, Q3, Q4, Price, Supplier
      final name = columns[0].trim();
      final unit = columns.length > 1 ? columns[1].trim() : '';
      final q1 = columns.length > 2 ? double.tryParse(columns[2]) ?? 0.0 : 0.0;
      final q2 = columns.length > 3 ? double.tryParse(columns[3]) ?? 0.0 : 0.0;
      final q3 = columns.length > 4 ? double.tryParse(columns[4]) ?? 0.0 : 0.0;
      final q4 = columns.length > 5 ? double.tryParse(columns[5]) ?? 0.0 : 0.0;
      final price =
          columns.length > 6
              ? CurrencyInputFormatter.parse(columns[6])
              : 0.0;
      final supplier = columns.length > 7 ? columns[7].trim() : '';

      final entry = BreakdownEntry(
        name: name,
        unit: unit,
        q1Qty: q1,
        q2Qty: q2,
        q3Qty: q3,
        q4Qty: q4,
        price: price,
        supplier: supplier,
        accountCode: fs.breakdownItems.isNotEmpty 
            ? fs.breakdownItems.last.accountCodeCtl.text 
            : accountCodeCtl.text,
      );

      // Recalculate total qty and amount
      final totalQty = q1 + q2 + q3 + q4;
      entry.quantityCtl.text = totalQty.toString();
      entry.amountCtl.text = CurrencyInputFormatter.formatDouble(
        totalQty * price,
      );

      _addBreakdownListeners(entry);
      fs.breakdownItems.add(entry);
    }
    updateAllFinancials();
    notifyListeners();
  }

  void loadTemplate(ActivityTemplate template) {
    activityNameCtl.text = template.name;
    sector = template.sector;
    subSector = template.subSector;

    // Reset fund sources and add a default one for the template items
    for (var fs in fundSourceEntries) {
      fs.dispose();
    }
    fundSourceEntries.clear();

    final fs = FundSourceEntry();
    fs.fundingSource = 'Agri MOOE';
    fs.objectOfExpenditure = 'Trainings and Seminar Expenses';
    fs.amountCtl.addListener(updateAllFinancials);

    for (var item in template.items) {
      final entry = BreakdownEntry(
        name: item.name,
        unit: item.unit,
        q1Qty: item.q1,
        q2Qty: item.q2,
        q3Qty: item.q3,
        q4Qty: item.q4,
        price: item.price,
      );

      final totalQty = item.q1 + item.q2 + item.q3 + item.q4;
      entry.quantityCtl.text = totalQty.toString();
      entry.amountCtl.text = CurrencyInputFormatter.formatDouble(totalQty * item.price);
      _addBreakdownListeners(entry);
      fs.breakdownItems.add(entry);
    }

    fundSourceEntries.add(fs);
    updateAllFinancials();
    notifyListeners();
  }

  void removeBreakdownItem(FundSourceEntry fs, int bIndex) {
    fs.breakdownItems[bIndex].amountCtl.removeListener(updateAllFinancials);
    fs.breakdownItems[bIndex].dispose();
    fs.breakdownItems.removeAt(bIndex);
    updateAllFinancials();
    notifyListeners();
  }

  void openForm({Activity? activity, List<String>? initialResponsiblePersons}) {
    this.initialResponsiblePersons = initialResponsiblePersons;
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
    isMinimized = false;
    notifyListeners();
  }

  void populateForm(Activity activity) {
    sector = AppConstants.sectors.contains(activity.sector)
        ? activity.sector
        : AppConstants.sectors.last; // 'Other'
    if (sector == 'Other') customSectorCtl.text = activity.sector;

    subSector = activity.subSector;
    selectedStatus = AppConstants.prStatuses.contains(activity.status)
        ? activity.status
        : AppConstants.prStatuses.last; // 'Other'
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
    budgetCtl.text = activity.totalBudget > 0
        ? CurrencyInputFormatter.formatDouble(activity.totalBudget)
        : '';
    
    inputtedAmountCtl.text = activity.inputtedAmount > 0
        ? CurrencyInputFormatter.formatDouble(activity.inputtedAmount)
        : '';

    double totalPRs = 0;
    for (var log in activity.prLogs) {
      totalPRs += log.prAmount;
    }
    totalProcurementCtl.text = CurrencyInputFormatter.formatDouble(totalPRs);

    ppmpAmountCtl.text = activity.ppmpAmount > 0
        ? CurrencyInputFormatter.formatDouble(activity.ppmpAmount)
        : (activity.totalBudget > 0 ? CurrencyInputFormatter.formatDouble(activity.totalBudget) : '');

    ppmpBalanceCtl.text = CurrencyInputFormatter.formatDouble(activity.ppmpBalanceCalculated);
    ppmpCtl.text = CurrencyInputFormatter.formatDouble(activity.ppmpBalanceCalculated);
    prBalanceCtl.text = CurrencyInputFormatter.formatDouble(activity.prBalanceCalculated);
    
    prLogs = List.from(activity.prLogs);

    // Accomplishment fields
    actualConductCtl.text = activity.actualConduct;
    accommRemarksCtl.text = activity.accommRemarks;

    // Appropriations
    appropCtl.text = CurrencyInputFormatter.formatDouble(activity.appropriation);
    trainingSeminarCtl.text = CurrencyInputFormatter.formatDouble(activity.trainingSeminarAmount);
    meetingsCtl.text = CurrencyInputFormatter.formatDouble(activity.meetingsAmount);
    df20Ctl.text = CurrencyInputFormatter.formatDouble(activity.df20Amount);
    cpocCtl.text = CurrencyInputFormatter.formatDouble(activity.cpocAmount);
    gadCtl.text = CurrencyInputFormatter.formatDouble(activity.gadAmount);
    prNumberCtl.text = activity.prNumber;
    supplierAppropCtl.text = activity.supplierApprop;
    barcodeAppropCtl.text = activity.barcodeApprop;
    statusAppropCtl.text = activity.statusApprop;
    statusAppropDateCtl.text = activity.statusAppropDate ?? '';
    accountCodeCtl.text = activity.accountCode ?? '';

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

        entry.amountCtl.addListener(updateAllFinancials);

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
              unit: item.unit,
              quantity: item.quantity ?? 0.0,
              price: item.price ?? 0.0,
              quarter: item.quarter ?? 1,
              q1Qty: item.q1Qty ?? 0.0,
              q2Qty: item.q2Qty ?? 0.0,
              q3Qty: item.q3Qty ?? 0.0,
              q4Qty: item.q4Qty ?? 0.0,
              supplier: item.supplier,
              status: item.status,
              statusDate: item.statusDate,
              accountCode: item.accountCode,
            );
            be.amountCtl.addListener(updateAllFinancials);
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
      entry.amountCtl.addListener(updateAllFinancials);

      // Also check if any breakdown items belong to this legacy source
      if (activity.breakdown.isNotEmpty) {
        for (var item in activity.breakdown) {
          final be = BreakdownEntry(
            name: item.name,
            amount: item.amount,
            unit: item.unit,
            quantity: item.quantity ?? 0.0,
            price: item.price ?? 0.0,
            quarter: item.quarter ?? 1,
            q1Qty: item.q1Qty ?? 0.0,
            q2Qty: item.q2Qty ?? 0.0,
            q3Qty: item.q3Qty ?? 0.0,
            q4Qty: item.q4Qty ?? 0.0,
            supplier: item.supplier,
            status: item.status,
            statusDate: item.statusDate,
            accountCode: item.accountCode,
          );
          _addBreakdownListeners(be);
          entry.breakdownItems.add(be);
        }
      }

      fundSourceEntries.add(entry);
    }
    if (fundSourceEntries.isEmpty) {
      addFundSource();
    }

    updateAllFinancials();
  }



  Activity toActivity(String? id, {DateTime? createdAt}) {
    return Activity(
      id: id ?? '',
      sector: sector == 'Other' ? customSectorCtl.text : sector,
      subSector: subSector == 'Other' ? customSubSectorCtl.text : subSector,
      activityName: activityNameCtl.text,
      performanceIndicator: performanceIndicatorCtl.text,
      targetNo: int.tryParse(targetNoCtl.text) ?? 0,
      fundingSource: fundSourceEntries.isNotEmpty ? fundSourceEntries.first.fundingSource : 'Agri MOOE',
      objectOfExpenditure: fundSourceEntries.isNotEmpty ? fundSourceEntries.first.objectOfExpenditure : 'Other-MOE Expenses',
      q1Budget: CurrencyInputFormatter.parse(q1BudgetCtl.text),
      q2Budget: CurrencyInputFormatter.parse(q2BudgetCtl.text),
      q3Budget: CurrencyInputFormatter.parse(q3BudgetCtl.text),
      q4Budget: CurrencyInputFormatter.parse(q4BudgetCtl.text),
      ppmpAmount: CurrencyInputFormatter.parse(ppmpAmountCtl.text),
      prAmount: CurrencyInputFormatter.parse(prAmountCtl.text),
      prBalance: CurrencyInputFormatter.parse(prBalanceCtl.text),
      responsiblePerson: responsiblePerson == 'Other' ? customResponsiblePersonCtl.text : responsiblePerson,
      status: prLogs.isNotEmpty ? prLogs.last.status : (selectedStatus == 'Other' ? customStatusCtl.text : selectedStatus),
      targetDate: '$selectedMonth ${selectedToMonth != null ? '- $selectedToMonth ' : ''}$selectedYear',
      targetParticipants: targetParticipantsCtl.text,
      actualConduct: actualConductCtl.text,
      accommRemarks: accommRemarksCtl.text,
      location: locationCtl.text,
      otherMoeSuppliers: otherMoeSuppliersCtl.text,
      unitHead: unitHeadCtl.text,
      remarks: remarksCtl.text,
      statusDate: prLogs.isNotEmpty ? prLogs.last.statusDate : (customStatusDateCtl.text.isNotEmpty ? customStatusDateCtl.text : null),
      isDraft: false,
      breakdown: fundSourceEntries.expand((fs) => fs.breakdownItems.map((bi) => BreakdownItem(
        name: bi.nameCtl.text,
        amount: CurrencyInputFormatter.parse(bi.amountCtl.text),
        unit: bi.unitCtl.text,
        quantity: double.tryParse(bi.quantityCtl.text) ?? 0,
        price: CurrencyInputFormatter.parse(bi.priceCtl.text),
        quarter: bi.quarter,
        q1Qty: double.tryParse(bi.q1QtyCtl.text) ?? 0,
        q2Qty: double.tryParse(bi.q2QtyCtl.text) ?? 0,
        q3Qty: double.tryParse(bi.q3QtyCtl.text) ?? 0,
        q4Qty: double.tryParse(bi.q4QtyCtl.text) ?? 0,
        supplier: bi.supplierCtl.text,
        status: bi.statusCtl.text,
        statusDate: bi.statusDateCtl.text,
        accountCode: bi.accountCodeCtl.text,
      ))).toList(),
      fundSources: fundSourceEntries.map((fs) => FundSourceItem(
        fundingSource: fs.fundingSource == 'Other' ? fs.customFundingSourceCtl.text : fs.fundingSource,
        objectOfExpenditure: fs.objectOfExpenditure == 'Other' ? fs.customObjectOfExpenditureCtl.text : fs.objectOfExpenditure,
        amount: CurrencyInputFormatter.parse(fs.amountCtl.text),
      )).toList(),
      appropriation: CurrencyInputFormatter.parse(appropCtl.text),
      trainingSeminarAmount: CurrencyInputFormatter.parse(trainingSeminarCtl.text),
      meetingsAmount: CurrencyInputFormatter.parse(meetingsCtl.text),
      df20Amount: CurrencyInputFormatter.parse(df20Ctl.text),
      cpocAmount: CurrencyInputFormatter.parse(cpocCtl.text),
      gadAmount: CurrencyInputFormatter.parse(gadCtl.text),
      ppmpBalance: CurrencyInputFormatter.parse(ppmpBalanceCtl.text),
      prNumber: prNumberCtl.text,
      supplierApprop: supplierAppropCtl.text,
      barcodeApprop: barcodeAppropCtl.text,
      statusApprop: statusAppropCtl.text,
      statusAppropDate: statusAppropDateCtl.text,
      accountCode: accountCodeCtl.text,
      prLogs: prLogs,
      inputtedAmount: CurrencyInputFormatter.parse(inputtedAmountCtl.text),
    );
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
    accountCodeCtl.clear();
    inputtedAmountCtl.clear();
    totalProcurementCtl.clear();
    ppmpAmountCtl.clear();
    prLogs.clear();

    for (var fs in fundSourceEntries) {
      fs.amountCtl.removeListener(updateAllFinancials);
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
    accountCodeCtl.dispose();
    inputtedAmountCtl.dispose();
    totalProcurementCtl.dispose();
    ppmpAmountCtl.dispose();
    for (var fs in fundSourceEntries) {
      fs.dispose();
    }
    super.dispose();
  }
}

