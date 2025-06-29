
enum CarrierChangeReason {
  manual,      // User manually switched carriers
  roaming,     // Device switched due to roaming
  location,    // Location-based carrier change
  automatic,   // Network-initiated change
  unknown      // Reason couldn't be determined
}

class CarrierChange {
  final String id;
  final DateTime timestamp;
  final String previousCarrier;
  final String newCarrier;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final String? country;
  final String networkType;
  final int? signalStrength;
  final String changeReason;
  final bool isSynced;

  CarrierChange({
    required this.id,
    required this.timestamp,
    required this.previousCarrier,
    required this.newCarrier,
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.country,
    required this.networkType,
    this.signalStrength,
    required this.changeReason,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'previousCarrier': previousCarrier,
      'newCarrier': newCarrier,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
      'networkType': networkType,
      'signalStrength': signalStrength,
      'changeReason': changeReason,
      'isSynced': isSynced,
    };
  }

  factory CarrierChange.fromMap(Map<String, dynamic> map) {
    return CarrierChange(
      id: map['id'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      previousCarrier: map['previousCarrier'] ?? '',
      newCarrier: map['newCarrier'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
      city: map['city'],
      country: map['country'],
      networkType: map['networkType'] ?? '',
      signalStrength: map['signalStrength'],
      changeReason: map['changeReason'] ?? 'automatic',
      isSynced: map['isSynced'] ?? false,
    );
  }

  CarrierChange copyWith({
    String? id,
    DateTime? timestamp,
    String? previousCarrier,
    String? newCarrier,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
    String? networkType,
    int? signalStrength,
    String? changeReason,
    bool? isSynced,
  }) {
    return CarrierChange(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      previousCarrier: previousCarrier ?? this.previousCarrier,
      newCarrier: newCarrier ?? this.newCarrier,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      networkType: networkType ?? this.networkType,
      signalStrength: signalStrength ?? this.signalStrength,
      changeReason: changeReason ?? this.changeReason,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get reasonText {
    switch (changeReason) {
      case 'manual':
        return 'Manual Switch';
      case 'roaming':
        return 'Roaming';
      case 'location':
        return 'Location Change';
      case 'automatic':
        return 'Network Initiated';
      case 'unknown':
      default:
        return 'Unknown';
    }
  }

  String get signalQuality {
    if (signalStrength != null) {
      if (signalStrength! >= -70) return 'Excellent';
      if (signalStrength! >= -85) return 'Good';
      if (signalStrength! >= -100) return 'Fair';
      return 'Poor';
    } else {
      return 'Unknown';
    }
  }
}
