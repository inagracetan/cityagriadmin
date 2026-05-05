import 'package:cloud_firestore/cloud_firestore.dart';

class Procurement {
  final String id;
  final String programId;
  final String prNumber;
  final double prAmount;
  final double prBalance; // Calculated: PPMP Amount - PR Amount
  final String poNumber;
  final double poAmount;
  final String? poDate;
  final String supplier;
  final String status;
  final String statusDate;
  final double ppmpAmount;
  final String objectOfExpenditure;
  final String fundSource;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Procurement({
    required this.id,
    required this.programId,
    required this.prNumber,
    required this.prAmount,
    required this.prBalance,
    required this.poNumber,
    required this.poAmount,
    this.poDate,
    required this.supplier,
    required this.status,
    required this.statusDate,
    required this.ppmpAmount,
    required this.objectOfExpenditure,
    required this.fundSource,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'program_id': programId,
      'pr_number': prNumber,
      'pr_amount': prAmount,
      'pr_balance': prBalance,
      'po_number': poNumber,
      'po_amount': poAmount,
      'po_date': poDate,
      'supplier': supplier,
      'status': status,
      'status_date': statusDate,
      'ppmp_amount': ppmpAmount,
      'object_of_expenditure': objectOfExpenditure,
      'fund_source': fundSource,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'created_by': createdBy,
    };
  }

  factory Procurement.fromFirestore(Map<String, dynamic> data, String id) {
    return Procurement(
      id: id,
      programId: data['program_id'] ?? '',
      prNumber: data['pr_number'] ?? '',
      prAmount: (data['pr_amount'] ?? 0).toDouble(),
      prBalance: (data['pr_balance'] ?? 0).toDouble(),
      poNumber: data['po_number'] ?? '',
      poAmount: (data['po_amount'] ?? 0).toDouble(),
      poDate: data['po_date'],
      supplier: data['supplier'] ?? '',
      status: data['status'] ?? '',
      statusDate: data['status_date'] ?? '',
      ppmpAmount: (data['ppmp_amount'] ?? 0).toDouble(),
      objectOfExpenditure: data['object_of_expenditure'] ?? '',
      fundSource: data['fund_source'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['created_by'] ?? '',
    );
  }

  // Validation helper
  static String? validatePO(double amount, String? number, String? date, String? status) {
    if (amount > 0) {
      if (number == null || number.isEmpty) return 'PO Number is required for amount > 0';
      if (date == null || date.isEmpty) return 'PO Date is required for amount > 0';
      if (status == null || status.isEmpty) return 'Status is required for amount > 0';
    }
    return null;
  }
}
