import 'package:flutter_test/flutter_test.dart';
import 'package:argentino_play/domain/sync_models.dart';

void main() {
  test('sync change survives a JSON round trip in UTC', () {
    final change = SyncChange(
      id: 'change-1',
      entityType: SyncEntityType.favorite,
      entityId: 'channel-1',
      operation: SyncOperation.upsert,
      deviceId: 'device-1',
      changedAt: DateTime.parse('2026-11-08T10:00:00-03:00'),
      payload: const {'channelId': 'channel-1', 'isFavorite': true},
      baseRevision: 4,
    );

    final decoded = SyncChange.fromJson(change.toJson());

    expect(decoded.id, change.id);
    expect(decoded.entityType, SyncEntityType.favorite);
    expect(decoded.operation, SyncOperation.upsert);
    expect(decoded.changedAt.isUtc, isTrue);
    expect(decoded.baseRevision, 4);
    expect(decoded.payload['isFavorite'], isTrue);
  });

  test('rejects unknown entity types and unsafe identifiers', () {
    final valid = <String, Object?>{
      'id': 'change-1',
      'entityType': 'unknown',
      'entityId': 'channel-1',
      'operation': 'upsert',
      'deviceId': 'device-1',
      'changedAt': '2026-11-08T10:00:00Z',
      'payload': <String, Object?>{},
      'baseRevision': null,
    };

    expect(
      () => SyncChange.fromJson(valid),
      throwsA(isA<FormatException>()),
    );

    valid['entityType'] = 'favorite';
    valid['entityId'] = '../private';
    expect(
      () => SyncChange.fromJson(valid),
      throwsA(isA<FormatException>()),
    );
  });

  test('cursor validates and normalizes its timestamp', () {
    final cursor = SyncCursor.fromJson({
      'value': 'opaque-server-cursor',
      'updatedAt': '2026-11-08T10:00:00-03:00',
    });

    expect(cursor.updatedAt.isUtc, isTrue);
    expect(
      () => SyncCursor.fromJson({
        'value': 'x' * 2049,
        'updatedAt': '2026-11-08T10:00:00Z',
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
