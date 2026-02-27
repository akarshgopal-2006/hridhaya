# Hridhaya (Flutter Frontend Prototype)

This folder contains a Flutter UI prototype implementing:
- Safety Loop (auto-thud trigger + 30s countdown + max vibration + “I’M OK” cancel)
- Digital Stethoscope (gyro-based “listening” + waveform + 15s analysis progress)
- Bystander Command Center (post-SOS guidance + CPR metronome 100–120 BPM)
- Hridhaya Dashboard (Cardiac Risk Index ring + hold-to-SOS + connection chips)
- Settings & Privacy (monitoring toggles + Delete My Health Data)

## Run locally

1. Install Flutter: see the official docs.
2. From **this** directory:

```bash
flutter pub get
flutter run
```

If you want full platform folders (android/ios/web), you can also do:

```bash
flutter create .
```

Then re-apply the `lib/` contents in this repo folder (they’re the “app frontend”).

## Notes
- The “thud” detector uses accelerometer magnitude spikes (best-effort heuristic).
- “Max vibration” is best-effort and depends on device OS + permissions.
