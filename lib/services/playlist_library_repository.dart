import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Metadata for one independently stored playlist.
class PlaylistRecord {
  const PlaylistRecord({
    required this.id,
    required this.name,
    required this.channelCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int channelCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PlaylistRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final count = json['channelCount'];
    final created = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final updated = DateTime.tryParse(json['updatedAt']?.toString() ?? '');
    if (id is! String ||
        !RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id) ||
        name is! String ||
        name.trim().isEmpty ||
        count is! int ||
        count < 0 ||
        created == null ||
        updated == null) {
      throw const FormatException('Invalid playlist metadata.');
    }
    return PlaylistRecord(
      id: id,
      name: name,
      channelCount: count,
      createdAt: created,
      updatedAt: updated,
    );
  }

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'channelCount': channelCount,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

/// Private, multi-playlist storage. Source files are kept separately from the
/// manifest so a large list does not need to be rewritten when metadata changes.
class PlaylistLibraryRepository {
  PlaylistLibraryRepository({Future<Directory> Function()? directoryProvider})
      : _directoryProvider =
            directoryProvider ?? getApplicationSupportDirectory;

  static const int maxPlaylistBytes = 5 * 1024 * 1024;
  final Future<Directory> Function() _directoryProvider;

  Future<Directory> _directory() async {
    final root = await _directoryProvider();
    final directory = Directory('${root.path}/playlists');
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> _manifest() async =>
      File('${(await _directory()).path}/index.json');

  Future<File> _sourceFile(String id) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id)) {
      throw ArgumentError.value(id, 'id', 'Invalid playlist identifier.');
    }
    return File('${(await _directory()).path}/playlist_$id.m3u8');
  }

  Future<List<PlaylistRecord>> listPlaylists() async {
    final file = await _manifest();
    if (!await file.exists()) return const [];
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      throw const FormatException('Playlist index is not a list.');
    }
    final records = decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid playlist index entry.');
          }
          return PlaylistRecord.fromJson(item);
        })
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return records;
  }

  Future<String?> loadPlaylist(String id) async {
    final records = await listPlaylists();
    if (!records.any((record) => record.id == id)) return null;
    final file = await _sourceFile(id);
    if (!await file.exists()) return null;
    if (await file.length() > maxPlaylistBytes) {
      throw const FileSystemException('Stored playlist exceeds its size limit.');
    }
    return file.readAsString(encoding: utf8);
  }

  Future<PlaylistRecord> createPlaylist({
    required String name,
    required String source,
    required int channelCount,
    String? id,
  }) async {
    final cleanName = name.trim();
    final bytes = utf8.encode(source);
    if (cleanName.isEmpty || cleanName.length > 80) {
      throw const FormatException('Playlist name must contain 1–80 characters.');
    }
    if (channelCount < 1) {
      throw const FormatException('Playlist must contain at least one channel.');
    }
    if (bytes.length > maxPlaylistBytes) {
      throw const FileSystemException('Playlist exceeds the 5 MB limit.');
    }
    final records = await listPlaylists();
    final normalized = cleanName.toLowerCase();
    if (records.any((record) => record.name.toLowerCase() == normalized)) {
      throw const FormatException('A playlist with that name already exists.');
    }
    final now = DateTime.now().toUtc();
    final newId = id ?? now.microsecondsSinceEpoch.toString();
    if (records.any((record) => record.id == newId)) {
      throw const FormatException('Playlist identifier already exists.');
    }
    final record = PlaylistRecord(
      id: newId,
      name: cleanName,
      channelCount: channelCount,
      createdAt: now,
      updatedAt: now,
    );
    await _atomicWrite(await _sourceFile(newId), bytes);
    try {
      await _writeManifest([...records, record]);
    } catch (_) {
      final sourceFile = await _sourceFile(newId);
      if (await sourceFile.exists()) await sourceFile.delete();
      rethrow;
    }
    return record;
  }

  Future<PlaylistRecord> renamePlaylist(String id, String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.length > 80) {
      throw const FormatException('Playlist name must contain 1–80 characters.');
    }
    final records = await listPlaylists();
    final index = records.indexWhere((record) => record.id == id);
    if (index < 0) throw const FormatException('Playlist not found.');
    if (records.any((record) =>
        record.id != id && record.name.toLowerCase() == cleanName.toLowerCase())) {
      throw const FormatException('A playlist with that name already exists.');
    }
    final old = records[index];
    final updated = PlaylistRecord(
      id: old.id,
      name: cleanName,
      channelCount: old.channelCount,
      createdAt: old.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    records[index] = updated;
    await _writeManifest(records);
    return updated;
  }

  Future<void> deletePlaylist(String id) async {
    final active = await activePlaylistId();
    final records = await listPlaylists();
    if (!records.any((record) => record.id == id)) return;
    await _writeManifest(records.where((record) => record.id != id).toList());
    final file = await _sourceFile(id);
    if (await file.exists()) await file.delete();
    if (active == id) await setActivePlaylistId(null);
  }

  Future<String?> activePlaylistId() async {
    final file = File('${(await _directory()).path}/active.txt');
    if (!await file.exists()) return null;
    final id = (await file.readAsString()).trim();
    if (id.isEmpty) return null;
    final records = await listPlaylists();
    return records.any((record) => record.id == id) ? id : null;
  }

  Future<void> setActivePlaylistId(String? id) async {
    if (id != null && !(await listPlaylists()).any((item) => item.id == id)) {
      throw const FormatException('Cannot activate an unknown playlist.');
    }
    final file = File('${(await _directory()).path}/active.txt');
    if (id == null) {
      if (await file.exists()) await file.delete();
    } else {
      await _atomicWrite(file, utf8.encode(id));
    }
  }

  Future<void> _writeManifest(List<PlaylistRecord> records) async {
    final content = jsonEncode(records.map((item) => item.toJson()).toList());
    await _atomicWrite(await _manifest(), utf8.encode(content));
  }

  Future<void> _atomicWrite(File destination, List<int> bytes) async {
    final temporary = File('${destination.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    try {
      await temporary.rename(destination.path);
    } on FileSystemException {
      if (await destination.exists()) await destination.delete();
      await temporary.rename(destination.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
