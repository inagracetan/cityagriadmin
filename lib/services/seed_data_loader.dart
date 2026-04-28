import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import 'firebase_service.dart';

class SeedDataLoader {
  static Future<void> load(FirebaseService fbService) async {
    try {
      final file = File('seed_data.json');
      if (!file.existsSync()) {
        debugPrint('seed_data.json not found');
        return;
      }
      final jsonStr = await file.readAsString();
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
      // It's safer to clear existing or use addActivity if batch is not available
      // But assuming batchAddActivities exists and works.
      await fbService.batchAddActivities(activities);
      debugPrint('Import successful!');
    } catch (e) {
      debugPrint('Error loading seed data: $e');
    }
  }
}
