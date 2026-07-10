import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart';
import '../../services/hive_service.dart';
import '../../services/notification_service.dart';
import '../../models/user_profile.dart';
import '../../models/streak.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final String mode;
  final String name;
  final String username;
  final String roleOrClass;
  final String email;

  const SubjectSelectionScreen({
    Key? key,
    required this.mode,
    required this.name,
    this.username = '',
    required this.roleOrClass,
    required this.email,
  }) : super(key: key);

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  late List<String> availableItems;
  late String selectedMode;
  late String userName;
  late String userUsername;
  late String roleOrClass;
  late String emailAddress;

  Set<String> selectedItems = {};
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSaving = false;
  final _customItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedMode = widget.mode;
    userName = widget.name;
    userUsername = widget.username;
    roleOrClass = widget.roleOrClass;
    emailAddress = widget.email;
    availableItems = List<String>.from(
        selectedMode == 'student' ? studentSubjects : professionalSkills);
  }

  @override
  void dispose() {
    _customItemController.dispose();
    super.dispose();
  }

  String? _validateCustomItem(String value) {
    return AppValidators.validateSkillsOrSubjects([value]);
  }

  void _addCustomItem() {
    final newItem = _customItemController.text.trim();
    if (newItem.isEmpty) return;

    // Validate custom item
    final validationError = _validateCustomItem(newItem);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    if (availableItems.contains(newItem)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item already exists')),
      );
      return;
    }

    setState(() {
      availableItems.add(newItem);
      if (selectedItems.length < 6) {
        selectedItems.add(newItem);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to list, select it below')),
        );
      }
      _customItemController.clear();
    });
  }

  void _toggleItem(String item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else if (selectedItems.length < 6) {
        selectedItems.add(item);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only select up to 6 items')),
        );
      }
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    final skillsError = AppValidators.validateSkillsOrSubjects(selectedItems.toList());
    if (skillsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(skillsError)),
      );
      return;
    }

    final reminderTimeStr =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
    final reminderError = AppValidators.validateReminderTime(reminderTimeStr);
    if (reminderError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reminderError)),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create user profile
      final userProfile = UserProfile(
        name: userName,
        username: userUsername,
        email: emailAddress,
        mode: selectedMode,
        roleOrClass: roleOrClass,
        skillsOrSubjects: selectedItems.toList(),
        reminderTime: reminderTimeStr,
        isFirstTime: false,
      );

      // Save to Hive
      await HiveService.saveUserProfile(userProfile);

      // Schedule daily reminder
      await NotificationService.scheduleDailyReminder(userProfile.reminderTime);

      // Initialize streak
      final initialStreak = Streak(
        currentStreak: 0,
        longestStreak: 0,
        lastEntryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await HiveService.saveStreak(initialStreak);

      if (mounted) {
        // Navigate to home
        context.goNamed('home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = selectedMode == 'student';
    final itemType = isStudent ? 'Subjects' : 'Skills';

    return Scaffold(
      appBar: AppBar(title: const Text('Step 3 of 3'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Pick up to 6 $itemType',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'You can change these later in settings',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Subject/Skill selection (3 items)
              Text(
                'Selected: ${selectedItems.length}/6',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Items grid
              Wrap(
                spacing: AppTheme.spacingMd,
                runSpacing: AppTheme.spacingMd,
                children: availableItems.map((item) {
                  final isSelected = selectedItems.contains(item);
                  return GestureDetector(
                    onTap: () => _toggleItem(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentBlue
                            : AppTheme.cardBg,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentBlue
                              : AppTheme.borderColor,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Add Custom item input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customItemController,
                      inputFormatters: [
                        RoleOrClassFormatter(maxLetters: 20, maxDigits: 3),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Add custom $itemType...',
                        prefixIcon: const Icon(Icons.add),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  ElevatedButton(
                    onPressed: _addCustomItem,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Reminder time section
              Text(
                'Daily Reminder Time',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'When should we remind you to check in?',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Time picker button
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    border: Border.all(color: AppTheme.accentBlue),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppTheme.accentBlue,
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      Icon(Icons.edit, color: AppTheme.accentBlue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Let's Go button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAndContinue,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Let\'s Go! 🚀'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Back button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
