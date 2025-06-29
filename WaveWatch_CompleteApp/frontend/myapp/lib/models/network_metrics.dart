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
  final bool isSynced;
  final String? deviceInfo;
  final String? appVersion;

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
    this.isSynced = false,
    this.deviceInfo,
    this.appVersion,
  });

  Map<String, dynamic> toMap() {
    // Create a map with all fields, ensuring no nulls for required fields
    final map = {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'networkType': networkType,
      'carrier': carrier,
      'signalStrength': signalStrength,
      'latitude': latitude,
      'longitude': longitude,
      'isSynced': isSynced ? 1 : 0,
    };
    
    // Add optional fields only if they're not null
    if (address != null) map['address'] = address as Object;
    if (city != null) map['city'] = city as Object;
    if (country != null) map['country'] = country as Object;
    if (downloadSpeed != null) map['downloadSpeed'] = downloadSpeed as Object;
    if (uploadSpeed != null) map['uploadSpeed'] = uploadSpeed as Object;
    if (latency != null) map['latency'] = latency as Object;
    if (jitter != null) map['jitter'] = jitter as Object;
    if (packetLoss != null) map['packetLoss'] = packetLoss as Object;
    if (deviceInfo != null) map['deviceInfo'] = deviceInfo as Object;
    if (appVersion != null) map['appVersion'] = appVersion as Object;
    
    return map;
  }

  factory NetworkMetrics.fromMap(Map<String, dynamic> map) {
    return NetworkMetrics(
      id: map['id'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      networkType: map['networkType'] ?? 'Unknown',
      carrier: map['carrier'] ?? 'Unknown',
      signalStrength: map['signalStrength'] ?? 0,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'],
      city: map['city'],
      country: map['country'],
      downloadSpeed: map['downloadSpeed']?.toDouble(),
      uploadSpeed: map['uploadSpeed']?.toDouble(),
      latency: map['latency'],
      jitter: map['jitter']?.toDouble(),
      packetLoss: map['packetLoss']?.toDouble(),
      isSynced: (map['isSynced'] ?? 0) == 1,
      deviceInfo: map['deviceInfo'],
      appVersion: map['appVersion'],
    );
  }

  NetworkMetrics copyWith({
    String? id,
    DateTime? timestamp,
    String? networkType,
    String? carrier,
    int? signalStrength,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
    double? downloadSpeed,
    double? uploadSpeed,
    int? latency,
    double? jitter,
    double? packetLoss,
    bool? isSynced,
    String? deviceInfo,
    String? appVersion,
  }) {
    return NetworkMetrics(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      networkType: networkType ?? this.networkType,
      carrier: carrier ?? this.carrier,
      signalStrength: signalStrength ?? this.signalStrength,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      latency: latency ?? this.latency,
      jitter: jitter ?? this.jitter,
      packetLoss: packetLoss ?? this.packetLoss,
      isSynced: isSynced ?? this.isSynced,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
