import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'domain/tv_channel.dart';
import 'services/m3u_parser.dart';

export 'domain/tv_channel.dart';
export 'services/m3u_parser.dart';

class ArgentinoPlayApp extends StatelessWidget {
  const ArgentinoPlayApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ArgentinoPlay IPTV Pro',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16A085), brightness: Brightness.dark), useMaterial3: true),
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TvChannel> _channels = [];
  Set<String> _favorites = {};
  bool _loading = true;
  String _query = '';
  int _tab = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _favorites = (prefs.getStringList('favorites') ?? []).toSet();
      _loading = false;
    });
  }

  Future<void> _toggleFavorite(TvChannel channel) async {
    setState(() {
      if (!_favorites.add(channel.url)) {
        _favorites.remove(channel.url);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.toList());
  }

  Future<void> _importPlaylist() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['m3u', 'm3u8'], withData: true);
    if (result == null || result.files.single.bytes == null) {
      return;
    }
    try {
      final text = utf8.decode(result.files.single.bytes!);
      final parsed = parseM3u(text);
      if (parsed.isEmpty) {
        throw const FormatException('No se encontraron canales HTTP/HTTPS válidos.');
      }
      if (!mounted) return;
      setState(() => _channels = parsed);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Se importaron ${parsed.length} canales. Verificá que tengas autorización para reproducir sus fuentes.')));
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo leer la lista seleccionada.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _channels.where((c) {
      final matches = c.name.toLowerCase().contains(_query.toLowerCase()) || c.group.toLowerCase().contains(_query.toLowerCase());
      return matches && (_tab != 1 || _favorites.contains(c.url));
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('🇦🇷 ArgentinoPlay', style: TextStyle(fontWeight: FontWeight.bold)), actions: [
        IconButton(tooltip: 'Importar lista M3U/M3U8', onPressed: _importPlaylist, icon: const Icon(Icons.playlist_add)),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar canales...', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _query = v),
        )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          Expanded(child: _InfoTile(icon: Icons.live_tv, label: 'Canales', value: '${_channels.length}')),
          const SizedBox(width: 10),
          Expanded(child: _InfoTile(icon: Icons.favorite, label: 'Favoritos', value: '${_favorites.length}')),
        ])),
        const SizedBox(height: 12),
        Expanded(child: visible.isEmpty
          ? _EmptyState(onImport: _importPlaylist, favoritesOnly: _tab == 1)
          : ListView.builder(itemCount: visible.length, itemBuilder: (context, index) {
              final channel = visible[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.live_tv)),
                title: Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(channel.group),
                trailing: IconButton(
                  tooltip: _favorites.contains(channel.url) ? 'Quitar de favoritos' : 'Agregar a favoritos',
                  icon: Icon(_favorites.contains(channel.url) ? Icons.favorite : Icons.favorite_border, color: _favorites.contains(channel.url) ? Colors.redAccent : null),
                  onPressed: () => _toggleFavorite(channel),
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(channel: channel))),
              );
            })),
      ]),
      bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (v) => setState(() => _tab = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.live_tv), label: 'Canales'),
        NavigationDestination(icon: Icon(Icons.favorite), label: 'Favoritos'),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon; final String label; final String value;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
    Icon(icon, size: 22), const SizedBox(width: 10),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.titleLarge), Text(label, style: Theme.of(context).textTheme.labelMedium)]),
  ])));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onImport, required this.favoritesOnly});
  final VoidCallback onImport; final bool favoritesOnly;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(favoritesOnly ? Icons.favorite_border : Icons.playlist_play, size: 64, color: Theme.of(context).colorScheme.primary),
    const SizedBox(height: 16),
    Text(favoritesOnly ? 'Todavía no hay favoritos' : 'Tu catálogo empieza acá', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    Text(favoritesOnly ? 'Marcá canales con el corazón para encontrarlos acá.' : 'Importá una lista M3U/M3U8 de fuentes propias, públicas autorizadas o licenciadas.', textAlign: TextAlign.center),
    if (!favoritesOnly) ...[const SizedBox(height: 18), FilledButton.icon(onPressed: onImport, icon: const Icon(Icons.upload_file), label: const Text('Importar lista'))],
  ])));
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.channel});
  final TvChannel channel;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  String? _error;
  bool _busy = true;

  @override
  void initState() { super.initState(); _start(); }

  Future<void> _start() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.channel.url));
      _controller = controller;
      await controller.initialize();
      await controller.play();
      if (mounted) {
        setState(() => _busy = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'No se pudo iniciar la reproducción. Verificá el enlace, el formato y los permisos de la fuente.';
        });
      }
    }
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.channel.name)),
    body: Center(child: _busy ? const CircularProgressIndicator() : _error != null
      ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center))
      : AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: Stack(alignment: Alignment.bottomCenter, children: [
          VideoPlayer(_controller!),
          VideoProgressIndicator(_controller!, allowScrubbing: true),
          Align(alignment: Alignment.center, child: IconButton.filledTonal(iconSize: 42, onPressed: () => setState(() => _controller!.value.isPlaying ? _controller!.pause() : _controller!.play()), icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow))),
        ]))),
  );
}
