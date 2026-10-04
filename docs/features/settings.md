# Application settings

**Settings** is the last navigation item, pinned to the bottom of the desktop
sidebar. It works without a device and preserves the selected device/ADB session.

- **Create GitHub issue** opens the project's issue creation page in the default
  browser. **View on GitHub** opens the source repository. Native IPC accepts only
  the two destination identifiers, not arbitrary URLs. Browser failures are shown
  inline and can be retried.
- **Open logs folder** opens the local rotating-log directory in the native file
  manager. Logs rotate at 5 MiB with 5 archives retained. Errors can be retried;
  no arbitrary path is accepted over IPC. See [Local logs](logging.md).
- **Check for updates** is disabled and marked as coming soon. Sparkle is not yet
  integrated; no update request is made.
- **Sentry crash reporting** saves a preference, initially off, in `settings.json`
  inside Tauri's application configuration directory. Writes atomically replace
  the file on a blocking worker. Failed writes retain the previous UI state;
  malformed settings surface an error instead of silently resetting preferences.

## Sentry error reporting

Provide the same build-time variable used by the Flutter application:

```bash
SENTRY_DSN='https://PUBLIC_KEY@HOST/PROJECT_ID' npm run tauri build -- --no-bundle
```

For local verification, supply it to `npm run tauri dev` instead. Cargo rebuilds
when the variable changes. The native SDK also accepts `SENTRY_DSN` at process
startup if no valid build-time DSN was supplied. The DSN is a public ingestion
identifier, not an auth token. Without a valid DSN, delivery is disabled without
preventing startup.
`SENTRY_AUTH_TOKEN` is not needed at runtime and must not be embedded in the app.

The native client reads persisted consent before initialization; missing or corrupt
preferences mean reporting is off. An atomic gate checks every event before it is
queued. Successful saves immediately update it for both stacks, without restarting;
failed saves preserve the previous state. Events already queued or in flight when
the switch is disabled may still finish sending. Settings writes are serialized.

`@sentry/vue` captures Vue errors, unhandled JavaScript errors and rejected promises.
Its browser transport is disabled: events go through a narrow IPC command to the
Rust `sentry` client, which also captures Rust panics. This keeps the DSN, consent,
release (`android-tools@<Cargo version>`) and environment (`development` or
`production`) in one place, without widening the webview's network CSP. Malformed
or oversized frontend events are discarded; reporting failures do not break the UI.
Browser-only mode and frontend demo scenarios do not initialize the Vue SDK.

Unlike Flutter `main`, this integration does not collect replays or screenshots.
Component props, automatic breadcrumbs, sessions and performance tracing are also
disabled. Error messages and stack traces can still contain application data.
Expected errors already handled and shown by feature services are not automatically
reported. Native signals/segfaults, errors before native setup, offline persistence
and Flutter preference migration are not supported. Release source-map/native-symbol
upload remains part of future distribution tooling; the historical Flutter release
workflow does not upload symbols for this branch.

## Architecture and verification

Vue receives a `SettingsService` contract; its Tauri adapter validates preferences
and translates structured errors. Native commands delegate persistence to a
runtime-independent file adapter. `src-tauri/src/reporting.rs` owns native reporting
and the runtime gate; `src/shared/infrastructure/crashReporting.ts` owns the Vue
adapter and injectable event sender. No new plugin permission is needed.

Development demos keep preferences in memory and simulate GitHub and folder actions. The
`error` scenario reports deterministic failures. Unit tests cover persistence,
corruption, write failures, IPC validation, navigation, pending operations, retry
and both link actions. Run `npm run check` and `npm run check:rust`.
Reporting tests use an in-memory Sentry transport and an injected IPC sender; no
Sentry project or network connection is required. They cover opt-in/out on both
stacks, restart, failed saves, corrupted settings, invalid payloads and Vue capture.

Desktop checks (no phone required):

1. Confirm Settings sits below all other navigation items at the bottom of the
   sidebar, including after resizing; verify keyboard navigation and switch focus.
2. Toggle the preference, restart the app and verify it is restored. Repeat for
   the opposite value.
3. Open both GitHub actions and verify the default browser reaches the expected
   repository and new issue pages.
4. Open the logs folder and verify it contains the active application log. Confirm
   the update action remains visibly unavailable.
5. In a desktop development build with a test DSN, enable reporting and trigger
   an unhandled error in the webview inspector (for example,
   `setTimeout(() => { throw new Error('Sentry desktop verification'); }, 0)`).
   Verify a JavaScript event arrives with the native release and environment.
   Disable reporting and repeat with a distinct message: no new event should arrive.
   Repeat after restarting for each preference. Delivery and symbolication against
   a real Sentry project are manual checks, not part of the automated suite.
