import 'package:argentino_play/services/playlist_library_repository.dart';
import 'package:argentino_play/services/playlist_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryPlaylistRepository extends PlaylistLibraryRepository {
  final List<PlaylistRecord> records = [
    PlaylistRecord(
      id: 'news',
      name: 'Noticias',
      channelCount: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  ];

  final Map<String, String> sources = {
    'news':
        '#EXTM3U\n#EXTINF:-1,Canal Noticias\nhttps://example.org/news.m3u8\n',
  };

  String? activeId;

  @override
  Future<List<PlaylistRecord>> listPlaylists() async =>
      List<PlaylistRecord>.unmodifiable(records);

  @override
  Future<String?> loadPlaylist(String id) async => sources[id];

  @override
  Future<PlaylistRecord> renamePlaylist(String id, String name) async {
    final index = records.indexWhere((record) => record.id == id);
    if (index < 0) throw const FormatException('Playlist not found.');
    final old = records[index];
    final updated = PlaylistRecord(
      id: old.id,
      name: name.trim(),
      channelCount: old.channelCount,
      createdAt: old.createdAt,
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    records[index] = updated;
    return updated;
  }

  @override
  Future<void> deletePlaylist(String id) async {
    records.removeWhere((record) => record.id == id);
    sources.remove(id);
    if (activeId == id) activeId = null;
  }

  @override
  Future<String?> activePlaylistId() async => activeId;

  @override
  Future<void> setActivePlaylistId(String? id) async {
    if (id != null && !records.any((record) => record.id == id)) {
      throw const FormatException('Cannot activate an unknown playlist.');
    }
    activeId = id;
  }
}

void main() {
  late _MemoryPlaylistRepository repository;

  setUp(() {
    repository = _MemoryPlaylistRepository();
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
    // The in-memory repository resolves deterministically; no filesystem I/O
    // or indeterminate loading animation is needed in these widget tests.
    await tester.pump();
    await tester.pump();
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
    expect(
      await repository.loadPlaylist('news'),
      contains('Canal Noticias'),
    );
  });

  testWidgets('requires confirmation before deleting a playlist',
      (tester) async {
    await openManager(tester, onSelected: (_, __) {});

    await tester.tap(find.byTooltip('Acciones de Noticias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '¿Querés eliminar "Noticias"? Esta acción no se puede deshacer.',
      ),
      findsOneWidget,
    );
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
