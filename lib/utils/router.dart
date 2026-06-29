import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/hive_service.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/mode_selection.dart';
import '../screens/onboarding/basic_details.dart';
import '../screens/onboarding/subject_selection.dart';
import '../screens/onboarding/onboarding_slideshow.dart';
import '../screens/home_screen.dart';
import '../screens/checkin_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/journal_detail_screen.dart';
import '../screens/weekly_review_screen.dart';
import '../screens/monthly_summary_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/main_layout.dart';

// Define route paths
class AppRoutes {
  static const String splash = '/';
  static const String modeSelection = '/mode-selection';
  static const String basicDetails = '/basic-details';
  static const String subjectSelection = '/subject-selection';
  static const String home = '/home';
  static const String checkIn = '/check-in';
  static const String goals = '/goals';
  static const String progress = '/progress';
  static const String journal = '/journal';
  static const String journalDetail = '/journal/:entryId';
  static const String weeklyReview = '/weekly-review';
  static const String monthlySummary = '/monthly-summary';
  static const String settings = '/settings';
  static const String onboardingSlideshow = '/onboarding-slideshow';
}

// Create router
final GoRouter appRouter = GoRouter(
  redirect: (context, state) {
    // Handle initial route based on user status
    if (state.uri.path == '/') {
      final hasUser = HiveService.hasUser();
      if (hasUser) {
        return AppRoutes.home;
      } else {
        return AppRoutes.splash;
      }
    }
    return null;
  },
  routes: [
    // Splash Screen
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Onboarding Slideshow
    GoRoute(
      path: AppRoutes.onboardingSlideshow,
      name: 'onboardingSlideshow',
      builder: (context, state) => const OnboardingSlideshowScreen(),
    ),

    // Onboarding Routes
    GoRoute(
      path: AppRoutes.modeSelection,
      name: 'modeSelection',
      builder: (context, state) => const ModeSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.basicDetails,
      name: 'basicDetails',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'student';
        return BasicDetailsScreen(mode: mode);
      },
    ),
    GoRoute(
      path: AppRoutes.subjectSelection,
      name: 'subjectSelection',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'student';
        final name = state.uri.queryParameters['name'] ?? '';
        final username = state.uri.queryParameters['username'] ?? '';
        final role = state.uri.queryParameters['role'] ?? '';
        final email = state.uri.queryParameters['email'] ?? '';
        return SubjectSelectionScreen(
          mode: mode,
          name: name,
          username: username,
          roleOrClass: role,
          email: email,
        );
      },
    ),

    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(state: state, child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TabPopScope(isHome: true, child: HomeScreen())),
          routes: [
            GoRoute(
              path: 'weekly-review',
              name: 'weeklyReview',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: WeeklyReviewScreen()),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.checkIn,
          name: 'checkIn',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TabPopScope(child: CheckInScreen())),
        ),
        GoRoute(
          path: AppRoutes.goals,
          name: 'goals',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TabPopScope(child: GoalsScreen())),
        ),
        GoRoute(
          path: AppRoutes.progress,
          name: 'progress',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TabPopScope(child: ProgressScreen())),
        ),
        GoRoute(
          path: AppRoutes.journal,
          name: 'journal',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TabPopScope(child: JournalScreen())),
        ),
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TabPopScope(child: SettingsScreen())),
        ),
      ],
    ),

    // Journal Detail (Moved to root level for fullscreen viewing and to fix navigation errors)
    GoRoute(
      path: '/journal/:entryId',
      name: 'journalDetail',
      builder: (context, state) {
        final entryId = state.pathParameters['entryId']!;
        return JournalDetailScreen(entryId: entryId);
      },
    ),

    // Monthly Summary
    GoRoute(
      path: AppRoutes.monthlySummary,
      name: 'monthlySummary',
      builder: (context, state) => const MonthlySummaryScreen(),
    ),
  ],

  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
);

class TabPopScope extends StatelessWidget {
  final Widget child;
  final bool isHome;

  const TabPopScope({Key? key, required this.child, this.isHome = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (!isHome) {
          context.go('/home');
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Are you sure you want to exit GrowLog?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: child,
    );
  }
}
