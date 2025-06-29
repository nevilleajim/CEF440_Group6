// models/feedback.dart
class Feedback {
  final String id;
  final DateTime timestamp;
  final String location;
  final double jitter;
  final double latency;
  final double packetLoss;
  final double signalStrength;
  final int userRating;
  final String comments;
  final String description;
  final double latitude;
  final double longitude;

  Feedback({
    required this.id,
    required this.timestamp,
    required this.location,
    required this.jitter,
    required this.latency,
    required this.packetLoss,
    required this.signalStrength,
    required this.userRating,
    required this.comments,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      jitter: json['jitter'].toDouble(),
      latency: json['latency'].toDouble(),
      packetLoss: json['packet_loss'].toDouble(),
      signalStrength: json['signal_strength'].toDouble(),
      userRating: json['user_rating'],
      comments: json['comments'] ?? '',
      description: json['description'] ?? '',
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}