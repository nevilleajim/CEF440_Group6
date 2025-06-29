import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_usage_service.dart';
import '../services/sync_service.dart';
import '../services/storage_service.dart';

class DataUsageWidget extends StatelessWidget {
  final bool showDetails;
  final bool isCompact;

  const DataUsageWidget({
    Key? key,
    this.showDetails = false,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DataUsageService>(
      builder: (context, dataUsageService, child) {
        if (isCompact) {
          return _buildCompactView(dataUsageService);
        }
        return _buildFullView(context, dataUsageService);
      },
    );
  }

  Widget _buildCompactView(DataUsageService dataUsageService) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.data_usage, size: 14, color: Colors.blue),
          SizedBox(width: 4),
          Text(
            DataUsageService.formatBytes(dataUsageService.totalBytes),
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context, DataUsageService dataUsageService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.data_usage, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Data Usage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                if (showDetails)
                  TextButton(
                    onPressed: () => _showDetailedUsage(context, dataUsageService),
                    child: Text('View Details'),
                  ),
              ],
            ),
            SizedBox(height: 16),
            
            // Current session (if active)
            Consumer<SyncService>(
              builder: (context, syncService, child) {
                if (syncService.isSyncing && dataUsageService.currentSessionTotal > 0) {
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Sync Session',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          DataUsageService.formatBytes(dataUsageService.currentSessionTotal),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            
            if (dataUsageService.currentSessionTotal > 0) SizedBox(height: 12),
            
            // Usage statistics
            Row(
              children: [
                Expanded(
                  child: _buildUsageStat(
                    'Today',
                    DataUsageService.formatBytes(dataUsageService.getTodayUsage()),
                    Icons.today,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildUsageStat(
                    'This Month',
                    DataUsageService.formatBytes(dataUsageService.getThisMonthUsage()),
                    Icons.calendar_month,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildUsageStat(
                    'Total',
                    DataUsageService.formatBytes(dataUsageService.totalBytes),
                    Icons.storage,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildUsageStat(
                    'Sessions',
                    '${dataUsageService.syncSessionsCount}',
                    Icons.sync,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Pending data estimate
            Consumer2<StorageService, SyncService>(
              builder: (context, storageService, syncService, child) {
                final stats = storageService.getDataStats();
                final pendingMetrics = stats['metricsUnsynced'] ?? 0;
                final pendingFeedback = stats['feedbackUnsynced'] ?? 0;
                
                if (pendingMetrics > 0 || pendingFeedback > 0) {
                  final estimatedUsage = dataUsageService.estimateDataUsageForPendingItems(
                    pendingMetrics,
                    pendingFeedback,
                  );
                  
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Sync',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                              Text(
                                '~${DataUsageService.formatBytes(estimatedUsage)} estimated',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedUsage(BuildContext context, DataUsageService dataUsageService) {
    showDialog(
      context: context,
      builder: (context) => DataUsageDetailDialog(dataUsageService: dataUsageService),
    );
  }
}

class DataUsageDetailDialog extends StatelessWidget {
  final DataUsageService dataUsageService;

  const DataUsageDetailDialog({
    Key? key,
    required this.dataUsageService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = dataUsageService.getUsageStats();
    
    return AlertDialog(
      title: Text('Data Usage Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Total Data Used', DataUsageService.formatBytes(stats['totalBytes'])),
            _buildDetailRow('Data Uploaded', DataUsageService.formatBytes(stats['totalBytesUploaded'])),
            _buildDetailRow('Data Downloaded', DataUsageService.formatBytes(stats['totalBytesDownloaded'])),
            Divider(),
            _buildDetailRow('Sync Sessions', '${stats['syncSessions']}'),
            _buildDetailRow('Average per Session', DataUsageService.formatBytes(stats['averagePerSession'].round())),
            _buildDetailRow('Average per Day', DataUsageService.formatBytes(stats['averagePerDay'].round())),
            Divider(),
            _buildDetailRow('Today\'s Usage', DataUsageService.formatBytes(stats['todayUsage'])),
            _buildDetailRow('This Month\'s Usage', DataUsageService.formatBytes(stats['thisMonthUsage'])),
            _buildDetailRow('Days Tracking', '${stats['daysTracking']}'),
            
            SizedBox(height: 16),
            
            // Reset button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showResetConfirmation(context);
                },
                icon: Icon(Icons.refresh),
                label: Text('Reset Statistics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Data Usage Statistics'),
        content: Text('Are you sure you want to reset all data usage statistics? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              dataUsageService.resetUsageStats();
              Navigator.of(context).pop(); // Close confirmation
              Navigator.of(context).pop(); // Close details dialog
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
