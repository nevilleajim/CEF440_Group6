// services/auth_service.dart
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'https://your-api-url.com/api';

  // Define mock users
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': '1',
      'name': 'King MTN',
      'email': 'kingodmk25@gmail.com',
      'password': '08200108Dmk##',
      'provider': 'MTN',
      'role': 'admin',
    },
    {
      'id': '2',
      'name': 'Kingo Orange',
      'email': 'kingodreams25@gmail.com',
      'password': '08200108Dmk##',
      'provider': 'Orange',
      'role': 'admin',
    },
    {
      'id': '3',
      'name': 'Kingo Blue',
      'email': 'kingoblue25@gmail.com',
      'password': '08200108Dmk##',
      'provider': 'Blue',
      'role': 'admin',
    },
  ];

  Future<User?> login(String email, String password) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 1000));

      // Debug print to check what's being received
      print('Login attempt - Email: $email, Password: $password');

      // Trim whitespace
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      // Find matching user
      final matchingUser = _mockUsers.firstWhere(
        (user) => user['email'] == trimmedEmail && user['password'] == trimmedPassword,
        orElse: () => <String, dynamic>{},
      );

      if (matchingUser.isNotEmpty) {
        print('Login successful - credentials match for ${matchingUser['name']}');

        // Create user data without password for security
        final mockUserData = <String, dynamic>{
          'id': matchingUser['id'],
          'name': matchingUser['name'],
          'email': matchingUser['email'],
          'provider': matchingUser['provider'],
          'role': matchingUser['role'],
        };

        print('Creating user with data: $mockUserData');

        try {
          final user = User.fromJson(mockUserData);
          print('User created successfully: ${user.toString()}');
          return user;
        } catch (e) {
          print('Error creating User from JSON: $e');
          return null;
        }
      }

      print('Login failed - credentials do not match any user');
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Helper method to get user info by email (for testing/debugging)
  Map<String, dynamic>? getUserByEmail(String email) {
    try {
      return _mockUsers.firstWhere(
        (user) => user['email'] == email.trim(),
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      return null;
    }
  }

  // Get all available users (without passwords for security)
  List<Map<String, String>> getAvailableUsers() {
    return _mockUsers.map((user) => {
      'name': user['name'] as String,
      'email': user['email'] as String,
      'provider': user['provider'] as String,
    }).toList();
  }

  Future<void> logout() async {
    // Handle logout logic
    await Future.delayed(Duration(milliseconds: 500));
  }
}