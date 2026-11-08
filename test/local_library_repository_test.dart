import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:argentino_play/services/local_library_repository.dart';

void main() {
  late Directory directory;
  late LocalLibraryRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('argentino-library-test-');
    repository = LocalLibraryRepository(directoryProvider: () async => directory);
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('persists playlist and guide source across repository instances', () async {
    const playlist = '#EXTM3U\n#EXTINF:-1,Demo\nhttps://example.org/live.m3u8\n';
    const guide = '<tv><channel id="demo"/></tv>';

    await repository.savePlaylist(playlist);
    await repository.saveGuide(guide);

    final reopened = LocalLibraryRepository(directoryProvider: () async => directory);
    expect(await reopened.loadPlaylist(), playlist);
    expect(await reopened.loadGuide(), guide);
  });

  test('returns null for library items that have not been imported', () async {
    expect(await repository.loadPlaylist(), isNull);
    expect(await repository.loadGuide(), isNull);
  });

  test('rejects oversized content without replacing an existing playlist', () async {
    const original = '#EXTM3U\n';
    await repository.savePlaylist(original);

    final oversized = 'x' * (LocalLibraryRepository.maxPlaylistBytes + 1);
    await expectLater(repository.savePlaylist(oversized), throwsA(isA<FileSystemException>()));
    expect(await repository.loadPlaylist(), original);
  });

  test('deletes stored playlist and guide independently', () async {
    await repository.savePlaylist('#EXTM3U\n');
    await repository.saveGuide('<tv/>');

    await repository.deletePlaylist();

    expect(await repository.loadPlaylist(), isNull);
    expect(await repository.loadGuide(), '<tv/>');
  });
}
