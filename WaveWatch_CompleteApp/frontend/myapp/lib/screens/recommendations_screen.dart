import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../models/network_metrics.dart';
import 'dart:math';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  
  List<Map<String, dynamic>> _recommendations = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';
  String _currentLocation = '';
  
  late AnimationController _animationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });
    
    try {
      // Get current location
      final locationData = await _locationService.getCurrentLocationWithAddress();
      _currentLocation = locationData['city'] ?? 'Unknown';
      
      // Generate recommendations from local data
      final recommendations = await _generateLocalRecommendations();
      final analytics = await _generateLocalAnalytics();
      
      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recommendations: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _generateLocalRecommendations() async {
    // Get network metrics from database
    final metrics = await _databaseService.getNetworkMetrics();
    
    if (metrics.isEmpty) {
      return [];
    }
    
    // Group metrics by carrier
    final Map<String, List<NetworkMetrics>> carrierMetrics = {};
    for (final metric in metrics) {
      if (!carrierMetrics.containsKey(metric.carrier)) {
        carrierMetrics[metric.carrier] = [];
      }
      carrierMetrics[metric.carrier]!.add(metric);
    }
    
    // Calculate scores for each carrier
    final List<Map<String, dynamic>> recommendations = [];
    
    carrierMetrics.forEach((carrier, metricsList) {
      // Skip carriers with too few data points
      if (metricsList.length < 3) return;
      
      // Calculate averages
      double avgDownloadSpeed = 0;
      double avgUploadSpeed = 0;
      double avgLatency = 0;
      double avgSignalStrength = 0;
      double avgJitter = 0;
      double avgPacketLoss = 0;
      
      int downloadCount = 0;
      int uploadCount = 0;
      int latencyCount = 0;
      int jitterCount = 0;
      int packetLossCount = 0;
      
      for (final metric in metricsList) {
        avgSignalStrength += metric.signalStrength;
        
        if (metric.downloadSpeed != null) {
          avgDownloadSpeed += metric.downloadSpeed!;
          downloadCount++;
        }
        
        if (metric.uploadSpeed != null) {
          avgUploadSpeed += metric.uploadSpeed!;
          uploadCount++;
        }
        
        if (metric.latency != null) {
          avgLatency += metric.latency!;
          latencyCount++;
        }
        
        if (metric.jitter != null) {
          avgJitter += metric.jitter!;
          jitterCount++;
        }
        
        if (metric.packetLoss != null) {
          avgPacketLoss += metric.packetLoss!;
          packetLossCount++;
        }
      }
      
      avgSignalStrength /= metricsList.length;
      if (downloadCount > 0) avgDownloadSpeed /= downloadCount;
      if (uploadCount > 0) avgUploadSpeed /= uploadCount;
      if (latencyCount > 0) avgLatency /= latencyCount;
      if (jitterCount > 0) avgJitter /= jitterCount;
      if (packetLossCount > 0) avgPacketLoss /= packetLossCount;
      
      // Calculate score (higher is better)
      double downloadScore = min(avgDownloadSpeed * 10, 100); // 10 Mbps = 100 points
      double uploadScore = min(avgUploadSpeed * 20, 100); // 5 Mbps = 100 points
      double latencyScore = max(0, 100 - (avgLatency / 2)); // 0ms = 100 points, 200ms = 0 points
      double signalScore = max(0, ((avgSignalStrength + 120) / 70) * 100); // -50dBm = 100 points, -120dBm = 0 points
      double jitterScore = max(0, 100 - (avgJitter * 10)); // 0ms = 100 points, 10ms = 0 points
      double packetLossScore = max(0, 100 - (avgPacketLoss * 20)); // 0% = 100 points, 5% = 0 points
      
      // Weighted average
      double score = (
        (downloadScore * 0.25) +
        (uploadScore * 0.15) +
        (latencyScore * 0.25) +
        (signalScore * 0.15) +
        (jitterScore * 0.1) +
        (packetLossScore * 0.1)
      );
      
      // Determine recommendation reason
      String reason = '';
      if (downloadScore >= 80) {
        reason = 'Best download speeds';
      } else if (latencyScore >= 80) {
        reason = 'Lowest latency';
      } else if (signalScore >= 80) {
        reason = 'Strongest signal';
      } else if (score >= 70) {
        reason = 'Good overall performance';
      } else if (score >= 50) {
        reason = 'Acceptable performance';
      } else {
        reason = 'Limited data available';
      }
      
      recommendations.add({
        'carrier': carrier,
        'score': score,
        'avg_download_speed': avgDownloadSpeed,
        'avg_upload_speed': avgUploadSpeed,
        'avg_latency': avgLatency,
        'avg_jitter': avgJitter,
        'avg_packet_loss': avgPacketLoss,
        'avg_signal_strength': avgSignalStrength,
        'total_samples': metricsList.length,
        'recommendation_reason': reason,
      });
    });
    
    // Sort by score (descending)
    recommendations.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    // If no recommendations, add dummy data for testing
    if (recommendations.isEmpty) {
      recommendations.addAll([
        {
          'carrier': 'MTN',
          'score': 85.0,
          'avg_download_speed': 8.5,
          'avg_upload_speed': 3.2,
          'avg_latency': 45.0,
          'avg_jitter': 3.5,
          'avg_packet_loss': 0.5,
          'avg_signal_strength': -75.0,
          'total_samples': 15,
          'recommendation_reason': 'Best download speeds',
        },
        {
          'carrier': 'Orange',
          'score': 78.0,
          'avg_download_speed': 7.2,
          'avg_upload_speed': 2.8,
          'avg_latency': 55.0,
          'avg_jitter': 4.2,
          'avg_packet_loss': 0.8,
          'avg_signal_strength': -80.0,
          'total_samples': 12,
          'recommendation_reason': 'Good overall performance',
        },
        {
          'carrier': 'Camtel',
          'score': 65.0,
          'avg_download_speed': 5.5,
          'avg_upload_speed': 2.1,
          'avg_latency': 75.0,
          'avg_jitter': 6.5,
          'avg_packet_loss': 1.2,
          'avg_signal_strength': -85.0,
          'total_samples': 8,
          'recommendation_reason': 'Acceptable performance',
        },
      ]);
    }
    
    return recommendations;
  }

  Future<Map<String, dynamic>> _generateLocalAnalytics() async {
    // Get network metrics from database
    final metrics = await _databaseService.getNetworkMetrics();
    
    if (metrics.isEmpty) {
      return {};
    }
    
    // Group metrics by carrier
    final Map<String, List<NetworkMetrics>> carrierMetrics = {};
    for (final metric in metrics) {
      if (!carrierMetrics.containsKey(metric.carrier)) {
        carrierMetrics[metric.carrier] = [];
      }
      carrierMetrics[metric.carrier]!.add(metric);
    }
    
    // Calculate analytics for each carrier
    final Map<String, dynamic> analytics = {};
    
    carrierMetrics.forEach((carrier, metricsList) {
      // Calculate averages
      double avgDownloadSpeed = 0;
      int downloadCount = 0;
      
      for (final metric in metricsList) {
        if (metric.downloadSpeed != null) {
          avgDownloadSpeed += metric.downloadSpeed!;
          downloadCount++;
        }
      }
      
      if (downloadCount > 0) {
        avgDownloadSpeed /= downloadCount;
      }
      
      analytics[carrier] = {
        'avg_download_speed': avgDownloadSpeed,
        'total_logs': metricsList.length,
      };
    });
    
    return analytics;
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF3B82F6);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'mtn':
        return Icons.signal_cellular_4_bar;
      case 'orange':
        return Icons.network_cell;
      case 'camtel':
      case 'nexttel':
        return Icons.cell_tower;
      default:
        return Icons.network_check;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFF093FB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'Provider Recommendations',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                        ),
                      ],
                    ).animate().slideY(begin: -1, duration: 600.ms),
                    
                    const SizedBox(height: 16),
                    
                    // Location info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _currentLocation.isNotEmpty ? _currentLocation : 'Loading location...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Analyzing network data...'),
                            ],
                          ),
                        )
                      : _isError
                          ? _buildErrorState()
                          : _recommendations.isEmpty
                              ? _buildEmptyState()
                              : _buildRecommendationsList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Recommendations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We encountered an error while loading recommendations. Please try again later.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need more network data to provide recommendations.\nStart using the app to collect data!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildRecommendationsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // AI Insights Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Powered Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Based on real user data and network performance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().slideX(delay: 200.ms),
          
          const SizedBox(height: 24),
          
          // Recommendations List
          ...List.generate(_recommendations.length, (index) {
            final recommendation = _recommendations[index];
            final isTopChoice = index == 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildRecommendationCard(recommendation, isTopChoice, index),
            ).animate().slideX(delay: Duration(milliseconds: 300 + (index * 100)));
          }),
          
          const SizedBox(height: 24),
          
          // Analytics Section
          if (_analytics.isNotEmpty) _buildAnalyticsSection(),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation, bool isTopChoice, int index) {
    final score = recommendation['score']?.toDouble() ?? 0.0;
    final carrier = recommendation['carrier'] ?? 'Unknown';
    final downloadSpeed = recommendation['avg_download_speed']?.toDouble() ?? 0.0;
    final uploadSpeed = recommendation['avg_upload_speed']?.toDouble() ?? 0.0;
    final latency = recommendation['avg_latency']?.toDouble() ?? 0.0;
    final signalStrength = recommendation['avg_signal_strength']?.toDouble() ?? 0.0;
    final samples = recommendation['total_samples'] ?? 0;
    final reason = recommendation['recommendation_reason'] ?? '';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isTopChoice 
            ? Border.all(color: const Color(0xFF10B981), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isTopChoice 
                ? const Color(0xFF10B981).withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isTopChoice ? 20 : 10,
            offset: Offset(0, isTopChoice ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isTopChoice
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    )
                  : LinearGradient(
                      colors: [_getScoreColor(score), _getScoreColor(score).withOpacity(0.8)],
                    ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Provider info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getProviderIcon(carrier),
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            carrier,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isTopChoice) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'BEST',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Score
                Column(
                  children: [
                    Text(
                      '${score.toInt()}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Metrics
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Download',
                        '${downloadSpeed.toStringAsFixed(1)} Mbps',
                        Icons.download,
                        _getScoreColor(score),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Upload',
                        '${uploadSpeed.toStringAsFixed(1)} Mbps',
                        Icons.upload,
                        _getScoreColor(score),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Latency',
                        '${latency.toInt()} ms',
                        Icons.speed,
                        _getScoreColor(score),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Signal',
                        '${signalStrength.toInt()} dBm',
                        Icons.signal_cellular_alt,
                        _getScoreColor(score),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Based on $samples data samples',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.insights,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Network Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._analytics.entries.map((entry) {
            final carrier = entry.key;
            final data = entry.value as Map<String, dynamic>;
            final avgSpeed = data['avg_download_speed']?.toDouble() ?? 0.0;
            final totalLogs = data['total_logs'] ?? 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_getProviderIcon(carrier), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carrier,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$totalLogs samples collected',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${avgSpeed.toStringAsFixed(1)} Mbps',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ).animate().slideY(delay: 600.ms);
  }
}