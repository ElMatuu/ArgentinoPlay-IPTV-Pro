import '../domain/epg.dart';
import '../domain/tv_channel.dart';

/// Builds a reusable, constant-time matcher for playlist channels.
///
/// Explicit tvg-id values are authoritative. Name matching is used only when
/// the playlist has no tvg-id and the normalized name is unique in the guide.
class EpgChannelMatcher {
  EpgChannelMatcher(XmltvGuide guide)
      : _channelsById = guide.channels,
        _channelsByNormalizedName = _buildNameIndex(guide);

  final Map<String, EpgChannel> _channelsById;
  final Map<String, EpgChannel?> _channelsByNormalizedName;

  EpgChannel? match(TvChannel channel) {
    final tvgId = channel.tvgId.trim();
    if (tvgId.isNotEmpty) {
      return _channelsById[tvgId];
    }

    final normalizedName = _normalizeChannelName(channel.name);
    if (normalizedName.isEmpty) {
      return null;
    }
    return _channelsByNormalizedName[normalizedName];
  }

  static Map<String, EpgChannel?> _buildNameIndex(XmltvGuide guide) {
    final index = <String, EpgChannel?>{};
    for (final candidate in guide.channels.values) {
      final name = _normalizeChannelName(candidate.displayName);
      if (name.isEmpty) continue;

      if (index.containsKey(name)) {
        // A null value records an ambiguous name and prevents unsafe matches.
        index[name] = null;
      } else {
        index[name] = candidate;
      }
    }
    return index;
  }
}

/// Convenience API for callers that only need a single match.
///
/// Screens rendering many channels should retain an [EpgChannelMatcher]
/// instance instead of rebuilding the index for every channel.
EpgChannel? matchEpgChannel(TvChannel channel, XmltvGuide guide) {
  return EpgChannelMatcher(guide).match(channel);
}

/// Returns the current programme for [channel], if the guide has a safe match.
EpgProgramme? currentProgrammeForChannel(
  TvChannel channel,
  XmltvGuide guide, {
  required DateTime at,
}) {
  final match = EpgChannelMatcher(guide).match(channel);
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
      .replaceAll(RegExp(r'\s+'), ' ');
}
