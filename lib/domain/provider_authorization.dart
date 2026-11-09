/// Rights evidence required before a provider source can be listed or played.
///
/// This model stores authorization metadata only. It deliberately does not
/// store stream URLs, playlist contents, credentials, or provider tokens.
enum ProviderRight {
  inAppPlayback,
  redistribution,
  commercialUse,
  epgMetadata,
}

enum ProviderPlatform {
  android,
  androidTv,
  ios,
  web,
  desktop,
}

class ProviderAuthorization {
  ProviderAuthorization({
    required this.providerId,
    required this.providerName,
    required this.rightsHolder,
    required this.evidenceUri,
    required this.checkedAt,
    required Set<ProviderRight> rights,
    required Set<ProviderPlatform> platforms,
    required Set<String> territories,
    this.expiresAt,
  })  : rights = Set.unmodifiable(rights),
        platforms = Set.unmodifiable(platforms),
        territories = Set.unmodifiable(
          territories.map((value) => value.trim().toUpperCase()),
        ) {
    _validate();
  }

  final String providerId;
  final String providerName;
  final String rightsHolder;
  final Uri evidenceUri;
  final DateTime checkedAt;
  final DateTime? expiresAt;
  final Set<ProviderRight> rights;
  final Set<ProviderPlatform> platforms;

  /// ISO 3166-1 alpha-2 codes, or "*" for worldwide permission.
  final Set<String> territories;

  bool permits({
    required ProviderRight right,
    required ProviderPlatform platform,
    required String territory,
    required DateTime at,
  }) {
    final normalizedTerritory = territory.trim().toUpperCase();
    if (normalizedTerritory.length != 2) return false;
    if (!rights.contains(right) || !platforms.contains(platform)) return false;
    if (!territories.contains('*') &&
        !territories.contains(normalizedTerritory)) {
      return false;
    }
    if (checkedAt.isAfter(at.toUtc())) return false;
    final expiry = expiresAt;
    if (expiry != null && !expiry.isAfter(at.toUtc())) return false;
    return true;
  }

  void _validate() {
    if (!_validIdentifier(providerId)) {
      throw const FormatException('Invalid provider identifier.');
    }
    if (providerName.trim().isEmpty || providerName.trim().length > 120) {
      throw const FormatException('Invalid provider name.');
    }
    if (rightsHolder.trim().isEmpty || rightsHolder.trim().length > 160) {
      throw const FormatException('Invalid rights holder.');
    }
    if (evidenceUri.scheme != 'https' ||
        evidenceUri.host.isEmpty ||
        evidenceUri.userInfo.isNotEmpty) {
      throw const FormatException('Rights evidence must be a safe HTTPS URL.');
    }
    if (rights.isEmpty || platforms.isEmpty || territories.isEmpty) {
      throw const FormatException(
        'Rights, platforms and territories are required.',
      );
    }
    if (territories.any(
      (value) => value != '*' && !RegExp(r'^[A-Z]{2}$').hasMatch(value),
    )) {
      throw const FormatException('Territories must be ISO alpha-2 codes or *.');
    }
    if (expiresAt != null && !expiresAt!.isAfter(checkedAt)) {
      throw const FormatException(
        'Authorization expiry must follow its check date.',
      );
    }
  }
}

bool _validIdentifier(String value) =>
    value.length <= 64 && RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(value);
