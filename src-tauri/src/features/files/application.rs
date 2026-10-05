use super::{domain::*, paths::*};
use crate::features::adb::domain::AdbSession;
use std::collections::HashSet;

const LIST: &str = r#"[ -r . ] && [ -x . ] || exit 43
for entry in ./* ./.[!.]* ./..?*; do
  [ -e "$entry" ] || [ -L "$entry" ] || continue
  stat -c '%f %s %Y' "$entry" || exit 44
  printf '%s\000' "${entry#./}"
done"#;

pub async fn shell(
    session: &dyn AdbSession,
    path: &str,
    command: &str,
    destination: Option<tokio::fs::File>,
) -> Result<Vec<u8>, FileError> {
    let out = session.file_shell(command, destination).await?;
    if out.exit_code == 0 {
        return Ok(out.stdout);
    }
    let text = out.stderr.to_lowercase();
    let (code, message) = if text.contains("run-as:")
        || (path.starts_with("/data/data/") && text.contains("not debuggable"))
    {
        (
            "private_access",
            "Private data access was denied. The app must be debuggable and allow run-as for the primary Android user.",
        )
    } else if out.exit_code == 42 || text.contains("file exists") {
        (
            "already_exists",
            "The destination already exists. Choose a different name; existing entries are never replaced.",
        )
    } else if out.exit_code == 46 {
        (
            "not_found",
            "The entry no longer exists. Refresh the directory.",
        )
    } else if out.exit_code == 45 {
        (
            "unsupported_entry",
            "Symbolic links and special files cannot be transferred or modified.",
        )
    } else if text.contains("read-only file system") {
        ("read_only", "This Android filesystem is read-only.")
    } else if text.contains("no space left") {
        ("no_space", "The Android device has no free space left.")
    } else if text.contains("permission denied") || out.exit_code == 43 {
        (
            "permission_denied",
            "This directory is missing or inaccessible to the Android shell. Check the path and device permissions.",
        )
    } else if text.contains("no such file") {
        (
            "not_found",
            "The entry no longer exists. Refresh the directory.",
        )
    } else {
        (
            "remote_failed",
            "Android could not complete this file operation. Refresh and check permissions, available space and whether the entry still exists.",
        )
    };
    Err(FileError::new(code, message))
}

pub async fn list(session: &dyn AdbSession, path: &str) -> Result<FileListing, FileError> {
    let path = normalize(path)?;
    let mut entries = if path == "/data" {
        vec![FileEntry::directory("data")]
    } else if path == "/data/data" {
        let bytes = shell(session, &path, "pm list packages --user 0", None).await?;
        let text = std::str::from_utf8(&bytes).map_err(|_| invalid_response())?;
        let mut packages = HashSet::new();
        for line in text.lines().filter(|line| !line.trim().is_empty()) {
            let value = line
                .trim()
                .strip_prefix("package:")
                .filter(|p| package(p))
                .ok_or_else(invalid_response)?;
            packages.insert(value);
        }
        packages.into_iter().map(FileEntry::directory).collect()
    } else {
        parse_entries(&shell(session, &path, &at(&path, LIST)?, None).await?)?
    };
    entries.sort_by(|a, b| {
        (a.kind != EntryKind::Directory)
            .cmp(&(b.kind != EntryKind::Directory))
            .then(a.name.cmp(&b.name))
    });
    Ok(FileListing { path, entries })
}

pub async fn mutate(
    session: &dyn AdbSession,
    path: &str,
    operation: Mutation,
    new_name: &str,
) -> Result<(), FileError> {
    let path = normalize(path)?;
    let (parent, script) = match operation {
        Mutation::CreateDirectory => {
            writable(&path)?;
            name(new_name)?;
            (&*path, format!("mkdir {}", quote(&format!("./{new_name}"))))
        }
        Mutation::Rename | Mutation::Delete => {
            let (parent, entry) = target(&path)?;
            let source = quote(&format!("./{entry}"));
            let guard = format!(
                "[ -e {source} ] || [ -L {source} ] || exit 46\n[ ! -L {source} ] && {{ [ -f {source} ] || [ -d {source} ]; }} || exit 45\n"
            );
            let script = match operation {
                Mutation::Rename => {
                    name(new_name)?;
                    let dest = quote(&format!("./{new_name}"));
                    // -n prevents replacement; -T prevents moving into a raced-in directory.
                    format!(
                        "{guard}[ ! -e {dest} ] && [ ! -L {dest} ] || exit 42\nmv -nT {source} {dest} || exit 44\n[ ! -e {source} ] && [ ! -L {source} ] || exit 42"
                    )
                }
                Mutation::Delete => format!("{guard}rm -r {source}"),
                Mutation::CreateDirectory => unreachable!(),
            };
            (parent, script)
        }
    };
    shell(session, &path, &at(parent, &script)?, None)
        .await
        .map_err(FileError::partial)?;
    Ok(())
}

fn invalid_response() -> FileError {
    FileError::new(
        "invalid_response",
        "Android returned invalid or unsupported file metadata. Refresh the directory.",
    )
}

pub fn parse_entries(mut bytes: &[u8]) -> Result<Vec<FileEntry>, FileError> {
    let mut entries = Vec::new();
    let mut names = HashSet::new();
    while !bytes.is_empty() {
        let end = bytes
            .iter()
            .position(|b| *b == b'\n')
            .ok_or_else(invalid_response)?;
        let fields: Vec<_> = std::str::from_utf8(&bytes[..end])
            .map_err(|_| invalid_response())?
            .split_whitespace()
            .collect();
        if fields.len() != 3 {
            return Err(invalid_response());
        }
        let mode = u32::from_str_radix(fields[0], 16).map_err(|_| invalid_response())?;
        let size = fields[1].parse().map_err(|_| invalid_response())?;
        let modified_at = fields[2].parse().map_err(|_| invalid_response())?;
        bytes = &bytes[end + 1..];
        let end = bytes
            .iter()
            .position(|b| *b == 0)
            .ok_or_else(invalid_response)?;
        let entry = std::str::from_utf8(&bytes[..end]).map_err(|_| invalid_response())?;
        name(entry).map_err(|_| invalid_response())?;
        if !names.insert(entry.to_owned()) {
            return Err(invalid_response());
        }
        entries.push(FileEntry {
            name: entry.into(),
            kind: match mode & 0o170000 {
                0o040000 => EntryKind::Directory,
                0o100000 => EntryKind::File,
                0o120000 => EntryKind::Symlink,
                _ => EntryKind::Other,
            },
            size: Some(size),
            modified_at: Some(modified_at),
            permissions: Some(format!("{:04o}", mode & 0o7777)),
        });
        bytes = &bytes[end + 1..];
    }
    Ok(entries)
}
