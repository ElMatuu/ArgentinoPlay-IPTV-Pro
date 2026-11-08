# Production readiness — ArgentinoPlay IPTV Pro

## Integrated baseline

- Pull request #15 was squash-merged into `main`.
- Merge commit: `cbe7821302af21bf52ae854d92ffb8af0761bd10`.
- Post-merge GitHub Actions run #178 completed successfully: Android scaffold generation/configuration, Dart formatting, static analysis, automated tests, debug APK build and artifact upload.
- The merged Flutter client includes M3U/M3U8 and XMLTV parsing, local playlist/guide persistence, multi-playlist management, favorites/search/guide UI, player startup/retry race protection, bounded seeking and isolated remote-key mapping tests.
- Android TV manifest configuration is currently applied to a generated scaffold during CI. The generated `android/` directory is not committed as a maintained platform project.

## What a green CI run proves — and what it does not

CI verifies source formatting, static analysis, automated tests, Android project generation/configuration and a debug APK build. It does not prove that streams play correctly on physical devices, that every TV remote works, that the app installs on a target television, or that the app is production-ready.

## Remaining work, kept separate by area

### A. Android project ownership
1. Review the exact Flutter-generated Android scaffold against the pinned Flutter toolchain.
2. Commit the complete, maintainable Android platform directory, including the Gradle wrapper JAR and scripts, Gradle configuration, manifest, resources and Kotlin entry point.
3. Keep machine-local files (for example `local.properties`), signing keys and credentials out of source control.
4. Verify a clean checkout can build without generating missing project files.

**Exit criterion:** a clean clone contains a complete Android project and builds the debug APK without `flutter create` mutating or generating tracked platform files.

### B. Android TV interaction
1. Audit focus ownership so media seeking does not swallow D-pad navigation events.
2. Implement deterministic focus traversal, visible focus indication and a usable Back/exit behavior.
3. Add widget tests for focus movement and remote-key behavior.
4. Validate on a physical Android TV device or emulator with a remote; document any unsupported keys.

**Exit criterion:** tested focus movement and player controls on a TV-sized interface, plus recorded device/emulator acceptance results.

### C. Playback reliability
1. Build a test matrix for authorized HLS, DASH and MP4 sample streams.
2. Cover loading, buffering, pause/resume, seek boundaries, unsupported formats, network loss, retry and controller disposal.
3. Record platform/plugin limitations; do not claim format support solely from a successful APK build.

**Exit criterion:** reproducible tests or documented device checks for each supported format and failure path.

### D. EPG and library quality
1. Measure parsing and search with large, representative XMLTV files.
2. Add efficient programme search and refresh behavior without blocking the UI.
3. Preserve deterministic channel matching: exact `tvg-id` first; name fallback only when unique.
4. Keep imports bounded and report malformed input safely.

### E. Security, privacy and release
1. Before enabling remote URL import, enforce HTTPS policy as appropriate, reject loopback/private/link-local destinations, validate every redirect, cap response size and enforce connection/read timeouts.
2. Review dependencies, licenses, permissions, diagnostics and privacy disclosures.
3. Keep signing credentials in protected CI secrets; never commit keystores or passwords.
4. Produce signed release artifacts and complete installation/upgrade/rollback checks on physical devices.

## Content rights

Use only streams that are owned, public-domain, explicitly licensed, or otherwise authorized for the intended use. A publicly reachable URL is not proof of retransmission rights. Do not bundle unlicensed channel lists.

## Release gate

Do not label the app production-ready until the Android project is reproducible from a clean clone, playback and TV acceptance checks are complete, security/privacy and content-rights reviews pass, and signed release artifacts are verified.
