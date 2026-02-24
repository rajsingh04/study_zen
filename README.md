# study_zen

A cross-platform Flutter application scaffolded for mobile, web, and desktop targets.

## Overview

`study_zen` is a Flutter project prepared for Android, iOS, web, macOS, Linux, and Windows.
It contains the standard Flutter app structure and a minimal starter UI under `lib/` so you can
use this workspace as a base for building study tools, learning aids, or productivity apps.

## Features

- Cross-platform Flutter setup (Android, iOS, web, macOS, Linux, Windows)
- Organized project layout with platform projects in the repo
- Asset folder for images and static files

## Prerequisites

- Flutter SDK (stable). Install instructions: https://docs.flutter.dev/get-started/install
- Android Studio / Xcode (for Android and iOS development respectively)
- For desktop targets, follow Flutter's platform-specific setup guides

## Quick start

1. Install dependencies:

```bash
flutter pub get
```

2. Run the app on a connected device or simulator/emulator:

```bash
flutter run -d <device-id>
```

To list available devices:

```bash
flutter devices
```

## Build

- Android APK:

```bash
flutter build apk --release
```

- iOS (requires macOS + Xcode):

```bash
flutter build ios --release
```

- Web:

```bash
flutter build web
```

## Tests & Analysis

- Run unit/widget tests:

```bash
flutter test
```

- Static analysis:

```bash
flutter analyze
```

## Project structure (key paths)

- `lib/` — Dart source, entrypoint is `lib/main.dart`.
- `assets/` — images and other static assets used by the app.
- `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/` — platform-specific projects.
- `test/` — automated tests.

## Assets

Place images under `assets/images/` and declare them in `pubspec.yaml` before use.

## Contributing

Contributions are welcome. Typical workflow:

```bash
git checkout -b feature/your-feature
# make changes
flutter pub get
flutter test
```

Create a PR describing the changes and any manual testing steps.

## Notes

- This README is a starting point — update it to describe the app's purpose, architecture, and
  any third-party services or environment variables your project requires.


