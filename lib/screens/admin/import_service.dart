import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import '../../models/activity.dart';
import '../../services/firebase_service.dart';

class ImportService {
  static Future<void> importActivitiesFromExcel(
    FirebaseService fbService,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      List<Activity> activitiesToImport = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null) continue;

        int headerRowIndex = -1;
        // Search first 10 rows for header
        for (int i = 0; i < (sheet.maxRows > 10 ? 10 : sheet.maxRows); i++) {
          final row = sheet.rows[i];
          final rowValues = row
              .map((c) => c?.value?.toString().toLowerCase() ?? '')
              .toList();
          if (rowValues.contains('ppa / activity') ||
              rowValues.contains('sector')) {
            headerRowIndex = i;
            break;
          }
        }

        if (headerRowIndex == -1) headerRowIndex = 0; // Fallback to first row

        for (int i = headerRowIndex + 1; i < sheet.maxRows; i++) {
          var row = sheet.rows[i];
          if (row.isEmpty || row.length < 2) continue;

          // Basic validation: must have at least an activity name or sector
          if (row[0]?.value == null && row[1]?.value == null) continue;

          String sector =
              _valToString(row[0]?.value) ??
              'Administrative Support Services Unit';
          String activityName = _valToString(row[1]?.value) ?? '';
          String location = _valToString(row[2]?.value) ?? '';
          String performanceIndicator = _valToString(row[3]?.value) ?? '';
          int targetNo = _valToInt(row[4]?.value) ?? 0;
          String fundingSource = _valToString(row[5]?.value) ?? 'Agri MOOE';
          String objOrFund = _valToString(row[6]?.value) ?? '';
          double approvedBudget = _valToDouble(row[7]?.value) ?? 0.0;
          double actualExpenditure = _valToDouble(row[8]?.value) ?? 0.0;
          // Index 9 is Balance (calculated field in export)
          String status = _valToString(row[10]?.value) ?? 'Planned';
          String responsiblePerson = _valToString(row[11]?.value) ?? '';
          String targetDate = _valToString(row[12]?.value) ?? 'Unspecified';

          String? obj = fundingSource == 'Agri MOOE'
              ? _parseObjectOfExpenditure(objOrFund)
              : null;

          if (fundingSource == 'Special Funds' ||
              (fundingSource != 'Agri MOOE' && objOrFund.isNotEmpty)) {
            final parsedFund = _parseSpecialFundSource(objOrFund);
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
              location: location,
            ),
          );
        }
      }

      if (activitiesToImport.isNotEmpty) {
        await fbService.batchAddActivities(activitiesToImport);
      }
    }
  }

  static String? _valToString(CellValue? cell) {
    if (cell == null) return null;
    return cell.toString();
  }

  static int? _valToInt(CellValue? cell) {
    if (cell == null) return null;
    if (cell is IntCellValue) return cell.value;
    return int.tryParse(cell.toString());
  }

  static double? _valToDouble(CellValue? cell) {
    if (cell == null) return null;
    if (cell is DoubleCellValue) return cell.value;
    if (cell is IntCellValue) return cell.value.toDouble();
    return double.tryParse(cell.toString());
  }

  static String? _parseObjectOfExpenditure(String value) {
    final v = value.trim().toLowerCase();
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
    return 'Other-MOE Expenses';
  }

  static String? _parseSpecialFundSource(String value) {
    final v = value.trim().toLowerCase();
    if (v.contains('20%')) return '20% DF';
    if (v.contains('gad')) return 'GAD';
    if (v.contains('cpoc')) return 'CPOC';
    if (v.contains('cdrrmo')) return 'CDRRMO';
    if (v.contains('capital')) return 'Capital Outlay';
    if (v.contains('mayor')) return 'Mayors Fund';
    if (v.contains('agri') || v.contains('mooe')) return 'Agri MOOE';
    return '20% DF';
  }
}

