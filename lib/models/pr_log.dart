import 'package:cloud_firestore/cloud_firestore.dart';

class PRLog {
  String id;
  String activityId;
  String status;
  String prNumber;
  double prAmount;
  String poNumber;
  double poAmount;
  String? statusDate;
  String supplier;
  String remarks;
  DateTime timestamp;
  String? updatedBy;

  PRLog({
    required this.id,
    required this.activityId,
    required this.status,
    required this.prNumber,
    required this.prAmount,
    this.poNumber = '',
    this.poAmount = 0.0,
    this.statusDate,
    this.supplier = '',
    this.remarks = '',
    required this.timestamp,
    this.updatedBy,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'activity_id': activityId,
      'status': status,
      'pr_number': prNumber,
      'pr_amount': prAmount,
      'po_number': poNumber,
      'po_amount': poAmount,
      'status_date': statusDate,
      'supplier': supplier,
      'remarks': remarks,
      'timestamp': Timestamp.fromDate(timestamp),
      'updated_by': updatedBy,
    };
  }

  factory PRLog.fromFirestore(Map<String, dynamic> data, String id) {
    return PRLog(
      id: id,
      activityId: data['activity_id'] ?? '',
      status: data['status'] ?? '',
      prNumber: data['pr_number'] ?? '',
      prAmount: (data['pr_amount'] ?? data['amount'] ?? 0).toDouble(),
      poNumber: data['po_number'] ?? '',
      poAmount: (data['po_amount'] ?? 0).toDouble(),
      statusDate: data['status_date'],
      supplier: data['supplier'] ?? '',
      remarks: data['remarks'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedBy: data['updated_by'],
    );
  }
}


