import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../services/hive_service.dart';
import '../models/entry.dart';
import '../models/user_profile.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  late DateTime _selectedMonth;
  late UserProfile _userProfile;
  bool _showSummary = true; // true = Summary, false = Weekly Lists

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _userProfile = HiveService.getUserProfile() ??
        UserProfile(
          name: 'User',
          email: '',
          mode: 'student',
          roleOrClass: '',
          skillsOrSubjects: [],
          reminderTime: '09:00',
          isFirstTime: true,
          createdAt: DateTime.now(),
        );
  }

  // Get all entries for the selected month
  List<Entry> _getEntriesForMonth(DateTime monthDate) {
    final allEntries = HiveService.getAllEntries();
    return allEntries.where((e) {
      return e.date.year == monthDate.year && e.date.month == monthDate.month;
    }).toList();
  }

  // Group entries by weeks of the month:
  // Week 1: 1-7, Week 2: 8-14, Week 3: 15-21, Week 4: 22-end
  Map<String, List<Entry>> _getEntriesGroupedByWeek(List<Entry> monthEntries) {
    final Map<String, List<Entry>> grouped = {
      'Week 1 (1st - 7th)': [],
      'Week 2 (8th - 14th)': [],
      'Week 3 (15th - 21st)': [],
      'Week 4 (22nd onwards)': [],
    };

    for (var entry in monthEntries) {
      final day = entry.date.day;
      if (day <= 7) {
        grouped['Week 1 (1st - 7th)']!.add(entry);
      } else if (day <= 14) {
        grouped['Week 2 (8th - 14th)']!.add(entry);
      } else if (day <= 21) {
        grouped['Week 3 (15th - 21st)']!.add(entry);
      } else {
        grouped['Week 4 (22nd onwards)']!.add(entry);
      }
    }
    return grouped;
  }

  // Find the most active week
  String _getMostActiveWeek(Map<String, List<Entry>> weeklyGroup) {
    String mostActive = 'N/A';
    int maxCount = 0;
    weeklyGroup.forEach((week, entries) {
      if (entries.length > maxCount) {
        maxCount = entries.length;
        mostActive = week.split(' ')[0] + ' ' + week.split(' ')[1]; // E.g. "Week 1"
      }
    });
    if (maxCount == 0) return 'No entries';
    return '$mostActive ($maxCount days)';
  }

  void _selectPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _selectNextMonth() {
    // Prevent selecting future months
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      return;
    }
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthEntries = _getEntriesForMonth(_selectedMonth);
    final weeklyGroup = _getEntriesGroupedByWeek(monthEntries);
    final totalDaysLogged = monthEntries.map((e) => e.date.day).toSet().length;
    final mostActiveWeek = _getMostActiveWeek(weeklyGroup);

    // Filter wins (highlights)
    final highlights = monthEntries
        .map((e) => e.win.trim())
        .where((w) => w.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Month Selector Header
          _buildMonthSelector(),

          // Segmented/Toggle Buttons (Summary vs Weekly Lists)
          _buildToggleButtons(),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: _showSummary
                  ? _buildSummaryContent(monthEntries, totalDaysLogged, mostActiveWeek, highlights)
                  : _buildWeeklyListsContent(weeklyGroup),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth);
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Container(
      color: AppTheme.cardBg,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd, horizontal: AppTheme.spacingLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: AppTheme.textPrimary),
            onPressed: _selectPreviousMonth,
          ),
          Text(
            monthName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentBlue,
                ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentMonth ? AppTheme.borderColor : AppTheme.textPrimary,
            ),
            onPressed: isCurrentMonth ? null : _selectNextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      color: AppTheme.cardBg,
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd, left: AppTheme.spacingLg, right: AppTheme.spacingLg),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showSummary = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: _showSummary ? AppTheme.accentBlue : AppTheme.borderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMd),
                    bottomLeft: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Summary',
                  style: TextStyle(
                    color: _showSummary ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showSummary = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: !_showSummary ? AppTheme.accentBlue : AppTheme.borderColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppTheme.radiusMd),
                    bottomRight: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Weekly Lists',
                  style: TextStyle(
                    color: !_showSummary ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(
    List<Entry> monthEntries,
    int totalDaysLogged,
    String mostActiveWeek,
    List<String> highlights,
  ) {
    if (monthEntries.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😢', style: TextStyle(fontSize: 48)),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'No entries found for this month.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate total hours/energy
    double totalHours = 0;
    for (var entry in monthEntries) {
      totalHours += entry.hoursOrEnergy;
    }

    final averageHours = monthEntries.isEmpty ? 0.0 : totalHours / monthEntries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat Cards Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Days Logged',
                value: '$totalDaysLogged',
                subtitle: 'this month',
                icon: Icons.calendar_today,
                color: AppTheme.accentBlue,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: _buildStatCard(
                title: 'Most Active',
                value: mostActiveWeek,
                subtitle: 'by entry count',
                icon: Icons.flash_on,
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingLg),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: _userProfile.mode == 'student' ? 'Avg Study Hours' : 'Avg Energy Level',
                value: averageHours.toStringAsFixed(1),
                subtitle: _userProfile.mode == 'student' ? 'hours per day' : 'out of 5',
                icon: _userProfile.mode == 'student' ? Icons.menu_book : Icons.bolt,
                color: AppTheme.successGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXl),

        // Highlights Section
        Text(
          'Key Highlights & Wins 🏆',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (highlights.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Center(
              child: Text('No wins logged this month.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: highlights.length > 5 ? 5 : highlights.length, // Show up to 5 highlights
            itemBuilder: (context, index) {
              return Card(
                color: AppTheme.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  side: BorderSide(color: AppTheme.borderColor),
                ),
                margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successGreen, size: 20),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Text(
                          highlights[index],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildWeeklyListsContent(Map<String, List<Entry>> weeklyGroup) {
    final keys = weeklyGroup.keys.toList();
    final hasAnyEntries = weeklyGroup.values.any((list) => list.isNotEmpty);

    if (!hasAnyEntries) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'No entries grouped by week.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keys.map((weekTitle) {
        final entries = weeklyGroup[weekTitle]!;
        if (entries.isEmpty) return const SizedBox.shrink();

        // Sort entries by date desc
        entries.sort((a, b) => b.date.compareTo(a.date));

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: AppTheme.spacingXs, bottom: AppTheme.spacingSm),
                child: Text(
                  weekTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ...entries.map((entry) {
                return Card(
                  color: AppTheme.cardBg,
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    side: BorderSide(color: AppTheme.borderColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d').format(entry.date),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          entry.subjectOrSkill,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.accentBlue,
                              ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.learned,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (entry.win.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingXs),
                            Text(
                              '🏆 Win: ${entry.win}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.successGreen,
                                    fontStyle: FontStyle.italic,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                    onTap: () => context.pushNamed(
                      'journalDetail',
                      pathParameters: {'entryId': entry.id},
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
