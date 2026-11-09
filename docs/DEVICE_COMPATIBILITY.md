# Device compatibility and support policy

## Purpose

ArgentinoPlay IPTV Pro aims for broad, dependable compatibility. "Android", "Smart TV" or a screen size alone is not proof that a device is supported. Compatibility is established by OS version, CPU/ABI, available media decoders, remote/input behavior, display characteristics, network behavior and repeatable installation/playback tests.

No software project can guarantee operation on every model ever sold or permanent compatibility for the lifetime of every device. This document defines how support claims are earned and maintained.

## Current verified baseline

- The application is currently a Flutter application with an Android build path.
- The Android scaffold configures package ID `com.argentinoplay.app`, compile SDK 36, Java 17, Internet permission, optional Leanback support and optional touchscreen support.
- The Gradle template currently uses Flutter's `flutter.minSdkVersion` and `flutter.targetSdkVersion`; the effective values must be recorded from the actual build before publishing an OS compatibility claim.
- CI has built a debug APK from a clean checkout. This proves the build pipeline, not installation or playback on every physical device.
- Android TV focus/navigation widget tests are automated; physical remote-control acceptance is still outstanding.
- Current dependencies include Flutter `video_player`, file picker, shared preferences and XML parsing. Platform-specific plugin support must be verified before enabling another platform.

## Platform status

| Platform family | Current status | What is needed before claiming support |
|---|---|---|
| Android phones | Build target; physical-device matrix pending | Install/upgrade, touch UI, portrait/landscape, audio/video, background/resume, import permissions, ABI and OS coverage |
| Android tablets | Build target; physical-device matrix pending | Phone checks plus large-screen layouts, split/multi-window and density/scaling |
| Android TV / Google TV | Leanback launcher and D-pad work in progress | Physical remote acceptance, focus visibility/traversal, Back, overscan/safe areas, launcher discovery and playback |
| Android TV boxes / AOSP boxes | Not universally verified | Per-vendor Android version, ABI, DRM/decoder capability, remote mapping, sideload/install and HDMI/audio checks |
| Amazon Fire TV / Fire OS | Not yet certified | Fire OS compatibility review, app distribution/install route, remote and media playback checks |
| iPhone / iPad | Not implemented/verified as a release target | iOS build, plugin availability, signing, file import, playback and device testing |
| Apple TV / tvOS | Not implemented/verified | Separate tvOS-capable app architecture and playback/input validation |
| Samsung Tizen / LG webOS | Not supported by this Android APK | Separate native/webOS/Tizen application and certification/testing |
| Roku and other proprietary TV systems | Not supported by this Android APK | Separate platform implementation and store/device certification |
| Web / Windows / macOS / Linux | Not currently release-verified | Platform-specific builds, browser/desktop playback and import testing |

A single Android APK cannot be installed directly on Tizen, webOS, Roku, iOS or tvOS. Android-based televisions and boxes may still differ in ABI, OS version, codecs, firmware and remote behavior.

## Android compatibility qualification matrix

Before a release, test at least these device classes:

1. Android phone: low-memory/entry-level and current mainstream device.
2. Android tablet: one compact and one large-screen device.
3. Android TV / Google TV: one certified TV or streaming device with a physical D-pad remote.
4. Android TV box: one mainstream certified box and, separately, any generic/AOSP box explicitly listed as supported.
5. Fire TV: only after a Fire OS build/install/playback check.

For each test record:
- manufacturer, exact model and hardware revision;
- Android/Fire OS version and API level;
- CPU ABI (arm64-v8a, armeabi-v7a, x86_64 where relevant);
- RAM, display resolution/density and available storage;
- installation route and APK/build version;
- remote/input type and key mapping;
- media container, codec, resolution, frame rate and audio codec;
- network type and test result;
- startup, playback, seek, pause/resume, background/foreground and recovery results;
- known defects and date last tested.

Do not mark a model as supported from emulator-only results. Label emulator results separately.

## Playback compatibility policy

A stream URL being reachable does not guarantee that the device can decode it. HLS, DASH, MP4, codecs, containers, DRM, captions, audio passthrough and hardware decoder limits vary by Android version, vendor firmware and device hardware.

Maintain a test set containing only owned, public-domain or explicitly authorized media. Include representative HLS and MP4 sources first; add DASH/DRM only when the required plugin, license and device support have been verified. Report unsupported codecs clearly and never promise universal playback.

## Installation and release channels

- Debug APKs are for internal testing only; they are not production releases.
- A release must be signed with protected release credentials, versioned, checksummed and tested as both a clean install and an upgrade from the prior supported version.
- Publish separate install guidance for Google Play/Android TV, managed distribution and sideloading where permitted.
- Prefer Android App Bundles for store distribution; provide APK variants only when there is a controlled and documented reason.
- Keep a rollback path and publish release notes, minimum OS/API, ABI coverage and known limitations.
- Do not ship credentials, private playlist URLs or unlicensed channel catalogs in the app.

## Long-term support and maintenance

"Lifetime support" cannot be guaranteed. The maintainable commitment is:
- publish a support policy and end-of-support dates for each major release;
- monitor Flutter, Android Gradle Plugin, Kotlin, Java and media plugin security updates;
- run CI on supported toolchains and dependency updates;
- keep a device regression matrix and rerun it for player, plugin, target SDK and release changes;
- provide a documented issue-reporting path that excludes passwords, tokens and private stream URLs;
- preserve migration, backup and rollback procedures for user playlists, favorites and EPG data.

## Release gate

Do not claim universal compatibility or production readiness. A device/platform may be listed as supported only after a reproducible build, successful install/upgrade, UI/input checks and authorized-media playback checks have been recorded for its declared version and model family.
