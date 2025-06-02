// screens/logs_screen.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/network_metrics.dart';
import '../models/feedback_data.dart';

class LogsScreen extends StatefulWidget {
  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();
  List<NetworkMetrics> _networkLogs = [];
  List<FeedbackData> _feedbackLogs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLogs();
  }

  void _loadLogs() async {
    setState(() => _isLoading = true);
    
    try {
      final networkLogs = await _dbService.getNetworkMetrics(limit: 100);
      final feedbackLogs = await _dbService.getFeedbackData(limit: 100);

      if (mounted) {
        setState(() {
          _networkLogs = networkLogs;
          _feedbackLogs = feedbackLogs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load logs');
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
      await _dbService.clearAllLogs(); // You'll need to implement this method
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
            Text(message),
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
              // Action Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Theme.of(context).primaryColor,
                        indicatorWeight: 3,
                        labelStyle: TextStyle(fontWeight: FontWeight.w600),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.network_cell, size: 12),
                                SizedBox(width: 8),
                                Text('Network'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.feedback, size: 10),
                                SizedBox(width: 4),
                                Text('Feedback'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    // Action Buttons
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue[700]),
                        onPressed: _isLoading ? null : _loadLogs,
                        tooltip: 'Refresh',
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.clear_all, color: Colors.red[700]),
                        onPressed: _isLoading ? null : _clearLogs,
                        tooltip: 'Clear All',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(height: 12),
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
             log.networkType.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredLogs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.network_cell,
        title: _searchQuery.isEmpty ? 'No Network Logs' : 'No Results Found',
        subtitle: _searchQuery.isEmpty 
            ? 'Network logs will appear here once collected'
            : 'Try adjusting your search query',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getNetworkColor(log.signalStrength).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.network_cell,
                color: _getNetworkColor(log.signalStrength),
                size: 24,
              ),
            ),
            title: Text(
              '${log.carrier} - ${log.networkType}',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  _formatDateTime(log.timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                SizedBox(height: 4),
                _buildSignalStrengthBar(log.signalStrength),
              ],
            ),
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Signal', '${log.signalStrength} dBm', Icons.signal_cellular_alt)),
                        SizedBox(width: 8),
                        Expanded(child: _buildMetricCard('Latency', '${log.latency ?? 'N/A'} ms', Icons.speed)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Jitter', '${log.jitter?.toStringAsFixed(2) ?? 'N/A'} ms', Icons.trending_up)),
                        SizedBox(width: 8),
                        Expanded(child: _buildMetricCard('Loss', '${log.packetLoss?.toStringAsFixed(2) ?? 'N/A'}%', Icons.warning)),
                      ],
                    ),
                    if (log.downloadSpeed != null || log.uploadSpeed != null) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          if (log.downloadSpeed != null)
                            Expanded(child: _buildMetricCard('Download', '${log.downloadSpeed!.toStringAsFixed(2)} Mbps', Icons.download)),
                          if (log.downloadSpeed != null && log.uploadSpeed != null)
                            SizedBox(width: 8),
                          if (log.uploadSpeed != null)
                            Expanded(child: _buildMetricCard('Upload', '${log.uploadSpeed!.toStringAsFixed(2)} Mbps', Icons.upload)),
                        ],
                      ),
                    ],
                    SizedBox(height: 12),
                    _buildLocationInfo(log.latitude, log.longitude),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackLogsTab() {
    final filteredLogs = _feedbackLogs.where((feedback) {
      if (_searchQuery.isEmpty) return true;
      return feedback.carrier.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (feedback.comments?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    if (filteredLogs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.feedback,
        title: _searchQuery.isEmpty ? 'No Feedback Logs' : 'No Results Found',
        subtitle: _searchQuery.isEmpty 
            ? 'User feedback will appear here once submitted'
            : 'Try adjusting your search query',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final feedback = filteredLogs[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.feedback, color: Colors.blue[700], size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${feedback.carrier} Feedback',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        Text(
                          _formatDateTime(feedback.timestamp),
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  _buildOverallRating(feedback.overallSatisfaction),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRatingColumn('Response', feedback.responseTime),
                    _buildRatingColumn('Usability', feedback.usability),
                    _buildRatingColumn('Overall', feedback.overallSatisfaction),
                  ],
                ),
              ),
              if (feedback.comments != null && feedback.comments!.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comments',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[800]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        feedback.comments!,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 8),
              _buildLocationInfo(feedback.latitude, feedback.longitude),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 40, color: Colors.grey[400]),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalStrengthBar(int signalStrength) {
    final strength = ((signalStrength + 120) / 70).clamp(0.0, 1.0);
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: strength,
        child: Container(
          decoration: BoxDecoration(
            color: _getNetworkColor(signalStrength),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingColumn(String label, int rating) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              size: 14,
              color: Colors.amber,
            );
          }),
        ),
        Text('$rating/5', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildOverallRating(int rating) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRatingColor(rating).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: _getRatingColor(rating)),
          SizedBox(width: 2),
          Text(
            '$rating/5',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _getRatingColor(rating),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(double latitude, double longitude) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getNetworkColor(int signalStrength) {
    if (signalStrength > -70) return Colors.green;
    if (signalStrength > -85) return Colors.orange;
    return Colors.red;
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}