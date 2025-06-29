import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'data_usage_service.dart';
import 'dart:convert';

class SyncService extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  final Connectivity _connectivity = Connectivity();
  final DataUsageService _dataUsageService = DataUsageService();
  
  Timer? _syncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String _syncStatus = 'Ready';
  int _pendingItems = 0;
  
  bool get isSyncing => _isSyncing;
  String get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingItems => _pendingItems;

  SyncService() {
    _initializeSync();
  }

  Future<void> _initializeSync() async {
    // Initialize API service first
    await _apiService.initialize();
    
    // Initialize storage service
    await _storageService.initialize();

    // Initialize data usage service
    await _dataUsageService.initialize();
    
    await _loadSyncStatus();
    
    // Check for pending items on startup
    await _updatePendingItemsCount();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        debugPrint('🌐 Connection restored, starting sync...');
        syncNow();
      }
    });
    
    // Start periodic sync timer (every 5 minutes when connected)
    _startPeriodicSync();
    
    // Perform initial sync if connected
    final isConnected = await _isConnected();
    if (isConnected) {
      syncNow();
    }
  }

  Future<void> _loadSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString('last_sync_time');
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }
    } catch (e) {
      debugPrint('Error loading sync status: $e');
    }
  }

  Future<void> _saveSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastSyncTime != null) {
        await prefs.setString('last_sync_time', _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving sync status: $e');
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (_) async {
      final isConnected = await _isConnected();
      if (isConnected && !_isSyncing) {
        syncNow();
      }
    });
  }

  Future<bool> _isConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updatePendingItemsCount() async {
    try {
      final stats = _storageService.getDataStats();
      _pendingItems = (stats['metricsUnsynced'] ?? 0) + (stats['feedbackUnsynced'] ?? 0);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating pending items count: $e');
    }
  }

  // SIMPLIFIED - No authentication required anymore
  Future<void> syncNow() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping...');
      return;
    }

    final isConnected = await _isConnected();
    if (!isConnected) {
      _syncStatus = 'No internet connection';
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _syncStatus = 'Syncing...';
    notifyListeners();

    try {
      // Start tracking data usage for this sync session
      _dataUsageService.startSyncSession();

      // Check if API is reachable
      bool apiReachable = false;
      try {
        final healthUrl = '${ApiService.baseUrl}/health';
        debugPrint('🔍 Checking API health at: $healthUrl');
        final response = await http.get(Uri.parse(healthUrl))
            .timeout(Duration(seconds: 5));
        apiReachable = response.statusCode == 200;
        debugPrint('✅ API health check response: ${response.statusCode}');
      } catch (e) {
        debugPrint('⚠️ API not reachable: $e');
      }

      if (!apiReachable) {
        _syncStatus = 'API server not reachable';
        debugPrint('⚠️ API server not reachable, skipping sync');
        return;
      }

      // Sync data without authentication requirement
      debugPrint('🚀 Starting anonymous data sync...');
      await _syncNetworkMetrics();
      await _syncFeedbackData();
      
      _lastSyncTime = DateTime.now();
      _syncStatus = 'Sync completed';
      await _saveSyncStatus();
      
      await _updatePendingItemsCount();
      
      debugPrint('✅ Anonymous sync completed successfully');
    } catch (e) {
      _syncStatus = 'Sync failed: ${e.toString()}';
      debugPrint('❌ Sync failed: $e');
    } finally {
      // End data usage tracking
      await _dataUsageService.endSyncSession();

      _isSyncing = false;
      notifyListeners();
      
      // Reset status after 3 seconds
      Timer(Duration(seconds: 3), () {
        if (_syncStatus.contains('completed') || _syncStatus.contains('failed')) {
          _syncStatus = 'Ready';
          notifyListeners();
        }
      });
    }
  }

  Future<void> _syncNetworkMetrics() async {
    try {
      final unsyncedMetrics = _storageService.getUnsyncedNetworkMetrics();
      
      if (unsyncedMetrics.isEmpty) {
        debugPrint('No unsynced network metrics to upload');
        return;
      }

      debugPrint('📊 Syncing ${unsyncedMetrics.length} network metrics anonymously...');
      
      List<String> syncedIds = [];
      
      for (final metric in unsyncedMetrics) {
        try {
          await _apiService.submitNetworkLog(metric);
          syncedIds.add(metric.id);
          debugPrint('✅ Successfully synced metric: ${metric.id}');

          // Track data usage for network metrics
          final dataSize = jsonEncode(metric.toMap()).length;
          await _dataUsageService.trackUpload(dataSize, description: 'Network metrics');
        } catch (e) {
          debugPrint('❌ Failed to sync metric ${metric.id}: $e');
          // Continue with other metrics
        }
      }
      
      if (syncedIds.isNotEmpty) {
        await _storageService.markNetworkMetricsAsSynced(syncedIds);
        debugPrint('✅ Marked ${syncedIds.length} network metrics as synced');
      }
    } catch (e) {
      debugPrint('❌ Error syncing network metrics: $e');
      rethrow;
    }
  }

  Future<void> _syncFeedbackData() async {
    try {
      final unsyncedFeedback = _storageService.getUnsyncedFeedbackData();
      
      if (unsyncedFeedback.isEmpty) {
        debugPrint('No unsynced feedback to upload');
        return;
      }

      debugPrint('💬 Syncing ${unsyncedFeedback.length} feedback items anonymously...');
      
      List<String> syncedIds = [];
      
      for (final feedback in unsyncedFeedback) {
        try {
          await _apiService.submitFeedback(feedback);
          syncedIds.add(feedback.id);
          debugPrint('✅ Successfully synced feedback: ${feedback.id}');

          // Track data usage for feedback
          final dataSize = jsonEncode(feedback.toMap()).length;
          await _dataUsageService.trackUpload(dataSize, description: 'Feedback data');
        } catch (e) {
          debugPrint('❌ Failed to sync feedback ${feedback.id}: $e');
          // Continue with other feedback
        }
      }
      
      if (syncedIds.isNotEmpty) {
        await _storageService.markFeedbackAsSynced(syncedIds);
        debugPrint('✅ Marked ${syncedIds.length} feedback items as synced');
      }
    } catch (e) {
      debugPrint('❌ Error syncing feedback data: $e');
      rethrow;
    }
  }

  // Manual sync trigger
  Future<void> forceSync() async {
    await syncNow();
  }

  // Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    final stats = _storageService.getDataStats();
    return {
      ...stats,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'syncStatus': _syncStatus,
      'isSyncing': _isSyncing,
    };
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
