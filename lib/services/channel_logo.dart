import 'package:flutter/material.dart';

/// Displays an imported channel logo when its URL is a safe HTTP(S) address.
/// Invalid, unsupported, or failed logo requests fall back to the live-TV icon.
class ChannelLogo extends StatelessWidget {
  const ChannelLogo({
    super.key,
    required this.url,
    this.size = 40,
  });

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url.trim());
    final isAllowed = uri != null &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.userInfo.isEmpty;
    final fallback = Icon(Icons.live_tv, size: size * 0.5);

    return CircleAvatar(
      radius: size / 2,
      child: !isAllowed
          ? fallback
          : ClipOval(
              child: Image.network(
                uri.toString(),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
            ),
    );
  }
}
