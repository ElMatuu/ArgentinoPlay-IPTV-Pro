import 'dart:typed_data';

import 'package:argentino_play/services/playlist_library_repository.dart';
import 'package:argentino_play/services/playlist_manager_screen.dart';
import 'package:file_picker/file_picker.dart';
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
  Future<PlaylistRecord> replacePlaylistSource({
    required String id,
    required String source,
    required int channelCount,
  }) async {
    if (channelCount < 1) {
      throw const FormatException(
        'Playlist must contain at least one channel.',
      );
    }
    final record = _records[id];
    if (record == null) {
      throw const FormatException('Playlist not found.');
    }
    final updated = PlaylistRecord(
      id: record.id,
      name: record.name,
      channelCount: channelCount,
      createdAt: record.createdAt,
      updatedAt: DateTime.utc(2026, 1, 3),
    );
    _records[id] = updated;
    _sources[id] = source;
    return updated;
  }

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
    String? activePlaylistId,
    Future<FilePickerResult?> Function()? pickPlaylistFile,
    void Function(PlaylistRecord record, String source)? onReplaced,
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
                      activePlaylistId: activePlaylistId,
                      onSelected: onSelected,
                      onReplaced: onReplaced ?? (_, __) {},
                      pickPlaylistFile: pickPlaylistFile,
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
    expect(find.text('1 canal'), findsOneWidget);
  });

  testWidgets('uses plural channel label when count is not one',
      (tester) async {
    repository.seed(
      id: 'sports',
      name: 'Deportes',
      channelCount: 2,
      source: '#EXTM3U\\n',
    );
    await openManager(tester, onSelected: (_, __) {});

    expect(find.text('2 canales'), findsOneWidget);
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

  testWidgets('replaces active playlist source and notifies the player state',
      (tester) async {
    const replacement =
        '#EXTM3U\n#EXTINF:-1,Canal Nuevo\nhttps://example.org/new.m3u8\n';
    PlaylistRecord? replacedRecord;
    String? replacedSource;

    await openManager(
      tester,
      onSelected: (_, __) {},
      activePlaylistId: 'news',
      pickPlaylistFile: () async => FilePickerResult([
        PlatformFile(
          name: 'replacement.m3u8',
          size: replacement.length,
          bytes: Uint8List.fromList(replacement.codeUnits),
        ),
      ]),
      onReplaced: (record, source) {
        replacedRecord = record;
        replacedSource = source;
      },
    );

    await tester.tap(find.byTooltip('Acciones de Noticias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reemplazar M3U/M3U8'));
    await tester.pumpAndSettle();

    expect(replacedRecord?.id, 'news');
    expect(replacedRecord?.name, 'Noticias');
    expect(replacedRecord?.channelCount, 1);
    expect(replacedSource, contains('Canal Nuevo'));
    expect(await repository.loadPlaylist('news'), contains('Canal Nuevo'));
    expect(
      find.text('Lista "Noticias" actualizada: 1 canal.'),
      findsOneWidget,
    );
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

  testWidgets('does not replace a playlist when the selected file is invalid',
      (tester) async {
    const invalid = 'not an M3U playlist';
    await openManager(
      tester,
      onSelected: (_, __) {},
      activePlaylistId: 'news',
      pickPlaylistFile: () async => FilePickerResult([
        PlatformFile(
          name: 'invalid.m3u',
          size: invalid.length,
          bytes: Uint8List.fromList(invalid.codeUnits),
        ),
      ]),
    );

    await tester.tap(find.byTooltip('Acciones de Noticias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reemplazar M3U/M3U8'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se encontraron canales'), findsOneWidget);
    expect(await repository.loadPlaylist('news'), contains('Canal Noticias'));
  });

  testWidgets('does not notify active player when replacing an inactive list',
      (tester) async {
    const replacement =
        '#EXTM3U\\n#EXTINF:-1,Canal Nuevo\\nhttps://example.org/new.m3u8\\n';
    var replacementNotifications = 0;
    await openManager(
      tester,
      onSelected: (_, __) {},
      activePlaylistId: 'another-list',
      pickPlaylistFile: () async => FilePickerResult([
        PlatformFile(
          name: 'replacement.m3u8',
          size: replacement.length,
          bytes: Uint8List.fromList(replacement.codeUnits),
        ),
      ]),
      onReplaced: (_, __) => replacementNotifications++,
    );

    await tester.tap(find.byTooltip('Acciones de Noticias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reemplazar M3U/M3U8'));
    await tester.pumpAndSettle();

    expect(replacementNotifications, 0);
    expect(await repository.loadPlaylist('news'), contains('Canal Nuevo'));
  });

}
