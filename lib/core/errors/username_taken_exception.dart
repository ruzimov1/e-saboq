/// Ro'yxatdan o'tishda login allaqachon band bo'lganda.
class UsernameTakenException implements Exception {
  const UsernameTakenException();

  @override
  String toString() => 'Bu login band. Boshqa nom tanlang.';
}
