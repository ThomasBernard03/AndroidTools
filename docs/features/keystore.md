# Keystore generation

## Scope and interaction

**Generate keystore** replaces the planned APK generation destination. It creates
a new JKS (`.jks`) or PKCS12 (`.p12`) file with one RSA 2048-bit private key and a
self-signed SHA256withRSA certificate. No phone, Java, Android SDK, external tool,
network access or account is required at runtime.

- Destination: an absolute path selected through the native save dialog or typed
  manually. Missing extensions from the dialog are added. Changing format replaces
  a `.jks`/`.p12` extension. Other mismatched extensions are rejected.
- Passwords: 6–128 printable ASCII characters, including spaces, preserved exactly.
  This intentionally conservative constraint avoids Java/Android password encoding
  differences. Show/hide and copy are icon buttons inside every password field,
  including confirmations, with accessible labels and hover titles. The primary
  password fields also offer a Generate icon: Web Crypto creates
  24 uniformly distributed characters (144 bits of entropy) and fills confirmation.
- JKS can use a distinct key password; the default reuses the store password.
  Leaving the optional key password empty also reuses the store password, even
  when Use keystore password is unchecked. The store password remains required.
  PKCS12 always uses one password for both protections. Switching to a shared
  password clears the previous distinct key password and confirmation.
- The format dropdown uses the shared `SelectField.vue` widget with themed options,
  descriptions and a selected checkmark. It supports arrow keys, Home/End,
  typeahead, Enter/Space, Escape, Tab and outside-click dismissal. It closes when
  disabled or navigating away; keyboard focus stays on the combobox trigger.
- Alias: defaults to `upload`, with 1–64 lowercase ASCII letters, digits, `.`, `_`
  or `-`. This avoids Java's case-insensitive alias surprises and JKS modified-UTF
  encoding ambiguity.
- Validity: 1–100 calendar years, default 30, with a UTC expiration date preview.
  February 29 clamps to February 28 when necessary. The actual date is computed
  again at generation time.
- Identity: a nonempty common name is required by this form; organization,
  organizational unit, city, state and two-letter country code are optional.
  Identity strings support UTF-8, at most 128 bytes per field, without control
  characters. Country codes are normalized to uppercase; membership in an ISO
  country list is not checked. These values appear in the public certificate.

Submission validates locally and again in Rust. While choosing a location or
generating, the form is disabled and duplicate submissions are ignored. Cancellation
of the save dialog preserves the previous path. Failures retain inputs for retry.
The result displays the destination, format, alias, expiry and copyable SHA-1/SHA-256
certificate fingerprints. Show in folder uses the operating system's file manager.
SHA-1 is an identifier for integrations, not the certificate signature algorithm.

The screen is cached during navigation so an ongoing operation and its result are
not lost. Form passwords remain in application memory until edited or the window
closes; they are never saved in settings or local storage. Copy explicitly writes
to the system clipboard and does not automatically clear it. Native request
password strings are zeroized on drop; JavaScript/IPC/library copies cannot be
guaranteed to be erased. No secret values are included in errors or logs.

## Implementation

- Frontend: `src/features/keystore` contains service contracts, validation, adapters
  and the workspace. `PasswordField.vue` is a shared widget. UI components use the
  injected `KeystoreService`, never direct IPC.
- Rust: `src-tauri/src/features/keystore` contains the request/result/error contract,
  validation/use case, `KeystoreEncoder` and `KeystoreFiles` traits, native adapters
  and thin commands. Cryptography and writes run on a blocking worker.
- Vendored OpenSSL generates RSA keys, certificates and PKCS12; `jks` encodes JKS
  with its random feature explicitly enabled. JKS uses its legacy Java-defined
  password protection for compatibility. No manual cryptography is implemented.
- A sibling temporary file is synced then published without replacement. Existing
  files, directories and symlinks are rejected, including a destination created
  after the initial check. Failed operations clean up the temporary file. Unix
  files have owner-only permissions; Windows uses the destination folder's ACLs.
- Tauri dialog, clipboard and opener plugins are accessed through feature commands
  on the Rust side. No generic frontend plugin permissions are added.

Only new stores are supported: no import, modification, additional keys, APK signing
or configurable algorithms. Generated files have been tested against Java 21;
compatibility with every older JDK, Gradle version or Android signing tool is not
claimed. Native dialogs, clipboard access and file-manager reveal require desktop
verification on each supported operating system.

## Verification

```bash
npm run check
npm run check:rust
npx playwright install chromium
npm run test:e2e
```

Rust behavior tests inject failing/fake dependencies and use temporary directories.
Native integration tests decrypt both formats, reject wrong passwords, verify RSA
key/certificate correspondence and self-signature, check fingerprints and Unix file
permissions. Existing-file/race tests ensure no replacement or temporary-file leak.
Frontend tests exercise validation, shared/distinct passwords, generation, clipboard
failure, dialog cancellation, PKCS12 switching, busy state, retry and IPC validation.
Playwright covers the full simulated journey, navigation persistence, clipboard,
narrow viewport layout and a failed write.

Optional Java interoperability check (not part of the normal suite):

```bash
cargo test --manifest-path src-tauri/Cargo.toml keytool_can_import --locked -- --ignored
```

This generates disposable stores and asks `keytool` to import their private keys
into another PKCS12 file, then decrypts the imported result. It needs `keytool` on
PATH but no Android SDK. Test passwords are fixed disposable fixtures.

### Desktop checks

1. Run `npm run tauri dev`; open Generate keystore without a phone.
2. Choose and cancel destinations; verify the native dialog and both extensions.
3. Generate/show/hide/copy passwords, including a distinct JKS key password. Paste
   into a disposable editor to check the native clipboard.
4. Generate both formats; confirm displayed fingerprints and Show in folder.
5. Try an existing file and a nonexistent/unwritable folder; verify understandable
   errors, no file replacement and successful retry at a new destination.
6. Navigate away during generation and return; verify the result remains available.

### Explicit demos

Development-only `?demo=empty`/`?demo=devices` use deterministic simulated results;
`?demo=error` reports a simulated write failure. The keystore screen labels these
scenarios, creates no file and disables Show in folder. Clipboard actions still
copy the chosen value through the browser clipboard. A normal browser session
without a demo shows a native-runtime-required message rather than fake success.
