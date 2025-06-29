import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';

class SyncStatusWidget extends StatelessWidget {
  final bool showDetails;
  final bool isCompact;

  const SyncStatusWidget({
    Key? key,
    this.showDetails = false,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 8,
            vertical: isCompact ? 2 : 4,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor(syncService).withOpacity(0.1),
            borderRadius: BorderRadius.circular(isCompact ? 12 : 20),
            border: Border.all(
              color: _getStatusColor(syncService),
              width: 1,
            ),
          ),
          child: isCompact ? _buildCompactView(syncService) : _buildFullView(syncService),
        );
      },
    );
  }

  Widget _buildCompactView(SyncService syncService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIcon(syncService),
        if (syncService.pendingItems > 0) ...[
          SizedBox(width: 4),
          Text(
            '${syncService.pendingItems}',
            style: TextStyle(
              fontSize: 10,
              color: _getStatusColor(syncService),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFullView(SyncService syncService) {
    return InkWell(
      onTap: showDetails ? () => _showSyncDetails(syncService) : null,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(syncService),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getStatusText(syncService),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(syncService),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (syncService.pendingItems > 0 && !syncService.isSyncing)
                Text(
                  '${syncService.pendingItems} pending',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(syncService).withOpacity(0.7),
                  ),
                ),
              if (syncService.lastSyncTime != null && !syncService.isSyncing)
                Text(
                  _getLastSyncText(syncService.lastSyncTime!),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(syncService).withOpacity(0.7),
                  ),
                ),
            ],
          ),
          if (showDetails) ...[
            SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: 14,
              color: _getStatusColor(syncService).withOpacity(0.7),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(SyncService syncService) {
    if (syncService.isSyncing) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(syncService)),
        ),
      );
    }

    return Icon(
      _getStatusIcon(syncService),
      size: 14,
      color: _getStatusColor(syncService),
    );
  }

  Color _getStatusColor(SyncService syncService) {
    if (syncService.isSyncing) return Colors.blue;
    if (syncService.syncStatus.contains('failed')) return Colors.red;
    if (syncService.syncStatus.contains('completed')) return Colors.green;
    if (syncService.pendingItems > 0) return Colors.orange;
    if (syncService.syncStatus.contains('No internet')) return Colors.grey;
    return Colors.blue;
  }

  IconData _getStatusIcon(SyncService syncService) {
    if (syncService.syncStatus.contains('failed')) return Icons.error_outline;
    if (syncService.syncStatus.contains('completed')) return Icons.check_circle_outline;
    if (syncService.pendingItems > 0) return Icons.cloud_upload_outlined;
    if (syncService.syncStatus.contains('No internet')) return Icons.cloud_off_outlined;
    return Icons.cloud_outlined;
  }

  String _getStatusText(SyncService syncService) {
    if (syncService.isSyncing) return 'Syncing...';
    if (syncService.syncStatus.contains('failed')) return 'Sync failed';
    if (syncService.syncStatus.contains('completed')) return 'Synced';
    if (syncService.pendingItems > 0) return 'Pending sync';
    if (syncService.syncStatus.contains('No internet')) return 'Offline';
    return 'Ready';
  }

  String _getLastSyncText(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  void _showSyncDetails(SyncService syncService) {
    // This would show a detailed sync status dialog
    // Implementation depends on your navigation setup
  }
}

// Floating Sync Status Widget for overlay display
class FloatingSyncStatus extends StatelessWidget {
  const FloatingSyncStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        // Only show when syncing or there are pending items
        if (!syncService.isSyncing && syncService.pendingItems == 0) {
          return SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(20),
            child: SyncStatusWidget(showDetails: true),
          ),
        );
      },
    );
  }
}

// Sync Status Banner for prominent display
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        // Only show banner for important status updates
        if (!_shouldShowBanner(syncService)) {
          return SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getBannerColor(syncService),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (syncService.isSyncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  _getBannerIcon(syncService),
                  color: Colors.white,
                  size: 16,
                ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getBannerText(syncService),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!syncService.isSyncing)
                TextButton(
                  onPressed: () => syncService.forceSync(),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowBanner(SyncService syncService) {
    return syncService.isSyncing ||
           syncService.syncStatus.contains('failed') ||
           syncService.syncStatus.contains('No internet') ||
           (syncService.pendingItems > 10); // Show for many pending items
  }

  Color _getBannerColor(SyncService syncService) {
    if (syncService.isSyncing) return Colors.blue;
    if (syncService.syncStatus.contains('failed')) return Colors.red;
    if (syncService.syncStatus.contains('No internet')) return Colors.grey;
    if (syncService.pendingItems > 10) return Colors.orange;
    return Colors.blue;
  }

  IconData _getBannerIcon(SyncService syncService) {
    if (syncService.syncStatus.contains('failed')) return Icons.error;
    if (syncService.syncStatus.contains('No internet')) return Icons.cloud_off;
    if (syncService.pendingItems > 10) return Icons.cloud_upload;
    return Icons.info;
  }

  String _getBannerText(SyncService syncService) {
    if (syncService.isSyncing) return 'Syncing data to server...';
    if (syncService.syncStatus.contains('failed')) return 'Failed to sync data. Check your connection.';
    if (syncService.syncStatus.contains('No internet')) return 'No internet connection. Data will sync when online.';
    if (syncService.pendingItems > 10) return '${syncService.pendingItems} items waiting to sync';
    return 'Sync status update';
  }
}
