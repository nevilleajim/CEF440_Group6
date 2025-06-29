import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static Future<void> resetDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'qoe_data.db');
      await deleteDatabase(path);
      debugPrint('✅ Database reset successfully');
    } catch (e) {
      debugPrint('❌ Error resetting database: $e');
    }
  }
  
  static Future<void> checkAndFixDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'qoe_data.db');
      
      // Open database to check schema
      final db = await openDatabase(path);
      
      // Check if tables exist
      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      var tableNames = tables.map((t) => t['name'] as String).toList();
      
      if (!tableNames.contains('network_metrics') || !tableNames.contains('feedback_data')) {
        debugPrint('⚠️ Missing tables, resetting database...');
        await db.close();
        await resetDatabase();
        return;
      }
      
      // Check columns in network_metrics
      try {
        var networkMetricsInfo = await db.rawQuery('PRAGMA table_info(network_metrics)');
        var networkMetricsColumns = networkMetricsInfo.map((c) => c['name'] as String).toList();
        
        if (!networkMetricsColumns.contains('isSynced')) {
          debugPrint('⚠️ Missing isSynced column in network_metrics, resetting database...');
          await db.close();
          await resetDatabase();
          return;
        }
      } catch (e) {
        debugPrint('❌ Error checking network_metrics schema: $e');
        await db.close();
        await resetDatabase();
        return;
      }
      
      // Check columns in feedback_data
      try {
        var feedbackDataInfo = await db.rawQuery('PRAGMA table_info(feedback_data)');
        var feedbackDataColumns = feedbackDataInfo.map((c) => c['name'] as String).toList();
        
        if (!feedbackDataColumns.contains('isSynced') || 
            !feedbackDataColumns.contains('city') || 
            !feedbackDataColumns.contains('country')) {
          debugPrint('⚠️ Missing columns in feedback_data, resetting database...');
          await db.close();
          await resetDatabase();
          return;
        }
      } catch (e) {
        debugPrint('❌ Error checking feedback_data schema: $e');
        await db.close();
        await resetDatabase();
        return;
      }
      
      await db.close();
      debugPrint('✅ Database schema is valid');
    } catch (e) {
      debugPrint('❌ Error checking database: $e');
      await resetDatabase();
    }
  }
}
