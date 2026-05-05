import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import '../models/budget_line.dart';
import '../models/expenditure.dart';
import '../models/program.dart';
import 'firebase_service.dart';

class ProjectInitializationService {
  static Future<void> initialize2026Targets(FirebaseService fbService) async {
    try {
      // 1. Initialize Budget Lines
      await initialize2026Budgets(fbService);

      // 1.5 Initialize Programs
      await initialize2026Programs(fbService);

      // 2. Initialize Sample Expenditures
      await initialize2026Expenditures(fbService);

      // 3. Initialize Activity Targets
      final targets = [
        {'sector': 'Crop Section', 'target': 35, 'name': 'PR & PPMP Facilitation (Crops)'},
        {'sector': 'Inland Fisheries Section', 'target': 5, 'name': 'PR & PPMP Facilitation (Fisheries)'},
        {'sector': 'Institutional Development Section', 'target': 23, 'name': 'PR & PPMP Facilitation (IDS)'},
        {'sector': 'Integrated Agricultural Laboratory', 'target': 11, 'name': 'PR & PPMP Facilitation (PMED/Lab)'},
      ];

      for (var config in targets) {
        final sector = config['sector'] as String;
        final targetCount = config['target'] as int;
        final baseName = config['name'] as String;

        // Check if we already have activities for this sector with this name
        final isDuplicate = await fbService.checkDuplicateActivity(baseName, sector, 'January 2026');
        
        if (!isDuplicate) {
          debugPrint('Initializing $targetCount targets for $sector...');
          
          final activity = Activity(
            id: '', // Will be set by Firestore
            sector: sector,
            activityName: baseName,
            performanceIndicator: 'No. of PPAs facilitated',
            targetNo: targetCount,
            fundingSource: 'Agri MOOE',
            responsiblePerson: 'Admin',
            status: 'Planned',
            targetDate: 'January 2026',
            targetParticipants: 'Office Staff',
            location: 'Office',
          );
          
          await fbService.addActivity(activity);
        }
      }
      
      debugPrint('2026 Targets initialization completed.');
    } catch (e) {
      debugPrint('Error initializing 2026 targets: $e');
    }
  }

  static Future<void> initialize2026Budgets(FirebaseService fbService) async {
    try {
      // Training & Seminars Budget Line (Account Code: 5-02-02-010)
      final trainingLine = BudgetLine(
        id: 'training-seminars-2026',
        accountCode: '5-02-02-010',
        fundSource: 'Agri MOOE',
        objectOfExpenditure: 'Trainings and Seminar Expenses',
        approvedAmount: 500000.00,
        currentBalance: 500000.00,
        ppmpAmount: 499393.00,
        budgetLimit: 500000.00,
        q1Ppmp: 125000.00,
        q2Ppmp: 119824.00,
        q3Ppmp: 124425.00,
        q4Ppmp: 117144.00,
        isAgriMooe: true,
      );

      // Agricultural and Marine Supplies Expenses
      final agriSuppliesLine = BudgetLine(
        id: 'agri-marine-supplies-2026',
        accountCode: '5-02-03-040',
        fundSource: 'Agri MOOE',
        objectOfExpenditure: 'Agricultural and Marine Supplies Expenses',
        approvedAmount: 8500000.00,
        currentBalance: 8500000.00,
        ppmpAmount: 8450000.00,
        budgetLimit: 8500000.00,
        q1Ppmp: 3500000.00,
        q2Ppmp: 2500000.00,
        q3Ppmp: 1500000.00,
        q4Ppmp: 950000.00,
        isAgriMooe: true,
      );

      // Other Supplies and Materials Expenses
      final otherSuppliesLine = BudgetLine(
        id: 'other-supplies-2026',
        accountCode: '5-02-03-990',
        fundSource: 'Agri MOOE',
        objectOfExpenditure: 'Other Supplies and Materials Expenses',
        approvedAmount: 2000000.00,
        currentBalance: 2000000.00,
        ppmpAmount: 1980000.00,
        budgetLimit: 2000000.00,
        q1Ppmp: 500000.00,
        q2Ppmp: 500000.00,
        q3Ppmp: 500000.00,
        q4Ppmp: 480000.00,
        isAgriMooe: true,
      );

      // Travelling Expenses - Local
      final travellingLine = BudgetLine(
        id: 'travelling-local-2026',
        accountCode: '5-02-01-010',
        fundSource: 'Agri MOOE',
        objectOfExpenditure: 'Travelling Expenses - Local',
        approvedAmount: 400000.00,
        currentBalance: 400000.00,
        ppmpAmount: 400000.00,
        budgetLimit: 400000.00,
        q1Ppmp: 100000.00,
        q2Ppmp: 100000.00,
        q3Ppmp: 100000.00,
        q4Ppmp: 100000.00,
        isAgriMooe: true,
      );

      // Prizes
      final prizesLine = BudgetLine(
        id: 'prizes-2026',
        accountCode: '5-02-06-020',
        fundSource: 'Agri MOOE',
        objectOfExpenditure: 'Prizes',
        approvedAmount: 150000.00,
        currentBalance: 150000.00,
        ppmpAmount: 150000.00,
        budgetLimit: 150000.00,
        q1Ppmp: 0.0,
        q2Ppmp: 50000.00,
        q3Ppmp: 50000.00,
        q4Ppmp: 50000.00,
        isAgriMooe: true,
      );

      // 20% EDF - Agricultural Infrastructure
      final edfLine = BudgetLine(
        id: 'edf-agri-infra-2026',
        accountCode: '1-07-04-990',
        fundSource: '20% EDF',
        objectOfExpenditure: 'Agricultural Infrastructure Projects',
        approvedAmount: 15000000.00,
        currentBalance: 15000000.00,
        ppmpAmount: 15000000.00,
        budgetLimit: 15000000.00,
        q1Ppmp: 5000000.00,
        q2Ppmp: 5000000.00,
        q3Ppmp: 5000000.00,
        q4Ppmp: 0.0,
        isAgriMooe: false,
        isCMO: false,
      );

      // CMO Special Project Fund
      final cmoLine = BudgetLine(
        id: 'cmo-special-2026',
        accountCode: 'CMO-2026',
        fundSource: 'City Mayor\'s Office',
        objectOfExpenditure: 'Special Agricultural Projects',
        approvedAmount: 5000000.00,
        currentBalance: 5000000.00,
        ppmpAmount: 5000000.00,
        budgetLimit: 5000000.00,
        isAgriMooe: false,
        isCMO: true,
      );

      await fbService.updateBudgetLine(trainingLine);
      await fbService.updateBudgetLine(agriSuppliesLine);
      await fbService.updateBudgetLine(otherSuppliesLine);
      await fbService.updateBudgetLine(travellingLine);
      await fbService.updateBudgetLine(prizesLine);
      await fbService.updateBudgetLine(edfLine);
      await fbService.updateBudgetLine(cmoLine);
      debugPrint('2026 Budget Lines initialized (including CMO).');
    } catch (e) {
      debugPrint('Error initializing 2026 budgets: $e');
    }
  }

  static Future<void> initialize2026Expenditures(FirebaseService fbService) async {
    try {
      // Check if expenditures already exist
      final existing = await fbService.db.collection('expenditures').limit(1).get();
      if (existing.docs.isNotEmpty) return;

      final sampleExpenditures = [
        Expenditure(
          id: '',
          activityId: 'sample-act-1',
          activityName: 'Hybrid Rice Techno Demo Launching',
          sector: 'Crop Section',
          prNumber: '2026-01-001',
          poNumber: 'PO-2026-001',
          poStatus: 'Delivered',
          amount: 15000.00,
          fundSource: 'Agri MOOE',
          objectOfExpenditure: 'Trainings and Seminar Expenses',
          timestamp: DateTime.now(),
        ),
        Expenditure(
          id: '',
          activityId: 'sample-act-2',
          activityName: 'FFS Corn Graduation',
          sector: 'Crop Section',
          prNumber: '2026-01-002',
          amount: 8500.00,
          fundSource: 'Agri MOOE',
          objectOfExpenditure: 'Trainings and Seminar Expenses',
          timestamp: DateTime.now(),
        ),
        Expenditure(
          id: '',
          activityId: 'sample-act-3',
          activityName: 'Rice Seeds Distribution',
          sector: 'Crop Section',
          prNumber: '2026-02-015',
          poNumber: 'PO-2026-045',
          poStatus: 'Pending',
          amount: 1250000.00,
          fundSource: 'Agri MOOE',
          objectOfExpenditure: 'Agricultural and Marine Supplies Expenses',
          timestamp: DateTime.now(),
        ),
      ];

      for (var exp in sampleExpenditures) {
        await fbService.addExpenditure(exp);
      }
      debugPrint('2026 Sample Expenditures initialized.');
    } catch (e) {
      debugPrint('Error initializing 2026 expenditures: $e');
    }
  }

  static Future<void> initialize2026Programs(FirebaseService fbService) async {
    try {
      final programs = [
        Program(id: 'rice', name: 'Rice Program', totalAllocation: 2500000, currentPpmpBalance: 2500000, fiscalYear: '2026'),
        Program(id: 'corn', name: 'Corn Program', totalAllocation: 1500000, currentPpmpBalance: 1500000, fiscalYear: '2026'),
        Program(id: 'hvcdp', name: 'HVCDP Program', totalAllocation: 2000000, currentPpmpBalance: 2000000, fiscalYear: '2026'),
        Program(id: 'organic', name: 'Organic Program', totalAllocation: 1000000, currentPpmpBalance: 1000000, fiscalYear: '2026'),
        Program(id: 'inland_fisheries', name: 'Inland Fisheries Program', totalAllocation: 1200000, currentPpmpBalance: 1200000, fiscalYear: '2026'),
        Program(id: 'admin', name: 'Admin Program', totalAllocation: 3000000, currentPpmpBalance: 3000000, fiscalYear: '2026'),
      ];

      for (var program in programs) {
        // Check if exists
        final doc = await fbService.db.collection('programs').doc(program.id).get();
        if (!doc.exists) {
          await fbService.updateProgram(program);
        }
      }
      debugPrint('2026 Programs initialized.');
    } catch (e) {
      debugPrint('Error initializing 2026 programs: $e');
    }
  }
}
