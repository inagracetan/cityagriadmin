
import '../core/constants.dart';

class Program {
  final String id;
  final String name;
  final double totalAllocation;
  final double currentPpmpBalance;
  final String fiscalYear;

  Program({
    required this.id,
    required this.name,
    required this.totalAllocation,
    required this.currentPpmpBalance,
    required this.fiscalYear,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'program_name': name,
      'total_allocation': totalAllocation,
      'current_ppmp_balance': currentPpmpBalance,
      'fiscal_year': fiscalYear,
    };
  }

  factory Program.fromFirestore(Map<String, dynamic> data, String id) {
    return Program(
      id: id,
      name: data['program_name'] ?? '',
      totalAllocation: (data['total_allocation'] ?? 0).toDouble(),
      currentPpmpBalance: (data['current_ppmp_balance'] ?? 0).toDouble(),
      fiscalYear: data['fiscal_year'] ?? SystemConfig.nextFiscalYearStr,
    );
  }

  Program copyWith({
    String? id,
    String? name,
    double? totalAllocation,
    double? currentPpmpBalance,
    String? fiscalYear,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAllocation: totalAllocation ?? this.totalAllocation,
      currentPpmpBalance: currentPpmpBalance ?? this.currentPpmpBalance,
      fiscalYear: fiscalYear ?? this.fiscalYear,
    );
  }
}

