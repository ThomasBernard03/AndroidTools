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
  Native CI and release packaging target macOS (Intel and Apple Silicon).

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

The compact sidebar groups **Device overview**, **File explorer** and **Logcat**
under Device, and **APK analysis**, **Generate keystore**, **APK signing** and
**Keystore explorer** under **APK & Keystore**. APK analysis inspects local packages and Generate keystore creates signing keys
locally. APK signing signs local packages using an existing keystore. File explorer
browses and manages Android files. Logcat displays an explicit **Coming soon** screen.
Navigation remains available without a device and preserves the selected device
and ADB state when returning to the overview.

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

## Explore Android files

Open **Device → File explorer** to browse **Shared storage**, **Application data**
and **Android root**. Upload or download files and complete folders, rename entries,
create folders and delete entries with confirmation. Existing destinations are not
replaced. Private application data requires a debuggable app allowing `run-as` for
the primary Android user; Android permissions still apply at the root.

Transfers stream over the shared ADB session. Interrupted operations report possible
partial changes. The interface includes breadcrumbs, search and metadata; previews
are deferred. See [File explorer](docs/features/files.md) for transfer semantics,
limits, explicit demos and hardware verification.

## Analyze an APK

Open **APK & Keystore → APK analysis**, then drag and drop one `.apk` or click **Choose APK**.
The compact report shows the application icon when supported, APK size, application
version, debuggable status, minimum/maximum SDK and signing certificate details.
No phone, Android SDK or upload is required. Results survive navigation.

APK v2/v3/v3.1 signatures and signed content digests are cryptographically checked;
v1-only APKs explicitly report **Not verified**. Raster, vector and adaptive icons
are previewed locally when their drawable features are supported. APKs up to 1 GiB
are supported, with additional metadata limits. See [APK analysis](docs/features/apk.md)
for report details, limitations and desktop verification.

## Generate a keystore

Open **APK & Keystore → Generate keystore** without connecting a phone. Choose a destination,
JKS or PKCS12 format, passwords, an alias and a certificate identity. The defaults
are JKS, alias `upload`, RSA 2048 and 30 years of validity. The format uses a themed,
keyboard-accessible dropdown. Icons inside each password field show, hide or copy
its value. **Generate** creates a secure 24-character password and
fills its confirmation. JKS supports a separate key password; PKCS12 uses the
keystore password for both protections. Leaving the optional key password empty
also reuses the keystore password, which remains required.

Creation is native: no Java, Android SDK or external `keytool` is required. Existing
files are never replaced. The result includes SHA-1/SHA-256 certificate fingerprints
and **Show in folder**. Back up the file and passwords for future signing operations.
The screen retains its state while navigating within the application.

In development, `/?demo=empty` or `/?demo=devices` simulates successful creation;
`/?demo=error` simulates a write failure. These explicitly labeled scenarios create
no file or key. See [keystore generation](docs/features/keystore.md) for constraints,
architecture and desktop verification.

## Sign an APK

Open **APK & Keystore → APK signing**, enter or choose the APK and keystore paths, then enter
the key alias, keystore password and optional separate key password. JKS and
single-key PKCS12 RSA keystores are supported, including those generated in the app.

Click **Sign APK**. After local signing succeeds, the native save dialog proposes
`name-signed.apk`. Choose a new filename to save; existing files are never replaced.
Cancelling saves nothing. The result includes **Show in folder**.

Signing uses APK Signature Scheme v2 for **Android 7.0 and later**, without Java or
an Android SDK. See [APK signing](docs/features/signing.md) for limits, demo scenarios
and independent desktop verification.

## Explore a keystore

Open **APK & Keystore → Keystore explorer**, choose a JKS or PKCS12 file and enter
its store password. The read-only report shows aliases, entry types, certificate
subjects and issuers, serial numbers, validity dates and SHA-1/SHA-256 fingerprints.
For JKS, select an alias and use **Verify key** to check its separate password and
confirm that the unlocked key matches its certificate. An empty key password uses
the store password. Editing store credentials clears the previous report.

No phone, Java or Android SDK is required. Files up to 16 MiB are supported.
PKCS12 exposes the first signing identity and additional certificates, with an
explicit multi-key inventory limitation. Incorrect passwords and damaged files can
produce the same integrity failure. See [Keystore explorer](docs/features/keystore-explorer.md)
for verification semantics, demos and manual checks.

## Application settings

Open **Settings** at the bottom of the sidebar to open the GitHub project, create
an issue and control Sentry error reporting. The preference survives restarts and
applies immediately to Vue errors and Rust panics. Supply `SENTRY_DSN` when building
the desktop application to enable delivery; reporting defaults to off.
**Open logs folder** opens local diagnostic files, rotated at 5 MiB with 5 archives
retained. Local logs work independently of Sentry. Installed macOS releases use
Sparkle for automatic checks and **Check for updates**.
See [Settings](docs/features/settings.md) and [Local logs](docs/features/logging.md).

## Quality checks

```bash
npm run check
npm run check:rust
npx playwright install chromium
npm run test:e2e
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
requests, demo scenarios, keystore form interactions and IPC validation. Rust tests
also reopen generated keystores, verify private keys and certificates, reject wrong
passwords and protect existing files. Playwright runs the simulated keystore journey
in Chromium. The normal suite requires no phone, Android SDK, Java or native window;
an optional ignored test checks Java `keytool` interoperability.

## Build the desktop binary

```bash
npm run tauri build -- --no-bundle
```

The binary is written to `src-tauri/target/release/`. Normal development does not
require Sparkle or generate installers. Pushes to `main` build and publish a
universal, ad-hoc-signed macOS DMG, upload native symbols to Sentry when configured,
and update the existing Sparkle appcast. See [Build and release](docs/releases.md)
for versioning, secrets, local bundle checks and retry behavior.

The application icon is reused from the Flutter application on `main`
(`macos/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon512x512@2x.png`).
Its 1024-pixel source is stored as `src-tauri/icons/app-icon.png`. Keep about
100 px of transparent padding around the artwork (content about 824 px centered)
so the macOS Dock does not render it oversized; do not use an edge-to-edge
squircle. Regenerate the runtime icons with:

```bash
npm run tauri icon -- src-tauri/icons/app-icon.png --output src-tauri/icons
```

Keep only `32x32.png` and `icon.icns` from the generated output and remove the
other platform files.

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
preserve Flutter release history and continue to support macOS distribution.
Quality CI checks the frontend on Linux and Rust plus the universal release bundle
on macOS. The separate release workflow publishes only from `main`.

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
