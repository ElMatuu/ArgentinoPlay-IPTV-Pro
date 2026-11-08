import 'package:flutter_test/flutter_test.dart';
import 'package:argentino_play/domain/epg.dart';
import 'package:argentino_play/domain/tv_channel.dart';
import 'package:argentino_play/services/epg_matcher.dart';

void main() {
  final guide = XmltvGuide(
    channels: {
      'news.ar': const EpgChannel(
        id: 'news.ar',
        displayName: 'Noticias Árgentina',
      ),
      'sports.ar': const EpgChannel(
        id: 'sports.ar',
        displayName: 'Deportes',
      ),
      'news.backup': const EpgChannel(
        id: 'news.backup',
        displayName: 'Noticias Argentina',
      ),
    },
    programmes: [
      EpgProgramme(
        channelId: 'news.ar',
        title: 'Resumen',
        start: DateTime.utc(2026, 1, 1, 10),
        end: DateTime.utc(2026, 1, 1, 11),
      ),
    ],
  );

  group('matchEpgChannel', () {
    test('uses an exact tvg-id before display-name matching', () {
      const channel = TvChannel(
        name: 'Otro nombre',
        url: 'https://example.org/live.m3u8',
        tvgId: 'news.ar',
      );

      expect(matchEpgChannel(channel, guide)?.id, 'news.ar');
    });

    test('does not fall back to name when an explicit tvg-id is unknown', () {
      const channel = TvChannel(
        name: 'Noticias Argentina',
        url: 'https://example.org/live.m3u8',
        tvgId: 'unknown.id',
      );

      expect(matchEpgChannel(channel, guide), isNull);
    });

    test('normalizes accents and punctuation for unique name matches', () {
      const uniqueGuide = XmltvGuide(
        channels: {
          'news.ar': EpgChannel(
            id: 'news.ar',
            displayName: 'Noticias Árgentina HD',
          ),
        },
        programmes: [],
      );
      const channel = TvChannel(
        name: '  NOTICIAS Argentina - HD ',
        url: 'https://example.org/live.m3u8',
      );

      expect(matchEpgChannel(channel, uniqueGuide)?.id, 'news.ar');
    });

    test('rejects ambiguous display-name matches', () {
      const channel = TvChannel(
        name: 'Noticias Argentina',
        url: 'https://example.org/live.m3u8',
      );

      expect(matchEpgChannel(channel, guide), isNull);
    });

    test('returns null for an empty channel name', () {
      const channel = TvChannel(
        name: '',
        url: 'https://example.org/live.m3u8',
      );

      expect(matchEpgChannel(channel, guide), isNull);
    });
  });

  test('currentProgrammeForChannel returns the programme at the instant', () {
    final uniqueGuide = XmltvGuide(
      channels: {
        'news.ar': const EpgChannel(
          id: 'news.ar',
          displayName: 'Noticias',
        ),
      },
      programmes: [
        EpgProgramme(
          channelId: 'news.ar',
          title: 'Resumen',
          start: DateTime.utc(2026, 1, 1, 10),
          end: DateTime.utc(2026, 1, 1, 11),
        ),
      ],
    );
    const channel = TvChannel(
      name: 'Noticias',
      url: 'https://example.org/live.m3u8',
    );

    expect(
      currentProgrammeForChannel(
        channel,
        uniqueGuide,
        at: DateTime.utc(2026, 1, 1, 10, 30),
      )?.title,
      'Resumen',
    );
  });
}
