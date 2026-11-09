# Production readiness — ArgentinoPlay IPTV Pro

## Integrated baseline

- Pull request #15 was squash-merged into `main`.
- Merge commit: `cbe7821302af21bf52ae854d92ffb8af0761bd10`.
- Post-merge GitHub Actions run #178 completed successfully: Android scaffold generation/configuration, Dart formatting, static analysis, automated tests, debug APK build and artifact upload.
- The merged Flutter client includes M3U/M3U8 and XMLTV parsing, local playlist/guide persistence, multi-playlist management, favorites/search/guide UI, player startup/retry race protection, bounded seeking and isolated remote-key mapping tests.
- The complete Flutter-generated `android/` platform scaffold is committed on the dedicated Android scaffold branch in PR #40, including Gradle wrapper files, manifest/resources and Kotlin entry point.
- Latest end-to-end clean-clone verification passed on GitHub Actions run [#42690457985](https://github.com/ElMatuu/ArgentinoPlay-IPTV-Pro/actions/runs/42690457985) for commit `46cc7693e2dc29e20602a6e6f39e2274107b4e6b`. Formatting, static analysis, automated tests, Android build, clean-checkout verification and debug APK upload all completed successfully.
- Verified debug APK artifact: `argentino-play-clean-checkout-debug-apk` (artifact ID `13703222217`, 83,708,787 bytes; approximately 83.7 MB). This is a CI debug artifact, not a signed release.
- The generated Android Gradle configuration intentionally leaves the release variant unsigned. The previous generated debug-keystore signing assignment has been removed; protected production signing is still required before any release.

## What a green CI run proves — and what it does not

CI verifies source formatting, static analysis, automated tests, Android project generation/configuration and a debug APK build. It does not prove that streams play correctly on physical devices, that every TV remote works, that the app installs on a target television, or that the app is production-ready.

## Remaining work, kept separate by area

### A. Android project ownership
**Status: completed on PR #40 branch; merge still pending.**

1. Generated and committed the Android platform directory with the pinned Flutter 3.47.9 toolchain, Gradle wrapper JAR/scripts, Gradle configuration, manifest, resources and Kotlin entry point.
2. Verified `namespace`, `applicationId` and Kotlin package are consistently `com.argentinoplay.app`.
3. Added Internet permission, Android TV Leanback launcher declaration and optional touchscreen feature.
4. Kept `android/local.properties`, IDE files and signing credentials out of the committed scaffold.
5. Passed a clean Git clone build without running `flutter create` in the clone; debug APK artifact uploaded by CI.

**Exit criterion:** met by successful clean-clone build in run #42665404448. PR #40 remains a draft and must be reviewed before merging; this does not constitute a signed release or physical-device acceptance.

### B. Android TV interaction
1. Audit focus ownership so media seeking does not swallow D-pad navigation events.
2. Implement deterministic focus traversal, visible focus indication and a usable Back/exit behavior. The player now maps Android GoBack, Escape and browser-back keys to route navigation, including while playback is loading or has failed.
3. Add widget tests for focus movement and remote-key behavior. Current unit tests cover select/enter/space/media toggle, play/pause, arrow and dedicated media seek keys, Back mappings, and ignored navigation keys. Seek calculation tests cover forward/backward offsets, zero/end clamping, invalid durations, and millisecond precision. A reusable TV button now exposes a 3 px focused outline and tests cover its focus styling and Tab traversal. Physical D-pad traversal on Android TV remains to be accepted.
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
3. The Android release variant is intentionally unsigned; it must never fall back to the debug keystore. Configure protected production signing before publishing.
4. Keep signing credentials in protected CI secrets; never commit keystores or passwords.
5. Produce signed release artifacts and complete installation/upgrade/rollback checks on physical devices.

## Content rights

Use only streams that are owned, public-domain, explicitly licensed, or otherwise authorized for the intended use. A publicly reachable URL is not proof of retransmission rights. Do not bundle unlicensed channel lists.

## Release gate

Do not label the app production-ready until the Android project is reproducible from a clean clone, playback and TV acceptance checks are complete, security/privacy and content-rights reviews pass, and signed release artifacts are verified.


Android TV focus: Home Material controls use a visible focus overlay; automated Down-key traversal coverage added. Physical Android TV/emulator acceptance remains pending.
