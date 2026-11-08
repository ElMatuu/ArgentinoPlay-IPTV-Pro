import 'dart:convert';

import '../domain/tv_channel.dart';

/// Parses an M3U/M3U8 playlist and keeps only safe HTTP(S) stream URLs.
///
/// This parser does not verify ownership or retransmission rights. The caller
/// must ensure every imported source is authorized for the intended use.
List<TvChannel> parseM3u(String source) {
  final normalized = source.replaceFirst('\uFEFF', '');
  final lines = const LineSplitter().convert(normalized);
  final firstContentLine = lines
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');

  if (!firstContentLine.toUpperCase().startsWith('#EXTM3U')) {
    throw const FormatException(
      'El archivo no contiene una cabecera M3U válida.');
  }

  final channels = <TvChannel>[];
  String? pendingName;
  String pendingLogo = '';
  String pendingGroup = 'General';
  String pendingTvgId = '';
  String pendingCountry = '';
  String pendingLanguage = '';

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty || line.toUpperCase().startsWith('#EXTM3U')) {
      continue;
    }

    if (line.startsWith('#EXTINF:')) {
      final comma = _findTitleSeparator(line);
      final attributesPart = comma < 0 ? line : line.substring(0, comma);
      final title = comma < 0 ? '' : line.substring(comma + 1).trim();
      final attributes = _readAttributes(attributesPart);

      pendingName = title.isNotEmpty
          ? title
          : (attributes['tvg-name'] ?? 'Canal sin nombre').trim();
      pendingLogo = attributes['tvg-logo'] ?? '';
      pendingGroup = attributes['group-title'] ?? 'General';
      pendingTvgId = attributes['tvg-id'] ?? '';
      pendingCountry = attributes['tvg-country'] ?? '';
      pendingLanguage = attributes['tvg-language'] ?? '';
      continue;
    }

    if (line.startsWith('#EXTGRP:')) {
      pendingGroup = line.substring('#EXTGRP:'.length).trim();
      continue;
    }

    if (line.startsWith('#')) {
      continue;
    }

    final name = pendingName;
    if (name == null) {
      continue;
    }

    final uri = Uri.tryParse(line);
    if (_isAllowedStreamUri(uri)) {
      channels.add(
        TvChannel(
          name: name.isEmpty ? 'Canal sin nombre' : name,
          url: uri!.toString(),
          logo: pendingLogo,
          group: pendingGroup.isEmpty ? 'General' : pendingGroup,
          tvgId: pendingTvgId,
          country: pendingCountry,
          language: pendingLanguage,
        ),
      );
    }

    pendingName = null;
    pendingLogo = '';
    pendingGroup = 'General';
    pendingTvgId = '';
    pendingCountry = '';
    pendingLanguage = '';
  }

  return channels;
}

bool _isAllowedStreamUri(Uri? uri) {
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
    return false;
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return false;
  }
  if (uri.userInfo.isNotEmpty) {
    return false;
  }
  return true;
}

int _findTitleSeparator(String line) {
  var insideQuotes = false;
  for (var index = 0; index < line.length; index++) {
    final character = line[index];
    if (character == '"') {
      insideQuotes = !insideQuotes;
    } else if (character == ',' && !insideQuotes) {
      return index;
    }
  }
  return -1;
}

Map<String, String> _readAttributes(String line) {
  final attributes = <String, String>{};
  final pattern = RegExp(r'([\w-]+)\s*=\s*"([^"]*)"');
  for (final match in pattern.allMatches(line)) {
    final key = match.group(1);
    final value = match.group(2);
    if (key != null && value != null) {
      attributes[key.toLowerCase()] = value;
    }
  }
  return attributes;
}
