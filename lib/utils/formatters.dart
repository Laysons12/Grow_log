import 'package:flutter/services.dart';

class RoleOrClassFormatter extends TextInputFormatter {
  final int maxLetters;
  final int maxDigits;

  RoleOrClassFormatter({required this.maxLetters, required this.maxDigits});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Allowed characters: letters, digits, spaces, and punctuation: . , & - '
    final allowedRegex = RegExp(r"^[a-zA-Z0-9 .,&'-]+$");
    if (!allowedRegex.hasMatch(newValue.text)) {
      return oldValue;
    }

    final letterCount = newValue.text.replaceAll(RegExp(r"[^a-zA-Z]"), '').length;
    final digitCount = newValue.text.replaceAll(RegExp(r"[^0-9]"), '').length;

    if (letterCount > maxLetters || digitCount > maxDigits) {
      return oldValue;
    }

    return newValue;
  }
}

class MaxDigitsFormatter extends TextInputFormatter {
  final int maxDigits;
  final Function()? onLimitExceeded;
  MaxDigitsFormatter(this.maxDigits, {this.onLimitExceeded});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitCount = newValue.text.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount > maxDigits) {
      if (onLimitExceeded != null) {
        onLimitExceeded!();
      }
      return oldValue;
    }
    return newValue;
  }
}
