// screens/feedback/feedback_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/user.dart';
import '../../models/feedback.dart' as feedback_model;
import '../../widgets/feedback/feedback_card.dart';

class FeedbackScreen extends StatefulWidget {
  final User user;

  const FeedbackScreen({Key? key, required this.user}) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  List<feedback_model.Feedback> _feedbacks = [];
  List<feedback_model.Feedback> _filteredFeedbacks = [];
  bool _isLoading = false;
  
  // Filter and search variables
  String _searchQuery = '';
  int _selectedRatingFilter = 0; // 0 = all ratings
  String _selectedLocationFilter = 'All';
  DateTimeRange? _dateRange;
  final TextEditingController _searchController = TextEditingController();

  // Provider color schemes
  Map<String, Map<String, dynamic>> get _providerThemes => {
    'MTN': {
      'primary': const Color(0xFFFFCC00),
      'secondary': const Color(0xFFFFF8DC),
      'accent': const Color(0xFFFF9800),
      'gradient': [const Color(0xFFFFCC00), const Color(0xFFFF9800)],
      'logo': '🟡',
    },
    'Orange': {
      'primary': const Color(0xFFFF6600),
      'secondary': const Color(0xFFFFF3E0),
      'accent': const Color(0xFFFF8A50),
      'gradient': [const Color(0xFFFF6600), const Color(0xFFFF8A50)],
      'logo': '🟠',
    },
    'blue': {
      'primary': const Color(0xFF1976D2),
      'secondary': const Color(0xFFE3F2FD),
      'accent': const Color(0xFF42A5F5),
      'gradient': [const Color(0xFF1976D2), const Color(0xFF42A5F5)],
      'logo': '🔵',
    },
  };

  Map<String, dynamic> get _currentTheme => 
      _providerThemes[widget.user.provider] ?? _providerThemes['blue']!;

  @override
  void initState() {
    super.initState();
    _loadDummyData(); // Using dummy data for demonstration
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty || 
           _selectedRatingFilter > 0 || 
           _selectedLocationFilter != 'All' || 
           _dateRange != null;
  }

  void _applyFilters() {
    setState(() {
      _filteredFeedbacks = _feedbacks.where((feedback) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          if (!feedback.location.toLowerCase().contains(searchLower) &&
              !feedback.comments.toLowerCase().contains(searchLower)) {
            return false;
          }
        }

        // Rating filter
        if (_selectedRatingFilter > 0 && feedback.userRating != _selectedRatingFilter) {
          return false;
        }

        // Location filter
        if (_selectedLocationFilter != 'All' && feedback.location != _selectedLocationFilter) {
          return false;
        }

        // Date range filter
        if (_dateRange != null) {
          final feedbackDate = DateTime(
            feedback.timestamp.year,
            feedback.timestamp.month,
            feedback.timestamp.day,
          );
          final startDate = DateTime(
            _dateRange!.start.year,
            _dateRange!.start.month,
            _dateRange!.start.day,
          );
          final endDate = DateTime(
            _dateRange!.end.year,
            _dateRange!.end.month,
            _dateRange!.end.day,
          );
          
          if (feedbackDate.isBefore(startDate) || feedbackDate.isAfter(endDate)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _loadDummyData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate dummy feedback data
    _feedbacks = List.generate(8, (index) {
      final locations = ['Bamenda', 'Douala', 'Yaoundé', 'Buea', 'Limbe', 'Bafoussam', 'Ngaoundéré', 'Garoua'];
      final comments = [
        'Excellent network quality, very satisfied with the service.',
        'Good coverage but occasional drops during peak hours.',
        'Outstanding performance, highly recommended!',
        'Average service, room for improvement in rural areas.',
        'Very reliable connection, great for business use.',
        'Fast speeds but high latency sometimes affects video calls.',
        'Consistent quality throughout the day.',
        'Could be better, facing connectivity issues occasionally.',
      ];

      return feedback_model.Feedback(
        id: 'fb_${index + 1}',
        timestamp: DateTime.now().subtract(Duration(days: index, hours: index * 2)),
        location: locations[index % locations.length],
        jitter: 5.0 + (index * 2.5),
        latency: 45.0 + (index * 8.0),
        packetLoss: 0.1 + (index * 0.3),
        signalStrength: -65.0 - (index * 3.0),
        userRating: 5 - (index % 3),
        comments: index % 3 == 0 ? comments[index % comments.length] : '',
        description: 'Network performance feedback from ${locations[index % locations.length]}',
        latitude: 5.9 + (index * 0.1),
        longitude: 10.1 + (index * 0.1),
      );
    });

    _filteredFeedbacks = List.from(_feedbacks);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadFeedbacks() async {
    // final feedbacks = await _apiService.getFeedbacks(widget.user.provider);
    // For now, reload dummy data
    await _loadDummyData();
  }

  Future<void> _exportToCSV() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/feedback_export.csv';
      final file = File(path);

      String csvContent = 'ID,Timestamp,Location,Rating,Latency,Signal Strength,Comments\n';
      
      for (final feedback in _filteredFeedbacks) {
        csvContent += '${feedback.id},${feedback.timestamp.toIso8601String()},${feedback.location},${feedback.userRating},${feedback.latency},${feedback.signalStrength},"${feedback.comments}"\n';
      }

      await file.writeAsString(csvContent);
      await Share.shareXFiles([XFile(path)], text: 'Network Feedback Export');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export completed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _clearAllFeedbacks() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text('Are you sure you want to clear all feedback data? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _feedbacks.clear();
                  _filteredFeedbacks.clear();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All feedback data cleared')),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Options'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating filter
                    const Text('Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      children: [0, 1, 2, 3, 4, 5].map((rating) {
                        return FilterChip(
                          label: Text(rating == 0 ? 'All' : '$rating⭐'),
                          selected: _selectedRatingFilter == rating,
                          onSelected: (selected) {
                            setDialogState(() {
                              _selectedRatingFilter = rating;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Location filter
                    const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _selectedLocationFilter,
                      isExpanded: true,
                      items: ['All', 'Bamenda', 'Douala', 'Yaoundé', 'Buea', 'Limbe', 'Bafoussam', 'Ngaoundéré', 'Garoua']
                          .map((location) => DropdownMenuItem(
                                value: location,
                                child: Text(location),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedLocationFilter = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date range filter
                    const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ListTile(
                      title: Text(
                        _dateRange == null 
                            ? 'Select date range' 
                            : '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} - ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}'
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                          initialDateRange: _dateRange,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            _dateRange = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applyFilters();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Search by location or comments...',
          prefixIcon: Icon(Icons.search, color: _currentTheme['primary']),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _currentTheme['primary'], width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    if (!_hasActiveFilters()) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Active Filters:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedRatingFilter = 0;
                    _selectedLocationFilter = 'All';
                    _dateRange = null;
                    _searchController.clear();
                  });
                  _applyFilters();
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (_searchQuery.isNotEmpty)
                Chip(
                  label: Text('Search: "$_searchQuery"'),
                  labelStyle: const TextStyle(fontSize: 10),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                ),
              if (_selectedRatingFilter > 0)
                Chip(
                  label: Text('Rating: $_selectedRatingFilter'),
                  labelStyle: const TextStyle(fontSize: 10),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _selectedRatingFilter = 0;
                    });
                    _applyFilters();
                  },
                ),
              if (_selectedLocationFilter != 'All')
                Chip(
                  label: Text('Location: $_selectedLocationFilter'),
                  labelStyle: const TextStyle(fontSize: 10),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _selectedLocationFilter = 'All';
                    });
                    _applyFilters();
                  },
                ),
              if (_dateRange != null)
                Chip(
                  label: Text('Date: ${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'),
                  labelStyle: const TextStyle(fontSize: 10),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _dateRange = null;
                    });
                    _applyFilters();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: _currentTheme['primary'],
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: _currentTheme['primary'],
          secondary: _currentTheme['accent'],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: kToolbarHeight,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentTheme['gradient'],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          titleSpacing: 10,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.user.provider} Provider',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              tooltip: 'Export to CSV',
              onPressed: _filteredFeedbacks.isEmpty ? null : _exportToCSV,
              constraints: const BoxConstraints(minHeight: 60, minWidth: 40),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white),
                  if (_hasActiveFilters())
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
              tooltip: 'Filter',
              onPressed: _showFilterDialog,
              constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
              padding: EdgeInsets.zero,
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'clear') _clearAllFeedbacks();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All Data'),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 36,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        widget.user.name,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_currentTheme['primary']),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading feedback data...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: _currentTheme['primary'],
                onRefresh: _loadFeedbacks,
                child: _feedbacks.isEmpty
                    ? _buildEmptyState()
                    : CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: _buildSearchBar()),
                          SliverToBoxAdapter(child: _buildStatsHeader()),
                          SliverToBoxAdapter(child: _buildActiveFiltersChips()),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => FeedbackCard(
                                feedback: _filteredFeedbacks[index],
                                theme: _currentTheme,
                              ),
                              childCount: _filteredFeedbacks.length,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        ],
                      ),
              ),
      ),
    );
  }


  Widget _buildStatsHeader() {
    if (_filteredFeedbacks.isEmpty) return const SizedBox.shrink();

    final avgRating = _filteredFeedbacks.map((f) => f.userRating).reduce((a, b) => a + b) / _filteredFeedbacks.length;
    final avgLatency = _filteredFeedbacks.map((f) => f.latency).reduce((a, b) => a + b) / _filteredFeedbacks.length;
    final avgSignal = _filteredFeedbacks.map((f) => f.signalStrength).reduce((a, b) => a + b) / _filteredFeedbacks.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: _currentTheme['primary'],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Performance Overview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentTheme['primary'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_filteredFeedbacks.length} of ${_feedbacks.length} items',
                            style: TextStyle(
                              fontSize: 12,
                              color: _currentTheme['primary'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Avg Rating',
                  '${avgRating.toStringAsFixed(1)}/5',
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Latency',
                  '${avgLatency.toStringAsFixed(0)}ms',
                  Icons.speed,
                  _currentTheme['primary'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Signal',
                  '${avgSignal.toStringAsFixed(0)}dBm',
                  Icons.signal_cellular_alt,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.feedback_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Feedback Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh and check for new feedback',
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