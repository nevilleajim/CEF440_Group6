import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(NetworkAdminApp());
}

class NetworkAdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Admin',
      theme: AppTheme.lightTheme,
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}