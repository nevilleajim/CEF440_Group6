//main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'services/reward_service.dart';
import 'services/network_service.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await BackgroundService().initializeService();

  // Initialize rewards service
  final rewardsService = RewardsService();
  await rewardsService.initialize();

  // Initialize network service
  final networkService = NetworkService();

  runApp(NetworkMonitorApp(
    rewardsService: rewardsService,
    networkService: networkService,
  ));
}

class NetworkMonitorApp extends StatelessWidget {
  final RewardsService rewardsService;
  final NetworkService networkService;

  const NetworkMonitorApp({
    super.key,
    required this.rewardsService,
    required this.networkService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RewardsService>.value(
          value: rewardsService,
        ),
        ChangeNotifierProvider<NetworkService>.value(
          value: networkService,
        ),
        // Add other providers here if needed
      ],
      child: MaterialApp(
        title: 'Network Monitor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
