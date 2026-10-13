# Logcat

## Behavior

- Authorize ADB and open **Device → Logcat**. Capture starts with
  `logcat -v threadtime '*:V'`, replaying **all logs still available on the phone**
  before streaming new messages. No SDK, external executable or second USB session
  is used. Logs already overwritten in Android's own ring buffers cannot be recovered.
- **Minimum level** includes the chosen priority and higher levels. Changing it
  queries the disk history without restarting capture or discarding lower priorities.
- Standard lines display **timestamp, PID-TID, tag, level, message**, in that order.
  The level has a padded color badge; repeat counters follow the message.
  Continuation lines and unknown formats remain literal. Colors reuse the light
  SwiftUI palette in standard RGB: black for Verbose, blue for Debug, green for Info,
  ochre for Warning and red for Error and Fatal.
- **Package name** uses the same `SelectField` widget as other app dropdowns, with
  its optional searchable mode. Click to open the list, type a substring to narrow
  the installed packages, and select using the pointer or arrows and Enter. Selection
  completes the field. **Apply package** starts a new capture; **All packages** clears
  the filter. Starting a package capture resolves its UID from `pm list packages -U`
  and adds `--uid=<number>`. The UID filter covers secondary processes and restarts.
- **Group repeats** is enabled by default. Consecutive identical lines are represented
  by their first line and a live **×N** counter. Standard threadtime timestamps are
  ignored, but PID, TID, priority, tag and the exact message are preserved when
  comparing. Continuation lines are compared literally. Intervening different logs,
  including logs hidden by the minimum-level filter, start a new group; chronology
  is preserved. Grouping spans USB chunks and storage batches. Disable it to see every
  original line with its original timestamp. Search in grouped mode examines the
  representative first line; disable grouping to find a repeated entry by timestamp.
- **Refresh** pauses the old stream, opens a new one, replaces history on success,
  and refreshes package suggestions. Changing packages also replaces session history.
- **Clear device logs** pauses capture, executes `logcat -c` and starts a fresh
  capture. It clears the default Android buffers for **all packages**. On failure,
  the previous disk history remains browsable and searchable. New logs can arrive
  immediately after a successful clear.
- **Search logs** is literal and case-insensitive. It searches the entire selected
  history on disk, not only rendered rows. Previous/Next and Enter/Shift+Enter wrap
  between matching rows. Results scroll into view with surrounding context and
  highlighted occurrences. The status shows the matching row's position rather than
  building a list of every match in memory. Long searches show **Searching history…**;
  typing another query cancels the previous traversal. Each search uses a snapshot
  of the row count; the next navigation includes newly captured logs.
- **Follow live** follows the newest row. Scrolling or searching disables it.
  **First line**, **Latest**, Home/End, Page Up/Down, arrows and the scrollbar navigate
  the complete history. Without wrapping, wheel steps remain line-based even for
  very large histories.
- **Soft wrap**, off by default, wraps long messages (including unbroken text) to
  the viewport width. Wrapped rows expand without overlapping; wheel and Page Up/Down
  scrolling can traverse messages taller than the viewport. Search and live following
  still navigate logical entries. The option lasts until leaving the workspace.
- Changing phones clears the view and package selection. Stream and storage errors
  stop capture but retain published history for inspection. Leaving the workspace
  disposes capture and temporary history; reopening starts a fresh capture.

## Storage, performance and limits

There is **no 5,000-line or 4 Mi-character retention limit**, nor a 1,000-entry replay
limit. A background Rust task continuously reads the owned `AdbStream` independently
of UI polling. The shared ADB session lock is held only while opening that channel.

`DiskHistory` writes original records into an anonymous temporary file. Six disk-only
offset indexes provide direct access for each minimum priority; six additional indexes
address consecutive groups. The first record of a group has a fixed-width repeat
counter. Only the last comparison key and constant-size counters remain in memory.
Grouping does not remove originals. Each record is published after its text and
indexes have been written. Disk failures stop capture and report an explicit error
instead of silently evicting older history.

File operations run on blocking workers. Append batches and viewport reads are at
most 200 rows. Searches yield after 2,000 rows or 15 ms, allowing capture and scrolling
to proceed. The frontend polls counts every 150 ms and loads only its current page.
Search results and obsolete viewport responses are revision-checked. Capture tokens
prevent an old stop request from closing a newer stream.

The virtual viewport renders visible rows plus overscan. Its physical scrollbar is
capped at one million pixels and maps to logical row positions, avoiding browser
layout-height limits. Searching and keyboard navigation address exact logical rows.
With soft wrap, the current page (at most 200 entries) uses browser-measured heights
and unloaded history uses estimated heights. Page replacement preserves the top
entry and its pixel offset; resizing reflows the text. The scrollbar remains
approximate for unloaded wrapped history. Live following aligns the bottom of the
latest message; the position indicator shows the current logical entry in this mode.
Native parsers still reject malformed/oversized individual output: 2 MiB chunks,
64 KiB lines and search queries over 4,096 UTF-8 bytes. These bound individual work
units, not the number of stored entries. History length is ultimately constrained by
available temporary-disk space. Files are deleted when their handles close, including
app termination. This is session history, not an export or restart-persistent archive.
Log content is rendered literally and is not sent to diagnostic logging.

Shell v2 requires Android 7+. UID filtering normally requires Android 8+; unsupported
flags and permission failures are reported without falling back to unfiltered logs.
Packages sharing a UID share their logs. Package/UID visibility depends on the Android
user/profile and shell permissions. Only default Logcat buffers are read and cleared.

## Deterministic verification

- `/?demo=devices`: a new synthetic log every 400 ms.
- `/?demo=devices&logcat=large`: 20,000 initial synthetic rows plus live logs. The demo
  generates rows by index instead of allocating the full history.
- `/?demo=devices&logcat=repeats`: three consecutive occurrences of each message.
- `/?demo=devices&logcat=long`: mixed short messages and long unbroken payloads for
  verifying wrapping and scrolling within a message taller than the viewport.

All demos are development-only and visibly labeled. Package selection restarts the
same fixture. Real USB or disk failures never switch to demo data.

```bash
npm run check
npm run check:rust
npm run test:e2e -- e2e/logcat.spec.ts
```

Tests cover disk retention beyond the old limits, random access, priority indexes,
bidirectional resumable search, UTF-8 framing, grouping across batches, preservation
of original timestamps, write failures, stale IPC, navigation cleanup, clear failures,
searchable dropdown completion, bounded rendering and a ten-million-row scrollbar.
Chromium journeys exercise the large-history view, search scrolling, repeat counters
and package selection, plus wrapping, non-overlapping rows, resizing and live following.

## Hardware verification

1. Authorize a phone and verify initial replay plus live timestamp/PID/TID/tag/message.
   Generate more than 5,000 messages. Use First line to find the oldest captured row,
   then search for messages in the middle and near the end.
2. Emit a repeated message at changing timestamps. Verify ×N increases, then disable
   grouping and inspect every original. Change PID, TID, priority or payload and
   verify it starts another group; interleave a different log and check ordering.
3. Open the package dropdown, type a substring, select a package and apply. Restart
   that app and exercise secondary processes. Restore All packages. Test each level.
4. Search and scroll while logs continue. Follow live must remain off until requested.
   Check wheel/trackpad, scrollbar dragging, keyboard navigation and narrow windows.
5. Refresh and clear. Verify Android's buffers are cleared for all apps. Test a denied
   clear and confirm old history is still searchable. On a constrained test volume,
   verify a write failure reports an error without discarding published rows.
6. Switch devices during startup, unplug during capture, navigate away, then use file
   exploration/screen preview. Reopen Logcat and verify no stale device logs appear.
   On older Android, test unfiltered capture separately from UID filtering.
