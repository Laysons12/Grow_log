import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../services/hive_service.dart';
import '../models/user_profile.dart';
import '../models/goal.dart';
import '../utils/validators.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late UserProfile userProfile;
  late List<Goal> activeGoals;
  late List<Goal> completedGoals;

  final _goalController = TextEditingController();
  late ConfettiController _confettiController;
  String selectedSkillOrSubject = '';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _showAddForm = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadData();
  }

  void _loadData() {
    userProfile = HiveService.getUserProfile()!;
    selectedSkillOrSubject = userProfile.skillsOrSubjects.isNotEmpty
        ? userProfile.skillsOrSubjects.first
        : '';
    _refreshGoals();
  }

  void _refreshGoals() {
    setState(() {
      activeGoals = HiveService.getActiveGoals();
      completedGoals = HiveService.getCompletedGoals();
    });
  }

  @override
  void dispose() {
    _goalController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _addGoal() async {
    if (selectedSkillOrSubject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add topics in Settings first.')),
      );
      return;
    }
    final title = _goalController.text.trim();
    final titleError = AppValidators.validateGoalTitle(title);
    if (titleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(titleError)));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final goal = Goal(
        text: title,
        linkedTo: selectedSkillOrSubject,
        dueDate: selectedDate,
        status: 'active',
      );

      await HiveService.addGoal(goal);
      _goalController.clear();
      setState(() => _showAddForm = false);
      _refreshGoals();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Goal added! 🎯')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _markGoalDone(Goal goal) async {
    final updatedGoal = goal.copyWith(
      status: 'done',
      completedAt: DateTime.now(),
    );
    await HiveService.updateGoal(updatedGoal);
    _refreshGoals();
    _confettiController.play();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Goal completed! 🎉')));

      final setNext = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Target Achieved! 🏆'),
          content: const Text('Awesome job! You have successfully completed your goal.\n\nWould you like to set your next goal now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Set New Goal'),
            ),
          ],
        ),
      );

      if (setNext == true && mounted) {
        setState(() {
          _showAddForm = true;
        });
      }
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    await HiveService.deleteGoal(goal.id);
    _refreshGoals();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(now) ? now : selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    userProfile = HiveService.getUserProfile()!;
    activeGoals = HiveService.getActiveGoals();
    completedGoals = HiveService.getCompletedGoals();
    if (!userProfile.skillsOrSubjects.contains(selectedSkillOrSubject)) {
      selectedSkillOrSubject = userProfile.skillsOrSubjects.isNotEmpty
          ? userProfile.skillsOrSubjects.first
          : '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Goals',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${activeGoals.length} active, ${completedGoals.length} completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                FloatingActionButton.small(
                  onPressed: () => setState(() => _showAddForm = !_showAddForm),
                  child: Icon(_showAddForm ? Icons.close : Icons.add),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Add goal form
            if (_showAddForm) ...[
              if (userProfile.skillsOrSubjects.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Center(
                    child: Text(
                      'Please add topics in Settings first.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  border: Border.all(color: AppTheme.accentBlue),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Goal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    TextField(
                      controller: _goalController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Describe your goal...',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Link to:',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMd,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkBg,
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  value: userProfile.skillsOrSubjects.contains(selectedSkillOrSubject)
                                      ? selectedSkillOrSubject
                                      : userProfile.skillsOrSubjects.first,
                                  items: userProfile.skillsOrSubjects.map((
                                    item,
                                  ) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(
                                      () => selectedSkillOrSubject = value!,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Column(
                          children: [
                            Text(
                              'Due Date',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMd,
                                  vertical: AppTheme.spacingSm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                ),
                                child: Text(
                                  AppHelpers.formatDateShort(selectedDate),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _addGoal,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Add Goal'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // Active goals
            if (activeGoals.isNotEmpty) ...[
              Text(
                'Active Goals',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ...activeGoals.map((goal) => _buildGoalCard(goal)).toList(),
              const SizedBox(height: AppTheme.spacingLg),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Center(
                  child: Text(
                    'No active goals. Add one to get started! 🎯',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // Completed goals
            if (completedGoals.isNotEmpty) ...[
              ExpansionTile(
                title: Text(
                  'Completed Goals (${completedGoals.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                children: [
                  const SizedBox(height: AppTheme.spacingMd),
                  ...completedGoals
                      .map((goal) => _buildGoalCard(goal, isCompleted: true))
                      .toList(),
                ],
              ),
            ],
          ],
        ),
      ),
      ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
      ),
    ],
  ),
);
}

  Widget _buildGoalCard(Goal goal, {bool isCompleted = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(
          color: isCompleted ? AppTheme.successGreen : AppTheme.borderColor,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: Text(
                            goal.linkedTo,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.accentBlue),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          AppHelpers.getRelativeDate(goal.dueDate),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: goal.isOverdue && !isCompleted
                                    ? const Color(0xFFFF6B6B)
                                    : AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isCompleted)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.done),
                          SizedBox(width: 8),
                          Text('Mark Done'),
                        ],
                      ),
                      onTap: () => _markGoalDone(goal),
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                      onTap: () => _deleteGoal(goal),
                    ),
                  ],
                )
              else
                Text('✅', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ],
      ),
    );
  }
}
