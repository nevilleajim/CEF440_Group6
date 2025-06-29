import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/carrier_change.dart';

class CarrierTrackingService extends ChangeNotifier {
  static final CarrierTrackingService _instance = CarrierTrackingService._internal();
  factory CarrierTrackingService() => _instance;
  CarrierTrackingService._internal();

  List<CarrierChange> _carrierChanges = [];
  String? _lastKnownCarrier;
  DateTime? _lastCarrierCheckTime;
  bool _isInitialized = false;

  // Getters
  List<CarrierChange> get carrierChanges => List.unmodifiable(_carrierChanges);
  String? get lastKnownCarrier => _lastKnownCarrier;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadPersistedData();
    _isInitialized = true;
    debugPrint('✅ CarrierTrackingService initialized with ${_carrierChanges.length} changes');
  }

  Future<void> trackCarrierChange({
    required String newCarrier,
    required String networkType,
    int? signalStrength,
    String changeReason = 'automatic',
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
  }) async {
    try {
      // Skip if it's the same carrier
      if (_lastKnownCarrier == newCarrier) {
        return;
      }

      // Skip if we just checked recently (within 30 seconds) to avoid spam
      if (_lastCarrierCheckTime != null && 
          DateTime.now().difference(_lastCarrierCheckTime!).inSeconds < 30) {
        return;
      }

      final previousCarrier = _lastKnownCarrier ?? 'Unknown';
      
      final carrierChange = CarrierChange(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        previousCarrier: previousCarrier,
        newCarrier: newCarrier,
        latitude: latitude,
        longitude: longitude,
        address: address,
        city: city,
        country: country,
        networkType: networkType,
        signalStrength: signalStrength,
        changeReason: changeReason,
        isSynced: false,
      );

      _carrierChanges.insert(0, carrierChange); // Insert at beginning for newest first
      _lastKnownCarrier = newCarrier;
      _lastCarrierCheckTime = DateTime.now();

      // Keep only last 1000 changes to prevent memory issues
      if (_carrierChanges.length > 1000) {
        _carrierChanges = _carrierChanges.take(1000).toList();
      }

      // Persist the data
      await _persistCarrierChanges();
      notifyListeners();

      debugPrint('📱 Carrier change tracked: $previousCarrier → $newCarrier ($changeReason)');
      debugPrint('📍 Location: ${city ?? 'Unknown'}, ${country ?? 'Unknown'}');
    } catch (e) {
      debugPrint('❌ Error tracking carrier change: $e');
    }
  }

  // Get carrier changes for a specific time period
  List<CarrierChange> getCarrierChangesInPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _carrierChanges.where((change) =>
        change.timestamp.isAfter(startDate) && 
        change.timestamp.isBefore(endDate)
    ).toList();
  }

  // Get carrier changes by location (within radius)
  List<CarrierChange> getCarrierChangesByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) {
    return _carrierChanges.where((change) {
      if (change.latitude == null || change.longitude == null) return false;
      
      final distance = _calculateDistance(
        latitude, longitude,
        change.latitude!, change.longitude!,
      );
      return distance <= radiusKm;
    }).toList();
  }

  // Get carrier usage statistics
  Map<String, dynamic> getCarrierStatistics() {
    if (_carrierChanges.isEmpty) {
      return {
        'totalChanges': 0,
        'uniqueCarriers': 0,
        'mostUsedCarrier': 'Unknown',
        'averageChangesPerDay': 0.0,
        'carrierUsage': <String, int>{},
        'changeReasons': <String, int>{},
      };
    }

    // Count carrier usage
    final carrierUsage = <String, int>{};
    final changeReasons = <String, int>{};
    
    for (final change in _carrierChanges) {
      carrierUsage[change.newCarrier] = (carrierUsage[change.newCarrier] ?? 0) + 1;
      changeReasons[change.changeReason] = (changeReasons[change.changeReason] ?? 0) + 1;
    }

    // Find most used carrier
    String mostUsedCarrier = 'Unknown';
    int maxUsage = 0;
    carrierUsage.forEach((carrier, usage) {
      if (usage > maxUsage) {
        maxUsage = usage;
        mostUsedCarrier = carrier;
      }
    });

    // Calculate average changes per day
    final firstChange = _carrierChanges.last.timestamp; // Last because list is newest first
    final lastChange = _carrierChanges.first.timestamp;
    final daysDifference = lastChange.difference(firstChange).inDays;
    final averageChangesPerDay = daysDifference > 0 
        ? _carrierChanges.length / daysDifference 
        : 0.0;

    return {
      'totalChanges': _carrierChanges.length,
      'uniqueCarriers': carrierUsage.keys.length,
      'mostUsedCarrier': mostUsedCarrier,
      'averageChangesPerDay': averageChangesPerDay,
      'carrierUsage': carrierUsage,
      'changeReasons': changeReasons,
    };
  }

  // Get recent carrier changes (last 24 hours)
  List<CarrierChange> getRecentCarrierChanges() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return getCarrierChangesInPeriod(
      startDate: yesterday,
      endDate: DateTime.now(),
    );
  }

  // Get carrier changes by city
  Map<String, List<CarrierChange>> getCarrierChangesByCity() {
    final changesByCity = <String, List<CarrierChange>>{};
    
    for (final change in _carrierChanges) {
      final city = change.city ?? 'Unknown';
      if (!changesByCity.containsKey(city)) {
        changesByCity[city] = [];
      }
      changesByCity[city]!.add(change);
    }
    
    return changesByCity;
  }

  // Calculate distance between two points in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Mark carrier changes as synced
  Future<void> markCarrierChangesAsSynced(List<String> ids) async {
    for (String id in ids) {
      final index = _carrierChanges.indexWhere((change) => change.id == id);
      if (index != -1) {
        _carrierChanges[index] = _carrierChanges[index].copyWith(isSynced: true);
      }
    }
    
    await _persistCarrierChanges();
    notifyListeners();
    debugPrint('✅ Marked ${ids.length} carrier changes as synced');
  }

  // Get unsynced carrier changes
  List<CarrierChange> getUnsyncedCarrierChanges() {
    return _carrierChanges.where((change) => !change.isSynced).toList();
  }

  // Clear all carrier change data
  Future<void> clearAllData() async {
    _carrierChanges.clear();
    _lastKnownCarrier = null;
    _lastCarrierCheckTime = null;
    await _clearPersistedData();
    notifyListeners();
    debugPrint('🗑️ All carrier change data cleared');
  }

  // Persist carrier changes to SharedPreferences
  Future<void> _persistCarrierChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _carrierChanges.map((change) => change.toMap()).toList();
      await prefs.setString('carrier_changes', jsonEncode(jsonList));
      await prefs.setString('last_known_carrier', _lastKnownCarrier ?? '');
      
      if (_lastCarrierCheckTime != null) {
        await prefs.setInt('last_carrier_check_time', _lastCarrierCheckTime!.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('❌ Error persisting carrier changes: $e');
    }
  }

  // Load persisted carrier changes from SharedPreferences
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load carrier changes
      final carrierChangesJson = prefs.getString('carrier_changes');
      if (carrierChangesJson != null) {
        final List<dynamic> jsonList = jsonDecode(carrierChangesJson);
        _carrierChanges = jsonList
            .map((json) => CarrierChange.fromMap(json as Map<String, dynamic>))
            .toList();
        debugPrint('📱 Loaded ${_carrierChanges.length} carrier changes from storage');
      }
      
      // Load last known carrier
      _lastKnownCarrier = prefs.getString('last_known_carrier');
      if (_lastKnownCarrier?.isEmpty == true) {
        _lastKnownCarrier = null;
      }
      
      // Load last check time
      final lastCheckTime = prefs.getInt('last_carrier_check_time');
      if (lastCheckTime != null) {
        _lastCarrierCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheckTime);
      }
      
    } catch (e) {
      debugPrint('❌ Error loading persisted carrier changes: $e');
    }
  }

  // Clear persisted data
  Future<void> _clearPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('carrier_changes');
      await prefs.remove('last_known_carrier');
      await prefs.remove('last_carrier_check_time');
      debugPrint('🗑️ Cleared persisted carrier change data');
    } catch (e) {
      debugPrint('❌ Error clearing persisted carrier change data: $e');
    }
  }
}
