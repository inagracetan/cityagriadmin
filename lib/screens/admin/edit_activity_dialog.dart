import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
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

  late ActivityFormProvider formProvider;
  List<String> availableStaff = AppConstants.staffList;
  List<String> availableSuppliers = [];
  bool saving = false;
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
    loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    formProvider = context.watch<ActivityFormProvider>();
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
    super.dispose();
  }
  Future<void> handleClose() async {
    if (!formProvider.isEdited(widget.activity) ||
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
      if (mounted) formProvider.closeForm();
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
                            if (formProvider.sector == 'Other')
                              GridRow(
                                label: 'A2',
                                fieldLabel: 'Custom Sector',
                                child: GridTextField(
                                  controller: formProvider.customSectorCtl,
                                  tooltip: 'Enter the custom section or unit name.',
                                ),
                              ),
                            if (formProvider.sector == AppConstants.sectorCrop) ...[
                              GridRow(
                                label: 'A2',
                                fieldLabel: 'Crop Program',
                                child: buildSubSectorCell(),
                              ),
                              if (formProvider.subSector == 'Other')
                                GridRow(
                                  label: 'A3',
                                  fieldLabel: 'Custom Program',
                                  child: GridTextField(
                                    controller: formProvider.customSubSectorCtl,
                                    tooltip: 'Enter the custom crop program name.',
                                  ),
                                ),
                            ],
                            GridRow(
                              label: 'A4',
                              fieldLabel: 'Unit Head',
                              child: GridTextField(
                                controller: formProvider.unitHeadCtl,
                                tooltip: 'Name of the unit head responsible.',
                              ),
                            ),
                            GridRow(
                              label: 'A5',
                              fieldLabel: 'Activity Name',
                              child: GridTextField(
                                controller: formProvider.activityNameCtl,
                                tooltip: 'The official name of this activity.',
                              ),
                            ),
                            GridRow(
                              label: 'A6',
                              fieldLabel: 'Account Code',
                              child: GridTextField(
                                controller: formProvider.accountCodeCtl,
                                tooltip: 'Primary accounting code for the whole activity.',
                              ),
                            ),
                            GridRow(
                              label: 'A7',
                              fieldLabel: 'Location',
                              child: GridTextField(
                                controller: formProvider.locationCtl,
                                tooltip: 'Venue or implementation site.',
                              ),
                            ),
                            GridRow(
                              label: 'A8',
                              fieldLabel: 'Indicator',
                              child: GridTextField(
                                controller: formProvider.performanceIndicatorCtl,
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
                                controller: formProvider.targetNoCtl,
                                keyboardType: TextInputType.number,
                                tooltip: 'Number of units, participants, or targets.',
                              ),
                            ),
                            GridRow(
                              label: 'B2',
                              fieldLabel: 'Approved Budget (Ref)',
                              child: GridCurrencyField(
                                controller: formProvider.budgetCtl,
                                readOnly: true,
                                tooltip: 'Reference budget calculated from breakdowns.',
                              ),
                            ),
                            GridRow(
                              label: 'B3',
                              fieldLabel: 'PPMP Amount',
                              child: GridCurrencyField(
                                controller: formProvider.ppmpAmountCtl,
                                tooltip: 'Allocated amount in the PPMP.',
                              ),
                            ),
                            GridRow(
                              label: 'B4',
                              fieldLabel: 'Inputted Amount (Override)',
                              helpText:
                                  'Manually set the approved budget if needed.',
                              child: GridCurrencyField(
                                controller: formProvider.inputtedAmountCtl,
                                onChanged: (v) => formProvider.updateAllFinancials(),
                                tooltip: 'Override the calculated budget with this manual value.',
                              ),
                            ),
                            GridRow(
                              label: 'B5',
                              fieldLabel: 'PPMP Balance (Auto)',
                              child: GridCurrencyField(
                                controller: formProvider.ppmpCtl,
                                readOnly: true,
                                tooltip: 'Remaining balance after procurement logs.',
                              ),
                            ),
                            GridRow(
                              label: 'B6',
                              fieldLabel: 'Participants',
                              child: GridTextField(
                                controller: formProvider.targetParticipantsCtl,
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
                            ...formProvider.prLogs.asMap().entries.map((entry) {
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
                                              formProvider.prLogs.removeAt(idx);
                                              formProvider.updateAllFinancials();
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
                                          formProvider.updateAllFinancials();
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
                                          formProvider.updateAllFinancials();
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
                                  formProvider.prLogs.add(
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
                                  formProvider.updateAllFinancials();
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
                                controller: formProvider.totalProcurementCtl,
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
                            if (formProvider.responsiblePerson == 'Other')
                              GridRow(
                                label: 'D2',
                                fieldLabel: 'Custom Person',
                                child: GridTextField(
                                  controller: formProvider.customResponsiblePersonCtl,
                                ),
                              ),
                            GridRow(
                              label: 'D3',
                              fieldLabel: 'Activity Status',
                              helpText: 'Overall status of the activity.',
                              child: buildStatusCell(),
                            ),
                            if (formProvider.selectedStatus == 'Other')
                              GridRow(
                                label: 'D4',
                                fieldLabel: 'Custom Status',
                                child: GridTextField(
                                  controller: formProvider.customStatusCtl,
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
                                controller: formProvider.remarksCtl,
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
                          controller: formProvider.otherMoeSuppliersCtl,
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
                          controller: formProvider.actualConductCtl,
                          maxLines: 2,
                        ),
                      ),
                      GridRow(
                        label: 'G2',
                        fieldLabel: 'Remarks',
                        child: GridTextField(
                          controller: formProvider.accommRemarksCtl,
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
    value: formProvider.sector,
    options: [...AppConstants.sectors, 'Other'],
    onChanged: (val) => formProvider.setSector(val!),
  );

  Widget buildSubSectorCell() => GridDropdown<String?>(
    value: formProvider.subSector,
    options: [null, ...AppConstants.subSectors],
    onChanged: (val) => formProvider.setSubSector(val),
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
          (availableStaff.contains(formProvider.responsiblePerson) ||
              formProvider.responsiblePerson == 'Other')
          ? formProvider.responsiblePerson
          : null,
      options: [...availableStaff, 'Other'],
      onChanged: (val) => formProvider.setResponsiblePerson(val!),
    );
  }

  Widget buildStatusCell() => GridDropdown<String>(
    value: formProvider.selectedStatus,
    options: [...AppConstants.prStatuses, 'Other'],
    onChanged: (val) => formProvider.setStatus(val!),
  );

  Widget buildMonthCell() => GridDropdown<String>(
    value: formProvider.selectedMonth,
    options: AppConstants.months,
    onChanged: (val) => formProvider.setMonth(val!),
  );
  Widget buildToMonthCell() => GridDropdown<String?>(
    value: formProvider.selectedToMonth,
    options: [null, ...AppConstants.months],
    onChanged: (val) => formProvider.setToMonth(val),
  );
  Widget buildYearCell() => GridDropdown<String>(
    value: formProvider.selectedYear,
    options: AppConstants.years,
    onChanged: (val) => formProvider.setYear(val!),
  );

  Widget buildFundSourcesSection() {
    return Column(
      children: [
        ...formProvider.fundSourceEntries.asMap().entries.map((entry) {
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
                    'B${idx + 1}',
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
                            if (formProvider.fundSourceEntries.length > 1)
                              Tooltip(
                                message: 'Remove this fund source.',
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() {
                                    formProvider.fundSourceEntries.removeAt(idx).dispose();
                                    formProvider.updateAllFinancials();
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
                                  formProvider.sector,
                                  subSector: formProvider.subSector,
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
            formProvider.fundSourceEntries.add(
              FundSourceEntry()..amountCtl.addListener(formProvider.updateAllFinancials),
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
      children: formProvider.fundSourceEntries.asMap().entries.map((entry) {
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
                            formProvider.updateAllFinancials();
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
              BreakdownEntry()..amountCtl.addListener(formProvider.updateAllFinancials),
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
            onPressed: save,
            label: 'SAVE CHANGES',
            variant: ButtonVariant.primary,
            isLoading: formProvider.isSaving,
            tooltip: 'Apply and save all modifications made to this activity.',
          ),
        ],
      ),
    );
  }

  Future<void> save() async {
    if (formProvider.isSaving) return;
    if (!formKey.currentState!.validate()) return;

    final success = await formProvider.saveForm(
      context,
      activityId: widget.activity.id,
      isEdit: true,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes Saved Successfully')),
      );
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
        if (mounted) formProvider.closeForm();
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

