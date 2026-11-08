import 'dart:io';

import 'package:argentino_play/services/playlist_library_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late PlaylistLibraryRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('argentino-playlists-');
    repository =
        PlaylistLibraryRepository(directoryProvider: () async => directory);
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('creates, lists, loads and restores selection after reopening',
      () async {
    final first = await repository.createPlaylist(
      name: 'Noticias',
      source: '#EXTM3U\n#EXTINF:-1,Canal A\nhttps://example.org/a.m3u8\n',
      channelCount: 1,
      id: 'news',
    );
    final second = await repository.createPlaylist(
      name: 'Deportes',
      source: '#EXTM3U\n#EXTINF:-1,Canal B\nhttps://example.org/b.m3u8\n',
      channelCount: 1,
      id: 'sports',
    );

    expect(
      (await repository.listPlaylists()).map((item) => item.name),
      ['Deportes', 'Noticias'],
    );
    expect(await repository.loadPlaylist(first.id), contains('Canal A'));
    expect(await repository.loadPlaylist(second.id), contains('Canal B'));

    await repository.setActivePlaylistId(second.id);

    final reopened = PlaylistLibraryRepository(
      directoryProvider: () async => directory,
    );
    expect(await reopened.activePlaylistId(), second.id);
    expect(await reopened.loadPlaylist(second.id), contains('Canal B'));
    expect(await reopened.listPlaylists(), hasLength(2));
  });

  test('renames without changing source and rejects duplicate names', () async {
    final item = await repository.createPlaylist(
      name: 'Original',
      source: '#EXTM3U',
      channelCount: 1,
      id: 'original',
    );
    final renamed = await repository.renamePlaylist(item.id, '  Mi lista  ');
    expect(renamed.name, 'Mi lista');
    expect(await repository.loadPlaylist(item.id), '#EXTM3U');
    await expectLater(
      repository.createPlaylist(
        name: 'MI LISTA',
        source: '#EXTM3U',
        channelCount: 1,
        id: 'duplicate',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('deletes only selected playlist and clears active selection', () async {
    final keep = await repository.createPlaylist(
      name: 'Conservar',
      source: '#EXTM3U',
      channelCount: 1,
      id: 'keep',
    );
    final remove = await repository.createPlaylist(
      name: 'Eliminar',
      source: '#EXTM3U',
      channelCount: 1,
      id: 'remove',
    );
    await repository.setActivePlaylistId(remove.id);
    await repository.deletePlaylist(remove.id);

    expect(await repository.loadPlaylist(keep.id), '#EXTM3U');
    expect(await repository.loadPlaylist(remove.id), isNull);
    expect(await repository.activePlaylistId(), isNull);
  });

  test('rejects invalid names, zero channels and oversized content', () async {
    await expectLater(
      repository.createPlaylist(
        name: ' ',
        source: '#EXTM3U',
        channelCount: 1,
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      repository.createPlaylist(
        name: 'Vacía',
        source: '#EXTM3U',
        channelCount: 0,
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      repository.createPlaylist(
        name: 'Grande',
        source: List<String>.filled(5 * 1024 * 1024 + 1, 'x').join(),
        channelCount: 1,
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('does not activate unknown identifiers', () async {
    await expectLater(
      repository.setActivePlaylistId('missing'),
      throwsA(isA<FormatException>()),
    );
    expect(await repository.activePlaylistId(), isNull);
  });

  test('reports a damaged manifest instead of silently losing the library',
      () async {
    final index = File('${directory.path}/playlists/index.json');
    await index.parent.create(recursive: true);
    await index.writeAsString('{not-json');

    await expectLater(
      repository.listPlaylists(),
      throwsA(isA<FormatException>()),
    );
  });
}
