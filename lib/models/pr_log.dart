import 'package:cloud_firestore/cloud_firestore.dart';

class PRLog {
  final String id;
  final String activityId;
  final String status;
  final String prNumber;
  final double amount;
  final String remarks;
  final DateTime timestamp;
  final String? updatedBy;

  PRLog({
    required this.id,
    required this.activityId,
    required this.status,
    required this.prNumber,
    required this.amount,
    required this.remarks,
    required this.timestamp,
    this.updatedBy,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'activity_id': activityId,
      'status': status,
      'pr_number': prNumber,
      'amount': amount,
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
      amount: (data['amount'] ?? 0).toDouble(),
      remarks: data['remarks'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      updatedBy: data['updated_by'],
    );
  }
}
