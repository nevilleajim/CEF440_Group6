import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/carrier_tracking_service.dart';
import '../models/carrier_change.dart';

class CarrierHistoryScreen extends StatefulWidget {
  const CarrierHistoryScreen({super.key});

  @override
  State<CarrierHistoryScreen> createState() => _CarrierHistoryScreenState();
}

class _CarrierHistoryScreenState extends State<CarrierHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrier History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Changes'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
            Tab(icon: Icon(Icons.location_on), text: 'Locations'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '24h', child: Text('Last 24 Hours')),
              const PopupMenuItem(value: '7d', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30d', child: Text('Last 30 Days')),
              const PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Consumer<CarrierTrackingService>(
        builder: (context, carrierService, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildChangesTab(carrierService),
              _buildStatisticsTab(carrierService),
              _buildLocationsTab(carrierService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChangesTab(CarrierTrackingService service) {
    final changes = _getFilteredChanges(service);

    if (changes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_cellular_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No carrier changes recorded',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Carrier changes will appear here as they happen',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: changes.length,
      itemBuilder: (context, index) {
        final change = changes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getReasonColor(change.changeReason),
              child: Icon(
                _getReasonIcon(change.changeReason),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              '${change.previousCarrier} → ${change.newCarrier}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateTime(change.timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
                if (change.city != null)
                  Text(
                    '📍 ${change.city}, ${change.country ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                Text(
                  '📶 ${change.networkType} • ${change.signalStrength ?? 'Unknown'} dBm',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(
                change.changeReason.toUpperCase(),
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: _getReasonColor(change.changeReason).withOpacity(0.2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab(CarrierTrackingService service) {
    final stats = service.getCarrierStatistics();
    final carrierUsage = stats['carrierUsage'] as Map<String, int>;
    final changeReasons = stats['changeReasons'] as Map<String, int>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Changes',
                  '${stats['totalChanges']}',
                  Icons.swap_horiz,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Unique Carriers',
                  '${stats['uniqueCarriers']}',
                  Icons.cell_tower,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Most Used',
                  stats['mostUsedCarrier'],
                  Icons.star,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Avg/Day',
                  '${(stats['averageChangesPerDay'] as double).toStringAsFixed(1)}',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Carrier Usage Chart
          if (carrierUsage.isNotEmpty) ...[
            const Text(
              'Carrier Usage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...carrierUsage.entries.map((entry) {
              final percentage = (entry.value / stats['totalChanges'] * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${entry.value} (${percentage.toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCarrierColor(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
          ],

          // Change Reasons Chart
          if (changeReasons.isNotEmpty) ...[
            const Text(
              'Change Reasons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...changeReasons.entries.map((entry) {
              final percentage = (entry.value / stats['totalChanges'] * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getReasonIcon(entry.key),
                              size: 16,
                              color: _getReasonColor(entry.key),
                            ),
                            const SizedBox(width: 8),
                            Text(entry.key.toUpperCase()),
                          ],
                        ),
                        Text('${entry.value} (${percentage.toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getReasonColor(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationsTab(CarrierTrackingService service) {
    final changesByCity = service.getCarrierChangesByCity();

    if (changesByCity.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No location data available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Location data will appear here when available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: changesByCity.keys.length,
      itemBuilder: (context, index) {
        final city = changesByCity.keys.elementAt(index);
        final changes = changesByCity[city]!;
        final carriers = changes.map((c) => c.newCarrier).toSet();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.location_city),
            title: Text(city),
            subtitle: Text('${changes.length} changes • ${carriers.length} carriers'),
            children: changes.map((change) {
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                title: Text('${change.previousCarrier} → ${change.newCarrier}'),
                subtitle: Text(_formatDateTime(change.timestamp)),
                trailing: Text(change.changeReason.toUpperCase()),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<CarrierChange> _getFilteredChanges(CarrierTrackingService service) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case '24h':
        startDate = now.subtract(const Duration(hours: 24));
        break;
      case '7d':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        startDate = now.subtract(const Duration(days: 30));
        break;
      default:
        return service.carrierChanges;
    }

    return service.getCarrierChangesInPeriod(
      startDate: startDate,
      endDate: now,
    );
  }

  Color _getReasonColor(String reason) {
    switch (reason.toLowerCase()) {
      case 'roaming':
        return Colors.red;
      case 'location':
        return Colors.blue;
      case 'manual':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getReasonIcon(String reason) {
    switch (reason.toLowerCase()) {
      case 'roaming':
        return Icons.travel_explore;
      case 'location':
        return Icons.location_on;
      case 'manual':
        return Icons.touch_app;
      default:
        return Icons.autorenew;
    }
  }

  Color _getCarrierColor(String carrier) {
    // Simple hash-based color generation
    final hash = carrier.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
