class Expenditure {
  final String id;
  final String activityId;
  final String activityName; // Denormalized for easier display
  final String sector; // Denormalized for easier filtering
  final String prNumber;
  final String? poNumber;
  final String? poDate;
  final String? poStatus; // Pending, Delivered, Paid
  final double amount;
  final String? fundSource;
  final String? objectOfExpenditure;

  Expenditure({
    required this.id,
    required this.activityId,
    required this.activityName,
    required this.sector,
    required this.prNumber,
    this.poNumber,
    this.poDate,
    this.poStatus,
    required this.amount,
    this.fundSource,
    this.objectOfExpenditure,
    required DateTime timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'activity_id': activityId,
      'activity_name': activityName,
      'sector': sector,
      'pr_number': prNumber,
      'po_number': poNumber ?? '',
      'po_date': poDate ?? '',
      'po_status': poStatus ?? 'Pending',
      'amount': amount,
      'fund_source': fundSource ?? '',
      'object_of_expenditure': objectOfExpenditure ?? '',
    };
  }

  factory Expenditure.fromFirestore(Map<String, dynamic> data, String id) {
    return Expenditure(
      id: id,
      activityId: data['activity_id'] ?? '',
      activityName: data['activity_name'] ?? '',
      sector: data['sector'] ?? '',
      prNumber: data['pr_number'] ?? '',
      poNumber: data['po_number'],
      poDate: data['po_date'],
      poStatus: data['po_status'],
      amount: (data['amount'] ?? 0).toDouble(),
      fundSource: data['fund_source'],
      objectOfExpenditure: data['object_of_expenditure'],
      timestamp: DateTime.now(),
    );
  }

  Expenditure copyWith({
    String? id,
    String? activityId,
    String? activityName,
    String? sector,
    String? prNumber,
    String? poNumber,
    String? poDate,
    String? poStatus,
    double? amount,
    String? fundSource,
    String? objectOfExpenditure,
  }) {
    return Expenditure(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      activityName: activityName ?? this.activityName,
      sector: sector ?? this.sector,
      prNumber: prNumber ?? this.prNumber,
      poNumber: poNumber ?? this.poNumber,
      poDate: poDate ?? this.poDate,
      poStatus: poStatus ?? this.poStatus,
      amount: amount ?? this.amount,
      fundSource: fundSource ?? this.fundSource,
      objectOfExpenditure: objectOfExpenditure ?? this.objectOfExpenditure,
      timestamp: DateTime.now(),
    );
  }
}
