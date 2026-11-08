import 'package:argentino_play/domain/epg.dart';
import 'package:argentino_play/services/epg_programme_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final programmes = [
    EpgProgramme(
      channelId: 'news',
      title: 'Noticias de Córdoba',
      description: 'Resumen de actualidad nacional',
      start: DateTime.utc(2026, 1, 1, 10),
      end: DateTime.utc(2026, 1, 1, 11),
      categories: const ['Informativo', 'Actualidad'],
    ),
    EpgProgramme(
      channelId: 'news',
      title: 'Fútbol en vivo',
      description: 'Partido de primera división',
      start: DateTime.utc(2026, 1, 1, 11),
      end: DateTime.utc(2026, 1, 1, 13),
      categories: const ['Deportes'],
    ),
    EpgProgramme(
      channelId: 'news',
      title: 'Cocina fácil',
      description: 'Recetas para todos los días',
      start: DateTime.utc(2026, 1, 1, 13),
      end: DateTime.utc(2026, 1, 1, 14),
      categories: const ['Entretenimiento'],
    ),
  ];

  test('searches title, description and categories without case accents', () {
    expect(
      EpgProgrammeSearch.filter(programmes, query: 'CORDOBA')
          .map((item) => item.title),
      ['Noticias de Córdoba'],
    );
    expect(
      EpgProgrammeSearch.filter(programmes, query: 'primera division')
          .map((item) => item.title),
      ['Fútbol en vivo'],
    );
    expect(
      EpgProgrammeSearch.filter(programmes, query: 'INFORMATIVO')
          .map((item) => item.title),
      ['Noticias de Córdoba'],
    );
  });

  test('filters by category and combines category with text query', () {
    expect(
      EpgProgrammeSearch.filter(programmes, category: 'deportes')
          .map((item) => item.title),
      ['Fútbol en vivo'],
    );
    expect(
      EpgProgrammeSearch.filter(
        programmes,
        category: 'Informativo',
        query: 'actualidad',
      ).map((item) => item.title),
      ['Noticias de Córdoba'],
    );
  });

  test('empty query and category preserve the complete schedule', () {
    expect(EpgProgrammeSearch.filter(programmes), programmes);
    expect(EpgProgrammeSearch.filter(programmes, query: '   '), programmes);
  });

  test('lists unique non-empty categories', () {
    expect(
      EpgProgrammeSearch.categories([
        ...programmes,
        programmes.first.copyWith(),
      ]),
      ['Actualidad', 'Deportes', 'Entretenimiento', 'Informativo'],
    );
  });
}
