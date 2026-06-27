import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../services/backup_service.dart';
import '../../services/hive_service.dart';
import '../../utils/formatters.dart';

class BasicDetailsScreen extends StatefulWidget {
  final String mode;
  const BasicDetailsScreen({Key? key, required this.mode}) : super(key: key);

  @override
  State<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _industryController = TextEditingController();
  late String _mode;
  bool _isLoading = false;

  // Username availability state
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;

    // Set up live username availability check
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _usernameDebounce?.cancel();
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    // Basic validation first
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!usernameRegex.hasMatch(username)) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    final digitCount = username.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount > 4) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () {
      final taken = HiveService.isUsernameTaken(username);
      if (mounted) {
        setState(() {
          _isUsernameAvailable = !taken;
          _isCheckingUsername = false;
        });
      }
    });
  }

  // --- Validators ---

  String? _validateName(String? value) {
    return AppValidators.validateName(value);
  }

  String? _validateUsername(String? value) {
    return AppValidators.validateUsername(value, isTaken: HiveService.isUsernameTaken);
  }

  String? _validateEmail(String? value) {
    return AppValidators.validateEmail(value, isTaken: HiveService.isEmailTaken);
  }

  String? _validateRole(String? value) {
    return AppValidators.validateRoleOrClass(value, _mode);
  }

  String? _validateIndustry(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final text = value.trim();
    final letterCount = text.replaceAll(RegExp(r"[^a-zA-Z]"), '').length;
    if (letterCount > 20) {
      return 'Industry can have at most 20 letters';
    }
    final digitCount = text.replaceAll(RegExp(r"[^0-9]"), '').length;
    if (digitCount > 2) {
      return 'Industry can have at most 2 numbers';
    }
    final allowedRegex = RegExp(r"^[a-zA-Z0-9 .,&'-]+$");
    if (!allowedRegex.hasMatch(text)) {
      return 'Contains invalid characters';
    }
    return null;
  }

  Future<void> _continueToNextStep() async {
    if (_isCheckingUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the username availability check to finish.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final role = _roleController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final hasBackup = await BackupService.hasBackup(email);
      if (hasBackup && mounted) {
        // Show restore backup dialog
        final shouldRestore = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Welcome Back! 🎒'),
            content: Text(
              'We found an existing cloud backup for "$email".\n\nWould you like to restore your past logs and goals, or start fresh?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Start Fresh'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore My Data'),
              ),
            ],
          ),
        );

        if (shouldRestore == true && mounted) {
          final success = await BackupService.restoreBackup(email);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Successfully restored backup! 🎉')),
            );
            context.goNamed('home');
            return;
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to restore backup. Proceeding manually.')),
            );
          }
        }
      }

      if (mounted) {
        final encodedName = Uri.encodeComponent(name);
        final encodedUsername = Uri.encodeComponent(username);
        final encodedRole = Uri.encodeComponent(role);
        final encodedEmail = Uri.encodeComponent(email);
        context.push('/subject-selection?mode=$_mode&name=$encodedName&username=$encodedUsername&role=$encodedRole&email=$encodedEmail');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking backup: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isStudent = _mode == 'student';

    return Scaffold(
      appBar: AppBar(title: const Text('Step 2 of 3'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Tell us about yourself',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Help us personalize your GrowLog experience',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Mode indicator
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isStudent ? '🎓' : '💼',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isStudent ? 'Student Mode' : 'Professional Mode',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            isStudent
                                ? 'Track your academic growth'
                                : 'Track your career growth',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Name input
                Text('Full Name', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _nameController,
                  maxLength: 25,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                  validator: _validateName,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Username input
                Text('Username', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _usernameController,
                  maxLength: 25,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    MaxDigitsFormatter(4),
                  ],
                  validator: _validateUsername,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    hintText: 'Choose a unique username',
                    prefixIcon: const Icon(Icons.alternate_email),
                    counterText: '',
                    suffixIcon: _buildUsernameSuffix(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Email input
                Text('Email Address', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Role/Class input
                Text(
                  isStudent ? 'Class / College' : 'Current Role',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextFormField(
                  controller: _roleController,
                  inputFormatters: [
                    RoleOrClassFormatter(maxLetters: 25, maxDigits: 3),
                  ],
                  maxLength: 50,
                  validator: _validateRole,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    hintText: isStudent
                        ? 'e.g., Class 10, B.Tech 2nd Year'
                        : 'e.g., Software Engineer, Product Manager',
                    prefixIcon: const Icon(Icons.badge),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Industry field (only for professionals)
                if (!isStudent) ...[
                  Text('Industry', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextFormField(
                    controller: _industryController,
                    inputFormatters: [
                      RoleOrClassFormatter(maxLetters: 20, maxDigits: 2),
                    ],
                    validator: _validateIndustry,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Technology, Finance, Healthcare',
                      prefixIcon: Icon(Icons.work),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _continueToNextStep,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Back button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildUsernameSuffix() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return null;

    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isUsernameAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (_isUsernameAvailable == false) {
      return const Icon(Icons.cancel, color: Colors.red);
    }

    return null;
  }
}
