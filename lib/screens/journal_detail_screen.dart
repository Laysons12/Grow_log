import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../services/hive_service.dart';
import '../models/entry.dart';

class JournalDetailScreen extends StatefulWidget {
  final String entryId;

  const JournalDetailScreen({super.key, required this.entryId});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  late Entry? entry;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  void _loadEntry() {
    final allEntries = HiveService.getAllEntries();
    entry = allEntries.firstWhere(
      (e) => e.id == widget.entryId,
      orElse: () => Entry(
        date: DateTime.now(),
        mode: 'student',
        learned: 'Entry not found',
        subjectOrSkill: '',
        hoursOrEnergy: 0,
        moodOrFocus: '',
        win: '',
        improve: '',
      ),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Entry Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final e = entry!;

    return Scaffold(
      appBar: AppBar(title: const Text('Entry Details'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and time header
            _buildHeader(e),
            const SizedBox(height: AppTheme.spacingXl),

            // What I learned/studied
            _buildSection(
              title: e.mode == 'student' ? 'What I Studied' : 'What I Learned',
              content: e.learned,
              icon: '📚',
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // Study metrics row
            if (e.mode == 'student')
              _buildMetricsRow(e)
            else
              _buildProfessionalMetrics(e),
            const SizedBox(height: AppTheme.spacingXl),

            // One win
            _buildSection(title: 'One Win Today 🏆', content: e.win, icon: '⭐'),
            const SizedBox(height: AppTheme.spacingXl),

            // What to improve
            _buildSection(
              title: 'What to Improve 📈',
              content: e.improve,
              icon: '🎯',
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // Doubts (student only)
            if (e.mode == 'student' && e.doubts != null && e.doubts!.isNotEmpty)
              _buildSection(
                title: 'Doubts to Clear 🤔',
                content: e.doubts!,
                icon: '❓',
              ),

            if (e.mode == 'student' && (e.doubts == null || e.doubts!.isEmpty))
              const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Entry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppHelpers.formatDate(entry.date),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                entry.subjectOrSkill,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppTheme.accentBlue),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Text(
              AppHelpers.formatTime(entry.date),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required String icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppTheme.spacingMd),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(Entry entry) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: '⏱️',
            label: 'Study Hours',
            value: AppHelpers.formatHours(entry.hoursOrEnergy),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: _buildMetricCard(
            icon: '🎯',
            label: 'Focus Level',
            value: '${entry.moodOrFocus}/5',
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalMetrics(Entry entry) {
    return Wrap(
      spacing: AppTheme.spacingMd,
      runSpacing: AppTheme.spacingMd,
      children: [
        SizedBox(
          width: (MediaQuery.of(context).size.width - AppTheme.spacingLg * 2 - AppTheme.spacingMd) / 2,
          child: _buildMetricCard(
            icon: '⏱️',
            label: 'Learning Hours',
            value: AppHelpers.formatHours(entry.hoursOrEnergy),
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - AppTheme.spacingLg * 2 - AppTheme.spacingMd) / 2,
          child: _buildMetricCard(
            icon: '⚡',
            label: 'Energy',
            value: AppHelpers.getEnergyEmoji(entry.energyLevel.toInt()),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: _buildMetricCard(
            icon: '😊',
            label: 'Mood',
            value: entry.moodOrFocus,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: AppTheme.spacingSm),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
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
}
