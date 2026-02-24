# StormSense Flutter App

Companion app for the [StormSense](../README.md) Raspberry Pi weather station.

## Features

- **Dashboard** — Live temperature, pressure, and storm level from your Pi
- **History** — 24-hour pressure and temperature charts with time range filtering
- **Notifications** — Local push alerts when storm level escalates to Warning or Severe
- **Settings** — Temperature units (F/C), pressure units (hPa/inHg), poll interval

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run
```

Requires Flutter SDK 3.11+.

## Architecture

- **State management:** flutter_bloc
- **HTTP client:** Dio
- **Charts:** fl_chart
- **Code generation:** Freezed + json_serializable
- **Routing:** GoRouter
- **Persistence:** SharedPreferences

Each feature follows the BLoC pattern with a `bloc/` directory for events, states, and the BLoC itself, and a `view/` directory for widgets.
