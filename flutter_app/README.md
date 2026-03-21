# BoxRFID – Flutter Android App

A Flutter Android app for reading and writing RFID tags for the QIDI Box filament storage system.

## Overview

This is the Android companion app for BoxRFID. It uses your Android device's built-in NFC reader to:
- **Write** filament metadata (material, color, manufacturer) to MIFARE Classic RFID tags
- **Read** existing tag data from QIDI Box tags
- **Auto-detect** tags automatically when held to the device

## Requirements

- Android 5.0 (API 21) or later
- A device with **NFC hardware** (the app will still install on non-NFC devices but NFC features won't be available)
- NFC enabled in device settings
- The tag must be a **MIFARE Classic** tag (as used by the QIDI Box)

## Building

### Prerequisites

- Flutter SDK 3.22+
- Android Studio / Android SDK
- A connected Android device or emulator (emulators do not support NFC)

### Steps

```bash
cd flutter_app
flutter pub get
flutter run
```

To build a release APK:

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Features

- **Material selector** – choose from standard QIDI materials or add your own
- **Color grid** – select from 24 filament colors
- **Manufacturer selector** – optional, toggleable in Settings
- **Write tag** – writes selected material/color/manufacturer to a MIFARE Classic block 4
- **Read tag** – reads and displays tag content
- **Auto-detect** – continuously reads tags as they are presented
- **Settings**:
  - Language: German, English, Spanish, Portuguese, French, Chinese
  - Custom materials (add / edit / delete)
  - Custom manufacturers (add / edit / delete)
  - General preferences

## Tag Format

The app reads/writes data to **block 4** of a MIFARE Classic 1K tag:

| Byte | Content          | Notes                    |
|------|------------------|--------------------------|
| 0    | Material code    | See defaults.dart        |
| 1    | Color code       | 1–24 per color grid      |
| 2    | Manufacturer code| 0 = Generic, 1 = QIDI    |
| 3–15 | Reserved (zero)  |                          |

Authentication uses key `D3:F7:D3:F7:D3:F7` (QIDI vendor key) with fallback to `FF:FF:FF:FF:FF:FF`.

## NFC Compatibility Note

MIFARE Classic support on Android depends on the NFC chipset in your device. Most modern Android phones support MIFARE Classic, but some (notably many Google Pixel devices and some Samsung models) do not. If your device does not support MIFARE Classic, you will see an error message.

## License

CC BY-NC-SA 4.0 – See [LICENSE](../LICENSE)
