import '../domain/tv_channel.dart';

/// Matches every search term against the channel's user-visible catalogue
/// metadata. Accents and repeated whitespace are normalized for forgiving
/// searches (for example, "espanol" matches "Español").
bool channelMatchesQuery(TvChannel channel, String query) {
  final terms = _normalize(query).split(' ').where((term) => term.isNotEmpty);
  if (terms.isEmpty) return true;

  final searchableText = _normalize([
    channel.name,
    channel.group,
    channel.country,
    channel.language,
    channel.tvgId,
  ].join(' '));

  return terms.every(searchableText.contains);
}

String _normalize(String value) {
  var normalized = value.toLowerCase();
  const replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };
  replacements.forEach((source, replacement) {
    normalized = normalized.replaceAll(source, replacement);
  });
  return normalized.replaceAll(RegExp(r'\\s+'), ' ').trim();
}
