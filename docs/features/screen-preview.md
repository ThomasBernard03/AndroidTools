# Device screen preview

Device overview places Android and USB information on the left and a screenshot
inside a phone frame on the right. Below 1024 px, the preview follows the details.
The frame preserves the captured image's aspect ratio, including landscape images.

The preview captures automatically when ADB becomes connected or the overview is
opened. **Refresh preview** requests a new still image; there is no live mirroring
or remote control. A failed refresh clears the previous image and offers retry.
**Save preview**, beside Refresh, opens a native save dialog for the displayed PNG
without taking another screenshot. The suggested filename includes the connection
ID and local save date/time, for
example `device-preview_usb-1-2-18d1-4ee7_2026-10-08_22-05-30.png`. Characters that
are unsuitable for portable filenames are replaced with hyphens. The button is disabled
until an image is available and while saving. Cancellation writes nothing; success and write failures are reported
below the controls. Existing files are not replaced; choose a new filename.
Changing device, losing the known ADB connection, or leaving the overview discards
the capture. Connection changes are detected on requests, not by a hotplug monitor.

## Implementation and limits

- `capture_device_screen` uses the shared serialized ADB session and `screencap -p`.
- Binary-safe shell v2 requires Android 7 or later. No SDK or external adb is used.
- Capture has a 15-second timeout after session acquisition, a 16 MiB output limit,
  and a 32-megapixel dimension limit. Connection authorization has its own timeout.
- PNG bytes are returned as a validated data URL. No capture file is created on
  the phone; local files are created only through **Save preview**. Image contents
  are not logged. Saving validates the PNG again and publishes it atomically.
- Android may hide protected content or reject capture. A locked phone may show
  its lock screen or require unlocking. Only the default display is captured.
- `/?demo=devices` uses a visibly labeled deterministic screen illustration and
  simulates saving without creating a file or opening a native dialog.

## Verification

Automated Rust tests cover binary preservation and invalid/failed captures. Vue
tests cover authorization gating, refresh/retry, device changes, stale responses
and disposal. IPC tests reject non-PNG responses and preserve native errors.
Save tests cover exact image bytes, cancellation, write failures, existing-file
protection, duplicate clicks and obsolete results after switching devices.

Hardware-only checks:

1. Connect and authorize an Android phone. Confirm the preview matches its screen.
2. Navigate on the phone and click **Refresh preview**; confirm the image changes.
3. Rotate the phone and refresh; confirm the complete screenshot is visible.
4. Switch between two phones while a capture is pending; confirm no old image is
   shown for the new phone. Disconnect, refresh, reconnect and retry.
5. Check locked and protected screens and confirm errors remain local to the preview.
6. Resize the window and use keyboard navigation to reach the refresh button.
7. Click **Save preview**, choose a new PNG filename, then open the saved file and
   compare it with the displayed preview. Navigate on the phone before saving to
   verify the app saves the existing snapshot. Also cancel the dialog and try an
   existing filename or unavailable destination; the preview should remain intact.
