import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:argentino_play/services/supabase_auth_service.dart';

void main() {
  late SupabaseAuthService auth;

  setUp(() {
    auth = SupabaseAuthService(
      client: SupabaseClient('https://example.supabase.co', 'test-publishable'),
    );
  });

  test('rejects malformed email before making a network request', () async {
    await expectLater(
      auth.signIn(email: 'not-an-email', password: 'correct horse battery'),
      throwsA(isA<AuthInputException>()),
    );
  });

  test('rejects passwords shorter than eight characters on sign-up', () async {
    await expectLater(
      auth.signUp(email: 'user@example.com', password: 'short'),
      throwsA(isA<AuthInputException>()),
    );
  });

  test('rejects empty password on sign-in', () async {
    await expectLater(
      auth.signIn(email: 'user@example.com', password: ''),
      throwsA(isA<AuthInputException>()),
    );
  });

  test('rejects display names longer than the profile database limit',
      () async {
    await expectLater(
      auth.signUp(
        email: 'user@example.com',
        password: 'correct horse battery',
        displayName: 'a' * 81,
      ),
      throwsA(isA<AuthInputException>()),
    );
  });

  test('rejects unsupported recovery redirect schemes', () async {
    await expectLater(
      auth.sendPasswordRecovery(
        email: 'user@example.com',
        redirectTo: 'javascript:alert(1)',
      ),
      throwsA(isA<AuthInputException>()),
    );
  });
}
