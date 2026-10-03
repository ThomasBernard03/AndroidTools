# Android Tools

A new desktop foundation built with **Tauri 2 + Rust + Vue 3 + TypeScript +
Tailwind CSS 4**. This branch rebuilds the project incrementally. It lists Android
USB devices and reads Android information over an authenticated ADB connection. No Android SDK
or external `adb` executable is required. Tests and explicit demo scenarios run
without a phone.

## Prerequisites

- Node.js **24 LTS**, version 24.15 or later within the 24.x series, and npm.
  Run `nvm use` if you use nvm.
- Rust through [rustup](https://rustup.rs/). `rust-toolchain.toml` pins the version
  and components used locally and in CI.
- On macOS: Xcode or the Command Line Tools (`xcode-select --install`).
- On Windows/Linux: install the [Tauri prerequisites](https://v2.tauri.app/start/prerequisites/).
  Native CI for this first milestone targets macOS.

## Install and run

```bash
npm ci
npm run tauri dev
```

Tauri starts Vite, compiles Rust and opens a native window. The first launch takes
longer because Cargo must compile the dependencies.

To work on the interface in a browser:

```bash
npm run dev
```

Open <http://127.0.0.1:1420/?demo=devices> for the explicit device demo.
Use `?demo=empty` or `?demo=error` for the other deterministic scenarios.
Demo mode is visibly labeled and only enabled in development builds. Opening the
browser without a demo scenario displays a native-runtime-required error; real
USB failures never fall back to fake data.

## Select a connected device

1. Enable developer options and **USB debugging** on the phone.
2. Connect it with a USB data cable and launch `npm run tauri dev`.
3. The first detected device is selected automatically. Use the **Device** dropdown
   to choose another device.
4. Click **Refresh** after connecting or disconnecting a phone.
5. When selecting a device, unlock the phone and accept **Allow USB debugging**.
   The application waits up to 30 seconds for authorization; use **Retry ADB
   connection** if needed.

Discovery runs at startup and on manual refresh. Each option shows the USB product
name, serial when available and a connection identifier, so identical models remain
distinguishable. The first device in discovery order is selected by default, starting
its ADB connection. Refresh preserves the current selection while it remains present;
otherwise it selects the first available device. Selection is cleared when discovery
fails or no devices remain. Connection changes are detected on manual refresh.

The **Device overview** displays the selected device's USB manufacturer, product,
serial number, vendor/product IDs and connection ID. Missing strings are shown as
**Unavailable**; descriptor IDs remain visible even when USB metadata access fails.
These values refresh with the device list and are not Android system properties.

A persistent bottom status bar shows the selected device and its serial number
(or connection ID), the USB transport and the ADB connection state. Selecting a
device starts a direct ADB-over-USB session. **Android information** displays the
manufacturer, model, Android version, API level, security patch, build, CPU
architecture and battery level/status when available. Use **Refresh Android info**
to read a new snapshot. Connection state reflects the last request, not a live
hotplug monitor.

This feature detects physical USB interfaces exposing ADB, not emulators, Wi-Fi
devices, MTP-only connections or fastboot devices. USB presence does not establish
ADB authorization. The separate ADB connection performs authentication and reads
Android properties. Missing USB metadata does not hide a detected ADB device;
it appears with a fallback name and a warning.

ADB requires a readable, unique USB serial number to match the selected device
across the discovery and transport libraries. The app stores its own host key in
its application data directory. If another ADB client holds the USB interface,
close it and stop its ADB server before retrying; Android Tools does not stop it
automatically. See [ADB information](docs/features/adb.md) for details and hardware checks.

See [device discovery](docs/features/devices.md) for architecture, limitations and
hardware verification instructions.

## Quality checks

```bash
npm run check
npm run check:rust
```

`check` runs formatting checks, ESLint, TypeScript validation, the Vite build and
Vitest tests. `check:rust` runs rustfmt checks, Clippy and Cargo tests. On a fresh
checkout, build the frontend before running Rust checks: Tauri embeds files from
`dist/` in some build configurations.

```bash
npm run test:watch
npm run format
cargo fmt --manifest-path src-tauri/Cargo.toml
```

Frontend tests cover selection, refresh, disappearance, errors and retry, stale
requests, demo scenarios and IPC validation. Rust tests cover discovery filtering,
ordering, missing metadata normalization, error propagation and serialization.
All automated tests run without a phone, Android SDK or native window.

## Build the desktop binary

```bash
npm run tauri build -- --no-bundle
```

The binary is written to `src-tauri/target/release/`. Installer generation is
disabled for this first milestone. Distribution packaging, signing, notarization and
updates will be addressed in a dedicated milestone.

The application icon is reused from the Flutter application on `main`
(`macos/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon512x512@2x.png`).
Its original 1024-pixel source is stored as `src-tauri/icons/app-icon.png`.
Regenerate the runtime icon with:

```bash
npm run tauri icon -- src-tauri/icons/app-icon.png --output src-tauri/icons --png 32
```

## Project layout

```text
src/
  main.ts                         Vue bootstrap
  App.vue                         Interface composition
  App.test.ts                     Composition test without a native runtime
  styles.css                      Tailwind and global styles
  features/devices/               Contracts, adapters, selection UI and tests
src-tauri/
  src/lib.rs                      Tauri bootstrap
  src/main.rs                     Binary entry point
  src/features/devices/           Discovery contract, use case, USB adapter and IPC
  tauri.conf.json                 Window, build and content security policy
  capabilities/main.json          Native window permissions
docs/
  architecture.md                 Decisions and rules for future features
  features/devices.md             Device discovery guide and hardware checks
```

Read the [architecture guide](docs/architecture.md) before adding a feature.
All project content, including the interface, documentation and comments, must be
written in English, as specified in [AGENTS.md](AGENTS.md).

`package-lock.json` and `src-tauri/Cargo.lock` are versioned for reproducible
dependency installation. The existing `appcast/`, `appcast.xml` and `CHANGELOG.md`
preserve Flutter release history and are not used by this foundation.
The new CI checks the frontend on Linux and Rust plus the desktop build on macOS;
it does not publish releases.

## Tooling choices

- **Node.js 24 LTS** runs the frontend development tools. Node.js 26 is currently
  in its Current phase; this project uses the latest LTS line for its development
  baseline. Node.js is not embedded in the shipped desktop application.
- **Cargo** is Rust's package manager and build tool. It resolves dependencies,
  compiles the application and runs Rust tests.
- **rustfmt** formats Rust source code; `cargo fmt --check` verifies formatting.
- **Clippy** is Rust's linter. It detects common mistakes and suggests more idiomatic
  code. CI treats its warnings as failures.

Dependency versions were reviewed on October 2, 2026. Vite 8 and Vitest 5 are used.
TypeScript remains on 6.0.x because the current `typescript-eslint` release supports
TypeScript versions below 6.1; TypeScript 7 is newer but is not supported by that
linter yet. Revisit this constraint when updating the toolchain.

The CI commands are portable, but native Tauri compilation depends on the host
platform. The macOS job validates the macOS runtime and binary using Apple's SDK;
a Linux build would instead validate WebKitGTK and the Linux binary. Frontend
checks run on Linux because they do not need a native window or macOS APIs.
