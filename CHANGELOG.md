# Changelog

All notable changes to Android Tools will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),


## [2026.04.1] - 2026-04-25

### New Features
- **APK Inspector** - Analyse APK files without installing them: view metadata, permissions, manifest, components, and signatures
- APK Inspector keeps a history of recently inspected APK files

### Improvements
- New application design (home screen, navigation rail, information screen, logcat)
- Redesigned device information screen with stat cards (battery, storage, RAM…)
- Display Android version logo on the information screen
- Update flutter version to 3.41.6
- Add light mode
- Can preview PDF
- Can take screenshots
- Can disable crash reporting
- Refresh devices when app is resumed

### Removed
- Application Installer feature (superseded by APK Inspector)

### Distribution
- New dark gradient background for the macOS DMG installer


## [2026.02.3] - 2026-02-10

### Improvements
- Can download file from preview
- Can delete file from preview

### Fixs
- Fix selected text color in file explorer

## [2026.02.2] - 2026-02-08

### Fixs
- Fix search in file explorer
- Fix upload in private app directory
- Filx delete file in private app directory

### Improvements
- New file explorer design


## [2026.02.1] - 2026-02-03

### Fixs
- Can filter logcat by level & process

### Improvements
- Improve text file preview performances (Thanks to [flutter_monaco](https://github.com/omar-hanafy/flutter_monaco))
- Can preview svg images

## [2026.01.1] - 2026-01-28

### Initial Release

This is the first public release of Android Tools, a powerful desktop application for managing Android devices and exploring their file systems.

#### Features

##### Device Management
- **Device information display** - View detailed device specifications, Android version, and hardware details
- **Multiple device support** - Manage multiple Android devices simultaneously

##### File Explorer
- **Browse device file system** - Navigate through your Android device's directories with an intuitive interface
- **File operations** - View, copy, and manage files on your Android device
- **File preview support**:
  - Image preview (PNG, JPEG, etc.)
  - Text file preview with syntax highlighting
  - File metadata display (size, last modified date)
- **Drag and drop support** - Transfer files between your computer and Android device

##### Application Installer
- **Install APK files** - Easily install applications on connected devices
- **Application history** - View and track previously installed applications

##### Logcat Viewer
- **Real-time log monitoring** - View device logs as they happen
- **Log filtering** - Filter logs by tag, priority level, and custom patterns
