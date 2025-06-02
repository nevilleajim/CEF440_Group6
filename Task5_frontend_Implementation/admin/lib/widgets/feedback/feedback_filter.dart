// widgets/feedback/feedback_filter.dart
import 'package:flutter/material.dart';

class FeedbackFilter extends StatefulWidget {
  final Function(String?, int?) onFilterChanged;

  const FeedbackFilter({Key? key, required this.onFilterChanged}) : super(key: key);

  @override
  _FeedbackFilterState createState() => _FeedbackFilterState();
}

class _FeedbackFilterState extends State<FeedbackFilter> {
  String? _selectedLocation;
  int? _selectedRating;

  final List<String> _locations = [
    'All Locations',
    'Douala',
    'Yaoundé',
    'Bamenda',
    'Bafoussam',
    'Garoua',
    'Maroua',
    'Ngaoundéré',
    'Bertoua',
    'Ebolowa',
    'Kribi',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _locations.map((location) {
                      return DropdownMenuItem(
                        value: location == 'All Locations' ? null : location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedLocation = value);
                      widget.onFilterChanged(_selectedLocation, _selectedRating);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedRating,
                    decoration: const InputDecoration(
                      labelText: 'Min Rating',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Ratings')),
                      ...List.generate(5, (index) {
                        final rating = index + 1;
                        return DropdownMenuItem(
                          value: rating,
                          child: Row(
                            children: [
                              Text('$rating'),
                              const SizedBox(width: 4),
                              Icon(Icons.star, size: 16, color: Colors.amber),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedRating = value);
                      widget.onFilterChanged(_selectedLocation, _selectedRating);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
