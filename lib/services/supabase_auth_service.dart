import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin authentication boundary for the optional cloud account.
///
/// Local playback must not depend on a signed-in account. Callers should
/// present errors to the user without logging passwords, access tokens,
/// refresh tokens, or full authentication responses.
class SupabaseAuthService {
  SupabaseAuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalizedEmail = _validateEmail(email);
    _validatePassword(password);

    return _client.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {
        if (displayName != null && displayName.trim().isNotEmpty)
          'name': displayName.trim(),
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _validateEmail(email);
    if (password.isEmpty) {
      throw const AuthInputException('Ingresá tu contraseña.');
    }

    return _client.auth.signInWithPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<void> sendPasswordRecovery({
    required String email,
    required String redirectTo,
  }) async {
    final normalizedEmail = _validateEmail(email);
    final redirect = Uri.tryParse(redirectTo);
    if (redirect == null ||
        !redirect.hasScheme ||
        !const {'https', 'io.supabase.argentinoplay'}.contains(
          redirect.scheme,
        )) {
      throw const AuthInputException(
        'La dirección de recuperación no es válida.',
      );
    }

    await _client.auth.resetPasswordForEmail(
      normalizedEmail,
      redirectTo: redirectTo,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  String _validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty ||
        email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw const AuthInputException('Ingresá un correo electrónico válido.');
    }
    return email;
  }

  void _validatePassword(String value) {
    if (value.length < 8 || value.length > 128) {
      throw const AuthInputException(
        'La contraseña debe tener entre 8 y 128 caracteres.',
      );
    }
  }
}

/// Safe validation failure suitable for showing in the sign-in UI.
class AuthInputException implements Exception {
  const AuthInputException(this.message);

  final String message;

  @override
  String toString() => message;
}
