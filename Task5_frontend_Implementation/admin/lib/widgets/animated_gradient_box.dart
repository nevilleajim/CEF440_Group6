import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';

class AnimatedGradientBox extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  
  const AnimatedGradientBox({
    Key? key,
    required this.child,
    this.colors = AppColors.loginGradient,
  }) : super(key: key);

  @override
  State<AnimatedGradientBox> createState() => _AnimatedGradientBoxState();
}

class _AnimatedGradientBoxState extends State<AnimatedGradientBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors,
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
          ),
          child: Stack(
            children: [
              Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: NetworkPatternPainter(),
                  size: Size.infinite,
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class NetworkPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    final dotPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
      
    final spacing = 60.0;
    final radius = 2.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw dot
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
        
        // Connect to right
        if (x + spacing < size.width) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x + spacing, y),
            paint,
          );
        }
        
        // Connect to bottom
        if (y + spacing < size.height) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x, y + spacing),
            paint,
          );
        }
        
        // Connect diagonally
        if (x + spacing < size.width && y + spacing < size.height) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x + spacing, y + spacing),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}