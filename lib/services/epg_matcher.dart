import '../domain/epg.dart';
import '../domain/tv_channel.dart';

/// Matches a playlist channel to its XMLTV channel.
///
/// A non-empty [TvChannel.tvgId] is authoritative: if it does not exist in the
/// guide, name matching is not used as a potentially misleading fallback.
/// Name matching is used only when the playlist has no tvg-id and only when
/// the normalized display name is unique in the guide.
EpgChannel? matchEpgChannel(TvChannel channel, XmltvGuide guide) {
  final tvgId = channel.tvgId.trim();
  if (tvgId.isNotEmpty) {
    return guide.channels[tvgId];
  }

  final normalizedName = _normalizeChannelName(channel.name);
  if (normalizedName.isEmpty) {
    return null;
  }

  EpgChannel? match;
  for (final candidate in guide.channels.values) {
    if (_normalizeChannelName(candidate.displayName) != normalizedName) {
      continue;
    }
    if (match != null) {
      return null;
    }
    match = candidate;
  }
  return match;
}

/// Returns the current programme for [channel], if the guide has a safe match.
EpgProgramme? currentProgrammeForChannel(
  TvChannel channel,
  XmltvGuide guide, {
  required DateTime at,
}) {
  final match = matchEpgChannel(channel, guide);
  if (match == null) {
    return null;
  }
  return guide.programmeAt(match.id, at);
}

String _normalizeChannelName(String value) {
  var normalized = value.toLowerCase();
  const replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  replacements.forEach((source, replacement) {
    normalized = normalized.replaceAll(source, replacement);
  });
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\\s+'), ' ');
}
