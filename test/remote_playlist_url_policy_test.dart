import 'package:argentino_play/services/remote_playlist_url_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateRemotePlaylistUrl', () {
    test('allows a qualified HTTPS hostname', () {
      final result =
          validateRemotePlaylistUrl('https://media.example.org/list.m3u');
      expect(result.allowed, isTrue);
    });

    test('rejects non-HTTPS schemes and malformed URLs', () {
      expect(
          validateRemotePlaylistUrl('http://media.example.org/a.m3u').allowed,
          isFalse);
      expect(validateRemotePlaylistUrl('file:///etc/passwd').allowed, isFalse);
      expect(validateRemotePlaylistUrl('not a url').allowed, isFalse);
    });

    test('rejects embedded credentials and local hostnames', () {
      expect(
          validateRemotePlaylistUrl('https://user:pass@media.example.org/a')
              .allowed,
          isFalse);
      expect(validateRemotePlaylistUrl('https://localhost/a').allowed, isFalse);
      expect(
        validateRemotePlaylistUrl('https://localhost./a').allowed,
        isFalse,
      );
      expect(
        validateRemotePlaylistUrl('https://localhost../a').allowed,
        isFalse,
      );
      expect(
        validateRemotePlaylistUrl('https://tv.localhost./a').allowed,
        isFalse,
      );
      expect(
        validateRemotePlaylistUrl('https://printer.local./a').allowed,
        isFalse,
      );
      expect(validateRemotePlaylistUrl('https://printer.local/a').allowed,
          isFalse);
      expect(validateRemotePlaylistUrl('https://intranet/a').allowed, isFalse);
    });

    test('rejects private, loopback, link-local and reserved IPv4 literals',
        () {
      for (final host in [
        '10.0.0.1',
        '127.0.0.1',
        '169.254.1.2',
        '172.16.0.1',
        '192.168.1.1',
        '100.64.0.1',
        '224.0.0.1',
      ]) {
        expect(
          validateRemotePlaylistUrl('https://$host/list.m3u').allowed,
          isFalse,
          reason: 'Expected $host to be rejected',
        );
      }
    });

    test('rejects non-public and deprecated IPv6 literals', () {
      for (final host in [
        '[::1]',
        '[fc00::1]',
        '[fe80::1]',
        '[::]',
        '[::a00:1]',
        '[::7f00:1]',
      ]) {
        expect(
          validateRemotePlaylistUrl('https://$host/list.m3u').allowed,
          isFalse,
          reason: 'Expected $host to be rejected',
        );
      }
    });

    test('rejects IPv4-mapped IPv6 addresses containing private IPv4', () {
      for (final host in ['[::ffff:7f00:1]', '[::ffff:a00:1]']) {
        expect(
          validateRemotePlaylistUrl('https://$host/list.m3u').allowed,
          isFalse,
          reason: 'Expected mapped private address $host to be rejected',
        );
      }
    });

    test('rejects non-standard numeric IPv4 host forms', () {
      for (final host in [
        '127.1',
        '0177.0.0.1',
        '0x7f.0.0.1',
        '2130706433',
      ]) {
        expect(
          validateRemotePlaylistUrl('https://$host/list.m3u').allowed,
          isFalse,
          reason: 'Expected non-standard numeric host $host to be rejected',
        );
      }
    });

    test('rejects special-purpose IPv4 ranges', () {
      for (final host in [
        '192.0.0.8',
        '192.0.2.1',
        '192.88.99.1',
        '198.51.100.1',
        '203.0.113.1',
        '240.0.0.1',
      ]) {
        expect(
          validateRemotePlaylistUrl('https://$host/list.m3u').allowed,
          isFalse,
          reason: 'Expected special-purpose IPv4 address $host to be rejected',
        );
      }
    });

    test('rejects IPv6 protocol, documentation and transition ranges', () {
      for (final host in [
        '[2001::1]',
        '[2001:db8::1]',
        '[2002:c000:0201::1]',
        '[3fff::1]',
      ]) {
        expect(
          validateRemotePlaylistUrl('https://$host/list.m3u').allowed,
          isFalse,
          reason: 'Expected special-purpose IPv6 address $host to be rejected',
        );
      }
    });

    test('allows a public IPv6 global-unicast address', () {
      expect(
        validateRemotePlaylistUrl('https://[2606:4700:4700::1111]/list.m3u')
            .allowed,
        isTrue,
      );
    });

    test('documents the DNS resolution boundary', () {
      final result =
          validateRemotePlaylistUrl('https://media.example.org/list.m3u');
      expect(result.allowed, isTrue);
      expect(result.reason, contains('static URL policy'));
    });
  });
}
