// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feedback.dart';
import '../models/network_analytics.dart';

class ApiService {
  static const String baseUrl = 'https://your-api-url.com/api';

  Future<List<Feedback>> getFeedbacks(String provider) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feedbacks?provider=$provider'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['feedbacks'];
        return data.map((json) => Feedback.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<NetworkAnalytics>> getAnalytics(String provider) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics?provider=$provider'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['analytics'];
        return data.map((json) => NetworkAnalytics.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
