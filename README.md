# Android Tools

A new desktop foundation built with **Tauri 2 + Rust + Vue 3 + TypeScript +
Tailwind CSS 4**. This branch rebuilds the project incrementally. Only the welcome
screen is implemented so far. The first feature will list devices using simulated
data, followed by real USB integration. No phone or Android SDK is required for
this milestone.

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

Open <http://127.0.0.1:1420>. The welcome screen works in both environments.
Future native features will be available in the browser through explicit simulated
services, introduced with the first feature.

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

The frontend test verifies that the welcome screen mounts without a Tauri runtime
or phone. The Rust test runner is ready but has no business tests yet: the backend
only starts Tauri. Behavior tests will be introduced alongside each feature.

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
  App.test.ts                     Bootstrap test without a native runtime
  styles.css                      Tailwind and global styles
  shared/presentation/widgets/    Shared components
src-tauri/
  src/lib.rs                      Tauri bootstrap
  src/main.rs                     Binary entry point
  tauri.conf.json                 Window, build and content security policy
  capabilities/main.json          Native window permissions
docs/
  architecture.md                 Decisions and rules for future features
```

Read the [architecture guide](docs/architecture.md) before adding the first feature.
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
