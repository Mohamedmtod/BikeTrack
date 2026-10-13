---
trigger: glob
globs: "ios/**/*.swift, ios/**/*.plist, ios/**/*.entitlements"
description: "Rules for native iOS Swift code (Core Motion, Core Location, NFC, HealthKit)."
---
# iOS native rules
- Swift code cannot be compiled on Windows: mark it "uncompiled" in the report and list what must be verified on device.
- Write each sensor event to local storage immediately (write-ahead); do not rely on applicationWillTerminate (D-009).
- Never stop location updates completely while a trip is open in background; downgrade to lowPower (plan §6.3). Verify on device.
- NFC background reading: Universal Link only (D-008). Tap requires user to tap a notification.
- Do not assume background behavior. Unknowns go to "open questions".
- Add/modify Info.plist keys and entitlements only as listed in plan §11.
