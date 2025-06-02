import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color? color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.black,
                  ),
                ),
                SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}