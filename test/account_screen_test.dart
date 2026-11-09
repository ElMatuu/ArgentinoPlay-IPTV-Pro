import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:argentino_play/services/account_screen.dart';
import 'package:argentino_play/services/supabase_bootstrap.dart';

void main() {
  testWidgets(
    'account screen stays available when cloud is not initialized',
    (tester) async {
    expect(SupabaseBootstrap.isConfigured, isFalse);

    await tester.pumpWidget(
      const MaterialApp(home: AccountScreen()),
    );

    expect(
      find.textContaining('La conexión con la nube todavía no está configurada'),
      findsOneWidget,
    );
  });
}
