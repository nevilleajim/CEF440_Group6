import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feedback_data.dart';
import '../models/network_metrics.dart';

class ApiService {
  static const String baseUrl = 'https://backend-qoe.onrender.com'; // Change to your server URL
  static const String _tokenKey = 'auth_token';

  String? _token;

  // Initialize and load token
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    print('🔑 API Service initialized with token: ${_token != null ? "Present" : "None"}');
  }

  // Save token
  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('🔑 Token saved');
  }

  // Clear token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('🔑 Token cleared');
  }

  // Get headers with auth
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? provider,
  }) async {
    try {
      print('🔑 Registering user: $username, $email');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'provider': provider,
        }),
      ).timeout(Duration(seconds: 10));
      
      print('🔑 Registration response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  Future<String> login({
    required String username,
    required String password,
  }) async {
    try {
      print('🔑 Logging in user: $username');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(Duration(seconds: 10));
      
      print('🔑 Login response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        await _saveToken(token);
        return token;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

// Change the getCurrentUser method to use the /health endpoint instead of /profile
Future<Map<String, dynamic>> getCurrentUser() async {
  try {
    print('👤 Getting current user profile');
    // Using /health endpoint since /profile doesn't exist
    final response = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: _headers,
    ).timeout(Duration(seconds: 10));
    
    print('👤 Profile response: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user info: ${response.body}');
    }
  } catch (e) {
    print('❌ Get user error: $e');
    throw Exception('Failed to get user info: $e');
  }
}

// Change the checkAuthentication method to use the /health endpoint instead of /profile
Future<bool> checkAuthentication() async {
  try {
    if (_token == null) {
      print('🔑 No token available, not authenticated');
      return false;
    }
    
    print('🔑 Checking authentication with token');
    // Using /health endpoint since /profile doesn't exist
    final response = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: _headers,
    ).timeout(Duration(seconds: 5));
    
    print('🔑 Auth check response: ${response.statusCode}');
    return response.statusCode == 200;
  } catch (e) {
    print('❌ Auth check error: $e');
    return false;
  }
}

  // Feedback endpoints - FIXED VERSION
  Future<Map<String, dynamic>> submitFeedback(FeedbackData feedback) async {
    try {
      print('📝 Submitting feedback: ${feedback.id}');
      
      // Create a clean payload that exactly matches what works in Postman
      final payload = <String, dynamic>{
        'overall_satisfaction': feedback.overallSatisfaction,
        'response_time': feedback.responseTime,
        'usability': feedback.usability,
        'carrier': feedback.carrier,
        'location': '${feedback.city ?? 'Unknown'}, ${feedback.country ?? 'Unknown'}',
      };
      
      // Only add optional fields if they have valid values
      if (feedback.comments != null && feedback.comments!.isNotEmpty) {
        payload['comments'] = feedback.comments;
      }
      
      if (feedback.issueType != null && feedback.issueType!.isNotEmpty) {
        payload['issue_type'] = feedback.issueType;
      }
      
      if (feedback.networkType != null && feedback.networkType!.isNotEmpty) {
        payload['network_type'] = feedback.networkType;
      }
      
      if (feedback.signalStrength != null) {
        payload['signal_strength'] = feedback.signalStrength;
      }
      
      if (feedback.downloadSpeed != null && feedback.downloadSpeed! > 0) {
        payload['download_speed'] = feedback.downloadSpeed;
      }
      
      if (feedback.uploadSpeed != null && feedback.uploadSpeed! > 0) {
        payload['upload_speed'] = feedback.uploadSpeed;
      }
      
      if (feedback.latency != null && feedback.latency! > 0) {
        payload['latency'] = feedback.latency;
      }
      
      print('📝 Final feedback payload: ${jsonEncode(payload)}');
      print('📝 Payload size: ${jsonEncode(payload).length} bytes');
      print('📝 Headers: $_headers');
      
      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(Duration(seconds: 30));
      
      print('📝 Feedback submission response: ${response.statusCode}');
      print('📝 Response headers: ${response.headers}');
      print('📝 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Feedback successfully submitted to database!');
        return responseData;
      } else {
        print('❌ Feedback submission failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to submit feedback: ${response.body}');
      }
    } catch (e) {
      print('❌ Feedback submission error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to submit feedback: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFeedbacks() async {
    try {
      print('📝 Getting feedbacks');
      final response = await http.get(
        Uri.parse('$baseUrl/feedback'),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('📝 Get feedbacks response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get feedbacks: ${response.body}');
      }
    } catch (e) {
      print('❌ Get feedbacks error: $e');
      throw Exception('Failed to get feedbacks: $e');
    }
  }

  // Network logs endpoints
  Future<Map<String, dynamic>> submitNetworkLog(NetworkMetrics metrics) async {
    try {
      print('📊 Submitting network log: ${metrics.id}');
      final response = await http.post(
        Uri.parse('$baseUrl/network-logs'),
        headers: _headers,
        body: jsonEncode({
          'carrier': metrics.carrier,
          'network_type': metrics.networkType,
          'signal_strength': metrics.signalStrength,
          'download_speed': metrics.downloadSpeed,
          'upload_speed': metrics.uploadSpeed,
          'latency': metrics.latency,
          'jitter': metrics.jitter,
          'packet_loss': metrics.packetLoss,
          'location': '${metrics.city ?? 'Unknown'}, ${metrics.country ?? 'Unknown'}',
          'device_info': 'Flutter App',
          'app_version': '1.0.0',
        }),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Network log submission response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Network log submission failed: ${response.body}');
        throw Exception('Failed to submit network log: ${response.body}');
      }
    } catch (e) {
      print('❌ Network log submission error: $e');
      throw Exception('Failed to submit network log: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNetworkLogs() async {
    try {
      print('📊 Getting network logs');
      final response = await http.get(
        Uri.parse('$baseUrl/network-logs'),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('📊 Get network logs response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get network logs: ${response.body}');
      }
    } catch (e) {
      print('❌ Get network logs error: $e');
      throw Exception('Failed to get network logs: $e');
    }
  }

  // Recommendations endpoint
  Future<List<Map<String, dynamic>>> getRecommendations(String location) async {
    try {
      print('🔍 Getting recommendations for: $location');
      final response = await http.get(
        Uri.parse('$baseUrl/recommendations?location=${Uri.encodeComponent(location)}'),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('🔍 Get recommendations response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get recommendations: ${response.body}');
      }
    } catch (e) {
      print('❌ Get recommendations error: $e');
      throw Exception('Failed to get recommendations: $e');
    }
  }

  // Analytics endpoint
  Future<Map<String, dynamic>> getProviderAnalytics({String? location}) async {
    try {
      String url = '$baseUrl/analytics/providers';
      if (location != null) {
        url += '?location=${Uri.encodeComponent(location)}';
      }
      
      print('📈 Getting provider analytics');
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('📈 Get analytics response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get analytics: ${response.body}');
      }
    } catch (e) {
      print('❌ Get analytics error: $e');
      throw Exception('Failed to get analytics: $e');
    }
  }

  bool get isAuthenticatedSync => _token != null;
}
