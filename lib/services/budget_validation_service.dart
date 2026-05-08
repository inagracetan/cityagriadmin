import '../models/activity.dart';
import '../models/budget_line.dart';
import '../core/constants.dart';

class BudgetValidationService {
  /// Check for "No Budget" Flag: Immediately flag any activity or item that has
  /// no corresponding appropriation in the Proposed Budget.
  static bool hasNoBudget(Activity activity, List<BudgetLine> budgetLines) {
    if (activity.accountCode == null || activity.accountCode!.isEmpty) {
      return true;
    }
    
    // Check if any budget line matches the account code and has appropriation > 0
    final matches = budgetLines.where((bl) => bl.accountCode == activity.accountCode);
    if (matches.isEmpty) return true;
    
    return matches.every((bl) => bl.appropriation <= 0);
  }

  /// Check for Over-Obligation Warning: Trigger a warning if the PR Amount
  /// exceeds the Approved Budget for that specific program.
  static bool isOverObligated(Activity activity) {
    return activity.prAmount > activity.approvedBudget;
  }

  /// Check for Timeline Variance: Alert users if an item scheduled for "Jan-March"
  /// in the PPMP has no PR status by the end of Q1.
  static bool hasTimelineVariance(Activity activity, DateTime now) {
    if (activity.quarter == 'Q1') {
      // Q1 ends March 31. If today is April 1 or later of the same year or later year.
      if (now.year > SystemConfig.nextFiscalYear || (now.year == SystemConfig.nextFiscalYear && now.month > 3)) {
        final status = activity.status.toLowerCase();
        // If status is still in early stages
        return status == 'planned' || status == 'pr preparation';
      }
    }
    return false;
  }

  /// Functional Constraint: Budget Ceiling
  /// The sum of all TOTAL AMOUNT entries in the PPMP for a specific account code
  /// must not exceed the PROPOSED EXPENDITURES for ${SystemConfig.nextFiscalYearStr} for that same code.
  static double getAccountCodePPMPTotal(String accountCode, List<Activity> allActivities) {
    double total = 0;
    for (var activity in allActivities) {
      // If activity has a breakdown, only sum the matching breakdown items
      if (activity.breakdown.isNotEmpty) {
        for (var item in activity.breakdown) {
          if (item.accountCode == accountCode) {
            total += item.amount;
          }
        }
      } else {
        // If no breakdown, use the top-level account code
        if (activity.accountCode == accountCode) {
          total += activity.ppmpAmount;
        }
      }
    }
    return total;
  }

  static bool exceedsBudgetCeiling(String accountCode, List<Activity> allActivities, List<BudgetLine> budgetLines) {
    final ppmpTotal = getAccountCodePPMPTotal(accountCode, allActivities);
    final budgetLine = budgetLines.firstWhere(
      (bl) => bl.accountCode == accountCode,
      orElse: () => BudgetLine(id: '', accountCode: accountCode, fundSource: '', objectOfExpenditure: ''),
    );
    
    if (budgetLine.id.isEmpty) return false; // Or should we flag it?
    
    return ppmpTotal > budgetLine.appropriation;
  }

  /// Summary of status/alerts for an activity
  static Map<String, dynamic> getActivityAlerts(Activity activity, List<Activity> allActivities, List<BudgetLine> budgetLines) {
    final now = DateTime.now();
    return {
      'noBudget': hasNoBudget(activity, budgetLines) || needsNoBudgetFlag(activity.effectivePRAmount, activity.prBalanceCalculated + activity.effectivePRAmount),
      'overObligated': isOverObligated(activity),
      'timelineVariance': hasTimelineVariance(activity, now),
      'ceilingViolation': activity.accountCode != null && activity.accountCode!.isNotEmpty 
          ? exceedsBudgetCeiling(activity.accountCode!, allActivities, budgetLines)
          : false,
      'supplementalPPMP': needsSupplementalPPMP(activity.effectivePOAmount, activity.effectivePRAmount),
    };
  }

  /// ── Validation Rules (Hard Stops) ──────────────────────────────────
  
  /// If Requested PR > Remaining PR Balance, Then set Status = "No Budget"
  static bool needsNoBudgetFlag(double requestedPRAmount, double remainingPRBalance) {
    if (remainingPRBalance <= 0) return true;
    return requestedPRAmount > remainingPRBalance;
  }

  /// If PO Amount > PR Amount, Then flag for "Supplemental PPMP"
  static bool needsSupplementalPPMP(double poAmount, double prAmount) {
    if (prAmount <= 0) return false;
    return poAmount > prAmount;
  }

  /// ── Summary Consolidation Logic ────────────────────────────────────
  
  static Map<String, double> getConsolidatedSummary(List<BudgetLine> allBudgetLines) {
    double totalAppropriation = 0;
    double totalObligated = 0;
    double totalDisbursed = 0;
    
    // Group by Object of Expenditure to handle Main vs Sub deduplication
    final Map<String, List<BudgetLine>> grouped = {};
    for (var bl in allBudgetLines) {
      grouped.putIfAbsent(bl.objectOfExpenditure, () => []).add(bl);
    }

    for (var categoryLines in grouped.values) {
      final mainEntry = categoryLines.firstWhere(
        (l) => l.subCategory == l.objectOfExpenditure,
        orElse: () => categoryLines.first,
      );
      final hasMainOverride = mainEntry.subCategory == mainEntry.objectOfExpenditure && mainEntry.proposedBudget > 0;
      final otherLines = categoryLines.where((l) => l.subCategory != l.objectOfExpenditure).toList();

      if (hasMainOverride) {
        // Use the Main entry as the "inputted as is" total for the category
        totalAppropriation += mainEntry.appropriation;
        totalObligated += mainEntry.prAmount;
        totalDisbursed += mainEntry.poAmount;
      } else {
        // Otherwise, sum the sub-categories, excluding the Main placeholder if others exist
        final actualSubLines = otherLines.isNotEmpty ? otherLines : [mainEntry];
        for (var bl in actualSubLines) {
          totalAppropriation += bl.appropriation;
          totalObligated += bl.prAmount;
          totalDisbursed += bl.poAmount;
        }
      }
    }
    
    double utilizationRate = totalAppropriation > 0 ? (totalObligated / totalAppropriation) * 100 : 0;
    double unobligatedBalance = totalAppropriation - totalObligated;
    
    return {
      'totalAppropriation': totalAppropriation,
      'totalObligated': totalObligated,
      'totalDisbursed': totalDisbursed,
      'utilizationRate': utilizationRate,
      'unobligatedBalance': unobligatedBalance,
    };
  }
}

