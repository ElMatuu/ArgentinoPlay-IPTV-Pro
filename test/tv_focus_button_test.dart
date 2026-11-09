import 'package:argentino_play/services/tv_focus_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness() {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: Scaffold(
        body: FocusTraversalGroup(
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TvFocusButton(
                label: 'Reproducir',
                icon: Icons.play_arrow,
                onPressed: _noop,
                autofocus: true,
              ),
              TvFocusButton(
                label: 'Pausar',
                icon: Icons.pause,
                onPressed: _noop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('focus outline is more prominent while focused', (tester) async {
    await tester.pumpWidget(buildHarness());
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Reproducir'),
    );
    final side = button.style!.side!;
    final focused = side.resolve({WidgetState.focused})!;
    final idle = side.resolve(<WidgetState>{})!;

    expect(focused.width, 3);
    expect(idle.width, 1);
    expect(focused.color, isNot(idle.color));
  });

  testWidgets('Tab moves focus through TV controls', (tester) async {
    await tester.pumpWidget(buildHarness());
    final pauseContext = tester.element(find.text('Pausar'));
    expect(
      Focus.of(tester.element(find.text('Reproducir'))).hasPrimaryFocus,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(Focus.of(pauseContext).hasPrimaryFocus, isTrue);
  });
}

void _noop() {}
