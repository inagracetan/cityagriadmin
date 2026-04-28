import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity.dart';
import '../models/user_model.dart';
import '../models/pr_log.dart';

class FirebaseService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Stream all activities for Admin Master Table
  Stream<List<Activity>> streamActivities({
    String? sector,
    String? status,
    String? responsiblePerson,
  }) {
    Query<Map<String, dynamic>> query = db.collection('activities');
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
        .collection('activities')
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
        .collection('activities')
        .doc(activityId)
        .collection('pr_logs')
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
        .collection('activities')
        .doc(log.activityId)
        .collection('pr_logs')
        .add(log.toFirestore());
  }

  // Add a new activity
  Future<String> addActivity(Activity activity) async {
    final docRef = await db
        .collection('activities')
        .add(activity.toFirestore());
    return docRef.id;
  }

  // Batch add activities (chunked by 250 because each activity adds 2 ops if it has expenditure)
  Future<void> batchAddActivities(List<Activity> activities) async {
    for (var i = 0; i < activities.length; i += 250) {
      final end = (i + 250 < activities.length) ? i + 250 : activities.length;
      final chunk = activities.sublist(i, end);
      final batch = db.batch();
      for (var activity in chunk) {
        final docRef = db.collection('activities').doc();
        batch.set(docRef, activity.toFirestore());
      }
      await batch.commit();
    }
  }

  // Update an existing activity
  Future<void> updateActivity(Activity activity) async {
    await db
        .collection('activities')
        .doc(activity.id)
        .update(activity.toFirestore());
  }

  // Delete an activity + all its transactions sub-collection
  Future<void> deleteActivity(String activityId) async {
    final batch = db.batch();

    // Delete all PR logs first
    final prLogs = await db
        .collection('activities')
        .doc(activityId)
        .collection('pr_logs')
        .get();
    for (final doc in prLogs.docs) {
      batch.delete(doc.reference);
    }

    // Delete the activity itself
    batch.delete(db.collection('activities').doc(activityId));
    await batch.commit();
  }

  // Get a list of all staff names
  Future<List<String>> getAvailableStaff() async {
    final snapshot = await db.collection('users').get();
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
        .collection('users')
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
        .collection('activities')
        .where('activity_name', isEqualTo: name)
        .where('sector', isEqualTo: sector)
        .where('target_date', isEqualTo: targetDate)
        .get();
        
    if (excludeId != null) {
      return query.docs.any((doc) => doc.id != excludeId);
    }
    return query.docs.isNotEmpty;
  }
}
