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

  /// Resolves the XMLTV channel id for a TV channel.
  ///
  /// Uses [tvgId] when the guide has that exact id. Otherwise falls back to
  /// comparing [channelName] with the normalized display-name of each guide
  /// channel, so playlists without tvg-id can still show programming.
  String? resolveChannelId({
    required String tvgId,
    required String channelName,
  }) {
    if (tvgId.isNotEmpty && channels.containsKey(tvgId)) {
      return tvgId;
    }
    final normalized = normalizeEpgName(channelName);
    if (normalized.isEmpty) {
      return null;
    }
    for (final channel in channels.values) {
      if (normalizeEpgName(channel.displayName) == normalized) {
        return channel.id;
      }
    }
    return null;
  }
}

/// Normalizes a channel name for guide fallback matching: case, accents,
/// punctuation and repeated spacing are folded away.
///
/// Handles common Latin-1 Supplement and Latin Extended-A characters used in
/// Spanish, Portuguese, French, German, and other European languages.
String normalizeEpgName(String value) {
  return value
      .toLowerCase()
      .replaceAll('ß', 'ss')
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ò', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ç', 'c')
      .replaceAll('ã', 'a')
      .replaceAll('õ', 'o')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
