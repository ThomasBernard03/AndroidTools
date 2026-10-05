# Device discovery and selection

## Behavior

- Discover connected Android USB devices at startup and on **Refresh**.
- Choose a device from the left sidebar dropdown. The main workspace displays
  the selected connection's details or a getting-started screen when none is selected.
- Match the ADB interface class/subclass/protocol `ff/42/01`.
- Show each physical USB device once, even if it exposes multiple interfaces.
- Use USB product strings as names, falling back to **Android device**.
- Display serial numbers when available and always include the connection ID.
- Automatically select the first device in discovery order when there is no valid
  selection, including startup and refresh. Allow choosing another device manually.
- Preserve the selected ID across successful refreshes while it remains present.
- Clear devices and selection on discovery failure, and allow retry.
- If the selected connection disappears, select the first remaining device, or
  clear selection when the list is empty.
- Disable refresh and selection during discovery. Ignore stale asynchronous results
  and results received after the owning Vue scope has been disposed.

Selection is owned by the feature's composable and is not persisted to disk.
The application forwards the selection to the separate [ADB feature](adb.md),
which authenticates and reads Android information. Discovery itself never claims
the ADB interface.

## Data flow

```text
DevicePicker.vue
  -> useDevices (loading, errors, selection, request lifetime)
  -> DeviceService interface
  -> Tauri service adapter (IPC response validation)
  -> list_devices command (spawn_blocking)
  -> Rust DeviceService (deterministic ordering)
  -> DeviceRepository trait
  -> UsbDeviceRepository (rusb / libusb)
```

The domain and application code have no dependency on Tauri or a USB library.
Serde serialization is used at the Rust boundary. The USB adapter does not claim
interfaces, execute shell commands or invoke an external `adb` process.

USB metadata reads have a 200 ms timeout per descriptor request. Missing or
inaccessible metadata is a per-device warning, not a discovery-wide failure.
Failure to initialize USB or enumerate the bus produces a structured
`usb_unavailable` error. A failed worker task produces an `internal` error.

## Simulated dependencies

Run `npm run dev` and open one of these URLs:

| URL                                   | Scenario                                                                                  |
| ------------------------------------- | ----------------------------------------------------------------------------------------- |
| `http://127.0.0.1:1420/?demo=devices` | Two identical models with different serials and a third device with inaccessible metadata |
| `http://127.0.0.1:1420/?demo=empty`   | No connected devices                                                                      |
| `http://127.0.0.1:1420/?demo=error`   | USB discovery failure                                                                     |

Demo mode is explicitly labeled and development-only. A browser without the demo
parameter reports that the desktop runtime is required. Production uses real USB.

Frontend tests inject services with controlled results, failures and pending
promises. Rust tests inject `FakeRepository` into the application service. No test
enumerates the machine's USB devices or opens a native window.

## Known limitations

- Only physical USB ADB interfaces are supported. Emulators, wireless ADB, fastboot
  and MTP-only interfaces are not listed.
- Discovery does not check ADB authorization. An unauthorized phone may still
  appear; selecting it starts the separate ADB authentication flow.
- Refresh is manual after the initial scan. There is no hotplug subscription or
  background polling, so unplugging a phone is reflected on the next refresh.
- IDs combine USB bus, address, vendor and product IDs. They identify the current
  attachment, not the permanent phone identity. A disconnected USB address may be
  reused between scans; use the serial/label to confirm the intended device.
- Names come from USB descriptors, not Android's `getprop` model property.
- Devices disappearing before their descriptors can be read are skipped. If all
  configuration descriptors are inaccessible, the ADB interface cannot be identified
  and that device is skipped. Missing string metadata alone does not hide a device.
- Linux may require udev permissions. Windows needs a libusb-compatible driver for
  metadata access. Native builds and hardware behavior on those OSes are not yet
  verified by this milestone's macOS CI.

## Verification

```bash
npm run check
npm run check:rust
npm run tauri build -- --no-bundle
```

### Hardware-only checklist

These checks must be performed manually; automated fakes do not prove USB hardware
compatibility. They have not been performed as part of the automated implementation.

1. Start without a phone and verify the empty state.
2. Connect a phone with USB debugging enabled and click **Refresh**.
3. Verify the name/serial against the phone and select it.
4. Connect a second phone, ideally the same model. Verify both are distinct and
   selecting either displays its own identity.
5. Refresh with both connected and verify the selection is retained.
6. Disconnect the selected phone and refresh. Verify the first remaining phone is
   selected, or selection is cleared if none remain.
7. Disable USB debugging and confirm an MTP-only connection is not listed.
8. Where possible, deny USB metadata access and verify the device is retained with
   a warning when its ADB configuration descriptors remain readable.
9. Run with Android Studio open and confirm enumeration remains usable. Discovery
   does not claim USB interfaces or stop another application's ADB server. Selecting
   a phone starts ADB, which can report an interface-claim failure if another client
   already owns it.
