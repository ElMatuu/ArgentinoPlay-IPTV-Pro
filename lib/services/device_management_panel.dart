import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_registration_service.dart';

/// Device list for the authenticated account. The current device cannot be
/// revoked here, avoiding accidental loss of the active session.
class DeviceManagementPanel extends StatefulWidget {
  const DeviceManagementPanel({required this.userId, this.service, super.key});

  final String userId;
  final DeviceRegistrationService? service;

  @override
  State<DeviceManagementPanel> createState() => _DeviceManagementPanelState();
}

class _DeviceManagementPanelState extends State<DeviceManagementPanel> {
  late final DeviceRegistrationService _service;
  List<RegisteredDevice> _devices = const [];
  String? _currentDeviceId;
  String? _error;
  bool _loading = true;
  bool _revoking = false;

  @override
  void initState() {
    super.initState();
    _service =
        widget.service ??
        DeviceRegistrationService(
          gateway: SupabaseDeviceRegistryGateway(Supabase.instance.client),
          idStore: PreferencesDeviceIdStore(),
        );
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      await _service.registerCurrentDevice(
        userId: widget.userId,
        label: 'Este dispositivo',
        platform: _platformName(),
        appVersion: '1.0.0+1',
      );
      final currentId = await _service.currentDeviceId(widget.userId);
      final devices = await _service.listDevices(widget.userId);
      if (!mounted) return;
      setState(() {
        _currentDeviceId = currentId;
        _devices = devices;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'No se pudieron cargar los dispositivos. Revisá la conexión y los permisos de la cuenta.';
      });
    }
  }

  String _platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'other';
    }
  }

  Future<void> _revoke(RegisteredDevice device) async {
    if (device.id == _currentDeviceId || _revoking) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revocar dispositivo'),
        content: Text(
          '¿Querés revocar "' +
              device.label +
              '" para futuras operaciones de sincronización? La sesión de ese equipo no se cierra automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _revoking = true;
      _error = null;
    });
    try {
      await _service.revokeDevice(userId: widget.userId, deviceId: device.id);
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo revocar el dispositivo. Intentá nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _revoking = false);
    }
  }

  String _dateLabel(DateTime value) {
    final local = value.toLocal();
    final date =
        local.day.toString().padLeft(2, '0') +
        '/' +
        local.month.toString().padLeft(2, '0') +
        '/' +
        local.year.toString();
    final time =
        local.hour.toString().padLeft(2, '0') +
        ':' +
        local.minute.toString().padLeft(2, '0');
    return date + ' · ' + time;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.devices_other),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mis dispositivos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar dispositivos',
                  onPressed: _loading || _revoking ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const Text(
              'Administrá los equipos asociados a tu cuenta. Revocar un equipo bloquea su uso en futuras funciones de sincronización.',
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_devices.isEmpty)
              const Text('Todavía no hay dispositivos registrados.')
            else
              ..._devices.map((device) {
                final isCurrent = device.id == _currentDeviceId;
                final isRevoked = device.revokedAt != null;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isCurrent ? Icons.phone_android : Icons.devices,
                  ),
                  title: Text(device.label),
                  subtitle: Text(
                    device.platform +
                        ' · v' +
                        device.appVersion +
                        '\nÚltima actividad: ' +
                        _dateLabel(device.lastSeenAt) +
                        (isRevoked ? '\nAcceso revocado' : ''),
                  ),
                  isThreeLine: true,
                  trailing: isCurrent
                      ? const Chip(label: Text('Este equipo'))
                      : isRevoked
                      ? const Chip(label: Text('Revocado'))
                      : IconButton(
                          tooltip: 'Revocar dispositivo',
                          onPressed: _revoking ? null : () => _revoke(device),
                          icon: const Icon(Icons.block),
                        ),
                );
              }),
            if (_revoking) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
