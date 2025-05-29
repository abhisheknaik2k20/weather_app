import 'package:flutter/material.dart';
import 'package:my_app/screens/HOME_SCREEN/home_screen.dart';
import 'package:my_app/screens/JOURNEY/journey_predict.dart';
import 'package:my_app/screens/PROFILE/profile.dart';

class BlackScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const BlackScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<BlackScreen> createState() => _BlackScreenState();
}

class _BlackScreenState extends State<BlackScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          MyHomePage(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
          const JourneyPredict(),
          ProfileScreen(
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildNavItem(0, Icons.home, 'Home', Colors.blue),
            _buildNavItem(1, Icons.explore, 'Journey', Colors.orange),
            _buildNavItem(2, Icons.person, 'Profile', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color color) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? color
                    : (widget.isDarkMode ? Colors.grey[500] : Colors.grey[600]),
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? color
                      : (widget.isDarkMode
                            ? Colors.grey[500]
                            : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
