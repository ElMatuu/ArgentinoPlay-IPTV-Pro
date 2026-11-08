import 'package:argentino_play/domain/epg.dart';
import 'package:argentino_play/services/m3u_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseM3u', () {
    test('reads EXTINF attributes without quotes', () {
      const playlist = '#EXTM3U\n'
          '#EXTINF:-1 tvg-id=canal-a.ar tvg-logo=https://example.org/a.png '
          'group-title=Noticias,Canal A\n'
          'https://example.org/a.m3u8\n';
      final channels = parseM3u(playlist);
      expect(channels, hasLength(1));
      expect(channels.single.tvgId, 'canal-a.ar');
      expect(channels.single.logo, 'https://example.org/a.png');
      expect(channels.single.group, 'Noticias');
      expect(channels.single.name, 'Canal A');
    });

    test('reads single-quoted attributes and keeps quoted commas', () {
      const playlist = '#EXTM3U\n'
          "#EXTINF:-1 tvg-id='a' tvg-name='Canal, HD',Canal \"A, HD\"\n"
          'https://example.org/a.m3u8\n';
      final channels = parseM3u(playlist);
      expect(channels, hasLength(1));
      expect(channels.single.tvgId, 'a');
      expect(channels.single.name, 'Canal "A, HD"');
    });

    test('keeps ignoring unsupported schemes', () {
      const playlist = '#EXTM3U\n'
          '#EXTINF:-1,Local\n'
          'file:///etc/passwd\n'
          '#EXTINF:-1,Remote\n'
          'https://example.org/live.m3u8\n';
      final channels = parseM3u(playlist);
      expect(channels, hasLength(1));
      expect(channels.single.name, 'Remote');
    });
  });

  group('XmltvGuide.resolveChannelId', () {
    final guide = XmltvGuide(
      channels: {
        'canal-a.ar': const EpgChannel(
          id: 'canal-a.ar',
          displayName: 'Canal A',
        ),
        'radio-1': const EpgChannel(
          id: 'radio-1',
          displayName: 'Radio del Espectáculo!',
        ),
      },
      programmes: [
        EpgProgramme(
          channelId: 'canal-a.ar',
          title: 'Noticias',
          start: DateTime.utc(2026, 1, 1, 12),
          end: DateTime.utc(2026, 1, 1, 13),
        ),
      ],
    );

    test('returns the exact tvg-id when the guide has it', () {
      expect(
        guide.resolveChannelId(tvgId: 'canal-a.ar', channelName: 'Otro'),
        'canal-a.ar',
      );
    });

    test('falls back to the normalized display-name', () {
      expect(
        guide.resolveChannelId(tvgId: '', channelName: '  CANAL  a '),
        'canal-a.ar',
      );
      expect(
        guide.resolveChannelId(
          tvgId: 'missing',
          channelName: 'Radio del espectaculo',
        ),
        'radio-1',
      );
    });

    test('returns null when nothing matches', () {
      expect(
        guide.resolveChannelId(tvgId: 'missing', channelName: 'No existe'),
        isNull,
      );
    });

    test('programmeAt works with the resolved id', () {
      final id = guide.resolveChannelId(tvgId: '', channelName: 'Canal A');
      expect(id, 'canal-a.ar');
      final programme =
          guide.programmeAt(id!, DateTime.utc(2026, 1, 1, 12, 30));
      expect(programme?.title, 'Noticias');
    });
  });

  group('normalizeEpgName', () {
    test('folds case, spacing, punctuation and accents', () {
      expect(normalizeEpgName('  Canal   A!! '), 'canal a');
      expect(normalizeEpgName('Espectáculo ÁÉÍÓÚ'), 'espectaculo aeiou');
    });

    test('handles French accents', () {
      expect(normalizeEpgName('Café'), 'cafe');
      expect(normalizeEpgName('Hôtel'), 'hotel');
      expect(normalizeEpgName('Ça va'), 'ca va');
      expect(normalizeEpgName('Noël'), 'noel');
    });

    test('handles German umlauts', () {
      expect(normalizeEpgName('München'), 'munchen');
      expect(normalizeEpgName('Köln'), 'koln');
      expect(normalizeEpgName('Düsseldorf'), 'dusseldorf');
    });

    test('handles Portuguese accents', () {
      expect(normalizeEpgName('São Paulo'), 'sao paulo');
      expect(normalizeEpgName('Rio de Janeiro'), 'rio de janeiro');
    });

    test('handles uppercase accents', () {
      expect(normalizeEpgName('\u00c1\u00c9\u00cd\u00d3\u00d1'), 'aeion');
      expect(normalizeEpgName('\u00c0\u00c2\u00c4'), 'aaa');
    });

    test('handles German sharp s', () {
      expect(normalizeEpgName('Stra\u00dfe'), 'strasse');
      expect(normalizeEpgName('Wei\u00df'), 'weiss');
    });

    test('handles Portuguese tilde characters', () {
      expect(normalizeEpgName('S\u00e3o Paulo'), 'sao paulo');
      expect(normalizeEpgName('Jo\u00e3o'), 'joao');
      expect(normalizeEpgName('A\u00f5s'), 'aos');
    });
  });
}
