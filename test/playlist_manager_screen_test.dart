import 'dart:io';

import 'package:argentino_play/services/playlist_library_repository.dart';
import 'package:argentino_play/services/playlist_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late PlaylistLibraryRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('playlist-manager-');
    repository =
        PlaylistLibraryRepository(directoryProvider: () async => directory);
    await repository.createPlaylist(
      name: 'Noticias',
      source: '#EXTM3U\n#EXTINF:-1,Canal Noticias\nhttps://example.org/news.m3u8\n',
      channelCount: 1,
      id: 'news',
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  Future<void> openManager(
    WidgetTester tester, {
    required void Function(PlaylistRecord record, String source) onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlaylistManagerScreen(
                      repository: repository,
                      activePlaylistId: null,
                      onSelected: onSelected,
                    ),
                  ),
                );
              },
              child: const Text('Abrir listas'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir listas'));
    // The screen loads its manifest from disk. Let real file I/O complete
    // outside the widget test's fake-async clock before settling animations.
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows saved playlist and channel count', (tester) async {
    await openManager(tester, onSelected: (_, __) {});

    expect(find.text('Mis listas'), findsOneWidget);
    expect(find.text('Noticias'), findsOneWidget);
    expect(find.text('1 canales'), findsOneWidget);
  });

  testWidgets('renames a playlist from its actions menu', (tester) async {
    await openManager(tester, onSelected: (_, __) {});

    await tester.tap(find.byTooltip('Acciones de Noticias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renombrar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Noticias nacionales');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Noticias nacionales'), findsOneWidget);
    expect(await repository.loadPlaylist('news'), contains('Canal Noticias'));
  });

  testWidgets('requires confirmation before deleting a playlist',
      (tester) async {
    await openManager(tester, onSelected: (_, __) {});

    await tester.tap(find.byTooltip('Acciones de Noticias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Querés eliminar "Noticias"? Esta acción no se puede deshacer.'),
        findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no guardaste listas.'), findsOneWidget);
    expect(await repository.listPlaylists(), isEmpty);
  });

  testWidgets('selects and activates a saved playlist', (tester) async {
    PlaylistRecord? selected;
    String? selectedSource;

    await openManager(
      tester,
      onSelected: (record, source) {
        selected = record;
        selectedSource = source;
      },
    );

    await tester.tap(find.widgetWithText(ListTile, 'Noticias'));
    await tester.pumpAndSettle();

    expect(selected?.id, 'news');
    expect(selectedSource, contains('Canal Noticias'));
    expect(await repository.activePlaylistId(), 'news');
  });
}
