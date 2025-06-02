// widgets/feedback/feedback_card.dart
import 'package:flutter/material.dart';
import '../../models/feedback.dart' as feedback_model;

class FeedbackCard extends StatelessWidget {
  final feedback_model.Feedback feedback;
  final Map<String, dynamic> theme;

  const FeedbackCard({
    Key? key, 
    required this.feedback,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme['primary'].withOpacity(0.1),
                  theme['secondary'],
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme['primary'].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: theme['primary'],
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feedback.location,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              _formatTimestamp(feedback.timestamp),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildRatingStars(),
                  ],
                ),
              ],
            ),
          ),
          
          // Metrics Table
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Metrics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMetricsTable(),
                
                if (feedback.comments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: theme['primary'],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feedback.comments,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (index) {
            return Icon(
              index < feedback.userRating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 16,
            );
          }),
          const SizedBox(width: 8),
          Text(
            '${feedback.userRating}/5',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsTable() {
    final metrics = [
      {'label': 'Latency', 'value': '${feedback.latency.toStringAsFixed(1)}ms', 'icon': Icons.speed, 'color': _getLatencyColor()},
      {'label': 'Jitter', 'value': '${feedback.jitter.toStringAsFixed(1)}ms', 'icon': Icons.graphic_eq, 'color': _getJitterColor()},
      {'label': 'Signal Strength', 'value': '${feedback.signalStrength.toStringAsFixed(1)}dBm', 'icon': Icons.signal_cellular_alt, 'color': _getSignalColor()},
      {'label': 'Packet Loss', 'value': '${feedback.packetLoss.toStringAsFixed(1)}%', 'icon': Icons.warning_amber, 'color': _getPacketLossColor()},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: metrics.asMap().entries.map((entry) {
          final index = entry.key;
          final metric = entry.value;
          final isLast = index == metrics.length - 1;
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: index % 2 == 0 ? Colors.grey.withOpacity(0.02) : Colors.transparent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(isLast ? 12 : 0),
                bottomRight: Radius.circular(isLast ? 12 : 0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (metric['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    metric['icon'] as IconData,
                    color: metric['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    metric['label'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (metric['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    metric['value'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: metric['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getLatencyColor() {
    if (feedback.latency < 50) return Colors.green;
    if (feedback.latency < 100) return Colors.orange;
    return Colors.red;
  }

  Color _getJitterColor() {
    if (feedback.jitter < 10) return Colors.green;
    if (feedback.jitter < 20) return Colors.orange;
    return Colors.red;
  }

  Color _getSignalColor() {
    if (feedback.signalStrength > -70) return Colors.green;
    if (feedback.signalStrength > -85) return Colors.orange;
    return Colors.red;
  }

  Color _getPacketLossColor() {
    if (feedback.packetLoss < 1) return Colors.green;
    if (feedback.packetLoss < 3) return Colors.orange;
    return Colors.red;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}