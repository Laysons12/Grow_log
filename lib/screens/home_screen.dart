import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../services/hive_service.dart';
import '../models/user_profile.dart';
import '../models/streak.dart';
import '../models/entry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserProfile? userProfile;
  late Streak? currentStreak;
  late List<Entry> recentEntries;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    userProfile = HiveService.getUserProfile();
    currentStreak = HiveService.getStreak();
    recentEntries = HiveService.getAllEntries().take(3).toList();
  }

  void _refresh() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    _loadData();
    return Scaffold(
      appBar: AppBar(
        title: const Text('GrowLog'),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Monthly Summary',
            onPressed: () => context.pushNamed('monthlySummary'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: userProfile == null
              ? Center(
                  child: Text(
                    'Please complete onboarding',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Greeting card
                    _buildGreetingCard(),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Streak card
                    _buildStreakCard(),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Quick check-in button
                    _buildCheckInButton(),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Today's goal section
                    _buildTodayGoalSection(),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Recent entries
                    _buildRecentEntriesSection(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppHelpers.getGreeting()}, ${userProfile?.name}! 👋',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Ready to grow today?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final streak = currentStreak?.currentStreak ?? 0;
    final longestStreak = currentStreak?.longestStreak ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildStreakItem('🔥 Current', '$streak', 'days')),
          Container(width: 1, height: 60, color: AppTheme.borderColor),
          Expanded(child: _buildStreakItem('👑 Longest', '$longestStreak', 'days')),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String label, String value, String unit) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        Text(unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildCheckInButton() {
    final checkedInSubjects = HiveService.getTodayCheckedInSubjects();
    final totalSubjects = userProfile?.skillsOrSubjects.length ?? 0;
    final checkedInCount = checkedInSubjects
        .where((s) => userProfile!.skillsOrSubjects
            .map((sub) => sub.trim().toLowerCase())
            .contains(s))
        .length;
    final allDone = totalSubjects > 0 && checkedInCount >= totalSubjects;

    return GestureDetector(
      onTap: () => context.goNamed('checkIn'),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          border: Border.all(
            color: allDone ? AppTheme.successGreen : AppTheme.borderColor,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone
                        ? 'All subjects done! ✅'
                        : checkedInCount > 0
                            ? 'Continue checking in'
                            : 'Check in for today',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    allDone
                        ? 'Tap to update any entry'
                        : '$checkedInCount/$totalSubjects subjects checked in today',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: AppTheme.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayGoalSection() {
    final todayGoals = HiveService.getActiveGoals()
        .where(
          (g) =>
              g.dueDate.isBefore(DateTime.now().add(const Duration(days: 1))),
        )
        .toList();

    if (todayGoals.isEmpty) {
      return GestureDetector(
        onTap: () => context.goNamed('goals'),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Center(
            child: Text(
              'No goals for today. Add one! 🎯',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today\'s Goals', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacingMd),
        ...todayGoals.take(2).map((goal) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(goal.isCompleted ? '✅' : '⭕')),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.text,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        goal.linkedTo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecentEntriesSection() {
    if (recentEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Center(
          child: Text(
            'No entries yet. Start by checking in! ✍️',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Entries',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            GestureDetector(
              onTap: () => context.goNamed('journal'),
              child: Text(
                'View all →',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.accentBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...recentEntries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppHelpers.getRelativeDate(entry.date),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      entry.subjectOrSkill,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  entry.learned,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
