# Production readiness — ArgentinoPlay IPTV Pro

## Current repository milestone

This repository now contains the first Flutter client foundation:
- M3U/M3U8 file import and HTTP(S) entry parsing.
- Channel search and category display.
- Local favorites persistence.
- Basic network video playback through video_player.
- Automated parser/widget tests.
- GitHub Actions formatting, analysis, tests and Android debug APK artifact.

## Not production-ready yet

A successful debug APK build is not a production release. The following work remains:
- Test playback against a documented matrix of authorized HLS/DASH/MP4 streams and real Android devices.
- Add robust playback state handling, buffering/retry, audio/subtitle selection and lifecycle recovery.
- Add XMLTV EPG ingestion, timezone handling and channel-program matching.
- Add secure playlist management, validation, import limits and protection against private-network/SSRF access if remote URL import is introduced.
- Add Android TV focus/remote navigation and large-screen layouts.
- Add privacy disclosures, permission review, dependency/license/security scanning and crash diagnostics that do not leak URLs or credentials.
- Add localization, accessibility, offline/error states and integration tests.
- Configure release signing outside source control using protected GitHub secrets; never commit keystores or passwords.
- Run release builds, install on supported devices, execute acceptance tests and document rollback/release procedures.

## Content rights

Only use streams that are owned, public-domain, explicitly licensed, or otherwise authorized for the intended use. A publicly reachable URL is not proof of retransmission rights. Do not bundle unlicensed channel lists.

## Release gate

Do not label a build production-ready until CI is green, a signed release artifact is produced, rights and privacy checks are complete, and the app has passed real-device acceptance testing.
