import '../models/feedback_data.dart';
import '../models/user_data.dart';
import '../models/network_metrics.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  UserData? _userData;
  List<NetworkMetrics> _networkMetrics = [];

  UserData get userData => _userData ?? UserData(
    id: 'user_001',
    feedbackHistory: [],
    lastSync: DateTime.now(),
  );

  Future<void> saveFeedback(FeedbackData feedback) async {
    await Future.delayed(Duration(milliseconds: 500));
    _userData ??= userData;
    _userData!.feedbackHistory.add(feedback);
    _userData!.addPoints(10);
  }

  Future<void> saveNetworkMetrics(NetworkMetrics metrics) async {
    await Future.delayed(Duration(milliseconds: 300));
    _networkMetrics.add(metrics);
    print('Network metrics saved: ${metrics.id}');
  }

  List<NetworkMetrics> getNetworkMetrics() {
    return List.unmodifiable(_networkMetrics);
  }

  NetworkMetrics? getNetworkMetricsById(String id) {
    try {
      return _networkMetrics.firstWhere((metrics) => metrics.id == id);
    } catch (e) {
      return null;
    }
  }

  // ADDED: Clear all data method
  void clearAllData() {
    _networkMetrics.clear();
    _userData?.feedbackHistory.clear();
    print('All data cleared from StorageService');
  }

  Future<void> syncData() async {
    await Future.delayed(Duration(seconds: 2));
    _userData ??= userData;
  }
}