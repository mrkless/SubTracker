import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../insights/presentation/insights_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    InsightsScreen(),
    CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Ultra-Premium Floating Navbar
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildFloatingNavbar(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavbar(bool isDarkMode) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: isDarkMode 
          ? const Color(0xE61E293B) 
          : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: isDarkMode 
            ? Colors.white.withOpacity(0.12) 
            : AppTheme.borderLight.withOpacity(0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.45 : 0.08),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  index: 0,
                  currentIndex: _currentIndex,
                  icon: Icons.grid_view_rounded,
                  label: 'Home',
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                _NavItem(
                  index: 1,
                  currentIndex: _currentIndex,
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                
                // Centered "Punch-through" FAB
                _buildPremiumFab(),

                _NavItem(
                  index: 2,
                  currentIndex: _currentIndex,
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Insights',
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                _NavItem(
                  index: 3,
                  currentIndex: _currentIndex,
                  icon: Icons.calendar_today_rounded,
                  label: 'Schedule',
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFab() {
    return GestureDetector(
      onTap: () => context.push('/add_subscription'),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryAccent, Color(0xFF6A1DD4)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryAccent.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final void Function(int) onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutQuart,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryAccent.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppTheme.secondaryAccent
                    : AppTheme.textMutedDark,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.secondaryAccent : AppTheme.textMutedDark,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
