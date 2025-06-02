import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dashboard_screen.dart';
import 'feedback_screen.dart';
import 'speed_test_screen.dart';
import 'settings_screen.dart';
import 'view_logs_screen.dart';
import '../widgets/navigation_bar.dart';
import '../services/network_service.dart';
import '../models/network_metrics.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final NetworkService _networkService = NetworkService();
  NetworkMetrics? currentMetrics;

  late AnimationController _pulseController;
  late AnimationController _rotationController;

  final List<Widget> _screens = [
    HomePage(),
    DashboardScreen(),
    FeedbackScreen(),
    SpeedTestScreen(),
    LogsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _networkService.startMonitoring();
    _networkService.metricsStream.listen((metrics) {
      setState(() {
        currentMetrics = metrics;
      });
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _networkService.stopMonitoring();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final NetworkService _networkService = NetworkService();
  NetworkMetrics? _currentMetrics;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _startNetworkMonitoring();
  }

  void _startNetworkMonitoring() {
    _networkService.startMonitoring();
    _networkService.metricsStream.listen((metrics) {
      if (mounted) {
        setState(() {
          _currentMetrics = metrics;
        });
      }
    });
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
  }

  void _startAnimations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) _fadeController.forward();
        });
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) _slideController.forward();
        });
        Future.delayed(Duration(milliseconds: 400), () {
          if (mounted) _scaleController.forward();
        });
      }
    });
  }

  String _getNetworkQualityStatus(NetworkMetrics? metrics) {
    if (metrics == null) return 'Unknown';

    // Evaluate based on latency and signal strength
    if (metrics.latency != null &&
        metrics.latency! < 50 &&
        metrics.signalStrength > -70) {
      return 'Excellent';
    } else if (metrics.latency != null &&
        metrics.latency! < 100 &&
        metrics.signalStrength > -85) {
      return 'Good';
    } else if (metrics.latency != null && metrics.latency! < 150) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'Excellent':
        return Color(0xFF10B981);
      case 'Good':
        return Color(0xFF6366F1);
      case 'Fair':
        return Color(0xFFF59E0B);
      case 'Poor':
        return Color(0xFFEF4444);
      default:
        return Color(0xFF64748B);
    }
  }

  String _getMetricQuality(String metric, dynamic value) {
    if (value == null) return 'N/A';

    switch (metric) {
      case 'download':
        double speed = value.toDouble();
        if (speed >= 25) return 'Excellent';
        if (speed >= 10) return 'Good';
        if (speed >= 5) return 'Fair';
        return 'Poor';

      case 'upload':
        double speed = value.toDouble();
        if (speed >= 5) return 'Excellent';
        if (speed >= 2) return 'Good';
        if (speed >= 1) return 'Fair';
        return 'Poor';

      case 'latency':
        int latency = value;
        if (latency <= 30) return 'Excellent';
        if (latency <= 60) return 'Good';
        if (latency <= 100) return 'Fair';
        return 'Poor';

      case 'jitter':
        double jitter = value.toDouble();
        if (jitter <= 5) return 'Excellent';
        if (jitter <= 15) return 'Good';
        if (jitter <= 30) return 'Fair';
        return 'Poor';

      default:
        return 'Good';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _networkService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAppBar(),
                          SizedBox(height: 24),
                          _buildHeroSection(),
                          SizedBox(height: 24),
                          _buildNetworkStatusCard(),
                          SizedBox(height: 20),
                          _buildStatsGrid(),
                          SizedBox(height: 20),
                          _buildQuickActions(),
                          SizedBox(height: 20),
                          _buildInsightsCard(),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SlideTransition(
      position: _slideAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  'QoE App',
                  style: TextStyle(
                    color: Color.fromARGB(255, 5, 39, 119),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen()),
            ),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF0F172A).withOpacity(0.06),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: Color(0xFF475569),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFF3B82F6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6366F1).withOpacity(0.25),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(110, 110),
                        painter: WavePainter(_waveAnimation.value),
                      );
                    },
                  ),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.network_check_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Your Voice Matters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Know Your Network. Improve Your Experience.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard() {
    String quality = _getNetworkQualityStatus(_currentMetrics);
    Color qualityColor = _getQualityColor(quality);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 16,
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
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: qualityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.signal_cellular_4_bar_rounded,
                        color: qualityColor,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Network Status',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [qualityColor, qualityColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        quality,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Provider',
                    _currentMetrics?.carrier ?? 'Unknown',
                    Icons.business_rounded,
                    Color(0xFF6366F1),
                  ),
                ),
                Container(
                  width: 1,
                  height: 35,
                  color: Color(0xFFE2E8F0),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Type',
                    _currentMetrics?.networkType ?? 'Unknown',
                    Icons.network_cell_rounded,
                    Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': 'Download',
        'value': _currentMetrics?.downloadSpeed?.toStringAsFixed(1) ?? '--',
        'unit': 'Mbps',
        'icon': Icons.download_rounded,
        'color': Color(0xFF10B981),
        'quality':
            _getMetricQuality('download', _currentMetrics?.downloadSpeed),
      },
      {
        'title': 'Upload',
        'value': _currentMetrics?.uploadSpeed?.toStringAsFixed(1) ?? '--',
        'unit': 'Mbps',
        'icon': Icons.upload_rounded,
        'color': Color(0xFF6366F1),
        'quality': _getMetricQuality('upload', _currentMetrics?.uploadSpeed),
      },
      {
        'title': 'Latency',
        'value': _currentMetrics?.latency?.toString() ?? '--',
        'unit': 'ms',
        'icon': Icons.timer_outlined,
        'color': Color(0xFFEF4444),
        'quality': _getMetricQuality('latency', _currentMetrics?.latency),
      },
      {
        'title': 'Jitter',
        'value': _currentMetrics?.jitter?.toStringAsFixed(1) ?? '--',
        'unit': 'ms',
        'icon': Icons.graphic_eq_rounded,
        'color': Color(0xFFF59E0B),
        'quality': _getMetricQuality('jitter', _currentMetrics?.jitter),
      },
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              String quality = stat['quality'] as String;
              Color qualityColor = _getQualityColor(quality);

              return Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF0F172A).withOpacity(0.03),
                      blurRadius: 8,
                      offset: Offset(0, 2),
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
                            color: (stat['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            stat['icon'] as IconData,
                            color: stat['color'] as Color,
                            size: 18,
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: qualityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            quality == 'N/A' ? '--' : quality,
                            style: TextStyle(
                              color: qualityColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Text(
                      stat['title'] as String,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stat['value'] as String,
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 3),
                        Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            stat['unit'] as String,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Give Feedback',
                  Icons.feedback_outlined,
                  LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FeedbackScreen()),
                    );
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Speed Test',
                  Icons.speed_rounded,
                  LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SpeedTestScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'View Reports',
                  Icons.analytics_outlined,
                  LinearGradient(colors: [
                    Color.fromARGB(255, 239, 68, 199),
                    Color.fromARGB(255, 220, 38, 190)
                  ]),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DashboardScreen()),
                    );
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'View Logs',
                  Icons.history,
                  LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LogsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Gradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Network Insights',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up_rounded,
                      color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Boost your network performance with us. We hold you at heart',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animation;

  WavePainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 5;

    for (int i = 0; i < 3; i++) {
      final currentRadius = radius + (i * 8) + (animation * 15);
      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) =>
      oldDelegate.animation != animation;
}
