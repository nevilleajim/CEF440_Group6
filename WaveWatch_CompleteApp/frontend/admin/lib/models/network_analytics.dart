// models/network_analytics.dart
class NetworkAnalytics {
  final String location;
  final double avgLatency;
  final double avgJitter;
  final double avgPacketLoss;
  final double avgSignalStrength;
  final double avgUserRating;
  final int totalFeedbacks;

  NetworkAnalytics({
    required this.location,
    required this.avgLatency,
    required this.avgJitter,
    required this.avgPacketLoss,
    required this.avgSignalStrength,
    required this.avgUserRating,
    required this.totalFeedbacks,
  });

  factory NetworkAnalytics.fromJson(Map<String, dynamic> json) {
    return NetworkAnalytics(
      location: json['location'],
      avgLatency: json['avg_latency'].toDouble(),
      avgJitter: json['avg_jitter'].toDouble(),
      avgPacketLoss: json['avg_packet_loss'].toDouble(),
      avgSignalStrength: json['avg_signal_strength'].toDouble(),
      avgUserRating: json['avg_user_rating'].toDouble(),
      totalFeedbacks: json['total_feedbacks'],
    );
  }
}