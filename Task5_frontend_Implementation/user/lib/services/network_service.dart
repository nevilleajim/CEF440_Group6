// services/network_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import '../models/network_metrics.dart';
import 'location_service.dart';
import 'database_service.dart';

class NetworkService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final LocationService _locationService = LocationService();
  final DatabaseService _dbService = DatabaseService();
  static const MethodChannel _channel = MethodChannel('network_info_channel');
  
  NetworkMetrics? _currentMetrics;
  Timer? _metricsTimer;
  
  // Stream controller for metrics
  final StreamController<NetworkMetrics> _metricsStreamController = 
      StreamController<NetworkMetrics>.broadcast();
  
  NetworkMetrics? get currentMetrics => _currentMetrics;
  
  // Stream getter for listening to metrics updates
  Stream<NetworkMetrics> get metricsStream => _metricsStreamController.stream;

  NetworkService() {
    // Don't start automatically - let startMonitoring() handle it
    // _startPeriodicCollection();
  }

  // Method to start monitoring - this is what your widgets are calling
  void startMonitoring() {
    if (_metricsTimer == null || !_metricsTimer!.isActive) {
      _startPeriodicCollection();
      // Collect initial metrics immediately
      collectNetworkMetrics();
    }
  }

  void _startPeriodicCollection() {
    _metricsTimer = Timer.periodic(Duration(seconds: 30), (_) { // Increased interval to reduce load
      collectNetworkMetrics();
    });
  }

  Future<void> collectNetworkMetrics() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final locationData = await _locationService.getCurrentLocationWithAddress();
      
      String networkType = _getNetworkType(connectivityResult);
      String carrier = await _getCarrier();
      int signalStrength = await _getSignalStrength();
      
      final metrics = NetworkMetrics(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        networkType: networkType,
        carrier: carrier,
        signalStrength: signalStrength,
        latitude: locationData['latitude'] ?? 0.0,
        longitude: locationData['longitude'] ?? 0.0,
        address: locationData['address'],
        city: locationData['city'],
        country: locationData['country'],
        latency: await _measureLatency(),
        jitter: await _measureJitter(),
        packetLoss: await _measurePacketLoss(),
      );

      _currentMetrics = metrics;
      await _dbService.insertNetworkMetrics(metrics);
      
      // Notify both the stream and ChangeNotifier listeners
      _metricsStreamController.add(metrics);
      notifyListeners();
      
      debugPrint('Network metrics collected successfully: ${metrics.carrier} - ${metrics.address}');
    } catch (e) {
      debugPrint('Error collecting network metrics: $e');
      // Continue operation even if some metrics fail
      notifyListeners();
    }
  }

  String _getNetworkType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'None';
    }
  }

  Future<String> _getCarrier() async {
    try {
      if (Platform.isAndroid) {
        // Try to get carrier name via method channel
        try {
          final String? carrierName = await _channel.invokeMethod('getCarrierName');
          if (carrierName != null && carrierName.isNotEmpty) {
            return _normalizeCarrierName(carrierName);
          }
        } on MissingPluginException {
          debugPrint('Carrier method channel not implemented, using fallback detection');
          // Fallback: Try to detect carrier from network info
          return await _detectCarrierFromNetwork();
        } catch (e) {
          debugPrint('Method channel error: $e');
          return await _detectCarrierFromNetwork();
        }
      }
      return 'Unknown';
    } catch (e) {
      debugPrint('Error getting carrier: $e');
      return 'Unknown';
    }
  }

  // Fallback method to detect carrier without native code
  Future<String> _detectCarrierFromNetwork() async {
    try {
      // This is a simplified detection based on common patterns
      // You might need to implement more sophisticated detection
      
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.mobile) {
        // Try to detect based on IP or other network characteristics
        // This is a basic implementation - you might want to enhance it
        
        // For Cameroon, common carriers
        List<String> commonCarriers = ['MTN', 'Orange', 'Camtel', 'Nexttel'];
        
        // Random selection for demo - replace with actual detection logic
        final random = Random();
        return commonCarriers[random.nextInt(commonCarriers.length)];
      }
      
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _normalizeCarrierName(String carrierName) {
    String normalized = carrierName.toUpperCase().trim();
    
    if (normalized.contains('MTN')) {
      return 'MTN';
    } else if (normalized.contains('ORANGE')) {
      return 'Orange';
    } else if (normalized.contains('CAMTEL') || normalized.contains('NEXTTEL')) {
      return 'Camtel';
    }
    
    return carrierName;
  }

  Future<int> _getSignalStrength() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.mobile) {
        // Try to get actual signal strength if possible
        try {
          final int? signalStrength = await _channel.invokeMethod('getSignalStrength');
          if (signalStrength != null) {
            return signalStrength;
          }
        } on MissingPluginException {
          // Fallback to simulation
        } catch (e) {
          debugPrint('Signal strength method channel error: $e');
        }
        
        // Simulate realistic mobile signal strength values
        return -50 - Random().nextInt(50); // -50 to -100 dBm
      } else if (connectivityResult == ConnectivityResult.wifi) {
        // WiFi signal strength simulation
        return -30 - Random().nextInt(40); // -30 to -70 dBm
      }
      
      return -90; // Default weak signal
    } catch (e) {
      debugPrint('Error getting signal strength: $e');
      return -90;
    }
  }

  Future<int?> _measureLatency() async {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 5));
      stopwatch.stop();
      
      if (result.isNotEmpty) {
        return stopwatch.elapsedMilliseconds;
      }
    } catch (e) {
      debugPrint('Latency measurement failed: $e');
    }
    return null;
  }

  Future<double?> _measureJitter() async {
    List<int> latencies = [];
    
    for (int i = 0; i < 3; i++) { // Reduced from 5 to 3 for faster execution
      final latency = await _measureLatency();
      if (latency != null) {
        latencies.add(latency);
      }
      await Future.delayed(Duration(milliseconds: 200));
    }
    
    if (latencies.length >= 2) {
      double sum = 0;
      for (int i = 1; i < latencies.length; i++) {
        sum += (latencies[i] - latencies[i-1]).abs();
      }
      return sum / (latencies.length - 1);
    }
    
    return null;
  }

  Future<double?> _measurePacketLoss() async {
    int sent = 5; // Reduced from 10 for faster execution
    int received = 0;
    
    for (int i = 0; i < sent; i++) {
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(Duration(seconds: 2));
        if (result.isNotEmpty) received++;
      } catch (e) {
        // Packet lost
      }
    }
    
    return ((sent - received) / sent) * 100;
  }

  // Method to manually collect metrics (useful for testing)
  Future<void> collectMetricsNow() async {
    await collectNetworkMetrics();
  }

  // Method to check network connectivity
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  // Stop monitoring method
  void stopMonitoring() {
    _metricsTimer?.cancel();
    _metricsTimer = null;
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    _metricsStreamController.close();
    super.dispose();
  }
}