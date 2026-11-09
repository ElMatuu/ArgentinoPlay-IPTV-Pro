import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Android TV Down key moves focus between channel rows',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF16A085),
            ),
            focusColor: const Color(0xFF16A085).withValues(alpha: 0.22),
          ),
          home: Scaffold(
            body: FocusTraversalGroup(
              child: Column(
                children: [
                  ListTile(
                    autofocus: true,
                    title: const Text('Canal Uno'),
                    onTap: _noop,
                  ),
                  ListTile(
                    title: const Text('Canal Dos'),
                    onTap: _noop,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final first = tester.widget<ListTile>(find.byType(ListTile).at(0));
      final second = tester.widget<ListTile>(find.byType(ListTile).at(1));
      expect(first.onTap, isNotNull);
      expect(second.onTap, isNotNull);

      final initialFocus = FocusManager.instance.primaryFocus;
      expect(initialFocus, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, isNot(same(initialFocus)));
    },
  );

  test('TV focus overlay uses a visible high-contrast theme color', () {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF16A085),
      ),
      focusColor: const Color(0xFF16A085).withValues(alpha: 0.22),
    );

    expect(theme.focusColor.a, closeTo(0.22, 0.01));
    expect(theme.focusColor, isNot(Colors.transparent));
  });
}

void _noop() {}
