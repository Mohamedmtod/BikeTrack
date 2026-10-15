# T-012 Runbook — iOS Auto-Start Feasibility Probe

This runbook guides the owner through building, installing with AltStore/AltServer on Windows, and recording honest G1–G6 evidence on an iPhone.

## 1. Prerequisites

- Target device: iPhone with iOS 17+ (or iOS 18+ for the guarded service-session experiment).
- Windows PC with AltServer and AltStore configured using a free Apple ID.
- iPhone and Windows PC on the same Wi-Fi network for AltServer refreshes.
- Codemagic connected to GitHub repository `Mohamedmtod/BikeTrack`.
- A Shortcuts-compatible NFC tag for G4.

## 2. Codemagic build (unsigned IPA)

1. In Codemagic, start `ios-probe-unsigned` on `spike/t-012b-native-probe`.
2. Wait for the macOS build and download `BikeTrackProbe.ipa` from its artifacts.
3. Confirm **Verify Info.plist keys** prints `UIBackgroundModes` (`location`), `CFBundleURLTypes` (`biketrack`), file sharing keys, and both location-use strings.
4. Treat a successful IPA build as native compilation/project-integration evidence only; it does not prove permission behavior, GPS, Shortcuts, notifications, or locked-device persistence.

## 3. AltStore installation and refresh

1. Install `BikeTrackProbe.ipa` with AltStore on the iPhone using the configured free Apple ID.
2. Open the installed **BikeTrack Probe** app once while unlocked.
3. Keep AltServer running on the Windows PC and leave both devices on the same Wi-Fi network.
4. In AltStore, refresh the app before its seven-day signing window expires. Record the refresh date and any failure message.
5. The probe has no app extensions; do not interpret successful installation as evidence that either App Intent works.

## 4. Evidence handling

- Use the probe screen’s **Clear log** before every independent run. It replaces the active `probe_log.jsonl`; sequence numbers are monotonic within that file.
- After each run, use **Share log** or Files > On My iPhone > BikeTrack Probe to export `probe_log.jsonl`.
- Save one exported file per condition, named with the gate, date, iOS version, and lock state.
- On Windows, analyze each export with:

  ```powershell
  cd probes/ios_autostart
  dart run tool/analyze_log.dart path\to\probe_log.jsonl
  ```

- Record malformed lines, first-fix latencies, fix and receive-time gaps, accepted/rejected ratio, invalid success notifications, and recovery attempts exactly as reported.

## 5. Gate procedures

### G1 — install, launch, and refresh

1. Launch the app from the Home Screen.
2. Confirm the diagnostic screen shows native status and a log tail, not merely a Flutter frame.
3. In Settings > Privacy & Security > Location Services > BikeTrack Probe, confirm location choices appear.
4. In Files > On My iPhone, confirm the BikeTrack Probe folder is visible.
5. Refresh through AltStore while AltServer and the iPhone are on the same Wi-Fi. Export the log.

### G2 — in-app start and pocket ride

1. Clear the log, grant **When in use**, then **Always**, then notifications from the diagnostic screen/settings.
2. Tap **Start ride** and wait for the success notification only after an accepted-fix entry appears.
3. Put the phone in a pocket, lock it, and ride or walk for 30 minutes.
4. Stop the ride, export the log, and run the analyzer.
5. Record the first accepted-fix latency and each `fix_ts_ms` / `recv_ms` gap over 30 seconds. A visible notification alone is not a pass.

### G3 — Shortcuts App Intents

1. Open Shortcuts and find both **Start Ride** and **Start Background Ride** from BikeTrack Probe.
2. Run each variant separately with the app open, app not running, and phone locked.
3. For every condition, clear/export/analyze separately and record whether `intent_invoked`, `start_requested`, an accepted `fix`, and the corresponding notification appear.
4. A background intent with no connected scene or Flutter UI is the intended experiment; failure is valid evidence, not a reason to substitute the foreground intent.

### G4 — NFC personal automation

1. Create a Shortcuts personal automation triggered by the NFC tag.
2. Add the selected BikeTrack Probe App Intent action and enable **Run Immediately** / disable confirmation where iOS offers it.
3. Test foreground and background intent variants under: unlocked, lock screen lit, and screen off.
4. For each condition, tap once, do not manually open the app, then export and analyze the log.
5. Record the exact iOS prompt/automation behavior if iOS refuses unattended execution.

### G5 — killed-app recovery

1. Start a ride and verify an accepted fix is logged.
2. Force-quit the app from the app switcher, then use the chosen location/intent trigger condition.
3. Reopen only to export evidence after the condition has had time to run.
4. Record `launch`, `recovery_attempt`, authorization state, later fixes, and any absence of recovery. Do not claim an iOS relaunch occurred without these entries.

### G6 — seven-day refresh and retained data

1. Preserve a probe log and create/verify both App Shortcuts.
2. Refresh via AltStore and AltServer on the same Wi-Fi before expiry, then repeat after the relevant refresh interval.
3. Confirm the log remains available in Files and record whether intents remain visible and executable.
4. Export/analyze a post-refresh run. Record refresh failures separately from intent/GPS failures.

## 6. Device-only checks

Windows verification covers Dart formatting, analyzer tests, and Flutter tests. Codemagic must compile the Swift sources and validate the Xcode project. Only device runs can establish location/notification authorization, App Intent visibility and execution without a scene, locked/background GPS persistence, recovery, NFC automation, AltStore refresh, and Files export.
