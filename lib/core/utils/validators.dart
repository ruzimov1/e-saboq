String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email kiriting';
  }
  final email = value.trim();
  final ok = RegExp(r'^[\w.+-]+@[\w.-]+\.\w{2,}$').hasMatch(email);
  return ok ? null : 'Email noto\'g\'ri';
}

String? validatePassword(String? value, {int minLength = 6}) {
  if (value == null || value.isEmpty) {
    return 'Parol kiriting';
  }
  if (value.length < minLength) {
    return 'Kamida $minLength belgi';
  }
  return null;
}

String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName kiriting';
  }
  return null;
}

/// Login: 3–24 belgi, lotin harflari, raqam va pastki chiziq.
String? validateUsername(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Login kiriting';
  }
  final u = value.trim();
  final ok = RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(u);
  return ok
      ? null
      : 'Login: 3–24 belgi, faqat lotin harflari, raqam va _';
}
