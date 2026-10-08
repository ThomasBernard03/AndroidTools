# ADB connection and Android information

## Behavior

Selecting a USB device automatically starts an authenticated ADB session, including
the default selection of the first discovered device at startup or refresh. The
phone may display **Allow USB debugging**. Unlock it and accept the prompt; choose
to remember this host on the phone if desired. Authorization waits up to 30 seconds.
If the prompt is denied or left unanswered, the interface reports **Authorization
required** and offers **Retry ADB connection**. A missing handshake times out
separately, rather than assuming the user rejected authentication.

The overview displays these read-only values:

- Android manufacturer and model
- Android version and API level
- Security patch date and build identifier
- CPU ABIs (with the legacy single-ABI property as a fallback)
- Battery percentage, normalized using the device's battery scale, and charging status

Properties come from `getprop`; battery data comes from `dumpsys battery`. No shell
command is supplied by the frontend. Missing values are **Unavailable**. If only
the battery command is unsupported, properties remain visible with a warning.
Transport failures clear the snapshot and release the session. USB descriptor
information remains visible and is never presented as Android system properties.

The bottom bar displays USB as the transport and the ADB state separately:
**Connecting…**, **Connected**, **Authorization required**, **Disconnected**, or
**Unavailable**. The app retains an authenticated session while that device is
selected. **Refresh Android info** reads a new snapshot through that session.
Changing selection releases the old session; clearing selection releases USB.
Requests are serialized, and late results never overwrite a newer selection.

There is no periodic polling or hotplug subscription. Information and connection
state reflect the last request. Use either refresh button to check a disconnection;
the sidebar's **Refresh** also updates the list of USB attachments.

## Architecture and identity

```text
App selection -> useAdb -> AdbService interface -> validated Tauri IPC
  -> read_android_info -> Rust AdbService -> AdbConnector / AdbSession traits
  -> UsbAdbConnector -> rsadb -> nusb -> device adbd
```

`rsadb` handles the ADB wire protocol, RSA authorization and shell streams.
`nusb` handles the ADB USB interface. The existing discovery adapter remains
`rusb`/libusb. No Android SDK, external adb executable or local ADB server is needed.

Before each new connection, the adapter sends `host:kill` to `127.0.0.1:5037`
using the ADB smart socket protocol and waits for the shutdown connection to close.
This runs on a blocking worker with two-second socket timeouts, without launching
an external executable. An absent server is normal; a rejected request or timeout
produces a USB access error. Logs record whether a server was stopped. Refreshing
an existing session does not repeat this step.

The adapter then re-enumerates discovery devices and resolves the
requested connection ID. It requires a non-null serial unique among devices with
the same vendor/product IDs. It then requires exactly one matching ADB transport
device with those values. It never falls back to the first device, or to a model
name. A missing/ambiguous serial produces `identity_unavailable`; USB metadata
remains available. This conservative matching avoids mixing up identical phones
across the two USB libraries. IDs identify attachments and can be reused after
disconnection; they are not permanent device identities.

The app creates a 2048-bit RSA host key at `<app_data_dir>/adb/adbkey` on first use.
Generation and filesystem access run on a blocking worker. The private key is
atomically persisted without replacing another instance's key, with owner-only
permissions on Unix. Subsequent sessions reuse it; an unreadable or corrupt key
produces a structured error instead of silently replacing the identity. Android
Tools uses its own key rather than modifying `~/.android/adbkey`.

Native session changes are guarded by an async mutex. Enumeration/key preparation
run off the UI thread; opening USB and the handshake have a combined 40-second
deadline (including the 30-second authorization wait), and each shell command has
a 10-second deadline. A failed read drops the session. Frontend selection changes
wait for any in-flight bounded request, then act on the latest selection. Disposal
queues a disconnect after any outstanding request.

## Limitations and errors

- USB ADB only; no wireless pairing, emulators, fastboot, root operations or device
  actions. RSA authorization is supported; TLS authentication is not.
- The standard local ADB server is stopped automatically, interrupting its clients.
  Another tool may restart it and reclaim USB; close that tool and retry in this
  case. Servers on custom ports or remote hosts and other direct USB clients are
  not stopped. The app does not continuously monitor or kill background processes.
- Permissions and drivers still apply: Linux may need udev rules; Windows needs a
  compatible USB driver. Native behavior on those platforms needs hardware checks.
- ADB requires a unique readable serial; discovery can still show devices without one.
- Battery formats and properties vary across Android versions and vendors. Empty
  properties and unrecognized battery fields remain absent, never fabricated.
- Storage and RAM information are not included in this increment.

## Simulations and automated verification

Open `/?demo=devices` in development:

- `DEMO-A`: successful connection, Android 16, battery 82% and charging.
- `DEMO-B`: authorization required.
- The third USB device: USB access failure.

Every demo is visibly labeled. Native failures never switch to demo data. All
automated tests run without a phone, SDK, ADB server or native window:

```bash
npm run check
npm run check:rust
npm run tauri build -- --no-bundle
```

Tests cover IPC validation, exact selection matching, missing/duplicate serials,
key reuse and permissions, authorization errors, session reuse/release, partial
battery failures, property parsing, malformed battery scales, retry, stale results,
view disposal and overview/status-bar integration. Loopback fake-server tests cover
the shutdown request, absent servers, rejected/truncated responses and a server
that acknowledges shutdown but keeps its connection open.

## Hardware-only verification

These checks have not been performed during automated implementation:

1. Connect a phone with USB debugging enabled. Select it, accept the authorization
   prompt and compare all displayed values with Android Settings.
2. Restart the app and verify the same host key is reused. If the phone remembered
   the key, no new authorization should be required.
3. Revoke USB debugging authorizations on the phone; deny or ignore the next prompt.
   Verify the authorization message, then retry and accept.
4. Connect two identical models with different serials; switch between them and
   confirm the information and status bar always follow the selection.
5. Switch or clear selection during authorization. Confirm no late data appears
   for the old phone and its USB interface is released when the request completes.
6. Disconnect during a read and after a successful read. Refresh and confirm stale
   Android information is cleared, then reconnect and retry.
7. Run another ADB server that holds the interface. Select a device and confirm
   the server stops automatically, the log reports `stopped=true`, and USB connects.
   Repeat with no server (`stopped=false`). If a tool automatically restarts the
   server, close that tool and retry. Confirm shutdown interrupts other ADB clients.
8. Refresh battery information and test a phone with missing vendor properties.
   Missing fields should remain unavailable while other information is shown.
