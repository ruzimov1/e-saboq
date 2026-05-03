import 'dart:math';

/// Topshiriq kodi: masalan `ABC12` (harflar + raqamlar).
String generateAssignmentCode({int length = 5}) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
}
