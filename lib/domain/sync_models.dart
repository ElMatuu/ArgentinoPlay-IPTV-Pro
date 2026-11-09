/// Portable contracts for the future local-first synchronization layer.
///
/// These value objects deliberately contain no network client, credentials or
/// backend assumptions. The app remains usable when no sync provider is set.
enum SyncEntityType { playlistMetadata, favorite, userPreference }

enum SyncOperation { upsert, delete }

class SyncChange {
  const SyncChange({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.deviceId,
    required this.changedAt,
    required this.payload,
    this.baseRevision,
  });

  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperation operation;
  final String deviceId;
  final DateTime changedAt;
  final Map<String, Object?> payload;
  final int? baseRevision;

  Map<String, Object?> toJson() => {
        'id': id,
        'entityType': entityType.name,
        'entityId': entityId,
        'operation': operation.name,
        'deviceId': deviceId,
        'changedAt': changedAt.toUtc().toIso8601String(),
        'payload': payload,
        'baseRevision': baseRevision,
      };

  factory SyncChange.fromJson(Map<String, Object?> json) {
    final id = _requiredString(json, 'id');
    final entityId = _requiredString(json, 'entityId');
    final deviceId = _requiredString(json, 'deviceId');
    final entityName = _requiredString(json, 'entityType');
    final operationName = _requiredString(json, 'operation');
    final changedAt = DateTime.tryParse(
      _requiredString(json, 'changedAt'),
    );
    final rawPayload = json['payload'];
    final baseRevision = json['baseRevision'];

    if (!_validId(id) || !_validId(entityId) || !_validId(deviceId)) {
      throw const FormatException('Invalid synchronization identifier.');
    }
    if (changedAt == null || rawPayload is! Map<String, dynamic>) {
      throw const FormatException('Invalid synchronization change.');
    }
    if (baseRevision != null && (baseRevision is! int || baseRevision < 0)) {
      throw const FormatException('Invalid base revision.');
    }

    return SyncChange(
      id: id,
      entityType: SyncEntityType.values.firstWhere(
        (value) => value.name == entityName,
        orElse: () => throw const FormatException('Unknown sync entity type.'),
      ),
      entityId: entityId,
      operation: SyncOperation.values.firstWhere(
        (value) => value.name == operationName,
        orElse: () => throw const FormatException('Unknown sync operation.'),
      ),
      deviceId: deviceId,
      changedAt: changedAt.toUtc(),
      payload: Map<String, Object?>.from(rawPayload),
      baseRevision: baseRevision as int?,
    );
  }
}

class SyncCursor {
  const SyncCursor({
    required this.value,
    required this.updatedAt,
  });

  final String value;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'value': value,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory SyncCursor.fromJson(Map<String, Object?> json) {
    final value = json['value'];
    final updatedAt = DateTime.tryParse(json['updatedAt']?.toString() ?? '');
    if (value is! String || value.length > 2048 || updatedAt == null) {
      throw const FormatException('Invalid synchronization cursor.');
    }
    return SyncCursor(value: value, updatedAt: updatedAt.toUtc());
  }
}

class SyncConflict {
  const SyncConflict({
    required this.entityType,
    required this.entityId,
    required this.localChange,
    required this.remoteRevision,
    required this.detectedAt,
  });

  final SyncEntityType entityType;
  final String entityId;
  final SyncChange localChange;
  final int remoteRevision;
  final DateTime detectedAt;
}

/// IDs are opaque and must not contain paths, URLs or credential material.
bool _validId(String value) =>
    value.length <= 128 && RegExp(r'^[a-zA-Z0-9._:-]+$').hasMatch(value);

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty || value.length > 2048) {
    throw FormatException('Invalid $key.');
  }
  return value;
}
