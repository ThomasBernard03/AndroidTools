# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
fvm flutter run

# Run with optional integrations
fvm flutter run \
  --dart-define=SENTRY_DSN=your_dsn \
  --dart-define=AUTO_UPDATER_FEED_URL=your_feed_url

# Code generation (required after modifying Drift tables or @MappableClass models)
fvm dart run build_runner build -d

# Clean rebuild
fvm flutter clean && fvm flutter pub get && fvm dart run build_runner build -d

# Tests
fvm flutter test
fvm flutter test test/path/to/specific_test.dart

# Lint / format
fvm flutter analyze
fvm dart format .

# Build macOS release
fvm flutter build macos \
  --dart-define=SENTRY_DSN=your_dsn \
  --obfuscate \
  --split-debug-info=build/debug-info
```

## Environment Variables (dart-define)

| Key | Purpose |
|-----|---------|
| `SENTRY_DSN` | Sentry crash reporting DSN |
| `AUTO_UPDATER_FEED_URL` | Sparkle/auto-updater feed URL |
| `GIT_REPOSITORY_URL` | Link to the repository (shown in UI) |
| `ISSUE_URL` | Link to bug tracker (shown in UI) |

All four are optional at runtime; missing values produce warnings in the log.

## Architecture

### Dependency Injection

`getIt` (GetIt instance) is a package-level global defined in `lib/main.dart`. Every feature registers its own dependencies in a `*Module.configureDependencies()` static method called from `main()`. Modules must be registered before `await getIt.allReady()`.

### Feature Structure

Each feature under `lib/features/` follows clean architecture:

```
feature/
├── core/          # Module registration + feature-specific extensions
├── data/          # Repository implementations, data sources
├── domain/        # Entities, repository interfaces, use cases
└── presentation/  # BLoC (events/states), screens, widgets
```

Shared cross-feature code lives in `lib/shared/` with the same layer breakdown.

### BLoC Pattern

All state management uses `flutter_bloc`. BLoCs are provided via `BlocProvider` in the widget tree. The root-level `SettingsBloc` (theme mode) is provided in `MyApp` — it is the only BLoC not registered through a module.

### ADB / AAPT Paths

For release builds, `adb` and `aapt` binaries are bundled inside the app bundle (macOS: `Contents/Resources/`, Windows: next to the exe). `lib/shared/core/constants.dart` resolves the path at runtime based on `Platform.resolvedExecutable`. During development, ensure `adb` is in your PATH or the bundled binary is present.

### Generated Files

Never edit files ending in `.g.dart` or `.mapper.dart`. Regenerate with `build_runner` after:
- Modifying a `@DriftDatabase` table or DAO
- Adding/changing a `@MappableClass` annotated model

### Database

`AppDatabase` (Drift/SQLite) is a lazily-registered singleton in `SharedModule`. Tables: `install_history`, `app_settings`.
