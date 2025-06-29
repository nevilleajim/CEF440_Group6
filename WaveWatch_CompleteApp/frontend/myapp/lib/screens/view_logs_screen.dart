// screens/logs_screen.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/network_metrics.dart';
import '../models/feedback_data.dart';
import 'dart:async';

class LogsScreen extends StatefulWidget {
  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storageService = StorageService();
  List<NetworkMetrics> _networkLogs = [];
  List<FeedbackData> _feedbackLogs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLogs();
    
    // Auto-refresh every 2 seconds to show new feedback
    _refreshTimer = Timer.periodic(Duration(seconds: 2), (_) {
      if (mounted) {
        _loadLogs();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadLogs() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔄 Loading logs from StorageService...');
      
      // Initialize storage service if needed
      await _storageService.initialize();
      
      // Get data from StorageService
      final networkLogs = _storageService.getNetworkMetrics();
      final feedbackLogs = _storageService.getFeedbackData();

      debugPrint('📊 Loaded ${networkLogs.length} network logs from StorageService');
      debugPrint('💬 Loaded ${feedbackLogs.length} feedback logs from StorageService');

      if (feedbackLogs.isNotEmpty) {
        debugPrint('📝 First feedback: ${feedbackLogs.first.id} - ${feedbackLogs.first.carrier}');
        debugPrint('📝 Feedback comments: ${feedbackLogs.first.comments ?? "No comments"}');
        debugPrint('📝 Feedback timestamp: ${feedbackLogs.first.timestamp}');
      }

      if (mounted) {
        setState(() {
          _networkLogs = List.from(networkLogs.reversed); // Show latest first
          _feedbackLogs = List.from(feedbackLogs.reversed); // Show latest first
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading logs from StorageService: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load logs: $e');
      }
    }
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text('Clear Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
          content: Text(
            'Are you sure you want to clear all logs? This action cannot be undone.',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performClearLogs();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performClearLogs() async {
    setState(() => _isLoading = true);
    
    try {
      _storageService.clearAllData();
      setState(() {
        _networkLogs.clear();
        _feedbackLogs.clear();
        _isLoading = false;
      });
      _showSuccessSnackBar('Logs cleared successfully');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to clear logs');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        title: Text(
          'Data Logs',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search logs...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[500]),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ),
              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Color(0xFF6366F1),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Color(0xFF6366F1),
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.network_check, size: 20),
                          SizedBox(width: 8),
                          Text('Network (${_networkLogs.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.feedback, size: 20),
                          SizedBox(width: 8),
                          Text('Feedback (${_feedbackLogs.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[700]),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[400]),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6366F1)),
                  SizedBox(height: 16),
                  Text(
                    'Loading logs...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNetworkLogsTab(),
                _buildFeedbackLogsTab(),
              ],
            ),
    );
  }

  Widget _buildNetworkLogsTab() {
    final filteredLogs = _networkLogs.where((log) {
      if (_searchQuery.isEmpty) return true;
      return log.carrier.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.networkType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (log.city?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    if (filteredLogs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.network_check,
        title: _searchQuery.isEmpty ? 'No Network Logs' : 'No Matching Logs',
        subtitle: _searchQuery.isEmpty
            ? 'Network metrics will appear here once collected'
            : 'Try adjusting your search terms',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) => _buildNetworkLogCard(filteredLogs[index]),
    );
  }

  Widget _buildFeedbackLogsTab() {
    final filteredLogs = _feedbackLogs.where((log) {
      if (_searchQuery.isEmpty) return true;
      
      // Safely check nullable fields
      final carrier = log.carrier.toLowerCase();
      final comments = log.comments?.toLowerCase() ?? '';
      
      return carrier.contains(_searchQuery.toLowerCase()) ||
             comments.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredLogs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.feedback,
        title: _searchQuery.isEmpty ? 'No Feedback Logs' : 'No Matching Feedback',
        subtitle: _searchQuery.isEmpty
            ? 'User feedback will appear here once submitted'
            : 'Try adjusting your search terms',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) => _buildFeedbackLogCard(filteredLogs[index]),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey[400]),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkLogCard(NetworkMetrics log) {
    // Determine network quality based on signal strength
    final quality = _getNetworkQuality(log.signalStrength);
    final qualityColor = _getQualityColor(quality);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: qualityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.network_check,
                        color: qualityColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.carrier,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          log.networkType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: qualityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quality,
                    style: TextStyle(
                      color: qualityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Download',
                    '${log.downloadSpeed?.toStringAsFixed(1) ?? '--'} Mbps',
                    Icons.download,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Upload',
                    '${log.uploadSpeed?.toStringAsFixed(1) ?? '--'} Mbps',
                    Icons.upload,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Latency',
                    '${log.latency ?? '--'} ms',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Signal',
                    '${log.signalStrength} dBm',
                    Icons.signal_cellular_4_bar,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            
            if (log.city != null) ...[
              SizedBox(height: 12),
              Divider(color: Colors.grey[200]),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      log.city!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Text(
                    _formatTimestamp(log.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackLogCard(FeedbackData feedback) {
    // Use overallSatisfaction for the rating
    final rating = feedback.overallSatisfaction;
    final ratingColor = _getRatingColor(rating);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.feedback,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.carrier,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          feedback.timestamp.toString().substring(0, 16),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ratingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: ratingColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$rating/5',
                        style: TextStyle(
                          color: ratingColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Comments (if any)
            if (feedback.comments != null && feedback.comments!.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  feedback.comments!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 12),
            
            // Ratings Grid - Using the actual fields from FeedbackData
            Row(
              children: [
                Expanded(
                  child: _buildRatingItem('Overall', feedback.overallSatisfaction),
                ),
                Expanded(
                  child: _buildRatingItem('Response', feedback.responseTime),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildRatingItem('Usability', feedback.usability),
                ),
                Expanded(
                  child: Container(), // Empty container for balance
                ),
              ],
            ),
            
            SizedBox(height: 12),
            Divider(color: Colors.grey[200]),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (feedback.city != null)
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        feedback.city!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        '${feedback.latitude.toStringAsFixed(4)}, ${feedback.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                Text(
                  _formatTimestamp(feedback.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingItem(String label, int rating) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                size: 14,
                color: index < rating ? Colors.amber : Colors.grey[400],
              );
            }),
          ),
        ],
      ),
    );
  }

  // Helper methods for network quality
  String _getNetworkQuality(int signalStrength) {
    if (signalStrength >= -70) return 'Excellent';
    if (signalStrength >= -85) return 'Good';
    if (signalStrength >= -100) return 'Fair';
    return 'Poor';
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'Excellent': return Colors.green;
      case 'Good': return Colors.lightGreen;
      case 'Fair': return Colors.orange;
      case 'Poor': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
