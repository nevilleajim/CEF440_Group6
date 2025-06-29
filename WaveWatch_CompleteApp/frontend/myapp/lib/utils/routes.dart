import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/speed_test_screen.dart';
import '../screens/carrier_history_screen.dart';

class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String feedback = '/feedback';
  static const String metrics = '/metrics';
  static const String speedTest = '/speed_test';
  static const String rewards = '/rewards';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String carrierHistory = '/carrier_history';
}

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String feedback = '/feedback';
  static const String metrics = '/metrics';
  static const String speedTest = '/speed_test';
  static const String rewards = '/rewards';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String carrierHistory = '/carrier_history';
  
  static Map<String, WidgetBuilder> get routes => {
    login: (context) => LoginScreen(),
    home: (context) => HomeScreen(),
    settings: (context) => SettingsScreen(),
    feedback: (context) => FeedbackScreen(),
    speedTest: (context) => SpeedTestScreen(),
    carrierHistory: (context) => CarrierHistoryScreen(),
    // Add other routes as needed
  };
}
