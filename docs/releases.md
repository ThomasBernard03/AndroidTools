# Desktop build and release

`.github/workflows/release.yml` preserves the Flutter distribution contract:
push to `main`, a draft GitHub release with notes from `CHANGELOG.md`, a universal macOS
application, an ad-hoc signature, the historical DMG layout, Sentry native symbols,
a Sparkle-signed download, and the existing public appcast. Development branches
never publish. Manual dispatch is also restricted to `main`.

The same release now includes a Windows x64 NSIS installer and a signed Tauri
update manifest (`latest.json`). Sparkle remains macOS-only. Both platform builds
must succeed before the shared draft is published. Linux packaging is not yet enabled.

Build and publication steps are explicit in the workflow. Small Bash helpers install
Sparkle and verify the bundle; `scripts/release.mjs` validates metadata and updates
XML using Node.js. No Python release script is required.

## Preparing a version

1. Set the same calendar SemVer in `src-tauri/tauri.conf.json`, `package.json` and
   `src-tauri/Cargo.toml`. SemVer does not allow leading zeroes: use `2026.6.1`,
   not `2026.06.1`. Update lockfiles through npm and Cargo when versions change.
2. Increment `bundle.macOS.bundleVersion` in `src-tauri/tauri.conf.json`. This is
   Sparkle's independent, strictly increasing integer build number, formerly the
   `+35` suffix in Flutter's `pubspec.yaml`. The first release from this rewrite is
   `2026.10.3`, build `39`, following build `38` in the preserved appcast.
3. Update `CHANGELOG.md` with a `## [2026.06.1] - YYYY-MM-DD` section matching
   the zero-padded release tag. Its body becomes the GitHub release description,
   preserving Markdown headings and lists up to the next level-two heading.
   Missing, empty or duplicate sections fail preparation before draft creation.
   Sparkle's release-notes link points to the matching
   GitHub release page (`releases/tag/<version>`).
4. Merge to `main`. Quality checks and the release pipeline run automatically.

GitHub tags and download names retain the historical zero-padded month:
`2026.06.1` and `AndroidTools-2026.06.1-macos.dmg`. The installed application's
short version uses SemVer; Sparkle compares the integer build number.
Windows filenames use the same padded tag; `latest.json` uses the unpadded SemVer
for Tauri's version comparison. Bump the version and macOS build for the first
Windows publication: an already-advertised macOS version remains a no-op, rather
than retroactively changing a published release.

The workflow reads the latest appcast from `main`. An already advertised version
and build are a no-op; reused versions, reused builds and older builds fail.
Releases target the triggering commit, rather than a potentially newer branch tip.

## GitHub configuration

Reuse these existing secrets:

| Secret                | Purpose                                                                    |
| --------------------- | -------------------------------------------------------------------------- |
| `SPARKLE_PRIVATE_KEY` | Required: signs the DMG using the existing Ed25519 key.                    |
| `SENTRY_DSN`          | Optional: enables reporting in the installed app, subject to user consent. |
| `SENTRY_AUTH_TOKEN`   | Optional, with the next two secrets: uploads native symbols.               |
| `SENTRY_ORG`          | Sentry organization.                                                       |
| `SENTRY_PROJECT`      | Sentry project.                                                            |

Windows additionally requires a repository **variable** `TAURI_UPDATER_PUBLIC_KEY`
and a **secret** `TAURI_SIGNING_PRIVATE_KEY`. The optional secret
`TAURI_SIGNING_PRIVATE_KEY_PASSWORD` unlocks an encrypted private key. These use
Tauri's base64-encoded Minisign format, not Sparkle's raw Ed25519 format. Keep the
same identity for subsequent Windows releases.

Generate a persistent identity locally, outside the repository (PowerShell):

```powershell
New-Item -ItemType Directory -Force "$HOME/.tauri"
npm run tauri signer generate -- -w "$HOME/.tauri/android-tools.key"
```

Back up both files. In GitHub **Settings → Secrets and variables → Actions**, set
the variable to the contents of `android-tools.key.pub` and the secret to the
contents of `android-tools.key`; set the password secret if one was chosen.
No production key is generated or replaced by CI. The public key is injected into
a temporary release configuration; the private key is only provided to the build
step. An absent/invalid public key, missing private key or mismatched signature
fails publication. No production GitHub configuration is changed by local checks.

Tauri update signatures authenticate downloaded installers. Windows Authenticode
signing is not configured; a manual installer download may show an unknown-publisher
prompt. Sentry PDB uploads are not yet configured for Windows.

The workflow's `GITHUB_TOKEN` needs `contents: write` for releases and the appcast
commit. Branch protection must permit that appcast commit. No personal token or
Apple certificate is introduced. The release remains ad-hoc signed and not
notarized, matching Flutter; macOS can require approval on first manual installation.

The existing repository, issue and appcast URLs are fixed in application/release
configuration. The old `REPOSITORY_URL`, `ISSUE_URL` and `APP_CAST_FILE_PATH`
repository variables are no longer consumed. The public appcast URL is unchanged:

```text
https://raw.githubusercontent.com/ThomasBernard03/AndroidTools/refs/heads/main/appcast.xml
```

## Release sequence and retries

1. Validate metadata and create/reuse a draft for the exact source commit.
2. Install Node 24, the repository's pinned Rust toolchain, both macOS targets and
   Sparkle 2.9.6 (matching `tauri-plugin-sparkle-updater` 0.3.0).
3. Run frontend and Rust checks, including compilation and tests with Sparkle enabled.
4. Build `universal-apple-darwin` with `macos-updater` and
   `src-tauri/tauri.release.conf.json`. Verify bundle identity, version/build,
   framework presence, runtime search path, architectures and code signature.
5. If all Sentry credentials exist, upload both architectures' dSYM bundles,
   associate commits and finalize `android-tools@<SemVer>`, matching the Rust SDK.
   Missing credentials skip the upload; upload failures fail the job. JavaScript
   source maps are not uploaded by this workflow.
6. Create `AndroidTools-<version>-macos.dmg` with the restored Flutter background,
   icon positions and Applications shortcut. Sign it with Sparkle, then independently
   verify its signature against the historical public key. The private key is held
   in a restricted temporary file removed when the step exits.
7. Upload the DMG to the draft and transfer public metadata between jobs.
8. Generate the feed against the latest `main`, publish the release, then commit
   the appcast. Existing feed entries are retained. Publishing the download first
   prevents clients from seeing an update whose file is still private.

In parallel, the Windows job installs Perl, uses the pinned Rust MSVC toolchain,
runs frontend/Rust checks with and without `windows-updater`, and builds the
per-user NSIS installer using `src-tauri/tauri.windows.release.conf.json` plus the
injected public key. It independently verifies the Tauri installer signature and
uploads these assets to the shared draft:

- `AndroidTools-<padded-version>-windows-x64-setup.exe`
- `AndroidTools-<padded-version>-windows-x64-setup.exe.sig`
- `latest.json` (version, notes, publication date and `windows-x86_64` download/signature)

The final job checks all desktop assets before publishing. The Windows updater reads
`https://github.com/ThomasBernard03/AndroidTools/releases/latest/download/latest.json`.

Only one release workflow runs at a time. A failed build leaves a draft. Rerun the
same workflow to retry it; the draft notes are refreshed from that commit's changelog.
Already published release notes are retained during recovery.
If publication succeeds but the appcast push fails,
rerunning **all jobs of that run** downloads the already-published DMG and repairs
the feed without rebuilding or replacing the public artifact. Windows recovery
downloads and verifies the existing installer, signature and manifest rather than
rebuilding or replacing them. A release from a
different commit cannot be overwritten. If `main` has moved during the final push,
the push fails rather than overwriting that change; rerun all jobs to read the new
feed. The appcast-only bot commit does not trigger another release.

## Sparkle continuity

The bundle keeps `com.example.androidTools`, `Android Tools.app`, the historical
public key and feed URL. These values permit existing Flutter/Sparkle installations
to identify the replacement. The release includes Sparkle.framework, automatic
checks and **Settings → Check for updates**, which opens Sparkle's native UI.
Sparkle verifies downloads and handles installation/relaunch.

The framework is optional for normal development and unit tests. Ordinary development
builds return an explicit unavailable error for manual update checks. Windows uses
the separately enabled `windows-updater` feature, never Sparkle.
Explicit browser demos simulate the action; they never request an update.

Restoring the historical identifier also changes Tauri's application directories
from the provisional `com.thomasbernard.androidtools` identifier used during this
branch's development. Those provisional settings/ADB host keys are not migrated.
Flutter preference migration is also outside this release flow.

## Local verification

Normal checks require no Sparkle installation, phone, signing key or GitHub access:

```bash
npm ci
npm run check
npm run check:rust
```

On macOS, verify the release bundle without publishing or accessing secrets:

```bash
bash scripts/setup-sparkle.sh
export SPARKLE_FRAMEWORK_PATH="$PWD/src-tauri"
rustup target add aarch64-apple-darwin x86_64-apple-darwin
cargo test --manifest-path src-tauri/Cargo.toml --features macos-updater --locked \
  --config "target.$(rustc -vV | sed -n 's/^host: //p').runner=['env', 'DYLD_FRAMEWORK_PATH=$SPARKLE_FRAMEWORK_PATH']"
npm run tauri build -- --target universal-apple-darwin --features macos-updater --config src-tauri/tauri.release.conf.json -- --locked
bash scripts/verify-macos-bundle.sh
```

The Cargo runner sets the framework path on the test executable itself; setting it
only on the Cargo process is insufficient on some macOS environments. Quality CI
also builds and verifies the universal release bundle on pull requests, without
release secrets or publication.

On Windows, install the Tauri prerequisites, MSVC C++ tools and Strawberry Perl.
Build the frontend first, then check the updater-enabled backend:

```powershell
npm ci
npm run check
npm run check:rust
cargo clippy --manifest-path src-tauri/Cargo.toml --features windows-updater --all-targets --locked -- -D warnings
cargo test --manifest-path src-tauri/Cargo.toml --features windows-updater --locked
```

To build an installer locally with a disposable test identity (not for publication):

```powershell
New-Item -ItemType Directory -Force "$env:TEMP/android-tools-release-check"
$check = "$env:TEMP/android-tools-release-check"
npm run tauri signer generate -- --ci -w "$check/test.key"
$env:TAURI_UPDATER_PUBLIC_KEY = (Get-Content "$check/test.key.pub" -Raw).Trim()
$env:TAURI_SIGNING_PRIVATE_KEY = "$check/test.key"
$env:TAURI_SIGNING_PRIVATE_KEY_PASSWORD = ''
node scripts/windows-release.mjs configure "$check/windows-release.json"
npm run tauri build -- --features windows-updater --config "$check/windows-release.json" -- --locked
node scripts/windows-release.mjs metadata
```

The quality workflow performs this signed build with an ephemeral key without
release secrets or publication. Release-helper tests also check real Tauri CLI
signatures, changed bytes, wrong keys and padded-tag/unpadded-SemVer mapping.
Never distribute the CI/test-key installer as an official release.

Manual distribution verification (not part of the hardware-free suite):

- Mount the DMG and check its background, icon and Applications shortcut; install
  and launch on both Intel and Apple Silicon.
- From a historical Flutter installation, check that Sparkle offers the new build,
  validates the download, replaces the app and relaunches the Tauri version.
- In the installed Tauri release, use **Check for updates** and verify Sparkle's
  up-to-date, network failure and subsequent signed-update dialogs. Check that the
  linked GitHub release page renders correctly in the release-notes area.
- With a test Sentry project and reporting enabled, verify that native events match
  the release and uploaded dSYM UUIDs. No secret-bearing publication is performed
  by local tests.
- On Windows, install the NSIS package, launch from the Start menu, and verify an
  upgrade from an older installed version signed with the same test key. Exercise
  **Later**, successful installation/relaunch, up-to-date and offline states. A
  damaged installer or a signature from another key must not launch installation.
  End-to-end installed upgrades require two published/test-feed versions and remain
  a manual distribution check; building an installer alone does not prove an upgrade.
