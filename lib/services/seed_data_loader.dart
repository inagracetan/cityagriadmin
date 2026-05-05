import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import 'firebase_service.dart';
import 'project_initialization_service.dart';

class SeedDataLoader {
  static Future<void> load(FirebaseService fbService, {bool force = false}) async {
    try {
      if (!force) {
        // Check if already seeded (simple check: if any activities exist, skip auto-seed)
        final existing = await fbService.db.collection('activities').limit(1).get();
        if (existing.docs.isNotEmpty) {
          debugPrint('Activities already exist. Skipping auto-seed.');
          return;
        }
      } else {
        debugPrint('Forced seed requested. Clearing existing activities and expenditures...');
        
        // Clear activities
        final activities = await fbService.db.collection('activities').get();
        for (var doc in activities.docs) {
          await doc.reference.delete();
        }

        // Clear expenditures
        final expenditures = await fbService.db.collection('expenditures').get();
        for (var doc in expenditures.docs) {
          await doc.reference.delete();
        }

        // Clear budget lines
        final budgetLines = await fbService.db.collection('budget_lines').get();
        for (var doc in budgetLines.docs) {
          await doc.reference.delete();
        }
        
        // Also re-initialize the 2026 data (budgets, targets, expenditures) if forced
        await ProjectInitializationService.initialize2026Targets(fbService);
      }

      final jsonStr = await rootBundle.loadString('assets/seed_data.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
      final List<dynamic> data = jsonMap['activities'] ?? [];

      List<Activity> activities = [];
      for (var item in data) {
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
        // Activity.fromFirestore handles snake_case keys correctly
        final act = Activity.fromFirestore(
            itemMap,
            itemMap['id']?.toString() ?? '',
        );
        activities.add(act);
      }

      debugPrint('Importing ${activities.length} activities...');
      await fbService.batchAddActivities(activities);
      debugPrint('Import successful!');
    } catch (e) {
      debugPrint('Error loading seed data: $e');
      rethrow;
    }
  }
}
