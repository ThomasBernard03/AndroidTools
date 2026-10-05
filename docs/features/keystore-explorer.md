# Keystore explorer

The **APK & Keystore** navigation group includes a read-only **Keystore explorer**.
Choose a local file or enter its path, supply its store password and click
**Explore keystore**. The workspace and report survive navigation. Passwords are
held only in workspace memory, never persisted or logged. No private key bytes
cross IPC. Native request passwords and decrypted JKS key buffers are zeroized on
drop. Source files are never written.

## Reports and credential checks

- JKS: all aliases are sorted, with private-key or trusted-certificate types and
  each entry's certificate chain. Successful loading checks the password-protected
  store digest, including when the password is empty.
- JKS private keys initially show **Key password not checked**. Select an alias
  and click **Verify key**. An empty key password reuses the store password. The
  adapter decrypts the key and compares its public key to the leaf certificate.
  Failure leaves the readable store metadata visible and does not declare the
  store corrupt. Changing key credentials resets previous key-check results.
- PKCS12: OpenSSL exposes the first signing identity and additional certificates.
  Private-key unlocking uses the store password and the public key is compared to
  the certificate. Separate passwords and a complete multi-key inventory are not
  supported. Additional certificates are not classified as trusted entries or
  presented as a verified chain. Missing friendly names display **No alias available**.
- PKCS12 password protection and the integrity MAC are checked by OpenSSL when
  present. MAC-less stores cannot establish store integrity; the UI therefore
  reports that the store opened rather than asserting integrity verification.
- Certificates show subject, issuer, serial, validity dates, SHA-1 and SHA-256.
  Trust, revocation, current validity and compatibility with a previously published
  application are not validated. Dates are displayed as reported by OpenSSL.

A wrong password and damaged authenticated data cannot always be distinguished.
Messages explicitly describe that ambiguity. Decode failures can also indicate
unsupported formats or encryption; legacy PKCS12 encryption unavailable in the
default OpenSSL provider is not enabled automatically. Empty stores are supported.

## Architecture and limits

`explorer.rs` defines serializable reports, structured errors, input validation and
the injectable `KeystoreInspector`. `explorer_native.rs` reads a regular file into
a bounded snapshot (16 MiB), detects JKS by its magic and otherwise tries PKCS12.
JKS lengths are checked before dependency allocations, with limits of 4096 entries
and 64 certificates per chain. Unknown versions, duplicate aliases and trailing
data are rejected. The JKS dependency supports UTF-8 aliases; Java modified UTF-8
edge cases may be rejected as unsupported data.
`explorer_commands.rs` runs the use case on a blocking worker. The existing native
keystore picker and clipboard command are reused.

The frontend has its own service contract and validated IPC adapter. Reports are
cleared when the path or store password changes, before new requests and after
errors. Request revisions prevent late responses from showing stale data. Dialog
cancellation preserves the current report. Controls are disabled during work.

## Verification

Run `npm run check` and `npm run check:rust`. Native tests generate real stores in
temporary directories, check multiple aliases and trusted entries, separate key
passwords, empty stores/passwords, unreadable files, truncated contents and digest
damage. They verify read-only behavior and IPC serialization. Vue tests cover
credential changes, retry, cancellation, stale results and limitations; IPC tests
reject malformed certificates and statuses. No Java, phone or native window is
required.

Development browser demo: open `/?demo=empty`, navigate to **Keystore explorer**,
choose the simulated file and use `demo-password`. Use the same password for the
key or deliberately enter a different one. `/?demo=error` simulates an unlock
failure. Demo data is visibly labeled and never substitutes for real errors.

Desktop checks (manual):

1. Generate JKS and PKCS12 stores in the application and open each in the explorer.
2. Compare alias and fingerprint values with the generation result and, optionally,
   `keytool -list -v -keystore <path>` (let keytool prompt for the password).
3. Open a multi-entry JKS with a trusted certificate and distinct key passwords;
   check each key with correct and incorrect passwords.
4. Try an incorrect store password and a truncated copy of the file. Confirm that
   no stale success report remains and that errors do not imply certain corruption.
5. Cancel file selection, navigate away and back, and check native clipboard/show
   password controls. Confirm the source file remains unchanged.
