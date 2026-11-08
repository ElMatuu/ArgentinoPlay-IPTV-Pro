import 'package:flutter_test/flutter_test.dart';
import 'package:argentino_play/services/xmltv_parser.dart';

void main() {
  group('parseXmltvTimestamp', () {
    test('normalizes a positive timezone offset to UTC', () {
      final timestamp = parseXmltvTimestamp('20260101120000 +0100');
      expect(timestamp, DateTime.utc(2026, 1, 1, 11));
    });

    test('supports timestamps without seconds or timezone', () {
      final timestamp = parseXmltvTimestamp('202601011230');
      expect(timestamp, DateTime.utc(2026, 1, 1, 12, 30));
    });

    test('rejects invalid dates and malformed values', () {
      expect(parseXmltvTimestamp('20260230120000 +0000'), isNull);
      expect(parseXmltvTimestamp('not-a-date'), isNull);
    });
  });

  test('parses XMLTV channels, programmes and categories', () {
    const xmltv = '<tv>'
        '<channel id="news.ar">'
        '<display-name>Noticias Argentina</display-name>'
        '<icon src="https://example.org/news.png"/>'
        '</channel>'
        '<programme start="20260101120000 +0100" '
        'stop="20260101130000 +0100" channel="news.ar">'
        '<title>Resumen del día</title>'
        '<desc>Noticias nacionales e internacionales.</desc>'
        '<category>News</category><category>Actualidad</category>'
        '</programme>'
        '</tv>';

    final guide = parseXmltv(xmltv);

    expect(guide.channels, hasLength(1));
    expect(guide.channels['news.ar']?.displayName, 'Noticias Argentina');
    expect(guide.channels['news.ar']?.icon, 'https://example.org/news.png');
    expect(guide.programmes, hasLength(1));
    expect(guide.programmes.single.start, DateTime.utc(2026, 1, 1, 11));
    expect(guide.programmes.single.end, DateTime.utc(2026, 1, 1, 12));
    expect(guide.programmes.single.categories, ['News', 'Actualidad']);
    expect(
      guide.programmeAt('news.ar', DateTime.utc(2026, 1, 1, 11, 30))?.title,
      'Resumen del día',
    );
  });

  test('ignores programmes with missing identifiers or invalid intervals', () {
    const xmltv = '<tv>'
        '<programme start="20260101130000 +0000" '
        'stop="20260101120000 +0000" channel="news.ar">'
        '<title>Intervalo inválido</title></programme>'
        '<programme start="20260101120000 +0000" '
        'stop="20260101130000 +0000">'
        '<title>Sin canal</title></programme>'
        '</tv>';

    expect(parseXmltv(xmltv).programmes, isEmpty);
  });
}
