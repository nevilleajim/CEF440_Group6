import 'package:WaveWatch/models/feedback_data.dart';

class UserData {
  final String id;
  int points;
  List<FeedbackData> feedbackHistory;
  final DateTime lastSync;

  UserData({
    required this.id,
    this.points = 0,
    required this.feedbackHistory,
    required this.lastSync,
  });

  void addPoints(int amount) {
    points += amount;
  }
}
