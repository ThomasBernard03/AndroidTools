# Application settings

**Settings** is the last navigation item, pinned to the bottom of the desktop
sidebar. It works without a device and preserves the selected device/ADB session.

- **Create GitHub issue** opens the project's issue creation page in the default
  browser. **View on GitHub** opens the source repository. Native IPC accepts only
  the two destination identifiers, not arbitrary URLs. Browser failures are shown
  inline and can be retried.
- **Open logs folder** is disabled and marked as coming soon. Application logging
  and its directory have not been implemented.
- **Check for updates** is disabled and marked as coming soon. Sparkle is not yet
  integrated; no update request is made.
- **Sentry crash reporting** saves a preference, initially off, in `settings.json`
  inside Tauri's application configuration directory. Writes atomically replace
  the file on a blocking worker. Failed writes retain the previous UI state;
  malformed settings surface an error instead of silently resetting preferences.

## Sentry limitation

This branch has no Sentry SDK or DSN. The switch persists consent only, and the UI
explicitly states that no reports are sent. Future Sentry initialization must read
this preference before creating a client and honor changes at runtime. Actual
crash capture, SDK configuration and delivery still require implementation.

## Architecture and verification

Vue receives a `SettingsService` contract; its Tauri adapter validates preferences
and translates structured errors. Native commands delegate persistence to a
runtime-independent file adapter. No new dependency or plugin permission is needed.

Development demos keep preferences in memory and simulate GitHub actions. The
`error` scenario reports deterministic failures. Unit tests cover persistence,
corruption, write failures, IPC validation, navigation, pending operations, retry
and both link actions. Run `npm run check` and `npm run check:rust`.

Desktop checks (no phone required):

1. Confirm Settings sits below all other navigation items at the bottom of the
   sidebar, including after resizing; verify keyboard navigation and switch focus.
2. Toggle the preference, restart the app and verify it is restored. Repeat for
   the opposite value.
3. Open both GitHub actions and verify the default browser reaches the expected
   repository and new issue pages.
4. Confirm logs and update actions are visibly unavailable.
