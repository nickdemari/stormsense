# Contributing to StormSense

Thanks for your interest in contributing! StormSense is a Raspberry Pi weather station with a Flutter companion app. Here's how to get involved.

## Project Structure

```
stormsense/
├── stormsense-pi/    # Python — runs on the Raspberry Pi
│   ├── storm_sense/  # Source code
│   └── tests/        # pytest tests
├── storm_sense/      # Flutter — companion mobile app
│   ├── lib/          # Dart source code
│   └── test/         # Flutter tests
└── docs/             # Documentation
```

## Development Setup

### Raspberry Pi (Python)

```bash
cd stormsense-pi
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m pytest tests/
```

> **Note:** The `rainbowhat` library only works on a Raspberry Pi with the Rainbow HAT attached. Tests mock the hardware, so you can run them anywhere.

### Flutter App

```bash
cd storm_sense
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run
```

Requires Flutter SDK 3.11+.

## Making Changes

1. Fork the repo and create a branch from `main`
2. Make your changes
3. Run the relevant test suite (see above)
4. Open a PR with a clear description of what and why

## Code Style

- **Python:** Follow PEP 8. Use type hints. Target Python 3.7+ compatibility (`from __future__ import annotations`).
- **Flutter/Dart:** Follow the default `analysis_options.yaml`. Use BLoC pattern for state management. Run `dart run build_runner build` after modifying Freezed models.

## What to Work On

Check the [Issues](https://github.com/nickdemari/stormsense/issues) tab for open tasks. Issues labeled `good first issue` are a great starting point.

## Reporting Bugs

Use the [Bug Report](https://github.com/nickdemari/stormsense/issues/new?template=bug_report.md) template. Include which component is affected (Pi, App, or both) and steps to reproduce.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
