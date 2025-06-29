//background_service.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/network_metrics.dart';
import 'location_service.dart';
import 'database_service.dart';
import 'network_service.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const String notificationChannelId = 'network_monitor_channel';
  static const int _syncInterval = 15; // minutes
  static Timer? _syncTimer;
  static Timer? _metricsTimer;
  static bool _isInitialized = false;
  static DatabaseService? _dbService;
  static NetworkService? _networkService;
  static StorageService? _storageService;
  static final _uuid = Uuid();

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await _createNotificationChannel();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Network Monitor',
        initialNotificationContent: 'Initializing network monitoring...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  Future<void> _createNotificationChannel() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Network Monitor Service',
      description: 'This channel is used for network monitoring service notifications.',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    print('🚀 Background service started');

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Network Monitor',
        content: 'Starting up...',
      );
    }

    await Future.delayed(const Duration(seconds: 3));

    try {
      await _initializeServices(service);
      await _setupTimers(service);
      _setupMessageHandlers(service);

      print('✅ Background service initialized successfully');
    } catch (e) {
      print('❌ Critical error starting background service: $e');

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Error',
          content: 'Startup failed: ${e.toString().length > 30 ? '${e.toString().substring(0, 30)}...' : e.toString()}',
        );
      }

      _retryInitialization(service);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _initializeServices(ServiceInstance service) async {
    print('🔧 Initializing services...');

    _dbService = DatabaseService();
    await _dbService!.database;
    
    _storageService = StorageService();
    await _storageService!.initialize();

    _networkService = NetworkService();
    _networkService!.startMonitoring();

    _isInitialized = true;

    if (service is AndroidServiceInstance) {
      final metricsCount = await _getMetricsCount();
      service.setForegroundNotificationInfo(
        title: 'Network Monitor',
        content: 'Monitoring active - $metricsCount records',
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _setupTimers(ServiceInstance service) async {
    print('⏰ Setting up monitoring timers...');

    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      await _collectMetrics(service);
    });

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: _syncInterval), (timer) async {
      await _performSync(service);
    });

    print('⏰ Timers configured successfully');
  }

  @pragma('vm:entry-point')
  static void _setupMessageHandlers(ServiceInstance service) {
    service.on('stopService').listen((event) {
      print('🛑 Stop service requested');
      _metricsTimer?.cancel();
      _syncTimer?.cancel();
      _networkService?.stopMonitoring();
      service.stopSelf();
    });

    service.on('clearData').listen((event) async {
      try {
        await _dbService?.resetDatabase();
        _storageService?.clearAllData();
        print('🗑️ All data cleared');

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Network Monitor Active',
            content: 'Data cleared. Starting fresh...',
          );
        }
      } catch (e) {
        print('❌ Error clearing data: $e');
      }
    });

    service.on('collectNow').listen((event) async {
      print('🔄 Manual collection triggered');
      await _collectMetrics(service);
    });

    print('📡 Message handlers configured');
  }

  @pragma('vm:entry-point')
  static Future<void> _collectMetrics(ServiceInstance service) async {
    if (!_isInitialized || _dbService == null || _networkService == null) {
      print('⚠️ Services not initialized, skipping collection');
      return;
    }

    try {
      print('📊 Starting metrics collection cycle...');

      // Get location data first
      double latitude = 0.0;
      double longitude = 0.0;
      String? address;
      String? city;
      String? country;
      
      try {
        final locationService = LocationService();
        final locationData = await locationService.getCurrentLocationWithAddress();
        latitude = locationData['latitude'] ?? 0.0;
        longitude = locationData['longitude'] ?? 0.0;
        address = locationData['address'];
        city = locationData['city'];
        country = locationData['country'];
        print('📍 Location: $city, $country');
      } catch (e) {
        print('⚠️ Location error: $e');
      }
      
      // Trigger network metrics collection
      await _networkService!.collectNetworkMetrics();
      
      // Wait for the metrics to be collected and get the latest
      await Future.delayed(Duration(seconds: 5)); // Give time for collection
      
      final currentMetrics = _networkService!.currentMetrics;
      
      if (currentMetrics != null) {
        // Create a new metrics object with updated location data
        final metrics = NetworkMetrics(
          id: _uuid.v4(),
          timestamp: DateTime.now(),
          networkType: currentMetrics.networkType,
          carrier: currentMetrics.carrier,
          signalStrength: currentMetrics.signalStrength,
          latitude: latitude,
          longitude: longitude,
          address: address,
          city: city,
          country: country,
          downloadSpeed: currentMetrics.downloadSpeed,
          uploadSpeed: currentMetrics.uploadSpeed,
          latency: currentMetrics.latency,
          jitter: currentMetrics.jitter,
          packetLoss: currentMetrics.packetLoss,
        );
        
        print('📶 Collected metrics: ${metrics.networkType} | ${metrics.carrier}');
        print('📶 Signal: ${metrics.signalStrength} dBm | Latency: ${metrics.latency} ms');
        print('📶 Download: ${metrics.downloadSpeed?.toStringAsFixed(2)} Mbps | Upload: ${metrics.uploadSpeed?.toStringAsFixed(2)} Mbps');
        
        // Save to database
        await _dbService!.insertNetworkMetrics(metrics);
        print('💾 Saved metrics with ID: ${metrics.id}');
        
        // Check if metrics are below threshold and notify user if needed
        _checkMetricsThresholds(metrics, service);
        
        // Update notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Network Monitor Active',
            content: '${metrics.networkType} | ${metrics.carrier} | ${(metrics.downloadSpeed ?? 0).toStringAsFixed(1)} Mbps ↓',
          );
        }
      } else {
        print('⚠️ No metrics collected, creating fallback entry');
        
        // Create fallback metrics
        final fallbackMetrics = NetworkMetrics(
          id: _uuid.v4(),
          timestamp: DateTime.now(),
          networkType: 'Unknown',
          carrier: 'Unknown',
          signalStrength: -100,
          latitude: latitude,
          longitude: longitude,
          address: address,
          city: city,
          country: country,
          downloadSpeed: 0.0,
          uploadSpeed: 0.0,
          latency: 0,
          jitter: 0.0,
          packetLoss: 0.0,
        );
        
        await _dbService!.insertNetworkMetrics(fallbackMetrics);
      }

    } catch (e) {
      print('❌ Error collecting metrics: $e');
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Error',
          content: 'Error collecting metrics',
        );
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _performSync(ServiceInstance service) async {
    if (!_isInitialized || _dbService == null) {
      print('⚠️ Services not initialized, skipping sync');
      return;
    }

    print('🔄 Starting data sync cycle...');
    try {
      final allMetrics = await _dbService!.getNetworkMetrics();
      print('🔄 Found ${allMetrics.length} total records');

      if (allMetrics.isNotEmpty) {
        // Here you would implement your sync logic with a remote server
        await Future.delayed(const Duration(seconds: 2));
        print('✅ Sync completed for ${allMetrics.length} records');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_sync', DateTime.now().toIso8601String());
        await prefs.setInt('last_sync_count', allMetrics.length);
      }

      if (service is AndroidServiceInstance) {
        final totalCount = await _getMetricsCount();
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Active',
          content: 'Records: $totalCount | Last sync: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        );
      }
    } catch (e) {
      print('❌ Sync error: $e');
    }
  }

  @pragma('vm:entry-point')
  static void _retryInitialization(ServiceInstance service) {
    print('🔄 Setting up retry timer...');

    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_isInitialized) {
        timer.cancel();
        return;
      }

      print('🔄 Retrying initialization...');
      try {
        await _initializeServices(service);
        await _setupTimers(service);
        timer.cancel();
        print('✅ Retry successful');
      } catch (e) {
        print('⚠️ Retry failed: $e');

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Network Monitor (Retrying)',
            content: 'Initialization retry failed - will try again...',
          );
        }
      }
    });
  }

  static Future<int> _getMetricsCount() async {
    try {
      final metrics = await _dbService!.getNetworkMetrics();
      return metrics.length;
    } catch (e) {
      print('Error getting metrics count: $e');
      return 0;
    }
  }

  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    _metricsTimer?.cancel();
    _syncTimer?.cancel();
    _networkService?.stopMonitoring();

    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  Future<void> clearAllData() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('clearData');
    } else {
      final dbService = DatabaseService();
      await dbService.resetDatabase();
      
      final storageService = StorageService();
      await storageService.initialize();
      storageService.clearAllData();
    }
  }

  Future<Map<String, dynamic>> getServiceStatus() async {
    final service = FlutterBackgroundService();
    final prefs = await SharedPreferences.getInstance();

    try {
      final totalMetrics = await _getMetricsCount();

      return {
        'isRunning': await service.isRunning(),
        'isInitialized': _isInitialized,
        'totalMetrics': totalMetrics,
        'lastSync': prefs.getString('last_sync'),
        'lastSyncCount': prefs.getInt('last_sync_count'),
      };
    } catch (e) {
      return {
        'isRunning': await service.isRunning(),
        'isInitialized': _isInitialized,
        'error': e.toString(),
        'lastSync': prefs.getString('last_sync'),
      };
    }
  }

  @pragma('vm:entry-point')
  static void _checkMetricsThresholds(NetworkMetrics metrics, ServiceInstance service) async {
    try {
      // Calculate a comprehensive network quality score based on all metrics
      int qualityScore = _calculateNetworkQualityScore(metrics);
      
      // Define thresholds for different network issues
      bool hasSignalIssue = metrics.signalStrength < -95; // Very poor signal
      bool hasLatencyIssue = metrics.latency != null && metrics.latency! > 150; // High latency
      bool hasSpeedIssue = metrics.downloadSpeed != null && metrics.downloadSpeed! < 1.0; // Very slow speed
      bool hasJitterIssue = metrics.jitter != null && metrics.jitter! > 30; // High jitter
      bool hasPacketLossIssue = metrics.packetLoss != null && metrics.packetLoss! > 5.0; // Significant packet loss
      
      // Track which issues were detected
      List<String> detectedIssues = [];
      
      if (hasSignalIssue) detectedIssues.add("Poor signal strength (${metrics.signalStrength} dBm)");
      if (hasLatencyIssue) detectedIssues.add("High latency (${metrics.latency} ms)");
      if (hasSpeedIssue) detectedIssues.add("Slow download speed (${metrics.downloadSpeed?.toStringAsFixed(1)} Mbps)");
      if (hasJitterIssue) detectedIssues.add("High jitter (${metrics.jitter?.toStringAsFixed(1)} ms)");
      if (hasPacketLossIssue) detectedIssues.add("Packet loss (${metrics.packetLoss?.toStringAsFixed(1)}%)");
      
      // Only show notification if quality score is below threshold OR specific critical issues are detected
      if (qualityScore < 60 || detectedIssues.isNotEmpty) {
        String notificationTitle;
        String notificationBody;
        
        if (qualityScore < 30) {
          notificationTitle = 'Very Poor Network Quality Detected';
          notificationBody = 'Multiple network issues detected: ${detectedIssues.join(", ")}. Please share your experience.';
        } else if (qualityScore < 60) {
          notificationTitle = 'Poor Network Quality Detected';
          notificationBody = 'Network issues detected: ${detectedIssues.isNotEmpty ? detectedIssues.join(", ") : "Overall poor performance"}. How is your experience?';
        } else {
          notificationTitle = 'Network Issue Detected';
          notificationBody = 'Issue detected: ${detectedIssues.first}. Please provide feedback.';
        }
        
        print('📢 Triggering feedback notification: $notificationTitle');
        print('📊 Network quality score: $qualityScore/100');
        print('📊 Detected issues: ${detectedIssues.join(", ")}');
        
        await _showFeedbackNotification(notificationTitle, notificationBody);
      }
    } catch (e) {
      print('❌ Error checking metrics thresholds: $e');
    }
  }
  
  @pragma('vm:entry-point')
  static int _calculateNetworkQualityScore(NetworkMetrics metrics) {
    // Start with a perfect score of 100
    int score = 100;
    
    // Signal strength evaluation (weight: 25%)
    // -70 dBm or better is excellent, -110 dBm or worse is terrible
    if (metrics.signalStrength >= -70) {
      // Excellent signal
    } else if (metrics.signalStrength >= -85) {
      score -= 5; // Good signal
    } else if (metrics.signalStrength >= -95) {
      score -= 15; // Fair signal
    } else if (metrics.signalStrength >= -105) {
      score -= 20; // Poor signal
    } else {
      score -= 25; // Very poor signal
    }
      
    // Latency evaluation (weight: 20%)
    if (metrics.latency != null) {
      if (metrics.latency! <= 30) {
        // Excellent latency
      } else if (metrics.latency! <= 60) {
        score -= 5; // Good latency
      } else if (metrics.latency! <= 100) {
        score -= 10; // Fair latency
      } else if (metrics.latency! <= 150) {
        score -= 15; // Poor latency
      } else {
        score -= 20; // Very poor latency
      }
    } else {
      score -= 20; // Unknown latency
    }
    
    // Download speed evaluation (weight: 20%)
    if (metrics.downloadSpeed != null) {
      if (metrics.downloadSpeed! >= 25) {
        // Excellent speed
      } else if (metrics.downloadSpeed! >= 10) {
        score -= 5; // Good speed
      } else if (metrics.downloadSpeed! >= 5) {
        score -= 10; // Fair speed
      } else if (metrics.downloadSpeed! >= 1) {
        score -= 15; // Poor speed
      } else {
        score -= 20; // Very poor speed
      }
    } else {
      score -= 20; // Unknown download speed
    }
    
    // Upload speed evaluation (weight: 10%)
    if (metrics.uploadSpeed != null) {
      if (metrics.uploadSpeed! >= 5) {
        // Excellent upload
      } else if (metrics.uploadSpeed! >= 2) {
        score -= 2; // Good upload
      } else if (metrics.uploadSpeed! >= 1) {
        score -= 5; // Fair upload
      } else if (metrics.uploadSpeed! >= 0.5) {
        score -= 7; // Poor upload
      } else {
        score -= 10; // Very poor upload
      }
    } else {
      score -= 10; // Unknown upload speed
    }
    
    // Jitter evaluation (weight: 15%)
    if (metrics.jitter != null) {
      if (metrics.jitter! <= 5) {
        // Excellent stability
      } else if (metrics.jitter! <= 15) {
        score -= 5; // Good stability
      } else if (metrics.jitter! <= 30) {
        score -= 10; // Fair stability
      } else {
        score -= 15; // Poor stability
      }
    } else {
      score -= 15; // Unknown jitter
    }
    
    // Packet loss evaluation (weight: 10%)
    if (metrics.packetLoss != null) {
      if (metrics.packetLoss! <= 0.5) {
        // Excellent reliability
      } else if (metrics.packetLoss! <= 2) {
        score -= 2; // Good reliability
      } else if (metrics.packetLoss! <= 5) {
        score -= 5; // Fair reliability
      } else if (metrics.packetLoss! <= 10) {
        score -= 7; // Poor reliability
      } else {
        score -= 10; // Very poor reliability
      }
    } else {
      score -= 10; // Unknown packet loss
    }
    
    return score;
  }

  @pragma('vm:entry-point')
  static Future<void> _showFeedbackNotification(String title, String body) async {
    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'feedback_channel',
        'Feedback Notifications',
        channelDescription: 'Notifications to request user feedback',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      
      await flutterLocalNotificationsPlugin.show(
        // Use a unique ID based on time to avoid overwriting
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: 'feedback',
      );
      
      print('📢 Feedback notification shown: $title');
    } catch (e) {
      print('❌ Error showing feedback notification: $e');
    }
  }
}
