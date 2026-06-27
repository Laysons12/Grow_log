import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../services/hive_service.dart';
import '../models/user_profile.dart';
import '../models/streak.dart';

class WeeklyReviewScreen extends StatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  late UserProfile userProfile;
  late Streak streak;
  late int weeklyEntries;
  late String topSkillOrSubject;
  late double totalHoursOrEntries;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  void _loadWeeklyData() {
    userProfile = HiveService.getUserProfile()!;
    streak =
        HiveService.getStreak() ??
        Streak(
          currentStreak: 0,
          longestStreak: 0,
          lastEntryDate: DateTime.now(),
        );

    final weekEntries = HiveService.getEntriesLastNDays(7);
    weeklyEntries = weekEntries.length;

    // Calculate total hours or entries
    if (userProfile.mode == 'student') {
      totalHoursOrEntries = weekEntries.fold(
        0,
        (sum, e) => sum + e.hoursOrEnergy,
      );
    } else {
      totalHoursOrEntries = weekEntries.length.toDouble();
    }

    // Find top skill/subject
    final skillBreakdown = <String, int>{};
    for (var entry in weekEntries) {
      skillBreakdown[entry.subjectOrSkill] =
          (skillBreakdown[entry.subjectOrSkill] ?? 0) + 1;
    }

    topSkillOrSubject = skillBreakdown.isEmpty
        ? 'N/A'
        : skillBreakdown.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
  }

  @override
  Widget build(BuildContext context) {
    final goalsClosed = HiveService.getCompletedGoals()
        .where(
          (g) =>
              g.completedAt != null &&
              g.completedAt!.isAfter(
                DateTime.now().subtract(const Duration(days: 7)),
              ),
        )
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Review'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: AppTheme.spacingXl),

            // Stats cards
            _buildStatsCards(goalsClosed),
            const SizedBox(height: AppTheme.spacingXl),

            // Motivational message
            _buildMotivationalMessage(),
            const SizedBox(height: AppTheme.spacingXl),

            // Weekly breakdown
            _buildWeeklyBreakdown(),
            const SizedBox(height: AppTheme.spacingXl),

            // Share button
            _buildShareButton(),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Review', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          '${AppHelpers.formatDateShort(weekStart)} — ${AppHelpers.formatDateShort(weekEnd)}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsCards(int goalsClosed) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                emoji: '📝',
                title: 'Check-ins',
                value: '$weeklyEntries',
                subtitle: 'times this week',
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: _buildStatCard(
                emoji: userProfile.mode == 'student' ? '⏱️' : '💪',
                title: userProfile.mode == 'student'
                    ? 'Study Hours'
                    : 'Sessions',
                value: userProfile.mode == 'student'
                    ? totalHoursOrEntries.toStringAsFixed(1)
                    : totalHoursOrEntries.toStringAsFixed(0),
                subtitle: 'logged',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                emoji: '🎯',
                title:
                    'Top ${userProfile.mode == 'student' ? 'Subject' : 'Skill'}',
                value: topSkillOrSubject,
                subtitle: 'most practiced',
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: _buildStatCard(
                emoji: '✅',
                title: 'Goals Done',
                value: '$goalsClosed',
                subtitle: 'this week',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: AppTheme.spacingSm),
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.accentBlue),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalMessage() {
    final message = _getMotivationalMessage();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentBlue,
            AppTheme.successGreen.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💬', style: TextStyle(fontSize: 32)),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage() {
    if (streak.currentStreak >= 30) {
      return '🌟 Amazing! You\'ve been consistent for ${streak.currentStreak} days. Keep it up!';
    } else if (streak.currentStreak >= 7) {
      return '🔥 Great streak of ${streak.currentStreak} days! You\'re building momentum.';
    } else if (weeklyEntries >= 5) {
      return '💪 Fantastic week! 5+ check-ins show real commitment.';
    } else if (weeklyEntries > 0) {
      return '👍 Good start! Keep checking in to build your streak.';
    } else {
      return '🌱 Start your journey today. Even one entry counts!';
    }
  }

  Widget _buildWeeklyBreakdown() {
    final weekEntries = HiveService.getEntriesLastNDays(7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week\'s Entries',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (weekEntries.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Center(
              child: Text(
                'No entries yet this week',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ...weekEntries.take(5).map((entry) {
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
                      color: AppTheme.accentBlue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        AppHelpers.getRelativeDate(entry.date) == 'Today'
                            ? '📅'
                            : '✓',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppHelpers.getRelativeDate(entry.date),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          entry.subjectOrSkill,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    entry.win.isNotEmpty ? '✅' : '•',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.share),
        label: const Text('Share This Week'),
        onPressed: () {
          // TODO: Implement share functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Share feature coming soon!')),
          );
        },
      ),
    );
  }
}
