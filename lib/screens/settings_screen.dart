import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../utils/formatters.dart';
import '../models/user_profile.dart';
import '../models/entry.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfile userProfile;
  bool _darkMode = true;
  String? _greenTopic;

  @override
  void initState() {
    super.initState();
    userProfile = HiveService.getUserProfile()!;
    _darkMode = HiveService.isDarkMode();
  }

  Future<void> _showEditDialog() async {
    final nameController = TextEditingController(text: userProfile.name);
    final roleController = TextEditingController(text: userProfile.roleOrClass);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                inputFormatters: [
                  RoleOrClassFormatter(maxLetters: 25, maxDigits: 3),
                ],
                decoration: InputDecoration(
                  labelText: userProfile.mode == 'student'
                      ? 'Class/College'
                      : 'Role',
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final nameText = nameController.text.trim();
              final roleText = roleController.text.trim();

              final nameErr = AppValidators.validateName(nameText);
              if (nameErr != null) {
                _showToast(nameErr);
                return;
              }

              final roleErr = AppValidators.validateRoleOrClass(roleText, userProfile.mode);
              if (roleErr != null) {
                _showToast(roleErr);
                return;
              }

              try {
                final updatedProfile = userProfile.copyWith(
                  name: nameText,
                  roleOrClass: roleText,
                );
                HiveService.saveUserProfile(updatedProfile);
                setState(() {
                  userProfile = updatedProfile;
                });
                Navigator.pop(context);
                _showToast('Profile updated');
              } catch (e) {
                _showToast('Error: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTopic(String topic) async {
    bool? shouldReplace = false;

    if (userProfile.skillsOrSubjects.length == 1) {
      shouldReplace = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Topic Completed! 🎉'),
          content: Text('Congratulations on completing "$topic"!\n\nDo you want to choose a new topic to replace it, or go back?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Go back
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Choose new topic
              child: const Text('Choose New Topic'),
            ),
          ],
        ),
      );
    }

    if (shouldReplace == null) return;

    List<String> currentTopics = List<String>.from(userProfile.skillsOrSubjects);

    currentTopics.remove(topic);

    if (shouldReplace == true) {
      if (!mounted) return;
      // Show dialog to enter new topic
      final newTopicController = TextEditingController();
      final newTopic = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add New Topic'),
          content: TextField(
            controller: newTopicController,
            inputFormatters: [
              RoleOrClassFormatter(maxLetters: 20, maxDigits: 3),
            ],
            decoration: InputDecoration(
              hintText: userProfile.mode == 'student' ? 'e.g., Mathematics, Literature' : 'e.g., Python, Negotiation',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, newTopicController.text.trim()),
              child: const Text('Add'),
            ),
          ],
        ),
      );

      if (newTopic == null || newTopic.trim().isEmpty) {
        return; // Abort completion if they cancel or enter empty topic
      }

      final sanitizedNewTopic = newTopic.trim();
      final singleTopicError = AppValidators.validateSkillsOrSubjects([sanitizedNewTopic]);
      if (singleTopicError != null) {
        _showToast(singleTopicError);
        return;
      }

      final tempTopics = List<String>.from(currentTopics)..add(sanitizedNewTopic);
      final listError = AppValidators.validateSkillsOrSubjects(tempTopics);
      if (listError != null) {
        _showToast(listError);
        return;
      }

      if (!currentTopics.contains(sanitizedNewTopic)) {
        currentTopics.add(sanitizedNewTopic);
      }
    }

    // Save profile changes
    final updatedProfile = userProfile.copyWith(skillsOrSubjects: currentTopics);
    await HiveService.saveUserProfile(updatedProfile);

    // Create a special milestone entry for early topic completion
    final newEntry = Entry(
      date: DateTime.now(),
      mode: userProfile.mode,
      learned: 'Successfully completed the topic: "$topic"! 🏆',
      subjectOrSkill: topic,
      hoursOrEnergy: userProfile.mode == 'student' ? 3.0 : 5.0,
      moodOrFocus: userProfile.mode == 'student' ? '5' : 'focused',
      win: 'Completed topic "$topic" early from profile settings!',
      improve: 'Keep up the momentum with other learning targets!',
    );
    await HiveService.addEntry(newEntry);
    
    setState(() {
      userProfile = updatedProfile;
    });

    _showToast('Topics updated successfully! Milestone logged! 🎉');
  }

  Future<void> _addNewTopicDialog() async {
    final newTopicController = TextEditingController();
    final newTopic = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Topic'),
        content: TextField(
          controller: newTopicController,
          inputFormatters: [
            RoleOrClassFormatter(maxLetters: 20, maxDigits: 3),
          ],
          decoration: InputDecoration(
            hintText: userProfile.mode == 'student' 
                ? 'e.g., Mathematics, Literature' 
                : 'e.g., Python, Negotiation',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, newTopicController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newTopic != null && newTopic.trim().isNotEmpty) {
      final sanitizedNewTopic = newTopic.trim();
      final singleTopicError = AppValidators.validateSkillsOrSubjects([sanitizedNewTopic]);
      if (singleTopicError != null) {
        _showToast(singleTopicError);
        return;
      }

      final tempTopics = List<String>.from(userProfile.skillsOrSubjects)..add(sanitizedNewTopic);
      final listError = AppValidators.validateSkillsOrSubjects(tempTopics);
      if (listError != null) {
        _showToast(listError);
        return;
      }

      final updatedProfile = userProfile.copyWith(skillsOrSubjects: tempTopics);
      await HiveService.saveUserProfile(updatedProfile);

      setState(() {
        userProfile = updatedProfile;
      });

      _showToast('New topic added successfully!');
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all your entries, goals, and streaks. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveService.clearAllData();
      _showToast('All data cleared');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.goNamed('splash');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            _buildSectionHeader('Profile'),
            const SizedBox(height: AppTheme.spacingMd),
            _buildProfileCard(),
            const SizedBox(height: AppTheme.spacingXl),

            // Profiles switching list
            _buildSectionHeader('Profiles / Switch Account'),
            const SizedBox(height: AppTheme.spacingMd),
            _buildProfilesSection(),
            const SizedBox(height: AppTheme.spacingXl),

            // App settings
            _buildSectionHeader('App Settings'),
            const SizedBox(height: AppTheme.spacingMd),
            _buildSettingsTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Daily reminder at ${userProfile.reminderTime}',
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.parse(userProfile.reminderTime.split(':')[0]),
                    minute: int.parse(userProfile.reminderTime.split(':')[1]),
                  ),
                );
                if (time != null && mounted) {
                  final newTimeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  final updatedProfile = userProfile.copyWith(reminderTime: newTimeStr);
                  await HiveService.saveUserProfile(updatedProfile);
                  await NotificationService.scheduleDailyReminder(newTimeStr);
                  setState(() {
                    userProfile = updatedProfile;
                  });
                  _showToast('Reminder scheduled for $newTimeStr');
                }
              },
            ),
            _buildSettingsTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: _darkMode ? 'Currently enabled' : 'Currently disabled',
              trailing: Switch(
                value: _darkMode,
                onChanged: (value) async {
                  await HiveService.setDarkMode(value);
                  setState(() {
                    _darkMode = value;
                  });
                  themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // Data section
            _buildSectionHeader('Data'),
            const SizedBox(height: AppTheme.spacingMd),
            _buildDangerTile(
              icon: Icons.delete_forever,
              title: 'Clear All Data',
              subtitle: 'Delete all entries, goals, and data',
              onTap: _clearAllData,
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // About section
            _buildSectionHeader('About'),
            const SizedBox(height: AppTheme.spacingMd),
            _buildAboutTile(
              icon: Icons.info,
              title: 'App Version',
              subtitle: '1.0.0',
            ),
            _buildAboutTile(
              icon: Icons.code,
              title: 'Build',
              subtitle: 'Flutter',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: AppTheme.accentBlue),
    );
  }

  Widget _buildProfileCard() {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userProfile.mode == 'student'
                          ? '🎓 Student Mode'
                          : '💼 Professional Mode',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userProfile.roleOrClass,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _showEditDialog,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            userProfile.mode == 'student' ? 'Your Subjects:' : 'Your Skills:', 
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.accentBlue)
          ),
          const SizedBox(height: 8),
          if (userProfile.skillsOrSubjects.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'All topics completed! 🎉',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            Column(
              children: userProfile.skillsOrSubjects.map((topic) {
                final isGreen = _greenTopic == topic;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: isGreen 
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: isGreen 
                          ? AppTheme.successGreen 
                          : Colors.redAccent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          topic,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isGreen)
                        ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check, size: 16, color: Colors.white),
                          label: const Text('Completed'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () async {
                            setState(() {
                              _greenTopic = topic;
                            });
                            await Future.delayed(const Duration(milliseconds: 800));
                            await _completeTopic(topic);
                            setState(() {
                              _greenTopic = null;
                            });
                          },
                          icon: const Icon(Icons.help_outline, size: 16, color: Colors.white),
                          label: const Text('Completed?'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          if (userProfile.skillsOrSubjects.length < 6) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _addNewTopicDialog,
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                userProfile.mode == 'student' ? 'Add Subject' : 'Add Skill',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentBlue,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfilesSection() {
    final allProfiles = HiveService.getAllProfiles();
    final activeEmail = HiveService.getActiveUserEmail();

    return Column(
      children: [
        ...allProfiles.map((profile) {
          final isActive = profile.email == activeEmail;
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              border: Border.all(color: isActive ? AppTheme.accentBlue : AppTheme.borderColor),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name + (isActive ? ' (Active)' : ''),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        '${profile.email} • ${profile.mode == 'student' ? 'Student' : 'Professional'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!isActive) ...[
                  TextButton(
                    onPressed: () async {
                      await HiveService.switchProfile(profile.email);
                      final updated = HiveService.getUserProfile()!;
                      await NotificationService.scheduleDailyReminder(updated.reminderTime);
                      _showToast('Switched to ${profile.name}\'s profile!');
                      context.go('/home');
                    },
                    child: const Text('Switch'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Profile?'),
                          content: Text('Are you sure you want to delete ${profile.name}\'s profile and all their history?'),
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
                        await HiveService.deleteProfile(profile.email);
                        setState(() {
                          userProfile = HiveService.getUserProfile()!;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: AppTheme.spacingSm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.goNamed('modeSelection');
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add New Profile'),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: AppTheme.accentBlue),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: trailing ?? const Icon(Icons.arrow_forward),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: Colors.redAccent),
          title: Text(title, style: const TextStyle(color: Colors.redAccent)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward, color: Colors.redAccent),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildAboutTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: AppTheme.textSecondary),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
      ),
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
