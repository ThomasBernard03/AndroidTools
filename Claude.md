# Android Tools - Project Documentation

## Project Overview

**Android Tools** is a cross-platform desktop application (Windows, Linux, macOS) built with Flutter that provides a comprehensive interface for managing Android devices. It serves as a lightweight alternative to Android Studio for common device management tasks.

The application allows users to:
- Browse and manage files on connected Android devices
- View detailed device information
- Install APK files
- Monitor device logs in real-time
- Track installation history

## Technology Stack

### Framework & Language
- **Flutter 3.41.6** - Cross-platform UI framework
- **Dart SDK ^3.10.8** - Programming language

### State Management & Architecture
- **flutter_bloc ^9.1.1** - BLoC pattern for state management
- **get_it ^9.2.0** - Dependency injection
- **rxdart ^0.28.0** - Reactive extensions

### Android Integration
- **adb_dart ^1.2.4** - ADB (Android Debug Bridge) integration
- **aapt_dart ^1.0.0** - Android Asset Packaging Tool integration

### Data & Storage
- **drift ^2.30.1** - SQLite database for local storage
- **drift_flutter ^0.2.8** - Flutter integration for Drift
- **shared_preferences ^2.3.4** - Key-value storage
- **dart_mappable ^4.6.1** - Data class code generation

### UI Components
- **flutter_svg ^2.2.3** - SVG rendering
- **bitsdojo_window ^0.1.6** - Custom window controls
- **desktop_drop ^0.7.0** - Drag and drop support
- **flutter_monaco ^1.4.0** - Monaco editor integration

### Features
- **sentry_flutter ^9.9.0** - Error tracking and monitoring
- **auto_updater ^1.0.0** - Automatic application updates
- **logger ^2.6.2** - Logging utilities

## Project Architecture

The project follows **Clean Architecture** principles with feature-based organization:

### Directory Structure

```
lib/
├── features/                    # Feature modules
│   ├── file_explorer/          # File browsing and management
│   │   ├── core/               # Module configuration
│   │   ├── data/               # Data layer (repositories)
│   │   ├── domain/             # Business logic (entities, use cases)
│   │   └── presentation/       # UI layer (BLoC, screens, widgets)
│   ├── information/            # Device information display
│   ├── application_installer/  # APK installation
│   ├── logcat/                 # Log viewer
│   ├── settings/               # App settings
│   └── home/                   # Main screen
└── shared/                      # Shared code across features
    ├── core/                    # Core utilities and constants
    ├── data/                    # Shared data sources and repositories
    ├── domain/                  # Shared domain entities and use cases
    └── presentation/            # Shared UI components
```

### Architectural Layers

Each feature follows a three-layer architecture:

1. **Presentation Layer**
   - BLoC (Business Logic Component) for state management
   - UI screens and widgets
   - Event and state definitions

2. **Domain Layer**
   - Entities (business models)
   - Use cases (business logic)
   - Repository interfaces

3. **Data Layer**
   - Repository implementations
   - Data sources (local, shell/ADB)
   - Data models and mappers

## Key Features

### 1. File Explorer
**Location:** `lib/features/file_explorer/`

- Browse Android device file system
- Preview files (images, text)
- Upload/download files via drag & drop
- Create/delete directories
- File metadata viewing

**Key Files:**
- [file_explorer_bloc.dart](lib/features/file_explorer/presentation/file_explorer_bloc.dart) - Main state management
- [file_repository.dart](lib/features/file_explorer/domain/repositories/file_repository.dart) - Repository interface
- [file_preview_screen.dart](lib/features/file_explorer/presentation/file_preview/file_preview_screen.dart) - File preview UI

### 2. Device Information
**Location:** `lib/features/information/`

- Display Android version and device model
- Show battery status
- Display storage information
- Network details
- Visual device preview

**Key Files:**
- [information_bloc.dart](lib/features/information/presentation/information_bloc.dart)
- [get_device_information_usecase.dart](lib/features/information/domain/usecases/get_device_information_usecase.dart)

### 3. Application Installer
**Location:** `lib/features/application_installer/`

- Install APK files
- Batch installation support
- Installation history tracking (stored in local database)

**Key Files:**
- [application_installer_bloc.dart](lib/features/application_installer/presentation/application_installer_bloc.dart)
- [install_application_usecase.dart](lib/shared/domain/usecases/install_application_usecase.dart)

### 4. Logcat Viewer
**Location:** `lib/features/logcat/`

- Real-time log streaming
- Filter by process, tag, and log level
- Color-coded log levels
- Clear logs functionality

**Key Files:**
- [logcat_bloc.dart](lib/features/logcat/presentation/logcat_bloc.dart)
- [listen_logcat_usecase.dart](lib/features/logcat/domain/usecases/listen_logcat_usecase.dart)

### 5. Settings
**Location:** `lib/features/settings/`

- Theme configuration (light/dark mode)
- Application preferences
- Persistent settings storage

## Data Persistence

### Local Database (Drift/SQLite)
**Location:** [lib/shared/data/datasources/local/app_database.dart](lib/shared/data/datasources/local/app_database.dart)

Tables:
- `install_history` - APK installation history
- `app_settings` - Application configuration

### Shared Preferences
**Location:** [lib/shared/data/helpers/settings_helper_shared_pref_impl.dart](lib/shared/data/helpers/settings_helper_shared_pref_impl.dart)

Used for lightweight key-value storage of user preferences.

## Development Workflow

### Code Generation
The project uses code generation for:
- Drift database tables
- Dart Mappable classes

Run code generation after modifying models or database schemas:
```bash
fvm dart run build_runner build -d
```

### Running the Application
```bash
# Standard run
fvm flutter run

# With Sentry error tracking
fvm flutter run --dart-define=SENTRY_DSN=your_sentry_dsn
```

### Building for Release

**macOS:**
```bash
fvm flutter build macos \
  --dart-define=SENTRY_DSN=your_sentry_dsn \
  --obfuscate \
  --split-debug-info=build/debug-info
```

**Windows (MSIX):**
The project uses the `msix` package for Windows packaging.
Configuration is in [pubspec.yaml](pubspec.yaml) under `msix_config`.

### Prerequisites
- **ADB** must be installed and available in system PATH
- **USB Debugging** must be enabled on the target Android device
- Flutter 3.41.6 (managed via FVM)

## Module System

The project uses dependency injection modules for each feature:

- `file_explorer_module.dart` - File explorer dependencies
- `information_module.dart` - Device information dependencies
- `logcat_module.dart` - Logcat dependencies
- `shared_module.dart` - Shared dependencies

All modules are registered using GetIt for service location.

## Theme System

**Location:** [lib/shared/presentation/themes.dart](lib/shared/presentation/themes.dart)

The application supports both light and dark modes with custom color schemes and typography using the "Nothing" font family.

## Error Handling & Monitoring

- **Sentry** integration for crash reporting and performance monitoring
- Configured in [sentry.dart](pubspec.yaml) (org: thomas-bernard, project: android-tools)
- Debug symbols are uploaded during release builds

## Assets

The application includes:
- Android version images (`assets/android_versions/`)
- Device preview images (Pixel devices in `assets/pixels/`)
- File type icons (`assets/images/file_extensions/`)
- Folder icons (`assets/images/folder/`)

## Version Management

- Current version: **2026.02.3+29**
- Versioning format: `YYYY.MM.PATCH+BUILD_NUMBER`
- Auto-update support via `auto_updater` package
- Update feed configured via `AUTO_UPDATER_FEED_URL` dart-define

## Common Commands

### Clean and rebuild
```bash
fvm flutter clean && fvm flutter pub get && fvm dart run build_runner build -d
```

### Run tests
```bash
fvm flutter test
```

### Format code
```bash
fvm dart format .
```

### Analyze code
```bash
fvm flutter analyze
```

## Important Notes for Development

1. **Never modify generated files** (files ending in `.g.dart` or `.mapper.dart`)
2. **Always run code generation** after changing database schemas or mappable classes
3. **Use BLoC pattern** for all state management - avoid setState in complex widgets
4. **Follow clean architecture** - keep layers separated (presentation → domain → data)
5. **Use dependency injection** - register services in module files
6. **Test with real Android devices** - ADB connection required for all features

## Git Workflow

- Main branch: `main`
- Development branch: `dev`
- Feature branches: `feature/feature-name`

The project includes GitHub Actions for automated builds and releases (`.github/workflows/release.yml`).

## Future Roadmap

- Real-time device connection/disconnection detection
- Live SQL database viewer
- Stack similar logcat lines (VSCode-style)
- Full Windows and Linux support
- Screen mirroring capability

## Troubleshooting

### ADB Issues
- Ensure ADB is in system PATH
- Verify USB debugging is enabled
- Try running `adb devices` in terminal to verify connection

### Build Issues
- Run `fvm flutter clean` and regenerate code
- Check Flutter version matches required version (3.41.6)
- Verify all dependencies are properly installed

### Performance
- Logcat filtering happens in real-time - large log volumes may impact performance
- File operations are asynchronous to prevent UI blocking
- Database queries are optimized with indexes
