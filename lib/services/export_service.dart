import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/activity.dart';
import '../core/date_formatter.dart';
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
        fmt(act.actualExpenditure),
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
        List<dynamic> bRow = List.filled(35, '');
        bRow[3] = '    ${item.name}';
        String qStr = '';
        if ((item.q1Qty ?? 0) > 0 || (item.q2Qty ?? 0) > 0 || (item.q3Qty ?? 0) > 0 || (item.q4Qty ?? 0) > 0) {
          qStr = ' (Q1:${item.q1Qty ?? 0}, Q2:${item.q2Qty ?? 0}, Q3:${item.q3Qty ?? 0}, Q4:${item.q4Qty ?? 0})';
        }
        bRow[34] =
            '${item.fullDisplayNameWithFallback(act.fundingSource, act.objectOfExpenditure)}: ${fmt(item.amount)}$qStr';
        csvData.add(bRow);
      }
    }

    String csvString = csvData
        .map(
          (row) => row
              .map((field) => '"${field.toString().replaceAll('"', '""')}"')
              .join(','),
        )
        .join('\n');

    return await saveFile(utf8.encode(csvString), 'activities_export', 'csv');
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
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0),
    );
    var mooeHeader = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
    );
    mooeHeader.value = TextCellValue('MOOE');
    mooeHeader.cellStyle = headerStyle;

    // Second Header Row
    List<String> headers = [
      'No.', // A
      'Activity Name', // B
      'Other-MOE', // C
      'Trainings & Seminar', // D
      'Appropriation', // E
      'PPMP BALANCE', // F
      'PR', // G
      'PR Balance', // H
      'PO Amount', // I
      'Supplier', // J
      'BARCODE', // K
    ];

    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    for (int i = 0; i < headers.length; i++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
              )
              .cellStyle =
          i >= 2 && i <= 4 ? subHeaderStyle : headerStyle;
    }

    int currentRow = 2;

    for (var sector in groupedActivities.keys) {
      List<Activity> acts = groupedActivities[sector]!;
      
      // Calculate sector totals
      double sectorAppropriation = acts.fold(0, (s, a) => s + a.approvedBudget);
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
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
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
                .where(
                  (i) =>
                      i.objectOfExpenditure == 'Other-MOE' ||
                      i.objectOfExpenditure == 'Other MOE',
                )
                .fold(0.0, (s, i) => s + i.amount),
          ), // C
          DoubleCellValue(
            act.trainingSeminarAmount +
                act.breakdown
                    .where(
                      (i) =>
                          i.objectOfExpenditure ==
                          'Trainings and Seminar Expenses',
                    )
                    .fold(0.0, (s, i) => s + i.amount),
          ), // D
          DoubleCellValue(act.approvedBudget), // E
          DoubleCellValue(act.ppmpBalance), // F
          act.prAmount > 0 ? DoubleCellValue(act.prAmount) : TextCellValue(''), // G
          act.prBalance > 0 ? DoubleCellValue(act.prBalance) : TextCellValue(''), // H
          act.actualExpenditure > 0 ? DoubleCellValue(act.actualExpenditure) : TextCellValue(''), // I
          TextCellValue(act.otherMoeSuppliers), // J
          TextCellValue(act.barcodeApprop), // K
        ]);

        for (int i = 0; i < 12; i++) {
          sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: i,
                      rowIndex: currentRow,
                    ),
                  )
                  .cellStyle =
              (i >= 2 && i <= 8) ? numberStyle : dataStyle;
        }
        
        currentRow++;
        actIdx++;
      }
      
      // Add a spacer row between sections
      sheet.appendRow(List.filled(12, TextCellValue('')));
      currentRow++;
    }

    // Set Column Widths
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 45);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 22);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 15);
    sheet.setColumnWidth(7, 15);
    sheet.setColumnWidth(8, 15);
    sheet.setColumnWidth(9, 25);
    sheet.setColumnWidth(10, 15);
    sheet.setColumnWidth(11, 20);

    final bytes = excel.save();
    return await saveFile(
      bytes!,
      'Financial_Report_${DateFormat('MM-dd-yyyy').format(DateTime.now())}',
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
    double totalE = activities.fold(0, (s, a) => s + a.actualExpenditure);

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
                final e = acts.fold(0.0, (s, a) => s + a.actualExpenditure);
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
                        e += a.actualExpenditure * ratio;
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
                      e += a.actualExpenditure;
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
                  fmt(a.actualExpenditure),
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
                      : 'N/A',
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
      'Consolidated_WFP_Report',
      'pdf',
    );
  }

  static String fmt(double val) =>
      NumberFormat.simpleCurrency(name: '').format(val);
  static String fmtInt(int val) => NumberFormat('#,##0').format(val);
  static String formatToMMDDYYYY(String? d) {
    if (d == null || d.isEmpty) return '';
    final dt = AppDateFormatter.parse(d);
    if (dt != null) return AppDateFormatter.format(dt);
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
      String suf = "_$c";
      res =
          (s.length + suf.length > 31 ? s.substring(0, 31 - suf.length) : s) +
          suf;
      c++;
    }
    exist.add(res);
    return res;
  }

}
