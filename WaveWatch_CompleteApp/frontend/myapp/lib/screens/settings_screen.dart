// screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/user_settings.dart';
import '../services/reward_service.dart';
import '../services/sync_service.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/data_usage_widget.dart';
import '../services/data_usage_service.dart';
import '../utils/routes.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserSettings _settings = UserSettings();
  bool _isLoading = true;
  late RewardsService _rewardsService;

  @override
  void initState() {
    super.initState();
    _rewardsService = Provider.of<RewardsService>(context, listen: false);
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _settings = UserSettings(
        notificationFrequency: prefs.getInt('notificationFrequency') ?? 60,
        backgroundCollection: prefs.getBool('backgroundCollection') ?? true,
        rewardPoints: _rewardsService.totalPoints,
      );
      _isLoading = false;
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationFrequency', _settings.notificationFrequency);
    await prefs.setBool('backgroundCollection', _settings.backgroundCollection);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Settings saved successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Consumer3<RewardsService, SyncService, DataUsageService>(
        builder: (context, rewardsService, syncService, dataUsageService, child) {
          return ListView(  // Changed from Column to ListView to fix overflow
            padding: EdgeInsets.all(16),
            children: [
              // Rewards Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stars, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Rewards & Achievements',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // Points Display
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Points',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${rewardsService.totalPoints}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Level',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    rewardsService.getLevelName(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Progress to next level
                        if (rewardsService.getPointsForNextLevel() > 0) ...[
                          Text(
                            'Next Level: ${rewardsService.getPointsForNextLevel()} points to go',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 1.0 - (rewardsService.getPointsForNextLevel() / 
                                    (rewardsService.totalPoints + rewardsService.getPointsForNextLevel())),
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ],
                        
                        SizedBox(height: 16),
                        
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Feedback',
                              '${rewardsService.feedbackCount}',
                              Icons.feedback,
                            ),
                            _buildStatItem(
                              'Speed Tests',
                              '${rewardsService.testCount}',
                              Icons.speed,
                            ),
                            _buildStatItem(
                              'Level',
                              '${rewardsService.getUserLevel()}',
                              Icons.trending_up,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),

              // Network Analysis Section - NEW
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Network Analysis',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.sim_card, color: Colors.orange),
                        ),
                        title: Text('Carrier History'),
                        subtitle: Text('Track carrier changes over time and location'),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, Routes.carrierHistory);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),

              // Sync Status Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Synchronization',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      
                      Consumer<SyncService>(
                        builder: (context, syncService, child) {
                          return Column(
                            children: [
                              // Current Status
                              Row(
                                children: [
                                  Text('Status: '),
                                  SyncStatusWidget(showDetails: false),
                                ],
                              ),
                              SizedBox(height: 8),
                              
                              // Sync Stats
                              if (syncService.lastSyncTime != null)
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      'Last sync: ${_formatDateTime(syncService.lastSyncTime!)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              
                              if (syncService.pendingItems > 0) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.cloud_upload, size: 16, color: Colors.orange),
                                    SizedBox(width: 4),
                                    Text(
                                      '${syncService.pendingItems} items pending sync',
                                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                                    ),
                                  ],
                                ),
                              ],
                              
                              SizedBox(height: 12),
                              
                              // Manual Sync Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: syncService.isSyncing ? null : () => syncService.forceSync(),
                                  icon: syncService.isSyncing 
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Icon(Icons.sync),
                                  label: Text(syncService.isSyncing ? 'Syncing...' : 'Sync Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),

              // Data Usage Section
              DataUsageWidget(showDetails: true),
              
              SizedBox(height: 16),
              
              // Notification Settings
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      
                      Text('Feedback Prompt Frequency'),
                      SizedBox(height: 8),
                      DropdownButton<int>(
                        value: _settings.notificationFrequency,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 30, child: Text('Every 30 minutes')),
                          DropdownMenuItem(value: 60, child: Text('Every hour')),
                          DropdownMenuItem(value: 120, child: Text('Every 2 hours')),
                          DropdownMenuItem(value: 240, child: Text('Every 4 hours')),
                          DropdownMenuItem(value: 480, child: Text('Every 8 hours')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _settings = UserSettings(
                              notificationFrequency: value!,
                              backgroundCollection: _settings.backgroundCollection,
                              rewardPoints: _settings.rewardPoints,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Data Collection Settings
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Collection',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      
                      SwitchListTile(
                        title: Text('Background Data Collection'),
                        subtitle: Text('Automatically collect network metrics in background'),
                        value: _settings.backgroundCollection,
                        onChanged: (value) {
                          setState(() {
                            _settings = UserSettings(
                              notificationFrequency: _settings.notificationFrequency,
                              backgroundCollection: value,
                              rewardPoints: _settings.rewardPoints,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // About Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text('QoE Monitor v1.0.0'),
                      Text('Real-time Quality of Experience monitoring for mobile networks in Cameroon.'),
                    ],
                  ),
                ),
              ),
              
              // Add some bottom padding to ensure everything is visible
              SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
