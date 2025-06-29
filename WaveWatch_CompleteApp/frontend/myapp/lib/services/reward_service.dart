import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardsService extends ChangeNotifier {
  static const String _pointsKey = 'total_points';
  static const String _testCountKey = 'test_count';
  static const String _feedbackCountKey = 'feedback_count';
  static const String _lastTestDateKey = 'last_test_date';
  static const String _lastFeedbackDateKey = 'last_feedback_date';
  
  int _totalPoints = 0;
  int _testCount = 0;
  int _feedbackCount = 0;
  DateTime? _lastTestDate;
  DateTime? _lastFeedbackDate;
  
  // Getters
  int get totalPoints => _totalPoints;
  int get testCount => _testCount;
  int get feedbackCount => _feedbackCount;
  DateTime? get lastTestDate => _lastTestDate;
  DateTime? get lastFeedbackDate => _lastFeedbackDate;
  
  // Point values for different achievements
  static const int speedTestPoints = 10;
  static const int feedbackPoints = 10;
  static const int dailyBonusPoints = 5;
  static const int weeklyBonusPoints = 50;
  static const int monthlyBonusPoints = 200;
  
  // Initialize the service and load saved data
  Future<void> initialize() async {
    await _loadData();
  }
  
  // Load data from SharedPreferences
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalPoints = prefs.getInt(_pointsKey) ?? 0;
      _testCount = prefs.getInt(_testCountKey) ?? 0;
      _feedbackCount = prefs.getInt(_feedbackCountKey) ?? 0;
      
      final lastTestString = prefs.getString(_lastTestDateKey);
      if (lastTestString != null) {
        _lastTestDate = DateTime.parse(lastTestString);
      }
      
      final lastFeedbackString = prefs.getString(_lastFeedbackDateKey);
      if (lastFeedbackString != null) {
        _lastFeedbackDate = DateTime.parse(lastFeedbackString);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading rewards data: $e');
    }
  }
  
  // Save data to SharedPreferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pointsKey, _totalPoints);
      await prefs.setInt(_testCountKey, _testCount);
      await prefs.setInt(_feedbackCountKey, _feedbackCount);
      
      if (_lastTestDate != null) {
        await prefs.setString(_lastTestDateKey, _lastTestDate!.toIso8601String());
      }
      
      if (_lastFeedbackDate != null) {
        await prefs.setString(_lastFeedbackDateKey, _lastFeedbackDate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving rewards data: $e');
    }
  }
  
  // Award points for providing feedback
  Future<int> awardFeedbackPoints() async {
    int pointsEarned = feedbackPoints;
    
    // Check for daily bonus
    if (_canAwardDailyFeedbackBonus()) {
      pointsEarned += dailyBonusPoints;
    }
    
    // Check for streak bonuses
    pointsEarned += _calculateFeedbackStreakBonus();
    
    _totalPoints += pointsEarned;
    _feedbackCount++;
    _lastFeedbackDate = DateTime.now();
    
    await _saveData();
    notifyListeners();
    
    debugPrint('🎉 Awarded $pointsEarned points for feedback! Total: $_totalPoints');
    return pointsEarned;
  }
  
  // Award points for completing a speed test
  Future<int> awardSpeedTestPoints({
    double? downloadSpeed,
    double? uploadSpeed,
    int? ping,
  }) async {
    int pointsEarned = speedTestPoints;
    
    // Bonus points for good performance
    if (downloadSpeed != null && downloadSpeed > 50) {
      pointsEarned += 5; // Bonus for fast download
    }
    if (uploadSpeed != null && uploadSpeed > 25) {
      pointsEarned += 3; // Bonus for fast upload
    }
    if (ping != null && ping < 50) {
      pointsEarned += 2; // Bonus for low ping
    }
    
    // Check for daily bonus
    if (_canAwardDailyTestBonus()) {
      pointsEarned += dailyBonusPoints;
    }
    
    // Check for streak bonuses
    pointsEarned += _calculateTestStreakBonus();
    
    _totalPoints += pointsEarned;
    _testCount++;
    _lastTestDate = DateTime.now();
    
    await _saveData();
    notifyListeners();
    
    debugPrint('🎉 Awarded $pointsEarned points for speed test! Total: $_totalPoints');
    return pointsEarned;
  }
  
  // Check if user can get daily feedback bonus
  bool _canAwardDailyFeedbackBonus() {
    if (_lastFeedbackDate == null) return true;
    
    final now = DateTime.now();
    final lastFeedback = _lastFeedbackDate!;
    
    return now.day != lastFeedback.day || 
           now.month != lastFeedback.month || 
           now.year != lastFeedback.year;
  }
  
  // Check if user can get daily test bonus
  bool _canAwardDailyTestBonus() {
    if (_lastTestDate == null) return true;
    
    final now = DateTime.now();
    final lastTest = _lastTestDate!;
    
    return now.day != lastTest.day || 
           now.month != lastTest.month || 
           now.year != lastTest.year;
  }
  
  // Calculate feedback streak bonus
  int _calculateFeedbackStreakBonus() {
    if (_feedbackCount > 0 && _feedbackCount % 5 == 0) {
      return 25; // Bonus for every 5 feedback submissions
    }
    if (_feedbackCount > 0 && _feedbackCount % 10 == 0) {
      return weeklyBonusPoints;
    }
    return 0;
  }
  
  // Calculate test streak bonus
  int _calculateTestStreakBonus() {
    if (_testCount > 0 && _testCount % 7 == 0) {
      return weeklyBonusPoints;
    }
    if (_testCount > 0 && _testCount % 30 == 0) {
      return monthlyBonusPoints;
    }
    return 0;
  }
  
  // Award custom points for specific achievements
  Future<void> awardCustomPoints(int points, String reason) async {
    _totalPoints += points;
    await _saveData();
    notifyListeners();
    
    debugPrint('Awarded $points points for: $reason');
  }
  
  // Get user level based on points
  int getUserLevel() {
    if (_totalPoints < 100) return 1;
    if (_totalPoints < 500) return 2;
    if (_totalPoints < 1000) return 3;
    if (_totalPoints < 2500) return 4;
    if (_totalPoints < 5000) return 5;
    return 6; // Max level
  }
  
  // Get points needed for next level
  int getPointsForNextLevel() {
    final currentLevel = getUserLevel();
    switch (currentLevel) {
      case 1: return 100 - _totalPoints;
      case 2: return 500 - _totalPoints;
      case 3: return 1000 - _totalPoints;
      case 4: return 2500 - _totalPoints;
      case 5: return 5000 - _totalPoints;
      default: return 0; // Max level reached
    }
  }
  
  // Get level name
  String getLevelName() {
    final level = getUserLevel();
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Explorer';
      case 3: return 'Speedster';
      case 4: return 'Expert';
      case 5: return 'Master';
      case 6: return 'Legend';
      default: return 'Unknown';
    }
  }
  
  // Reset all data (for testing or user request)
  Future<void> resetRewards() async {
    _totalPoints = 0;
    _testCount = 0;
    _feedbackCount = 0;
    _lastTestDate = null;
    _lastFeedbackDate = null;
    
    await _saveData();
    notifyListeners();
  }
  
  // Get achievements list
  List<Achievement> getAchievements() {
    List<Achievement> achievements = [];
    
    // Feedback achievements
    if (_feedbackCount >= 1) {
      achievements.add(Achievement(
        title: 'First Feedback',
        description: 'Submit your first feedback',
        isUnlocked: true,
        points: feedbackPoints,
      ));
    }
    
    if (_feedbackCount >= 5) {
      achievements.add(Achievement(
        title: 'Feedback Helper',
        description: 'Submit 5 feedback reports',
        isUnlocked: true,
        points: 25,
      ));
    }
    
    if (_feedbackCount >= 10) {
      achievements.add(Achievement(
        title: 'Community Contributor',
        description: 'Submit 10 feedback reports',
        isUnlocked: true,
        points: 50,
      ));
    }
    
    // Test count achievements
    if (_testCount >= 1) {
      achievements.add(Achievement(
        title: 'First Test',
        description: 'Complete your first speed test',
        isUnlocked: true,
        points: speedTestPoints,
      ));
    }
    
    if (_testCount >= 10) {
      achievements.add(Achievement(
        title: 'Speed Demon',
        description: 'Complete 10 speed tests',
        isUnlocked: true,
        points: 50,
      ));
    }
    
    if (_testCount >= 50) {
      achievements.add(Achievement(
        title: 'Network Ninja',
        description: 'Complete 50 speed tests',
        isUnlocked: true,
        points: 100,
      ));
    }
    
    // Points achievements
    if (_totalPoints >= 500) {
      achievements.add(Achievement(
        title: 'Point Collector',
        description: 'Earn 500 total points',
        isUnlocked: true,
        points: 25,
      ));
    }
    
    if (_totalPoints >= 1000) {
      achievements.add(Achievement(
        title: 'Point Master',
        description: 'Earn 1000 total points',
        isUnlocked: true,
        points: 50,
      ));
    }
    
    return achievements;
  }
}

// Achievement model
class Achievement {
  final String title;
  final String description;
  final bool isUnlocked;
  final int points;
  
  Achievement({
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.points,
  });
}
