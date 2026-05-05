import 'dart:convert';

import 'package:cityagriadmin/models/budget_line.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/date_formatter.dart';
import '../models/activity.dart';
import 'file_saver.dart';

class ExportService {
  static Future<String?> exportActivitiesToCSV(
    List<Activity> activities, {
    String? exportedBy,
  }) async {
    List<List<dynamic>> csvData = [
      if (exportedBy != null)
        [
          'Exported By:',
          exportedBy,
          '',
          'Date:',
          DateFormat('MM/dd/yyyy h:mm a').format(DateTime.now()),
        ],
      if (exportedBy != null) [],
      [
        'No.',
        'Section/Unit',
        'Section/Unit Head',
        'PPA / Activity Name',
        'Location',
        'Performance Indicator (Unit)',
        'Target (No.)',
        'Target Date',
        'Target Participants',
        'Funding Source',
        'Object of Expenditure / Special Funding Source',
        'Suppliers (Other-MOE)',
        'Q1 Budget (PHP)',
        'Q2 Budget (PHP)',
        'Mid-Year (PHP)',
        'Q3 Budget (PHP)',
        'Q4 Budget (PHP)',
        'Whole Year (PHP)',
        'PO AMOUNT',
        'PPMP BALANCE',
        'PR #',
        'PR',
        'Balance',
        'Date',
        'Responsible Person',
        'Funding Source Inputted By',
        'ACCOM Remarks',
        'Actual Conduct',
        'Breakdown',
      ],
    ];

    int actCount = 1;
    for (var act in activities) {
      csvData.add([
        actCount.toString(),
        act.subSector != null ? '${act.sector} (${act.subSector})' : act.sector,
        act.unitHead ?? '',
        act.activityName,
        act.location ?? '',
        act.performanceIndicator,
        fmtInt(act.targetNo),
        formatToMMDDYYYY(act.targetDate),
        act.targetParticipants,
        act.formattedSource,
        act.formattedSource,
        act.otherMoeSuppliers,
        fmt(act.q1Budget),
        fmt(act.q2Budget),
        fmt(act.midYearBudget),
        fmt(act.q3Budget),
        fmt(act.q4Budget),
        fmt(act.approvedBudget),
        fmt(act.effectivePOAmount),
        fmt(act.ppmpBalance),
        act.prNumber,
        fmt(act.prAmount),
        fmt(act.unexpendedBalance),
        formatToMMDDYYYY(act.statusDate),
        act.responsiblePerson,
        act.fundingInputtedBy ?? '',
        act.accommRemarks,
        act.actualConduct,
        '',
      ]);
      actCount++;

      for (var item in act.breakdown) {
        List<dynamic> bRow = List.filled(csvData[csvData.length - 1].length, '');
        bRow[3] = '    - ${item.name}';
        String qStr = '';
        if ((item.q1Qty ?? 0) > 0 || (item.q2Qty ?? 0) > 0 || (item.q3Qty ?? 0) > 0 || (item.q4Qty ?? 0) > 0) {
          qStr = ' (Q1:${item.q1Qty ?? 0}, Q2:${item.q2Qty ?? 0}, Q3:${item.q3Qty ?? 0}, Q4:${item.q4Qty ?? 0})';
        }
        // Column index 28 is "Breakdown" in headers
        if (bRow.length > 28) {
          bRow[28] = '${item.fullDisplayNameWithFallback(act.fundingSource, act.objectOfExpenditure)}: ${fmt(item.amount)}$qStr';
        }
        csvData.add(bRow);
      }
    }

    String csvString = csvData
        .map(
          (row) => row
              .map((field) => '"${(field?.toString() ?? "").replaceAll('"', '""')}"')
              .join(','),
        )
        .join('\n');

    return await saveFile(utf8.encode(csvString), 'activities export', 'csv');
  }

  static Future<String?> exportActivitiesToExcel(
    List<Activity> activities, {
    String? exportedBy,
  }) async {
    final excel = Excel.createExcel();

    // Grouping
    Map<String, List<Activity>> groupedActivities = {};
    for (var act in activities) {
      groupedActivities.putIfAbsent(act.sector, () => []).add(act);
    }

    // Styles
    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#3F51B5'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontFamily: getFontFamily(FontFamily.Arial),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle subHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontFamily: getFontFamily(FontFamily.Arial),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle dataStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 10,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle numberStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 10,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      numberFormat: CustomNumericNumFormat(formatCode: '#,##0.00'),
    );

    CellStyle sectionHeaderStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FF0000'),
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 12,
    );

    CellStyle sectionNumberStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FF0000'),
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: 12,
      numberFormat: CustomNumericNumFormat(formatCode: '#,##0.00'),
    );

    // 1. Financial Report Sheet
    String reportSheetName = 'Financial Report';
    excel.rename('Sheet1', reportSheetName);
    Sheet sheet = excel[reportSheetName];

    // Header Row 1 (Merging MOOE)
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
    );
    var mooeHeader = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
    );
    mooeHeader.value = TextCellValue('MOOE / EXPENDITURE BREAKDOWN');
    mooeHeader.cellStyle = headerStyle;

    // Second Header Row
    List<String> headers = [
      'No.', // A
      'Activity Name', // B
      'Other-MOE', // C
      'Trainings & Seminar', // D
      'Meetings', // E
      '20% DF', // F
      'Appropriation', // G
      'PPMP BALANCE', // H
      'PR', // I
      'PR Balance', // J
      'PO Amount', // K
      'Supplier', // L
      'BARCODE', // M
    ];

    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int i = 0; i < headers.length; i++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
              )
              .cellStyle =
          i >= 2 && i <= 5 ? subHeaderStyle : headerStyle;
    }

    int currentRow = 2;

    for (var sector in groupedActivities.keys) {
      List<Activity> acts = groupedActivities[sector]!;
      
      // Calculate sector totals
      double sectorAppropriation = acts.fold(0, (s, a) => s + (a.appropriation > 0 ? a.appropriation : a.approvedBudget));
      double sectorPPMPBalance = acts.fold(0, (s, a) => s + a.ppmpBalance);

      // Section Header Row
      var sectorCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      sectorCell.value = TextCellValue(
        '$sector ${NumberFormat.simpleCurrency(name: 'PHP ').format(sectorAppropriation)}',
      );
      sectorCell.cellStyle = sectionHeaderStyle;
      
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
      );

      // PPMP Balance for section
      var sectorPPMPCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow),
      );
      sectorPPMPCell.value = DoubleCellValue(sectorPPMPBalance);
      sectorPPMPCell.cellStyle = sectionNumberStyle;

      currentRow++;

      // Activity Rows
      int actIdx = 1;
      for (var act in acts) {
        sheet.appendRow([
          TextCellValue(actIdx.toString()), // A
          TextCellValue(act.activityName), // B
          DoubleCellValue(
            act.breakdown
                .where((i) => (i.objectOfExpenditure?.contains('Other-MOE') ?? false) || (i.objectOfExpenditure?.contains('Other MOE') ?? false))
                .fold(0.0, (s, i) => s + i.amount),
          ), // C
          DoubleCellValue(
            act.trainingSeminarAmount +
                act.breakdown
                    .where((i) => i.objectOfExpenditure == 'Trainings and Seminar Expenses')
                    .fold(0.0, (s, i) => s + i.amount),
          ), // D
          DoubleCellValue(
            act.meetingsAmount +
                act.breakdown
                    .where((i) => i.objectOfExpenditure == 'Meetings Expenses')
                    .fold(0.0, (s, i) => s + i.amount),
          ), // E
          DoubleCellValue(
            act.df20Amount +
                act.breakdown
                    .where((i) => i.fullDisplayNameWithFallback(act.fundingSource, act.objectOfExpenditure) == '20% DF')
                    .fold(0.0, (s, i) => s + i.amount),
          ), // F
          DoubleCellValue(act.appropriation > 0 ? act.appropriation : act.approvedBudget), // G
          DoubleCellValue(act.ppmpBalance), // H
          act.prAmount > 0 ? DoubleCellValue(act.prAmount) : TextCellValue(''), // I
          act.prBalance > 0 ? DoubleCellValue(act.prBalance) : TextCellValue(''), // J
          act.effectivePOAmount > 0 ? DoubleCellValue(act.effectivePOAmount) : TextCellValue(''), // K
          TextCellValue(act.otherMoeSuppliers), // L
          TextCellValue(act.barcodeApprop), // M
        ]);

        for (int i = 0; i < headers.length; i++) {
          sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: i,
                      rowIndex: currentRow,
                    ),
                  )
                  .cellStyle =
              (i >= 2 && i <= 10) ? numberStyle : dataStyle;
        }
        
        currentRow++;
        actIdx++;
      }
      
      // Add a spacer row between sections
      sheet.appendRow(List.filled(12, TextCellValue('')));
      currentRow++;
    }

    // Set Column Widths
    // Set Column Widths
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 45);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 22);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 18);
    sheet.setColumnWidth(7, 18);
    sheet.setColumnWidth(8, 15);
    sheet.setColumnWidth(9, 15);
    sheet.setColumnWidth(10, 15);
    sheet.setColumnWidth(11, 25);
    sheet.setColumnWidth(12, 15);

    final bytes = excel.save();
    return await saveFile(
      bytes!,
      'Financial Report ${DateFormat('MM-dd-yyyy').format(DateTime.now())}',
      'xlsx',
    );
  }

  static Future<String?> exportActivitiesToPdf(
    List<Activity> activities, {
    String? exportedBy,
  }) async {
    final pdf = pw.Document();
    Map<String, List<Activity>> sectorMap = {};
    for (var a in activities) {
      sectorMap.putIfAbsent(a.sector, () => []).add(a);
    }
    final sectors = sectorMap.keys.toList()..sort();

    Map<String, List<Activity>> expMap = {};
    for (var a in activities) {
      if (a.breakdown.isNotEmpty &&
          a.breakdown.any(
            (item) =>
                (item.fundingSource != null &&
                    item.fundingSource!.isNotEmpty) ||
                (item.objectOfExpenditure != null &&
                    item.objectOfExpenditure!.isNotEmpty),
          )) {
        final usedTypes = <String>{};
        for (var item in a.breakdown) {
          final type = item.fullDisplayNameWithFallback(
            a.fundingSource,
            a.objectOfExpenditure,
          );
          if (usedTypes.add(type)) expMap.putIfAbsent(type, () => []).add(a);
        }
      } else {
        final type = a.formattedSource;
        expMap.putIfAbsent(type, () => []).add(a);
      }
    }
    final expTypes = expMap.keys.toList()..sort();

    double totalB = activities.fold(0, (s, a) => s + a.approvedBudget);
    double totalE = activities.fold(0, (s, a) => s + a.effectivePOAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'AWFPS - Exported: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'AgriWork & Financial Planning System (AWFPS) - CONSOLIDATED REPORT',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              buildStatBox('TOTAL BUDGET', totalB, PdfColors.blue900),
              buildStatBox('TOTAL PO AMOUNT', totalE, PdfColors.orange900),
              buildStatBox('BALANCE', totalB - totalE, PdfColors.green900),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'I. SUMMARY BY SECTION/UNIT',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: ['Section', 'Budget', 'PO AMOUNT', 'Balance', 'Activities'],
            data: [
              ...sectors.map((s) {
                final acts = sectorMap[s]!;
                final b = acts.fold(0.0, (s, a) => s + a.approvedBudget);
                final e = acts.fold(0.0, (s, a) => s + a.effectivePOAmount);
                return [
                  s,
                  fmt(b),
                  fmt(e),
                  fmt(b - e),
                  acts.length.toString(),
                ];
              }),
              [
                'GRAND TOTAL',
                fmt(totalB),
                fmt(totalE),
                fmt(totalB - totalE),
                activities.length.toString(),
              ],
            ],
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'II. BREAKDOWN BY EXPENDITURE TYPE',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: [
              'Expenditure Category',
              'Budget',
              'PO AMOUNT',
              'Balance',
              'Trainings',
              'Meetings',
              '20% DF',
              'PPMP BALANCE',
              'PR',
              'PR Bal',
              'Count',
            ],
            data: [
              ...expTypes.map((t) {
                double b = 0,
                    e = 0,
                    tr = 0,
                    mt = 0,
                    df = 0,
                    pp = 0,
                    prTotal = 0,
                    pr = 0;
                int count = 0;
                for (var a in activities) {
                  bool matched = false;
                  if (a.breakdown.isNotEmpty &&
                      a.breakdown.any(
                        (item) =>
                            (item.fundingSource != null &&
                                item.fundingSource!.isNotEmpty) ||
                            (item.objectOfExpenditure != null &&
                                item.objectOfExpenditure!.isNotEmpty),
                      )) {
                    final totalBreakdown = a.breakdown.fold(
                      0.0,
                      (sum, item) => sum + item.amount,
                    );
                    for (var item in a.breakdown) {
                      final itemType = item.fullDisplayNameWithFallback(
                        a.fundingSource,
                        a.objectOfExpenditure,
                      );
                      if (itemType == t) {
                        matched = true;
                        final ratio = totalBreakdown > 0
                            ? item.amount / totalBreakdown
                            : 0.0;
                        b += item.amount;
                        e += a.effectivePOAmount * ratio;
                        tr +=
                            (a.trainingSeminarAmount +
                                a.breakdown
                                    .where(
                                      (i) =>
                                          i.objectOfExpenditure ==
                                          'Trainings and Seminar Expenses',
                                    )
                                    .fold(0.0, (s, i) => s + i.amount)) *
                            ratio;
                        mt +=
                            (a.meetingsAmount +
                                a.breakdown
                                    .where(
                                      (i) =>
                                          i.objectOfExpenditure ==
                                          'Meetings Expenses',
                                    )
                                    .fold(0.0, (s, i) => s + i.amount)) *
                            ratio;
                        df +=
                            (a.df20Amount +
                                a.breakdown
                                    .where(
                                      (i) =>
                                          i.fullDisplayNameWithFallback(
                                            a.fundingSource,
                                            a.objectOfExpenditure,
                                          ) ==
                                          '20% DF',
                                    )
                                    .fold(0.0, (s, i) => s + i.amount)) *
                            ratio;
                        pp += a.ppmpBalance * ratio;
                        prTotal += a.prAmount * ratio;
                        pr += a.prBalance * ratio;
                      }
                    }
                  } else {
                    if (a.formattedSource == t) {
                      matched = true;
                      b += a.approvedBudget;
                      e += a.effectivePOAmount;
                      tr +=
                          a.trainingSeminarAmount +
                          a.breakdown
                              .where(
                                (i) =>
                                    i.objectOfExpenditure ==
                                    'Trainings and Seminar Expenses',
                              )
                              .fold(0.0, (s, i) => s + i.amount);
                      mt +=
                          a.meetingsAmount +
                          a.breakdown
                              .where(
                                (i) =>
                                    i.objectOfExpenditure ==
                                    'Meetings Expenses',
                              )
                              .fold(0.0, (s, i) => s + i.amount);
                      df +=
                          a.df20Amount +
                          a.breakdown
                              .where(
                                (i) =>
                                    i.fullDisplayNameWithFallback(
                                      a.fundingSource,
                                      a.objectOfExpenditure,
                                    ) ==
                                    '20% DF',
                              )
                              .fold(0.0, (s, i) => s + i.amount);
                      pp += a.ppmpBalance;
                      prTotal += a.prAmount;
                      pr += a.prBalance;
                    }
                  }
                  if (matched) count++;
                }

                return [
                  t,
                  fmt(b),
                  fmt(e),
                  fmt(b - e),
                  fmt(tr),
                  fmt(mt),
                  fmt(df),
                  fmt(pp),
                  fmt(prTotal),
                  fmt(pr),
                  count.toString(),
                ];
              }),
              [
                'GRAND TOTAL',
                fmt(totalB),
                fmt(totalE),
                fmt(totalB - totalE),
                fmt(
                  activities.fold(
                    0.0,
                    (s, a) =>
                        s +
                        a.trainingSeminarAmount +
                        a.breakdown
                            .where(
                              (i) =>
                                  i.objectOfExpenditure ==
                                  'Trainings and Seminar Expenses',
                            )
                            .fold(0.0, (ss, ii) => ss + ii.amount),
                  ),
                ),
                fmt(
                  activities.fold(
                    0.0,
                    (s, a) =>
                        s +
                        a.meetingsAmount +
                        a.breakdown
                            .where(
                              (i) =>
                                  i.objectOfExpenditure == 'Meetings Expenses',
                            )
                            .fold(0.0, (ss, ii) => ss + ii.amount),
                  ),
                ),
                fmt(
                  activities.fold(
                    0.0,
                    (s, a) =>
                        s +
                        a.df20Amount +
                        a.breakdown
                            .where(
                              (i) =>
                                  i.fullDisplayNameWithFallback(
                                    a.fundingSource,
                                    a.objectOfExpenditure,
                                  ) ==
                                  '20% DF',
                            )
                            .fold(0.0, (ss, ii) => ss + ii.amount),
                  ),
                ),
                fmt(activities.fold(0.0, (s, a) => s + a.ppmpBalance)),
                fmt(activities.fold(0.0, (s, a) => s + a.prAmount)),
                fmt(activities.fold(0.0, (s, a) => s + a.prBalance)),
                activities.length.toString(),
              ],
            ],
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'III. DETAILED ACTIVITY LIST',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: [
              'No.',
              'Activity Name',
              'Section',
              'Responsible',
              'Budget',
              'Spent',
              'Breakdown (Item: Amount [Source])',
            ],
            data: () {
              int count = 1;
              return activities.map((a) {
                return [
                  (count++).toString(),
                  a.activityName,
                  a.sector,
                  a.responsiblePerson,
                  fmt(a.approvedBudget),
                  fmt(a.effectivePOAmount),
                  a.breakdown.isNotEmpty
                      ? a.breakdown
                            .map(
                                (e) {
                                  String qStr = '';
                                  if ((e.q1Qty ?? 0) > 0 || (e.q2Qty ?? 0) > 0 || (e.q3Qty ?? 0) > 0 || (e.q4Qty ?? 0) > 0) {
                                    qStr = ' (Q1:${e.q1Qty ?? 0}, Q2:${e.q2Qty ?? 0}, Q3:${e.q3Qty ?? 0}, Q4:${e.q4Qty ?? 0})';
                                  }
                                  return '${e.fullDisplayNameWithFallback(a.fundingSource, a.objectOfExpenditure)}: ${fmt(e.amount)}$qStr';
                                },
                            )
                            .join('\n')
                      : '',
                ];
              }).toList();
            }(),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(4),
            },
          ),
        ],
      ),
    );
    return await saveFile(
      (await pdf.save()).toList(),
      'Consolidated WFP Report',
      'pdf',
    );
  }

  static String fmt(double val) =>
      NumberFormat.simpleCurrency(name: '').format(val);
  static String fmtInt(int val) => NumberFormat('#,##0').format(val);
  static String formatToMMDDYYYY(String? d) {
    if (d == null || d.isEmpty || d.toLowerCase() == 'null') return '';
    final dt = DateFormatter.parse(d);
    if (dt != null) return DateFormatter.format(dt);
    return d;
  }


  static pw.Widget buildStatBox(String label, double val, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(
            NumberFormat.simpleCurrency(name: 'PHP ').format(val),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  static String sanitizeSheetName(String n, Set<String> exist) {
    String s = n.replaceAll(RegExp(r'[:\\/?*\[\]]'), '').trim();
    if (s.length > 31) s = s.substring(0, 31);
    String res = s;
    int c = 1;
    while (exist.contains(res)) {
      String suf = " $c";
      res =
          (s.length + suf.length > 31 ? s.substring(0, 31 - suf.length) : s) +
          suf;
      c++;
    }
    exist.add(res);
    return res;
  }

  /// Exports a list of activities with their itemized breakdowns to an Excel file
  /// specifically formatted for City Agriculture PPMP to BAC submission.
  static Future<String?> exportToAgriPpmpToBac(List<Activity> activities) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2E7D32'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle dataStyle = CellStyle(
      fontSize: 10,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle numberStyle = CellStyle(
      fontSize: 10,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      numberFormat: CustomNumericNumFormat(formatCode: '#,##0.00'),
    );

    List<String> headers = [
      'Sector/Section',
      'Responsible Person',
      'PPA/Activity',
      'Funding Source',
      'Object of Expenditure',
      'Item Description',
      'Unit',
      'Quantity',
      'Estimated Cost',
      'Total Amount',
      'Q1',
      'Q2',
      'Q3',
      'Q4',
      'Supplier',
      'Status',
      'Status Date',
    ];

    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    int rowIndex = 1;
    Map<String, List<Activity>> groups = {};
    for (var a in activities) {
      groups.putIfAbsent(a.sector, () => []).add(a);
    }

    final sortedSectors = groups.keys.toList()..sort();

    for (var sector in sortedSectors) {
      for (var act in groups[sector]!) {
        for (var item in act.breakdown) {
          final fs = (item.fundingSource != null && item.fundingSource!.isNotEmpty)
              ? item.fundingSource!
              : act.fundingSource;
          final oe = (item.objectOfExpenditure != null && item.objectOfExpenditure!.isNotEmpty)
              ? item.objectOfExpenditure!
              : (act.objectOfExpenditure ?? '');

          sheet.appendRow([
            TextCellValue(act.sector),
            TextCellValue(act.responsiblePerson),
            TextCellValue(act.activityName),
            TextCellValue(fs),
            TextCellValue(oe),
            TextCellValue(item.name),
            TextCellValue(item.unit ?? ''),
            IntCellValue(item.qty),
            DoubleCellValue(item.unitCost),
            DoubleCellValue(item.amount),
            IntCellValue((item.q1Qty ?? 0).toInt()),
            IntCellValue((item.q2Qty ?? 0).toInt()),
            IntCellValue((item.q3Qty ?? 0).toInt()),
            IntCellValue((item.q4Qty ?? 0).toInt()),
            TextCellValue(item.supplier ?? ''),
            TextCellValue(item.status ?? ''),
            TextCellValue(item.statusDate ?? ''),
          ]);

          for (int i = 0; i < headers.length; i++) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex)).cellStyle =
                (i >= 8 && i <= 13) ? numberStyle : dataStyle;
          }
          rowIndex++;
        }
      }
    }

    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 35);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 25);
    sheet.setColumnWidth(5, 30);
    for (int i = 6; i <= 13; i++) {
      sheet.setColumnWidth(i, 12);
    }
    sheet.setColumnWidth(14, 20);
    sheet.setColumnWidth(15, 15);
    sheet.setColumnWidth(16, 15);

    final bytes = excel.save();
    return await saveFile(bytes!, 'AGRI PPMP TO BAC ${DateFormat('MM-dd-yyyy').format(DateTime.now())}', 'xlsx');
  }

  /// Exports the proposed and approved budget lines to an Excel file.
  static Future<String?> exportToProposedBudget(List<BudgetLine> lines) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle dataStyle = CellStyle(
      fontSize: 10,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle numberStyle = CellStyle(
      fontSize: 10,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      numberFormat: CustomNumericNumFormat(formatCode: '#,##0.00'),
    );

    List<String> headers = [
      'Category',
      'Agri MOOE',
      'Fund Source',
      'Object of Expenditure',
      'Proposed Budget',
      'Proposed Expenditures',
      'Approved Budget',
      'Appropriation',
      'PPMP Amount',
      'PR Amount',
      'PO Amount',
      'Available Balance',
    ];

    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    int rowIndex = 1;
    for (var line in lines) {
      sheet.appendRow([
        TextCellValue(line.isCMO ? 'CMO Budget' : 'Regular'),
        TextCellValue(line.isAgriMooe ? 'Yes' : 'No'),
        TextCellValue(line.fundSource),
        TextCellValue(line.objectOfExpenditure),
        DoubleCellValue(line.proposedBudget),
        DoubleCellValue(line.proposedExpenditure),
        DoubleCellValue(line.approvedAmount),
        DoubleCellValue(line.appropriation),
        DoubleCellValue(line.ppmpAmount),
        DoubleCellValue(line.prAmount),
        DoubleCellValue(line.poAmount),
        DoubleCellValue(line.currentBalance),
      ]);

      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex)).cellStyle =
            (i >= 4) ? numberStyle : dataStyle;
      }
      rowIndex++;
    }

    sheet.setColumnWidth(0, 15);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 30);
    for (int i = 4; i < 12; i++) {
      sheet.setColumnWidth(i, 18);
    }

    final bytes = excel.save();
    return await saveFile(bytes!, '2026 PROPOSED BUDGET ${DateFormat('MM-dd-yyyy').format(DateTime.now())}', 'xlsx');
  }

  static Future<String?> exportToWfpAdmin(List<Activity> activities) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#6A1B9A'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle dataStyle = CellStyle(
      fontSize: 10,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    CellStyle numberStyle = CellStyle(
      fontSize: 10,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      numberFormat: CustomNumericNumFormat(formatCode: '#,##0.00'),
    );

    List<String> headers = [
      'PPA/Activity',
      'Section/Unit',
      'Funding Source',
      'Responsible Person',
      'Performance Indicator',
      'Target',
      'Budget',
      'Timeline',
    ];

    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }

    int rowIndex = 1;
    for (var act in activities) {
      sheet.appendRow([
        TextCellValue(act.activityName),
        TextCellValue(act.sector),
        TextCellValue(act.formattedSource),
        TextCellValue(act.responsiblePerson),
        TextCellValue(act.performanceIndicator),
        IntCellValue(act.targetNo),
        DoubleCellValue(act.approvedBudget),
        TextCellValue('${act.selectedMonth} ${act.selectedYear}'),
      ]);

      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex)).cellStyle =
            (i == 6) ? numberStyle : dataStyle;
      }
      rowIndex++;
    }

    sheet.setColumnWidth(0, 40);
    sheet.setColumnWidth(1, 25);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 30);
    sheet.setColumnWidth(5, 10);
    sheet.setColumnWidth(6, 15);
    sheet.setColumnWidth(7, 20);

    final bytes = excel.save();
    return await saveFile(bytes!, '2026 WFP ADMIN ${DateFormat('MM-dd-yyyy').format(DateTime.now())}', 'xlsx');
  }

  static Future<String?> exportRiceAndCornProgramReport(List<Activity> activities) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['PPMP 2026'];
    excel.delete('Sheet1');

    // Filter for Rice and Corn programs
    final filtered = activities.where((a) => 
      a.activityName.toLowerCase().contains('rice') || 
      a.activityName.toLowerCase().contains('corn')
    ).toList();

    // Sort by Section/Unit then Name
    filtered.sort((a, b) {
      int sectorComp = a.sector.compareTo(b.sector);
      if (sectorComp != 0) return sectorComp;
      return a.activityName.compareTo(b.activityName);
    });

    // Styles
    CellStyle headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
      fontFamily: getFontFamily(FontFamily.Arial),
    );

    CellStyle alertStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#FF0000'), // Red
      bold: true,
    );

    // Headers
    sheet.appendRow([TextCellValue('AGENCY: CITY AGRICULTURE OFFICE')]);
    sheet.appendRow([TextCellValue('PROGRAM: RICE & CORN PROGRAMS')]);
    sheet.appendRow([TextCellValue('YEAR: 2026')]);
    sheet.appendRow([]); // spacer

    List<CellValue> headers = [
      TextCellValue('Item & Specifications'),
      TextCellValue('Unit'),
      TextCellValue('Quantity'),
      TextCellValue('Unit Cost'),
      TextCellValue('TOTAL AMOUNT'),
      TextCellValue('Q1'),
      TextCellValue('Q2'),
      TextCellValue('Q3'),
      TextCellValue('Q4'),
      TextCellValue('Status'),
      TextCellValue('Responsible (HIDDEN)'),
      TextCellValue('Barcode (HIDDEN)'),
    ];
    sheet.appendRow(headers);
    
    // Apply header style
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4)).cellStyle = headerStyle;
    }

    double grandTotal = 0;
    String currentSector = '';

    for (var activity in filtered) {
      if (activity.sector != currentSector) {
        currentSector = activity.sector;
        sheet.appendRow([TextCellValue(currentSector.toUpperCase())]);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheet.maxRows - 1)).cellStyle = CellStyle(bold: true, italic: true);
      }

      double unitCost = activity.targetNo > 0 ? activity.ppmpAmount / activity.targetNo : 0;
      
      List<CellValue> rowData = [
        TextCellValue(activity.activityName),
        TextCellValue(activity.unit ?? 'set/unit'),
        IntCellValue(activity.targetNo),
        DoubleCellValue(unitCost),
        DoubleCellValue(activity.ppmpAmount),
        DoubleCellValue(activity.q1Budget),
        DoubleCellValue(activity.q2Budget),
        DoubleCellValue(activity.q3Budget),
        DoubleCellValue(activity.q4Budget),
        TextCellValue(activity.status),
        TextCellValue(activity.responsiblePerson),
        TextCellValue(activity.barcodeApprop),
      ];

      sheet.appendRow(rowData);
      int currentRowIdx = sheet.maxRows - 1;

      // Conditional Formatting: Red for No Budget or Recanvas
      if (activity.status == 'No Budget' || activity.status == 'Recanvas') {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRowIdx)).cellStyle = alertStyle;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRowIdx)).cellStyle = alertStyle;
      }

      grandTotal += activity.ppmpAmount;
    }

    // Summary Row
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('TOTAL PROGRAM COST:'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(grandTotal),
    ]);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheet.maxRows - 1)).cellStyle = CellStyle(bold: true);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: sheet.maxRows - 1)).cellStyle = CellStyle(bold: true);

    // Set Column Widths
    sheet.setColumnWidth(0, 50); // Item & Specs
    sheet.setColumnWidth(4, 20); // Total Amount
    sheet.setColumnWidth(10, 0); // Hide Responsible
    sheet.setColumnWidth(11, 0); // Hide Barcode

    final bytes = excel.save();
    return await saveFile(bytes!, 'AGRI_PPMP_RICE_CORN_2026', 'xlsx');
  }

}
