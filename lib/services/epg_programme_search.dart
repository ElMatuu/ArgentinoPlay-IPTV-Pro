import '../domain/epg.dart';

/// Filters one channel's XMLTV schedule by programme text and category.
class EpgProgrammeSearch {
  const EpgProgrammeSearch._();

  static List<EpgProgramme> filter(
    Iterable<EpgProgramme> programmes, {
    String query = '',
    String category = '',
  }) {
    final normalizedQuery = _normalize(query);
    final normalizedCategory = _normalize(category);

    return programmes.where((programme) {
      if (normalizedCategory.isNotEmpty &&
          !programme.categories.any(
            (item) => _normalize(item) == normalizedCategory,
          )) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final searchableText = _normalize([
        programme.title,
        programme.description,
        ...programme.categories,
      ].join(' '));
      return searchableText.contains(normalizedQuery);
    }).toList(growable: false);
  }

  static List<String> categories(Iterable<EpgProgramme> programmes) {
    final values = <String, String>{};
    for (final programme in programmes) {
      for (final category in programme.categories) {
        final label = category.trim();
        if (label.isNotEmpty) {
          values.putIfAbsent(_normalize(label), () => label);
        }
      }
    }
    final result = values.values.toList()..sort();
    return List.unmodifiable(result);
  }
}

String _normalize(String value) {
  var normalized = value.toLowerCase();
  const replacements = <String, String>{
    'á': 'a', 'à': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u',
    'ñ': 'n',
  };
  replacements.forEach((source, replacement) {
    normalized = normalized.replaceAll(source, replacement);
  });
  return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
}
