# APK signing

Open **APK → APK signing**, enter or choose an APK and an existing JKS or PKCS12
keystore, then provide its key alias and password. A separate JKS key password is
optional; leaving it empty reuses the keystore password. Click **Sign APK**.

Signing completes locally before the native **Save signed APK** dialog opens. Its
suggested filename is the source basename with `-signed` before the extension:
`my.app.apk` becomes `my.app-signed.apk`. Choose a destination to publish the file.
The result shows its full path and **Show in folder**. Cancelling the dialog saves
nothing and cleans up temporary files; click **Sign APK** again to retry.
Existing files are never replaced, including the original APK and keystore.

No phone, Java, Android SDK, external executable or network service is required.
The form and result survive navigation. Passwords stay in the in-memory form for
retry, are not persisted, and are excluded from Rust debug output. Rust-owned
password and private-key export buffers are erased on drop. JavaScript strings
cannot be reliably erased.

## Supported inputs and output

- APK Signature Scheme **v2**, RSA PKCS#1 v1.5 with SHA-256. Output requires
  **Android 7.0 / API 24 or later**. No v1, v3, v4 or key-rotation lineage is emitted.
- JKS private-key entries with a matching X.509 certificate, including keystores
  created by **Generate keystore**. PKCS12 supports one private key and certificate,
  with a matching certificate friendly-name alias and a shared store/key password.
  Multi-key PKCS12 files, absent friendly names and non-RSA keys are unsupported.
- Input files up to 1 GiB, 100,000 ZIP entries, 2 GiB total unpacked content and
  16 MiB keystores. Only stored/deflated, unencrypted ZIP entries are supported.
  Inputs must contain `AndroidManifest.xml`; signing does not establish that the
  application is otherwise valid or installable.
- Previous signing blocks and top-level JAR signatures under `META-INF` are removed.
  Other entry content is retained. ZIP metadata/compressed bytes may change.
  Stored entries are aligned to 4 bytes; stored `lib/**/*.so` entries to 16 KiB.
  Signing does not change ELF segment alignment inside native libraries.
- The source is snapshotted and rebuilt in temporary storage. Provision space for
  the input snapshot, rebuilt unsigned APK, signed APK and destination-side copy.
  Temporary files are removed after success, cancellation or handled failure.
- The completed APK's RSA signature and content digest are checked before opening
  the dialog. Publication uses a synced sibling temporary file and atomic
  no-clobber creation. A write failure can be retried by signing again.

## Architecture and verification

`features/signing` owns the Rust request, errors, `ApkSigner`/`SignedArtifact`
contracts and sign-then-save use case. The native adapter loads keys with `jks` /
OpenSSL, rebuilds and aligns entries with `zip`, and signs with `apksig`. The thin
Tauri command executes blocking work off the UI thread and supplies the save dialog.

Vue injects a `SigningService`; the IPC adapter validates nullable path responses
and translates structured errors. Explicit development demo scenarios (`?demo=empty`
or `?demo=devices`) simulate signing and saving; `?demo=error` simulates an unlock
failure. Simulations never create files or open a native dialog.

Run `npm run check` and `npm run check:rust`. Tests exercise workflow ordering,
cancellation cleanup, naming, input errors, both generated keystore formats,
wrong passwords/alias, content retention, library alignment, re-signing, tampering,
independent OpenSSL signature verification, no-clobber publication, IPC validation
and form retry/duplicate submission behavior. They require no native window or SDK.

Desktop verification (manual):

1. Generate both JKS and PKCS12 keystores and sign a real APK with each.
2. Confirm the save dialog appears after signing with `name-signed.apk`; cancel
   once and confirm no output, then retry into a new filename.
3. Check wrong passwords/alias fail before any save dialog; check an existing
   destination is preserved and **Show in folder** reveals a successful result.
4. With Android SDK Build Tools available, independently run
   `apksigner verify --verbose --print-certs --min-sdk-version 24 <signed.apk>`
   and `zipalign -c -P 16 -v 4 <signed.apk>`.
5. Install on an Android 7+ device. An installed application signed by another key
   must be uninstalled before installing this differently signed package.
