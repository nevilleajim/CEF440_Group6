import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../models/network_metrics.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  List<NetworkMetrics> _recentMetrics = [];
  Map<String, dynamic> _dataStats = {};

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadDashboardData();
    _startPeriodicRefresh();
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted && !_isRefreshing) {
        _loadDashboardData(isAutoRefresh: true);
      }
    });
  }

  Future<void> _loadDashboardData({bool isAutoRefresh = false}) async {
    if (!isAutoRefresh) {
      setState(() => _isRefreshing = true);
    }

    try {
      // Get fresh network data
      final networkService = Provider.of<NetworkService>(context, listen: false);
      await networkService.collectMetricsNow();

      // Get storage service data
      final storageService = Provider.of<StorageService>(context, listen: false);
      final recentMetrics = await storageService.getRecentNetworkMetrics(5);
      final dataStats = storageService.getDataStats();

      if (mounted) {
        setState(() {
          _recentMetrics = recentMetrics;
          _dataStats = dataStats;
          if (!isAutoRefresh) _isRefreshing = false;
        });
      }

      debugPrint('📊 Dashboard data loaded: ${recentMetrics.length} recent metrics');
    } catch (e) {
      debugPrint('❌ Error loading dashboard data: $e');
      if (!isAutoRefresh && mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F23),
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: RefreshIndicator(
                onRefresh: () => _loadDashboardData(),
                color: Color(0xFF6C63FF),
                backgroundColor: Color(0xFF1E1E3F),
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 24),
                      _buildCurrentNetworkCard(),
                      SizedBox(height: 24),
                      _buildQuickStats(),
                      SizedBox(height: 24),
                      _buildRecentMetricsSection(),
                      SizedBox(height: 24),
                      _buildSyncStatusCard(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                  'Network Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Real-time network monitoring',
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
            child: _isRefreshing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.dashboard, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentNetworkCard() {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        final currentMetrics = networkService.currentMetrics;
        final quality = networkService.getNetworkQualityStatus(currentMetrics);
        final qualityColor = networkService.getQualityColor(quality);

        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1E1E3F).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: qualityColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: qualityColor.withOpacity(0.2),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: qualityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getQualityIcon(quality),
                      color: qualityColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Network Quality',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          quality,
                          style: TextStyle(
                            color: qualityColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (currentMetrics != null) ...[
                _buildMetricRow('Carrier', currentMetrics.carrier, Icons.network_cell),
                _buildMetricRow('Network Type', currentMetrics.networkType, Icons.signal_cellular_4_bar),
                _buildMetricRow('Signal Strength', '${currentMetrics.signalStrength} dBm', Icons.signal_wifi_4_bar),
                if (currentMetrics.downloadSpeed != null)
                  _buildMetricRow('Download Speed', '${currentMetrics.downloadSpeed!.toStringAsFixed(1)} Mbps', Icons.download),
                if (currentMetrics.uploadSpeed != null)
                  _buildMetricRow('Upload Speed', '${currentMetrics.uploadSpeed!.toStringAsFixed(1)} Mbps', Icons.upload),
                if (currentMetrics.latency != null)
                  _buildMetricRow('Latency', '${currentMetrics.latency} ms', Icons.timer),
              ] else
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                        strokeWidth: 2,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Collecting network data...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
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
              icon,
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
                  label,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Metrics',
            '${_dataStats['metricsTotal'] ?? 0}',
            Icons.analytics,
            Color(0xFF6C63FF),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Feedback Items',
            '${_dataStats['feedbackTotal'] ?? 0}',
            Icons.feedback,
            Color(0xFF9F7AEA),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E3F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Network Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),
        if (_recentMetrics.isEmpty)
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E3F).withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.signal_cellular_off,
                    color: Colors.grey,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No recent network data',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start monitoring to see network metrics',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _recentMetrics.length,
            itemBuilder: (context, index) {
              final metric = _recentMetrics[index];
              return _buildMetricListItem(metric, index);
            },
          ),
      ],
    );
  }

  Widget _buildMetricListItem(NetworkMetrics metric, int index) {
    final networkService = Provider.of<NetworkService>(context, listen: false);
    final quality = networkService.getNetworkQualityStatus(metric);
    final qualityColor = networkService.getQualityColor(quality);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E3F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: qualityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: qualityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getQualityIcon(quality),
              color: qualityColor,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      metric.carrier,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: qualityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        quality,
                        style: TextStyle(
                          color: qualityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${metric.networkType} • ${metric.signalStrength} dBm',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (metric.downloadSpeed != null)
                Text(
                  '↓ ${metric.downloadSpeed!.toStringAsFixed(1)} Mbps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                _formatTime(metric.timestamp),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
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

  IconData _getQualityIcon(String quality) {
    switch (quality) {
      case 'Excellent':
        return Icons.signal_cellular_4_bar;
      case 'Good':
        return Icons.signal_cellular_0_bar;
      case 'Fair':
        return Icons.signal_cellular_0_bar;
      case 'Poor':
        return Icons.signal_cellular_0_bar;
      case 'No Internet':
        return Icons.signal_cellular_off;
      default:
        return Icons.signal_cellular_null;
    }
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
}
