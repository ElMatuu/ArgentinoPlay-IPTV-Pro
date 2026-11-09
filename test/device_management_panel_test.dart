import 'package:argentino_play/services/device_management_panel.dart';
import 'package:argentino_play/services/device_registration_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = '11111111-1111-4111-8111-111111111111';
const _phone = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _tv = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

void main() {
  testWidgets(
    'shows current and other devices and allows revoking the other one',
    (tester) async {
      final gateway = _PanelGateway()
        ..rows[_phone] = _row(_phone, 'Este dispositivo', 'android')
        ..rows[_tv] = _row(_tv, 'Living TV', 'android_tv');
      final store = _PanelIdStore()..values[_user] = _phone;
      final service = DeviceRegistrationService(
        gateway: gateway,
        idStore: store,
        clock: () => DateTime.utc(2026, 11, 9, 12),
        idGenerator: () => 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceManagementPanel(userId: _user, service: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mis dispositivos'), findsOneWidget);
      expect(find.text('Este equipo'), findsOneWidget);
      expect(find.text('Living TV'), findsOneWidget);
      expect(find.byTooltip('Revocar dispositivo'), findsOneWidget);

      await tester.tap(find.byTooltip('Revocar dispositivo'));
      await tester.pumpAndSettle();
      expect(find.text('Revocar dispositivo'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Revocar'));
      await tester.pumpAndSettle();

      expect(gateway.rows[_tv]!['revoked_at'], isNotNull);
      expect(find.text('Revocado'), findsOneWidget);
      expect(gateway.rows[_phone]!['revoked_at'], isNull);
    },
  );
}

Map<String, dynamic> _row(String id, String label, String platform) => {
  'id': id,
  'user_id': _user,
  'device_label': label,
  'platform': platform,
  'app_version': '1.0.0+1',
  'created_at': '2026-11-08T12:00:00.000Z',
  'last_seen_at': '2026-11-09T12:00:00.000Z',
  'revoked_at': null,
};

class _PanelIdStore implements DeviceIdStore {
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

class _PanelGateway implements DeviceRegistryGateway {
  final Map<String, Map<String, dynamic>> rows = {};

  @override
  Future<Map<String, dynamic>?> findDevice(String id) async {
    final row = rows[id];
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<void> insertDevice(Map<String, Object?> row) async {
    final id = row['id']! as String;
    rows[id] = {...row, 'revoked_at': null};
  }

  @override
  Future<void> updateDevice(String id, Map<String, Object?> values) async {
    rows[id]!.addAll(values);
  }

  @override
  Future<List<Map<String, dynamic>>> listDevices(String userId) async => rows
      .values
      .where((row) => row['user_id'] == userId)
      .map(Map<String, dynamic>.from)
      .toList();

  @override
  Future<void> revokeDevice({
    required String userId,
    required String deviceId,
    required DateTime revokedAt,
  }) async {
    final row = rows[deviceId];
    if (row != null && row['user_id'] == userId) {
      row['revoked_at'] = revokedAt.toIso8601String();
    }
  }
}
