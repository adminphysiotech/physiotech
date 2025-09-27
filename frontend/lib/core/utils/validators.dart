String? validateRequired(String value, {required String label}) {
  if (value.trim().isEmpty) {
    return '$label is required';
  }
  return null;
}

String? validateEmail(String value) {
  if (value.trim().isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[a-zA-Z]{2,}$');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePassword(String value) {
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  final hasUpper = value.contains(RegExp(r'[A-Z]'));
  final hasLower = value.contains(RegExp(r'[a-z]'));
  final hasNumber = value.contains(RegExp(r'[0-9]'));
  if (!(hasUpper && hasLower && hasNumber)) {
    return 'Password must include upper, lower, and number';
  }
  return null;
}

String? validatePasswordConfirmation(String password, String confirmation) {
  if (confirmation.isEmpty) {
    return 'Password confirmation is required';
  }
  if (password != confirmation) {
    return 'Passwords do not match';
  }
  return null;
}

String? validatePhoneNumber(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 8) {
    return 'Phone number looks invalid';
  }
  return null;
}
