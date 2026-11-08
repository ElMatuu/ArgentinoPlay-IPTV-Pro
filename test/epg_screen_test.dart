import 'package:argentino_play/domain/epg.dart';
import 'package:argentino_play/domain/tv_channel.dart';
import 'package:argentino_play/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EPG screen resolves a channel without tvg-id by unique name',
      (tester) async {
    final now = DateTime.now().toUtc();
    final guide = XmltvGuide(
      channels: const {
        'news.ar': EpgChannel(
          id: 'news.ar',
          displayName: 'Noticias Argentina',
        ),
      },
      programmes: [
        EpgProgramme(
          channelId: 'news.ar',
          title: 'Resumen informativo',
          start: now.subtract(const Duration(minutes: 30)),
          end: now.add(const Duration(minutes: 30)),
        ),
      ],
    );
    const channel = TvChannel(
      name: 'NOTICIAS Argentina',
      url: 'https://example.org/live.m3u8',
    );

    await tester.pumpWidget(
      MaterialApp(home: EpgScreen(channel: channel, guide: guide)),
    );

    expect(find.text('Resumen informativo'), findsOneWidget);
    expect(find.text('No hay programas disponibles para este canal.'),
        findsNothing);
  });
}
