import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataUsageService extends ChangeNotifier {
  static final DataUsageService _instance = DataUsageService._internal();
  factory DataUsageService() => _instance;
  DataUsageService._internal();

  // Data usage tracking
  int _totalBytesUploaded = 0;
  int _totalBytesDownloaded = 0;
  int _syncSessionsCount = 0;
  DateTime? _trackingStartDate;
  Map<String, int> _dailyUsage = {};
  Map<String, int> _monthlyUsage = {};
  
  // Current session tracking
  int _currentSessionUpload = 0;
  int _currentSessionDownload = 0;
  DateTime? _currentSessionStart;

  // Getters
  int get totalBytesUploaded => _totalBytesUploaded;
  int get totalBytesDownloaded => _totalBytesDownloaded;
  int get totalBytes => _totalBytesUploaded + _totalBytesDownloaded;
  int get syncSessionsCount => _syncSessionsCount;
  DateTime? get trackingStartDate => _trackingStartDate;
  int get currentSessionUpload => _currentSessionUpload;
  int get currentSessionDownload => _currentSessionDownload;
  int get currentSessionTotal => _currentSessionUpload + _currentSessionDownload;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadDataUsage();
    _isInitialized = true;
    debugPrint('📊 DataUsageService initialized');
  }

  // Start tracking a sync session
  void startSyncSession() {
    _currentSessionStart = DateTime.now();
    _currentSessionUpload = 0;
    _currentSessionDownload = 0;
    debugPrint('📊 Started sync session tracking');
  }

  // End tracking a sync session
  Future<void> endSyncSession() async {
    if (_currentSessionStart == null) return;

    _syncSessionsCount++;
    await _persistDataUsage();
    
    debugPrint('📊 Sync session ended - Upload: ${formatBytes(_currentSessionUpload)}, Download: ${formatBytes(_currentSessionDownload)}');
    
    _currentSessionStart = null;
    notifyListeners();
  }

  // Track uploaded data (when sending data to server)
  Future<void> trackUpload(int bytes, {String? description}) async {
    _totalBytesUploaded += bytes;
    _currentSessionUpload += bytes;
    
    final today = _getTodayKey();
    final thisMonth = _getThisMonthKey();
    
    _dailyUsage[today] = (_dailyUsage[today] ?? 0) + bytes;
    _monthlyUsage[thisMonth] = (_monthlyUsage[thisMonth] ?? 0) + bytes;
    
    await _persistDataUsage();
    notifyListeners();
    
    debugPrint('📤 Upload tracked: ${formatBytes(bytes)} ${description != null ? '($description)' : ''}');
  }

  // Track downloaded data (when receiving data from server)
  Future<void> trackDownload(int bytes, {String? description}) async {
    _totalBytesDownloaded += bytes;
    _currentSessionDownload += bytes;
    
    final today = _getTodayKey();
    final thisMonth = _getThisMonthKey();
    
    _dailyUsage[today] = (_dailyUsage[today] ?? 0) + bytes;
    _monthlyUsage[thisMonth] = (_monthlyUsage[thisMonth] ?? 0) + bytes;
    
    await _persistDataUsage();
    notifyListeners();
    
    debugPrint('📥 Download tracked: ${formatBytes(bytes)} ${description != null ? '($description)' : ''}');
  }

  // Get today's data usage
  int getTodayUsage() {
    final today = _getTodayKey();
    return _dailyUsage[today] ?? 0;
  }

  // Get this month's data usage
  int getThisMonthUsage() {
    final thisMonth = _getThisMonthKey();
    return _monthlyUsage[thisMonth] ?? 0;
  }

  // Get average daily usage
  double getAverageDailyUsage() {
    if (_dailyUsage.isEmpty) return 0.0;
    
    final totalUsage = _dailyUsage.values.fold(0, (sum, usage) => sum + usage);
    return totalUsage / _dailyUsage.length;
  }

  // Get usage for specific date
  int getUsageForDate(DateTime date) {
    final key = _getDateKey(date);
    return _dailyUsage[key] ?? 0;
  }

  // Get usage statistics
  Map<String, dynamic> getUsageStats() {
    final now = DateTime.now();
    final daysTracking = _trackingStartDate != null 
        ? now.difference(_trackingStartDate!).inDays + 1 
        : 1;

    return {
      'totalBytes': totalBytes,
      'totalBytesUploaded': _totalBytesUploaded,
      'totalBytesDownloaded': _totalBytesDownloaded,
      'syncSessions': _syncSessionsCount,
      'averagePerSession': _syncSessionsCount > 0 ? totalBytes / _syncSessionsCount : 0,
      'averagePerDay': daysTracking > 0 ? totalBytes / daysTracking : 0,
      'todayUsage': getTodayUsage(),
      'thisMonthUsage': getThisMonthUsage(),
      'daysTracking': daysTracking,
      'trackingStartDate': _trackingStartDate?.toIso8601String(),
    };
  }

  // Get daily usage history (last 30 days)
  Map<String, int> getDailyUsageHistory({int days = 30}) {
    final history = <String, int>{};
    final now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _getDateKey(date);
      history[key] = _dailyUsage[key] ?? 0;
    }
    
    return history;
  }

  // Reset all data usage statistics
  Future<void> resetUsageStats() async {
    _totalBytesUploaded = 0;
    _totalBytesDownloaded = 0;
    _syncSessionsCount = 0;
    _trackingStartDate = DateTime.now();
    _dailyUsage.clear();
    _monthlyUsage.clear();
    _currentSessionUpload = 0;
    _currentSessionDownload = 0;
    
    await _persistDataUsage();
    notifyListeners();
    
    debugPrint('📊 Data usage statistics reset');
  }

  // Estimate data usage for pending items
  int estimateDataUsageForPendingItems(int networkMetricsCount, int feedbackCount) {
    // Rough estimates based on typical JSON payload sizes
    const int avgNetworkMetricSize = 500; // bytes per network metric
    const int avgFeedbackSize = 300; // bytes per feedback item
    
    return (networkMetricsCount * avgNetworkMetricSize) + (feedbackCount * avgFeedbackSize);
  }

  // Helper methods
  String _getTodayKey() => _getDateKey(DateTime.now());
  
  String _getThisMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
  
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Persistence methods
  Future<void> _loadDataUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _totalBytesUploaded = prefs.getInt('data_usage_uploaded') ?? 0;
      _totalBytesDownloaded = prefs.getInt('data_usage_downloaded') ?? 0;
      _syncSessionsCount = prefs.getInt('sync_sessions_count') ?? 0;
      
      final trackingStartString = prefs.getString('tracking_start_date');
      if (trackingStartString != null) {
        _trackingStartDate = DateTime.parse(trackingStartString);
      } else {
        _trackingStartDate = DateTime.now();
        await prefs.setString('tracking_start_date', _trackingStartDate!.toIso8601String());
      }
      
      // Load daily usage
      final dailyUsageString = prefs.getString('daily_usage');
      if (dailyUsageString != null) {
        final Map<String, dynamic> dailyUsageJson = jsonDecode(dailyUsageString);
        _dailyUsage = dailyUsageJson.map((key, value) => MapEntry(key, value as int));
      }
      
      // Load monthly usage
      final monthlyUsageString = prefs.getString('monthly_usage');
      if (monthlyUsageString != null) {
        final Map<String, dynamic> monthlyUsageJson = jsonDecode(monthlyUsageString);
        _monthlyUsage = monthlyUsageJson.map((key, value) => MapEntry(key, value as int));
      }
      
      debugPrint('📊 Loaded data usage: ${formatBytes(totalBytes)} total');
    } catch (e) {
      debugPrint('❌ Error loading data usage: $e');
    }
  }

  Future<void> _persistDataUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('data_usage_uploaded', _totalBytesUploaded);
      await prefs.setInt('data_usage_downloaded', _totalBytesDownloaded);
      await prefs.setInt('sync_sessions_count', _syncSessionsCount);
      
      if (_trackingStartDate != null) {
        await prefs.setString('tracking_start_date', _trackingStartDate!.toIso8601String());
      }
      
      // Persist daily usage
      await prefs.setString('daily_usage', jsonEncode(_dailyUsage));
      
      // Persist monthly usage
      await prefs.setString('monthly_usage', jsonEncode(_monthlyUsage));
      
    } catch (e) {
      debugPrint('❌ Error persisting data usage: $e');
    }
  }

  // Utility function to format bytes
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
