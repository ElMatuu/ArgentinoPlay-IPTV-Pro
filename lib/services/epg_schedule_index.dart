import '../domain/epg.dart';

/// Builds a per-channel schedule so programme lookups do not scan the entire
/// XMLTV programme list for every visible channel.
class EpgScheduleIndex {
  EpgScheduleIndex(Iterable<EpgProgramme> programmes) {
    final grouped = <String, List<EpgProgramme>>{};
    for (final programme in programmes) {
      grouped.putIfAbsent(programme.channelId, () => []).add(programme);
    }

    _programmesByChannel = Map.unmodifiable({
      for (final entry in grouped.entries)
        entry.key: List<EpgProgramme>.unmodifiable(
          entry.value..sort(_compareProgrammes),
        ),
    });
  }

  late final Map<String, List<EpgProgramme>> _programmesByChannel;

  /// Returns a channel's programmes in chronological order.
  List<EpgProgramme> programmesFor(String channelId) {
    return _programmesByChannel[channelId] ?? const [];
  }

  /// Finds the latest-starting programme active at [instant] using binary
  /// search. If schedules overlap, the programme that started most recently
  /// wins; expired entries are skipped while walking backwards.
  EpgProgramme? programmeAt(String channelId, DateTime instant) {
    final schedule = _programmesByChannel[channelId];
    if (schedule == null || schedule.isEmpty) return null;

    final target = instant.toUtc();
    var low = 0;
    var high = schedule.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (!schedule[middle].start.toUtc().isAfter(target)) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    for (var index = low - 1; index >= 0; index--) {
      final programme = schedule[index];
      if (programme.isOnAirAt(target)) return programme;
    }
    return null;
  }
}

int _compareProgrammes(EpgProgramme left, EpgProgramme right) {
  final byStart = left.start.compareTo(right.start);
  if (byStart != 0) return byStart;
  return left.end.compareTo(right.end);
}
