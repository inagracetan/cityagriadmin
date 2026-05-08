import 'package:cloud_firestore/cloud_firestore.dart';

class Procurement {
  final String id;
  final String programId;
  final String? activityId;
  final String prNumber;
  final double prAmount;
  final double prBalance;
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
  final String? remarks;

  Procurement({
    required this.id,
    required this.programId,
    this.activityId,
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
    this.remarks,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'program_id': programId,
      'activity_id': activityId,
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
      'remarks': remarks,
    };
  }

  factory Procurement.fromFirestore(Map<String, dynamic> data, String id) {
    return Procurement(
      id: id,
      programId: data['program_id'] ?? '',
      activityId: data['activity_id'],
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
      remarks: data['remarks'],
    );
  }

  Procurement copyWith({
    String? id,
    String? programId,
    String? activityId,
    String? prNumber,
    double? prAmount,
    double? prBalance,
    String? poNumber,
    double? poAmount,
    String? poDate,
    String? supplier,
    String? status,
    String? statusDate,
    double? ppmpAmount,
    String? objectOfExpenditure,
    String? fundSource,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? remarks,
  }) {
    return Procurement(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      activityId: activityId ?? this.activityId,
      prNumber: prNumber ?? this.prNumber,
      prAmount: prAmount ?? this.prAmount,
      prBalance: prBalance ?? this.prBalance,
      poNumber: poNumber ?? this.poNumber,
      poAmount: poAmount ?? this.poAmount,
      poDate: poDate ?? this.poDate,
      supplier: supplier ?? this.supplier,
      status: status ?? this.status,
      statusDate: statusDate ?? this.statusDate,
      ppmpAmount: ppmpAmount ?? this.ppmpAmount,
      objectOfExpenditure: objectOfExpenditure ?? this.objectOfExpenditure,
      fundSource: fundSource ?? this.fundSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      remarks: remarks ?? this.remarks,
    );
  }
}
