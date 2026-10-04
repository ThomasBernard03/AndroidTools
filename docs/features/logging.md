# Local application logs

Open **Settings → Application logs → Open logs folder** to open the native file
manager. Failures are shown inline and can be retried. The action works without a
phone and is simulated explicitly in development demos.

## Storage and retention

The Rust composition root initializes `log` with `flexi_logger` in Tauri's
`app_log_dir()` before starting device services. The native command resolves the
same directory; it accepts no path from the webview. For the current app identifier:

- macOS: `~/Library/Logs/com.thomasbernard.androidtools`
- Windows: the app's local data directory, under `logs`
- Linux: the app's local data directory, under `logs`

`android-tools_rCURRENT.log` is appended across restarts. Rotation uses numbered
archives at **5 MiB**, retaining **5 archives plus the current file** (approximately
30 MiB). Rotation happens at record boundaries, so a file can exceed the threshold
by one record. Cleanup also runs when the logger starts. No external log-rotation
daemon is needed. Concurrent application processes sharing this directory are not
supported by the file writer.

Writes run on a background thread. Normal application exit drains and shuts down
the writer. A forced kill, power loss or native crash can lose queued entries.
Initialization failures fail desktop startup rather than silently promising logs
that cannot be written; subsequent writer failures are reported by the library to
stderr. File access follows the current user's filesystem permissions.

## Events and privacy

Each line includes an RFC 3339 UTC timestamp, level and Rust target. The level is
`INFO` for application targets; third-party dependency logging is disabled. This
deliberate filter avoids verbose USB/network/crypto internals and accidental
credential leakage. Local logging is always active, independently of Sentry consent,
and does not itself send data over the network.

Logged events include startup/version, normal exit, USB discovery, ADB information
reads/disconnection, APK analysis/signing, keystore generation and log-folder opening.
Operations record success/failure and elapsed milliseconds. A successfully completed
signing command also includes user cancellation; it does not imply a file was saved.
Rust panics record their source location, while preserving the existing panic hook.
Vue errors, unhandled JavaScript errors and promise rejections record only a fixed
event identifier through a dedicated IPC adapter. Existing Vue error reporting is
preserved and logging failures cannot recursively produce unhandled rejections.

Do not log request/response bodies, passwords, keys, clipboard values, user paths,
device serials, Android properties or arbitrary error payloads. In particular,
frontend exception messages and stacks are intentionally absent from local logs.
New Rust diagnostics should use `log::info!`, `log::warn!` or `log::error!` with
deliberately selected non-sensitive fields. Business logic remains independent of
the logger: operation instrumentation lives at the command boundary.

## Verification

`npm run check` and `npm run check:rust` cover rotation with small files, bounded
retention, restart append, dependency filtering, invalid destinations, IPC event
validation, Vue integration, folder-action errors, pending requests and retry.
Tests use temporary directories and injected services without a native window.

Desktop checks (no phone required):

1. Launch the app, open Settings and activate **Open logs folder** with the keyboard.
2. Verify the file manager opens the directory containing the active log. Refresh
   devices and confirm a timestamped operation result appears, including failures.
3. Disable Sentry reporting and verify local events are still written.
4. Restart the app and verify the active file retains the previous session.
5. Trigger an unhandled error from the development webview inspector and verify
   `frontend event=unhandled_error` appears without the exception payload.
