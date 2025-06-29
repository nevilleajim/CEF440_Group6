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
  final String? city;
  final String? country;
  final String? address;
  final bool isSynced;
  
  // Add these missing fields that were showing as NULL
  final String? issueType;
  final String? networkType;
  final int? signalStrength;
  final double? downloadSpeed;
  final double? uploadSpeed;
  final int? latency;

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
    this.city,
    this.country,
    this.address,
    required this.isSynced,
    this.issueType,
    this.networkType,
    this.signalStrength,
    this.downloadSpeed,
    this.uploadSpeed,
    this.latency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'overall_satisfaction': overallSatisfaction,
      'response_time': responseTime,
      'usability': usability,
      'comments': comments,
      'network_metrics_id': networkMetricsId,
      'latitude': latitude,
      'longitude': longitude,
      'carrier': carrier,
      'city': city,
      'country': country,
      'address': address,
      'is_synced': isSynced ? 1 : 0,
      'issue_type': issueType,
      'network_type': networkType,
      'signal_strength': signalStrength,
      'download_speed': downloadSpeed,
      'upload_speed': uploadSpeed,
      'latency': latency,
    };
  }

  factory FeedbackData.fromMap(Map<String, dynamic> map) {
    return FeedbackData(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      overallSatisfaction: map['overall_satisfaction'],
      responseTime: map['response_time'],
      usability: map['usability'],
      comments: map['comments'],
      networkMetricsId: map['network_metrics_id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      carrier: map['carrier'],
      city: map['city'],
      country: map['country'],
      address: map['address'],
      isSynced: map['is_synced'] == 1,
      issueType: map['issue_type'],
      networkType: map['network_type'],
      signalStrength: map['signal_strength'],
      downloadSpeed: map['download_speed'],
      uploadSpeed: map['upload_speed'],
      latency: map['latency'],
    );
  }

  FeedbackData copyWith({
    String? id,
    DateTime? timestamp,
    int? overallSatisfaction,
    int? responseTime,
    int? usability,
    String? comments,
    String? networkMetricsId,
    double? latitude,
    double? longitude,
    String? carrier,
    String? city,
    String? country,
    String? address,
    bool? isSynced,
    String? issueType,
    String? networkType,
    int? signalStrength,
    double? downloadSpeed,
    double? uploadSpeed,
    int? latency,
  }) {
    return FeedbackData(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      overallSatisfaction: overallSatisfaction ?? this.overallSatisfaction,
      responseTime: responseTime ?? this.responseTime,
      usability: usability ?? this.usability,
      comments: comments ?? this.comments,
      networkMetricsId: networkMetricsId ?? this.networkMetricsId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      carrier: carrier ?? this.carrier,
      city: city ?? this.city,
      country: country ?? this.country,
      address: address ?? this.address,
      isSynced: isSynced ?? this.isSynced,
      issueType: issueType ?? this.issueType,
      networkType: networkType ?? this.networkType,
      signalStrength: signalStrength ?? this.signalStrength,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      latency: latency ?? this.latency,
    );
  }
}
