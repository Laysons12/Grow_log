import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'utils/router.dart';
import 'utils/theme.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveService.initHive();

  // Initialize Notifications
  await NotificationService.initialize();

  // Load initial theme mode
  themeNotifier.value = HiveService.isDarkMode() ? ThemeMode.dark : ThemeMode.light;
  AppTheme.isDark = themeNotifier.value == ThemeMode.dark;

  // Schedule daily notification if active user exists
  final profile = HiveService.getUserProfile();
  if (profile != null) {
    await NotificationService.scheduleDailyReminder(profile.reminderTime);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        AppTheme.isDark = currentThemeMode == ThemeMode.dark;
        return MaterialApp.router(
          title: 'GrowLog',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: currentThemeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
