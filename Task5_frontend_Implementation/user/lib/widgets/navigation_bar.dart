import 'package:flutter/material.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Color(0xFF6366F1), // Indigo
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
          ),
          items: [
            _buildNavigationBarItem(
              icon: Icons.home_rounded,
              label: 'Home',
              index: 0,
            ),
            _buildNavigationBarItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              index: 1,
            ),
            _buildNavigationBarItem(
              icon: Icons.feedback_rounded,
              label: 'Feedback',
              index: 2,
            ),
            _buildNavigationBarItem(
              icon: Icons.speed_rounded,
              label: 'Speed Test',
              index: 3,
            ),
            _buildNavigationBarItem(
              icon: Icons.receipt_long_rounded,
              label: 'Logs',
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = currentIndex == index;
    
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Color(0xFF6366F1).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: isSelected ? 26 : 24,
            ),
            if (isSelected)
              Positioned(
                top: -2,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
      activeIcon: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 26,
          color: Colors.white,
        ),
      ),
      label: label,
    );
  }
}

// Alternative version with modern floating design
class ModernNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 25,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, 'Home', 0),
            _buildNavItem(Icons.dashboard_rounded, 'Dashboard', 1),
            _buildNavItem(Icons.feedback_rounded, 'Feedback', 2),
            _buildNavItem(Icons.speed_rounded, 'Speed', 3),
            _buildNavItem(Icons.receipt_long_rounded, 'Logs', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Color(0xFF6366F1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: isSelected ? 24 : 22,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}