# Device acceptance test record

Use one copy of this record for each physical device. A CI build is not a substitute for these tests. Do not mark a device as supported until every required case has a recorded result.

## Device identity

- Test date (UTC):
- Tester:
- Manufacturer and exact model:
- Device class: phone / tablet / Android TV / Google TV / TV box / Fire TV
- Android or Fire OS version:
- Android API level:
- CPU ABI:
- RAM:
- Display resolution and density:
- Installation method: debug APK / signed release APK / store
- App version and commit SHA:
- Network: Wi-Fi / Ethernet / mobile; measured download and latency:
- Remote/input: touchscreen / D-pad remote / mouse / keyboard / gamepad

## Required installation and startup checks

| ID | Check | Expected result | Result / evidence |
|---|---|---|---|
| INS-01 | Install cleanly on supported OS | Install completes without package/signature errors | |
| INS-02 | First launch | Home screen appears; no crash or indefinite loading | |
| INS-03 | Relaunch after force-stop | App opens and local library remains intact | |
| INS-04 | Upgrade from previous signed build | User data is retained; upgrade completes | |

## Library and guide checks

| ID | Check | Expected result | Result / evidence |
|---|---|---|---|
| LIB-01 | Import a small authorized M3U and M3U8 file | Valid HTTP/HTTPS entries appear; malformed entries are safely ignored | |
| LIB-02 | Search and switch Canales/Favoritos/Programación | Results and focus/selection remain usable | |
| LIB-03 | Restart after importing a playlist | Active playlist and favorites persist | |
| EPG-01 | Import a valid XMLTV guide | Channels and programme schedule appear | |
| EPG-02 | Load a malformed or oversized guide | Clear error; app remains usable | |

## Playback checks

Only use streams that the tester owns, operates, or is explicitly authorized to test.

| ID | Check | Expected result | Result / evidence |
|---|---|---|---|
| PLAY-01 | Start an authorized HLS stream | Video and audio start; loading state ends | |
| PLAY-02 | Pause and resume | Playback state follows the command | |
| PLAY-03 | Seek backward/forward | Position changes within media bounds | |
| PLAY-04 | Temporary network loss and recovery | App reports/retries safely; no permanent frozen screen | |
| PLAY-05 | Unsupported codec or unavailable stream | Readable error and retry/return path; no crash | |
| PLAY-06 | Background and foreground app | Playback follows the documented lifecycle policy | |
| PLAY-07 | Exit player and start another channel | Previous controller is released; new channel can start | |

## TV remote and accessibility checks

Complete on a physical TV or box with its normal remote, not only with widget tests.

| ID | Check | Expected result | Result / evidence |
|---|---|---|---|
| TV-01 | Navigate all home actions using D-pad only | Every action can receive visible focus and be activated | |
| TV-02 | Move focus through channel list | Focus order is predictable; selected item is visible | |
| TV-03 | Open and operate player controls | Play/pause, seek and retry are reachable with remote | |
| TV-04 | Press Back from player and dialogs | Returns to the expected previous screen without trapping focus | |
| TV-05 | Reconnect or replace remote | App remains operable using standard Android TV input events | |

## Stability and release checks

- Run a continuous authorized stream for at least 30 minutes; record stalls, heat, battery/power, and memory symptoms:
- Repeat start/stop across at least 10 channels:
- Rotate phone/tablet where supported:
- Test low-bandwidth and high-latency network:
- Verify app permissions and privacy disclosures:
- Verify signed release installation, upgrade, and rollback:
- Attach logs/screenshots or issue links:
- Defects and severity:
- Overall result: PASS / FAIL / BLOCKED
- Reviewer and review date:

## Qualification rule

A device is **qualified** only when all required tests pass on the recorded model, OS version, app version, and input method. A pass on one device does not certify every model in its product family. Record failures as unsupported or blocked; never convert missing evidence into a pass.
