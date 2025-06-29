import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/network_metrics.dart';
import '../models/feedback_data.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static Database? _database;
  static const int _currentVersion = 3;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabaseWithRetry();
    return _database!;
  }

  // More aggressive approach to database initialization
  Future<Database> _initDatabaseWithRetry() async {
    String path = join(await getDatabasesPath(), 'qoe_data.db');
    
    try {
      // First try normal initialization
      return await _normalInitDatabase(path);
    } catch (e) {
      debugPrint('❌ Normal database init failed: $e');
      
      // If that fails, try to delete and recreate the database
      try {
        debugPrint('🔄 Attempting database recovery...');
        await deleteDatabase(path);
        return await openDatabase(
          path,
          version: _currentVersion,
          onCreate: _createTables,
        );
      } catch (e) {
        debugPrint('❌ Database recovery failed: $e');
        
        // Last resort: create database in a new location
        try {
          String backupPath = join(await getDatabasesPath(), 'qoe_data_new.db');
          debugPrint('🆘 Creating database at new location: $backupPath');
          return await openDatabase(
            backupPath,
            version: _currentVersion,
            onCreate: _createTables,
          );
        } catch (e) {
          debugPrint('❌ All database recovery attempts failed: $e');
          rethrow;
        }
      }
    }
  }

  Future<Database> _normalInitDatabase(String path) async {
    return await openDatabase(
      path,
      version: _currentVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Verify schema on every open
        await _verifySchema(db);
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading database from v$oldVersion to v$newVersion');
    
    // Always verify and fix schema regardless of version
    await _verifySchema(db);
  }

  // Verify and fix schema if needed
  Future<void> _verifySchema(Database db) async {
    debugPrint('🔍 Verifying database schema...');
    
    try {
      // Check if tables exist
      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      var tableNames = tables.map((t) => t['name'] as String).toList();
      
      debugPrint('📋 Existing tables: $tableNames');
      
      if (!tableNames.contains('network_metrics')) {
        debugPrint('⚠️ network_metrics table missing, creating...');
        await _createNetworkMetricsTable(db);
      }
      
      if (!tableNames.contains('feedback_data')) {
        debugPrint('⚠️ feedback_data table missing, creating...');
        await _createFeedbackDataTable(db);
      }
      
      // Test table access
      try {
        await db.rawQuery('SELECT COUNT(*) FROM network_metrics');
        debugPrint('✅ network_metrics table accessible');
      } catch (e) {
        debugPrint('❌ network_metrics table not accessible: $e');
        await _createNetworkMetricsTable(db);
      }
      
      try {
        await db.rawQuery('SELECT COUNT(*) FROM feedback_data');
        debugPrint('✅ feedback_data table accessible');
      } catch (e) {
        debugPrint('❌ feedback_data table not accessible: $e');
        await _createFeedbackDataTable(db);
      }
      
      debugPrint('✅ Database schema verification complete');
    } catch (e) {
      debugPrint('❌ Schema verification failed: $e');
      // If verification fails, recreate tables
      await _recreateTablesWithBackup(db);
    }
  }

  Future<void> _recreateTablesWithBackup(Database db) async {
    debugPrint('🔄 Recreating tables with backup...');
    
    try {
      // Drop and recreate tables
      await db.execute('DROP TABLE IF EXISTS network_metrics');
      await db.execute('DROP TABLE IF EXISTS feedback_data');
      
      await _createTables(db, 0);
      
      debugPrint('✅ Tables recreated successfully');
    } catch (e) {
      debugPrint('❌ Failed to recreate tables: $e');
      // If recreation fails, create empty tables
      await _createTables(db, 0);
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await _createNetworkMetricsTable(db);
    await _createFeedbackDataTable(db);
  }

  Future<void> _createNetworkMetricsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS network_metrics(
        id TEXT PRIMARY KEY,
        timestamp INTEGER,
        networkType TEXT,
        carrier TEXT,
        signalStrength INTEGER,
        latitude REAL,
        longitude REAL,
        address TEXT,
        city TEXT,
        country TEXT,
        downloadSpeed REAL,
        uploadSpeed REAL,
        latency INTEGER,
        jitter REAL,
        packetLoss REAL,
        isSynced INTEGER DEFAULT 0
      )
    ''');
    debugPrint('✅ network_metrics table created/verified');
  }

  Future<void> _createFeedbackDataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS feedback_data(
        id TEXT PRIMARY KEY,
        timestamp INTEGER,
        overallSatisfaction INTEGER,
        responseTime INTEGER,
        usability INTEGER,
        comments TEXT,
        networkMetricsId TEXT,
        latitude REAL,
        longitude REAL,
        carrier TEXT,
        city TEXT,
        country TEXT,
        address TEXT,
        isSynced INTEGER DEFAULT 0
      )
    ''');
    debugPrint('✅ feedback_data table created/verified');
  }

  Future<void> clearAllLogs() async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.delete('network_metrics');
      await txn.delete('feedback_data');
    });
    debugPrint('🗑️ All logs cleared');
  }

  Future<void> insertNetworkMetrics(NetworkMetrics metrics) async {
    try {
      final db = await database;
      
      // Convert to map and ensure all fields are present
      final map = metrics.toMap();
      
      // Ensure isSynced is present
      if (!map.containsKey('isSynced')) {
        map['isSynced'] = 0;
      }
      
      await db.insert(
        'network_metrics', 
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Network metrics inserted successfully: ${metrics.id}');
    } catch (e) {
      debugPrint('❌ Error inserting network metrics: $e');
      rethrow;
    }
  }

  Future<void> insertFeedback(FeedbackData feedback) async {
    try {
      final db = await database;
      
      // Convert to map and ensure all fields are present
      final map = feedback.toMap();
      
      // Ensure isSynced is present
      if (!map.containsKey('isSynced')) {
        map['isSynced'] = 0;
      }
      
      debugPrint('💾 Inserting feedback data: $map');
      
      await db.insert(
        'feedback_data', 
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Feedback data inserted successfully: ${feedback.id}');
      
      // Verify insertion
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM feedback_data')
      ) ?? 0;
      debugPrint('📊 Total feedback records in database: $count');
      
    } catch (e) {
      debugPrint('❌ Error inserting feedback data: $e');
      rethrow;
    }
  }

  Future<List<NetworkMetrics>> getNetworkMetrics({int? limit, bool? syncedOnly}) async {
    try {
      final db = await database;
      String whereClause = '';
      List<Object?> whereArgs = [];
      
      if (syncedOnly != null) {
        whereClause = 'WHERE isSynced = ?';
        whereArgs = [syncedOnly ? 1 : 0];
      }
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT * FROM network_metrics 
        $whereClause
        ORDER BY timestamp DESC
        ${limit != null ? 'LIMIT $limit' : ''}
      ''', whereArgs);
      
      debugPrint('📊 Retrieved ${maps.length} network metrics from database');
      
      return List.generate(maps.length, (i) {
        try {
          return NetworkMetrics.fromMap(maps[i]);
        } catch (e) {
          debugPrint('⚠️ Error parsing network metrics: $e');
          // Return a default object if parsing fails
          return NetworkMetrics(
            id: maps[i]['id'] ?? 'error-${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp'] ?? 0),
            networkType: maps[i]['networkType'] ?? 'Unknown',
            carrier: maps[i]['carrier'] ?? 'Unknown',
            signalStrength: maps[i]['signalStrength'] ?? 0,
            latitude: (maps[i]['latitude'] ?? 0.0).toDouble(),
            longitude: (maps[i]['longitude'] ?? 0.0).toDouble(),
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Error getting network metrics: $e');
      // Return empty list on error
      return [];
    }
  }

  Future<List<FeedbackData>> getFeedbackData({int? limit, bool? syncedOnly}) async {
    try {
      final db = await database;
      String whereClause = '';
      List<Object?> whereArgs = [];
      
      if (syncedOnly != null) {
        whereClause = 'WHERE isSynced = ?';
        whereArgs = [syncedOnly ? 1 : 0];
      }
      
      debugPrint('🔍 Querying feedback_data table...');
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT * FROM feedback_data 
        $whereClause
        ORDER BY timestamp DESC
        ${limit != null ? 'LIMIT $limit' : ''}
      ''', whereArgs);
      
      debugPrint('📊 Retrieved ${maps.length} feedback records from database');
      
      if (maps.isNotEmpty) {
        debugPrint('📝 Sample feedback record: ${maps.first}');
      }
      
      return List.generate(maps.length, (i) {
        try {
          return FeedbackData.fromMap(maps[i]);
        } catch (e) {
          debugPrint('⚠️ Error parsing feedback data: $e');
          // Return a default object if parsing fails
          return FeedbackData(
            id: maps[i]['id'] ?? 'error-${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp'] ?? 0),
            overallSatisfaction: maps[i]['overallSatisfaction'] ?? 0,
            responseTime: maps[i]['responseTime'] ?? 0,
            usability: maps[i]['usability'] ?? 0,
            networkMetricsId: maps[i]['networkMetricsId'] ?? '',
            latitude: (maps[i]['latitude'] ?? 0.0).toDouble(),
            longitude: (maps[i]['longitude'] ?? 0.0).toDouble(),
            carrier: maps[i]['carrier'] ?? 'Unknown', // Add this required parameter
            isSynced: (maps[i]['isSynced'] ?? 0) == 1, // Also add this required parameter
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Error getting feedback data: $e');
      // Return empty list on error
      return [];
    }
  }

  // Get unsynced data for API sync
  Future<List<NetworkMetrics>> getUnsyncedNetworkMetrics() async {
    return await getNetworkMetrics(syncedOnly: false);
  }

  Future<List<FeedbackData>> getUnsyncedFeedbackData() async {
    return await getFeedbackData(syncedOnly: false);
  }

  // Mark data as synced
  Future<void> markNetworkMetricsAsSynced(List<String> ids) async {
    try {
      final db = await database;
      final batch = db.batch();
      
      for (String id in ids) {
        batch.update(
          'network_metrics',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      
      await batch.commit();
      debugPrint('✅ Marked ${ids.length} network metrics as synced');
    } catch (e) {
      debugPrint('❌ Error marking network metrics as synced: $e');
    }
  }

  Future<void> markFeedbackAsSynced(List<String> ids) async {
    try {
      final db = await database;
      final batch = db.batch();
      
      for (String id in ids) {
        batch.update(
          'feedback_data',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      
      await batch.commit();
      debugPrint('✅ Marked ${ids.length} feedback data as synced');
    } catch (e) {
      debugPrint('❌ Error marking feedback data as synced: $e');
    }
  }

  // Get statistics
  Future<Map<String, int>> getDataStats() async {
    try {
      final db = await database;
      
      final metricsTotal = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM network_metrics')
      ) ?? 0;
      
      final metricsSynced = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM network_metrics WHERE isSynced = 1')
      ) ?? 0;
      
      final feedbackTotal = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM feedback_data')
      ) ?? 0;
      
      final feedbackSynced = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM feedback_data WHERE isSynced = 1')
      ) ?? 0;
      
      debugPrint('📊 Database stats - Metrics: $metricsTotal, Feedback: $feedbackTotal');
      
      return {
        'metricsTotal': metricsTotal,
        'metricsSynced': metricsSynced,
        'metricsUnsynced': metricsTotal - metricsSynced,
        'feedbackTotal': feedbackTotal,
        'feedbackSynced': feedbackSynced,
        'feedbackUnsynced': feedbackTotal - feedbackSynced,
      };
    } catch (e) {
      debugPrint('❌ Error getting data stats: $e');
      return {
        'metricsTotal': 0,
        'metricsSynced': 0,
        'metricsUnsynced': 0,
        'feedbackTotal': 0,
        'feedbackSynced': 0,
        'feedbackUnsynced': 0,
      };
    }
  }

  Future<void> resetDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'qoe_data.db');
      await deleteDatabase(path);
      _database = null;
      debugPrint('✅ Database reset successfully');
    } catch (e) {
      debugPrint('❌ Error resetting database: $e');
    }
  }
}
