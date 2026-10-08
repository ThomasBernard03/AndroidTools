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

Screen preview shares the ADB session through `capture_device_screen`. The use case
executes binary-safe `screencap -p` with bounded output and timeout, returning a PNG
data URL. Vue injects a separate `ScreenshotService`; the preview clears images on
selection/connection changes and ignores obsolete responses and unmounted views.

## 2. Organizing future features

File exploration lives in `features/files`. Listing and mutation use cases use the
injected `AdbSession`; bounded recursive transfers combine streamed ADB operations
with local temporary files. `AdbService::with_session` serializes whole operations
on the shared connection. The native adapter requires shell v2 exit status and keeps
transfer binary data outside IPC. Bounded read-only previews return literal UTF-8 text
or raster image data URLs over IPC. Thin commands handle native pickers. Vue injects a validated
`FileService`; its cached workspace discards stale device/path results and reports
partial operations explicitly. See [File explorer](features/files.md).

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
APK installation snapshots and matches the analyzed SHA-256 before using the shared
ADB session to stage the package, run Android's package manager and attempt cleanup.
The workspace keeps installation visible, explains why it is disabled until an APK
and authenticated selected device are available, and discards results after the
device or report changes.

Keystore generation lives in `features/keystore` on both stacks. Rust validates
requests through a use case with injectable encoder and file-publication traits;
native adapters generate RSA/certificates with vendored OpenSSL, encode JKS with
`jks`, and atomically publish a new file without replacement. Tauri commands run
blocking work off the UI thread and provide scoped dialog/clipboard/reveal actions.
The frontend injects a `KeystoreService` and validates IPC results. Explicit demos
and Chromium journeys exercise the form without native dialogs or real keys.
See [keystore generation](features/keystore.md) for limitations and verification.

Read-only keystore exploration shares `features/keystore`. A separate
`KeystoreInspector` trait isolates the use case from filesystem and cryptographic
parsers. Its native adapter snapshots bounded JKS/PKCS12 files and returns public
certificate metadata and explicit key-check statuses. The frontend injects a
`KeystoreExplorerService`, validates IPC and invalidates reports when credentials
change. See [Keystore explorer](features/keystore-explorer.md).

APK signing lives in `features/signing`. Its use case injects an `ApkSigner`, an
owned `SignedArtifact` and a destination picker, enforcing sign-before-dialog
ordering and cleanup on cancellation. Native adapters read JKS/PKCS12, rebuild
aligned ZIP entries, sign APK v2 and publish atomically without replacement.
The frontend injects a validated `SigningService`; credentials are not persisted.
See [APK signing](features/signing.md) for supported formats and verification.

Application settings live in `features/settings`. Vue injects a validated
`SettingsService`; native commands atomically persist preferences off the UI thread
and open fixed GitHub destinations through the existing opener plugin. The native
Sentry client owns the transport and an atomic consent gate shared by Rust panics
and Vue error events forwarded over IPC. Successful settings writes update this
gate immediately. Local diagnostics use `log` and `flexi_logger` with asynchronous
file writes, size-based rotation and bounded retention. Native command boundaries
record operation outcomes; a narrow frontend adapter forwards fixed error events.
Settings opens the same native log directory. See [Local logs](features/logging.md).
Release builds register the optional Sparkle plugin. A settings command delegates
manual checks to its native UI; ordinary development builds report unavailability.
The historical bundle identity, public key and feed are retained. See
[Build and release](releases.md).
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
- Lucide (`@lucide/vue`) supplies interface icons through the shared `AppIcon.vue`
  widget. Import individual icons there and map them to semantic names instead of
  hand-writing SVG paths. Icons inherit the current text color and caller sizing
  classes; decorative icons are hidden from assistive technology. Icon-only
  controls must provide an accessible label.
- Windows XP Luna-inspired application theme with semantic tokens in
  `src/styles.css`: warm gray canvas, ivory surfaces, blue accents, beveled controls
  and a blue gradient title bar. Shared task panels organize sidebar navigation.
  Use tokens rather than feature-specific palettes. The desktop shell has
  a left device sidebar and a main workspace; below 768 px they stack vertically.
- Preserve standard keyboard behavior, visible focus indicators and reduced-motion
  support. The keystore format and device picker share a themed, accessible
  select-only combobox. The document uses a light color
  scheme for native form controls.
- Interface text is non-selectable for desktop-style interaction. Inputs, textareas,
  editable content and explicit `.select-text` regions remain selectable. Pointer
  focus has no outline; keyboard focus retains the shared `:focus-visible` indicator.
- English for all UI text, accessibility labels, documentation and comments.
- No native plugin or permission without a feature that requires it.
- Run blocking operations outside the UI thread when they are introduced.
- Structured business errors translated into understandable UI messages.
- Formatting, lint, builds and tests run in CI without a phone.
- macOS distribution uses a universal Tauri bundle, ad-hoc signing and the existing
  Sparkle feed. Quality CI verifies the release bundle; only `main` publishes.

## 5. Feature definition of done

1. Expected behavior and failures are defined.
2. External dependencies are replaceable.
3. Meaningful tests pass without a phone.
4. Simulated scenarios are reproducible.
5. Behavior, limitations and test commands are documented.
6. Quality checks have been run and their results reported.
