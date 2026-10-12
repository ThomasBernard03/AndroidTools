---
name: bump-version
description: Version bump and release preparation for Android Tools. Use when asked to bump, increment, or prepare an application version or release, including CalVer, CHANGELOG.md, Sparkle build numbers, npm/Cargo lockfiles, and release validation.
---

# Bump Android Tools Version

Prepare one release version without publishing, tagging, committing, or editing generated release feeds.

## Required context

Read these files before changing anything:

- `AGENTS.md`
- `docs/releases.md`
- `package.json`
- `src-tauri/Cargo.toml`
- `src-tauri/tauri.conf.json`
- The beginning of `CHANGELOG.md`
- The current entries in `appcast.xml`

Inspect the worktree first. Preserve unrelated user changes and never revert them. If an existing change conflicts with the version bump, stop and ask how to proceed.

## Determine the release values

1. Obtain the target application version from the request. If none was provided, ask one concise question rather than choosing a release number.
2. Accept either padded or unpadded input, but normalize it into both forms:
   - Manifest SemVer: `YYYY.M.PATCH`, with no leading zero in the month, for example `2026.6.1`.
   - Release tag/changelog version: `YYYY.MM.PATCH`, with a two-digit month, for example `2026.06.1`.
3. Require a valid calendar SemVer matching `YYYY.(1-12).PATCH`, with no leading zeroes in the manifest form. The target must be newer than the current application version.
4. Set the release date from the actual current date in `YYYY-MM-DD` format. Do not infer it from the target version.
5. Calculate the next macOS `bundleVersion` as one more than the greatest positive integer found in the current Tauri config and all `sparkle:version` values in `appcast.xml`. It must never be reused or decreased.

## Prepare release notes

Add the new release section immediately before the current newest release in `CHANGELOG.md`:

```markdown
## [YYYY.MM.PATCH] - YYYY-MM-DD

### New Features

- ...

### Improvements

- ...

### Fixes

- ...
```

Use only non-empty headings. Write concise user-facing notes in English, as required by the repository. Derive notes from changes since the previous release using commits and the actual diff, not commit subjects alone. Do not claim behavior that the code or documentation does not support. If release scope cannot be determined reliably, ask the user for the notes instead of inventing them.

Never rewrite historical changelog sections.

## Update active metadata

Make the smallest possible edits:

- Set `package.json` `version` to the unpadded manifest SemVer.
- Set `src-tauri/Cargo.toml` package `version` to the same value.
- Set `src-tauri/tauri.conf.json` `version` to the same value.
- Set `src-tauri/tauri.conf.json` `bundle.macOS.bundleVersion` to the calculated integer, represented in the existing JSON style.
- Search for the exact previous manifest version. Update additional occurrences only when they represent active application metadata that is expected to track every release. Leave examples, test fixtures, historical changelog entries, published feeds, and archived metadata unchanged.

Do not edit `appcast.xml`, `latest.json`, `release-metadata.json`, generated files under `src-tauri/gen`, or dependency lockfiles manually. The release workflow owns published feeds and artifact metadata.

## Regenerate lockfiles

Use package managers so the root package versions change without a dependency upgrade:

1. Run `npm install --package-lock-only --ignore-scripts` after editing `package.json`.
2. Run `cargo check --manifest-path src-tauri/Cargo.toml` without `--locked` once after editing `Cargo.toml`, allowing Cargo to refresh the root package entry in `src-tauri/Cargo.lock`.
3. Inspect both lockfile diffs. Only the Android Tools root package version should change. If dependency versions or checksums change, stop and investigate rather than accepting an incidental dependency update.

## Validate

Run these checks in order:

```bash
node scripts/release.mjs prepare
node scripts/release.mjs notes
npm run check
npm run check:rust
```

Confirm all of the following in the final diff:

- npm, Cargo, and Tauri versions are identical and unpadded.
- The changelog heading uses the padded release version and occurs exactly once.
- The Sparkle build is greater than every published build.
- Lockfiles contain the same root package version and no unrelated resolution changes.
- Historical release assets and feeds are untouched.

Do not run a desktop release build unless explicitly requested. Do not create a Git tag, GitHub release, commit, or push unless explicitly requested.

Report the manifest version, padded release version, Sparkle build number, changed files, and verification results. Mention any checks that could not run and the exact reason.
