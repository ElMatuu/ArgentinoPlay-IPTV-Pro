class EpgChannel {
  const EpgChannel({
    required this.id,
    required this.displayName,
    this.icon = '',
  });

  final String id;
  final String displayName;
  final String icon;
}

class EpgProgramme {
  const EpgProgramme({
    required this.channelId,
    required this.title,
    required this.start,
    required this.end,
    this.description = '',
    this.categories = const [],
  });

  final String channelId;
  final String title;
  final DateTime start;
  final DateTime end;
  final String description;
  final List<String> categories;

  bool isOnAirAt(DateTime instant) {
    final utcInstant = instant.toUtc();
    return !utcInstant.isBefore(start) && utcInstant.isBefore(end);
  }
}

class XmltvGuide {
  const XmltvGuide({
    required this.channels,
    required this.programmes,
  });

  final Map<String, EpgChannel> channels;
  final List<EpgProgramme> programmes;

  List<EpgProgramme> programmesFor(String channelId) {
    return programmes
        .where((programme) => programme.channelId == channelId)
        .toList(growable: false);
  }

  EpgProgramme? programmeAt(String channelId, DateTime instant) {
    for (final programme in programmes) {
      if (programme.channelId == channelId && programme.isOnAirAt(instant)) {
        return programme;
      }
    }
    return null;
  }
}
