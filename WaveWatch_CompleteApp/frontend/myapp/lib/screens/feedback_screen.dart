//feedback_screen.dart
import 'package:WaveWatch/models/network_metrics.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/location_service.dart';
import '../models/feedback_data.dart';
import '../services/network_service.dart';
import '../services/sync_service.dart';
import '../services/storage_service.dart';
import '../services/reward_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  final TextEditingController _commentsController = TextEditingController();
  int _overallSatisfaction = 0;
  int _responseTime = 0;
  int _usability = 0;
  String? _selectedIssue;
  bool _isSubmitting = false;
  bool _isLoadingNetworkInfo = true;
  bool _autoRefreshEnabled = true;
  
  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  DateTime? _lastRefreshTime;
  
  // Network quality trend tracking
  List<NetworkMetrics> _recentMetrics = [];
  Map<String, TrendInfo> _trends = {};

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _submitController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _submitAnimation;

  final List<Map<String, dynamic>> _issues = [
    {
      'title': 'Slow Internet Speed',
      'icon': Icons.speed,
      'color': Colors.orange
    },
    {
      'title': 'Connection Drops',
      'icon': Icons.signal_wifi_off,
      'color': Colors.red
    },
    {'title': 'High Latency', 'icon': Icons.timer, 'color': Colors.amber},
    {
      'title': 'Poor Call Quality',
      'icon': Icons.call_end,
      'color': Colors.deepOrange
    },
    {
      'title': 'No Signal',
      'icon': Icons.signal_cellular_off,
      'color': Colors.grey
    },
    {'title': 'Other', 'icon': Icons.help_outline, 'color': Colors.blue},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _loadHistoricalData();
    _loadCurrentNetworkInfo();
    _startAutoRefresh();
  }

  Future<void> _loadHistoricalData() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      // Get the last 10 network metrics to analyze trends
      final metrics = await storageService.getRecentNetworkMetrics(10);
      
      if (metrics.isNotEmpty) {
        setState(() {
          _recentMetrics = metrics;
        });
        _calculateTrends();
        debugPrint('📈 Loaded ${metrics.length} historical metrics for trend analysis');
      }
    } catch (e) {
      debugPrint('❌ Error loading historical data: $e');
    }
  }

  void _calculateTrends() {
    if (_recentMetrics.length < 2) {
      debugPrint('⚠️ Not enough historical data for trend analysis');
      return;
    }

    // Sort metrics by timestamp (newest first)
    _recentMetrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Calculate trends for key metrics
    _calculateMetricTrend('download', 'Download Speed');
    _calculateMetricTrend('upload', 'Upload Speed');
    _calculateMetricTrend('latency', 'Latency');
    _calculateMetricTrend('signal', 'Signal Strength');
    
    // Calculate overall trend
    _calculateOverallTrend();
    
    debugPrint('📊 Network trends calculated: ${_trends.length} metrics analyzed');
  }

  void _calculateMetricTrend(String key, String label) {
    try {
      // Get values for the specific metric
      List<double> values = [];
      
      for (var metric in _recentMetrics) {
        double? value;
        switch (key) {
          case 'download':
            value = metric.downloadSpeed;
            break;
          case 'upload':
            value = metric.uploadSpeed;
            break;
          case 'latency':
            value = metric.latency?.toDouble();
            break;
          case 'signal':
            value = metric.signalStrength.toDouble();
            break;
        }
        
        if (value != null) {
          // For latency, lower is better, so invert the trend
          if (key == 'latency') {
            value = -value;
          }
          // For signal strength, less negative is better
          if (key == 'signal') {
            value = -value; // Convert to positive for comparison (e.g., -85 becomes 85)
          }
          
          values.add(value);
        }
      }
      
      if (values.length >= 2) {
        // Calculate trend using linear regression
        double trend = _calculateTrendSlope(values);
        
        // Determine trend direction and strength
        TrendDirection direction;
        if (trend > 0.1) {
          direction = TrendDirection.improving;
        } else if (trend < -0.1) {
          direction = TrendDirection.degrading;
        } else {
          direction = TrendDirection.stable;
        }
        
        // Calculate percent change
        double percentChange = 0;
        if (values.length >= 2 && values.last != 0) {
          percentChange = ((values.first - values.last) / values.last.abs()) * 100;
        }
        
        // Store trend info
        _trends[key] = TrendInfo(
          label: label,
          direction: direction,
          percentChange: percentChange.abs(),
          currentValue: values.first,
          previousValue: values.length > 1 ? values[1] : values.first,
        );
        
        debugPrint('📈 $label trend: ${direction.name} (${percentChange.toStringAsFixed(1)}%)');
      }
    } catch (e) {
      debugPrint('❌ Error calculating $key trend: $e');
    }
  }

  void _calculateOverallTrend() {
    if (_trends.isEmpty) return;
    
    // Weight factors for different metrics
    const Map<String, double> weights = {
      'download': 0.4,
      'upload': 0.2,
      'latency': 0.3,
      'signal': 0.1,
    };
    
    double weightedSum = 0;
    double totalWeight = 0;
    
    // Calculate weighted average of trends
    weights.forEach((key, weight) {
      if (_trends.containsKey(key)) {
        double trendValue;
        switch (_trends[key]!.direction) {
          case TrendDirection.improving:
            trendValue = 1.0;
            break;
          case TrendDirection.stable:
            trendValue = 0.0;
            break;
          case TrendDirection.degrading:
            trendValue = -1.0;
            break;
        }
        
        weightedSum += trendValue * weight;
        totalWeight += weight;
      }
    });
    
    if (totalWeight > 0) {
      double overallTrend = weightedSum / totalWeight;
      
      // Determine overall trend direction
      TrendDirection direction;
      if (overallTrend > 0.2) {
        direction = TrendDirection.improving;
      } else if (overallTrend < -0.2) {
        direction = TrendDirection.degrading;
      } else {
        direction = TrendDirection.stable;
      }
      
      // Store overall trend
      _trends['overall'] = TrendInfo(
        label: 'Overall Quality',
        direction: direction,
        percentChange: 0,
        currentValue: 0,
        previousValue: 0,
      );
      
      debugPrint('📊 Overall network trend: ${direction.name}');
    }
  }

  double _calculateTrendSlope(List<double> values) {
    if (values.length < 2) return 0;
    
    // Simple linear regression to find trend slope
    int n = values.length;
    List<int> x = List.generate(n, (i) => i);
    
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (int i = 0; i < n; i++) {
      sumX += x[i];
      sumY += values[i];
      sumXY += x[i] * values[i];
      sumX2 += x[i] * x[i];
    }
    
    // Calculate slope (m) of the regression line
    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  void _startAutoRefresh() {
    if (_autoRefreshEnabled) {
      _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
        if (mounted && _autoRefreshEnabled && !_isSubmitting) {
          debugPrint('🔄 Auto-refreshing network data...');
          _loadCurrentNetworkInfo(isAutoRefresh: true);
        }
      });
      debugPrint('✅ Auto-refresh started (every 30 seconds)');
    }
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    debugPrint('⏹️ Auto-refresh stopped');
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
    });
    
    if (_autoRefreshEnabled) {
      _startAutoRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Auto-refresh enabled (every 30s)'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.all(16),
        ),
      );
    } else {
      _stopAutoRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.pause, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Auto-refresh disabled'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _loadCurrentNetworkInfo({bool isAutoRefresh = false}) async {
    if (!isAutoRefresh) {
      setState(() => _isLoadingNetworkInfo = true);
    }
    
    try {
      // Get fresh network metrics
      final networkService = Provider.of<NetworkService>(context, listen: false);
      await networkService.collectMetricsNow();
      
      // Small delay to ensure data is collected
      await Future.delayed(Duration(milliseconds: 500));
      
      _lastRefreshTime = DateTime.now();
      
      // Update recent metrics and recalculate trends
      final currentMetrics = networkService.currentMetrics;
      if (currentMetrics != null) {
        _recentMetrics.insert(0, currentMetrics);
        // Keep only the last 10 metrics
        if (_recentMetrics.length > 10) {
          _recentMetrics = _recentMetrics.sublist(0, 10);
        }
        _calculateTrends();
      }
      
      if (!isAutoRefresh) {
        setState(() => _isLoadingNetworkInfo = false);
      } else {
        // For auto-refresh, just trigger a rebuild to update the timestamp
        if (mounted) setState(() {});
      }
      
      debugPrint('📊 Network info ${isAutoRefresh ? 'auto-' : ''}refreshed at ${_lastRefreshTime}');
    } catch (e) {
      debugPrint('Error loading network info: $e');
      if (!isAutoRefresh) {
        setState(() => _isLoadingNetworkInfo = false);
      }
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _submitController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );

    _submitAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _submitController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    Future.delayed(Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
    Future.delayed(Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _submitController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F23),
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 32),
                  _buildSyncStatusCard(),
                  SizedBox(height: 24),
                  _buildOverallTrendCard(),
                  SizedBox(height: 24),
                  _buildOverallSatisfactionSection(),
                  SizedBox(height: 24),
                  _buildResponseTimeSection(),
                  SizedBox(height: 24),
                  _buildUsabilitySection(),
                  SizedBox(height: 32),
                  _buildIssueSection(),
                  SizedBox(height: 24),
                  _buildCommentsSection(),
                  SizedBox(height: 32),
                  _buildInfoCard(),
                  SizedBox(height: 32),
                  _buildSubmitButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.feedback, color: Color(0xFF6C63FF), size: 22),
          ),
          SizedBox(width: 12),
          Text(
            'Share Your Experience',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        // Auto-refresh toggle button
        IconButton(
          onPressed: _toggleAutoRefresh,
          icon: Icon(
            _autoRefreshEnabled ? Icons.autorenew : Icons.pause_circle_outline,
            color: _autoRefreshEnabled ? Color(0xFF50C878) : Colors.grey,
          ),
          tooltip: _autoRefreshEnabled ? 'Disable Auto-refresh' : 'Enable Auto-refresh',
        ),
        // Manual refresh button
        IconButton(
          onPressed: () => _loadCurrentNetworkInfo(),
          icon: _isLoadingNetworkInfo 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF6C63FF),
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.refresh, color: Color(0xFF6C63FF)),
          tooltip: 'Refresh Network Info',
        ),
      ],
    );
  }

  Widget _buildOverallTrendCard() {
    final overallTrend = _trends['overall'];
    
    if (overallTrend == null) {
      return SizedBox.shrink(); // Don't show if no trend data
    }
    
    Color trendColor;
    IconData trendIcon;
    String trendText;
    
    switch (overallTrend.direction) {
      case TrendDirection.improving:
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        trendText = 'Your network quality is improving';
        break;
      case TrendDirection.stable:
        trendColor = Colors.blue;
        trendIcon = Icons.trending_flat;
        trendText = 'Your network quality is stable';
        break;
      case TrendDirection.degrading:
        trendColor = Colors.orange;
        trendIcon = Icons.trending_down;
        trendText = 'Your network quality is degrading';
        break;
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            trendColor.withOpacity(0.2),
            trendColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trendColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              trendIcon,
              color: trendColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trendText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Based on ${_recentMetrics.length} recent measurements',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1E1E3F).withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: syncService.isSyncing 
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  syncService.isSyncing ? Icons.sync : Icons.cloud_done,
                  color: syncService.isSyncing ? Colors.orange : Colors.green,
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      syncService.isSyncing ? 'Syncing data...' : 'Data synced',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (syncService.lastSyncTime != null)
                      Text(
                        'Last sync: ${_formatTime(syncService.lastSyncTime!)}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (syncService.pendingItems > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${syncService.pendingItems} pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We Value Your Feedback',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Help us improve your network experience',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.star, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(String title, int currentRating,
      Function(int) onRatingChanged, Color accentColor) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E3F).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                bool isSelected = index < currentRating;
                return GestureDetector(
                  onTap: () => _animateRating(index + 1, onRatingChanged),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: isSelected ? Color(0xFFFFD700) : Colors.grey,
                      size: 30,
                    ),
                  ),
                );
              }),
            ),
            if (currentRating > 0)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  _getRatingText(currentRating),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSatisfactionSection() {
    return _buildRatingSection(
        'Overall Satisfaction',
        _overallSatisfaction,
        (rating) => setState(() => _overallSatisfaction = rating),
        Color(0xFF6C63FF));
  }

  Widget _buildResponseTimeSection() {
    return _buildRatingSection('Response Time', _responseTime,
        (rating) => setState(() => _responseTime = rating), Color(0xFF9F7AEA));
  }

  Widget _buildUsabilitySection() {
    return _buildRatingSection('Usability', _usability,
        (rating) => setState(() => _usability = rating), Color(0xFF50C878));
  }

  Widget _buildIssueSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E3F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 8),
              Text(
                'What went wrong?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                'Optional',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: _issues.length,
            itemBuilder: (context, index) {
              final issue = _issues[index];
              bool isSelected = _selectedIssue == issue['title'];

              return GestureDetector(
                onTap: () => _selectIssue(issue['title']),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? issue['color'].withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? issue['color']
                          : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        issue['icon'],
                        color: isSelected ? issue['color'] : Colors.grey,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          issue['title'],
                          style: TextStyle(
                            color: isSelected ? issue['color'] : Colors.grey,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E3F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Additional Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                'Optional',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _commentsController,
            style: TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share any additional thoughts or suggestions...',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        final currentMetrics = networkService.currentMetrics;
        
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1E1E3F).withOpacity(0.8),
                Color(0xFF2D2D5F).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF6C63FF), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Current Network Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  // Auto-refresh status indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _autoRefreshEnabled 
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _autoRefreshEnabled ? Icons.autorenew : Icons.pause,
                          color: _autoRefreshEnabled ? Colors.green : Colors.grey,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _autoRefreshEnabled ? 'Auto' : 'Manual',
                          style: TextStyle(
                            color: _autoRefreshEnabled ? Colors.green : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (_isLoadingNetworkInfo)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                        strokeWidth: 2,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Collecting network information...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._buildInfoItems(currentMetrics),
              
              // Last refresh time
              if (_lastRefreshTime != null && !_isLoadingNetworkInfo)
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.update, color: Colors.grey, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Last updated: ${_formatTime(_lastRefreshTime!)}',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Spacer(),
                        if (_autoRefreshEnabled)
                          Text(
                            'Next: ${_getNextRefreshTime()}',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getNextRefreshTime() {
    if (_lastRefreshTime == null) return 'Soon';
    
    final nextRefresh = _lastRefreshTime!.add(Duration(seconds: 30));
    final now = DateTime.now();
    final difference = nextRefresh.difference(now);
    
    if (difference.inSeconds <= 0) {
      return 'Now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else {
      return '${difference.inMinutes}m ${difference.inSeconds % 60}s';
    }
  }

  List<Widget> _buildInfoItems(NetworkMetrics? metrics) {
    final items = [
      {
        'icon': Icons.access_time,
        'label': 'Timestamp',
        'value': metrics?.timestamp != null 
            ? '${metrics!.timestamp.toString().substring(0, 19)}'
            : DateTime.now().toString().substring(0, 19),
        'trend': null,
      },
      {
        'icon': Icons.location_on,
        'label': 'Location',
        'value': metrics?.city != null 
            ? '${metrics!.city}, ${metrics.country ?? 'Unknown'}'
            : 'Location not available',
        'trend': null,
      },
      {
        'icon': Icons.network_cell,
        'label': 'Carrier',
        'value': metrics?.carrier ?? 'Unknown',
        'trend': null,
      },
      {
        'icon': Icons.signal_cellular_4_bar,
        'label': 'Network Type',
        'value': metrics?.networkType ?? 'Unknown',
        'trend': null,
      },
      {
        'icon': Icons.signal_wifi_4_bar,
        'label': 'Signal Strength',
        'value': metrics?.signalStrength != null 
            ? '${metrics!.signalStrength} dBm'
            : 'Not available',
        'trend': _trends['signal'],
      },
      {
        'icon': Icons.speed,
        'label': 'Download Speed',
        'value': metrics?.downloadSpeed != null 
            ? '${metrics!.downloadSpeed!.toStringAsFixed(1)} Mbps'
            : 'Not available',
        'trend': _trends['download'],
      },
      {
        'icon': Icons.upload,
        'label': 'Upload Speed',
        'value': metrics?.uploadSpeed != null 
            ? '${metrics!.uploadSpeed!.toStringAsFixed(1)} Mbps'
            : 'Not available',
        'trend': _trends['upload'],
      },
      {
        'icon': Icons.timer,
        'label': 'Latency',
        'value': metrics?.latency != null 
            ? '${metrics!.latency} ms'
            : 'Not available',
        'trend': _trends['latency'],
      },
    ];

    return items
        .map((item) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: Color(0xFF6C63FF),
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              item['value'] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (item['trend'] != null)
                              _buildTrendIndicator(item['trend'] as TrendInfo),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  Widget _buildTrendIndicator(TrendInfo trend) {
    IconData icon;
    Color color;
    String tooltip;
    
    switch (trend.direction) {
      case TrendDirection.improving:
        icon = Icons.trending_up;
        color = Colors.green;
        tooltip = '${trend.percentChange.toStringAsFixed(1)}% improvement';
        break;
      case TrendDirection.stable:
        icon = Icons.trending_flat;
        color = Colors.blue;
        tooltip = 'Stable';
        break;
      case TrendDirection.degrading:
        icon = Icons.trending_down;
        color = Colors.orange;
        tooltip = '${trend.percentChange.toStringAsFixed(1)}% decrease';
        break;
    }
    
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: EdgeInsets.only(left: 8),
        child: Icon(
          icon,
          color: color,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    bool canSubmit = _overallSatisfaction > 0 &&
        _responseTime > 0 &&
        _usability > 0 &&
        !_isSubmitting;

    return ScaleTransition(
      scale: _submitAnimation,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: canSubmit
              ? LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.3),
                    Colors.grey.withOpacity(0.3)
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: canSubmit ? _submitFeedback : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Submitting...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Submit Feedback',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _animateRating(int rating, Function(int) onRatingChanged) {
    onRatingChanged(rating);
    _scaleController.reset();
    _scaleController.forward();
  }

  void _selectIssue(String issue) {
    setState(() {
      _selectedIssue = _selectedIssue == issue ? null : issue;
    });
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - We\'ll work on it';
      case 2:
        return 'Fair - Room for improvement';
      case 3:
        return 'Good - Thanks for the feedback';
      case 4:
        return 'Very Good - Great to hear!';
      case 5:
        return 'Excellent - You made our day!';
      default:
        return '';
    }
  }

  void _submitFeedback() async {
    _submitController.forward().then((_) {
      _submitController.reverse();
    });
    
    setState(() => _isSubmitting = true);

    try {
      debugPrint('🔄 Starting feedback submission...');
      
      // Get real network metrics from NetworkService
      final networkService = Provider.of<NetworkService>(context, listen: false);
      await networkService.collectMetricsNow();
      final currentMetrics = networkService.currentMetrics;
      
      debugPrint('📊 Current metrics: ${currentMetrics?.toMap()}');
      
      // Get location data
      final locationData = await LocationService().getCurrentLocationWithAddress();
      debugPrint('📍 Location data: $locationData');
      
      // Create feedback data with ALL network metrics included
      final feedback = FeedbackData(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        overallSatisfaction: _overallSatisfaction,
        responseTime: _responseTime,
        usability: _usability,
        comments: _commentsController.text.isEmpty ? null : _commentsController.text,
        networkMetricsId: currentMetrics?.id ?? '',
        latitude: locationData['latitude'] ?? 0.0,
        longitude: locationData['longitude'] ?? 0.0,
        carrier: currentMetrics?.carrier ?? 'Unknown',
        city: locationData['city'],
        country: locationData['country'],
        address: locationData['address'],
        isSynced: false,
        // Add these missing fields that were showing as NULL
        issueType: _selectedIssue,
        networkType: currentMetrics?.networkType,
        signalStrength: currentMetrics?.signalStrength,
        downloadSpeed: currentMetrics?.downloadSpeed,
        uploadSpeed: currentMetrics?.uploadSpeed,
        latency: currentMetrics?.latency,
      );

      debugPrint('💬 Feedback data created: ${feedback.toMap()}');

      // Save to storage service first
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.saveFeedback(feedback);
      debugPrint('✅ Feedback saved to storage service');
      
      // Also save current network metrics if available
      if (currentMetrics != null) {
        await storageService.saveNetworkMetrics(currentMetrics.copyWith(isSynced: false));
        debugPrint('✅ Network metrics saved to storage service');
      }

      // Award points for feedback using correct method name
      final rewardService = Provider.of<RewardsService>(context, listen: false);
      final pointsEarned = await rewardService.awardFeedbackPoints();
      debugPrint('🎉 $pointsEarned points awarded for feedback');

      // Trigger sync if connected
      final syncService = Provider.of<SyncService>(context, listen: false);
      try {
        await syncService.syncNow();
        debugPrint('🔄 Sync triggered successfully');
      } catch (e) {
        debugPrint('⚠️ Sync will happen automatically when connected: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thank you for your feedback! You earned $pointsEarned points. Data saved and will sync automatically.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 4),
        ),
      );

      // Clear form
      _commentsController.clear();
      setState(() {
        _overallSatisfaction = 0;
        _responseTime = 0;
        _usability = 0;
        _selectedIssue = null;
      });

      _startAnimations();
      debugPrint('✅ Feedback submission completed successfully');
      
    } catch (e) {
      debugPrint('❌ Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to save feedback. Please try again.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

// Trend direction enum
enum TrendDirection {
  improving,
  stable,
  degrading,
}

// Trend information class
class TrendInfo {
  final String label;
  final TrendDirection direction;
  final double percentChange;
  final double currentValue;
  final double previousValue;
  
  TrendInfo({
    required this.label,
    required this.direction,
    required this.percentChange,
    required this.currentValue,
    required this.previousValue,
  });
}
