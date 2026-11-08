import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:argentino_play/services/local_library_repository.dart';
import 'package:argentino_play/main.dart';

void main() {
  test('M3U parser reads valid HTTP channels and metadata', () {
    const playlist = '#EXTM3U\n#EXTINF:-1 tvg-logo="https://example.org/logo.png" group-title="Noticias",Canal Demo\nhttps://example.org/live.m3u8\n';
    final channels = parseM3u(playlist);
    expect(channels, hasLength(1));
    expect(channels.single.name, 'Canal Demo');
    expect(channels.single.group, 'Noticias');
    expect(channels.single.logo, 'https://example.org/logo.png');
  });

  test('M3U parser ignores unsupported schemes and malformed entries', () {
    const playlist = '#EXTM3U\n#EXTINF:-1,No válido\nfile:///etc/passwd\n#EXTINF:-1,Válido\nhttps://example.org/live.m3u8\n';
    final channels = parseM3u(playlist);
    expect(channels, hasLength(1));
    expect(channels.single.name, 'Válido');
  });

  testWidgets('home screen shows playlist import empty state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp('argentino-play-test-');
    final repository = LocalLibraryRepository(directoryProvider: () async => directory);
    await tester.pumpWidget(ArgentinoPlayApp(libraryRepository: repository));
    await tester.pumpAndSettle();
    expect(find.text('Tu catálogo empieza acá'), findsOneWidget);
    expect(find.text('Importar lista'), findsOneWidget);
    await directory.delete(recursive: true);
  });
}
