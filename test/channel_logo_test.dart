import 'package:argentino_play/services/channel_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(String url) {
    return MaterialApp(
      home: Scaffold(
        body: ChannelLogo(url: url),
      ),
    );
  }

  group('ChannelLogo', () {
    testWidgets('shows a fallback icon when no logo is provided',
        (tester) async {
      await tester.pumpWidget(buildSubject(''));

      expect(find.byIcon(Icons.live_tv), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('does not load unsupported or credential-bearing URLs',
        (tester) async {
      for (final url in [
        'file:///tmp/logo.png',
        'https://user:password@example.org/logo.png',
        'javascript:alert(1)',
      ]) {
        await tester.pumpWidget(buildSubject(url));

        expect(find.byIcon(Icons.live_tv), findsOneWidget);
        expect(find.byType(Image), findsNothing);
      }
    });

    testWidgets('requests a valid HTTP(S) logo URL', (tester) async {
      await tester.pumpWidget(
        buildSubject('https://example.org/logo.png'),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<NetworkImage>());
      expect((image.image as NetworkImage).url, 'https://example.org/logo.png');
    });
  });
}
