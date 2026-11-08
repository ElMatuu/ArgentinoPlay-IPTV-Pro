import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Stores imported source files in the app-private support directory.
///
/// The source is parsed by the caller before saving. Each write uses a
/// temporary file and a backup so a failed replacement can restore the
/// previous library item.
class LocalLibraryRepository {
  LocalLibraryRepository({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const int maxPlaylistBytes = 5 * 1024 * 1024;
  static const int maxGuideBytes = 10 * 1024 * 1024;

  final Future<Directory> Function() _directoryProvider;

  Future<void> savePlaylist(String source) =>
      _write('playlist.m3u8', source, maxPlaylistBytes);

  Future<String?> loadPlaylist() => _read('playlist.m3u8', maxPlaylistBytes);

  Future<void> deletePlaylist() => _delete('playlist.m3u8');

  Future<void> saveGuide(String source) =>
      _write('guide.xml', source, maxGuideBytes);

  Future<String?> loadGuide() => _read('guide.xml', maxGuideBytes);

  Future<void> deleteGuide() => _delete('guide.xml');

  Future<File> _resolve(String name) async {
    final root = await _directoryProvider();
    final directory = Directory('${root.path}/library');
    await directory.create(recursive: true);
    return File('${directory.path}/$name');
  }

  Future<void> _write(String name, String source, int maxBytes) async {
    final bytes = utf8.encode(source);
    if (bytes.length > maxBytes) {
      throw const FileSystemException('Library item exceeds its size limit.');
    }

    final destination = await _resolve(name);
    final temporary = File('${destination.path}.tmp');
    final backup = File('${destination.path}.bak');

    await temporary.writeAsBytes(bytes, flush: true);
    final hadPrevious = await destination.exists();
    if (hadPrevious) {
      if (await backup.exists()) {
        await backup.delete();
      }
      await destination.rename(backup.path);
    }

    try {
      await temporary.rename(destination.path);
      if (await backup.exists()) {
        await backup.delete();
      }
    } catch (_) {
      if (hadPrevious && !await destination.exists() && await backup.exists()) {
        await backup.rename(destination.path);
      }
      rethrow;
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  Future<String?> _read(String name, int maxBytes) async {
    final file = await _resolve(name);
    if (!await file.exists()) {
      return null;
    }
    final length = await file.length();
    if (length > maxBytes) {
      throw const FileSystemException(
        'Stored library item exceeds its size limit.');
    }
    return file.readAsString(encoding: utf8);
  }

  Future<void> _delete(String name) async {
    final file = await _resolve(name);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
