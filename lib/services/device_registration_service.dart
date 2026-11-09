import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A device registered to one authenticated cloud account.
class RegisteredDevice {
  const RegisteredDevice({
    required this.id,
    required this.userId,
    required this.label,
    required this.platform,
    required this.appVersion,
    required this.createdAt,
    required this.lastSeenAt,
    this.revokedAt,
  });

  final String id;
  final String userId;
  final String label;
  final String platform;
  final String appVersion;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final DateTime? revokedAt;

  factory RegisteredDevice.fromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final userId = row['user_id'];
    final label = row['device_label'];
    final platform = row['platform'];
    final appVersion = row['app_version'];
    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
    final lastSeenAt = DateTime.tryParse(
      row['last_seen_at']?.toString() ?? '',
    );
    final revokedAtValue = row['revoked_at'];
    final revokedAt = revokedAtValue == null
        ? null
        : DateTime.tryParse(revokedAtValue.toString());

    if (id is! String ||
        !_isUuid(id) ||
        userId is! String ||
        !_isUuid(userId) ||
        label is! String ||
        label.isEmpty ||
        platform is! String ||
        !_supportedPlatforms.contains(platform) ||
        appVersion is! String ||
        createdAt == null ||
        lastSeenAt == null ||
        (revokedAtValue != null && revokedAt == null)) {
      throw const FormatException('Invalid registered device record.');
    }

    return RegisteredDevice(
      id: id,
      userId: userId,
      label: label,
      platform: platform,
      appVersion: appVersion,
      createdAt: createdAt.toUtc(),
      lastSeenAt: lastSeenAt.toUtc(),
      revokedAt: revokedAt?.toUtc(),
    );
  }
}

const Set<String> _supportedPlatforms = {
  'android',
  'android_tv',
  'ios',
  'windows',
  'macos',
  'web',
  'other',
};

bool _isUuid(String value) => RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);

/// Abstraction makes device lifecycle behavior testable without network access.
abstract interface class DeviceRegistryGateway {
  Future<Map<String, dynamic>?> findDevice(String id);

  Future<void> insertDevice(Map<String, Object?> row);

  Future<void> updateDevice(String id, Map<String, Object?> values);

  Future<List<Map<String, dynamic>>> listDevices(String userId);

  Future<void> revokeDevice({
    required String userId,
    required String deviceId,
    required DateTime revokedAt,
  });
}

/// Supabase implementation. RLS remains the authority for account ownership.
class SupabaseDeviceRegistryGateway implements DeviceRegistryGateway {
  SupabaseDeviceRegistryGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> findDevice(String id) async {
    return _client.from('devices').select().eq('id', id).maybeSingle();
  }

  @override
  Future<void> insertDevice(Map<String, Object?> row) async {
    await _client.from('devices').insert(row);
  }

  @override
  Future<void> updateDevice(String id, Map<String, Object?> values) async {
    await _client.from('devices').update(values).eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> listDevices(String userId) async {
    return _client
        .from('devices')
        .select()
        .eq('user_id', userId)
        .order('last_seen_at', ascending: false);
  }

  @override
  Future<void> revokeDevice({
    required String userId,
    required String deviceId,
    required DateTime revokedAt,
  }) async {
    await _client
        .from('devices')
        .update({'revoked_at': revokedAt.toUtc().toIso8601String()})
        .eq('user_id', userId)
        .eq('id', deviceId)
        .isFilter('revoked_at', null);
  }
}

/// Per-account local storage for the current device identifier.
abstract interface class DeviceIdStore {
  Future<String?> read(String userId);

  Future<void> write(String userId, String deviceId);

  Future<void> remove(String userId);
}

/// Uses the existing Supabase Flutter client's SharedPreferences dependency.
class PreferencesDeviceIdStore implements DeviceIdStore {
  static const String _prefix = 'cloud_device_id_';

  @override
  Future<String?> read(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('$_prefix$userId');
  }

  @override
  Future<void> write(String userId, String deviceId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('$_prefix$userId', deviceId);
  }

  @override
  Future<void> remove(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_prefix$userId');
  }
}

/// Registers, refreshes, lists and revokes devices for the signed-in user.
///
/// The device identifier is stored per account, so signing into another
/// account on the same phone never reuses the previous account's row.
class DeviceRegistrationService {
  DeviceRegistrationService({
    required DeviceRegistryGateway gateway,
    required DeviceIdStore idStore,
    DateTime Function()? clock,
    String Function()? idGenerator,
  })  : _gateway = gateway,
        _idStore = idStore,
        _clock = clock ?? DateTime.now,
        _idGenerator = idGenerator ?? _generateUuidV4;

  final DeviceRegistryGateway _gateway;
  final DeviceIdStore _idStore;
  final DateTime Function() _clock;
  final String Function() _idGenerator;

  Future<RegisteredDevice> registerCurrentDevice({
    required String userId,
    required String label,
    required String platform,
    required String appVersion,
  }) async {
    _validateUuid(userId, 'userId');
    final cleanLabel = label.trim();
    if (cleanLabel.isEmpty || cleanLabel.length > 80) {
      throw const FormatException('Device label must contain 1–80 characters.');
    }
    if (!_supportedPlatforms.contains(platform)) {
      throw const FormatException('Unsupported device platform.');
    }
    if (appVersion.length > 32) {
      throw const FormatException('App version exceeds 32 characters.');
    }

    final now = _clock().toUtc();
    final savedId = await _idStore.read(userId);
    if (savedId != null && _isUuid(savedId)) {
      final existing = await _gateway.findDevice(savedId);
      if (existing != null &&
          existing['user_id'] == userId &&
          existing['revoked_at'] == null) {
        await _gateway.updateDevice(savedId, {
          'device_label': cleanLabel,
          'platform': platform,
          'app_version': appVersion,
          'last_seen_at': now.toIso8601String(),
        });
        final refreshed = await _gateway.findDevice(savedId);
        if (refreshed == null) {
          throw StateError('Device disappeared after its last-seen update.');
        }
        return RegisteredDevice.fromRow(refreshed);
      }
    }

    final id = _idGenerator();
    _validateUuid(id, 'generated device id');
    final row = <String, Object?>{
      'id': id,
      'user_id': userId,
      'device_label': cleanLabel,
      'platform': platform,
      'app_version': appVersion,
      'created_at': now.toIso8601String(),
      'last_seen_at': now.toIso8601String(),
    };
    await _gateway.insertDevice(row);
    await _idStore.write(userId, id);
    final inserted = await _gateway.findDevice(id);
    if (inserted == null) {
      throw StateError('Device was inserted but could not be read back.');
    }
    return RegisteredDevice.fromRow(inserted);
  }

  Future<String?> currentDeviceId(String userId) async {
    _validateUuid(userId, 'userId');
    final savedId = await _idStore.read(userId);
    return savedId != null && _isUuid(savedId) ? savedId : null;
  }

  Future<List<RegisteredDevice>> listDevices(String userId) async {
    _validateUuid(userId, 'userId');
    final rows = await _gateway.listDevices(userId);
    final devices = rows.map(RegisteredDevice.fromRow).toList();
    if (devices.any((device) => device.userId != userId)) {
      throw const FormatException('Device list contains another account.');
    }
    return devices;
  }

  Future<void> revokeDevice({
    required String userId,
    required String deviceId,
  }) async {
    _validateUuid(userId, 'userId');
    _validateUuid(deviceId, 'deviceId');
    await _gateway.revokeDevice(
      userId: userId,
      deviceId: deviceId,
      revokedAt: _clock().toUtc(),
    );
    if (await _idStore.read(userId) == deviceId) {
      await _idStore.remove(userId);
    }
  }

  static void _validateUuid(String value, String field) {
    if (!_isUuid(value)) {
      throw FormatException('$field must be a valid UUID.');
    }
  }
}

String _generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
  final value = hex.join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}
