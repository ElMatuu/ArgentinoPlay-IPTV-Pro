import 'package:flutter_test/flutter_test.dart';
import 'package:argentino_play/domain/provider_authorization.dart';

void main() {
  final checkedAt = DateTime.utc(2026, 11, 9, 12);

  ProviderAuthorization authorization({
    Uri? evidenceUri,
    Set<ProviderRight>? rights,
    Set<ProviderPlatform>? platforms,
    Set<String>? territories,
    DateTime? expiresAt,
  }) {
    return ProviderAuthorization(
      providerId: 'public-broadcaster',
      providerName: 'Public Broadcaster',
      rightsHolder: 'Example Media Authority',
      evidenceUri: evidenceUri ??
          Uri.parse('https://provider.example/legal/streaming-permission'),
      checkedAt: checkedAt,
      expiresAt: expiresAt,
      rights: rights ?? {ProviderRight.inAppPlayback},
      platforms: platforms ?? {ProviderPlatform.android, ProviderPlatform.androidTv},
      territories: territories ?? {'AR'},
    );
  }

  test('permits only a documented right, platform and territory', () {
    final record = authorization();

    expect(
      record.permits(
        right: ProviderRight.inAppPlayback,
        platform: ProviderPlatform.androidTv,
        territory: 'ar',
        at: checkedAt.add(const Duration(minutes: 1)),
      ),
      isTrue,
    );
    expect(
      record.permits(
        right: ProviderRight.redistribution,
        platform: ProviderPlatform.androidTv,
        territory: 'AR',
        at: checkedAt.add(const Duration(minutes: 1)),
      ),
      isFalse,
    );
    expect(
      record.permits(
        right: ProviderRight.inAppPlayback,
        platform: ProviderPlatform.ios,
        territory: 'AR',
        at: checkedAt.add(const Duration(minutes: 1)),
      ),
      isFalse,
    );
    expect(
      record.permits(
        right: ProviderRight.inAppPlayback,
        platform: ProviderPlatform.android,
        territory: 'US',
        at: checkedAt.add(const Duration(minutes: 1)),
      ),
      isFalse,
    );
  });

  test('supports worldwide territory only when explicitly recorded', () {
    final record = authorization(territories: {'*'});

    expect(
      record.permits(
        right: ProviderRight.inAppPlayback,
        platform: ProviderPlatform.android,
        territory: 'US',
        at: checkedAt.add(const Duration(minutes: 1)),
      ),
      isTrue,
    );
  });

  test('rejects expired and not-yet-checked authorizations', () {
    final expiring = authorization(
      expiresAt: checkedAt.add(const Duration(days: 1)),
    );

    expect(
      expiring.permits(
        right: ProviderRight.inAppPlayback,
        platform: ProviderPlatform.android,
        territory: 'AR',
        at: checkedAt.add(const Duration(days: 1)),
      ),
      isFalse,
    );
    expect(
      expiring.permits(
        right: ProviderRight.inAppPlayback,
        platform: ProviderPlatform.android,
        territory: 'AR',
        at: checkedAt.subtract(const Duration(seconds: 1)),
      ),
      isFalse,
    );
  });

  test('rejects insecure evidence links and malformed scope', () {
    expect(
      () => authorization(evidenceUri: Uri.parse('http://provider.example/license')),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => authorization(territories: {'Argentina'}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => authorization(rights: {}),
      throwsA(isA<FormatException>()),
    );
  });

  test('does not treat an evidence URL as proof of rights by itself', () {
    final record = authorization(rights: {ProviderRight.epgMetadata});

    expect(
      record.permits(
        right: ProviderRight.inAppPlayback,
        platform: ProviderPlatform.android,
        territory: 'AR',
        at: checkedAt.add(const Duration(minutes: 1)),
      ),
      isFalse,
    );
  });
}
