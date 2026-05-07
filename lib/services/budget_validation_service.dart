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
      if (activity.accountCode == accountCode) {
        total += activity.ppmpAmount;
      }
      // Also check breakdown items if they have their own account codes
      for (var item in activity.breakdown) {
        if (item.accountCode == accountCode) {
          total += item.amount;
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
    
    return ppmpTotal > budgetLine.proposedExpenditure;
  }

  /// Summary of status/alerts for an activity
  static Map<String, dynamic> getActivityAlerts(Activity activity, List<Activity> allActivities, List<BudgetLine> budgetLines) {
    final now = DateTime.now();
    return {
      'noBudget': hasNoBudget(activity, budgetLines),
      'overObligated': isOverObligated(activity),
      'timelineVariance': hasTimelineVariance(activity, now),
      'ceilingViolation': activity.accountCode != null && activity.accountCode!.isNotEmpty 
          ? exceedsBudgetCeiling(activity.accountCode!, allActivities, budgetLines)
          : false,
    };
  }
}

