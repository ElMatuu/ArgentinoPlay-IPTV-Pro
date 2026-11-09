import 'package:flutter_test/flutter_test.dart';

import 'package:argentino_play/services/supabase_bootstrap.dart';

void main() {
  test('cloud account stays unavailable until initialization succeeds', () {
    expect(SupabaseBootstrap.isConfigured, isFalse);
  });
}
