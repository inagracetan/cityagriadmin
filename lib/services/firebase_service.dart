import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/activity.dart';
import '../models/budget_line.dart';
import '../models/expenditure.dart';
import '../models/notification_model.dart';
import '../models/pr_log.dart';
import '../models/procurement.dart';
import '../models/program.dart';
import '../models/user_model.dart';


class FirebaseService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ── Budget Lines (Layer A) ──────────────────────────────────────────

  Stream<List<BudgetLine>> streamBudgetLines() {
    return db.collection(AppConstants.colBudgetLines).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => BudgetLine.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateBudgetLine(BudgetLine line) async {
    await db.collection(AppConstants.colBudgetLines).doc(line.id).set(line.toFirestore());
  }

  Future<void> deleteBudgetLine(String id) async {
    await db.collection(AppConstants.colBudgetLines).doc(id).delete();
  }

  // ── Expenditures (Layer B) ───────────────────────────────────────────

  Stream<List<Expenditure>> streamExpenditures({String? sector, String? prNumber}) {
    Query<Map<String, dynamic>> query = db.collection(AppConstants.colExpenditures);
    if (sector != null && sector.isNotEmpty) {
      query = query.where('sector', isEqualTo: sector);
    }
    if (prNumber != null && prNumber.isNotEmpty) {
      query = query.where('pr_number', isEqualTo: prNumber);
    }
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Expenditure.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<String> addExpenditure(Expenditure expenditure) async {
    // 1. Add expenditure
    final docRef = await db.collection(AppConstants.colExpenditures).add(expenditure.toFirestore());
    
    // 2. Update Budget Line balance (Deduct)
    if (expenditure.fundSource != null && expenditure.objectOfExpenditure != null) {
      await _adjustBudgetBalance(
        expenditure.fundSource!,
        expenditure.objectOfExpenditure!,
        -expenditure.amount,
      );
    }
    
    
    // Trigger notification
    await addNotification(SystemNotification(
      id: '',
      title: 'New Expenditure Recorded',
      message: 'An expenditure for "${expenditure.activityName}" has been recorded against the allocated budget.',
      timestamp: DateTime.now(),
      type: NotificationType.budget,
      relatedId: docRef.id,
    ));

    return docRef.id;
  }

  Future<void> updateExpenditure(Expenditure expenditure, double oldAmount) async {
    // 1. Update expenditure
    await db.collection(AppConstants.colExpenditures).doc(expenditure.id).update(expenditure.toFirestore());
    
    // 2. Adjust Budget Line balance if amount changed
    if (expenditure.amount != oldAmount) {
      if (expenditure.fundSource != null && expenditure.objectOfExpenditure != null) {
        await _adjustBudgetBalance(
          expenditure.fundSource!,
          expenditure.objectOfExpenditure!,
          oldAmount - expenditure.amount,
        );
      }
    }
  }

  Future<void> deleteExpenditure(Expenditure expenditure) async {
    // 1. Delete expenditure
    await db.collection(AppConstants.colExpenditures).doc(expenditure.id).delete();
    
    // 2. Restore Budget Line balance (Add back)
    if (expenditure.fundSource != null && expenditure.objectOfExpenditure != null) {
      await _adjustBudgetBalance(
        expenditure.fundSource!,
        expenditure.objectOfExpenditure!,
        expenditure.amount,
      );
    }
  }

  Future<void> _adjustBudgetBalance(String fs, String oe, double adjustment) async {
    final query = await db
        .collection(AppConstants.colBudgetLines)
        .where('fund_source', isEqualTo: fs)
        .where('object_of_expenditure', isEqualTo: oe)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final currentBalance = (doc.data()['current_balance'] ?? 0).toDouble();
      await doc.reference.update({'current_balance': currentBalance + adjustment});
    }
  }

  // ── CMO Budget (Layer C) ─────────────────────────────────────────────

  Future<void> adjustCMOBudget(double adjustment, String remarks) async {
    final query = await db.collection(AppConstants.colBudgetLines).where('is_cmo', isEqualTo: true).limit(1).get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final currentBalance = (doc.data()['current_balance'] ?? 0).toDouble();
      await doc.reference.update({'current_balance': currentBalance + adjustment});
      
      // Log adjustment? (Optional but good)
      await db.collection(AppConstants.colCmoLedger).add({
        'adjustment': adjustment,
        'remarks': remarks,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Activities ──────────────────────────────────────────────────────
  
  // Stream all activities for Admin Master Table
  Stream<List<Activity>> streamActivities({
    String? sector,
    String? status,
    String? responsiblePerson,
  }) {
    Query<Map<String, dynamic>> query = db.collection(AppConstants.colActivities);
    if (sector != null && sector.isNotEmpty) {
      query = query.where('sector', isEqualTo: sector);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    if (responsiblePerson != null && responsiblePerson.isNotEmpty) {
      query = query.where('responsible_person', isEqualTo: responsiblePerson);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Activity.fromFirestore(doc.data(), doc.id))
          .toList(),
    );
  }

  // Stream activities assigned to a specific staff
  Stream<List<Activity>> streamActivitiesForStaff(String staffName) {
    return db
        .collection(AppConstants.colActivities)
        .where('responsible_person', isEqualTo: staffName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Activity.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream PR logs for an activity
  Stream<List<PRLog>> streamPRLogs(String activityId) {
    return db
        .collection(AppConstants.colActivities)
        .doc(activityId)
        .collection(AppConstants.colPrLogs)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PRLog.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  // Add a PR log entry
  Future<void> addPRLog(PRLog log) async {
    await db
        .collection(AppConstants.colActivities)
        .doc(log.activityId)
        .collection(AppConstants.colPrLogs)
        .add(log.toFirestore());
  }

  // Add a new activity
  Future<String> addActivity(Activity activity) async {
    final docRef = await db
        .collection(AppConstants.colActivities)
        .add(activity.toFirestore());

    // Trigger notification
    await addNotification(SystemNotification(
      id: '',
      title: 'New Activity Created',
      message: 'Activity "${activity.activityName}" has been added to the system.',
      timestamp: DateTime.now(),
      type: NotificationType.success,
      relatedId: docRef.id,
    ));

    // Log the event
    await logEvent(
      type: 'activity',
      action: 'create',
      message: 'Created activity: ${activity.activityName}',
      metadata: {'activity_id': docRef.id},
    );

    // Sync budget lines to ensure ledger consistency
    await syncBudgetLinesWithActivities();

    return docRef.id;
  }

  // Batch add activities (chunked by 250 because each activity adds 2 ops if it has expenditure)
  Future<void> batchAddActivities(List<Activity> activities) async {
    for (var i = 0; i < activities.length; i += 250) {
      final end = (i + 250 < activities.length) ? i + 250 : activities.length;
      final chunk = activities.sublist(i, end);
      final batch = db.batch();
      for (var activity in chunk) {
        final docRef = db.collection(AppConstants.colActivities).doc();
        batch.set(docRef, activity.toFirestore());
      }
      await batch.commit();
    }
  }

  // Update an existing activity
  Future<void> updateActivity(Activity activity) async {
    // Validation: Prevent over-obligation if it's a critical item
    if (activity.isOverObligated && activity.isRodenticideWarning) {
      throw Exception('Over-obligation blocked: No budget remaining for critical Rice Program items.');
    }

    await db
        .collection(AppConstants.colActivities)
        .doc(activity.id)
        .update(activity.toFirestore());

    // Trigger notification
    await addNotification(SystemNotification(
      id: '',
      title: 'Activity Updated',
      message: 'Activity "${activity.activityName}" has been updated.',
      timestamp: DateTime.now(),
      type: NotificationType.info,
      relatedId: activity.id,
    ));

    // Log the event
    await logEvent(
      type: 'activity',
      action: 'update',
      message: 'Updated activity: ${activity.activityName}',
      metadata: {'activity_id': activity.id},
    );

    // Sync budget lines to ensure ledger consistency
    await syncBudgetLinesWithActivities();
  }

  // Update only the status of an activity
  Future<void> updateActivityStatus(String activityId, String newStatus) async {
    try {
      await db.collection(AppConstants.colActivities).doc(activityId).update({'status': newStatus});
      
      // Trigger notification
      await addNotification(SystemNotification(
        id: '',
        title: 'Status Updated',
        message: 'The status of an activity has been changed to $newStatus.',
        timestamp: DateTime.now(),
        type: NotificationType.info,
        relatedId: activityId,
      ));

      // Log the event
      await logEvent(
        type: 'activity',
        action: 'status_change',
        message: 'Changed status of activity $activityId to $newStatus',
        metadata: {'activity_id': activityId, 'new_status': newStatus},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Delete an activity + all its transactions sub-collection
  Future<void> deleteActivity(String activityId) async {
    final batch = db.batch();

    // Delete all PR logs first
    final prLogs = await db
        .collection(AppConstants.colActivities)
        .doc(activityId)
        .collection(AppConstants.colPrLogs)
        .get();
    for (final doc in prLogs.docs) {
      batch.delete(doc.reference);
    }

    // Delete the activity itself
    batch.delete(db.collection(AppConstants.colActivities).doc(activityId));
    await batch.commit();
  }

  // Get a list of all staff names
  Future<List<String>> getAvailableStaff() async {
    final snapshot = await db.collection(AppConstants.colUsers).get();
    return snapshot.docs
        .map((doc) => (doc.get('name') as String).trim())
        .where((name) => name.isNotEmpty)
        .toSet() // Ensure unique names
        .toList()
      ..sort();
  }

  // Stream all users
  Stream<List<UserModel>> streamUsers() {
    return db
        .collection(AppConstants.colUsers)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }
  // Check for duplicate activity
  Future<bool> checkDuplicateActivity(
      String name, String sector, String targetDate, {String? excludeId}) async {
    final query = await db
        .collection(AppConstants.colActivities)
        .where('activity_name', isEqualTo: name)
        .where('sector', isEqualTo: sector)
        .where('target_date', isEqualTo: targetDate)
        .get();
        
    if (excludeId != null) {
      return query.docs.any((doc) => doc.id != excludeId);
    }
    return query.docs.isNotEmpty;
  }

  // ── Programs (WFP Entity) ───────────────────────────────────────────

  Stream<List<Program>> streamPrograms() {
    return db.collection(AppConstants.colPrograms).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Program.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateProgram(Program program) async {
    await db.collection(AppConstants.colPrograms).doc(program.id).set(program.toFirestore());
  }

  // ── Procurements (Procurement Entity) ────────────────────────────────

  Stream<List<Procurement>> streamProcurements(String programId) {
    return db
        .collection(AppConstants.colPrograms)
        .doc(programId)
        .collection(AppConstants.colProcurements)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Procurement.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  // searchable data table utilize collectionGroup
  Stream<List<Procurement>> streamAllProcurements() {
    return db
        .collectionGroup(AppConstants.colProcurements)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Procurement.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<String> addProcurement(Procurement procurement) async {
    // 1. Validate against Appropriation (Budget Ceiling)
    await validateAgainstAppropriation(
      procurement.fundSource,
      procurement.objectOfExpenditure,
      procurement.prAmount,
    );

    // 2. Add procurement
    final docRef = await db
        .collection(AppConstants.colPrograms)
        .doc(procurement.programId)
        .collection(AppConstants.colProcurements)
        .add(procurement.toFirestore());

    // 3. Deduct from Program Balance
    await _adjustProgramBalance(procurement.programId, -procurement.prAmount);

    
    // Trigger notification
    await addNotification(SystemNotification(
      id: '',
      title: 'New Procurement Added',
      message: 'Procurement PR "${procurement.prNumber}" has been added to program.',
      timestamp: DateTime.now(),
      type: NotificationType.activity,
      relatedId: docRef.id,
    ));

    // Sync budget lines to ensure ledger consistency
    await syncBudgetLinesWithActivities();

    return docRef.id;
  }

  Future<void> updateProcurement(Procurement procurement, double oldAmount) async {
    // 1. Update procurement
    await db
        .collection(AppConstants.colPrograms)
        .doc(procurement.programId)
        .collection(AppConstants.colProcurements)
        .doc(procurement.id)
        .update(procurement.toFirestore());

    // 2. Adjust Program balance if amount changed
    if (procurement.prAmount != oldAmount) {
      await _adjustProgramBalance(procurement.programId, oldAmount - procurement.prAmount);
    }

    // Sync budget lines to ensure ledger consistency
    await syncBudgetLinesWithActivities();
  }

  Future<void> deleteProcurement(Procurement procurement) async {
    await db
        .collection(AppConstants.colPrograms)
        .doc(procurement.programId)
        .collection(AppConstants.colProcurements)
        .doc(procurement.id)
        .delete();

    // Restore Program balance
    await _adjustProgramBalance(procurement.programId, procurement.prAmount);

    // Sync budget lines to ensure ledger consistency
    await syncBudgetLinesWithActivities();
  }

  Future<void> _adjustProgramBalance(String programId, double adjustment) async {
    final docRef = db.collection(AppConstants.colPrograms).doc(programId);
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final currentBalance = (snapshot.data()?['current_ppmp_balance'] ?? 0).toDouble();
        transaction.update(docRef, {'current_ppmp_balance': currentBalance + adjustment});
      }
    });
  }

  Future<void> validateAgainstAppropriation(String fs, String? oe, double amount) async {
    final query = await db
        .collection(AppConstants.colBudgetLines) // Using budget_lines as appropriations
        .where('fund_source', isEqualTo: fs)
        .where('object_of_expenditure', isEqualTo: oe)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final programmedAmount = (doc.data()['proposed_budget'] ?? doc.data()['proposed_amount'] ?? 0).toDouble();
      final currentSpent = (doc.data()['pr_amount'] ?? 0).toDouble(); // Assume this tracks total spent
      
      if (currentSpent + amount > programmedAmount) {
        throw Exception('Budget Exceeded: Remaining appropriation for "$oe" is ${programmedAmount - currentSpent}');
      }
    } else {
      // Optional: allow if no appropriation found, or throw
      // throw Exception('Appropriation not found for "$oe" under "$fs"');
    }
  }

  // ── Notifications ───────────────────────────────────────────────────

  Stream<List<SystemNotification>> streamNotifications({String? userId}) {
    Query<Map<String, dynamic>> query = db.collection(AppConstants.colNotifications);
    
    // Show user-specific OR global notifications
    if (userId != null) {
      query = query.where(Filter.or(
        Filter('user_id', isEqualTo: userId),
        Filter('user_id', isNull: true),
      ));
    } else {
      query = query.where('user_id', isNull: true);
    }
    
    return query.orderBy('timestamp', descending: true).limit(50).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => SystemNotification.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addNotification(SystemNotification notification) async {
    await db.collection(AppConstants.colNotifications).add(notification.toFirestore());
  }

  Future<void> markNotificationAsRead(String id) async {
    await db.collection(AppConstants.colNotifications).doc(id).update({'is_read': true});
  }

  Future<void> markAllNotificationsAsRead(String? userId) async {
    Query<Map<String, dynamic>> query = db.collection(AppConstants.colNotifications)
        .where('is_read', isEqualTo: false);
        
    if (userId != null) {
      // Mark user specific and global notifications as read
      // Note: In a real app, you might only want to mark user-specific as read 
      // or track 'read' status per user for global ones. 
      // For this system, we'll just mark whatever is in the view.
      final snapshot = await query.get();
      final batch = db.batch();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['user_id'] == userId || data['user_id'] == null) {
          batch.update(doc.reference, {'is_read': true});
        }
      }
      await batch.commit();
    } else {
      final snapshot = await query.where('user_id', isNull: true).get();
      final batch = db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    }
  }

  // ── System Logs ─────────────────────────────────────────────────────

  Future<void> logEvent({
    required String type,
    required String action,
    required String message,
    String? userId,
    String? userName,
    Map<String, dynamic>? metadata,
  }) async {
    await db.collection(AppConstants.colSystemLogs).add({
      'type': type,
      'action': action,
      'message': message,
      'user_id': userId,
      'user_name': userName,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSystemLogs() {
    return db.collection(AppConstants.colSystemLogs)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  /// Reconciles BudgetLine metrics (PPMP, PR, PO amounts) by aggregating all Activity records.
  /// This ensures that the Budget Ledger (Macro) always reflects the Transactional Data (Micro).
  Future<void> syncBudgetLinesWithActivities() async {
    try {
      // 1. Fetch all activities and budget lines
      final activitiesSnapshot = await db.collection(AppConstants.colActivities).get();
      final activities = activitiesSnapshot.docs.map((doc) => Activity.fromFirestore(doc.data(), doc.id)).toList();

      // NEW: Fetch all standalone procurements across all programs
      final procurementsSnapshot = await db.collectionGroup(AppConstants.colProcurements).get();
      final procurements = procurementsSnapshot.docs.map((doc) => Procurement.fromFirestore(doc.data(), doc.id)).toList();

      final budgetLinesSnapshot = await db.collection(AppConstants.colBudgetLines).get();
      final budgetLines = budgetLinesSnapshot.docs.map((doc) => BudgetLine.fromFirestore(doc.data(), doc.id)).toList();

      final batch = db.batch();
      int operationCount = 0;

      // 2. Aggregate values from Activities
      Map<String, double> ppmpByAccount = {};
      Map<String, double> prByAccount = {};
      Map<String, double> poByAccount = {};

      for (var activity in activities) {
        // If activity has a breakdown, distribute amounts by individual item account codes
        if (activity.breakdown.isNotEmpty) {
          double totalBreakdown = activity.totalBreakdownAmount;
          for (var item in activity.breakdown) {
            final ac = item.accountCode;
            if (ac == null || ac.isEmpty) continue;
            
            ppmpByAccount[ac] = (ppmpByAccount[ac] ?? 0) + item.amount;
            
            // Distribute PR/PO amounts proportionally to breakdown item amounts
            if (totalBreakdown > 0) {
              double ratio = item.amount / totalBreakdown;
              prByAccount[ac] = (prByAccount[ac] ?? 0) + (activity.effectivePRAmount * ratio);
              poByAccount[ac] = (poByAccount[ac] ?? 0) + (activity.effectivePOAmount * ratio);
            }
          }
        } else {
          // Fallback to top-level activity account code
          final ac = activity.accountCode;
          if (ac != null && ac.isNotEmpty) {
            ppmpByAccount[ac] = (ppmpByAccount[ac] ?? 0) + activity.ppmpAmount;
            prByAccount[ac] = (prByAccount[ac] ?? 0) + activity.effectivePRAmount;
            poByAccount[ac] = (poByAccount[ac] ?? 0) + activity.effectivePOAmount;
          }
        }
      }

      // 3. Aggregate values from standalone Procurements (linked by FS + OE)
      Map<String, double> prByFsOe = {};
      Map<String, double> poByFsOe = {};
      for (var proc in procurements) {
        final key = '${proc.fundSource}_${proc.objectOfExpenditure}';
        prByFsOe[key] = (prByFsOe[key] ?? 0) + proc.prAmount;
        poByFsOe[key] = (poByFsOe[key] ?? 0) + proc.poAmount;
      }

      // 4. Update each budget line
      for (var bl in budgetLines) {
        double totalPPMP = ppmpByAccount[bl.accountCode] ?? 0;
        double totalPR = prByAccount[bl.accountCode] ?? 0;
        double totalPO = poByAccount[bl.accountCode] ?? 0;

        // Add standalone procurements based on FS + OE matching
        final key = '${bl.fundSource}_${bl.objectOfExpenditure}';
        totalPR += prByFsOe[key] ?? 0;
        totalPO += poByFsOe[key] ?? 0;

        // Only update if values changed significantly
        if ((bl.ppmpAmount - totalPPMP).abs() > 0.01 || 
            (bl.prAmount - totalPR).abs() > 0.01 || 
            (bl.poAmount - totalPO).abs() > 0.01) {
          final updatedLine = bl.copyWith(
            ppmpAmount: totalPPMP,
            prAmount: totalPR,
            poAmount: totalPO,
            currentBalance: bl.appropriation - totalPR, // Unobligated Balance
          );
          
          batch.update(db.collection(AppConstants.colBudgetLines).doc(bl.id), updatedLine.toFirestore());
          operationCount++;

          if (operationCount >= 450) {
            await batch.commit();
            operationCount = 0;
          }
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }
      
      debugPrint('Budget Ledger Synced: $operationCount lines updated.');
    } catch (e) {
      debugPrint('Error syncing budget ledger: $e');
    }
  }
}



