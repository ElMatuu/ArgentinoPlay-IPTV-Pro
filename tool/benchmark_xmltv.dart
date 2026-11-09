import 'package:argentino_play/domain/tv_channel.dart';
import 'package:argentino_play/services/epg_matcher.dart';
import 'package:argentino_play/services/xmltv_parser.dart';

/// Reproducible, non-gating XMLTV benchmark.
///
/// Run with: dart run tool/benchmark_xmltv.dart
/// Timings are informational and should be compared on the same machine/runtime.
void main() {
  const channelCount = 2500;
  const playlistCount = 500;
  final xml = StringBuffer('<tv>');
  for (var i = 0; i < channelCount; i++) {
    xml
      ..write('<channel id="channel.$i">')
      ..write('<display-name>Canal de prueba $i</display-name>')
      ..write('</channel>');
  }
  for (var i = 0; i < channelCount; i++) {
    xml
      ..write('<programme start="20260101120000 +0000" ')
      ..write('stop="20260101130000 +0000" channel="channel.$i">')
      ..write('<title>Programa $i</title></programme>');
  }
  xml.write('</tv>');

  final parseWatch = Stopwatch()..start();
  final guide = parseXmltv(xml.toString());
  parseWatch.stop();

  final playlist = List<TvChannel>.generate(
    playlistCount,
    (i) => TvChannel(
      name: 'Canal de prueba ${i * 3}',
      url: 'https://example.invalid/${i * 3}.m3u8',
    ),
    growable: false,
  );

  final indexWatch = Stopwatch()..start();
  final matcher = EpgChannelMatcher(guide);
  indexWatch.stop();

  final reusedWatch = Stopwatch()..start();
  var reusedMatches = 0;
  for (final channel in playlist) {
    if (matcher.match(channel) != null) reusedMatches++;
  }
  reusedWatch.stop();

  final rebuiltWatch = Stopwatch()..start();
  var rebuiltMatches = 0;
  for (final channel in playlist) {
    if (matchEpgChannel(channel, guide) != null) rebuiltMatches++;
  }
  rebuiltWatch.stop();

  if (guide.channels.length != channelCount ||
      guide.programmes.length != channelCount ||
      reusedMatches != playlistCount ||
      rebuiltMatches != playlistCount) {
    throw StateError('Benchmark fixture or matcher produced unexpected results.');
  }

  print('XMLTV benchmark (informational; no timing threshold)');
  print('Guide: ${guide.channels.length} channels, '
      '${guide.programmes.length} programmes');
  print('Playlist: $playlistCount channels');
  print('XML bytes: ${xml.length}');
  print('Parse: ${parseWatch.elapsedMilliseconds} ms');
  print('Build reusable name index: ${indexWatch.elapsedMicroseconds} µs');
  print('Match with reused index: ${reusedWatch.elapsedMicroseconds} µs');
  print('Match rebuilding index per lookup: '
      '${rebuiltWatch.elapsedMilliseconds} ms');
}
