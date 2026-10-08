# macOS build and release

`.github/workflows/release.yml` preserves the Flutter distribution contract:
push to `main`, a draft GitHub release with generated notes, a universal macOS
application, an ad-hoc signature, the historical DMG layout, Sentry native symbols,
a Sparkle-signed download, and the existing public appcast. Development branches
never publish. Manual dispatch is also restricted to `main`.

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
3. Update `CHANGELOG.md`. Sparkle's release-notes link points to the matching
   GitHub release page (`releases/tag/<version>`).
4. Merge to `main`. Quality checks and the release pipeline run automatically.

GitHub tags and download names retain the historical zero-padded month:
`2026.06.1` and `AndroidTools-2026.06.1-macos.dmg`. The installed application's
short version uses SemVer; Sparkle compares the integer build number.

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

Only one release workflow runs at a time. A failed build leaves a draft. Rerun the
same workflow to retry it. If publication succeeds but the appcast push fails,
rerunning **all jobs of that run** downloads the already-published DMG and repairs
the feed without rebuilding or replacing the public artifact. A release from a
different commit cannot be overwritten. If `main` has moved during the final push,
the push fails rather than overwriting that change; rerun all jobs to read the new
feed. The appcast-only bot commit does not trigger another release.

## Sparkle continuity

The bundle keeps `com.example.androidTools`, `Android Tools.app`, the historical
public key and feed URL. These values permit existing Flutter/Sparkle installations
to identify the replacement. The release includes Sparkle.framework, automatic
checks and **Settings → Check for updates**, which opens Sparkle's native UI.
Sparkle verifies downloads and handles installation/relaunch.

The framework is optional for normal development and unit tests. Unbundled builds
and other platforms return an explicit unavailable error for manual update checks.
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
