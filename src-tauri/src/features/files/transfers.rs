use std::path::{Path, PathBuf};

use super::{
    application::{list, shell},
    domain::*,
    paths::*,
};
use crate::features::adb::domain::AdbSession;

fn budget(depth: usize, count: usize) -> Result<(), FileError> {
    if depth > 128 || count > 100_000 {
        return Err(FileError::new(
            "transfer_limit",
            "A transfer supports at most 128 directory levels and 100,000 entries.",
        ));
    }
    Ok(())
}

fn unsupported() -> FileError {
    FileError::new(
        "unsupported_entry",
        "Transfers support regular files and directories only, without symbolic links or special files.",
    )
}

/// Iterative, bounded traversal. Existing local entries are never opened for writing.
/// Completed entries remain on failure and the caller reports a partial transfer.
pub async fn download(
    session: &dyn AdbSession,
    remote: &str,
    local: PathBuf,
) -> Result<(), FileError> {
    let remote = normalize(remote)?;
    target(&remote)?;
    let mut queue = vec![(remote, local, 0)];
    let mut count = 0;
    while let Some((remote, local, depth)) = queue.pop() {
        count += 1;
        budget(depth, count + queue.len())?;
        let (parent, entry) = target(&remote)?;
        let source = quote(&format!("./{entry}"));
        let kind = shell(session, &remote, &at(parent, &format!("[ ! -L {source} ] || exit 45\nif [ -d {source} ]; then printf d; elif [ -f {source} ]; then printf f; else exit 45; fi"))?, None).await?;
        match kind.as_slice() {
            b"d" => {
                tokio::fs::create_dir(&local).await?;
                for entry in list(session, &remote).await?.entries {
                    local_name(&entry.name)?;
                    if !matches!(entry.kind, EntryKind::Directory | EntryKind::File) {
                        return Err(unsupported());
                    }
                    queue.push((
                        join(&remote, &entry.name),
                        local.join(entry.name),
                        depth + 1,
                    ));
                }
            }
            b"f" => {
                let parent_dir = local.parent().ok_or_else(invalid_path)?.to_owned();
                let temporary = tokio::task::spawn_blocking(move || {
                    tempfile::NamedTempFile::new_in(parent_dir)
                })
                .await
                .map_err(|_| {
                    FileError::new("internal", "Cannot create download staging file.")
                })??;
                let output = tokio::fs::File::from_std(temporary.reopen()?);
                shell(
                    session,
                    &remote,
                    &at(
                        parent,
                        &format!("[ ! -L {source} ] && [ -f {source} ] || exit 45\ncat {source}"),
                    )?,
                    Some(output),
                )
                .await?;
                tokio::task::spawn_blocking(move || {
                    temporary.as_file().sync_all()?;
                    temporary
                        .persist_noclobber(local)
                        .map_err(|error| error.error)?;
                    Ok::<_, std::io::Error>(())
                })
                .await
                .map_err(|_| FileError::new("internal", "Cannot finish the download."))??;
            }
            _ => {
                return Err(FileError::new(
                    "invalid_response",
                    "Android returned an invalid entry type.",
                ));
            }
        }
    }
    Ok(())
}

/// Streams via a private shell-owned staging file, allowing run-as to inherit stdin.
/// A failed upload may leave a partial destination; staging cleanup is always attempted.
pub async fn upload(
    session: &dyn AdbSession,
    remote: &str,
    local: PathBuf,
) -> Result<(), FileError> {
    let remote = normalize(remote)?;
    writable(&remote)?;
    let mut queue = vec![(remote, local, 0)];
    let mut count = 0;
    while let Some((parent, local, depth)) = queue.pop() {
        count += 1;
        budget(depth, count + queue.len())?;
        let entry = local
            .file_name()
            .and_then(|s| s.to_str())
            .ok_or_else(invalid_path)?;
        name(entry)?;
        let remote = join(&parent, entry);
        let metadata = tokio::fs::symlink_metadata(&local).await?;
        if metadata.is_dir() {
            shell(
                session,
                &remote,
                &at(&parent, &format!("mkdir {}", quote(&format!("./{entry}"))))?,
                None,
            )
            .await?;
            let mut children = tokio::fs::read_dir(&local).await?;
            while let Some(child) = children.next_entry().await? {
                queue.push((remote.clone(), child.path(), depth + 1));
                budget(depth, count + queue.len())?;
            }
        } else if metadata.is_file() {
            upload_file(session, &parent, entry, &local).await?;
        } else {
            return Err(unsupported());
        }
    }
    Ok(())
}

async fn upload_file(
    session: &dyn AdbSession,
    parent: &str,
    entry: &str,
    local: &Path,
) -> Result<(), FileError> {
    let bytes = shell(
        session,
        parent,
        "mktemp /data/local/tmp/android-tools.XXXXXXXXXX",
        None,
    )
    .await?;
    let stage = std::str::from_utf8(&bytes)
        .map_err(|_| invalid_path())?
        .trim();
    if !stage
        .strip_prefix("/data/local/tmp/android-tools.")
        .is_some_and(|suffix| {
            !suffix.is_empty() && suffix.bytes().all(|b| b.is_ascii_alphanumeric())
        })
    {
        return Err(FileError::new(
            "invalid_response",
            "Android could not create a transfer staging file.",
        ));
    }
    let result = async {
        session.push(local, stage).await?;
        shell(
            session,
            parent,
            &upload_command(parent, entry, stage)?,
            None,
        )
        .await?;
        Ok::<_, FileError>(())
    }
    .await;
    let cleanup = shell(session, parent, &format!("rm -f {}", quote(stage)), None).await;
    match (result, cleanup) {
        (Err(mut error), Err(_)) => {
            error
                .message
                .push_str(" The remote staging file could not be removed from /data/local/tmp.");
            Err(error)
        }
        (Err(error), _) => Err(error),
        (Ok(()), Err(mut error)) => {
            error.message = "The upload completed, but its staging file could not be removed from /data/local/tmp. Refresh before retrying.".into();
            Err(error)
        }
        (Ok(()), Ok(_)) => Ok(()),
    }
}

pub(super) fn upload_command(parent: &str, entry: &str, stage: &str) -> Result<String, FileError> {
    name(entry)?;
    let dest = quote(&format!("./{entry}"));
    let write = at(
        parent,
        &format!("[ ! -e {dest} ] && [ ! -L {dest} ] || exit 42\nset -C\ncat > {dest}"),
    )?;
    Ok(format!("sh -c {} < {}", quote(&write), quote(stage)))
}
