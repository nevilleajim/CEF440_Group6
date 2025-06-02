// services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/network_metrics.dart';
import '../models/feedback_data.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }


  Future<void> clearAllLogs() async {
    final db = await database;
    
    // Use a transaction to ensure both operations succeed or both fail
    await db.transaction((txn) async {
      // Clear all network metrics
      await txn.delete('network_metrics');
      
      // Clear all feedback data
      await txn.delete('feedback_data');
    });
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'qoe_data.db');
    
    return await openDatabase(
      path,
      version: 2, // Increment version to trigger migration
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add missing columns to existing table
          await db.execute('ALTER TABLE network_metrics ADD COLUMN address TEXT');
          await db.execute('ALTER TABLE network_metrics ADD COLUMN city TEXT');
          await db.execute('ALTER TABLE network_metrics ADD COLUMN country TEXT');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE network_metrics(
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
        packetLoss REAL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE feedback_data(
        id TEXT PRIMARY KEY,
        timestamp INTEGER,
        overallSatisfaction INTEGER,
        responseTime INTEGER,
        usability INTEGER,
        comments TEXT,
        networkMetricsId TEXT,
        latitude REAL,
        longitude REAL,
        carrier TEXT
      )
    ''');
  }

  Future<void> insertNetworkMetrics(NetworkMetrics metrics) async {
    final db = await database;
    await db.insert('network_metrics', metrics.toMap());
  }

  Future<void> insertFeedback(FeedbackData feedback) async {
    final db = await database;
    await db.insert('feedback_data', feedback.toMap());
  }

  Future<List<NetworkMetrics>> getNetworkMetrics({int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'network_metrics',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) => NetworkMetrics.fromMap(maps[i]));
  }

  Future<List<FeedbackData>> getFeedbackData({int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'feedback_data',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) => FeedbackData.fromMap(maps[i]));
  }

  // Helper method to completely reset database if needed
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'qoe_data.db');
    await deleteDatabase(path);
    _database = null;
  }
}