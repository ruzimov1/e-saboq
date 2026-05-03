import 'package:flutter_test/flutter_test.dart';

import 'package:edu_interactive/features/auth/data/auth_username.dart';

void main() {
  test('authEmailFromUsername produces internal domain', () {
    expect(
      authEmailFromUsername('test_user'),
      'test_user@eduinteractive.auth',
    );
  });

  test('usernameFromAuthEmail strips internal domain', () {
    expect(
      usernameFromAuthEmail('test_user@eduinteractive.auth'),
      'test_user',
    );
  });
}
