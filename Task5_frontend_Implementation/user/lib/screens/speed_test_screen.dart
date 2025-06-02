import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:io';

// Import your speed test service
// import 'services/speed_test_service.dart';

// SpeedTestService class (include this in your services/speed_test_service.dart file)
class SpeedTestService {
  static const String testUrl = 'https://httpbin.org/bytes/';
  
  Future<Map<String, double>> runSpeedTest({
    Function(double)? onDownloadProgress,
    Function(double)? onUploadProgress,
    Function(double)? onPingComplete,
  }) async {
    // Test ping first
    final ping = await _measurePing();
    onPingComplete?.call(ping);
    
    // Test download speed with progress
    final downloadSpeed = await _measureDownloadSpeed(onDownloadProgress);
    
    // Test upload speed with progress
    final uploadSpeed = await _measureUploadSpeed(onUploadProgress);
    
    return {
      'download': downloadSpeed,
      'upload': uploadSpeed,
      'ping': ping,
    };
  }

  Future<double> _measurePing() async {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await InternetAddress.lookup('google.com');
      stopwatch.stop();
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return stopwatch.elapsedMilliseconds.toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _measureDownloadSpeed(Function(double)? onProgress) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('${testUrl}5242880')); // 5MB for better accuracy
      final stopwatch = Stopwatch()..start();
      
      final response = await request.close();
      int totalBytes = 0;
      const expectedBytes = 5242880; // 5MB
      
      await for (var chunk in response) {
        totalBytes += chunk.length;
        final progress = totalBytes / expectedBytes;
        onProgress?.call(progress.clamp(0.0, 1.0));
        
        // Small delay to make progress visible
        await Future.delayed(const Duration(milliseconds: 10));
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

  Future<double> _measureUploadSpeed(Function(double)? onProgress) async {
    try {
      final client = HttpClient();
      final data = List.generate(2097152, (index) => index % 256); // 2MB of data
      final request = await client.postUrl(Uri.parse('https://httpbin.org/post'));
      
      request.headers.set('Content-Type', 'application/octet-stream');
      
      final stopwatch = Stopwatch()..start();
      
      // Simulate progress by sending data in chunks
      const chunkSize = 65536; // 64KB chunks
      for (int i = 0; i < data.length; i += chunkSize) {
        final end = math.min(i + chunkSize, data.length);
        final chunk = data.sublist(i, end);
        request.add(chunk);
        
        final progress = (i + chunk.length) / data.length;
        onProgress?.call(progress);
        
        // Small delay to make progress visible
        await Future.delayed(const Duration(milliseconds: 20));
      }
      
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

// Complete RewardsProvider implementation
class RewardsProvider extends ChangeNotifier {
  int _totalPoints = 0;
  List<String> _recentActivities = [];

  int get totalPoints => _totalPoints;
  List<String> get recentActivities => _recentActivities;

  Future<void> addPoints(String userId, int points, String activity) async {
    _totalPoints += points;
    _recentActivities.insert(0, '$activity (+$points points)');
    
    // Keep only last 10 activities
    if (_recentActivities.length > 10) {
      _recentActivities = _recentActivities.take(10).toList();
    }
    
    notifyListeners();
    
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

// Constants class
class AppConstants {
  static const int pointsPerSpeedTest = 50;
}

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen>
    with TickerProviderStateMixin {
  bool _isRunning = false;
  double _downloadProgress = 0;
  double _uploadProgress = 0;
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;
  double _ping = 0;
  String _currentPhase = 'Ready';
  String? _errorMessage;
  
  late AnimationController _pulseController;
  late AnimationController _gaugeController;
  late AnimationController _particleController;
  
  final SpeedTestService _speedTestService = SpeedTestService();
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _gaugeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _gaugeController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  Future<void> _startSpeedTest() async {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
      _downloadProgress = 0;
      _uploadProgress = 0;
      _downloadSpeed = 0;
      _uploadSpeed = 0;
      _ping = 0;
      _currentPhase = 'Initializing...';
      _errorMessage = null;
    });
    
    _gaugeController.forward();
    
    try {
      // Run the actual speed test using the service
      final results = await _speedTestService.runSpeedTest(
        onDownloadProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _currentPhase = 'Download Test';
              // Estimate speed based on progress and time
              _downloadSpeed = progress * 50; // Rough estimation for UI
            });
          }
        },
        onUploadProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
              _currentPhase = 'Upload Test';
              // Estimate speed based on progress and time
              _uploadSpeed = progress * 25; // Rough estimation for UI
            });
          }
        },
        onPingComplete: (pingValue) {
          if (mounted) {
            setState(() {
              _ping = pingValue;
              _currentPhase = 'Testing Ping... ${pingValue.toStringAsFixed(0)}ms';
            });
          }
        },
      );
      
      // Update with final results
      if (mounted) {
        setState(() {
          _downloadSpeed = results['download'] ?? 0;
          _uploadSpeed = results['upload'] ?? 0;
          _ping = results['ping'] ?? 0;
          _downloadProgress = 1.0;
          _uploadProgress = 1.0;
          _currentPhase = 'Complete!';
        });
      }
      
      // Award points for completing speed test
      try {
        final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
        await rewardsProvider.addPoints(
          'user_id',
          AppConstants.pointsPerSpeedTest,
          'Speed test completion',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('Speed test completed! +${AppConstants.pointsPerSpeedTest} points'),
                ],
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8,
            ),
          );
        }
      } catch (providerError) {
        // Handle case where provider is not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Speed test completed successfully!'),
                ],
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _currentPhase = 'Test Failed';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to complete speed test: Network error')),
              ],
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
          if (_currentPhase != 'Complete!' && _currentPhase != 'Test Failed') {
            _currentPhase = 'Ready';
          }
        });
      }
      _gaugeController.reverse();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B73FF),
              Color(0xFF000DFF),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                _buildHeader().animate().slideY(begin: -1, duration: 800.ms).fadeIn(),
                
                const SizedBox(height: 40),
                
                // Main Speed Gauge
                Expanded(
                  flex: 3,
                  child: _buildSpeedGauge(size),
                ),
                
                const SizedBox(height: 30),
                
                // Metrics Grid
                _buildMetricsGrid().animate().slideY(begin: 1, duration: 800.ms).fadeIn(delay: 200.ms),
                
                const SizedBox(height: 30),
                
                // Start Button
                _buildStartButton().animate().scale(delay: 400.ms, duration: 600.ms),
                
                // Error message if any
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Network connection required for speed test',
                      style: TextStyle(
                        color: Colors.red[300],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Network Speed Test',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Measure your connection performance with precision',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSpeedGauge(Size size) {
    final maxSpeed = math.max(_downloadSpeed, _uploadSpeed);
    final overallProgress = (_downloadProgress + _uploadProgress) / 2;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated Background Particles
          ...List.generate(12, (index) {
            return AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                final angle = (index * 30.0) + (_particleController.value * 360);
                final radius = 120 + (math.sin(_particleController.value * 2 * math.pi) * 10);
                return Positioned(
                  left: size.width / 2 + math.cos(angle * math.pi / 180) * radius - 2,
                  top: size.width / 2 + math.sin(angle * math.pi / 180) * radius - 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
          
          // Main Gauge Ring
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3 + _pulseController.value * 0.2),
                    width: 3,
                  ),
                ),
              );
            },
          ),
          
          // Progress Ring
          if (_isRunning)
            SizedBox(
              width: size.width * 0.7,
              height: size.width * 0.7,
              child: CircularProgressIndicator(
                value: overallProgress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(
                    const Color(0xFF00E676),
                    const Color(0xFF00BCD4),
                    overallProgress,
                  )!,
                ),
              ),
            ).animate().scale(duration: 800.ms),
          
          // Center Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentPhase,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(),
              
              const SizedBox(height: 16),
              
              if (maxSpeed > 0)
                Column(
                  children: [
                    Text(
                      maxSpeed.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ).animate().scale(duration: 600.ms),
                    const Text(
                      'Mbps',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              
              if (!_isRunning && maxSpeed == 0)
                Icon(
                  Icons.speed,
                  size: 64,
                  color: Colors.white.withOpacity(0.8),
                ).animate().scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  duration: 1500.ms,
                ).then().scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1.0, 1.0),
                  duration: 1500.ms,
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Download',
                '${_downloadSpeed.toStringAsFixed(1)} Mbps',
                _downloadProgress,
                Icons.download,
                const Color(0xFF00E676),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Upload',
                '${_uploadSpeed.toStringAsFixed(1)} Mbps',
                _uploadProgress,
                Icons.upload,
                const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'Ping',
          '${_ping.toStringAsFixed(0)} ms',
          _ping > 0 ? 1 : 0,
          Icons.timeline,
          const Color(0xFFFF9800),
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(
    String label,
    String value,
    double progress,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: accentColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.white.withOpacity(0.2),
            ),
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.7),
                      accentColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStartButton() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        gradient: _isRunning
            ? LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.2),
                ],
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF00E676),
                  Color(0xFF00C853),
                ],
              ),
        boxShadow: [
          if (!_isRunning)
            BoxShadow(
              color: const Color(0xFF00E676).withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isRunning ? null : _startSpeedTest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRunning) ...[
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 10),
            ] else ...[
              const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _isRunning ? 'Testing Network...' : 'Start Speed Test',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}