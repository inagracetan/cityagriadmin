
class BudgetLine {
  final String id;
  final String accountCode; // Primary financial key
  final String fundSource;
  final String objectOfExpenditure;
  final double proposedBudget;
  final double proposedExpenditure;
  final double approvedAmount;
  final double currentBalance;
  final double appropriation;
  final double ppmpAmount;
  final double prAmount;
  final double poAmount;
  final double budgetLimit; // System's hard ceiling
  final double q1Ppmp;
  final double q2Ppmp;
  final double q3Ppmp;
  final double q4Ppmp;
  final bool isCMO; // Whether this is the CMO Budget
  final bool isAgriMooe; // Whether this is under Agri MOOE
  final String sector; // Sector classification
  final String subCategory; // Sub-classification for hierarchical tracking

  double get totalActualPRs => prAmount; // Convenience getter for UI labels

  // ── Core Formulas (Hierarchical Calculation) ──────────────────────
  /// PPMP Balance: Budget not yet assigned to any PPMP entry.
  /// Appropriation (Level A) - Total PPMP (Level B)
  double get ppmpBalance => appropriation - ppmpAmount;

  /// PR Balance: Obligation capacity remaining for this line.
  /// Total PPMP - Total PRs
  double get prBalance => ppmpAmount - prAmount;

  /// Savings/Variance: Realized savings at PO stage.
  /// Total PR Amount - Total PO Amount
  double get savings => prAmount - poAmount;

  /// Utilization Rate: (Total Obligated / Total Appropriation) * 100
  double get utilizationRate => appropriation > 0 ? (prAmount / appropriation) * 100 : 0.0;

  BudgetLine({
    required this.id,
    required this.accountCode,
    required this.fundSource,
    required this.objectOfExpenditure,
    this.subCategory = '',
    this.proposedBudget = 0.0,
    this.proposedExpenditure = 0.0,
    this.approvedAmount = 0.0,
    this.currentBalance = 0.0,
    this.appropriation = 0.0,
    this.ppmpAmount = 0.0,
    this.prAmount = 0.0,
    this.poAmount = 0.0,
    this.budgetLimit = 0.0,
    this.q1Ppmp = 0.0,
    this.q2Ppmp = 0.0,
    this.q3Ppmp = 0.0,
    this.q4Ppmp = 0.0,
    this.isCMO = false,
    this.isAgriMooe = false,
    this.sector = '',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'account_code': accountCode,
      'fund_source': fundSource,
      'object_of_expenditure': objectOfExpenditure,
      'proposed_budget': proposedBudget,
      'proposed_expenditure': proposedExpenditure,
      'approved_amount': approvedAmount,
      'current_balance': currentBalance,
      'appropriation': appropriation,
      'ppmp_amount': ppmpAmount,
      'pr_amount': prAmount,
      'po_amount': poAmount,
      'budget_limit': budgetLimit,
      'q1_ppmp': q1Ppmp,
      'q2_ppmp': q2Ppmp,
      'q3_ppmp': q3Ppmp,
      'q4_ppmp': q4Ppmp,
      'is_cmo': isCMO,
      'is_agri_mooe': isAgriMooe,
      'sector': sector,
      'sub_category': subCategory,
    };
  }

  factory BudgetLine.fromFirestore(Map<String, dynamic> data, String id) {
    String safeString(dynamic value, [String fallback = '']) {
      if (value == null || value.toString().toLowerCase() == 'null') return fallback;
      return value.toString();
    }

    return BudgetLine(
      id: id,
      accountCode: safeString(data['account_code']),
      fundSource: safeString(data['fund_source']),
      objectOfExpenditure: safeString(data['object_of_expenditure']),
      proposedBudget: (data['proposed_budget'] ?? data['proposed_amount'] ?? 0).toDouble(),
      proposedExpenditure: (data['proposed_expenditure'] ?? 0).toDouble(),
      approvedAmount: (data['approved_amount'] ?? 0).toDouble(),
      currentBalance: (data['current_balance'] ?? 0).toDouble(),
      appropriation: (data['appropriation'] ?? 0).toDouble(),
      ppmpAmount: (data['ppmp_amount'] ?? 0).toDouble(),
      prAmount: (data['pr_amount'] ?? 0).toDouble(),
      poAmount: (data['po_amount'] ?? 0).toDouble(),
      budgetLimit: (data['budget_limit'] ?? 0).toDouble(),
      q1Ppmp: (data['q1_ppmp'] ?? 0).toDouble(),
      q2Ppmp: (data['q2_ppmp'] ?? 0).toDouble(),
      q3Ppmp: (data['q3_ppmp'] ?? 0).toDouble(),
      q4Ppmp: (data['q4_ppmp'] ?? 0).toDouble(),
      isCMO: data['is_cmo'] ?? false,
      isAgriMooe: data['is_agri_mooe'] ?? false,
      sector: safeString(data['sector']),
      subCategory: safeString(data['sub_category']),
    );
  }

  BudgetLine copyWith({
    String? id,
    String? accountCode,
    String? fundSource,
    String? objectOfExpenditure,
    double? proposedBudget,
    double? proposedExpenditure,
    double? approvedAmount,
    double? currentBalance,
    double? appropriation,
    double? ppmpAmount,
    double? prAmount,
    double? poAmount,
    double? budgetLimit,
    double? q1Ppmp,
    double? q2Ppmp,
    double? q3Ppmp,
    double? q4Ppmp,
    bool? isCMO,
    bool? isAgriMooe,
    String? sector,
    String? subCategory,
  }) {
    return BudgetLine(
      id: id ?? this.id,
      accountCode: accountCode ?? this.accountCode,
      fundSource: fundSource ?? this.fundSource,
      objectOfExpenditure: objectOfExpenditure ?? this.objectOfExpenditure,
      proposedBudget: proposedBudget ?? this.proposedBudget,
      proposedExpenditure: proposedExpenditure ?? this.proposedExpenditure,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      appropriation: appropriation ?? this.appropriation,
      ppmpAmount: ppmpAmount ?? this.ppmpAmount,
      prAmount: prAmount ?? this.prAmount,
      poAmount: poAmount ?? this.poAmount,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      q1Ppmp: q1Ppmp ?? this.q1Ppmp,
      q2Ppmp: q2Ppmp ?? this.q2Ppmp,
      q3Ppmp: q3Ppmp ?? this.q3Ppmp,
      q4Ppmp: q4Ppmp ?? this.q4Ppmp,
      isCMO: isCMO ?? this.isCMO,
      isAgriMooe: isAgriMooe ?? this.isAgriMooe,
      sector: sector ?? this.sector,
      subCategory: subCategory ?? this.subCategory,
    );
  }
}



