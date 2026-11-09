import 'package:argentino_play/services/device_registration_service.dart';
import 'package:flutter_test/flutter_test.dart';

const userA = '11111111-1111-4111-8111-111111111111';
const userB = '22222222-2222-4222-8222-222222222222';
const deviceA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const deviceB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

void main() {
  late _FakeGateway gateway;
  late _FakeIdStore idStore;
  late DateTime now;
  late List<String> generatedIds;
  late DeviceRegistrationService service;

  setUp(() {
    gateway = _FakeGateway();
    idStore = _FakeIdStore();
    now = DateTime.utc(2026, 11, 9, 12);
    generatedIds = [deviceA, deviceB];
    service = DeviceRegistrationService(
      gateway: gateway,
      idStore: idStore,
      clock: () => now,
      idGenerator: () => generatedIds.removeAt(0),
    );
  });

  test('registers one device and persists its id for that account', () async {
    final device = await service.registerCurrentDevice(
      userId: userA,
      label: 'Mi teléfono',
      platform: 'android',
      appVersion: '1.0.0+1',
    );

    expect(device.id, deviceA);
    expect(device.userId, userA);
    expect(device.label, 'Mi teléfono');
    expect(device.platform, 'android');
    expect(idStore.values[userA], deviceA);
    expect(gateway.rows, hasLength(1));
  });

  test('refreshes the existing active device instead of duplicating it',
      () async {
    await service.registerCurrentDevice(
      userId: userA,
      label: 'Teléfono',
      platform: 'android',
      appVersion: '1.0.0',
    );
    now = now.add(const Duration(hours: 2));

    final refreshed = await service.registerCurrentDevice(
      userId: userA,
      label: 'Mi Samsung',
      platform: 'android',
      appVersion: '1.1.0',
    );

    expect(refreshed.id, deviceA);
    expect(refreshed.label, 'Mi Samsung');
    expect(refreshed.appVersion, '1.1.0');
    expect(refreshed.lastSeenAt, now);
    expect(gateway.rows, hasLength(1));
  });

  test('creates a new id when the saved device was revoked', () async {
    await service.registerCurrentDevice(
      userId: userA,
      label: 'Teléfono',
      platform: 'android',
      appVersion: '1.0.0',
    );
    await service.revokeDevice(userId: userA, deviceId: deviceA);

    final replacement = await service.registerCurrentDevice(
      userId: userA,
      label: 'Teléfono',
      platform: 'android',
      appVersion: '1.0.1',
    );

    expect(replacement.id, deviceB);
    expect(replacement.revokedAt, isNull);
    expect(gateway.rows, hasLength(2));
    expect(gateway.rows[deviceA]!['revoked_at'], isNotNull);
  });

  test('keeps device ids separate when accounts change on one phone',
      () async {
    await service.registerCurrentDevice(
      userId: userA,
      label: 'Teléfono',
      platform: 'android',
      appVersion: '1.0.0',
    );
    final secondAccount = await service.registerCurrentDevice(
      userId: userB,
      label: 'Teléfono',
      platform: 'android',
      appVersion: '1.0.0',
    );

    expect(secondAccount.id, deviceB);
    expect(idStore.values[userA], deviceA);
    expect(idStore.values[userB], deviceB);
  });

  test('lists only the requested account devices', () async {
    await service.registerCurrentDevice(
      userId: userA,
      label: 'Teléfono',
      platform: 'android',
      appVersion: '1.0.0',
    );
    await service.registerCurrentDevice(
      userId: userB,
      label: 'Televisor',
      platform: 'android_tv',
      appVersion: '1.0.0',
    );

    final devices = await service.listDevices(userA);
    expect(devices, hasLength(1));
    expect(devices.single.userId, userA);
  });

  test('revoking current device clears only that account local id', () async {
    await service.registerCurrentDevice(
      userId: userA,
      label: 'Teléfono',
      platform: 'android',
      appVersion: '1.0.0',
    );

    await service.revokeDevice(userId: userA, deviceId: deviceA);

    expect(idStore.values.containsKey(userA), isFalse);
    expect(gateway.rows[deviceA]!['revoked_at'], isNotNull);
  });

  test('rejects invalid user ids and device metadata', () async {
    await expectLater(
      service.registerCurrentDevice(
        userId: 'not-a-uuid',
        label: 'Teléfono',
        platform: 'android',
        appVersion: '1.0.0',
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      service.registerCurrentDevice(
        userId: userA,
        label: ' ',
        platform: 'android',
        appVersion: '1.0.0',
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      service.registerCurrentDevice(
        userId: userA,
        label: 'Teléfono',
        platform: 'unknown',
        appVersion: '1.0.0',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects malformed remote device records', () {
    expect(
      () => RegisteredDevice.fromRow({'id': 'bad'}),
      throwsA(isA<FormatException>()),
    );
  });
}

class _FakeIdStore implements DeviceIdStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String userId) async => values[userId];

  @override
  Future<void> write(String userId, String deviceId) async {
    values[userId] = deviceId;
  }

  @override
  Future<void> remove(String userId) async {
    values.remove(userId);
  }
}

class _FakeGateway implements DeviceRegistryGateway {
  final Map<String, Map<String, dynamic>> rows = {};

  @override
  Future<Map<String, dynamic>?> findDevice(String id) async {
    final row = rows[id];
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<void> insertDevice(Map<String, Object?> row) async {
    final id = row['id']! as String;
    if (rows.containsKey(id)) {
      throw StateError('Duplicate device id.');
    }
    rows[id] = {
      ...row,
      'created_at': row['created_at'],
      'last_seen_at': row['last_seen_at'],
      'revoked_at': null,
    };
  }

  @override
  Future<void> updateDevice(String id, Map<String, Object?> values) async {
    final row = rows[id];
    if (row == null) throw StateError('Device not found.');
    row.addAll(values);
  }

  @override
  Future<List<Map<String, dynamic>>> listDevices(String userId) async {
    return rows.values
        .where((row) => row['user_id'] == userId)
        .map(Map<String, dynamic>.from)
        .toList();
  }

  @override
  Future<void> revokeDevice({
    required String userId,
    required String deviceId,
    required DateTime revokedAt,
  }) async {
    final row = rows[deviceId];
    if (row != null && row['user_id'] == userId && row['revoked_at'] == null) {
      row['revoked_at'] = revokedAt.toIso8601String();
    }
  }
}
