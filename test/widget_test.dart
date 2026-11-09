import 'package:argentino_play/main.dart';
import 'package:argentino_play/services/local_library_repository.dart';
import 'package:argentino_play/services/playlist_library_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyPlaylistRepository extends PlaylistLibraryRepository {
  @override
  Future<List<PlaylistRecord>> listPlaylists() async => [];

  @override
  Future<String?> activePlaylistId() async => null;
}

class _EmptyLibraryRepository extends LocalLibraryRepository {
  @override
  Future<String?> loadPlaylist() async => null;

  @override
  Future<String?> loadGuide() async => null;
}

Future<void> _pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ArgentinoPlayApp(
      libraryRepository: _EmptyLibraryRepository(),
      playlistRepository: _EmptyPlaylistRepository(),
    ),
  );

  // Avoid pumpAndSettle because indeterminate progress indicators can keep
  // scheduling frames while the app is loading.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

void main() {
  test('M3U parser reads valid HTTP channels and metadata', () {
    const playlist =
        '#EXTM3U\n#EXTINF:-1 tvg-logo="https://example.org/logo.png" '
        'group-title="Noticias",Canal Demo\n'
        'https://example.org/live.m3u8\n';
    final channels = parseM3u(playlist);

    expect(channels, hasLength(1));
    expect(channels.single.name, 'Canal Demo');
    expect(channels.single.group, 'Noticias');
    expect(channels.single.logo, 'https://example.org/logo.png');
  });

  test('M3U parser ignores unsupported schemes and malformed entries', () {
    const playlist = '#EXTM3U\n#EXTINF:-1,No válido\nfile:///etc/passwd\n'
        '#EXTINF:-1,Válido\nhttps://example.org/live.m3u8\n';
    final channels = parseM3u(playlist);

    expect(channels, hasLength(1));
    expect(channels.single.name, 'Válido');
  });

  testWidgets('home screen shows playlist import empty state', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Tu catálogo empieza acá'), findsOneWidget);
    expect(find.text('Importar lista'), findsOneWidget);
  });

  testWidgets('selecting Favorites destination shows its empty state',
      (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Favoritos').last);
    await tester.pump();

    expect(find.text('Todavía no hay favoritos'), findsOneWidget);
  });
}
