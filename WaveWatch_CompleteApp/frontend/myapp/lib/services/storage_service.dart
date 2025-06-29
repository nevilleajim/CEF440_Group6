import '../models/feedback_data.dart';
import '../models/network_metrics.dart';
// ignore: unused_import
import 'database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_data.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  UserData? _userData;
  List<NetworkMetrics> _networkMetrics = [];
  List<FeedbackData> _feedbackData = [];
  
  // Track sync status
  List<String> _syncedNetworkMetricsIds = [];
  List<String> _syncedFeedbackIds = [];
  
  bool _isInitialized = false;

  // Initialize storage service and load persisted data
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadPersistedData();
    _isInitialized = true;
    print('✅ StorageService initialized');
  }

  UserData get userData => _userData ?? UserData(
    id: 'user_001',
    feedbackHistory: _feedbackData,
    lastSync: DateTime.now(),
  );

  // Save feedback data
  Future<void> saveFeedback(FeedbackData feedback) async {
    await Future.delayed(Duration(milliseconds: 500));
    
    _userData ??= userData;
    _feedbackData.add(feedback);
    _userData!.feedbackHistory = _feedbackData;
    _userData!.addPoints(10);
    
    // Persist to SharedPreferences
    await _persistFeedbackData();
    
    print('✅ Feedback saved: ${feedback.id} (Sync: ${feedback.isSynced})');
  }

  // Save network metrics
  Future<void> saveNetworkMetrics(NetworkMetrics metrics) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    _networkMetrics.add(metrics);
    
    // Persist to SharedPreferences
    await _persistNetworkMetrics();
    
    print('✅ Network metrics saved: ${metrics.id} (Sync: ${metrics.isSynced})');
  }

  // Get all network metrics
  List<NetworkMetrics> getNetworkMetrics() {
    return List.unmodifiable(_networkMetrics);
  }

  // Get recent network metrics for trend analysis
  Future<List<NetworkMetrics>> getRecentNetworkMetrics(int count) async {
    // Sort by timestamp (newest first) and take the requested count
    final sortedMetrics = List<NetworkMetrics>.from(_networkMetrics);
    sortedMetrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sortedMetrics.take(count).toList();
  }

  // Get all feedback data
  List<FeedbackData> getFeedbackData() {
    return List.unmodifiable(_feedbackData);
  }

  // Get unsynced network metrics
  List<NetworkMetrics> getUnsyncedNetworkMetrics() {
    return _networkMetrics.where((metrics) => !metrics.isSynced).toList();
  }

  // Get unsynced feedback data
  List<FeedbackData> getUnsyncedFeedbackData() {
    return _feedbackData.where((feedback) => !feedback.isSynced).toList();
  }

  // Mark network metrics as synced
  Future<void> markNetworkMetricsAsSynced(List<String> ids) async {
    for (String id in ids) {
      final index = _networkMetrics.indexWhere((metrics) => metrics.id == id);
      if (index != -1) {
        _networkMetrics[index] = _networkMetrics[index].copyWith(isSynced: true);
        _syncedNetworkMetricsIds.add(id);
      }
    }
    
    await _persistNetworkMetrics();
    await _persistSyncStatus();
    
    print('✅ Marked ${ids.length} network metrics as synced');
  }

  // Mark feedback as synced
  Future<void> markFeedbackAsSynced(List<String> ids) async {
    for (String id in ids) {
      final index = _feedbackData.indexWhere((feedback) => feedback.id == id);
      if (index != -1) {
        _feedbackData[index] = _feedbackData[index].copyWith(isSynced: true);
        _syncedFeedbackIds.add(id);
      }
    }
    
    // Update user data feedback history
    _userData?.feedbackHistory = _feedbackData;
    
    await _persistFeedbackData();
    await _persistSyncStatus();
    
    print('✅ Marked ${ids.length} feedback items as synced');
  }

  // Get network metrics by ID
  NetworkMetrics? getNetworkMetricsById(String id) {
    try {
      return _networkMetrics.firstWhere((metrics) => metrics.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get feedback by ID
  FeedbackData? getFeedbackById(String id) {
    try {
      return _feedbackData.firstWhere((feedback) => feedback.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get data statistics
  Map<String, int> getDataStats() {
    final unsyncedMetrics = getUnsyncedNetworkMetrics().length;
    final unsyncedFeedback = getUnsyncedFeedbackData().length;
    
    return {
      'metricsTotal': _networkMetrics.length,
      'metricsSynced': _networkMetrics.length - unsyncedMetrics,
      'metricsUnsynced': unsyncedMetrics,
      'feedbackTotal': _feedbackData.length,
      'feedbackSynced': _feedbackData.length - unsyncedFeedback,
      'feedbackUnsynced': unsyncedFeedback,
    };
  }

  // Clear all data
  void clearAllData() {
    _networkMetrics.clear();
    _feedbackData.clear();
    _syncedNetworkMetricsIds.clear();
    _syncedFeedbackIds.clear();
    _userData?.feedbackHistory.clear();
    
    // Clear persisted data
    _clearPersistedData();
    
    print('🗑️ All data cleared from StorageService');
  }

  // Sync data (placeholder for actual sync logic)
  Future<void> syncData() async {
    await Future.delayed(Duration(seconds: 2));
    _userData ??= userData;
    print('🔄 Data sync completed');
  }

  // Persist network metrics to SharedPreferences
  Future<void> _persistNetworkMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _networkMetrics.map((metrics) => metrics.toMap()).toList();
      await prefs.setString('network_metrics', jsonEncode(jsonList));
    } catch (e) {
      print('❌ Error persisting network metrics: $e');
    }
  }

  // Persist feedback data to SharedPreferences
  Future<void> _persistFeedbackData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _feedbackData.map((feedback) => feedback.toMap()).toList();
      await prefs.setString('feedback_data', jsonEncode(jsonList));
    } catch (e) {
      print('❌ Error persisting feedback data: $e');
    }
  }

  // Persist sync status
  Future<void> _persistSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('synced_network_metrics', _syncedNetworkMetricsIds);
      await prefs.setStringList('synced_feedback', _syncedFeedbackIds);
    } catch (e) {
      print('❌ Error persisting sync status: $e');
    }
  }

  // Load persisted data from SharedPreferences
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load network metrics
      final networkMetricsJson = prefs.getString('network_metrics');
      if (networkMetricsJson != null) {
        final List<dynamic> jsonList = jsonDecode(networkMetricsJson);
        _networkMetrics = jsonList
            .map((json) => NetworkMetrics.fromMap(json as Map<String, dynamic>))
            .toList();
        print('📱 Loaded ${_networkMetrics.length} network metrics from storage');
      }
      
      // Load feedback data
      final feedbackDataJson = prefs.getString('feedback_data');
      if (feedbackDataJson != null) {
        final List<dynamic> jsonList = jsonDecode(feedbackDataJson);
        _feedbackData = jsonList
            .map((json) => FeedbackData.fromMap(json as Map<String, dynamic>))
            .toList();
        print('📱 Loaded ${_feedbackData.length} feedback items from storage');
      }
      
      // Load sync status
      _syncedNetworkMetricsIds = prefs.getStringList('synced_network_metrics') ?? [];
      _syncedFeedbackIds = prefs.getStringList('synced_feedback') ?? [];
      
      // Update user data
      _userData = UserData(
        id: 'user_001',
        feedbackHistory: _feedbackData,
        lastSync: DateTime.now(),
      );
      
    } catch (e) {
      print('❌ Error loading persisted data: $e');
    }
  }

  // Clear persisted data
  Future<void> _clearPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('network_metrics');
      await prefs.remove('feedback_data');
      await prefs.remove('synced_network_metrics');
      await prefs.remove('synced_feedback');
      print('🗑️ Cleared persisted data');
    } catch (e) {
      print('❌ Error clearing persisted data: $e');
    }
  }
}
