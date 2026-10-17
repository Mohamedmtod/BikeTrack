# STATUS — BikeTrack

- T-020 UI correction on its task branch: Ride/History/Debug navigation, plain-language live status and actions, readable saved-ride cards and details.
- Route and distance still derive from projected GPS only; gaps remain disconnected. Debug retry, raw evidence and local diagnostic export remain available.
- `dart format .` completed, `flutter analyze` clean, full `flutter test` passed for UI work; native iOS MapKit/device behavior requires owner verification.
- Separate manual `iOS App Unsigned IPA` workflow packages the root app as `BikeTrack.ipa`; actual Codemagic build remains owner-run.
