import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const MainLayout({Key? key, required this.child, required this.state}) : super(key: key);

  int _getSelectedIndex(String path) {
    if (path.startsWith('/journal')) return 1;
    if (path.startsWith('/goals')) return 2;
    if (path.startsWith('/settings')) return 3;
    return 0; // default to Home
  }

  void _onTabChanged(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/journal');
        break;
      case 2:
        context.go('/goals');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getSelectedIndex(state.uri.path);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTabChanged(context, index),
        backgroundColor: AppTheme.cardBg,
        selectedItemColor: AppTheme.accentBlue,
        unselectedItemColor: AppTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
