# Repository guidance

## Stack and scope

This branch rebuilds Android Tools with Tauri 2, Rust, Vue 3, TypeScript and
Tailwind CSS 4. Read README.md and docs/architecture.md before adding features.
Implement one understandable, documented and tested feature at a time.

## Commands

```bash
npm ci
npm run tauri dev
npm run dev
npm run check
npm run check:rust
npm run format
cargo fmt --manifest-path src-tauri/Cargo.toml
npm run tauri build -- --no-bundle
```

Build the frontend before Rust checks on a fresh checkout. Use the pinned Rust
toolchain and Node 24 LTS. Commit both dependency lockfiles when they change.

## Architecture

- Organize features by responsibility, following docs/architecture.md.
- Keep business logic independent of Tauri, Vue and external hardware.
- Inject external dependencies through Rust traits and TypeScript interfaces.
- Keep Tauri commands thin; do not call invoke directly from UI components.
- Build deterministic fakes and meaningful behavior tests with each feature.
- The normal test suite must run without a phone, Android SDK or native window.
- Keep explicit demo scenarios separate from real device data and errors.
- Avoid speculative abstractions and empty layer scaffolding.

## Style and documentation

- Use English for all project content: user interface text, accessibility labels,
  error messages, documentation, project guides, code identifiers and test names.
- Write all comments in English, including code, tests, configuration files and
  scripts. API documentation and docstrings must also be written in English.
- Use one Vue component per file; shared widgets live in
  src/shared/presentation/widgets, feature widgets in their presentation layer.
- Use TypeScript strict mode and structured Rust errors.
- Document public Rust APIs, non-obvious decisions and feature limitations.
- Do not edit generated files in src-tauri/gen or dependency lockfiles manually.
- Preserve historical release assets unless their removal is explicitly requested.

## Verification

Run npm run check and npm run check:rust for changes spanning both stacks.
Use focused behavior tests for features, including failures and simulated
dependencies. Document hardware-only verification separately. The initial CI
checks the frontend on Linux and Rust plus a desktop build on macOS.
