# PROJECT_BRIEF — BikeTrack

## Goal
Record bike trips accurately on iPhone, separate them from walking and vehicles,
never add phantom distance, and mark anything uncertain for review.

## Primary success criterion (v1)
Zero phantom distance (standing still / forgotten trip / resume after stop).
Accuracy, classification and battery targets are set AFTER measurement (plan §16).

## In scope (M0–M5)
- Activity detection (Core Motion), GPS for cycling only, optional NFC start confirmation,
  manual start/stop always available, trip state machine (pause / review / auto-close),
  local SQLite + CSV export, manual correction, HealthKit cycling workouts (last).

## Out of scope (for now)
BLE wheel sensor, Apple Watch, cloud sync/accounts, Android.

## Constraints
- Developer on Windows; iOS build/sign via macOS access decided in M0.
- Target device: iPhone 14 Pro. iOS 16+ (prefer 17+).
- No paid subscription before M0 gate is resolved.
