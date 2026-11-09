import 'package:flutter_test/flutter_test.dart';
import 'package:argentino_play/services/m3u_parser.dart';

void main() {
  group('parseM3u', () {
    test('reads channel metadata and a quoted comma in attributes', () {
      const playlist = '#EXTM3U\n'
          '#EXTINF:-1 tvg-id="news.ar" tvg-name="Noticias" '
          'tvg-logo="https://example.org/logo.png" '
          'group-title="Noticias, Argentina" tvg-country="AR" '
          'tvg-language="es",Canal Demo\n'
          'https://example.org/live.m3u8\n';

      final channels = parseM3u(playlist);

      expect(channels, hasLength(1));
      expect(channels.single.name, 'Canal Demo');
      expect(channels.single.group, 'Noticias, Argentina');
      expect(channels.single.logo, 'https://example.org/logo.png');
      expect(channels.single.tvgId, 'news.ar');
      expect(channels.single.country, 'AR');
      expect(channels.single.language, 'es');
    });

    test('rejects a malformed header that only starts with EXT M3U text', () {
      expect(
        () => parseM3u('#EXTM3U_INVALID\n'
            '#EXTINF:-1,Canal\n'
            'https://example.org/live.m3u8'),
        throwsFormatException,
      );
    });

    test('supports UTF-8 BOM and CRLF line endings', () {
      const playlist = '\uFEFF#EXTM3U\r\n'
          '#EXTINF:-1,Canal Demo\r\n'
          'https://example.org/live.m3u8\r\n';

      expect(parseM3u(playlist).single.name, 'Canal Demo');
    });

    test('rejects a playlist without an M3U header', () {
      expect(
        () => parseM3u('#EXTINF:-1,Canal\nhttps://example.org/live.m3u8'),
        throwsFormatException,
      );
    });

    test('ignores unsupported schemes and URLs with embedded credentials', () {
      const playlist = '#EXTM3U\n'
          '#EXTINF:-1,Local file\n'
          'file:///etc/passwd\n'
          '#EXTINF:-1,Credential URL\n'
          'https://user:password@example.org/live.m3u8\n'
          '#EXTINF:-1,Valid channel\n'
          'https://example.org/live.m3u8\n';

      final channels = parseM3u(playlist);

      expect(channels, hasLength(1));
      expect(channels.single.name, 'Valid channel');
    });

    test('supports EXTGRP metadata', () {
      const playlist = '#EXTM3U\n'
          '#EXTINF:-1,Canal Demo\n'
          '#EXTGRP:Deportes\n'
          'https://example.org/live.m3u8\n';

      expect(parseM3u(playlist).single.group, 'Deportes');
    });

    test('ignores entries without a stream URL', () {
      const playlist = '#EXTM3U\n'
          '#EXTINF:-1,Canal sin URL\n'
          '#EXTINF:-1,Canal válido\n'
          'https://example.org/live.m3u8\n';

      final channels = parseM3u(playlist);

      expect(channels, hasLength(1));
      expect(channels.single.name, 'Canal válido');
    });

    test('reports entries without a stream URL, including a trailing entry', () {
      const playlist = '#EXTM3U\\n'
          '#EXTINF:-1,Missing before next entry\\n'
          '#EXTINF:-1,Valid channel\\n'
          'https://example.org/live.m3u8\\n'
          '#EXTINF:-1,Missing at end\\n';

      final report = parseM3uWithReport(playlist);

      expect(report.channels, hasLength(1));
      expect(report.missingStreamUrlCount, 2);
      expect(report.rejectedStreamUrlCount, 0);
      expect(report.rejectedEntries, 2);
    });

    test('reports unsupported and credential-bearing stream URLs', () {
      const playlist = '#EXTM3U\\n'
          '#EXTINF:-1,Local file\\n'
          'file:///etc/passwd\\n'
          '#EXTINF:-1,Credential URL\\n'
          'https://user:password@example.org/live.m3u8\\n'
          '#EXTINF:-1,Valid channel\\n'
          'https://example.org/live.m3u8\\n';

      final report = parseM3uWithReport(playlist);

      expect(report.channels, hasLength(1));
      expect(report.missingStreamUrlCount, 0);
      expect(report.rejectedStreamUrlCount, 2);
      expect(report.rejectedEntries, 2);
    });

    test('keeps parseM3u compatible with the report API', () {
      const playlist = '#EXTM3U\\n'
          '#EXTINF:-1,Canal\\n'
          'https://example.org/live.m3u8\\n';

      expect(parseM3u(playlist), parseM3uWithReport(playlist).channels);
    });
  });
}
