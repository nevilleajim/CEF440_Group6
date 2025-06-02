// screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserSettings _settings = UserSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _settings = UserSettings(
        notificationFrequency: prefs.getInt('notificationFrequency') ?? 60,
        backgroundCollection: prefs.getBool('backgroundCollection') ?? true,
        rewardPoints: prefs.getInt('rewardPoints') ?? 0,
      );
      _isLoading = false;
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationFrequency', _settings.notificationFrequency);
    await prefs.setBool('backgroundCollection', _settings.backgroundCollection);
    await prefs.setInt('rewardPoints', _settings.rewardPoints);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully!')),
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
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rewards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Points Earned'),
                        Text('${_settings.rewardPoints}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Earn points by providing feedback!', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notification Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            
            SizedBox(height: 24),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Text('QoE Monitor v1.0.0'),
                    Text('Real-time Quality of Experience monitoring for mobile networks in Cameroon.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}