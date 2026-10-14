# T-012 Runbook — iOS Auto-Start Feasibility Probe

This runbook guides the owner through building, installing via SideStore (free Apple ID, no Mac), and running the T-012 feasibility probe on iPhone.

---

## 1. Prerequisites
- Target device: iPhone with iOS 17+ (or iOS 18+)
- Free Apple ID configured with SideStore and WireGuard (SideStore VPN)
- Codemagic connected to GitHub repository `Mohamedmtod/BikeTrack`

---

## 2. Codemagic Build (Unsigned IPA)
1. Navigate to Codemagic dashboard for `BikeTrack`.
2. Start a new build on branch `spike/t-012a-probe-shell` (or merged spike branch).
3. Select workflow: **`ios-probe-unsigned`** (`iOS Probe Unsigned IPA`).
4. Wait for build completion (< 10 minutes on `mac_mini_m2`).
5. Verify build log:
   - Check step **`Verify Info.plist keys`**: confirm `UIBackgroundModes` (`location`), `CFBundleURLTypes` (`biketrack`), `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`, and location usage strings are printed in the log.
6. Under Build Artifacts, download **`BikeTrackProbe.ipa`**.

---

## 3. SideStore Installation
1. Transfer `BikeTrackProbe.ipa` to iPhone (via iCloud Drive, AirDrop, or local server).
2. On iPhone, connect the **SideStore WireGuard VPN**.
3. Open **SideStore**:
   - Go to **My Apps** tab.
   - Tap **+** (top left).
   - Select `BikeTrackProbe.ipa`.
4. Wait for SideStore to sign the bundle (`com.mohamedmtod.biketrack`) using your free developer certificate and install it.
5. If prompt asks to keep app extensions, remember this probe uses no extensions.

---

## 4. App Launch & Verification (Gate G1)
1. Tap **BikeTrack Probe** icon on the home screen.
2. Confirm the UI renders:
   - Header: `BikeTrack Probe`
   - Build: `1.0.0+1`
   - Body: `Probe shell OK`
3. Check iOS Settings:
   - Open **Settings > Privacy & Security > Location Services > BikeTrack Probe**.
   - Verify location permission options are available ("While Using the App" / "Always").
4. Check Files App:
   - Open iOS **Files** app > **On My iPhone**.
   - Verify **BikeTrack Probe** folder is present (enabled by `UIFileSharingEnabled` / `LSSupportsOpeningDocumentsInPlace`).
5. Return to SideStore:
   - Refresh the app manually to ensure resign and refresh work cleanly.

---

## 5. Overview of Test Gates (T-012 Matrix)
- **G1 (Part A)**: Build unsigned IPA, install via SideStore, launch shell, refresh app successfully.
- **G2 (Part B)**: In-app Start + 30-minute pocket ride with screen locked.
- **G3 (Part B)**: Shortcuts App Intent execution manually (app open / background / locked).
- **G4 (Part B)**: NFC Shortcuts Personal Automation ("Don't Ask Before Running", unlocked / lock-screen lit / screen off).
- **G5 (Part B)**: iOS-killed app state recovery on next location event / intent.
- **G6 (Part B)**: 7-day SideStore refresh keeps intent and probe log data intact.
- **T-012H (Later)**: HealthKit write authorization under free certificate SideStore signing.
