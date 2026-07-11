import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../services/hive_service.dart';
import '../models/user_profile.dart';
import '../models/streak.dart';
import '../models/entry.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late UserProfile userProfile;
  late Streak streak;
  late int totalEntries;
  late List<String> earnedBadges;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    userProfile = HiveService.getUserProfile()!;
    streak =
        HiveService.getStreak() ??
        Streak(
          currentStreak: 0,
          longestStreak: 0,
          lastEntryDate: DateTime.now(),
        );
    totalEntries = HiveService.getAllEntries().length;
    earnedBadges = HiveService.getBadges();

    // Check and award badges
    _checkAndAwardBadges();
  }

  void _checkAndAwardBadges() {
    if (streak.currentStreak >= 7 && !earnedBadges.contains('7_day_streak')) {
      HiveService.addBadge('7_day_streak');
    }
    if (streak.currentStreak >= 30 && !earnedBadges.contains('30_day_streak')) {
      HiveService.addBadge('30_day_streak');
    }
    if (streak.longestStreak >= 365 &&
        !earnedBadges.contains('365_day_streak')) {
      HiveService.addBadge('365_day_streak');
    }
    if (totalEntries >= 100 && !earnedBadges.contains('100_entries')) {
      HiveService.addBadge('100_entries');
    }
    setState(() {
      earnedBadges = HiveService.getBadges();
    });
  }

  @override
  Widget build(BuildContext context) {
    _loadData();
    final entries = HiveService.getEntriesLastNDays(7);
    final skillBreakdown = _getSkillBreakdown(entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak stats
            _buildStreakSection(),
            const SizedBox(height: AppTheme.spacingXl),

            // Bar chart
            _buildChartSection(entries),
            const SizedBox(height: AppTheme.spacingXl),

            // Skill/Subject breakdown
            _buildSkillBreakdown(skillBreakdown),
            const SizedBox(height: AppTheme.spacingXl),

            // Stats row
            _buildStatsRow(),
            const SizedBox(height: AppTheme.spacingXl),

            // Badges section
            _buildBadgesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Streak', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppTheme.spacingLg),
        Row(
          children: [
            Expanded(
              child: _buildStreakCard(
                emoji: '🔥',
                title: 'Current Streak',
                value: '${streak.currentStreak}',
                unit: 'days',
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: _buildStreakCard(
                emoji: '👑',
                title: 'Personal Best',
                value: '${streak.longestStreak}',
                unit: 'days',
                color: AppTheme.warningYellow,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakCard({
    required String emoji,
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: AppTheme.spacingSm),
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppTheme.spacingSm),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: color),
                ),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<dynamic> entries) {
    // Prepare data for the last 7 days
    final now = DateTime.now();
    final chartValues = <double>[];
    final chartLabels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayEntries = HiveService.getEntriesByDate(date);

      double value = 0;
      for (var entry in dayEntries) {
        if (userProfile.mode == 'student') {
          value += entry.hoursOrEnergy;
        } else {
          value += 1; // Count entries for professionals
        }
      }

      chartValues.add(value);
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      chartLabels.add(weekdays[date.weekday - 1]);
    }
    final double maxVal = chartValues.isEmpty ? 0 : chartValues.reduce((a, b) => a > b ? a : b);
    final double calculatedMaxY = maxVal < 5 ? 5 : maxVal + 1;
    final double yInterval = calculatedMaxY > 10 ? (calculatedMaxY / 5).roundToDouble() : 1.0;

    final hasData = chartValues.any((v) => v > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userProfile.mode == 'student'
              ? 'Study Hours (7 Days)'
              : 'Practice Entries (7 Days)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: SizedBox(
            height: 200,
            child: hasData
                ? BarChart(
                    BarChartData(
                      maxY: calculatedMaxY,
                      barGroups: chartValues
                          .asMap()
                          .entries
                          .map(
                            (e) => BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value,
                                  color: AppTheme.accentBlue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= chartLabels.length) {
                                return const SizedBox();
                              }
                              return Text(
                                chartLabels[index],
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: yInterval,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📊', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'No entries yet this week.\nStart logging to see your progress!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillBreakdown(Map<String, int> breakdown) {
    if (breakdown.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${userProfile.mode == 'student' ? 'Subject' : 'Skill'} Breakdown (This Week)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        ...breakdown.entries.map((entry) {
          final percentage =
              (entry.value / breakdown.values.reduce((a, b) => a + b));
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${entry.value} entries',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 8,
                    backgroundColor: AppTheme.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showEntriesDialog(String title, List<Entry> entries) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.accentBlue,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('No entries found.'))
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final formattedDate =
                              '${entry.date.day}/${entry.date.month}/${entry.date.year}';
                          return Card(
                            color: AppTheme.darkBg,
                            margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.subjectOrSkill,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingSm),
                                  Text(
                                    'Hours: ${entry.hoursOrEnergy.toStringAsFixed(1)} hrs',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingSm),
                                  Text(
                                    entry.learned,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              final entries = HiveService.getAllEntries();
              _showEntriesDialog('Total Entries Log', entries);
            },
            child: _buildStatCard('📝', 'Total Entries', '$totalEntries'),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: GestureDetector(
            onTap: () {
              final entries = HiveService.getEntriesLastNDays(7);
              _showEntriesDialog("This Week's Entries Log", entries);
            },
            child: _buildStatCard(
              '📅',
              'This Week',
              '${HiveService.getEntriesLastNDays(7).length}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.accentBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Badges', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppTheme.spacingMd),
        if (earnedBadges.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Center(
              child: Text(
                'Keep going! Earn badges by reaching milestones 🏆',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          Wrap(
            spacing: AppTheme.spacingMd,
            runSpacing: AppTheme.spacingMd,
            children: earnedBadges.map((badge) {
              final badgeName = badgeDefinitions[badge] ?? badge;
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.warningYellow.withValues(alpha: 0.1),
                  border: Border.all(color: AppTheme.warningYellow),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      badgeName,
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Map<String, int> _getSkillBreakdown(List<dynamic> entries) {
    final breakdown = <String, int>{};
    for (var entry in entries) {
      breakdown[entry.subjectOrSkill] =
          (breakdown[entry.subjectOrSkill] ?? 0) + 1;
    }
    return breakdown;
  }
}
