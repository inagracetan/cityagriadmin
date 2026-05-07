import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import '../models/budget_line.dart';
import 'firebase_service.dart';
import '../core/constants.dart';

class ImportService {
  static Future<void> importActivitiesFromExcel(
    FirebaseService fbService,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      List<int>? bytes;
      if (result.files.single.bytes != null) {
        bytes = result.files.single.bytes;
      } else if (result.files.single.path != null) {
        File file = File(result.files.single.path!);
        bytes = file.readAsBytesSync();
      }

      if (bytes == null) return;
      Excel excel;
      try {
        excel = Excel.decodeBytes(bytes);
      } catch (e) {
        debugPrint('Excel decoding failed: $e');
        if (e.toString().contains('numFmtId')) {
          throw Exception(
            'The Excel file has incompatible formatting. Please try to "Save As" the file in Excel to clean up custom styles, or use a simpler XLSX file.',
          );
        }
        rethrow;
      }

      List<Activity> activitiesToImport = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null) continue;

        int headerRowIndex = -1;
        for (int i = 0; i < (sheet.maxRows > 10 ? 10 : sheet.maxRows); i++) {
          final row = sheet.rows[i];
          final rowValues = row
              .map((c) => c?.value?.toString().toLowerCase().trim() ?? '')
              .toList();
          if (rowValues.contains('ppa / activity') ||
              rowValues.contains('activity') ||
              rowValues.contains('sector')) {
            headerRowIndex = i;
            break;
          }
        }

        if (headerRowIndex == -1) headerRowIndex = 0;

        final headerRow = sheet.rows[headerRowIndex]
            .map((c) => c?.value?.toString().toLowerCase().trim() ?? '')
            .toList();

        int idxSector = headerRow.indexWhere((h) => h.contains('sector'));
        int idxActivity = headerRow.indexWhere(
          (h) => h.contains('activity') || h.contains('ppa'),
        );
        int idxLocation = headerRow.indexWhere((h) => h.contains('location'));
        int idxIndicator = headerRow.indexWhere((h) => h.contains('indicator'));
        int idxTarget = headerRow.indexWhere(
          (h) => h == 'target' || h.contains('target no'),
        );
        int idxTargetDate = headerRow.indexWhere(
          (h) => h.contains('target date'),
        );
        int idxTargetParticipants = headerRow.indexWhere(
          (h) => h.contains('target participants'),
        );
        int idxFundingSource = headerRow.indexWhere(
          (h) => h.contains('funding source'),
        );
        int idxObjFund = headerRow.indexWhere(
          (h) => h.contains('object') || h == 'fund' || h.contains('fund'),
        );
        int idxBudget = headerRow.indexWhere((h) => h.contains('budget'));
        int idxActualExp = headerRow.indexWhere(
          (h) => h.contains('actual exp') || h.contains('spent'),
        );
        int idxStatus = headerRow.indexWhere((h) => h.contains('status'));
        int idxResponsible = headerRow.indexWhere(
          (h) => h.contains('responsible'),
        );
        int idxUnitHead = headerRow.indexWhere(
          (h) => h.contains('unit head') || h.contains('head'),
        );
        int idxAccom = headerRow.indexWhere((h) => h.contains('accom'));
        int idxActualCond = headerRow.indexWhere(
          (h) => h.contains('actual conduct'),
        );
        int idxBreakdown = headerRow.indexWhere((h) => h.contains('breakdown'));

        for (int i = headerRowIndex + 1; i < sheet.maxRows; i++) {
          var row = sheet.rows[i];
          if (row.isEmpty) continue;

          String getVal(int idx, String fallback) {
            if (idx == -1 || idx >= row.length) return fallback;
            return valToString(row[idx]?.value) ?? fallback;
          }

          int getIntVal(int idx, int fallback) {
            if (idx == -1 || idx >= row.length) return fallback;
            return valToInt(row[idx]?.value) ?? fallback;
          }

          double getDoubleVal(int idx, double fallback) {
            if (idx == -1 || idx >= row.length) return fallback;
            return valToDouble(row[idx]?.value) ?? fallback;
          }

          String activityName = getVal(idxActivity, '');
          String sector = getVal(
            idxSector,
            'Administrative Support Services Unit',
          );

          if (activityName.isEmpty &&
              sector == 'Administrative Support Services Unit') {
            continue;
          }

          String location = getVal(idxLocation, '');
          String performanceIndicator = getVal(idxIndicator, '');
          int targetNo = getIntVal(idxTarget, 0);
          String targetDate = getVal(idxTargetDate, 'Unspecified');
          String targetParticipants = getVal(idxTargetParticipants, '');
          String fundingSource = getVal(idxFundingSource, 'Agri MOOE');
          String objOrFund = getVal(idxObjFund, '');
          double approvedBudget = getDoubleVal(idxBudget, 0.0);
          double actualExpenditure = getDoubleVal(idxActualExp, 0.0);
          String status = getVal(idxStatus, 'Planned');
          String responsiblePerson = getVal(idxResponsible, '');
          String unitHead = getVal(idxUnitHead, '');
          String accommRemarks = getVal(idxAccom, '');
          String actualConduct = getVal(idxActualCond, '');
          String breakdown = getVal(idxBreakdown, '');

          // Normalize status
          if (status.isEmpty) status = 'Planned';
          if (fundingSource.isEmpty) fundingSource = 'Agri MOOE';

          String? obj = fundingSource == 'Agri MOOE'
              ? parseObjectOfExpenditure(objOrFund)
              : null;

          if (fundingSource == 'Special Funds' ||
              (fundingSource != 'Agri MOOE' && objOrFund.isNotEmpty)) {
            final parsedFund = parseSpecialFundSource(objOrFund);
            if (parsedFund != null) {
              fundingSource = parsedFund;
            }
          }

          double q1 = 0;
          double q2 = 0;
          double q3 = 0;
          double q4 = 0;

          String dateLower = targetDate.toLowerCase();
          if (dateLower.contains('january') ||
              dateLower.contains('february') ||
              dateLower.contains('march')) {
            q1 = approvedBudget;
          } else if (dateLower.contains('april') ||
              dateLower.contains('may') ||
              dateLower.contains('june')) {
            q2 = approvedBudget;
          } else if (dateLower.contains('july') ||
              dateLower.contains('august') ||
              dateLower.contains('september')) {
            q3 = approvedBudget;
          } else if (dateLower.contains('october') ||
              dateLower.contains('november') ||
              dateLower.contains('december')) {
            q4 = approvedBudget;
          } else {
            // Fallback to Q1 if month not found
            q1 = approvedBudget;
          }

          activitiesToImport.add(
            Activity(
              id: '',
              sector: sector,
              activityName: activityName,
              performanceIndicator: performanceIndicator,
              targetNo: targetNo,
              fundingSource: fundingSource,
              objectOfExpenditure: obj,
              q1Budget: q1,
              q2Budget: q2,
              q3Budget: q3,
              q4Budget: q4,
              actualExpenditure: actualExpenditure,
              responsiblePerson: responsiblePerson,
              status: status,
              targetDate: targetDate,
              targetParticipants: targetParticipants,
              actualConduct: actualConduct,
              accommRemarks: accommRemarks,
              location: location,
              unitHead: unitHead,
              breakdown: breakdown.isNotEmpty
                  ? [BreakdownItem(name: breakdown, amount: 0.0)]
                  : [],
            ),
          );
        }
      }

      if (activitiesToImport.isNotEmpty) {
        await fbService.batchAddActivities(activitiesToImport);
      }
    }
  }

  static Future<Map<String, dynamic>> importAgriPPMPFromExcel(
    FirebaseService fbService,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) return {'status': 'cancelled'};

    List<int>? bytes;
    if (result.files.single.bytes != null) {
      bytes = result.files.single.bytes;
    } else if (result.files.single.path != null) {
      File file = File(result.files.single.path!);
      bytes = file.readAsBytesSync();
    }

    if (bytes == null) return {'status': 'error', 'message': 'Could not read file'};
    var excel = Excel.decodeBytes(bytes);

    // Load budget lines for validation
    final budgetLinesSnapshot = await fbService.db.collection('budget_lines').get();
    final budgetLines = budgetLinesSnapshot.docs
        .map((doc) => BudgetLine.fromFirestore(doc.data(), doc.id))
        .toList();

    List<Activity> activitiesToImport = [];
    List<String> errorLogs = [];
    int successCount = 0;

    var sheet = excel.tables[SystemConfig.nextFiscalYearStr];
    sheet ??= excel.tables[excel.tables.keys.first];

    if (sheet == null) return {'status': 'error', 'message': 'Sheet not found'};

    int headerRowIndex = -1;
    for (int i = 0; i < (sheet.maxRows > 15 ? 15 : sheet.maxRows); i++) {
      final row = sheet.rows[i];
      final rowValues = row.map((c) => c?.value?.toString().toLowerCase().trim() ?? '').toList();
      if (rowValues.contains('item & specifications') || rowValues.contains('ppa')) {
        headerRowIndex = i;
        break;
      }
    }

    if (headerRowIndex == -1) headerRowIndex = 0;

    final headerRow = sheet.rows[headerRowIndex]
        .map((c) => c?.value?.toString().toLowerCase().trim() ?? '')
        .toList();

    int idxActivity = headerRow.indexWhere((h) => h.contains('item & specifications') || h.contains('activity'));
    int idxJan = headerRow.indexWhere((h) => h == 'jan');
    int idxFeb = headerRow.indexWhere((h) => h == 'feb');
    int idxMar = headerRow.indexWhere((h) => h == 'mar');
    int idxApr = headerRow.indexWhere((h) => h == 'apr');
    int idxMay = headerRow.indexWhere((h) => h == 'may');
    int idxJun = headerRow.indexWhere((h) => h == 'jun');
    int idxJul = headerRow.indexWhere((h) => h == 'jul');
    int idxAug = headerRow.indexWhere((h) => h == 'aug');
    int idxSep = headerRow.indexWhere((h) => h == 'sep');
    int idxOct = headerRow.indexWhere((h) => h == 'oct');
    int idxNov = headerRow.indexWhere((h) => h == 'nov');
    int idxDec = headerRow.indexWhere((h) => h == 'dec');
    int idxTotalQnty = headerRow.indexWhere((h) => h.contains('total qnty') || h.contains('quantity'));
    int idxTotalAmount = headerRow.indexWhere((h) => h.contains('total amount') || h == 'total');

    bool inTrainingsSection = false;

    for (int i = headerRowIndex + 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty) continue;

      String firstCell = valToString(row[0]?.value) ?? '';
      if (firstCell.toUpperCase().contains('TRAININGS & SEMINARS')) {
        inTrainingsSection = true;
        continue;
      } else if (firstCell.isNotEmpty && firstCell.length < 50 && firstCell == firstCell.toUpperCase()) {
        // Possible new section header
        inTrainingsSection = false;
      }

      String activityName = valToString(idxActivity != -1 && idxActivity < row.length ? row[idxActivity]?.value : null) ?? '';
      if (activityName.isEmpty) continue;

      double totalAmount = valToDouble(idxTotalAmount != -1 && idxTotalAmount < row.length ? row[idxTotalAmount]?.value : null) ?? 0.0;
      int targetNo = valToInt(idxTotalQnty != -1 && idxTotalQnty < row.length ? row[idxTotalQnty]?.value : null) ?? 0;

      // Monthly distribution
      List<double> monthly = List.filled(12, 0.0);
      final monthIndices = [idxJan, idxFeb, idxMar, idxApr, idxMay, idxJun, idxJul, idxAug, idxSep, idxOct, idxNov, idxDec];
      for (int m = 0; m < 12; m++) {
        if (monthIndices[m] != -1 && monthIndices[m] < row.length) {
          monthly[m] = valToDouble(row[monthIndices[m]]?.value) ?? 0.0;
        }
      }

      // Validation Rule: Compare with Approved Budget
      // Assuming we can find a budget line that matches either by account code or by description
      // In this specific import, we'll try to find a matching budget line.
      String accountCode = inTrainingsSection ? '5-02-02-010' : '';
      
      BudgetLine? matchingBudget;
      if (accountCode.isNotEmpty) {
        matchingBudget = budgetLines.firstWhere((bl) => bl.accountCode == accountCode, orElse: () => budgetLines.first); // fallback just for logic
      }

      if (matchingBudget != null && totalAmount > matchingBudget.approvedAmount) {
        errorLogs.add('Rejected "$activityName": Total Amount ($totalAmount) exceeds Approved Budget (${matchingBudget.approvedAmount}) for ${matchingBudget.accountCode}');
        continue;
      }

      activitiesToImport.add(
        Activity(
          id: '',
          sector: 'Administrative Support Services Unit', // Default or parsed
          activityName: activityName,
          performanceIndicator: 'As specified',
          targetNo: targetNo,
          fundingSource: 'Agri MOOE',
          q1Budget: monthly[0] + monthly[1] + monthly[2],
          q2Budget: monthly[3] + monthly[4] + monthly[5],
          q3Budget: monthly[6] + monthly[7] + monthly[8],
          q4Budget: monthly[9] + monthly[10] + monthly[11],
          ppmpAmount: totalAmount,
          responsiblePerson: 'Unassigned',
          status: 'Planned',
          targetDate: SystemConfig.nextFiscalYearStr,
          monthlyDistribution: monthly,
          accountCode: accountCode,
        ),
      );
      successCount++;
    }

    if (activitiesToImport.isNotEmpty) {
      await fbService.batchAddActivities(activitiesToImport);
    }

    return {
      'status': 'success',
      'imported': successCount,
      'errors': errorLogs,
    };
  }

  static String? valToString(CellValue? cell) {
    if (cell == null) return null;
    final s = cell.toString();
    return s.toLowerCase() == 'null' ? '' : s.replaceAll('_', ' ');
  }

  static int? valToInt(CellValue? cell) {
    if (cell == null) return null;
    if (cell is IntCellValue) return cell.value;
    return int.tryParse(cell.toString());
  }

  static double? valToDouble(CellValue? cell) {
    if (cell == null) return null;
    if (cell is DoubleCellValue) return cell.value;
    if (cell is IntCellValue) return cell.value.toDouble();
    return double.tryParse(cell.toString().replaceAll(',', ''));
  }

  static String? parseObjectOfExpenditure(String value) {
    final v = value.trim().toLowerCase();
    if (v.contains('administrative support')) {
      return 'Administrative Support Services Unit Appropriation';
    }
    if (v.contains('crop section')) return 'Crop Section Appropriation';
    if (v.contains('inland fisheries')) {
      return 'Inland Fisheries Section Appropriation';
    }
    if (v.contains('institutional development')) {
      return 'Institutional Development Section Appropriation';
    }
    if (v.contains('agriculture logistics')) {
      return 'Agriculture Logistics Section Appropriation';
    }
    if (v.contains('project development')) {
      return 'Project Development Section Appropriation';
    }
    if (v.contains('monitoring and evaluation')) {
      return 'Monitoring and Evaluation Section Appropriation';
    }
    if (v.contains('integrated agricultural')) {
      return 'Integrated Agricultural Laboratory Appropriation';
    }
    if (v.contains('travelling')) return 'Travelling Expenses';
    if (v.contains('training')) return 'Trainings and Seminar Expenses';
    if (v.contains('meetings')) return 'Meetings Expenses';
    if (v.contains('office supplies')) return 'Office Supplies Expenses';
    if (v.contains('fuel') || v.contains('oil')) return 'Fuel/Oil Expenses';
    if (v.contains('communication')) return 'Communication Expenses';
    if (v.contains('repair') || v.contains('maintenance')) {
      return 'Repair/Maintenance Expenses';
    }
    if (v.contains('personnel development')) {
      return 'Personnel Development Expenses';
    }
    if (v.contains('other')) return 'Other-MOE Expenses';
    return 'Other-MOE Expenses'; // fallback
  }

  static String? parseSpecialFundSource(String value) {
    final v = value.trim().toLowerCase();
    if (v.contains('20%')) return '20% DF';
    if (v.contains('gad')) return 'GAD';
    if (v.contains('cpoc')) return 'CPOC';
    if (v.contains('cdrrmo')) return 'CDRRMO';
    if (v.contains('capital')) return 'Capital Outlay';
    if (v.contains('mayor')) return 'Mayors Fund';
    if (v.contains('agri') || v.contains('mooe')) return 'Agri MOOE';
    return '20% DF'; // fallback
  }
}

