# Foundation architecture

## 1. Two languages, one application

Vue/TypeScript handles presentation and user interactions. Rust handles system
operations and business logic. Tauri provides the window and the IPC bridge between
them. Vite builds the frontend; Cargo builds the backend.

An IPC call behaves like an asynchronous service call: the frontend sends
serializable arguments, Rust executes a command and returns a result. Events can
report progress for long-running operations.

The device picker calls `list_devices` through an injectable frontend service.
The native command delegates discovery to a Rust service on a blocking worker.
The USB adapter uses `rusb` with vendored libusb; it does not launch external tools.

Android information lives in `features/adb`. `read_android_info` delegates to an
ADB application service with injectable `AdbConnector` and `AdbSession` traits.
The native adapter uses `rsadb` with its `nusb` USB transport for authentication
and shell streams. It matches a freshly discovered connection by a unique USB
serial plus vendor/product IDs, rather than choosing the first matching model.
No ADB server or external executable is launched. Authentication and reads are
asynchronous and timeout-bounded; filesystem/key generation and libusb discovery
run on blocking workers. The service owns one session and serializes its use.
The frontend injects a separate `AdbService`, validates IPC, serializes selection
changes and discards stale results. See [ADB information](features/adb.md).

## 2. Organizing future features

APK analysis lives in `features/apk` on both stacks. Rust validates input through an
`ApkInspector` trait; the native adapter snapshots the file, reads binary manifests,
resources and certificates with `apk-info`, inventories ZIP entries and hashes the
snapshot. Commands run on blocking workers. Vue injects an `ApkService` with validated
IPC and native drop event registration; its cached workspace discards stale results
and cleans up listeners on navigation. See [APK analysis](features/apk.md).
The analysis adapter separately checks modern APK signer signatures and content
digests, returning an explicit verification status. Android drawable XML is resolved
through an injectable resource reader and rendered to PNG with `resvg`; raw APK XML
is never inserted into the webview DOM.

Keystore generation lives in `features/keystore` on both stacks. Rust validates
requests through a use case with injectable encoder and file-publication traits;
native adapters generate RSA/certificates with vendored OpenSSL, encode JKS with
`jks`, and atomically publish a new file without replacement. Tauri commands run
blocking work off the UI thread and provide scoped dialog/clipboard/reveal actions.
The frontend injects a `KeystoreService` and validates IPC results. Explicit demos
and Chromium journeys exercise the form without native dialogs or real keys.
See [keystore generation](features/keystore.md) for limitations and verification.

APK signing lives in `features/signing`. Its use case injects an `ApkSigner`, an
owned `SignedArtifact` and a destination picker, enforcing sign-before-dialog
ordering and cleanup on cancellation. Native adapters read JKS/PKCS12, rebuild
aligned ZIP entries, sign APK v2 and publish atomically without replacement.
The frontend injects a validated `SigningService`; credentials are not persisted.
See [APK signing](features/signing.md) for supported formats and verification.

Application settings live in `features/settings`. Vue injects a validated
`SettingsService`; native commands atomically persist preferences off the UI thread
and open fixed GitHub destinations through the existing opener plugin. Sentry
consent is persisted, but SDK integration, logging and Sparkle are deferred.
See [Settings](features/settings.md).

Each feature will live under `src/features/<feature>/` on the frontend and
`src-tauri/src/features/<feature>/` in Rust. Introduce layers when they have a
concrete responsibility:

| Responsibility             | Frontend                       | Backend                    |
| -------------------------- | ------------------------------ | -------------------------- |
| Presentation / entry point | Vue components and composables | Thin Tauri commands        |
| Application                | Interaction orchestration      | Use cases                  |
| Domain                     | Models and service contracts   | Models, rules and traits   |
| Infrastructure             | IPC adapter                    | USB, files and persistence |

Dependencies point toward contracts rather than external implementations. The
composition root selects and injects concrete implementations. Rust business logic
remains testable independently of the Tauri runtime.

Device discovery uses a Rust `DeviceRepository` trait and a TypeScript
`DeviceService` interface. The composition roots (`src-tauri/src/lib.rs` and
`src/main.ts`) choose the real adapters. Tests inject fake repositories or services.
Explicit development-only demo scenarios replace IPC and are visibly labeled.
A USB error never silently turns into demo data.

Rust's serialized DTO defines the IPC wire contract. For these small commands we
use a small explicit TypeScript interface, runtime response validation and a Rust
serialization test instead of introducing a type-generation toolchain. Revisit
generation as commands grow. An unchecked generic on `invoke` is not sufficient:
the adapter validates required fields and unique connection IDs before returning
data to the presentation layer.

## 3. Tests and simulations

- **Rust unit tests**: business rules with injected dependencies.
- **Rust integration tests**: adapters with temporary files and fixtures.
- **Vitest**: composables and services with controlled results and failures.
- **Vue Test Utils**: visible behavior and user interactions.
- **Browser journeys**: introduce these with the first interactive workflows.
- **Hardware checks**: document USB verification separately; it must never be
  required to run the normal test suite.

A fake is a simplified working implementation. A mock verifies an interaction.
Prefer fakes for demo scenarios, and use mocks when the interaction itself matters.

Test empty, loading, success and error states, then relevant concurrency scenarios:
disconnection, stale results and cancellation. Tests should validate behavior
rather than duplicate implementation details.

## 4. Initial decisions

- Vue Composition API and strict TypeScript.
- No global store or router until there is a concrete need.
- Tailwind for styling; shared components for recurring patterns.
- Dark application theme with semantic color tokens in `src/styles.css`: charcoal
  canvas and surfaces, mint primary accent `#7CFFB2`, muted text, warning and error
  colors. Use tokens rather than feature-specific palettes. The desktop shell has
  a left device sidebar and a main workspace; below 768 px they stack vertically.
- Preserve standard keyboard behavior, visible focus indicators and reduced-motion
  support. The keystore format uses a themed, accessible select-only combobox;
  the device picker retains its native select. The document uses a dark color
  scheme for native form controls.
- English for all UI text, accessibility labels, documentation and comments.
- No native plugin or permission without a feature that requires it.
- Run blocking operations outside the UI thread when they are introduced.
- Structured business errors translated into understandable UI messages.
- Formatting, lint, builds and tests run in CI without a phone.
- Distribution packaging is deferred to a dedicated milestone; the desktop binary
  build is verified from this foundation onward.

## 5. Feature definition of done

1. Expected behavior and failures are defined.
2. External dependencies are replaceable.
3. Meaningful tests pass without a phone.
4. Simulated scenarios are reproducible.
5. Behavior, limitations and test commands are documented.
6. Quality checks have been run and their results reported.
