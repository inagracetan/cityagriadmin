class AppConstants {
  static const String appTitle = 'AgriWork & Financial Planning System (AWFPS)';

  // Sectors
  static const List<String> sectors = [
    'Administrative Support Services Unit',
    'Agriculture Logistics Section',
    'Crop Section',
    'Inland Fisheries Section',
    'Institutional Development Section',
    'Integrated Agricultural Laboratory',
    'Monitoring and Evaluation Section',
    'Project Development Section',
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

  // Years
  static const List<String> years = [
    '2024',
    '2025',
    '2026',
    '2027',
    '2028',
    '2029',
    '2030',
  ];

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

  // Sectional Performance Targets (2026 facilitated PPAs)
  static const Map<String, int> sectorTargets = {
    'Crop Section': 35,
    'Inland Fisheries Section': 5,
    'Institutional Development Section': 23,
    'Monitoring and Evaluation Section': 11, // PMED
  };

}

