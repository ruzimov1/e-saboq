/// Firebase Email/Password faqat email-format qabul qiladi — login uchun ichki domen.
const String kAuthEmailDomain = 'eduinteractive.auth';

/// Foydalanuvchi kiritgan loginni saqlash uchun (kichik harf, bo'shliqsiz).
String normalizeUsername(String raw) {
  return raw.trim().toLowerCase();
}

/// Firebase `createUser` / `signIn` uchun yashirin email.
String authEmailFromUsername(String raw) {
  final u = normalizeUsername(raw);
  return '$u@$kAuthEmailDomain';
}

/// `currentUser.email` dan login qatorini qaytaradi (eski haqiqiy email bo'lsa — o'zgartirmaymiz).
String usernameFromAuthEmail(String? email) {
  if (email == null || email.isEmpty) return '';
  const suffix = '@$kAuthEmailDomain';
  if (email.endsWith(suffix)) {
    return email.substring(0, email.length - suffix.length);
  }
  return email;
}
