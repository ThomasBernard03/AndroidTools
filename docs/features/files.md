# File explorer

Open **Device → File explorer** with an authorized USB device. The explorer uses
the existing direct ADB connection, without an Android SDK or external executable.
It is inspired by the explorer on `feature/rust`, adapted to the feature architecture.

## Navigation and operations

- **Shared storage** opens `/sdcard`.
- **Application data** lists installed packages for Android user 0 at the virtual
  `/data/data` location. `/data` exposes that route rather than pretending the shell
  can enumerate the protected filesystem. These are virtual navigation entries.
- **Android root** opens `/`, with normal Android shell permissions.
- Breadcrumbs, a parent button, refresh and a current-folder search support navigation.
- Double-click anywhere on a directory row to open it, or click its name. Action
  buttons keep their own behavior. Focus a row and press Enter to open a directory.
- Right-click a row (or press Shift+F10 on it) for its available actions: Open for
  directories, and Download, Rename and Delete for supported editable entries.
  Delete still requires confirmation. Use arrow keys, Home/End and Enter in the
  menu; Escape dismisses it and restores row focus. Clicking outside, scrolling,
  navigation and device changes also dismiss it.
- The listing includes hidden files, size, modification time and octal permissions.
  Directory entries sort before files. Symlinks and special files are identified.
- Upload one file or an entire folder using the native picker. Download an entry
  into a chosen local folder, retaining its original name. Empty folders are supported.
- Rename an entry within its current directory, create a folder, or permanently
  delete an entry. Folder deletion is recursive and requires confirmation.
- Cancelling a native picker performs no transfer.

## File previews

Click a file name, double-click its row, press Enter on the row, or choose **Preview**
from its context menu. A read-only panel above the listing shows loading, content or
an explicit error. **Close preview** dismisses it; Escape also closes it when focus
is inside the panel. Navigation, refresh, mutations and device changes clear previews
and discard pending results from the previous selection.

- UTF-8 text (including XML, JSON, logs, source files and extensionless text) is shown
  literally and can be selected/copied. Markup is never executed or inserted as HTML.
  Empty files have an explicit empty state. Text is limited to 1 MiB; binary data and
  other encodings are unsupported. SVG is displayed as text.
- PNG, JPEG and WebP images are selected by extension and checked for matching headers
  and dimensions. Images are limited to 8 MiB and 32 megapixels. Browser decoding
  failures are displayed explicitly. Other image formats are not supported yet.
- Reads use the same ADB session and `run-as` permissions as browsing. Remote `head -c`
  bounds content even if the file grows during the read; symlinks and special files
  are rejected. Bounded text and image data URLs cross IPC without saving a local file.
  Oversized files are rejected rather than silently truncated.

Private directories use `run-as`, not root escalation. The application must be
debuggable and allow `run-as` for the primary Android user. A listed package does
not imply that its data is accessible. Other users and work profiles are not supported.
Protected system directories remain subject to permissions and read-only mounts.

## Transfer and failure semantics

Existing destinations are never deliberately replaced or merged. Choose a new name
or remove an existing entry explicitly before retrying. Renames use Android `mv -nT`
to avoid replacement or moving the source into an existing destination directory.
Devices whose shell utilities do not support these options return an operation error.

Downloads stream binary stdout into a sibling temporary file and publish it without
replacement only after a successful remote exit. Uploads stream over ADB sync to a
random, shell-only staging file in `/data/local/tmp`, then copy it with exclusive
creation into the target directory. Private-app uploads inherit the staging stream
through `run-as`. Staging cleanup is attempted after success and failure; cleanup
failure is reported. Uploads need enough device space for both the stage and target.

A recursive transfer is **not transactional**. Completed entries and newly created
folders are retained on failure; an interrupted upload may leave an incomplete
destination file. Failed downloads do not publish the incomplete file. The UI
explicitly warns about partial effects and refreshes the listing. Recursive deletion
can also be partial. Inspect the destination before retrying.

File operations are serialized with Android-information requests on one ADB session.
The UI locks file actions while an operation or picker is pending. Switching devices
discards stale results, but does not cancel an already started operation on the
original device. Navigation away preserves the explorer and pending operation.
The status bar remains a last-known information-request status, not a live monitor.

Transport, authorization, timeout, private-access, permission, collision, read-only,
missing-file, disk-space, unsupported-entry and malformed-response failures are surfaced
as structured errors. Unknown IPC failures do not produce fake data or success messages.

## Boundaries and limitations

- File operations require shell v2 with an explicit exit status (normally Android 7+).
- Listings require Android `stat -c`; metadata output is limited to 16 MiB.
- Transfers allow 128 directory levels and 100,000 entries. Files are streamed,
  without loading their full contents into frontend or backend memory.
- Each native stream is bounded to 30 minutes; shell reads also have a 30-second
  idle timeout. The UI shows an indeterminate operation status, without cancellation,
  resume, or byte-progress reporting.
- Symbolic links and special files cannot be opened, transferred or mutated as
  selected entries. Recursive transfers fail if they encounter one. Recursive
  deletion removes nested links without following them.
- Names preserve spaces, quotes, shell metacharacters and newlines in listings.
  Download names incompatible with supported host filesystems are rejected, including
  Windows reserved names. Non-UTF-8 names are not supported.
- `/`, storage shortcuts, virtual package containers and package roots cannot be
  renamed or deleted. The explorer does not provide a root privilege mechanism.
- Metadata, permissions and timestamps are displayed, not preserved by transfers.
  Transfers are not filesystem snapshots: avoid concurrent changes to source and
  destination trees by other applications. Filesystem checks do not provide isolation
  against another process replacing paths or their ancestors during an operation.

## Architecture and verification

Rust `features/files` contains path rules, DTOs, listing/mutation use cases and bounded
transfer traversal. Thin commands own native pickers. `AdbService::with_session` leases
the existing connection for a complete operation. The injected `AdbSession` contract
provides binary shell output and streaming transfers; the USB adapter checks exit status,
separates stderr, and bounds metadata. Local transfer tests use temporary directories.

Vue injects `FileService`. The IPC adapter validates all returned metadata, rejects
duplicate names and validates completion results. `useFiles` handles loading, errors,
picker cancellation, partial effects and stale device/path requests.

In development, `/?demo=devices` provides a mutable in-memory file tree per device,
including an accessible debug package and a denied production package. Demo uploads,
downloads, renames and deletions do not touch local or Android files.
Open `notes.txt`, `Pictures/sample.png` or the debug package's `files/settings.json`
to try deterministic previews. `Download/example.apk` demonstrates an unsupported file.

Run `npm run check` and `npm run check:rust`. Automated tests cover malformed metadata,
path/filename rules, quoting, package access, collisions, binary and recursive downloads,
staging cleanup after upload failure, UI confirmation, cancellation and device switching.

### Hardware-only checks

1. Authorize a device and open all three locations. Verify hidden files, names with
   quotes/spaces, breadcrumbs, search, empty directories and refresh after external changes.
2. Open a debuggable package and a production package. Verify successful `run-as`
   access and an explicit private-access error respectively.
3. Round-trip a binary file and nested folder with an empty child in shared storage
   and a debug app's data. Compare file hashes outside the app.
4. Retry uploads/downloads into existing destinations. Verify originals are intact.
   Rename a file and folder; test a collision, cancellation and confirmed deletion.
5. Disconnect during upload/download and test insufficient local/device space and
   read-only destinations. Verify partial-effect messages and retry behavior.
6. Switch devices or workspaces during a picker/transfer. Ensure results from the
   original device do not appear under the new selection.
7. Preview XML/JSON and PNG/JPEG/WebP in shared storage and debug app data. Check empty,
   oversized, binary and damaged files, denied reads, and disconnection during a read.
   Switch devices or folders while loading and verify stale content never appears.
