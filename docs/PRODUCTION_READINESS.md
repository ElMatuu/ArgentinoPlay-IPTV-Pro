# Production readiness — ArgentinoPlay IPTV Pro

## Implemented in the Flutter client

- M3U/M3U8 parsing with channel name, group, logo, tvg-id, country and language metadata.
- XMLTV parsing with channel metadata, programme descriptions/categories and timezone normalization.
- Import of M3U/M3U8 and XMLTV files with 5 MB and 10 MB limits.
- Private local persistence of the imported playlist and guide in the app support directory.
- Temporary-file replacement with backup restoration on failed writes.
- Startup restoration of the saved playlist and guide; a damaged item does not prevent the other item from loading.
- Local favorites persistence, channel search, guide view and basic network playback.
- Parser, storage and widget tests.
- GitHub Actions formatting, static analysis, automated tests and Android debug APK artifact.

## Remaining release blockers

- Playback compatibility matrix for authorized HLS, DASH and MP4 streams, including error recovery and long-running playback.
- Player controls and capability checks for audio tracks, subtitles, aspect ratio, casting and reconnect behavior.
- Android TV remote/D-pad navigation, focus states, landscape and large-screen acceptance testing.
- Playlist management beyond a single active playlist: multiple libraries, rename, replace, remove, deduplication and source provenance.
- EPG refresh/scheduling, large-guide performance, channel matching assistance and programme search.
- Secure remote playlist/EPG URL import, including private-network/SSRF protections, redirect validation and download timeouts, before any URL-import feature is enabled.
- Privacy disclosures, permission review, dependency/license/security scanning and privacy-safe diagnostics.
- Accessibility, localization, responsive layouts and broader integration tests.
- Release signing outside source control using protected GitHub secrets; never commit keystores or passwords.
- Release APK/AAB build, install on supported physical devices, acceptance tests and rollback/release procedures.
- Platform-specific implementations for Samsung Tizen and LG webOS if those TV platforms are in scope; an Android APK does not install on those operating systems.

## Content rights

Only use streams that are owned, public-domain, explicitly licensed, or otherwise authorized for the intended use. A publicly reachable URL is not proof of retransmission rights. Do not bundle unlicensed channel lists.

## Release gate

A green debug CI run and a generated debug APK are development milestones, not a production release. Do not label the app production-ready until signed release artifacts, rights and privacy checks, security/dependency checks and real-device acceptance tests are complete.
