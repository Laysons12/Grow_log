import 'package:flutter_test/flutter_test.dart';
import 'package:growlog/utils/validators.dart';

void main() {
  group('AppValidators Unit Tests', () {
    test('validateName validations', () {
      expect(AppValidators.validateName(null), 'Please enter your name');
      expect(AppValidators.validateName(''), 'Please enter your name');
      expect(AppValidators.validateName('   '), 'Please enter your name');
      expect(AppValidators.validateName('John '), 'Name cannot have leading or trailing spaces');
      expect(AppValidators.validateName(' John'), 'Name cannot have leading or trailing spaces');
      expect(AppValidators.validateName('John123'), 'Name can only contain letters');
      expect(AppValidators.validateName('John!'), 'Name can only contain letters');
      expect(AppValidators.validateName('a' * 26), 'Name must be 25 characters or less');
      expect(AppValidators.validateName('John Doe'), isNull);
    });

    test('validateUsername validations', () {
      expect(AppValidators.validateUsername(null), 'Please enter a username');
      expect(AppValidators.validateUsername(''), 'Please enter a username');
      expect(AppValidators.validateUsername('user '), 'Username cannot have leading or trailing spaces');
      expect(AppValidators.validateUsername('user!'), 'Username can only contain letters and numbers');
      expect(AppValidators.validateUsername('a' * 26), 'Username must be 25 characters or less');
      expect(AppValidators.validateUsername('user12345'), 'Username can have at most 4 numbers');
      expect(AppValidators.validateUsername('user1234', isTaken: (u) => true), 'This username is already taken, please choose another');
      expect(AppValidators.validateUsername('user1234', isTaken: (u) => false), isNull);
    });

    test('validateEmail validations', () {
      expect(AppValidators.validateEmail(null), 'Please enter your email address');
      expect(AppValidators.validateEmail(''), 'Please enter your email address');
      expect(AppValidators.validateEmail('test@domain'), 'Please enter a valid email address');
      expect(AppValidators.validateEmail('test@domain.com', isTaken: (e) => true), 'This email address is already registered');
      expect(AppValidators.validateEmail('test@domain.com', isTaken: (e) => false), isNull);
    });

    test('validateRoleOrClass validations', () {
      expect(AppValidators.validateRoleOrClass(null, 'student'), 'Please enter your class or college');
      expect(AppValidators.validateRoleOrClass(null, 'professional'), 'Please enter your current role');
      expect(AppValidators.validateRoleOrClass('Class 10!', 'student'), 'Contains invalid characters');
      expect(AppValidators.validateRoleOrClass('a' * 26, 'student'), 'Class/College can have at most 25 letters');
      expect(AppValidators.validateRoleOrClass('a' * 26, 'professional'), 'Role can have at most 25 letters');
      expect(AppValidators.validateRoleOrClass('Class 1234', 'student'), 'Class/College can have at most 3 numbers');
      expect(AppValidators.validateRoleOrClass('St. Xavier\'s, & Co.', 'professional'), isNull);
    });

    test('validateSkillsOrSubjects validations', () {
      expect(AppValidators.validateSkillsOrSubjects([]), 'Please select at least one topic');
      expect(AppValidators.validateSkillsOrSubjects(List.generate(7, (i) => 'Topic $i')), 'You can select at most 6 topics');
      expect(AppValidators.validateSkillsOrSubjects(['Math', '']), 'Topic cannot be empty');
      expect(AppValidators.validateSkillsOrSubjects(['Math', 'a' * 21]), 'Topic can have at most 20 letters');
      expect(AppValidators.validateSkillsOrSubjects(['Math', 'Math123456']), 'Topic can have at most 3 numbers');
      expect(AppValidators.validateSkillsOrSubjects(['Math', 'Physics', 'math']), 'Duplicate topics are not allowed');
      expect(AppValidators.validateSkillsOrSubjects(['Math', 'Physics']), isNull);
    });

    test('validateReminderTime validations', () {
      expect(AppValidators.validateReminderTime(null), 'Please enter a reminder time');
      expect(AppValidators.validateReminderTime('9:00'), 'Reminder time must be in HH:mm 24-hour format');
      expect(AppValidators.validateReminderTime('25:00'), 'Reminder time must be in HH:mm 24-hour format');
      expect(AppValidators.validateReminderTime('09:60'), 'Reminder time must be in HH:mm 24-hour format');
      expect(AppValidators.validateReminderTime('09:00'), isNull);
    });

    test('validateDurationHours validations', () {
      expect(AppValidators.validateDurationHours(null), 'Please enter study/learning hours');
      expect(AppValidators.validateDurationHours(0.0), 'Hours must be greater than 0');
      expect(AppValidators.validateDurationHours(-1.5), 'Hours must be greater than 0');
      expect(AppValidators.validateDurationHours(17.0), 'Hours cannot exceed 16 hours per day');
      expect(AppValidators.validateDurationHours(8.5), isNull);
    });

    test('validateMood validations', () {
      expect(AppValidators.validateMood(null), 'Please select a mood');
      expect(AppValidators.validateMood('happy'), 'Invalid mood selection');
      expect(AppValidators.validateMood('Focused'), isNull);
      expect(AppValidators.validateMood('motivated'), isNull);
    });

    test('validateNotes validations', () {
      expect(AppValidators.validateNotes('a' * 501, fieldName: 'Doubts'), 'Doubts must be 500 characters or less');
      expect(AppValidators.validateNotes('a' * 500), isNull);
      expect(AppValidators.validateNotes('1' * 21, fieldName: 'Learned'), 'Learned can have at most 20 numbers');
    });

    test('validateWin validations', () {
      expect(AppValidators.validateWin(null), isNull);
      expect(AppValidators.validateWin(''), isNull);
      expect(AppValidators.validateWin('1' * 21), 'Win of the day can have at most 20 numbers');
      expect(AppValidators.validateWin('a' * 201), 'Win of the day can have at most 200 letters');
      expect(AppValidators.validateWin('My Win 12345'), isNull);
    });

    test('validateImprove validations', () {
      expect(AppValidators.validateImprove(null), isNull);
      expect(AppValidators.validateImprove(''), isNull);
      expect(AppValidators.validateImprove('1' * 21), 'What to improve can have at most 20 numbers');
      expect(AppValidators.validateImprove('a' * 600), isNull); // unlimited letters
    });

    test('validateDoubts validations', () {
      expect(AppValidators.validateDoubts(null), isNull);
      expect(AppValidators.validateDoubts(''), isNull);
      expect(AppValidators.validateDoubts('1' * 21), 'Doubts can have at most 20 numbers');
      expect(AppValidators.validateDoubts('a' * 1000), isNull); // unlimited letters
    });

    test('validateGoalTitle validations', () {
      expect(AppValidators.validateGoalTitle(null), 'Please enter a goal title');
      expect(AppValidators.validateGoalTitle('a' * 61), 'Goal title must be 60 characters or less');
      expect(AppValidators.validateGoalTitle('My Goal'), isNull);
    });
  });
}
