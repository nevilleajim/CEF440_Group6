// models/feedback_data.dart
class FeedbackData {
  final String id;
  final DateTime timestamp;
  final int overallSatisfaction;
  final int responseTime;
  final int usability;
  final String? comments;
  final String networkMetricsId;
  final double latitude;
  final double longitude;
  final String carrier;

  FeedbackData({
    required this.id,
    required this.timestamp,
    required this.overallSatisfaction,
    required this.responseTime,
    required this.usability,
    this.comments,
    required this.networkMetricsId,
    required this.latitude,
    required this.longitude,
    required this.carrier,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'overallSatisfaction': overallSatisfaction,
      'responseTime': responseTime,
      'usability': usability,
      'comments': comments,
      'networkMetricsId': networkMetricsId,
      'latitude': latitude,
      'longitude': longitude,
      'carrier': carrier,
    };
  }

  factory FeedbackData.fromMap(Map<String, dynamic> map) {
    return FeedbackData(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      overallSatisfaction: map['overallSatisfaction'],
      responseTime: map['responseTime'],
      usability: map['usability'],
      comments: map['comments'],
      networkMetricsId: map['networkMetricsId'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      carrier: map['carrier'],
    );
  }
}
