// services/database_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabaseService {
  static const String baseUrl = 'https://your-api-url.com/api';

  Future<Map<String, dynamic>?> executeQuery(String query, Map<String, dynamic> params) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'params': params,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getFeedbackData(String provider) async {
    final query = '''
      SELECT id, timestamp, location, jitter, latency, packet_loss, 
             signal_strength, user_rating, comments, description, 
             latitude, longitude
      FROM feedback_data 
      WHERE provider = ? 
      ORDER BY timestamp DESC
    ''';
    
    final result = await executeQuery(query, {'provider': provider});
    return result?['data'] ?? [];
  }

  Future<List<Map<String, dynamic>>> getAnalyticsData(String provider) async {
    final query = '''
      SELECT location, 
             AVG(latency) as avg_latency,
             AVG(jitter) as avg_jitter,
             AVG(packet_loss) as avg_packet_loss,
             AVG(signal_strength) as avg_signal_strength,
             AVG(user_rating) as avg_user_rating,
             COUNT(*) as total_feedbacks
      FROM feedback_data 
      WHERE provider = ?
      GROUP BY location
      ORDER BY avg_user_rating DESC
    ''';
    
    final result = await executeQuery(query, {'provider': provider});
    return result?['data'] ?? [];
  }
}
