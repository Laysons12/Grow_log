import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../services/hive_service.dart';
import '../models/entry.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late DateTime _selectedDate;
  late List<Entry> _selectedDateEntries;
  late List<Entry> _allEntries;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _allEntries = HiveService.getAllEntries();
    _loadEntriesForDate(_selectedDate);
  }

  void _loadEntriesForDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedDateEntries = HiveService.getEntriesByDate(date);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Entry> _getFilteredEntries() {
    if (_searchQuery.isEmpty) {
      return _selectedDateEntries;
    }

    return _selectedDateEntries.where((entry) {
      return entry.learned.toLowerCase().contains(_searchQuery) ||
          entry.subjectOrSkill.toLowerCase().contains(_searchQuery) ||
          entry.win.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Set<DateTime> _getDatesWithEntries() {
    return _allEntries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet();
  }

  Future<void> _deleteEntry(Entry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveService.deleteEntry(entry.id);
      _loadEntriesForDate(_selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _allEntries = HiveService.getAllEntries();
    _selectedDateEntries = HiveService.getEntriesByDate(_selectedDate);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Monthly Summary',
            onPressed: () => context.pushNamed('monthlySummary'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            _buildSearchBar(),
            const SizedBox(height: AppTheme.spacingLg),

            // Calendar
            _buildCalendar(),
            const SizedBox(height: AppTheme.spacingLg),

            // Date header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.formatDate(_selectedDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${_getFilteredEntries().length} ${_getFilteredEntries().length == 1 ? 'entry' : 'entries'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Entries list
            _buildEntriesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search entries...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _onSearchChanged('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildCalendar() {
    final datesWithEntries = _getDatesWithEntries();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2030),
        focusedDay: _selectedDate,
        selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
        onDaySelected: (selectedDay, focusedDay) {
          _loadEntriesForDate(selectedDay);
        },
        calendarStyle: CalendarStyle(
          defaultTextStyle: Theme.of(context).textTheme.bodySmall!,
          weekendTextStyle: Theme.of(context).textTheme.bodySmall!,
          selectedDecoration: BoxDecoration(
            color: AppTheme.accentBlue,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.borderColor,
            shape: BoxShape.circle,
          ),
          todayTextStyle: Theme.of(context).textTheme.bodySmall!,
          markersMaxCount: 1,
          markerDecoration: BoxDecoration(
            color: AppTheme.successGreen,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: Theme.of(context).textTheme.titleMedium!,
          leftChevronIcon: const Icon(Icons.chevron_left),
          rightChevronIcon: const Icon(Icons.chevron_right),
        ),
        eventLoader: (day) {
          return datesWithEntries.contains(
                DateTime(day.year, day.month, day.day),
              )
              ? ['entry']
              : [];
        },
      ),
    );
  }

  Widget _buildEntriesList() {
    final filteredEntries = _getFilteredEntries();

    if (filteredEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Center(
          child: Text(
            _searchQuery.isNotEmpty
                ? 'No entries match your search'
                : 'No entries for this date',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: filteredEntries.map((entry) => _buildEntryCard(entry)).toList(),
    );
  }

  Widget _buildEntryCard(Entry entry) {
    return GestureDetector(
      onTap: () {
        // Navigate to detail view
        context.goNamed('journalDetail', pathParameters: {'entryId': entry.id});
      },
      child: Container(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.formatTime(entry.date),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        entry.subjectOrSkill,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                      onTap: () {
                        if (entry.isToday()) {
                          context.go('/check-in?subject=${Uri.encodeComponent(entry.subjectOrSkill)}');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Past day entries cannot be edited'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                      onTap: () => _deleteEntry(entry),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              entry.learned,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (entry.mode == 'student')
                      Text(
                        '⏱️ ${AppHelpers.formatHours(entry.hoursOrEnergy)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      )
                    else
                      Text(
                        '⏱️ ${AppHelpers.formatHours(entry.hoursOrEnergy)}  ⚡ ${AppHelpers.getEnergyEmoji(entry.energyLevel.toInt())}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
                Text(
                  '${entry.win.length} words',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
