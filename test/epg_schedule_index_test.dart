import 'package:argentino_play/domain/epg.dart';
import 'package:argentino_play/services/epg_schedule_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2026, 1, 1, 10);

  group('EpgScheduleIndex', () {
    test('groups programmes by channel and sorts each schedule', () {
      final index = EpgScheduleIndex([
        EpgProgramme(
          channelId: 'news',
          title: 'Later',
          start: start.add(const Duration(hours: 2)),
          end: start.add(const Duration(hours: 3)),
        ),
        EpgProgramme(
          channelId: 'sports',
          title: 'Match',
          start: start,
          end: start.add(const Duration(hours: 1)),
        ),
        EpgProgramme(
          channelId: 'news',
          title: 'Earlier',
          start: start,
          end: start.add(const Duration(hours: 1)),
        ),
      ]);

      expect(index.programmesFor('news').map((item) => item.title),
          ['Earlier', 'Later']);
      expect(index.programmesFor('missing'), isEmpty);
      expect(index.programmesFor('sports').single.title, 'Match');
    });

    test('uses inclusive start and exclusive end boundaries', () {
      final programme = EpgProgramme(
        channelId: 'news',
        title: 'Bulletin',
        start: start,
        end: start.add(const Duration(hours: 1)),
      );
      final index = EpgScheduleIndex([programme]);

      expect(index.programmeAt('news', start), same(programme));
      expect(
        index.programmeAt('news', start.add(const Duration(minutes: 59))),
        same(programme),
      );
      expect(
        index.programmeAt('news', start.add(const Duration(hours: 1))),
        isNull,
      );
    });

    test('returns the most recently started programme when intervals overlap',
        () {
      final earlier = EpgProgramme(
        channelId: 'news',
        title: 'Long bulletin',
        start: start,
        end: start.add(const Duration(hours: 3)),
      );
      final later = EpgProgramme(
        channelId: 'news',
        title: 'Breaking news',
        start: start.add(const Duration(hours: 1)),
        end: start.add(const Duration(hours: 2)),
      );
      final index = EpgScheduleIndex([later, earlier]);

      expect(
        index.programmeAt('news', start.add(const Duration(minutes: 90)))?.title,
        'Breaking news',
      );
      expect(
        index.programmeAt('news', start.add(const Duration(hours: 2, minutes: 30)))?.title,
        'Long bulletin',
      );
    });

    test('does not return programmes from another channel', () {
      final index = EpgScheduleIndex([
        EpgProgramme(
          channelId: 'sports',
          title: 'Match',
          start: start,
          end: start.add(const Duration(hours: 1)),
        ),
      ]);

      expect(index.programmeAt('news', start.add(const Duration(minutes: 30))),
          isNull);
    });
  });
}
