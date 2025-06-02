// screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';
import '../services/database_service.dart';
import '../models/network_metrics.dart';

class CarrierTheme {
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final List<Color> gradient;
  final Color cardColor;

  CarrierTheme({
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.gradient,
    required this.cardColor,
  });
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  List<NetworkMetrics> _recentMetrics = [];
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _rotationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    
    _loadRecentMetrics();
    
    // Auto-refresh every 10 seconds
    Stream.periodic(Duration(seconds: 10)).listen((_) {
      if (mounted) _loadRecentMetrics();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _loadRecentMetrics() async {
    setState(() => _isRefreshing = true);
    _rotationController.forward();
    
    final metrics = await _dbService.getNetworkMetrics(limit: 20);
    if (mounted) {
      setState(() {
        _recentMetrics = metrics;
        _isRefreshing = false;
      });
    }
    _rotationController.reset();
  }

  CarrierTheme _getCarrierTheme(String? carrier) {
    switch (carrier?.toLowerCase()) {
      case 'mtn':
        return CarrierTheme(
          primary: Color(0xFFFFCC00),
          primaryDark: Color(0xFFE6B800),
          secondary: Color(0xFFFFF3B8),
          accent: Color(0xFF1A1A1A),
          gradient: [Color(0xFFFFCC00), Color(0xFFFFD700)],
          cardColor: Color(0xFFFFFDF0),
        );
      case 'orange':
        return CarrierTheme(
          primary: Color(0xFFFF6600),
          primaryDark: Color(0xFFE55A00),
          secondary: Color(0xFFFFE4CC),
          accent: Color(0xFFFFFFFF),
          gradient: [Color(0xFFFF6600), Color(0xFFFF8533)],
          cardColor: Color(0xFFFFF8F3),
        );
      case 'camtel':
      case 'nexttel':
        return CarrierTheme(
          primary: Color(0xFF0066CC),
          primaryDark: Color(0xFF0052A3),
          secondary: Color(0xFFCCE0FF),
          accent: Color(0xFFFFFFFF),
          gradient: [Color(0xFF0066CC), Color(0xFF3385FF)],
          cardColor: Color(0xFFF0F7FF),
        );
      default:
        return CarrierTheme(
          primary: Color(0xFF2C3E50),
          primaryDark: Color(0xFF1A252F),
          secondary: Color(0xFFECF0F1),
          accent: Color(0xFFFFFFFF),
          gradient: [Color(0xFF2C3E50), Color(0xFF3498DB)],
          cardColor: Color(0xFFF8F9FA),
        );
    }
  }

  Color _getLatencyColor(int latency) {
    if (latency <= 30) return Color(0xFF10B981);
    if (latency <= 60) return Color(0xFF6366F1);
    if (latency <= 100) return Color(0xFFF59E0B);
    return Color(0xFFEF4444);
  }

  Color _getJitterColor(double jitter) {
    if (jitter <= 5) return Color(0xFF10B981);
    if (jitter <= 15) return Color(0xFF6366F1);
    if (jitter <= 30) return Color(0xFFF59E0B);
    return Color(0xFFEF4444);
  }

  Color _getPacketLossColor(double packetLoss) {
    if (packetLoss <= 1) return Color(0xFF10B981);
    if (packetLoss <= 3) return Color(0xFF6366F1);
    if (packetLoss <= 5) return Color(0xFFF59E0B);
    return Color(0xFFEF4444);
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, child) {
        final theme = _getCarrierTheme(networkService.currentMetrics?.carrier);
        
        return Scaffold(
          backgroundColor: Color(0xFFF5F7FA),
          appBar: _buildAppBar(theme),
          body: RefreshIndicator(
            onRefresh: () async => _loadRecentMetrics(),
            color: theme.primary,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusOverview(networkService, theme),
                  SizedBox(height: 24),
                  _buildMetricsGrid(networkService, theme),
                  SizedBox(height: 24),
                  _buildRecentActivity(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(CarrierTheme theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.primary,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3 + 0.7 * _pulseController.value),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          SizedBox(width: 12),
          Text(
            'Network Monitor',
            style: TextStyle(
              color: theme.accent,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * 3.14159,
              child: IconButton(
                icon: Icon(Icons.refresh_rounded, color: theme.accent),
                onPressed: _isRefreshing ? null : _loadRecentMetrics,
              ),
            );
          },
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatusOverview(NetworkService networkService, CarrierTheme theme) {
    final metrics = networkService.currentMetrics;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Status',
                  style: TextStyle(
                    color: theme.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: metrics != null ? Colors.greenAccent : Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        metrics != null ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          color: theme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatusMetric(
                    'Carrier',
                    metrics?.carrier ?? 'Unknown',
                    Icons.sim_card_rounded,
                    theme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatusMetric(
                    'Signal',
                    metrics?.signalStrength != null ? '${metrics!.signalStrength} dBm' : 'Unknown',
                    Icons.signal_cellular_4_bar_rounded,
                    theme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatusMetric(
                    'Type',
                    metrics?.networkType ?? 'Unknown',
                    Icons.network_cell_rounded,
                    theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, IconData icon, CarrierTheme theme) {
    return Column(
      children: [
        Icon(icon, color: theme.accent.withOpacity(0.8), size: 24),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: theme.accent.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.accent,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(NetworkService networkService, CarrierTheme theme) {
    final metrics = networkService.currentMetrics;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Latency',
                metrics?.latency != null ? '${metrics!.latency} ms' : 'Unknown',
                Icons.speed_rounded,
                theme,
                _getLatencyColor(metrics?.latency ?? 0),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Jitter',
                metrics?.jitter != null ? '${metrics!.jitter!.toStringAsFixed(1)} ms' : 'Unknown',
                Icons.graphic_eq_rounded,
                theme,
                _getJitterColor(metrics?.jitter ?? 0),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Packet Loss',
                metrics?.packetLoss != null ? '${metrics!.packetLoss!.toStringAsFixed(1)}%' : 'Unknown',
                Icons.error_outline_rounded,
                theme,
                _getPacketLossColor(metrics?.packetLoss ?? 0),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Location',
                metrics?.city ?? 'Unknown',
                Icons.location_on_rounded,
                theme,
                theme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, CarrierTheme theme, Color statusColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: statusColor, size: 18),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(CarrierTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: _recentMetrics.isEmpty
              ? _buildEmptyState(theme)
              : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _recentMetrics.length > 5 ? 5 : _recentMetrics.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Color(0xFFE2E8F0),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final metric = _recentMetrics[index];
                    return ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.network_check_rounded,
                          color: theme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${metric.carrier} - ${metric.networkType}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${metric.latency}ms latency • ${metric.city}',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        '${DateTime.now().difference(metric.timestamp).inMinutes}m ago',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(CarrierTheme theme) {
    return Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 48,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 12),
            Text(
              'No recent activity',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Monitoring will begin automatically',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFBDC3C7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}