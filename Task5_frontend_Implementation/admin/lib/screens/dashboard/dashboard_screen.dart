// screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/network_analytics.dart';
import '../../widgets/dashboard/analytics_card.dart';
import '../../widgets/dashboard/performance_chart.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<NetworkAnalytics> _analytics = [];
  bool _isLoading = false; // Set to false to show dummy data

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    // Simulating API call with dummy data
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _analytics = _generateDummyData();
      _isLoading = false;
    });
  }

  List<NetworkAnalytics> _generateDummyData() {
    return [
      NetworkAnalytics(
        location: 'Yaoundé Central',
        avgLatency: 45.2,
        avgJitter: 2.1,
        avgPacketLoss: 0.8,
        avgSignalStrength: -68.5,
        avgUserRating: 4.2,
        totalFeedbacks: 1247,
      ),
      NetworkAnalytics(
        location: 'Douala Port',
        avgLatency: 52.8,
        avgJitter: 3.4,
        avgPacketLoss: 1.2,
        avgSignalStrength: -72.1,
        avgUserRating: 3.8,
        totalFeedbacks: 892,
      ),
      NetworkAnalytics(
        location: 'Bamenda Commercial',
        avgLatency: 38.1,
        avgJitter: 1.8,
        avgPacketLoss: 0.5,
        avgSignalStrength: -65.2,
        avgUserRating: 4.5,
        totalFeedbacks: 634,
      ),
      NetworkAnalytics(
        location: 'Bafoussam Market',
        avgLatency: 61.3,
        avgJitter: 4.2,
        avgPacketLoss: 2.1,
        avgSignalStrength: -78.9,
        avgUserRating: 3.4,
        totalFeedbacks: 423,
      ),
      NetworkAnalytics(
        location: 'Limbe Beach',
        avgLatency: 43.7,
        avgJitter: 2.8,
        avgPacketLoss: 1.0,
        avgSignalStrength: -70.4,
        avgUserRating: 4.0,
        totalFeedbacks: 567,
      ),
    ];
  }

  Color _getPrimaryColor() {
    switch (widget.user.provider.toLowerCase()) {
      case 'mtn':
        return const Color(0xFFFFD700); // Gold/Yellow
      case 'orange':
        return const Color(0xFFFF8C00); // Orange
      case 'blue':
      case 'nexttel':
        return const Color(0xFF1E88E5); // Blue
      default:
        return const Color(0xFF2196F3); // Default blue
    }
  }

  Color _getSecondaryColor() {
    switch (widget.user.provider.toLowerCase()) {
      case 'mtn':
        return const Color(0xFFFFA000); // Darker yellow
      case 'orange':
        return const Color(0xFFE65100); // Darker orange
      case 'blue':
      case 'nexttel':
        return const Color(0xFF0D47A1); // Darker blue
      default:
        return const Color(0xFF1565C0); // Default darker blue
    }
  }

  LinearGradient _getGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _getPrimaryColor().withOpacity(0.1),
        _getSecondaryColor().withOpacity(0.05),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_getPrimaryColor()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Analytics...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              color: _getPrimaryColor(),
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: _getGradient(),
                        ),
                      ),
                      title: Text(
                        'Network Analytics',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getPrimaryColor(),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getPrimaryColor().withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.user.provider.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Welcome Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getPrimaryColor(),
                                _getSecondaryColor(),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _getPrimaryColor().withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        widget.user.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.signal_cellular_alt,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Network performance insights for ${widget.user.provider}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        if (_analytics.isNotEmpty) ...[
                          AnalyticsCard(
                            analytics: _analytics,
                            primaryColor: _getPrimaryColor(),
                            secondaryColor: _getSecondaryColor(),
                          ),
                          const SizedBox(height: 20),
                          PerformanceChart(
                            analytics: _analytics,
                            primaryColor: _getPrimaryColor(),
                            secondaryColor: _getSecondaryColor(),
                          ),
                          const SizedBox(height: 20),
                          
                          // Additional insights
                          _buildInsightsSection(),
                        ] else
                          _buildEmptyState(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInsightsSection() {
    final bestLocation = _analytics.reduce((a, b) => 
        a.avgUserRating > b.avgUserRating ? a : b);
    final worstLocation = _analytics.reduce((a, b) => 
        a.avgUserRating < b.avgUserRating ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: _getPrimaryColor(),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Key Insights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.green[600],
                            size: 8,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Best Performance',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bestLocation.location,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${bestLocation.avgUserRating.toStringAsFixed(1)} ⭐',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_down,
                            color: Colors.orange[600],
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Needs Attention',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        worstLocation.location,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${worstLocation.avgUserRating.toStringAsFixed(1)} ⭐',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Analytics Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analytics data will appear here once network monitoring begins',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}