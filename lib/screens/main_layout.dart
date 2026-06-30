import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const MainLayout({Key? key, required this.child, required this.state}) : super(key: key);

  int _getSelectedIndex(String path) {
    if (path.startsWith('/check-in')) return 1;
    if (path.startsWith('/goals')) return 2;
    if (path.startsWith('/progress')) return 3;
    if (path.startsWith('/journal')) return 4;
    return 0; // default to Home
  }

  void _onTabChanged(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/check-in');
        break;
      case 2:
        context.go('/goals');
        break;
      case 3:
        context.go('/progress');
        break;
      case 4:
        context.go('/journal');
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Check-in'),
          BottomNavigationBarItem(icon: Icon(Icons.gps_fixed), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Journal'),
        ],
      ),
    );
  }
}
