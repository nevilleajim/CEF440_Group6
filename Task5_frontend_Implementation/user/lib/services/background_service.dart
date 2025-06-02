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

      // Get location data
      double latitude = 0.0;
      double longitude = 0.0;
      String? address;
      String? city;
      String? country;
      
    try {
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocationWithAddress(); // Changed method name
      latitude = locationData['latitude'] ?? 0.0;
      longitude = locationData['longitude'] ?? 0.0;
      address = locationData['address'];
      city = locationData['city'];
      country = locationData['country'];
    } catch (e) {
      print('⚠️ Location error: $e');
    }
      // Collect network metrics
      await _networkService!.collectNetworkMetrics();
      
      NetworkMetrics? latestMetrics;
      final completer = Completer<NetworkMetrics>();
      
      StreamSubscription? subscription;
      subscription = _networkService!.metricsStream.listen((metrics) {
        if (!completer.isCompleted) {
          completer.complete(metrics);
        }
        subscription?.cancel();
      });
      
      try {
        final rawMetrics = await completer.future.timeout(const Duration(seconds: 30));
        
        // Create NetworkMetrics with proper structure
        latestMetrics = NetworkMetrics(
          id: _uuid.v4(),
          timestamp: DateTime.now(),
          networkType: rawMetrics.networkType,
          carrier: rawMetrics.carrier, // Changed from rawMetrics.provider
          signalStrength: rawMetrics.signalStrength,
          latitude: latitude,
          longitude: longitude,
          address: address,
          city: city,
          country: country,
          downloadSpeed: rawMetrics.downloadSpeed,
          uploadSpeed: rawMetrics.uploadSpeed,
          latency: rawMetrics.latency,
          jitter: rawMetrics.jitter,
          packetLoss: 0.0, // Set default or calculate if available
        );
      } catch (e) {
        subscription.cancel();
        print('⚠️ Timeout waiting for metrics: $e');
        
        // Create fallback metrics
        latestMetrics = NetworkMetrics(
          id: _uuid.v4(),
          timestamp: DateTime.now(),
          networkType: 'Unknown',
          carrier: 'Unknown',
          signalStrength: 0,
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
      }

      print('📶 Collected metrics: ${latestMetrics.networkType}');

      await _dbService!.insertNetworkMetrics(latestMetrics);
      print('💾 Saved metrics with ID: ${latestMetrics.id}');

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Active',
          content: '${latestMetrics.networkType} | ${(latestMetrics.downloadSpeed ?? 0).toStringAsFixed(1)} Mbps ↓ | ${(latestMetrics.uploadSpeed ?? 0).toStringAsFixed(1)} Mbps ↑',
        );
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
}