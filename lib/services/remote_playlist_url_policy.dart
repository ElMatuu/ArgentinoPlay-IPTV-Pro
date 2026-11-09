import 'dart:io';

/// Result of applying the conservative policy for a future remote playlist
/// downloader. This validator does not resolve DNS names and must be combined
/// with address validation for every resolved IP and redirect at fetch time.
class RemotePlaylistUrlDecision {
  const RemotePlaylistUrlDecision._(this.allowed, this.reason);

  const RemotePlaylistUrlDecision.allow()
      : this._(true, 'HTTPS URL passed the static URL policy.');

  const RemotePlaylistUrlDecision.reject(String reason) : this._(false, reason);

  final bool allowed;
  final String reason;
}

/// Applies static checks before a remote playlist URL is handed to a network
/// client. Network code must still validate DNS results and every redirect.
RemotePlaylistUrlDecision validateRemotePlaylistUrl(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return const RemotePlaylistUrlDecision.reject('URL is malformed.');
  }
  if (uri.scheme.toLowerCase() != 'https') {
    return const RemotePlaylistUrlDecision.reject(
      'Only HTTPS URLs are allowed.',
    );
  }
  if (uri.userInfo.isNotEmpty) {
    return const RemotePlaylistUrlDecision.reject(
      'URLs containing embedded credentials are not allowed.',
    );
  }

  final host = uri.host.toLowerCase();
  final unbracketedHost = host.startsWith('[') && host.endsWith(']')
      ? host.substring(1, host.length - 1)
      : host;
  // A final DNS root dot does not change a hostname's identity. Remove it for
  // policy checks so localhost. and printer.local. cannot bypass suffix rules.
  var normalizedHost = unbracketedHost;
  while (normalizedHost.endsWith('.')) {
    normalizedHost = normalizedHost.substring(0, normalizedHost.length - 1);
  }
  final address = InternetAddress.tryParse(normalizedHost);
  final looksLikeNonStandardIpv4 = RegExp(
    r'^(?:0x[0-9a-f]+|[0-9]+)(?:\.(?:0x[0-9a-f]+|[0-9]+))*$',
    caseSensitive: false,
  ).hasMatch(normalizedHost);
  if (address == null &&
      (looksLikeNonStandardIpv4 ||
          normalizedHost.isEmpty ||
          normalizedHost == 'localhost' ||
          normalizedHost.endsWith('.localhost') ||
          normalizedHost.endsWith('.local') ||
          !normalizedHost.contains('.'))) {
    return const RemotePlaylistUrlDecision.reject(
      'Local or non-qualified hostnames are not allowed.',
    );
  }

  if (address != null && _isNonPublicAddress(address)) {
    return const RemotePlaylistUrlDecision.reject(
      'Private, local, or reserved IP addresses are not allowed.',
    );
  }

  return const RemotePlaylistUrlDecision.allow();
}

bool _isNonPublicAddress(InternetAddress address) {
  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    final a = bytes[0];
    final b = bytes[1];
    return a == 0 ||
        a == 10 ||
        a == 127 ||
        (a == 100 && b >= 64 && b <= 127) ||
        (a == 169 && b == 254) ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && (b == 0 || b == 168)) ||
        (a == 198 && (b == 18 || b == 19 || b == 51)) ||
        (a == 203 && b == 0) ||
        a >= 224;
  }

  final allZero = bytes.every((byte) => byte == 0);
  final loopback = bytes.take(15).every((byte) => byte == 0) && bytes[15] == 1;
  final uniqueLocal = (bytes[0] & 0xfe) == 0xfc;
  final linkLocal = bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80;
  final multicast = bytes[0] == 0xff;
  final ipv4Mapped = bytes.take(10).every((byte) => byte == 0) &&
      bytes[10] == 0xff &&
      bytes[11] == 0xff;
  if (ipv4Mapped) {
    final mapped = InternetAddress.fromRawAddress(bytes.sublist(12));
    return _isNonPublicAddress(mapped);
  }
  return allZero || loopback || uniqueLocal || linkLocal || multicast;
}
