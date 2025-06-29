import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'services/reward_service.dart';
import 'services/network_service.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';
import 'services/storage_service.dart';
import 'services/data_usage_service.dart';
import 'services/carrier_tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service first
  final storageService = StorageService();
  await storageService.initialize();

  // Initialize API service
  final apiService = ApiService();
  await apiService.initialize();

  // Initialize background service
  await BackgroundService().initializeService();

  // Initialize rewards service
  final rewardsService = RewardsService();
  await rewardsService.initialize();

  // Initialize network service
  final networkService = NetworkService();

  // Initialize data usage service
  final dataUsageService = DataUsageService();
  await dataUsageService.initialize();

  // Initialize sync service with API service
  final syncService = SyncService();
  
  // Initialize carrier tracking service
  final carrierTrackingService = CarrierTrackingService();
  await carrierTrackingService.initialize();

  runApp(NetworkMonitorApp(
    storageService: storageService,
    rewardsService: rewardsService,
    networkService: networkService,
    apiService: apiService,
    syncService: syncService,
    dataUsageService: dataUsageService,
    carrierTrackingService: carrierTrackingService,
  ));
}

class NetworkMonitorApp extends StatelessWidget {
  final StorageService storageService;
  final RewardsService rewardsService;
  final NetworkService networkService;
  final ApiService apiService;
  final SyncService syncService;
  final DataUsageService dataUsageService;
  final CarrierTrackingService carrierTrackingService;

  const NetworkMonitorApp({
    super.key,
    required this.storageService,
    required this.rewardsService,
    required this.networkService,
    required this.apiService,
    required this.syncService,
    required this.dataUsageService,
    required this.carrierTrackingService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(
          value: storageService,
        ),
        ChangeNotifierProvider<RewardsService>.value(
          value: rewardsService,
        ),
        ChangeNotifierProvider<NetworkService>.value(
          value: networkService,
        ),
        ChangeNotifierProvider<SyncService>.value(
          value: syncService,
        ),
        Provider<ApiService>.value(
          value: apiService,
        ),
        ChangeNotifierProvider<DataUsageService>.value(
          value: dataUsageService,
        ),
        ChangeNotifierProvider<CarrierTrackingService>.value(
          value: carrierTrackingService,
        ),
      ],
      child: MaterialApp(
        title: 'QoE Boost',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: apiService.isAuthenticatedSync ? const HomeScreen() : const LoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
