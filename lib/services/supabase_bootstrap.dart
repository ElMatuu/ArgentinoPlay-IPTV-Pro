import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the optional cloud client without making app startup depend on it.
/// Only the project URL and publishable key belong in a distributed client.
/// Secret keys and personal access tokens must never be compiled into the app.
abstract final class SupabaseBootstrap {
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool _initialized = false;

  /// True only after Supabase.initialize completed successfully.
  /// Environment variables alone do not mean the client is ready.
  static bool get isConfigured => _initialized;

  /// Returns false when cloud configuration is absent (offline/local mode).
  static Future<bool> initializeFromEnvironment() async {
    if (_url.isEmpty && _publishableKey.isEmpty) return false;
    if (_url.isEmpty || _publishableKey.isEmpty) {
      throw StateError(
        'Both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be configured.',
      );
    }

    final uri = Uri.tryParse(_url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.path.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'SUPABASE_URL must be a valid HTTPS project base URL.',
      );
    }
    if (!_publishableKey.startsWith('sb_publishable_')) {
      throw const FormatException(
        'SUPABASE_PUBLISHABLE_KEY must be a Supabase publishable key.',
      );
    }

    await Supabase.initialize(url: _url, publishableKey: _publishableKey);
    _initialized = true;
    return true;
  }
}
