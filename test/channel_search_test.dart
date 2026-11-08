import 'package:argentino_play/domain/tv_channel.dart';
import 'package:argentino_play/services/channel_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = TvChannel(
    name: 'Noticias del Día',
    url: 'https://example.org/live.m3u8',
    group: 'Información',
    tvgId: 'noticias.ar',
    country: 'Argentina',
    language: 'Español',
  );

  group('channelMatchesQuery', () {
    test('matches channel names and categories', () {
      expect(channelMatchesQuery(channel, 'noticias'), isTrue);
      expect(channelMatchesQuery(channel, 'informacion'), isTrue);
    });

    test('matches country, language and EPG identifier', () {
      expect(channelMatchesQuery(channel, 'argentina'), isTrue);
      expect(channelMatchesQuery(channel, 'espanol'), isTrue);
      expect(channelMatchesQuery(channel, 'noticias.ar'), isTrue);
    });

    test('normalizes accents and case', () {
      expect(channelMatchesQuery(channel, 'DIA'), isTrue);
      expect(channelMatchesQuery(channel, 'INFORMACIÓN'), isTrue);
    });

    test('requires all search terms to match catalogue metadata', () {
      expect(channelMatchesQuery(channel, 'argentina espanol'), isTrue);
      expect(channelMatchesQuery(channel, 'argentina deportes'), isFalse);
    });

    test('treats an empty or whitespace-only query as a match', () {
      expect(channelMatchesQuery(channel, ''), isTrue);
      expect(channelMatchesQuery(channel, '   '), isTrue);
    });
  });
}
