// widgets/dashboard/analytics_card.dart
import 'package:flutter/material.dart';
import '../../models/network_analytics.dart';

class AnalyticsCard extends StatelessWidget {
  final List<NetworkAnalytics> analytics;
  final Color primaryColor;
  final Color secondaryColor;

  const AnalyticsCard({
    Key? key,
    required this.analytics,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final avgLatency = analytics.isEmpty ? 0.0 : 
        analytics.map((a) => a.avgLatency).reduce((a, b) => a + b) / analytics.length;
    final avgRating = analytics.isEmpty ? 0.0 :
        analytics.map((a) => a.avgUserRating).reduce((a, b) => a + b) / analytics.length;
    final totalFeedbacks = analytics.isEmpty ? 0 :
        analytics.map((a) => a.totalFeedbacks).reduce((a, b) => a + b);
    final avgPacketLoss = analytics.isEmpty ? 0.0 :
        analytics.map((a) => a.avgPacketLoss).reduce((a, b) => a + b) / analytics.length;
    final avgSignalStrength = analytics.isEmpty ? 0.0 :
        analytics.map((a) => a.avgSignalStrength).reduce((a, b) => a + b) / analytics.length;

    return Container(
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
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.1),
                  secondaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Network Performance Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          
          // Metrics Grid
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Average Latency',
                        '${avgLatency.toStringAsFixed(1)}ms',
                        Icons.speed,
                        _getLatencyColor(avgLatency),
                        _getLatencyStatus(avgLatency),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'User Rating',
                        '${avgRating.toStringAsFixed(1)}/5',
                        Icons.star,
                        _getRatingColor(avgRating),
                        _getRatingStatus(avgRating),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Feedback',
                        _formatNumber(totalFeedbacks),
                        Icons.feedback,
                        primaryColor,
                        'Responses',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Packet Loss',
                        '${avgPacketLoss.toStringAsFixed(1)}%',
                        Icons.network_check,
                        _getPacketLossColor(avgPacketLoss),
                        _getPacketLossStatus(avgPacketLoss),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMetricCard(
                  'Signal Strength',
                  '${avgSignalStrength.toStringAsFixed(1)}dBm',
                  Icons.signal_cellular_alt,
                  _getSignalColor(avgSignalStrength),
                  _getSignalStatus(avgSignalStrength),
                  isWide: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String status, {
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: isWide
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }

  Color _getLatencyColor(double latency) {
    if (latency < 30) return Colors.green;
    if (latency < 60) return Colors.orange;
    return Colors.red;
  }

  String _getLatencyStatus(double latency) {
    if (latency < 30) return 'Excellent';
    if (latency < 60) return 'Good';
    return 'Poor';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getRatingStatus(double rating) {
    if (rating >= 4.0) return 'Excellent';
    if (rating >= 3.0) return 'Good';
    return 'Poor';
  }

  Color _getPacketLossColor(double loss) {
    if (loss < 1.0) return Colors.green;
    if (loss < 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getPacketLossStatus(double loss) {
    if (loss < 1.0) return 'Excellent';
    if (loss < 3.0) return 'Fair';
    return 'Poor';
  }

  Color _getSignalColor(double signal) {
    if (signal > -70) return Colors.green;
    if (signal > -85) return Colors.orange;
    return Colors.red;
  }

  String _getSignalStatus(double signal) {
    if (signal > -70) return 'Strong';
    if (signal > -85) return 'Moderate';
    return 'Weak';
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}