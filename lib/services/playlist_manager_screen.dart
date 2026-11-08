import 'package:flutter/material.dart';

import 'playlist_library_repository.dart';

class PlaylistManagerScreen extends StatefulWidget {
  const PlaylistManagerScreen({
    super.key,
    required this.repository,
    required this.activePlaylistId,
    required this.onSelected,
  });

  final PlaylistLibraryRepository repository;
  final String? activePlaylistId;
  final void Function(PlaylistRecord record, String source) onSelected;

  @override
  State<PlaylistManagerScreen> createState() => _PlaylistManagerScreenState();
}

class _PlaylistManagerScreenState extends State<PlaylistManagerScreen> {
  late Future<List<PlaylistRecord>> _playlists;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _playlists = widget.repository.listPlaylists();
  }

  Future<void> _select(PlaylistRecord record) async {
    try {
      final source = await widget.repository.loadPlaylist(record.id);
      if (source == null) {
        throw const FormatException('No se encontró el archivo de esta lista.');
      }
      if (!mounted) return;
      await widget.repository.setActivePlaylistId(record.id);
      if (!mounted) return;
      widget.onSelected(record, source);
      Navigator.of(context).pop();
    } catch (error) {
      _message('No se pudo abrir la lista: $error');
    }
  }

  Future<void> _rename(PlaylistRecord record) async {
    final controller = TextEditingController(text: record.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar lista'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Nombre'),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    try {
      await widget.repository.renamePlaylist(record.id, name);
      if (!mounted) return;
      setState(_refresh);
    } catch (error) {
      _message('No se pudo renombrar: $error');
    }
  }

  Future<void> _delete(PlaylistRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lista'),
        content: Text('¿Querés eliminar "${record.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deletePlaylist(record.id);
      if (!mounted) return;
      setState(_refresh);
    } catch (error) {
      _message('No se pudo eliminar: $error');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis listas')),
      body: FutureBuilder<List<PlaylistRecord>>(
        future: _playlists,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('No se pudieron cargar las listas: ${snapshot.error}'),
            );
          }
          final records = snapshot.data ?? const <PlaylistRecord>[];
          if (records.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no guardaste listas. Importá un archivo M3U o M3U8 para agregar la primera.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: records.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final record = records[index];
              final active = record.id == widget.activePlaylistId;
              return ListTile(
                leading: Icon(
                  active ? Icons.radio_button_checked : Icons.playlist_play,
                  color: active ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(record.name),
                subtitle: Text('${record.channelCount} canales${active ? ' · Activa' : ''}'),
                onTap: () => _select(record),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Acciones de ${record.name}',
                  onSelected: (value) {
                    if (value == 'rename') _rename(record);
                    if (value == 'delete') _delete(record);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'rename', child: Text('Renombrar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
