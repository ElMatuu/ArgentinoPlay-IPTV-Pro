import 'package:argentino_play/services/playlist_library_repository.dart';
import 'package:argentino_play/services/playlist_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic in-memory playlist library used by these widget tests.
///
/// Widget tests run inside a fake-async clock, so real dart:io futures
/// started by PlaylistLibraryRepository never complete there: the
/// CircularProgressIndicator of the FutureBuilder keeps scheduling frames
/// forever and any pumpAndSettle issued while it is visible times out.
/// Testing the screen against this fake removes pending file I/O entirely.
/// The production repository keeps its own coverage in
/// playlist_library_repository_test.dart.
class _FakePlaylistLibraryRepository extends PlaylistLibraryRepository {
  final Map<String, PlaylistRecord> _records = {};
  final Map<String, String> _sources = {};
  String? _activeId;

  void seed({
    required String id,
    required String name,
    required int channelCount,
    required String source,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    _records[id] = PlaylistRecord(
      id: id,
      name: name,
      channelCount: channelCount,
      createdAt: now,
      updatedAt: now,
    );
    _sources[id] = source;
  }

  @override
  Future<List<PlaylistRecord>> listPlaylists() async {
    final records = List<PlaylistRecord>.of(_records.values);
    records.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return records;
  }

  @override
  Future<String?> loadPlaylist(String id) async => _sources[id];

  @override
  Future<String?> activePlaylistId() async => _activeId;

  @override
  Future<void> setActivePlaylistId(String? id) async {
    if (id != null && !_records.containsKey(id)) {
      throw const FormatException('Cannot activate an unknown playlist.');
    }
    _activeId = id;
  }

  @override
  Future<PlaylistRecord> renamePlaylist(String id, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.length > 80) {
      throw const FormatException('Playlist name must contain 1-80 chars.');
    }
    final record = _records[id];
    if (record == null) {
      throw const FormatException('Playlist not found.');
    }
    final updated = PlaylistRecord(
      id: record.id,
      name: cleanName,
      channelCount: record.channelCount,
      createdAt: record.createdAt,
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    _records[id] = updated;
    return updated;
  }

  @override
  Future<void> deletePlaylist(String id) async {
    _records.remove(id);
    _sources.remove(id);
    if (_activeId == id) {
      _activeId = null;
    }
  }
}

void main() {
  late _FakePlaylistLibraryRepository repository;

  setUp(() {
    repository = _FakePlaylistLibraryRepository();
    repository.seed(
      id: 'news',
      name: 'Noticias',
      channelCount: 1,
      source:
          '#EXTM3U\n#EXTINF:-1,Canal Noticias\nhttps://example.org/news.m3u8\n',
    );
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
    final renamed = await repository.listPlaylists();
    expect(renamed, hasLength(1));
    expect(renamed.single.name, 'Noticias nacionales');
    expect(await repository.loadPlaylist('news'), contains('Canal Noticias'));
  });

  testWidgets('rejects an empty rename and keeps the previous name',
      (tester) async {
    await openManager(tester, onSelected: (_, __) {});

    await tester.tap(find.byTooltip('Acciones de Noticias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renombrar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo renombrar'), findsOneWidget);
    expect(find.text('Noticias'), findsOneWidget);
  });

  testWidgets('requires confirmation before deleting a playlist',
      (tester) async {
    await openManager(tester, onSelected: (_, __) {});

    await tester.tap(find.byTooltip('Acciones de Noticias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    const confirmation =
        '¿Querés eliminar "Noticias"? Esta acción no se puede deshacer.';
    expect(find.text(confirmation), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Todavía no guardaste listas.'),
      findsOneWidget,
    );
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
