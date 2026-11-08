import 'package:xml/xml.dart';

import '../domain/epg.dart';

/// Parses XMLTV data. Timestamps without an explicit offset are interpreted
/// as UTC to keep schedule comparisons deterministic across devices.
XmltvGuide parseXmltv(String source) {
  final document = XmlDocument.parse(source);
  final channels = <String, EpgChannel>{};
  final programmes = <EpgProgramme>[];

  for (final element in document.findAllElements('channel')) {
    final id = element.getAttribute('id')?.trim() ?? '';
    if (id.isEmpty) {
      continue;
    }
    final displayName = _firstText(element, 'display-name') ?? id;
    final icons = element.findElements('icon');
    final icon = icons.isEmpty ? '' : (icons.first.getAttribute('src') ?? '');
    channels[id] = EpgChannel(id: id, displayName: displayName, icon: icon);
  }

  for (final element in document.findAllElements('programme')) {
    final channelId = element.getAttribute('channel')?.trim() ?? '';
    final title = _firstText(element, 'title') ?? '';
    final start = parseXmltvTimestamp(element.getAttribute('start') ?? '');
    final end = parseXmltvTimestamp(element.getAttribute('stop') ?? '');
    if (channelId.isEmpty ||
        title.isEmpty ||
        start == null ||
        end == null ||
        !end.isAfter(start)) {
      continue;
    }

    final description = _firstText(element, 'desc') ?? '';
    final categories = element
        .findElements('category')
        .map((category) => category.innerText.trim())
        .where((category) => category.isNotEmpty)
        .toList(growable: false);

    programmes.add(
      EpgProgramme(
        channelId: channelId,
        title: title,
        start: start,
        end: end,
        description: description,
        categories: categories,
      ),
    );
  }

  programmes.sort((a, b) => a.start.compareTo(b.start));
  return XmltvGuide(channels: channels, programmes: programmes);
}

DateTime? parseXmltvTimestamp(String value) {
  final match = RegExp(
    r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})?'
    r'(?:\s*([+-])(\d{2})(\d{2}))?$',
  ).firstMatch(value.trim());
  if (match == null) {
    return null;
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6) ?? '0');

  try {
    var timestamp = DateTime.utc(year, month, day, hour, minute, second);
    if (timestamp.year != year ||
        timestamp.month != month ||
        timestamp.day != day ||
        timestamp.hour != hour ||
        timestamp.minute != minute ||
        timestamp.second != second) {
      return null;
    }

    final sign = match.group(7);
    if (sign != null) {
      final offsetHours = int.parse(match.group(8)!);
      final offsetMinutes = int.parse(match.group(9)!);
      if (offsetHours > 23 || offsetMinutes > 59) {
        return null;
      }
      final offset = Duration(hours: offsetHours, minutes: offsetMinutes);
      timestamp = sign == '+' ? timestamp.subtract(offset) : timestamp.add(offset);
    }
    return timestamp;
  } on ArgumentError {
    return null;
  }
}

String? _firstText(XmlElement element, String childName) {
  for (final child in element.findElements(childName)) {
    final value = child.innerText.trim();
    if (value.isNotEmpty) {
      return value;
    }
  }
  return null;
}
