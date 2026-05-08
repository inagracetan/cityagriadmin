import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/procurement.dart';
import '../../models/program.dart';
import '../../models/activity.dart';
import '../../widgets/skeleton_loading.dart';
import '../../models/budget_line.dart';
import '../../services/firebase_service.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../core/currency_formatter.dart';
import '../../widgets/enhanced_form_fields.dart';

class ProcurementFormDialog extends StatefulWidget {
  final Procurement? procurement; // If null, it's an "Add" operation
  final Program? initialProgram;
  final FirebaseService fbService;

  const ProcurementFormDialog({
    super.key,
    this.procurement,
    this.initialProgram,
    required this.fbService,
  });

  @override
  State<ProcurementFormDialog> createState() => _ProcurementFormDialogState();
}

class _ProcurementFormDialogState extends State<ProcurementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _prNumberController;
  late TextEditingController _prAmountController;
  late TextEditingController _supplierController;
  late TextEditingController _poNumberController;
  late TextEditingController _poAmountController;
  late TextEditingController _poDateController;
  
  String? _selectedProgramId;
  String? _selectedActivityId; // Added
  String? _selectedStatus;
  String? _selectedFundSource;
  String? _selectedObjectOfExpenditure;
  bool _isSubmitting = false;

  List<BudgetLine> _budgetLines = [];
  List<Program> _programs = []; 
  List<Activity> _activities = [];
  List<Activity> _filteredActivities = [];

  final List<String> _statuses = AppConstants.prStatuses;
  final List<String> _suppliers = AppConstants.commonSuppliers; // Added
  final TextEditingController _remarksController = TextEditingController(); // Added

  @override
  void initState() {
    super.initState();
    final p = widget.procurement;
    _prNumberController = TextEditingController(text: p?.prNumber ?? '');
    _prAmountController = TextEditingController(text: p?.prAmount.toString() ?? '');
    _supplierController = TextEditingController(text: p?.supplier ?? '');
    _poNumberController = TextEditingController(text: p?.poNumber ?? '');
    _poAmountController = TextEditingController(text: p?.poAmount.toString() ?? '');
    _poDateController = TextEditingController(text: p?.poDate ?? '');
    
    _selectedProgramId = p?.programId ?? widget.initialProgram?.id;
    _selectedActivityId = p?.activityId; // Assuming field exists or will be added
    _selectedStatus = p?.status ?? AppConstants.statusPRStage;
    _selectedFundSource = p?.fundSource;
    _selectedObjectOfExpenditure = p?.objectOfExpenditure;
    _remarksController.text = p?.remarks ?? '';

    _loadData(); // Changed
  }

  Future<void> _loadData() async {
    final lines = await widget.fbService.streamBudgetLines().first;
    final progs = await widget.fbService.streamPrograms().first;
    final acts = await widget.fbService.streamActivities().first;
    
    if (mounted) {
      setState(() {
        _budgetLines = lines;
        _programs = progs;
        _activities = acts;
        _filterActivities();

        // If not editing, and there's only one fund source, select it
        if (!(widget.procurement != null)) {
          final sources = lines.map((l) => l.fundSource).toSet().toList();
          if (sources.length == 1) _selectedFundSource = sources.first;
        }
      });
    }
  }

  void _filterActivities() {
    if (_selectedProgramId == null || _programs.isEmpty) {
      _filteredActivities = [];
    } else {
      final selectedProg = _programs.firstWhere(
        (p) => p.id == _selectedProgramId,
        orElse: () => _programs.first,
      );
      final progName = selectedProg.name.toLowerCase();

      // Filter activities by matching sector or subsector to program name
      _filteredActivities = _activities.where((a) {
        final sectorMatch = progName.contains(a.sector.toLowerCase());
        final subSectorMatch = a.subSector != null && 
                             a.subSector!.isNotEmpty && 
                             progName.contains(a.subSector!.toLowerCase());
        return sectorMatch || subSectorMatch;
      }).toList();
    }
  }

  @override
  void dispose() {
    _prNumberController.dispose();
    _prAmountController.dispose();
    _supplierController.dispose();
    _poNumberController.dispose();
    _poAmountController.dispose();
    _poDateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProgramId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program')),
      );
      return;
    }
    if (_selectedFundSource == null || _selectedObjectOfExpenditure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select budget details')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prAmount = CurrencyInputFormatter.parse(_prAmountController.text);
      final poAmount = CurrencyInputFormatter.parse(_poAmountController.text);

      final procurement = Procurement(
        id: widget.procurement?.id ?? '',
        programId: _selectedProgramId!,
        activityId: _selectedActivityId, // Link to activity
        prNumber: _prNumberController.text,
        prAmount: prAmount,
        prBalance: 0.0,
        poNumber: _poNumberController.text,
        poAmount: poAmount,
        poDate: _poDateController.text.isEmpty ? null : _poDateController.text,
        supplier: _supplierController.text,
        remarks: _remarksController.text, // Added
        status: _selectedStatus!,
        statusDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ppmpAmount: 0.0,
        objectOfExpenditure: _selectedObjectOfExpenditure!,
        fundSource: _selectedFundSource!,
        createdAt: widget.procurement?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'Admin',
      );

      if (widget.procurement == null) {
        await widget.fbService.addProcurement(procurement);
      } else {
        await widget.fbService.updateProcurement(
          procurement,
          widget.procurement!.prAmount,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    final isEdit = widget.procurement != null;

    final availableObjects = _budgetLines
        .where((l) => l.fundSource == _selectedFundSource)
        .map((l) => l.objectOfExpenditure)
        .toSet()
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEdit ? Icons.edit_note_rounded : Icons.add_task_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isEdit ? 'Edit Procurement' : 'New Procurement Request',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Program Selection
                      // Program & Activity Selection
                      if (widget.initialProgram != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_tree_outlined, color: Color(0xFF1B5E20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Program: ${widget.initialProgram!.name}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      _buildDropdown(
                        label: 'Link to Project/Activity',
                        value: _selectedActivityId,
                        items: _filteredActivities.map((a) => a.id).toList(),
                        itemLabels: _filteredActivities.map((a) => a.activityName).toList(),
                        onChanged: (v) => setState(() => _selectedActivityId = v),
                        icon: Icons.assignment_outlined,
                      ),

                      const SizedBox(height: 20),

                      // Budget Source Section
                      Text(
                        'BUDGET ALLOCATION',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Slate.shade400,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildDropdown(
                        label: 'Fund Source',
                        value: _selectedFundSource,
                        items: _budgetLines.map((l) => l.fundSource).toSet().toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedFundSource = v;
                            _selectedObjectOfExpenditure = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Object of Expenditure',
                        value: _selectedObjectOfExpenditure,
                        items: availableObjects,
                        onChanged: (v) => setState(() => _selectedObjectOfExpenditure = v),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      Text(
                        'PROCUREMENT DETAILS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Slate.shade400,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _prNumberController,
                              label: 'PR Number',
                              icon: Icons.numbers_rounded,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _prAmountController,
                              label: 'PR Amount',
                              icon: Icons.payments_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Supplier',
                              value: _supplierController.text.isEmpty ? null : _supplierController.text,
                              items: _suppliers,
                              onChanged: (v) => setState(() => _supplierController.text = v ?? ''),
                              icon: Icons.business_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _remarksController,
                        label: 'Remarks',
                        icon: Icons.chat_bubble_outline_rounded,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      Text(
                        'PURCHASE ORDER (OPTIONAL)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Slate.shade400,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _poNumberController,
                              label: 'PO Number',
                              icon: Icons.confirmation_number_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _poAmountController,
                              label: 'PO Amount',
                              icon: Icons.monetization_on_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Status',
                              value: _selectedStatus,
                              items: _statuses,
                              onChanged: (v) => setState(() => _selectedStatus = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _poDateController,
                              label: 'PO Date',
                              icon: Icons.calendar_today_rounded,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  _poDateController.text = DateFormat('yyyy-MM-dd').format(date);
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            height: 48,
                            width: 160,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SkeletonLoading(height: 20, width: 80)
                                  : Text(isEdit ? 'Save Changes' : 'Create PR'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onTap: onTap,
      readOnly: onTap != null,
      maxLines: maxLines,
      inputFormatters: keyboardType == TextInputType.number ? [CurrencyInputFormatter()] : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Slate.shade400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    List<String>? itemLabels,
    required void Function(String?) onChanged,
    IconData? icon,
  }) {
    // Map item labels if provided, otherwise use items
    final List<DropdownMenuEntry<String>> entries = List.generate(items.length, (index) {
      return DropdownMenuEntry<String>(
        value: items[index],
        label: itemLabels != null ? itemLabels[index] : items[index],
      );
    });

    return EnhancedSearchableDropdownField<String>(
      label: label,
      value: value,
      entries: entries,
      onSelected: onChanged,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Slate.shade400) : null,
      width: double.infinity,
    );
  }
}

