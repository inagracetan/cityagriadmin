class AppConstants {
  static const String appTitle = 'AgriWork & Financial Planning System (AWFPS)';

  // Firestore Collections
  static const String colActivities = 'activities';
  static const String colBudgetLines = 'budget_lines';
  static const String colExpenditures = 'expenditures';
  static const String colPrograms = 'programs';
  static const String colProcurements = 'procurements';
  static const String colNotifications = 'notifications';
  static const String colSystemLogs = 'system_logs';
  static const String colUsers = 'users';
  static const String colCmoLedger = 'cmo_ledger';
  static const String colPrLogs = 'pr_logs';

  // Sectors
  // Sector Names
  static const String sectorAdmin = 'Administrative Support Services Unit';
  static const String sectorLogistics = 'Agriculture Logistics Section';
  static const String sectorCrop = 'Crop Section';
  static const String sectorFisheries = 'Inland Fisheries Section';
  static const String sectorInstitutional = 'Institutional Development Section';
  static const String sectorLab = 'Integrated Agricultural Laboratory';
  static const String sectorME = 'Monitoring and Evaluation Section';
  static const String sectorProject = 'Project Development Section';

  // Sectors List
  static const List<String> sectors = [
    sectorAdmin,
    sectorLogistics,
    sectorCrop,
    sectorFisheries,
    sectorInstitutional,
    sectorLab,
    sectorME,
    sectorProject,
  ];

  // Sub-sectors
  static const List<String> subSectors = [
    'Corn',
    'HVCDP',
    'Organic Program',
    'Rice',
  ];

  // Funding Sources
  static const List<String> fundingSources = [
    '20% DF',
    'Agri MOOE',
    'CPOC',
    'Capital Outlay',
    'GAD',
    'Mayors Fund',
    'Other',
  ];

  // Months
  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // Years (Dynamically generated)
  static List<String> get years {
    final currentYear = DateTime.now().year;
    return List.generate(11, (index) => (currentYear - 2 + index).toString());
  }

  // Object of Expenditure
  static const List<String> objectsOfExpenditure = [
    'Administrative Support Services Unit Appropriation',
    'Agriculture Logistics Section Appropriation',
    'Communication Expenses',
    'Corn Appropriation',
    'Crop Section Appropriation',
    'Fuel/Oil Expenses',
    'HVCDP Appropriation',
    'Inland Fisheries Section Appropriation',
    'Institutional Development Section Appropriation',
    'Integrated Agricultural Laboratory Appropriation',
    'Meetings Expenses',
    'Monitoring and Evaluation Section Appropriation',
    'Office Supplies Expenses',
    'Organic Program Appropriation',
    'Other-MOE Expenses',
    'Personnel Development Expenses',
    'Project Development Section Appropriation',
    'Repair/Maintenance Expenses',
    'Rice Appropriation',
    'Trainings and Seminar Expenses',
    'Travelling Expenses',
    'Other',
  ];

  // Activity Statuses (New Workflow Sequence)
  static const List<String> activityStatuses = [
    statusPRPreparation,
    statusBACProcessing,
    statusObreAbstractSig,
    statusCompleted,
    // Other statuses for backward compatibility or special cases
    statusPlanned,
    statusNoBudget,
    statusNoBudgetYet,
    statusPRPrepared,
    statusBACApprovedOBRE,
    statusBACBidding,
    statusBACShopping,
    statusBacForPRNumber,
    statusBacOffice,
    statusObligated,
    statusIAR,
    statusRecanvas,
  ];

  // Procurement Statuses (For PR Logs)
  static const List<String> prStatuses = [
    statusPRStage,
    statusAbstractSigned,
    statusPOStage,
    statusObreAbstractSig,
    statusPOSigned,
    statusDelivered,
    statusCompleted,
    statusPending,
    statusPaid,
  ];

  static const String statusPlanned = 'Planned';
  static const String statusPRStage = 'PR Stage';
  static const String statusAbstractSigned = 'Abstract Signed';
  static const String statusPOStage = 'PO Stage';
  static const String statusObreAbstractSig = 'Obre & Abstract Sig';
  static const String statusPOSigned = 'PO Signed';
  static const String statusDelivered = 'Delivered';
  static const String statusCompleted = 'Completed';
  
  // Legacy or specialized statuses (keeping for compatibility)
  static const String statusPRPreparation = 'PR Preparation';
  static const String statusBACProcessing = 'BAC Processing';
  static const String statusPOPrepared = 'PO Prepared';
  static const String statusObligated = 'Obligated';
  static const String statusIAR = 'IAR';
  static const String statusNoBudget = 'No Budget';
  static const String statusNoBudgetYet = 'No budget yet';
  static const String statusBACShopping = 'BAC Shopping';
  static const String statusBacOffice = 'Bac Office';
  static const String statusBacForPRNumber = 'BAC-FOR PR NUMBER';
  static const String statusBACBidding = 'BAC-Bidding';
  static const String statusRecanvas = 'Recanvas';
  static const String statusPRPrepared = 'PR Prepared';
  static const String statusBACApprovedOBRE = 'BAC Approved/OBRE';
  static const String statusDraft = 'Draft';
  static const String statusPaid = 'Paid';
  static const String statusPending = 'Pending';

  // Common Suppliers
  static const List<String> commonSuppliers = [
    'A & L Pharma',
    'Buzz Stop',
    'D Apiapry goods Trading',
    "D' Apiary Consumer Goods Services",
    'Darryl Water Refilling Station',
    'Execom Computer Sales & Services',
    "Maxy's Catering Services",
    'Netwayer I.T. Solutions',
    'Print All',
    "R'Jays Lumber & Construction Supply",
    'Robertos',
    'Rysha Enterprises',
  ];

  // Staff List
  static const List<String> staffList = [
    'Admin',
    'Ina Tan',
    'Ina',
  ];

  // Common Units
  static const List<String> commonUnits = [
    'pcs',
    'sets',
    'units',
    'liters',
    'bottles',
    'bags',
    'packs',
    'boxes',
    'rolls',
    'meters',
    'grams',
    'kilograms',
    'meetings',
    'sessions',
    'pax',
    'lot',
  ];

  static List<String> getFilteredObjectsOfExpenditure(
    String? sector, {
    String? subSector,
    String? fundingSource,
  }) {
    // Non-section-specific items (standard expenses)
    final standardItems = objectsOfExpenditure
        .where((e) => !e.endsWith(' Appropriation'))
        .toList();

    // Appropriation are specific to the selected sector/sub-sector
    if (sector != null && sector != 'Other') {
      // If we have a specific subSector for the Crop Section, use that
      final specificApprop =
          (sector == 'Crop Section' &&
                  subSector != null &&
                  subSector != 'Other')
              ? '$subSector Appropriation'
              : '$sector Appropriation';

      // If the specific sector/sub-sector appropriation exists in our master list,
      // place it at the top for easy selection.
      if (objectsOfExpenditure.contains(specificApprop)) {
        return [specificApprop, ...standardItems];
      }
    }

    return standardItems;
  }

  static String abbreviate(String name) {
    if (name.isEmpty) return '';
    final n = name.trim();
    if (n == 'Administrative Support Services Unit') return 'ASSU';
    if (n == 'Crop Section') return 'CS';
    if (n == 'Inland Fisheries Section') return 'IFS';
    if (n == 'Institutional Development Section') return 'IDS';
    if (n == 'Agriculture Logistics Section') return 'ALS';
    if (n == 'Project Development Section') return 'PDS';
    if (n == 'Monitoring and Evaluation Section') return 'M&E';
    if (n == 'Integrated Agricultural Laboratory') return 'IAL';
    if (n == 'Agri MOOE') return 'AM';
    if (n == 'Special Funds') return 'SF';
    if (n == 'Capital Outlay') return 'CO';
    if (n == 'Purchase Request') return 'PR';
    if (n == 'Purchase Order') return 'PO';
    if (n == '20% DF') return '20DF';
    if (n == 'Inventory Acceptance Report') return 'IAR';
    if (n.length <= 5) return n;

    // Default to initials
    return n
        .split(RegExp(r'[\s\-/]'))
        .where((e) =>
            e.isNotEmpty &&
            !['and', 'or', 'for', 'the', 'of'].contains(e.toLowerCase()))
        .map((e) => e[0])
        .join()
        .toUpperCase();
  }

  // Sectional Performance Targets (facilitated PPAs)
  static const Map<String, int> sectorTargets = {
    'Crop Section': 35,
    'Inland Fisheries Section': 5,
    'Institutional Development Section': 23,
    'Monitoring and Evaluation Section': 11, // PMED
  };

}

class SystemConfig {
  static int get currentFiscalYear => DateTime.now().year;
  static int get nextFiscalYear => currentFiscalYear + 1;
  
  static String get currentFiscalYearStr => currentFiscalYear.toString();
  static String get nextFiscalYearStr => nextFiscalYear.toString();
  
  static const String adminRole = 'admin';
  static const String staffRole = 'staff';
  static const String programHeadRole = 'program_head';
}


