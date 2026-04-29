import '../core/constants.dart';

enum BudgetSource {
  agriMooe,
  df20,
  gad,
  cpoc,
  cdrrmo,
  capitalOutlay,
  mayorsFund,
  other,
}

enum ObjectOfExpenditure {
  travelling,
  training,
  officeSupplies,
  fuelOil,
  communication,
  repairMaintenance,
  meetings,
  otherMoe,
  personnelDevelopment,
  other,
}

enum ActivityStatus {
  planned,
  prPrepared,
  bacApprovedOBRE,
  obreAbstractSignature,
  poPrepared,
  obligated,
  iar,
  completed,
  noBudget,
  noBudgetYet,
  bacShopping,
  bacOffice,
  bacForPRNumber,
  bacBidding,
  recanvas,
}

class BreakdownItem {
  final String name;
  final double amount;
  final String? unit;
  final double? quantity;
  final double? price;
  final int? quarter; // Primary quarter (legacy support or if only one is selected)
  final double? q1Qty;
  final double? q2Qty;
  final double? q3Qty;
  final double? q4Qty;
  final String? fundingSource;
  final String? objectOfExpenditure;
  final String? supplier;
  final String? status;
  final String? statusDate;

  BreakdownItem({
    required this.name,
    required this.amount,
    this.unit,
    this.quantity,
    this.price,
    this.quarter,
    this.q1Qty,
    this.q2Qty,
    this.q3Qty,
    this.q4Qty,
    this.fundingSource,
    this.objectOfExpenditure,
    this.supplier,
    this.status,
    this.statusDate,
  });

  String get sourceText {
    final s = fundingSource ?? '';
    final o = objectOfExpenditure ?? '';
    if (s.isEmpty && o.isEmpty) return '';
    if (s.isNotEmpty && o.isNotEmpty) {
      if (s == 'Agri MOOE') return '$o ($s)';
      return '$s - $o';
    }
    return s.isNotEmpty ? s : o;
  }

  String fullDisplayNameWithFallback(String parentFS, String? parentOE) {
    final fs = (fundingSource != null && fundingSource!.isNotEmpty) ? fundingSource! : parentFS;
    final oe = (objectOfExpenditure != null && objectOfExpenditure!.isNotEmpty) ? objectOfExpenditure! : (parentOE ?? '');
    
    if (fs == 'Agri MOOE') return oe.isNotEmpty ? '$oe ($fs)' : fs;
    return oe.isNotEmpty ? '$fs - $oe' : fs;
  }

  double get totalQuantity => quantity ?? (q1Qty ?? 0) + (q2Qty ?? 0) + (q3Qty ?? 0) + (q4Qty ?? 0);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit ?? '',
      'quantity': quantity ?? 0.0,
      'price': price ?? 0.0,
      'quarter': quarter ?? 0,
      'q1_qty': q1Qty ?? 0.0,
      'q2_qty': q2Qty ?? 0.0,
      'q3_qty': q3Qty ?? 0.0,
      'q4_qty': q4Qty ?? 0.0,
      'fundingSource': fundingSource ?? '',
      'objectOfExpenditure': objectOfExpenditure ?? '',
      'supplier': supplier ?? '',
      'status': status ?? '',
      'statusDate': statusDate ?? '',
    };
  }

  factory BreakdownItem.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val.replaceAll(',', '')) ?? 0.0;
      }
      return 0.0;
    }

    String safeStr(dynamic v) => (v == null || v.toString().toLowerCase() == 'null') ? '' : v.toString();
    return BreakdownItem(
      name: safeStr(map['name']),
      amount: parseDouble(map['amount']),
      unit: safeStr(map['unit']),
      quantity: parseDouble(map['quantity']),
      price: parseDouble(map['price']),
      quarter: (map['quarter'] as num?)?.toInt(),
      q1Qty: parseDouble(map['q1_qty']),
      q2Qty: parseDouble(map['q2_qty']),
      q3Qty: parseDouble(map['q3_qty']),
      q4Qty: parseDouble(map['q4_qty']),
      fundingSource: safeStr(map['fundingSource']),
      objectOfExpenditure: safeStr(map['objectOfExpenditure']),
      supplier: safeStr(map['supplier']),
      status: safeStr(map['status']),
      statusDate: safeStr(map['statusDate']),
    );
  }
}

class FundSourceItem {
  final String fundingSource;
  final String? objectOfExpenditure;
  final double amount;

  FundSourceItem({
    required this.fundingSource,
    this.objectOfExpenditure,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'fundingSource': fundingSource,
      'objectOfExpenditure': objectOfExpenditure ?? '',
      'amount': amount,
    };
  }

  factory FundSourceItem.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val.replaceAll(',', '')) ?? 0.0;
      }
      return 0.0;
    }

    String safeStr(dynamic v) => (v == null || v.toString().toLowerCase() == 'null') ? '' : v.toString();
    return FundSourceItem(
      fundingSource: safeStr(map['fundingSource']).isEmpty ? 'Agri MOOE' : safeStr(map['fundingSource']),
      objectOfExpenditure: safeStr(map['objectOfExpenditure']),
      amount: parseDouble(map['amount']),
    );
  }
}

class Activity {
  String id;
  String
  sector; // Administrative Support Services Unit, Crop Section, Inland Fisheries Section, Institutional Development Section, Agriculture Logistics Section, Project Development Section, Monitoring and Evaluation Section, Integrated Agricultural Laboratory
  String? subSector; // Rice, Corn, HVCDP, Organic Program
  String activityName; // PPA
  String performanceIndicator;
  int targetNo;
  String fundingSource; // Agri MOOE, Special Funds, Capital Outlay
  String? objectOfExpenditure; // For Agri MOOE
  double q1Budget;
  double q2Budget;
  double q3Budget;
  double q4Budget;
  double actualExpenditure;
  double ppmpAmount;
  double prAmount;
  double prBalance;
  String responsiblePerson; // String as per requirement
  String status;
  String targetDate;
  String targetParticipants;
  String actualConduct; // used for ACCOM
  String accommRemarks; // used for ACCOM
  String? fundingInputtedBy;
  String? statusInputtedBy;
  String? location;
  String otherMoeSuppliers; // Added for Other-MOE multiple suppliers
  String? unit;
  String? unitHead;
  String remarks; // Added for general notes
  String? statusDate; // Custom date for status
  bool isDraft; // Whether this activity is a draft
  List<BreakdownItem> breakdown; // Added for breakdown
  List<FundSourceItem> fundSources; // Multiple funding & expenditures

  // ── Appropriations (Expenditure Summary) ──────────────────────────────
  double appropriation; // Total appropriation / budget allocated
  double trainingSeminarAmount; // Trainings and Seminar Expenses budget
  double meetingsAmount; // Meetings budget
  double df20Amount; // 20% DF amount
  double cpocAmount; // CPOC amount
  double gadAmount; // GAD amount
  double ppmpBalance; // PPMP Amount
  String prNumber; // PR number
  String supplierApprop; // Supplier (appropriation)
  String barcodeApprop; // Barcode
  String statusApprop; // Status (appropriation)
  String? statusAppropDate; // Date for PR status

  double get totalBudget => q1Budget + q2Budget + q3Budget + q4Budget;

  Activity({
    required this.id,
    required this.sector,
    this.subSector,
    required this.activityName,
    required this.performanceIndicator,
    required this.targetNo,
    required this.fundingSource,
    this.objectOfExpenditure,
    this.q1Budget = 0.0,
    this.q2Budget = 0.0,
    this.q3Budget = 0.0,
    this.q4Budget = 0.0,
    this.actualExpenditure = 0.0,
    this.ppmpAmount = 0.0,
    this.prAmount = 0.0,
    this.prBalance = 0.0,
    required this.responsiblePerson,
    required this.status,
    required this.targetDate,
    this.targetParticipants = '',
    this.actualConduct = '',
    this.accommRemarks = '',
    this.fundingInputtedBy,
    this.statusInputtedBy,
    this.location,
    this.otherMoeSuppliers = '',
    this.unit,
    this.unitHead,
    this.remarks = '',
    this.statusDate,
    this.isDraft = false,
    this.breakdown = const [],
    this.fundSources = const [],
    // Appropriations
    this.appropriation = 0.0,
    this.trainingSeminarAmount = 0.0,
    this.meetingsAmount = 0.0,
    this.df20Amount = 0.0,
    this.cpocAmount = 0.0,
    this.gadAmount = 0.0,
    this.ppmpBalance = 0.0,
    this.prNumber = '',
    this.supplierApprop = '',
    this.barcodeApprop = '',
    this.statusApprop = '',
    this.statusAppropDate,
  });

  double get approvedBudget => q1Budget + q2Budget + q3Budget + q4Budget;

  double get midYearBudget => q1Budget + q2Budget;

  double get wholeYearBudget => approvedBudget;

  /// Returns the sum of all breakdown item amounts.
  double get totalBreakdownAmount {
    if (breakdown.isEmpty) return 0.0;
    return breakdown.fold<double>(0, (sum, item) => sum + item.amount);
  }

  /// The effective PO Amount: prefers the sum of breakdown items if positive,
  /// otherwise falls back to the [actualExpenditure] field (cached total).
  double get effectivePOAmount {
    final sum = totalBreakdownAmount;
    return sum > 0 ? sum : actualExpenditure;
  }

  double get unexpendedBalance => approvedBudget - effectivePOAmount;

  double get unexpendedPPMP => ppmpBalance;

  double get unexpendedPR => approvedBudget - prAmount;

  bool get isLowBalance => approvedBudget > 0 && unexpendedBalance < 1000;

  String get formattedSource {
    final s = fundingSource;
    final o = objectOfExpenditure ?? '';
    if (s == 'Agri MOOE' && o.isNotEmpty) return '$o ($s)';
    return s;
  }

  String get quarter {
    final lower = targetDate.toLowerCase();
    
    // 1. Try parsing as a structured date first (e.g. "04/28/2026" or "2026-04-28")
    try {
      DateTime? dt;
      if (targetDate.contains('/')) {
        final parts = targetDate.split('/');
        if (parts.length == 3) {
          int? m = int.tryParse(parts[0]);
          int? d = int.tryParse(parts[1]);
          int? y = int.tryParse(parts[2]);
          if (m != null && m >= 1 && m <= 12) {
            dt = DateTime(y ?? DateTime.now().year, m, d ?? 1);
          }
        }
      } else if (targetDate.contains('-') && targetDate.length >= 10) {
        dt = DateTime.tryParse(targetDate);
      }
      
      if (dt != null) {
        if (dt.month >= 1 && dt.month <= 3) return 'Q1';
        if (dt.month >= 4 && dt.month <= 6) return 'Q2';
        if (dt.month >= 7 && dt.month <= 9) return 'Q3';
        if (dt.month >= 10 && dt.month <= 12) return 'Q4';
      }
    } catch (_) {}

    // 2. Fallback to month name keywords
    if (lower.contains('jan') || lower.contains('feb') || lower.contains('mar')) return 'Q1';
    if (lower.contains('apr') || lower.contains('may') || lower.contains('jun')) return 'Q2';
    if (lower.contains('jul') || lower.contains('aug') || lower.contains('sep')) return 'Q3';
    if (lower.contains('oct') || lower.contains('nov') || lower.contains('dec')) return 'Q4';

    return 'N/A';
  }

  factory Activity.fromFirestore(Map<String, dynamic> data, String id) {
    // Safely coerce a Firestore value to String — handles List<dynamic> gracefully
    String safeString(dynamic value, [String fallback = '']) {
      if (value == null || value.toString().toLowerCase() == 'null') return fallback;
      if (value is String) return value;
      if (value is List) return value.join(', ');
      return value.toString();
    }

    String rawStatus = safeString(data['status'], 'Planned');
    bool isDraft = data['is_draft'] ?? false;

    // Bridge old names to new name
    if (rawStatus == 'Draft') {
      rawStatus = 'Planned';
      isDraft = true;
    }
    if (rawStatus == 'Obre & Abstract Sig' || rawStatus == 'Obre & Abstract') {
      rawStatus = 'Obre & Abstract Signature';
    }

    final breakdown = (data['breakdown'] is List)
        ? (data['breakdown'] as List)
              .whereType<Map>()
              .map(
                (item) =>
                    BreakdownItem.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
        : (data['breakdown'] is String &&
              (data['breakdown'] as String).isNotEmpty)
        ? [BreakdownItem(name: data['breakdown'] as String, amount: 0.0)]
        : <BreakdownItem>[];

    final fundSources = (data['fund_sources'] is List)
        ? (data['fund_sources'] as List)
              .whereType<Map>()
              .map(
                (item) =>
                    FundSourceItem.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <FundSourceItem>[];

    // Migrate old funding source if fundSources is empty
    if (fundSources.isEmpty && data['funding_source'] != null) {
      String fs = safeString(data['funding_source'], 'Agri MOOE');
      // If it was "Special Funds" and has a special_fund_source, use that as fundingSource directly
      if (fs == 'Special Funds' && data['special_fund_source'] != null) {
        fs = data['special_fund_source'].toString();
      }
      fundSources.add(
        FundSourceItem(
          fundingSource: fs,
          objectOfExpenditure: data['object_of_expenditure'] as String?,
          amount: (data['q1_budget'] ?? data['approved_budget'] ?? 0)
              .toDouble(),
        ),
      );
    }

    String fs = safeString(data['funding_source'], 'Agri MOOE');
    String? ooe = data['object_of_expenditure'] as String?;

    // Migrate old "Special Funds" field
    if (fs == 'Special Funds' && data['special_fund_source'] != null) {
      fs = data['special_fund_source'].toString();
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val.replaceAll(',', '')) ?? 0.0;
      }
      return 0.0;
    }

    return Activity(
      id: id,
      sector: safeString(
        data['sector'],
        'Administrative Support Services Unit',
      ),
      subSector: data['sub_sector'] as String?,
      activityName: safeString(data['activity_name']),
      performanceIndicator: safeString(data['performance_indicator']),
      targetNo: (data['target_no'] ?? 0).toInt(),
      fundingSource: fs,
      objectOfExpenditure: ooe,
      q1Budget: parseDouble(data['q1_budget'] ?? (data['approved_budget'] ?? 0)),
      q2Budget: parseDouble(data['q2_budget']),
      q3Budget: parseDouble(data['q3_budget']),
      q4Budget: parseDouble(data['q4_budget']),
      actualExpenditure: parseDouble(data['actual_expenditure']),
      ppmpAmount: parseDouble(data['ppmp_amount']),
      prAmount: parseDouble(data['pr_amount'] ?? (data['approp_pr_amount'] ?? 0)),
      prBalance: parseDouble(data['pr_balance'] ?? (data['approp_pr_balance'] ?? 0)),
      responsiblePerson: safeString(data['responsible_person']),
      status: rawStatus,
      targetDate: safeString(data['target_date'], 'January'),
      targetParticipants: safeString(data['target_participants']),
      actualConduct: safeString(data['actual_conduct']),
      accommRemarks: safeString(data['accomm_remarks']),
      fundingInputtedBy: data['funding_inputted_by'] as String?,
      statusInputtedBy: data['status_inputted_by'] as String?,
      location: data['location'] as String?,
      otherMoeSuppliers: safeString(data['other_moe_suppliers']),
      unit: data['unit'] as String?,
      unitHead: data['unit_head'] as String?,
      remarks: safeString(data['remarks']),
      statusDate: data['status_date'] as String?,
      isDraft: isDraft,
      breakdown: breakdown,
      fundSources: fundSources,
      // Appropriations
      appropriation: parseDouble(data['approp_amount']),
      trainingSeminarAmount: parseDouble(data['approp_training_seminar']),
      meetingsAmount: parseDouble(data['approp_meetings']),
      df20Amount: parseDouble(data['approp_20df']),
      cpocAmount: parseDouble(data['approp_cpoc']),
      gadAmount: parseDouble(data['approp_gad']),
      ppmpBalance: parseDouble(data['approp_ppmp_balance'] ??
          data['ppmp_amount'] ??
          data['approved_budget'] ??
          0),
      prNumber: safeString(data['approp_pr_number']),
      supplierApprop: safeString(data['approp_supplier']),
      barcodeApprop: safeString(data['approp_barcode']),
      statusApprop: safeString(data['approp_status']),
      statusAppropDate: data['approp_status_date'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sector': sector,
      'sub_sector': subSector ?? '',
      'activity_name': activityName,
      'performance_indicator': performanceIndicator,
      'target_no': targetNo,
      'funding_source': fundingSource,
      'object_of_expenditure': objectOfExpenditure ?? '',
      'q1_budget': q1Budget,
      'q2_budget': q2Budget,
      'q3_budget': q3Budget,
      'q4_budget': q4Budget,
      'approved_budget': approvedBudget, // Storing for backward compatibility
      'actual_expenditure': actualExpenditure,
      'ppmp_amount': ppmpAmount,
      'pr_amount': prAmount,
      'pr_balance': prBalance,
      'responsible_person': responsiblePerson,
      'status': status,
      'target_date': targetDate,
      'target_participants': targetParticipants,
      'actual_conduct': actualConduct,
      'accomm_remarks': accommRemarks,
      'funding_inputted_by': fundingInputtedBy ?? '',
      'status_inputted_by': statusInputtedBy ?? '',
      'location': location ?? '',
      'other_moe_suppliers': otherMoeSuppliers,
      'unit': unit ?? '',
      'unit_head': unitHead ?? '',
      'remarks': remarks,
      if (statusDate != null && statusDate!.isNotEmpty)
        'status_date': statusDate,
      'is_draft': isDraft,
      'breakdown': breakdown.map((e) => e.toMap()).toList(),
      'fund_sources': fundSources.map((e) => e.toMap()).toList(),
      // Appropriations
      if (appropriation != 0) 'approp_amount': appropriation,
      if (trainingSeminarAmount != 0)
        'approp_training_seminar': trainingSeminarAmount,
      if (meetingsAmount != 0) 'approp_meetings': meetingsAmount,
      if (df20Amount != 0) 'approp_20df': df20Amount,
      if (cpocAmount != 0) 'approp_cpoc': cpocAmount,
      if (gadAmount != 0) 'approp_gad': gadAmount,
      if (ppmpBalance != 0) 'approp_ppmp_balance': ppmpBalance,
      if (prNumber.isNotEmpty) 'approp_pr_number': prNumber,
      if (supplierApprop.isNotEmpty) 'approp_supplier': supplierApprop,
      if (barcodeApprop.isNotEmpty) 'approp_barcode': barcodeApprop,
      if (statusApprop.isNotEmpty) 'approp_status': statusApprop,
      if (statusAppropDate != null && statusAppropDate!.isNotEmpty)
        'approp_status_date': statusAppropDate,
    };
  }

  Activity copyWith({
    String? id,
    String? sector,
    String? subSector,
    String? activityName,
    String? performanceIndicator,
    int? targetNo,
    String? fundingSource,
    String? objectOfExpenditure,
    double? q1Budget,
    double? q2Budget,
    double? q3Budget,
    double? q4Budget,
    double? actualExpenditure,
    double? ppmpAmount,
    double? prAmount,
    double? prBalance,
    String? responsiblePerson,
    String? status,
    String? targetDate,
    String? targetParticipants,
    String? actualConduct,
    String? accommRemarks,
    String? fundingInputtedBy,
    String? statusInputtedBy,
    String? location,
    String? otherMoeSuppliers,
    String? unit,
    String? unitHead,
    String? remarks,
    String? statusDate,
    bool? isDraft,
    List<BreakdownItem>? breakdown,
    List<FundSourceItem>? fundSources,
    double? appropriation,
    double? trainingSeminarAmount,
    double? meetingsAmount,
    double? df20Amount,
    double? cpocAmount,
    double? gadAmount,
    double? ppmpBalance,
    String? prNumber,
    String? supplierApprop,
    String? barcodeApprop,
    String? statusApprop,
    String? statusAppropDate,
  }) {
    return Activity(
      id: id ?? this.id,
      sector: sector ?? this.sector,
      subSector: subSector ?? this.subSector,
      activityName: activityName ?? this.activityName,
      performanceIndicator: performanceIndicator ?? this.performanceIndicator,
      targetNo: targetNo ?? this.targetNo,
      fundingSource: fundingSource ?? this.fundingSource,
      objectOfExpenditure: objectOfExpenditure ?? this.objectOfExpenditure,
      q1Budget: q1Budget ?? this.q1Budget,
      q2Budget: q2Budget ?? this.q2Budget,
      q3Budget: q3Budget ?? this.q3Budget,
      q4Budget: q4Budget ?? this.q4Budget,
      actualExpenditure: actualExpenditure ?? this.actualExpenditure,
      ppmpAmount: ppmpAmount ?? this.ppmpAmount,
      prAmount: prAmount ?? this.prAmount,
      prBalance: prBalance ?? this.prBalance,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      status: status ?? this.status,
      targetDate: targetDate ?? this.targetDate,
      targetParticipants: targetParticipants ?? this.targetParticipants,
      actualConduct: actualConduct ?? this.actualConduct,
      accommRemarks: accommRemarks ?? this.accommRemarks,
      fundingInputtedBy: fundingInputtedBy ?? this.fundingInputtedBy,
      statusInputtedBy: statusInputtedBy ?? this.statusInputtedBy,
      location: location ?? this.location,
      otherMoeSuppliers: otherMoeSuppliers ?? this.otherMoeSuppliers,
      unit: unit ?? this.unit,
      unitHead: unitHead ?? this.unitHead,
      remarks: remarks ?? this.remarks,
      statusDate: statusDate ?? this.statusDate,
      isDraft: isDraft ?? this.isDraft,
      breakdown: breakdown ?? this.breakdown,
      fundSources: fundSources ?? this.fundSources,
      appropriation: appropriation ?? this.appropriation,
      trainingSeminarAmount:
          trainingSeminarAmount ?? this.trainingSeminarAmount,
      meetingsAmount: meetingsAmount ?? this.meetingsAmount,
      df20Amount: df20Amount ?? this.df20Amount,
      cpocAmount: cpocAmount ?? this.cpocAmount,
      gadAmount: gadAmount ?? this.gadAmount,
      ppmpBalance: ppmpBalance ?? this.ppmpBalance,
      prNumber: prNumber ?? this.prNumber,
      supplierApprop: supplierApprop ?? this.supplierApprop,
      barcodeApprop: barcodeApprop ?? this.barcodeApprop,
      statusApprop: statusApprop ?? this.statusApprop,
      statusAppropDate: statusAppropDate ?? this.statusAppropDate,
    );
  }

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    bool contains(String? source) {
      if (source == null) return false;
      final normalized =
          source.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      if (normalized.contains(q)) return true;

      // Also check abbreviation
      final abbr = AppConstants.abbreviate(source).toLowerCase();
      if (abbr.contains(q)) return true;

      return false;
    }

    return contains(activityName) ||
        contains(responsiblePerson) ||
        contains(location) ||
        contains(subSector) ||
        contains(sector) ||
        contains(performanceIndicator) ||
        contains(targetParticipants) ||
        contains(actualConduct) ||
        contains(accommRemarks) ||
        contains(remarks) ||
        contains(prNumber) ||
        contains(supplierApprop) ||
        contains(barcodeApprop) ||
        contains(unit) ||
        contains(unitHead) ||
        contains(fundingSource) ||
        contains(objectOfExpenditure) ||
        contains(status) ||
        contains(statusApprop) ||
        contains(otherMoeSuppliers) ||
        contains(targetDate) ||
        contains(statusDate) ||
        contains(statusAppropDate) ||
        fundSources.any(
          (fs) =>
              contains(fs.fundingSource) || contains(fs.objectOfExpenditure),
        ) ||
        breakdown.any(
          (item) =>
              contains(item.name) ||
              contains(item.supplier) ||
              contains(item.fundingSource) ||
              contains(item.objectOfExpenditure) ||
              contains(item.status),
        );
  }
}
