import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../services/hive_service.dart';
import '../models/user_profile.dart';
import '../models/entry.dart';
import 'package:flutter/services.dart';
import '../utils/formatters.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late UserProfile userProfile;
  late bool isStudent;

  final _learnedController = TextEditingController();
  final _winController = TextEditingController();
  final _improveController = TextEditingController();
  final _doubtsController = TextEditingController();
  final _customTopicController = TextEditingController();
  final _hoursController = TextEditingController();

  String selectedSubjectOrSkill = '';
  bool isCustomTopic = false;
  int selectedEnergyOrFocus = 3;
  double selectedHours = 1.0;
  String selectedMood = 'motivated';
  bool _isSaving = false;

  // Edit mode state
  bool _isEditMode = false;
  String? _editingEntryId;
  Set<String> _checkedInSubjects = {};
  bool _initializedFromRoute = false;

  @override
  void initState() {
    super.initState();
    userProfile = HiveService.getUserProfile()!;
    isStudent = userProfile.mode == 'student';
    _checkedInSubjects = HiveService.getTodayCheckedInSubjects();
    selectedSubjectOrSkill = userProfile.skillsOrSubjects.isNotEmpty
        ? userProfile.skillsOrSubjects.first
        : '+ Add custom topic...';
    isCustomTopic = selectedSubjectOrSkill == '+ Add custom topic...';
    selectedMood = isStudent ? 'focused' : 'motivated';
    _hoursController.text = selectedHours.toString();

    // Check if the initially selected subject already has an entry today
    _checkForExistingEntry();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromRoute) {
      _initializedFromRoute = true;
      final uri = GoRouterState.of(context).uri;
      final subjectParam = uri.queryParameters['subject'];
      if (subjectParam != null && subjectParam.isNotEmpty) {
        final match = userProfile.skillsOrSubjects.firstWhere(
          (s) => s.trim().toLowerCase() == subjectParam.trim().toLowerCase(),
          orElse: () => '',
        );
        if (match.isNotEmpty) {
          selectedSubjectOrSkill = match;
          isCustomTopic = false;
        } else {
          selectedSubjectOrSkill = '+ Add custom topic...';
          isCustomTopic = true;
          _customTopicController.text = subjectParam;
        }
        _checkForExistingEntry();
      }
    }
  }

  @override
  void dispose() {
    _learnedController.dispose();
    _winController.dispose();
    _improveController.dispose();
    _doubtsController.dispose();
    _customTopicController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  /// Checks if the currently selected subject has an entry today.
  /// If yes, enters edit mode and populates the form.
  void _checkForExistingEntry() {
    if (isCustomTopic || selectedSubjectOrSkill.isEmpty) {
      _clearEditMode();
      return;
    }

    final existingEntry = HiveService.getTodayEntryForSubject(selectedSubjectOrSkill);
    if (existingEntry != null) {
      _enterEditMode(existingEntry);
    } else {
      _clearEditMode();
    }
  }

  void _enterEditMode(Entry entry) {
    setState(() {
      _isEditMode = true;
      _editingEntryId = entry.id;
      _learnedController.text = entry.learned;
      _winController.text = entry.win;
      _improveController.text = entry.improve;
      _doubtsController.text = entry.doubts ?? '';
      selectedHours = entry.hoursOrEnergy;
      _hoursController.text = selectedHours.toStringAsFixed(1);
      if (isStudent) {
        final focusVal = int.tryParse(entry.moodOrFocus);
        selectedEnergyOrFocus = (focusVal != null && focusVal >= 1 && focusVal <= 5) ? focusVal : 3;
      } else {
        selectedMood = entry.moodOrFocus;
        selectedEnergyOrFocus = entry.energyLevel.toInt().clamp(1, 5);
      }
    });
  }

  void _clearEditMode() {
    setState(() {
      _isEditMode = false;
      _editingEntryId = null;
      _learnedController.clear();
      _winController.clear();
      _improveController.clear();
      _doubtsController.clear();
      selectedHours = 1.0;
      _hoursController.text = '1.0';
      selectedEnergyOrFocus = 3;
      selectedMood = isStudent ? 'focused' : 'motivated';
    });
  }

  Future<void> _saveEntry() async {
    final topic = isCustomTopic
        ? (_customTopicController.text.trim().isNotEmpty
            ? _customTopicController.text.trim()
            : 'Custom')
        : selectedSubjectOrSkill;

    final learnedText = _learnedController.text.trim();
    final winText = _winController.text.trim();
    final improveText = _improveController.text.trim();
    final doubtsText = isStudent ? _doubtsController.text.trim() : null;

    if (learnedText.isEmpty) {
      _showToast('Please describe what you learned');
      return;
    }
    if (winText.isEmpty) {
      _showToast('Please specify a win');
      return;
    }
    if (improveText.isEmpty) {
      _showToast('Please specify an improvement target');
      return;
    }

    // Validate inputs
    final learnedErr = AppValidators.validateNotes(learnedText, fieldName: 'Learned');
    if (learnedErr != null) {
      _showToast(learnedErr);
      return;
    }
    final winErr = AppValidators.validateWin(winText);
    if (winErr != null) {
      _showToast(winErr);
      return;
    }
    final improveErr = AppValidators.validateImprove(improveText);
    if (improveErr != null) {
      _showToast(improveErr);
      return;
    }
    if (doubtsText != null && doubtsText.isNotEmpty) {
      final doubtsErr = AppValidators.validateDoubts(doubtsText);
      if (doubtsErr != null) {
        _showToast(doubtsErr);
        return;
      }
    }

    final hoursErr = AppValidators.validateDurationHours(selectedHours);
    if (hoursErr != null) {
      _showToast(hoursErr);
      return;
    }

    if (!isStudent) {
      final moodErr = AppValidators.validateMood(selectedMood);
      if (moodErr != null) {
        _showToast(moodErr);
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      // Auto-add new custom topics to profile
      if (isCustomTopic && _customTopicController.text.trim().isNotEmpty) {
        final currentSubjects = List<String>.from(userProfile.skillsOrSubjects);
        if (!currentSubjects.contains(topic)) {
          if (currentSubjects.length >= 6) {
            _showToast('Cannot add more than 6 active topics. Please complete or remove an existing topic in settings first.');
            setState(() => _isSaving = false);
            return;
          }
          currentSubjects.add(topic);
          final updatedProfile = userProfile.copyWith(skillsOrSubjects: currentSubjects);
          await HiveService.saveUserProfile(updatedProfile);
        }
      }

      // For new entries on a subject that already has a today entry (including custom topic matching existing check-ins)
      if (!_isEditMode) {
        final existingEntry = HiveService.getTodayEntryForSubject(topic);
        if (existingEntry != null) {
          _showToast('You already checked in for "$topic" today. Updating instead.');
          _isEditMode = true;
          _editingEntryId = existingEntry.id;
        }
      }

      final entry = Entry(
        id: _isEditMode ? _editingEntryId : null,
        date: DateTime.now(),
        mode: userProfile.mode,
        learned: learnedText,
        subjectOrSkill: topic,
        hoursOrEnergy: selectedHours,
        moodOrFocus: isStudent
            ? selectedEnergyOrFocus.toString()
            : selectedMood,
        win: winText,
        improve: improveText,
        doubts: isStudent ? doubtsText : null,
        energyLevel: isStudent ? null : selectedEnergyOrFocus.toDouble(),
      );

      if (_isEditMode) {
        await HiveService.updateEntry(entry);
        _showToast('Entry updated successfully! ✏️');
      } else {
        await HiveService.addEntry(entry);
        _showToast('Entry saved successfully! 🎉');
      }

      // Update streak
      final allEntries = HiveService.getAllEntries();
      final entryDates = allEntries.map((e) => e.date).toList();
      final currentStreak = AppHelpers.calculateCurrentStreak(entryDates);
      final existingStreak = HiveService.getStreak();

      if (existingStreak != null) {
        final newLongest = currentStreak > existingStreak.longestStreak
            ? currentStreak
            : existingStreak.longestStreak;
        await HiveService.saveStreak(
          existingStreak.copyWith(
            currentStreak: currentStreak,
            longestStreak: newLongest,
            lastEntryDate: DateTime.now(),
          ),
        );
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.goNamed('home');
      });
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _activeEmail;

  @override
  Widget build(BuildContext context) {
    final currentProfile = HiveService.getUserProfile()!;
    if (_activeEmail != currentProfile.email) {
      _activeEmail = currentProfile.email;
      userProfile = currentProfile;
      isStudent = userProfile.mode == 'student';
      _checkedInSubjects = HiveService.getTodayCheckedInSubjects();
      selectedSubjectOrSkill = userProfile.skillsOrSubjects.isNotEmpty
          ? userProfile.skillsOrSubjects.first
          : '+ Add custom topic...';
      isCustomTopic = selectedSubjectOrSkill == '+ Add custom topic...';
      selectedMood = isStudent ? 'focused' : 'motivated';
      _hoursController.text = selectedHours.toString();
      // Reset text inputs
      _learnedController.clear();
      _winController.clear();
      _improveController.clear();
      _doubtsController.clear();
      _customTopicController.clear();
      _checkForExistingEntry();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isStudent ? 'Study Check-in' : 'Daily Check-in'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              _isEditMode ? 'Update your entry' : 'How was your day?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _isEditMode
                  ? 'Editing today\'s entry for $selectedSubjectOrSkill'
                  : 'Share your progress and insights',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // What did I learn/study
            _buildTextField(
              label: isStudent
                  ? 'What did I study today?'
                  : 'What did I learn today?',
              hint: isStudent
                  ? 'Describe your study session...'
                  : 'Share what you learned...',
              controller: _learnedController,
              maxLines: 3,
              inputFormatters: [
                MaxDigitsFormatter(20, onLimitExceeded: () => _showToast('Only 20 numbers can be entered'))
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Subject/Skill dropdown
            _buildDropdown(),
            const SizedBox(height: AppTheme.spacingLg),

            // Hours input (Study/Learning)
            _buildHoursInput(),
            const SizedBox(height: AppTheme.spacingLg),

            // Focus / Energy section
            if (isStudent) _buildFocusInput() else _buildEnergyInput(),
            const SizedBox(height: AppTheme.spacingLg),

            // Mood selector (professional only)
            if (!isStudent) ...[
              _buildMoodSelector(),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // One win of the day
            _buildTextField(
              label: 'One win of the day 🏆',
              hint: 'What went well today?',
              controller: _winController,
              maxLines: 2,
              inputFormatters: [
                MaxDigitsFormatter(20, onLimitExceeded: () => _showToast('Only 20 numbers can be entered'))
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // What to improve
            _buildTextField(
              label: 'What to improve tomorrow',
              hint: 'Any areas for improvement?',
              controller: _improveController,
              maxLines: 2,
              inputFormatters: [
                MaxDigitsFormatter(20, onLimitExceeded: () => _showToast('Only 20 numbers can be entered'))
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Doubts (student only)
            if (isStudent)
              _buildTextField(
                label: 'Doubts to clear tomorrow',
                hint: 'Any concepts or doubts?',
                controller: _doubtsController,
                maxLines: 2,
                inputFormatters: [
                  MaxDigitsFormatter(20, onLimitExceeded: () => _showToast('Only 20 numbers can be entered'))
                ],
              ),
            if (isStudent) const SizedBox(height: AppTheme.spacingLg),

            // Edit mode indicator
            if (_isEditMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.warningYellow.withOpacity(0.1),
                  border: Border.all(color: AppTheme.warningYellow),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    const Text('✏️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'You already checked in for "$selectedSubjectOrSkill" today. Your changes will update the existing entry.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningYellow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Save / Update button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEntry,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditMode ? 'Update Entry' : 'Save Entry'),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTheme.spacingSm),
        TextField(
          controller: controller,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    final list = List<String>.from(userProfile.skillsOrSubjects);
    if (list.length < 6 && !list.contains('+ Add custom topic...')) {
      list.add('+ Add custom topic...');
    }

    if (!list.contains(selectedSubjectOrSkill)) {
      selectedSubjectOrSkill = list.first;
      isCustomTopic = selectedSubjectOrSkill == '+ Add custom topic...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isStudent ? 'Which subject?' : 'Which skill?',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            value: selectedSubjectOrSkill,
            items: list.map((item) {
              final isCheckedIn = _checkedInSubjects.contains(item.trim().toLowerCase()) &&
                  item != '+ Add custom topic...';
              return DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    Expanded(child: Text(item)),
                    if (isCheckedIn)
                      const Text(' ✅', style: TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSubjectOrSkill = value!;
                isCustomTopic = value == '+ Add custom topic...';
              });
              _checkForExistingEntry();
            },
          ),
        ),
        if (isCustomTopic) ...[
          const SizedBox(height: AppTheme.spacingMd),
          TextField(
            controller: _customTopicController,
            inputFormatters: [
              RoleOrClassFormatter(maxLetters: 20, maxDigits: 3),
            ],
            decoration: InputDecoration(
              hintText: isStudent ? 'Enter custom subject name' : 'Enter custom skill name',
              prefixIcon: const Icon(Icons.edit),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHoursInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isStudent ? 'Study hours today' : 'Learning hours today',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: selectedHours,
                min: 0,
                max: 16,
                divisions: 32,
                onChanged: (value) {
                  setState(() {
                    selectedHours = value;
                    _hoursController.text = value.toStringAsFixed(1);
                  });
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            SizedBox(
              width: 95,
              child: TextField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: AppTheme.spacingSm),
                  suffixText: 'hrs',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    if (parsed > 16.0) {
                      _hoursController.text = '16.0';
                      _hoursController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _hoursController.text.length),
                      );
                      setState(() {
                        selectedHours = 16.0;
                      });
                    } else {
                      setState(() {
                        selectedHours = parsed.clamp(0.0, 16.0);
                      });
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnergyInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Energy level today',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = selectedEnergyOrFocus == level;
            return GestureDetector(
              onTap: () => setState(() => selectedEnergyOrFocus = level),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentBlue : AppTheme.cardBg,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentBlue
                        : AppTheme.borderColor,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  AppHelpers.getEnergyEmoji(level),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFocusInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Focus level today',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = selectedEnergyOrFocus == level;
            return GestureDetector(
              onTap: () => setState(() => selectedEnergyOrFocus = level),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.successGreen : AppTheme.cardBg,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.successGreen
                        : AppTheme.borderColor,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  AppHelpers.getFocusEmoji(level),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mood today', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTheme.spacingMd),
        Wrap(
          spacing: AppTheme.spacingMd,
          runSpacing: AppTheme.spacingMd,
          children: moodOptions.map((mood) {
            final isSelected = selectedMood == mood.toLowerCase();
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppHelpers.getMoodEmoji(mood)),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(mood),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => selectedMood = mood.toLowerCase());
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
