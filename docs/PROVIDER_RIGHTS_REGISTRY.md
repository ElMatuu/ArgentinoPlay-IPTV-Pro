# Provider rights registry

ArgentinoPlay must not treat a reachable stream, public M3U URL, or a user's
general statement as proof that a provider authorized redistribution or
in-app playback.

Before a provider is added to a built-in catalog, record and review:

- The legal rights holder and provider identity.
- A stable HTTPS evidence reference (contract, official terms, or written
  permission); store no private tokens or credentials in this record.
- Explicit rights: in-app playback, redistribution, commercial use, and/or
  EPG metadata. These are separate permissions.
- Allowed territories and target platforms (Android and Android TV are
  separate platform scopes).
- The date checked and any expiry date.

ProviderAuthorization.permits is a client-side scope check, not legal
verification or a substitute for server-side review. A reviewer must inspect
the evidence and confirm it covers ArgentinoPlay's actual distribution model.
Unknown, expired, ambiguous, or unsupported permissions must fail closed.
Do not bundle provider stream URLs until that review is complete.

User-imported playlists remain local and are subject to the user's own rights
and provider terms. Do not upload M3U bodies, stream URLs, or embedded
credentials as part of the provider registry.
