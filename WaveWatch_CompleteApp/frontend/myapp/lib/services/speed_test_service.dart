// services/speed_test_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class SpeedTestService {
  static const String testUrl = 'https://httpbin.org/bytes/';
  
  Future<Map<String, double>> runSpeedTest() async {
    final downloadSpeed = await _measureDownloadSpeed();
    final uploadSpeed = await _measureUploadSpeed();
    
    return {
      'download': downloadSpeed,
      'upload': uploadSpeed,
    };
  }

  Future<double> _measureDownloadSpeed() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('${testUrl}1048576')); // 1MB
      final stopwatch = Stopwatch()..start();
      
      final response = await request.close();
      int totalBytes = 0;
      
      await for (var chunk in response) {
        totalBytes += chunk.length;
      }
      
      stopwatch.stop();
      client.close();
      
      // Convert to Mbps
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final mbps = (totalBytes * 8) / (seconds * 1000000);
      
      return mbps;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _measureUploadSpeed() async {
    try {
      final client = HttpClient();
      final data = Uint8List(1048576); // 1MB of data
      final request = await client.postUrl(Uri.parse('https://httpbin.org/post'));
      
      final stopwatch = Stopwatch()..start();
      request.add(data);
      await request.close();
      stopwatch.stop();
      
      client.close();
      
      // Convert to Mbps
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final mbps = (data.length * 8) / (seconds * 1000000);
      
      return mbps;
    } catch (e) {
      return 0.0;
    }
  }
}
