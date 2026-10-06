# APK analysis

Open **APK → APK analysis** and drop one `.apk` onto the workspace or select
**Choose APK**. Processing is local, read-only and independent of device selection.
No Java, Android SDK, external executable or network upload is involved.

## Report

- Application icon, label, package and file name.
- APK size and application version (version name and version code).
- Debuggable status: **Yes**, **No**, or **Unavailable** for unresolved values.
- Minimum and maximum SDK. An absent minimum is shown as Android's default API 1;
  an absent maximum is **No maximum declared**. The target SDK is not a maximum.
- Available v1/v2/v3/v3.1 and source-stamp certificates: subject, issuer, validity,
  serial, algorithm and SHA-1/SHA-256 fingerprints. Identical certificates are
  grouped across signing schemes; source stamps remain separate from APK signers.
- A separate cryptographic signature status: **Verified**, **Invalid**,
  **Not verified**, or **Unsigned**, with the checked signing schemes.

The screen is a compact application card followed by signature details. The first
certificate is expanded and additional certificates can be opened individually.
Missing version values display **Unavailable**. An absent debuggable attribute
uses Android's default, **No**. This flag is not proof that an APK is a release build.
Resource resolution is best-effort and does not enumerate all localized variants.

### Application icons

The resolved application icon supports PNG, JPEG and WebP, plus binary XML and
text XML Android VectorDrawable and adaptive icons. Vector paths, groups/transforms,
clipping, fill/stroke, ARGB colors, alpha, tint and linear/radial gradients are
rendered locally. Adaptive icons combine their background and foreground, resolve
resource IDs/aliases and use a circular mask over Android's 72dp viewport within
the 108dp layer canvas. Percentage insets are supported. Launcher masks vary by
device, so this is a preview, not a reproduction of every launcher.

Images are limited to 2 MiB and 2048×2048 source pixels. Vector previews are 192×192
PNG images. Resource recursion is limited to 16 levels, drawable trees to 2,048
nodes and total drawable input to 8 MiB. Unsupported drawables (including animations,
trim paths, sweep gradients and theme-dependent colors), missing resources and
decode failures use the generic package icon rather than a partial rendering.
No unrelated archive image is substituted.

### Signature verification

Certificate reading and cryptographic verification are independent operations.
The verifier checks v2/v3/v3.1 signing blocks using the original signed bytes:

- APK content digests, including the ZIP entries, central directory and adjusted EOCD.
- Signer signatures using RSA PKCS#1/PSS, ECDSA or DSA and SHA-256/SHA-512 as defined
  by the supported APK algorithm IDs.
- Matching certificate/public keys, signature/digest algorithm lists, signed SDK
  ranges for v3/v3.1, and v2 declarations requiring a v3 block.

Every signer in every recognized block must pass for **Verified**. Invalid
signatures/content/structure produce **Invalid**; unsupported algorithms/structures
and unreadable verification input produce **Not verified**. APKs with only JAR/v1
signatures are explicitly **Not verified**; their certificates remain available.
**Unsigned** means no modern signing block or JAR signature entry was detected.

This checks cryptographic file integrity, not publisher trust or Android installation
compatibility. It does not implement JAR/v1 verification, v4 `.idsig`, source-stamp
verification, certificate revocation/trust or Android's complete SDK-dependent
signer selection, signature rotation lineage and downgrade policies. It is not a
replacement for the full Android platform verifier. Unreadable certificates can
still produce a separate report note even when a verification result is available.

The tool does not decompile DEX, analyze behavior, scan for malware, extract files,
or support AAB/XAPK/APKM containers. Split APKs are inspected individually and are
not merged into a complete installed application.

## Implementation

Rust `features/apk` exposes `ApkInspector` and a validated analysis entry point.
The native adapter uses `apk-info` for binary XML/resources/certificates, `zip` for
the inventory, and OpenSSL for hashing and cryptographic verification. A bounded
signing-block parser preserves signed bytes; `apksig` computes APK chunked content
digests. It parses a temporary snapshot so the hash
and metadata describe the same bytes. The snapshot is removed automatically.
The analysis contract retains the detailed manifest and inventory internally;
the presentation selects the compact summary. The icon renderer resolves resources
through an injectable boundary, converts supported Android nodes to generated SVG,
and uses `resvg` to rasterize them to PNG. APK SVG/XML is never injected into the UI.
Raster icon bytes are read with a size bound and returned as a validated inline image.
The CSP allows `data:` images
for these previews; no filesystem permission or remote image loading is needed.
Tauri commands run blocking operations on worker threads; the file dialog reuses
the existing native dialog plugin. Frontend event permissions allow native drop
listener registration and cleanup, without granting filesystem APIs to the webview.

Limits are 1 GiB compressed input, 64 MiB total declared manifest/resource/META-INF
metadata, and 100,000 archive entries. Decoded manifest output is also limited to
64 MiB. Signing blocks are limited to 16 MiB. These are interactive-analysis limits,
not a sandbox guarantee. Corrupt
archives/manifests fail explicitly; certificate failures can yield a partial report.

Vue receives an injected `ApkService`; the IPC adapter validates nested report
fields. The workspace preserves results across navigation, unregisters inactive
drop listeners, and ignores stale analysis responses. Selecting a replacement
clears the previous report. Already-started native work finishes in the background.
Canceling the file dialog preserves the current result.

## Verification

`npm run check` and `npm run check:rust` exercise generated binary-manifest APKs,
certificate extraction, missing/corrupt/oversized inputs, report serialization,
valid and modified v2/v3/v3.1 signatures, mismatched certificate keys, unsupported
algorithms, binary XML vectors, adaptive compositing, gradients, clipping and alpha,
IPC validation, bounded icon previews/fallbacks, summary defaults, certificate
grouping, chooser cancellation, drag/drop validation, failures/retry, stale
responses and listener cleanup. `npm run test:e2e` includes the browser demo journey.
No phone or SDK is needed. `/?demo=empty` provides an explicitly simulated report;
`/?demo=error` simulates analysis failure and neither reads a local file.

Desktop-only checks (manual):

1. Run `npm run tauri dev`, open APK analysis without a connected phone.
2. Choose a known real APK, cancel a second dialog, and confirm the report remains.
3. Drop a real APK from Finder/Explorer, then a different APK; confirm the latest
   report wins. Try a non-APK and multiple files together.
4. Compare manifest values and certificate fingerprints against known build output;
   exercise resource-based labels and v1/v2/v3-signed packages.
5. Navigate away and drop a file; return and confirm the old report is preserved.
6. Check raster, vector and adaptive-icon APKs; compare their previews with a launcher.
7. Confirm absent maximum SDK is not replaced with target SDK and absent debuggable
   is shown as No. Confirm keyboard navigation and long certificate fields remain usable.
8. Compare v2/v3 signature results against a known signed build and an independently
   verified APK. Modify a signed ZIP entry and confirm **Invalid**. Check a v1-only
   APK reports **Not verified**, rather than Verified or Unsigned.

Native OS dialogs and OS file drops cannot be verified by the Chromium demo suite.

## Install the analyzed APK

**Install APK** is always visible. It stays disabled with an explanatory message
until an APK is analyzed and the selected device has an authenticated ADB connection.
The action targets that selection, prevents duplicate submissions,
and shows success or an installation error. Changing the selection or analyzing
another file clears the previous installation result. Navigation preserves ongoing work.

The backend snapshots the local file and checks its SHA-256 against the analysis
before transferring any bytes. Changed files require a new analysis. Installation
uses the shared serialized ADB session, a unique staging file under `/data/local/tmp`,
and `pm install -r`. Cleanup is attempted after both success and failure. A disconnected
device can retain its temporary staging file; an interrupted request may already have
installed the app. Check the device before retrying if the outcome is uncertain.

Android enforces signing compatibility, SDK requirements, storage and device policy.
This supports single APKs, including updates, without automatic downgrade, runtime
permission grants or split APK sets. Demo installation is simulated and changes no device.

Hardware verification: analyze a signed APK, select an authorized phone, install it
and confirm the app appears. Repeat with an update and an incompatible signing key;
check that the latter exposes Android's rejection. Disconnect during a transfer and
verify an error is shown. Change the file after analysis and verify installation asks
for reanalysis. Check that the staging file is removed after completed operations.
