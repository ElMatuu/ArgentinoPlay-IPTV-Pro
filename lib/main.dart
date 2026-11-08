import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'domain/epg.dart';
import 'domain/tv_channel.dart';
import 'services/local_library_repository.dart';
import 'services/m3u_parser.dart';
import 'services/xmltv_parser.dart';

export 'domain/epg.dart';
export 'domain/tv_channel.dart';
export 'services/m3u_parser.dart';
export 'services/xmltv_parser.dart';

void main() => runApp(ArgentinoPlayApp());

class ArgentinoPlayApp extends StatelessWidget {
  ArgentinoPlayApp({super.key, LocalLibraryRepository? libraryRepository})
      : libraryRepository = libraryRepository ?? LocalLibraryRepository();

  final LocalLibraryRepository libraryRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArgentinoPlay IPTV Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16A085),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(libraryRepository: libraryRepository),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.libraryRepository});

  final LocalLibraryRepository libraryRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TvChannel> _channels = [];
  Set<String> _favorites = {};
  XmltvGuide? _guide;
  bool _loading = true;
  bool _importing = false;
  String _query = '';
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    List<TvChannel> channels = [];
    XmltvGuide? guide;
    try {
      final playlist = await widget.libraryRepository.loadPlaylist();
      if (playlist != null) {
        channels = parseM3u(playlist);
      }
    } catch (_) {
      // Keep the rest of the library usable if a stored playlist is damaged.
    }
    try {
      final source = await widget.libraryRepository.loadGuide();
      if (source != null) {
        final parsed = parseXmltv(source);
        if (parsed.channels.isNotEmpty && parsed.programmes.isNotEmpty) {
          guide = parsed;
        }
      }
    } catch (_) {
      // A damaged guide must not prevent the channel list from loading.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _favorites = (prefs.getStringList('favorites') ?? []).toSet();
      _channels = channels;
      _guide = guide;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite(TvChannel channel) async {
    final wasFavorite = _favorites.contains(channel.url);
    setState(() {
      if (wasFavorite) {
        _favorites.remove(channel.url);
      } else {
        _favorites.add(channel.url);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', _favorites.toList());
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (wasFavorite) {
          _favorites.add(channel.url);
        } else {
          _favorites.remove(channel.url);
        }
      });
      _showMessage('No se pudo guardar el cambio de favoritos.');
    }
  }

  Future<void> _importPlaylist() async {
    if (_importing) {
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      _showMessage('No se pudo acceder al contenido del archivo.');
      return;
    }
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      _showMessage('La lista supera el límite de importación de 5 MB.');
      return;
    }

    setState(() => _importing = true);
    try {
      final source = utf8.decode(bytes);
      final parsed = parseM3u(source);
      if (parsed.isEmpty) {
        throw const FormatException(
          'No se encontraron canales HTTP/HTTPS válidos.',
        );
      }
      await widget.libraryRepository.savePlaylist(source);
      if (!mounted) {
        return;
      }
      setState(() {
        _channels = parsed;
        _tab = 0;
      });
      _showMessage(
        'Se importaron ${parsed.length} canales. Usá únicamente fuentes autorizadas.',
      );
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('No se pudo procesar la lista seleccionada.');
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  Future<void> _importEpg() async {
    if (_importing) {
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml', 'xmltv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      _showMessage('No se pudo acceder al contenido del archivo EPG.');
      return;
    }
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      _showMessage('La guía supera el límite de importación de 10 MB.');
      return;
    }

    setState(() => _importing = true);
    try {
      final source = utf8.decode(bytes);
      final guide = parseXmltv(source);
      if (guide.channels.isEmpty || guide.programmes.isEmpty) {
        throw const FormatException(
          'El XMLTV no contiene canales y programas utilizables.',
        );
      }
      await widget.libraryRepository.saveGuide(source);
      if (!mounted) {
        return;
      }
      setState(() => _guide = guide);
      _showMessage(
        'Guía importada: ${guide.channels.length} canales y '
        '${guide.programmes.length} programas.',
      );
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('No se pudo procesar el archivo XMLTV.');
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  EpgProgramme? _currentProgramme(TvChannel channel) {
    final guide = _guide;
    if (guide == null || channel.tvgId.isEmpty) {
      return null;
    }
    return guide.programmeAt(channel.tvgId, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final visible = _channels.where((channel) {
      final matches = channel.name.toLowerCase().contains(_query.toLowerCase()) ||
          channel.group.toLowerCase().contains(_query.toLowerCase());
      final inFavorites = _tab != 1 || _favorites.contains(channel.url);
      final inGuide = _tab != 2 ||
          (_guide?.channels.containsKey(channel.tvgId) ?? false);
      return matches && inFavorites && inGuide;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🇦🇷 ArgentinoPlay',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Importar lista M3U/M3U8',
            onPressed: _importing ? null : _importPlaylist,
            icon: const Icon(Icons.playlist_add),
          ),
          IconButton(
            tooltip: 'Importar guía XMLTV',
            onPressed: _importing ? null : _importEpg,
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_importing) const LinearProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar canales...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.live_tv,
                          label: 'Canales',
                          value: '${_channels.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.favorite,
                          label: 'Favoritos',
                          value: '${_favorites.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.event,
                          label: 'EPG',
                          value: '${_guide?.programmes.length ?? 0}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: visible.isEmpty
                      ? _EmptyState(
                          onImport: _tab == 2 ? _importEpg : _importPlaylist,
                          favoritesOnly: _tab == 1,
                          guideOnly: _tab == 2,
                        )
                      : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final channel = visible[index];
                            final programme = _currentProgramme(channel);
                            final isFavorite =
                                _favorites.contains(channel.url);
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.live_tv),
                              ),
                              title: Text(
                                channel.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                programme == null
                                    ? channel.group
                                    : '${channel.group} · Ahora: ${programme.title}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                tooltip: isFavorite
                                    ? 'Quitar de favoritos'
                                    : 'Agregar a favoritos',
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.redAccent : null,
                                ),
                                onPressed: () => _toggleFavorite(channel),
                              ),
                              onTap: () {
                                if (_tab == 2 && _guide != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EpgScreen(
                                        channel: channel,
                                        guide: _guide!,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PlayerScreen(channel: channel),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.live_tv),
            label: 'Canales',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Programación',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onImport,
    required this.favoritesOnly,
    required this.guideOnly,
  });

  final VoidCallback onImport;
  final bool favoritesOnly;
  final bool guideOnly;

  @override
  Widget build(BuildContext context) {
    final title = favoritesOnly
        ? 'Todavía no hay favoritos'
        : guideOnly
            ? 'Todavía no hay programación'
            : 'Tu catálogo empieza acá';
    final description = favoritesOnly
        ? 'Marcá canales con el corazón para encontrarlos acá.'
        : guideOnly
            ? 'Importá una guía XMLTV y vinculala mediante el identificador tvg-id de cada canal.'
            : 'Importá una lista M3U/M3U8 de fuentes propias, públicas autorizadas o licenciadas.';
    final icon = favoritesOnly
        ? Icons.favorite_border
        : guideOnly
            ? Icons.event
            : Icons.playlist_play;
    final buttonLabel = guideOnly ? 'Importar guía XMLTV' : 'Importar lista';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            if (!favoritesOnly) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.upload_file),
                label: Text(buttonLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EpgScreen extends StatelessWidget {
  const EpgScreen({
    super.key,
    required this.channel,
    required this.guide,
  });

  final TvChannel channel;
  final XmltvGuide guide;

  @override
  Widget build(BuildContext context) {
    final programmes = guide.programmesFor(channel.tvgId);
    return Scaffold(
      appBar: AppBar(title: Text('Programación · ${channel.name}')),
      body: programmes.isEmpty
          ? const Center(
              child: Text('No hay programas disponibles para este canal.'),
            )
          : ListView.separated(
              itemCount: programmes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final programme = programmes[index];
                final now = programme.isOnAirAt(DateTime.now());
                return ListTile(
                  leading: Icon(
                    now ? Icons.play_circle_fill : Icons.schedule,
                    color: now
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(programme.title),
                  subtitle: Text(
                    '${_formatTime(programme.start)}–'
                    '${_formatTime(programme.end)}'
                    '${programme.description.isEmpty ? '' : '\n${programme.description}'}',
                  ),
                  isThreeLine: programme.description.isNotEmpty,
                );
              },
            ),
    );
  }
}

String _formatTime(DateTime timestamp) {
  final local = timestamp.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.channel});

  final TvChannel channel;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  String? _error;
  bool _busy = true;
  bool _wasPlayingBeforePause = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    final previous = _controller;
    previous?.removeListener(_onPlayerChanged);
    await previous?.dispose();

    if (!mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.channel.url),
      );
      _controller = controller;
      controller.addListener(_onPlayerChanged);
      await controller.initialize();
      if (!mounted) {
        return;
      }
      await controller.play();
      if (mounted) {
        setState(() => _busy = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error =
              'No se pudo iniciar la reproducción. Revisá la conexión, el formato y los permisos de la fuente.';
        });
      }
    }
  }

  void _onPlayerChanged() {
    final controller = _controller;
    if (!mounted || controller == null) {
      return;
    }
    if (controller.value.hasError && _error == null) {
      setState(() {
        _busy = false;
        _error =
            'La fuente rechazó la reproducción o entregó un formato no compatible.';
      });
      return;
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _wasPlayingBeforePause = controller.value.isPlaying;
      controller.pause();
    } else if (state == AppLifecycleState.resumed &&
        _wasPlayingBeforePause) {
      controller.play();
      _wasPlayingBeforePause = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onPlayerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialized = controller?.value.isInitialized ?? false;
    final aspectRatio = initialized && controller!.value.aspectRatio > 0
        ? controller.value.aspectRatio
        : 16 / 9;

    return Scaffold(
      appBar: AppBar(title: Text(widget.channel.name)),
      body: Center(
        child: _busy
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : controller == null || !initialized
                    ? const Text('Preparando reproductor...')
                    : AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            VideoPlayer(controller),
                            VideoProgressIndicator(
                              controller,
                              allowScrubbing: true,
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: IconButton.filledTonal(
                                iconSize: 42,
                                onPressed: () {
                                  if (controller.value.isPlaying) {
                                    controller.pause();
                                  } else {
                                    controller.play();
                                  }
                                },
                                icon: Icon(
                                  controller.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                              ),
                            ),
                            if (controller.value.isBuffering)
                              const Align(
                                alignment: Alignment.topCenter,
                                child: LinearProgressIndicator(),
                              ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
