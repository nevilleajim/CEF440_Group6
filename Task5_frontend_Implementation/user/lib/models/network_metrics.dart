// models/network_metrics.dart
class NetworkMetrics {
  final String id;
  final DateTime timestamp;
  final String networkType;
  final String carrier;
  final int signalStrength;
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;
  final double? downloadSpeed;
  final double? uploadSpeed;
  final int? latency;
  final double? jitter;
  final double? packetLoss;

  NetworkMetrics({
    required this.id,
    required this.timestamp,
    required this.networkType,
    required this.carrier,
    required this.signalStrength,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
    this.downloadSpeed,
    this.uploadSpeed,
    this.latency,
    this.jitter,
    this.packetLoss,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'networkType': networkType,
      'carrier': carrier,
      'signalStrength': signalStrength,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
      'downloadSpeed': downloadSpeed,
      'uploadSpeed': uploadSpeed,
      'latency': latency,
      'jitter': jitter,
      'packetLoss': packetLoss,
    };
  }

  factory NetworkMetrics.fromMap(Map<String, dynamic> map) {
    return NetworkMetrics(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      networkType: map['networkType'],
      carrier: map['carrier'],
      signalStrength: map['signalStrength'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      address: map['address'],
      city: map['city'],
      country: map['country'],
      downloadSpeed: map['downloadSpeed']?.toDouble(),
      uploadSpeed: map['uploadSpeed']?.toDouble(),
      latency: map['latency'],
      jitter: map['jitter']?.toDouble(),
      packetLoss: map['packetLoss']?.toDouble(),
    );
  }
}