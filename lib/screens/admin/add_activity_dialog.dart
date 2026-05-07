import 'package:cityagriadmin/models/budget_line.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/activity_templates.dart';
import '../../core/constants.dart';
import '../../core/currency_formatter.dart';
import '../../core/responsive_utils.dart';
import '../../models/activity.dart';
import '../../models/pr_log.dart';
import '../../services/activity_form_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/enhanced_buttons_dialogs.dart';
import '../../widgets/grid_form_fields.dart';

// ── Modern design constants ─────────────────────────────────────────────
const modernGreen = Color(0xFF1B5E20);
const modernDark = Color(0xFF064E3B);
const border = Color(0xFFE2E8F0);

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
  int currentStep = 0;

  late ActivityFormProvider formProvider;
  List<BudgetLine> budgetLines = [];

  final List<String> steps = ['Classification', 'Budgeting', 'Procurement'];
  final List<IconData> stepIcons = [
    Icons.info_outline,
    Icons.account_balance_wallet_outlined,
    Icons.shopping_cart_outlined,
  ];

  @override
  void initState() {
    super.initState();
    // Use read for initialization tasks
    final initialProvider = context.read<ActivityFormProvider>();

    // Sync initial state if needed
    if (widget.initialResponsiblePersons != null &&
        widget.initialResponsiblePersons!.isNotEmpty) {
      initialProvider.setResponsiblePerson(
        widget.initialResponsiblePersons!.first,
      );
    }

    initialProvider.loadStaffAndSuppliers(widget.fbService);
    _loadBudgetLines();
  }

  Future<void> _loadBudgetLines() async {
    try {
      final lines = await widget.fbService.streamBudgetLines().first;
      setState(() {
        budgetLines = lines;
      });
    } catch (e) {
      debugPrint('Error loading budget lines: $e');
    }
  }

  /// Get all fund sources that support the given object of expenditure
  List<String> _getFundSourcesForExpenditure(String objectOfExpenditure) {
    final sources = budgetLines
        .where((line) => line.objectOfExpenditure == objectOfExpenditure)
        .map((line) => line.fundSource)
        .toSet()
        .toList();
    return sources;
  }

  /// Add rows for all fund sources supporting a given object of expenditure
  void _addRowsForExpenditure(
    FundSourceEntry currentEntry,
    String objectOfExpenditure,
  ) {
    final fundSources = _getFundSourcesForExpenditure(objectOfExpenditure);

    if (fundSources.isEmpty) {
      // If no specific budget lines found, use all available fund sources
      fundSources.addAll(AppConstants.fundingSources);
    }

    // Add entries for fund sources not already in the list
    for (final fundSource in fundSources) {
      final alreadyExists = fundSourceEntries.any(
        (entry) =>
            entry.fundingSource == fundSource &&
            entry.objectOfExpenditure == objectOfExpenditure,
      );

      if (!alreadyExists) {
        final newEntry = FundSourceEntry(
          initialSource: fundSource,
          initialOE: objectOfExpenditure,
        );
        newEntry.amountCtl.addListener(updateTotalBudget);
        fundSourceEntries.add(newEntry);
      }
    }

    if (mounted) {
      setState(() {});
      updateTotalBudget();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    formProvider = context.watch<ActivityFormProvider>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool saving = false;
  String activityStatus = AppConstants.statusPRPreparation;
  Set<String> selectedMonths = {'January'};

  // Aliases for easier access to provider members
  TextEditingController get activityNameCtl => formProvider.activityNameCtl;
  TextEditingController get unitHeadCtl => formProvider.unitHeadCtl;
  TextEditingController get performanceIndicatorCtl =>
      formProvider.performanceIndicatorCtl;
  TextEditingController get locationCtl => formProvider.locationCtl;
  TextEditingController get targetNoCtl => formProvider.targetNoCtl;
  TextEditingController get budgetCtl => formProvider.budgetCtl;
  TextEditingController get ppmpCtl => formProvider.ppmpCtl;
  TextEditingController get prAmountCtl => formProvider.prAmountCtl;
  TextEditingController get targetParticipantsCtl =>
      formProvider.targetParticipantsCtl;
  TextEditingController get remarksCtl => formProvider.remarksCtl;
  TextEditingController get accountCodeCtl => formProvider.accountCodeCtl;
  TextEditingController get inputtedAmountCtl => formProvider.inputtedAmountCtl;
  TextEditingController get ppmpAmountCtl => formProvider.ppmpAmountCtl;
  TextEditingController get customSectorCtl => formProvider.customSectorCtl;
  TextEditingController get customSubSectorCtl =>
      formProvider.customSubSectorCtl;
  TextEditingController get customResponsiblePersonCtl =>
      formProvider.customResponsiblePersonCtl;
  TextEditingController get customFundingSourceCtl =>
      formProvider.customFundingSourceCtl;
  TextEditingController get customStatusCtl => formProvider.customStatusCtl;
  TextEditingController get customStatusDateCtl =>
      formProvider.customStatusDateCtl;
  TextEditingController get customObjectOfExpenditureCtl =>
      formProvider.customObjectOfExpenditureCtl;

  String get sector => formProvider.sector;
  set sector(String v) => formProvider.setSector(v);
  String? get subSector => formProvider.subSector;
  set subSector(String? v) => formProvider.setSubSector(v);
  String get responsiblePerson => formProvider.responsiblePerson;
  set responsiblePerson(String v) => formProvider.setResponsiblePerson(v);
  String get selectedYear => formProvider.selectedYear;
  set selectedYear(String v) => formProvider.setYear(v);

  List<PRLog> get prLogs => formProvider.prLogs;
  List<FundSourceEntry> get fundSourceEntries => formProvider.fundSourceEntries;
  List<String> get availableStaff => formProvider.availableStaff;

  void updateTotalBudget() {
    formProvider.updateAllFinancials();
    if (mounted) setState(() {});
  }

  void _loadTemplate(ActivityTemplate template) {
    formProvider.loadTemplate(template);
    if (mounted) setState(() {});
  }

  bool get canPop => !isEdited;

  bool get isEdited =>
      activityNameCtl.text.trim().isNotEmpty ||
      budgetCtl.text.trim().isNotEmpty && budgetCtl.text.trim() != '0.00' ||
      fundSourceEntries.length > 1;

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

  List<String> get filteredSubSectors {
    if (sector == AppConstants.sectorCrop) {
      return ['Rice', 'Corn', 'HVCDP', 'Organic Program'];
    }
    if (sector == 'Inland Fisheries Section') {
      return ['Tilapia', 'Bangus', 'Seaweeds'];
    }
    return AppConstants.subSectors;
  }

  String get filteredSectionHead {
    if (sector == AppConstants.sectorCrop) return 'Engr. Richard B. Leono';
    if (sector == 'Administrative Support Services Unit') return 'Admin Head';
    return 'Section Head';
  }

  bool get hasBudgetWarning {
    final budget = CurrencyInputFormatter.parse(budgetCtl.text);
    final prAmount = CurrencyInputFormatter.parse(prAmountCtl.text);
    return prAmount > budget && budget > 0;
  }

  bool get isSaveDisabled {
    return saving ||
        activityNameCtl.text.isEmpty ||
        accountCodeCtl.text.isEmpty ||
        CurrencyInputFormatter.parse(budgetCtl.text) <= 0;
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await handleClose();
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 900),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            buildTitleBar(),
            GridStatusBreadcrumbs(
              currentStatus: activityStatus,
              statuses: [
                AppConstants.statusPRPreparation,
                AppConstants.statusBACProcessing,
                AppConstants.statusObreAbstractSig,
                AppConstants.statusCompleted,
              ],
              onStatusChanged: (val) => setState(() => activityStatus = val),
            ),
            GridStepIndicator(
              currentStep: currentStep,
              steps: steps,
              icons: stepIcons,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      _buildStepGuidance(),
                      if (currentStep == 0) buildStep1(),
                      if (currentStep == 1) buildStep2(),
                      if (currentStep == 2) buildStep3(),
                      const SizedBox(height: 32),
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

  Widget _buildStepGuidance() {
    String title = "";
    String description = "";
    IconData icon = Icons.help_outline;

    switch (currentStep) {
      case 0:
        title = "Basic Information";
        description =
            "Start by defining what this activity is and who is responsible. You can use a template to save time.";
        icon = Icons.info_outline;
        break;
      case 1:
        title = "Budget & Planning";
        description =
            "Allocate funds and set targets. The PPMP Balance is automatically calculated based on your total budget.";
        icon = Icons.account_balance_wallet_outlined;
        break;
      case 2:
        title = "Procurement Details";
        description =
            "Enter the specific Purchase Request details and supplier information to track the actual spending.";
        icon = Icons.shopping_cart_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: modernGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: modernGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: modernDark,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTitleBar() => Container(
    height: 80,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [modernDark, modernGreen],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
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
          child: const Icon(
            Icons.add_task_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Agri Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Follow the steps to plan your procurement and budget.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: 'Minimize this form to continue later.',
          child: IconButton(
            onPressed: () =>
                context.read<ActivityFormProvider>().minimizeForm(),
            icon: const Icon(Icons.remove_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Discard changes and close this dialog.',
          child: IconButton(
            onPressed: handleClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    ),
  );

  Widget buildStep1() => Column(
    children: [
      const GridSectionHeader(label: '0', title: 'Quick Templates'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: modernGreen, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: GridDropdown<ActivityTemplate?>(
                value: null,
                hint: 'Select a program template to auto-fill...',
                options: [null, ...ActivityTemplates.templates],
                labelBuilder: (t) => t?.name ?? 'Select Template',
                tooltip:
                    'Select a program template to automatically fill the form fields.',
                onChanged: (val) {
                  if (val != null) _loadTemplate(val);
                },
              ),
            ),
          ],
        ),
      ),
      const GridSectionHeader(label: 'A', title: 'Classification & Assignment'),
      GridDualRow(
        label: '',
        icon: const Icon(
          Icons.business_center_outlined,
          size: 18,
          color: modernGreen,
        ),
        fieldLabel1: 'Section / Unit',
        helpText1:
            'The administrative unit or section proposing this activity.',
        child1: GridDropdown<String>(
          value: sector,
          options: [...AppConstants.sectors, 'Other'],
          tooltip:
              'The administrative unit or section proposing this activity.',
          onChanged: (val) {
            if (val != null) {
              setState(() {
                sector = val;
                subSector = null;
                unitHeadCtl.text = filteredSectionHead;
              });
            }
          },
        ),
        fieldLabel2: 'Program',
        helpText2: 'The specific agricultural program or project category.',
        child2: GridDropdown<String?>(
          value: subSector,
          options: [null, ...filteredSubSectors, 'Other'],
          tooltip: 'The specific agricultural program or project category.',
          onChanged: (val) => setState(() => subSector = val),
        ),
      ),
      if (sector == 'Other' || subSector == 'Other')
        GridDualRow(
          label: '',
          fieldLabel1: 'Custom Section',
          child1: GridTextField(
            controller: customSectorCtl,
            readOnly: sector != 'Other',
          ),
          fieldLabel2: 'Custom Program',
          child2: GridTextField(
            controller: customSubSectorCtl,
            readOnly: subSector != 'Other',
          ),
        ),
      GridRow(
        label: '',
        icon: const Icon(
          Icons.account_tree_outlined,
          size: 18,
          color: modernGreen,
        ),
        fieldLabel: 'Account Code',
        helpText:
            'Official COA account code for this expense (e.g. 5-02-02-010 for Training).',
        child: GridAccountCodePicker(
          controller: accountCodeCtl,
          hint: 'Search account code...',
          tooltip:
              'Official COA account code for this expense (e.g. 5-02-02-010 for Training).',
        ),
      ),
      GridRow(
        label: '',
        icon: const Icon(Icons.edit_note_rounded, size: 18, color: modernGreen),
        fieldLabel: 'PPA / Activity Name',
        child: GridTextField(
          controller: activityNameCtl,
          hint: 'e.g. Rice Technology Demonstration',
          tooltip: 'Enter the full name of the activity or project.',
        ),
      ),
      GridDualRow(
        label: '',
        icon: const Icon(
          Icons.person_pin_circle_outlined,
          size: 18,
          color: modernGreen,
        ),
        fieldLabel1: 'Section Head',
        child1: GridTextField(
          controller: unitHeadCtl,
          tooltip:
              'The head of the section or unit responsible for the activity.',
        ),
        fieldLabel2: 'Responsible',
        child2: GridDropdown<String>(
          value: availableStaff.contains(responsiblePerson)
              ? responsiblePerson
              : null,
          options: [...availableStaff, 'Other'],
          tooltip:
              'The person directly in charge of coordinating this activity.',
          onChanged: (v) => setState(() => responsiblePerson = v!),
        ),
      ),
      if (responsiblePerson == 'Other')
        GridRow(
          label: '',
          fieldLabel: 'Custom Responsible Person',
          child: GridTextField(
            controller: customResponsiblePersonCtl,
            tooltip:
                'Enter the name of the person responsible for this activity.',
          ),
        ),
      GridRow(
        label: '',
        icon: const Icon(
          Icons.calendar_month_outlined,
          size: 18,
          color: modernGreen,
        ),
        fieldLabel: 'Implementation Months',
        child: GridMonthGrid(
          selectedMonths: selectedMonths,
          onToggle: (m) => setState(() {
            if (selectedMonths.contains(m)) {
              if (selectedMonths.length > 1) selectedMonths.remove(m);
            } else {
              selectedMonths.add(m);
            }
          }),
        ),
      ),
      GridDualRow(
        label: '',
        icon: const Icon(Icons.map_outlined, size: 18, color: modernGreen),
        fieldLabel1: 'Location',
        child1: GridTextField(
          controller: locationCtl,
          tooltip: 'Where the activity will take place.',
        ),
        fieldLabel2: 'Remarks',
        child2: GridTextField(
          controller: remarksCtl,
          tooltip: 'Additional notes or details about the activity.',
        ),
      ),
    ],
  );

  Widget buildStep2() => Column(
    children: [
      const GridSectionHeader(label: 'B', title: 'Budgeting & Targets'),
      GridDualRow(
        label: '',
        icon: const Icon(
          Icons.trending_up_rounded,
          size: 18,
          color: modernGreen,
        ),
        fieldLabel1: 'Target No.',
        child1: GridTextField(
          controller: targetNoCtl,
          keyboardType: TextInputType.number,
          tooltip: 'Number of sessions, items, or sites targeted.',
        ),
        fieldLabel2: 'Target Participants',
        child2: GridTextField(
          controller: targetParticipantsCtl,
          tooltip: 'Expected number of beneficiaries or participants.',
        ),
      ),
      GridRow(
        label: '',
        icon: const Icon(
          Icons.track_changes_outlined,
          size: 18,
          color: modernGreen,
        ),
        fieldLabel: 'Performance Indicator',
        child: GridTextField(
          controller: performanceIndicatorCtl,
          tooltip: 'How the success of this activity will be measured.',
        ),
      ),
      GridDualRow(
        label: '',
        icon: const Icon(Icons.payments_outlined, size: 18, color: modernGreen),
        fieldLabel1: 'Approved Budget (Ref)',
        child1: GridCurrencyField(controller: budgetCtl, readOnly: true),
        fieldLabel2: 'PPMP Amount',
        child2: GridCurrencyField(
          controller: ppmpAmountCtl,
          tooltip:
              'Total amount allocated in the Project Procurement Management Plan.',
        ),
      ),
      GridRow(
        label: '',
        icon: const Icon(Icons.input_rounded, size: 18, color: modernGreen),
        fieldLabel: 'Inputted Amount (Approved Budget Override)',
        helpText:
            'Use this to manually set the budget if the calculated amount is incorrect.',
        child: GridCurrencyField(
          controller: inputtedAmountCtl,
          tooltip: 'Manually override the approved budget if necessary.',
        ),
      ),
      GridRow(
        label: '',
        icon: const Icon(
          Icons.account_balance_outlined,
          size: 18,
          color: modernGreen,
        ),
        fieldLabel: 'PPMP Balance (Auto)',
        helpText:
            'Remaining balance for this activity/account code after deducting PRs.',
        child: GridCurrencyField(
          controller: ppmpCtl,
          readOnly: true,
          tooltip:
              'Remaining balance for this activity/account code after deducting PRs.',
        ),
      ),
      const GridSectionHeader(label: 'E', title: 'Fund Sources'),
      buildFundSourcesSection(),
      const GridSectionHeader(label: 'F', title: 'Detailed Breakdown'),
      buildBreakdownsSection(),
    ],
  );

  Widget buildStep3() => Column(
    children: [
      const GridSectionHeader(
        label: 'C',
        title: 'Procurement Tracking (PR/PO List)',
      ),
      if (hasBudgetWarning)
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: GridFormTheme.warningBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GridFormTheme.warningRed),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: GridFormTheme.warningRed,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Procurement exceeds allocated budget',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GridFormTheme.warningRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ...prLogs.asMap().entries.map((entry) {
        final idx = entry.key;
        final log = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PR #${idx + 1}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: modernGreen,
                    ),
                  ),
                  Tooltip(
                    message: 'Delete this PR log.',
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => setState(() {
                        prLogs.removeAt(idx);
                        updateTotalBudget();
                      }),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              GridDualRow(
                label: '',
                fieldLabel1: 'PR Number',
                child1: GridTextField(
                  initialValue: log.prNumber,
                  onChanged: (v) => log.prNumber = v,
                ),
                fieldLabel2: 'PR Amount',
                child2: GridCurrencyField(
                  initialValue: log.prAmount,
                  onChanged: (v) {
                    log.prAmount = v;
                    updateTotalBudget();
                  },
                ),
              ),
              GridDualRow(
                label: '',
                fieldLabel1: 'Status',
                child1: GridDropdown<String>(
                  value: log.status,
                  options: AppConstants.prStatuses,
                  onChanged: (v) => setState(() => log.status = v!),
                ),
                fieldLabel2: 'Status Date',
                child2: GridDateField(
                  initialValue: log.statusDate,
                  onChanged: (v) => log.statusDate = v,
                ),
              ),
              GridDualRow(
                label: '',
                fieldLabel1: 'PO Number',
                child1: GridTextField(
                  initialValue: log.poNumber,
                  onChanged: (v) => log.poNumber = v,
                ),
                fieldLabel2: 'PO Amount',
                child2: GridCurrencyField(
                  initialValue: log.poAmount,
                  onChanged: (v) {
                    log.poAmount = v;
                    updateTotalBudget();
                  },
                ),
              ),
            ],
          ),
        );
      }),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: EnhancedButton(
          onPressed: () => setState(() {
            prLogs.add(
              PRLog(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                activityId: '',
                prNumber: '',
                prAmount: 0,
                status: AppConstants.statusPRStage,
                statusDate: DateTime.now().toString().split(' ').first,
                timestamp: DateTime.now(),
              ),
            );
          }),
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: 'Add Purchase Request (PR)',
          variant: ButtonVariant.secondary,
          tooltip:
              'Add a new Purchase Request log to track procurement progress.',
        ),
      ),
      const SizedBox(height: 24),
      GridDualRow(
        label: '',
        icon: const Icon(
          Icons.summarize_outlined,
          size: 18,
          color: modernGreen,
        ),
        fieldLabel1: 'Total PR Amount',
        child1: GridCurrencyField(controller: prAmountCtl, readOnly: true),
        fieldLabel2: 'Year',
        child2: GridDropdown<String>(
          value: selectedYear,
          options: AppConstants.years,
          onChanged: (v) => setState(() => selectedYear = v!),
        ),
      ),
    ],
  );

  Widget buildFundSourcesSection() {
    return Column(
      children: [
        ...fundSourceEntries.asMap().entries.map((entry) {
          final idx = entry.key;
          final fe = entry.value;
          return Container(
            color: idx.isEven ? Colors.white : GridFormTheme.rowEven,
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: GridFormTheme.accentGreen,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, color: GridFormTheme.border),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      buildSourceDropdownForFundSource(fe),
                      if (fe.fundingSource == 'Agri MOOE')
                        buildObjOfExpenditureDropdownForFundSource(fe),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, color: GridFormTheme.border),
                Expanded(
                  flex: 2,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    child: GridCurrencyField(
                      controller: fe.amountCtl,
                      isCompact: true,
                      readOnly: fe.breakdownItems.isNotEmpty,
                      onSubmitted: (v) => updateTotalBudget(),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Remove this fund source.',
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    onPressed: () => setState(() {
                      fundSourceEntries.removeAt(idx).dispose();
                      updateTotalBudget();
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
        EnhancedButton(
          onPressed: () => setState(() {
            final e = FundSourceEntry();
            e.amountCtl.addListener(updateTotalBudget);
            fundSourceEntries.add(e);
          }),
          icon: const Icon(Icons.add_rounded),
          label: 'Add Source',
          variant: ButtonVariant.tertiary,
          tooltip: 'Add another funding source for this activity.',
        ),
      ],
    );
  }

  Widget buildBreakdownsSection() => Column(
    children: fundSourceEntries.map((fe) => buildNestedBreakdown(fe)).toList(),
  );

  Widget buildNestedBreakdown(FundSourceEntry fe) {
    final bool isMobile = ResponsiveUtils.isMobile(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: GridFormTheme.highlightGreen,
          child: Row(
            children: [
              const Icon(Icons.list_alt, size: 14),
              const SizedBox(width: 8),
              Text(
                fe.fundingSource,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile && fe.breakdownItems.isNotEmpty)
          Container(
            height: 28,
            color: GridFormTheme.labelBg,
            child: const Row(
              children: [
                SizedBox(width: 30),
                Expanded(flex: 3, child: HeaderCell(label: 'DESCRIPTION')),
                Expanded(flex: 1, child: HeaderCell(label: 'UNIT')),
                Expanded(flex: 1, child: HeaderCell(label: 'Q1')),
                Expanded(flex: 1, child: HeaderCell(label: 'Q2')),
                Expanded(flex: 1, child: HeaderCell(label: 'Q3')),
                Expanded(flex: 1, child: HeaderCell(label: 'Q4')),
                Expanded(flex: 1, child: HeaderCell(label: 'QTY')),
                Expanded(flex: 2, child: HeaderCell(label: 'PRICE')),
                Expanded(flex: 2, child: HeaderCell(label: 'AMOUNT')),
                Expanded(flex: 2, child: HeaderCell(label: 'ACCT CODE')),
                Expanded(flex: 3, child: HeaderCell(label: 'SUPPLIER')),
                SizedBox(width: 40),
              ],
            ),
          ),
        ...fe.breakdownItems.asMap().entries.map((entry) {
          final be = entry.value;
          return Container(
            color: entry.key.isEven ? Colors.white : GridFormTheme.rowEven,
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: GridTextField(
                    controller: be.nameCtl,
                    isCompact: true,
                    tooltip: 'Description of the item or service.',
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GridAutocompleteField(
                    controller: be.unitCtl,
                    options: AppConstants.commonUnits,
                    hint: 'unit',
                    isCompact: true,
                    tooltip: 'Unit of measurement (e.g., pcs, units, sets).',
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GridTextField(
                    controller: be.q1QtyCtl,
                    isCompact: true,
                    onSubmitted: (v) => updateBreakdownAmount(be),
                    tooltip: 'Quantity required for Quarter 1.',
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GridTextField(
                    controller: be.q2QtyCtl,
                    isCompact: true,
                    onSubmitted: (v) => updateBreakdownAmount(be),
                    tooltip: 'Quantity required for Quarter 2.',
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GridTextField(
                    controller: be.q3QtyCtl,
                    isCompact: true,
                    onSubmitted: (v) => updateBreakdownAmount(be),
                    tooltip: 'Quantity required for Quarter 3.',
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GridTextField(
                    controller: be.q4QtyCtl,
                    isCompact: true,
                    onSubmitted: (v) => updateBreakdownAmount(be),
                    tooltip: 'Quantity required for Quarter 4.',
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GridTextField(
                    controller: be.quantityCtl,
                    readOnly: true,
                    isCompact: true,
                    tooltip:
                        'Automatically calculated total quantity (Q1+Q2+Q3+Q4).',
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GridCurrencyField(
                    controller: be.priceCtl,
                    isCompact: true,
                    onSubmitted: (v) => updateBreakdownAmount(be),
                    tooltip: 'Unit price for this item.',
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GridCurrencyField(
                    controller: be.amountCtl,
                    readOnly: true,
                    isCompact: true,
                    tooltip:
                        'Automatically calculated total amount (Price x Total Quantity).',
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GridAccountCodePicker(
                    controller: be.accountCodeCtl,
                    isCompact: true,
                    hint: 'code',
                    tooltip:
                        'Select the appropriate accounting classification code.',
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: GridTextField(
                    controller: be.supplierCtl,
                    isCompact: true,
                    tooltip: 'Specify the vendor or supplier for this item.',
                  ),
                ),
                Tooltip(
                  message: 'Delete this breakdown item.',
                  child: IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    onPressed: () => setState(() {
                      fe.breakdownItems.removeAt(entry.key).dispose();
                      updateTotalBudget();
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
        EnhancedButton(
          onPressed: () => setState(() {
            final nb = BreakdownEntry();
            nb.amountCtl.addListener(updateTotalBudget);
            fe.breakdownItems.add(nb);
          }),
          icon: const Icon(Icons.add_rounded),
          label: 'Add Item',
          variant: ButtonVariant.tertiary,
          tooltip: 'Add a new line item to this fund source breakdown.',
        ),
      ],
    );
  }

  void updateBreakdownAmount(BreakdownEntry be) {
    final q1 = double.tryParse(be.q1QtyCtl.text) ?? 0;
    final q2 = double.tryParse(be.q2QtyCtl.text) ?? 0;
    final q3 = double.tryParse(be.q3QtyCtl.text) ?? 0;
    final q4 = double.tryParse(be.q4QtyCtl.text) ?? 0;
    final total = q1 + q2 + q3 + q4;
    be.quantityCtl.text = total.toString();
    final price = CurrencyInputFormatter.parse(be.priceCtl.text);
    be.amountCtl.text = CurrencyInputFormatter.formatDouble(total * price);
    updateTotalBudget();
  }

  Widget buildSourceDropdownForFundSource(FundSourceEntry e) =>
      GridDropdown<String>(
        value: e.fundingSource,
        options: AppConstants.fundingSources,
        onChanged: (v) => setState(() {
          e.fundingSource = v!;
          if (v == 'Agri MOOE') {
            e.objectOfExpenditure = '$sector Appropriation';
          } else {
            e.objectOfExpenditure = null;
          }
        }),
      );
  Widget buildObjOfExpenditureDropdownForFundSource(FundSourceEntry e) =>
      GridDropdown<String>(
        value: e.objectOfExpenditure,
        options: AppConstants.getFilteredObjectsOfExpenditure(
          sector,
          fundingSource: e.fundingSource,
        ),
        onChanged: (v) {
          setState(() => e.objectOfExpenditure = v);
          // Auto-add rows for all fund sources supporting this expenditure
          if (v != null) {
            _addRowsForExpenditure(e, v);
          }
        },
      );

  Widget buildFooter() => Container(
    height: 90,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: border)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: [
        if (currentStep > 0)
          EnhancedButton(
            onPressed: () => setState(() => currentStep--),
            icon: const Icon(Icons.arrow_back_rounded),
            label: 'Back',
            variant: ButtonVariant.secondary,
            tooltip: 'Go back to the previous step.',
          ),
        const Spacer(),
        EnhancedButton(
          onPressed: handleClose,
          label: 'Cancel',
          variant: ButtonVariant.tertiary,
          tooltip: 'Discard all changes and exit.',
        ),
        const SizedBox(width: 16),
        if (currentStep < steps.length - 1)
          EnhancedButton(
            onPressed: () => setState(() => currentStep++),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: 'Next Step',
            variant: ButtonVariant.primary,
            tooltip: 'Proceed to the next part of the form.',
          )
        else
          EnhancedButton(
            onPressed: isSaveDisabled ? null : () => onSave(false),
            icon: const Icon(Icons.save_rounded),
            label: 'Complete & Save',
            variant: ButtonVariant.primary,
            tooltip:
                'Validate all information and save this activity to the database.',
          ),
      ],
    ),
  );

  void onSave(bool asDraft) async {
    if (saving) return;
    if (!asDraft) {
      if (!formKey.currentState!.validate()) return;

      // Mandate PR Log fields
      for (int i = 0; i < prLogs.length; i++) {
        final log = prLogs[i];
        if (log.prNumber.isEmpty ||
            log.prAmount <= 0 ||
            log.status.isEmpty ||
            log.statusDate == null ||
            log.statusDate!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please complete all fields for PR #${i + 1} (Number, Amount, Status, and Date)',
              ),
            ),
          );
          return;
        }
      }
    }
    setState(() => saving = true);
    try {
      final monthList = selectedMonths.toList()
        ..sort(
          (a, b) => AppConstants.months
              .indexOf(a)
              .compareTo(AppConstants.months.indexOf(b)),
        );
      final dateRange = monthList.length > 1
          ? '${monthList.first} - ${monthList.last} $selectedYear'
          : '${monthList.first} $selectedYear';

      final activity = Activity(
        id: '',
        sector: sector == 'Other' ? customSectorCtl.text : sector,
        subSector: subSector == 'Other' ? customSubSectorCtl.text : subSector,
        activityName: activityNameCtl.text,
        performanceIndicator: performanceIndicatorCtl.text,
        targetNo: int.tryParse(targetNoCtl.text) ?? 0,
        fundingSource: fundSourceEntries.first.fundingSource == 'Other'
            ? fundSourceEntries.first.customFundingSourceCtl.text
            : fundSourceEntries.first.fundingSource,
        objectOfExpenditure:
            fundSourceEntries.first.objectOfExpenditure == 'Other'
            ? fundSourceEntries.first.customObjectOfExpenditureCtl.text
            : fundSourceEntries.first.objectOfExpenditure,
        responsiblePerson: responsiblePerson == 'Other'
            ? customResponsiblePersonCtl.text
            : responsiblePerson,
        status: activityStatus,
        targetDate: dateRange,
        location: locationCtl.text,
        unitHead: unitHeadCtl.text,
        remarks: remarksCtl.text,
        accountCode: accountCodeCtl.text,
        isDraft: asDraft,
        inputtedAmount: CurrencyInputFormatter.parse(inputtedAmountCtl.text),
        prLogs: prLogs,
        fundSources: fundSourceEntries
            .map(
              (e) => FundSourceItem(
                fundingSource: e.fundingSource == 'Other'
                    ? e.customFundingSourceCtl.text
                    : e.fundingSource,
                amount: CurrencyInputFormatter.parse(e.amountCtl.text),
                objectOfExpenditure: e.objectOfExpenditure == 'Other'
                    ? e.customObjectOfExpenditureCtl.text
                    : e.objectOfExpenditure,
              ),
            )
            .toList(),
        breakdown: fundSourceEntries
            .expand(
              (fe) => fe.breakdownItems.map(
                (be) => BreakdownItem(
                  name: be.nameCtl.text,
                  amount: CurrencyInputFormatter.parse(be.amountCtl.text),
                  unit: be.unitCtl.text,
                  quantity: double.tryParse(be.quantityCtl.text),
                  price: CurrencyInputFormatter.parse(be.priceCtl.text),
                  q1Qty: double.tryParse(be.q1QtyCtl.text),
                  q2Qty: double.tryParse(be.q2QtyCtl.text),
                  q3Qty: double.tryParse(be.q3QtyCtl.text),
                  q4Qty: double.tryParse(be.q4QtyCtl.text),
                  fundingSource: fe.fundingSource,
                  objectOfExpenditure: fe.objectOfExpenditure,
                  supplier: be.supplierCtl.text,
                  accountCode: be.accountCodeCtl.text,
                ),
              ),
            )
            .toList(),
      );
      await widget.fbService.addActivity(activity);
      if (mounted) {
        context.read<ActivityFormProvider>().closeForm();
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

class HeaderCell extends StatelessWidget {
  final String label;
  const HeaderCell({super.key, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: GridFormTheme.labelText,
        ),
      ),
    );
  }
}
