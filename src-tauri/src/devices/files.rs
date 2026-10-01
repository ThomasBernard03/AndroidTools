use adb_client::ADBDeviceExt;
use serde::Serialize;
use std::{fs, io, path::Path};

use super::{DeviceService, ServiceError};

const PREVIEW_LIMIT: usize = 256 * 1024;
// NUL-delimited names preserve whitespace, newlines and shell metacharacters.
const LIST_SCRIPT: &str = r#"[ -r . ] && [ -x . ] || exit 1
for entry in ./* ./.[!.]* ./..?*; do
  [ -e "$entry" ] || [ -L "$entry" ] || continue
  stat -c '%f %s %Y' "$entry" || exit 1
  printf '%s\000' "${entry#./}"
done"#;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FileEntry {
    name: String,
    kind: &'static str,
    size: Option<u64>,
    modified_at: Option<i64>,
    permissions: Option<String>,
}

impl FileEntry {
    fn directory(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            kind: "directory",
            size: None,
            modified_at: None,
            permissions: None,
        }
    }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FileListing {
    pub path: String,
    entries: Vec<FileEntry>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FilePreview {
    text: String,
    truncated: bool,
}

impl DeviceService {
    pub fn create_directory(
        &self,
        device_id: &str,
        path: &str,
        name: &str,
    ) -> Result<(), ServiceError> {
        validate_name(name)?;
        let path = normalize_path(path)?;
        writable_directory(&path)?;
        let command = at_path(&path, &format!("mkdir {}", quote(&format!("./{name}"))))?;
        self.file_shell(device_id, &path, &command)?;
        Ok(())
    }

    pub fn delete_entry(&self, device_id: &str, path: &str) -> Result<(), ServiceError> {
        let path = normalize_path(path)?;
        let (parent, name) = entry_target(&path)?;
        let target = quote(&format!("./{name}"));
        let command = at_path(
            parent,
            &format!(
                "[ ! -L {target} ] && {{ [ -f {target} ] || [ -d {target} ]; }} && rm -r {target}"
            ),
        )?;
        self.file_shell(device_id, &path, &command)?;
        Ok(())
    }

    pub fn download_entry(
        &self,
        device_id: &str,
        path: &str,
        local: &Path,
    ) -> Result<(), ServiceError> {
        let path = normalize_path(path)?;
        entry_target(&path)?;
        self.download_tree(device_id, &path, local, 0)
    }

    fn download_tree(
        &self,
        device_id: &str,
        path: &str,
        local: &Path,
        depth: usize,
    ) -> Result<(), ServiceError> {
        check_depth(depth)?;
        let (parent, name) = entry_target(path)?;
        let target = quote(&format!("./{name}"));
        let command = at_path(
            parent,
            &format!(
                "[ ! -L {target} ] || exit 1; if [ -d {target} ]; then printf d; elif [ -f {target} ]; then printf f; else exit 1; fi"
            ),
        )?;
        let kind = self.file_shell(device_id, path, &command)?;
        if kind == b"d" {
            fs::create_dir(local).map_err(local_error)?;
            for entry in self.list_files(device_id, path)?.entries {
                validate_local_name(&entry.name)?;
                if !matches!(entry.kind, "directory" | "file") {
                    return Err(unsupported_entry());
                }
                self.download_tree(
                    device_id,
                    &format!("{path}/{}", entry.name),
                    &local.join(&entry.name),
                    depth + 1,
                )?;
            }
        } else if kind == b"f" {
            let parent_dir = local.parent().ok_or_else(invalid_path)?;
            let mut temporary = tempfile::NamedTempFile::new_in(parent_dir).map_err(local_error)?;
            let command = at_path(
                parent,
                &format!("[ -f {target} ] && [ ! -L {target} ] && cat {target}"),
            )?;
            self.shell_to(device_id, &command, temporary.as_file_mut())?;
            if depth == 0 {
                temporary.persist(local).map_err(|e| local_error(e.error))?;
            } else {
                temporary
                    .persist_noclobber(local)
                    .map_err(|e| local_error(e.error))?;
            }
        } else {
            return Err(invalid_response());
        }
        Ok(())
    }

    pub fn upload_entry(
        &self,
        device_id: &str,
        path: &str,
        local: &Path,
    ) -> Result<(), ServiceError> {
        let path = normalize_path(path)?;
        writable_directory(&path)?;
        self.upload_tree(device_id, &path, local, 0)
    }

    fn upload_tree(
        &self,
        device_id: &str,
        parent: &str,
        local: &Path,
        depth: usize,
    ) -> Result<(), ServiceError> {
        check_depth(depth)?;
        let name = local
            .file_name()
            .and_then(|s| s.to_str())
            .ok_or_else(invalid_path)?;
        validate_name(name)?;
        let metadata = fs::symlink_metadata(local).map_err(local_error)?;
        let path = format!("{}/{name}", parent.trim_end_matches('/'));
        if metadata.is_dir() {
            self.create_directory(device_id, parent, name)?;
            for entry in fs::read_dir(local).map_err(local_error)? {
                self.upload_tree(
                    device_id,
                    &path,
                    &entry.map_err(local_error)?.path(),
                    depth + 1,
                )?;
            }
        } else if metadata.is_file() {
            let mut input = fs::File::open(local).map_err(local_error)?;
            // Stage through sync, then inherit stdin through run-as for private directories.
            self.with_device(device_id, |device| {
                let mut output = Vec::new();
                Self::run_shell(
                    device,
                    "mktemp /data/local/tmp/android-tools.XXXXXXXXXX",
                    &mut output,
                )?;
                let stage = std::str::from_utf8(&output)
                    .map_err(|_| invalid_response())?
                    .trim();
                if !stage
                    .strip_prefix("/data/local/tmp/android-tools.")
                    .is_some_and(|suffix| {
                        !suffix.is_empty() && suffix.bytes().all(|b| b.is_ascii_alphanumeric())
                    })
                {
                    return Err(invalid_response());
                }
                let result = (|| {
                    device.push(&mut input, &stage)?;
                    Self::run_shell(
                        device,
                        &upload_command(parent, name, stage)?,
                        &mut io::sink(),
                    )
                })();
                let cleanup =
                    Self::run_shell(device, &format!("rm -f {}", quote(stage)), &mut io::sink());
                result.and(cleanup)
            })?;
        } else {
            return Err(unsupported_entry());
        }
        Ok(())
    }

    pub fn list_files(&self, device_id: &str, path: &str) -> Result<FileListing, ServiceError> {
        let path = normalize_path(path)?;
        let mut entries = if path == "/data" {
            // Android prevents shell from enumerating /data. Expose the private-app route.
            vec![FileEntry::directory("data")]
        } else if path == "/data/data" {
            let output = self.shell(device_id, "pm list packages --user 0")?;
            parse_packages(&output)?
        } else {
            let command = at_path(&path, LIST_SCRIPT)?;
            let output = self.file_shell(device_id, &path, &command)?;
            parse_entries(&output)?
        };
        entries.sort_by(|a, b| {
            (a.kind != "directory")
                .cmp(&(b.kind != "directory"))
                .then_with(|| a.name.cmp(&b.name))
        });
        Ok(FileListing { path, entries })
    }

    pub fn preview_file(&self, device_id: &str, path: &str) -> Result<FilePreview, ServiceError> {
        let path = normalize_path(path)?;
        let (parent, name) = path.rsplit_once('/').ok_or_else(invalid_path)?;
        if name.is_empty() || parent == "/data/data" || path == "/data/data" {
            return Err(invalid_path());
        }
        let file = quote(&format!("./{name}"));
        // Refuse devices, pipes and links; previewing them could block the USB session.
        let script = format!(
            "[ -f {file} ] && [ ! -L {file} ] || exit 1; head -c {} {file}",
            PREVIEW_LIMIT + 1
        );
        let command = at_path(if parent.is_empty() { "/" } else { parent }, &script)?;
        let bytes = self.file_shell(device_id, &path, &command)?;
        decode_preview(&bytes)
    }

    fn file_shell(
        &self,
        device_id: &str,
        path: &str,
        command: &str,
    ) -> Result<Vec<u8>, ServiceError> {
        self.shell(device_id, command).map_err(|error| {
            if error.code == "shell" && path.starts_with("/data/data/") {
                ServiceError::new(
                    "private_access",
                    "Accès aux données privées refusé. L’application doit être debuggable et autoriser run-as (utilisateur Android principal).",
                    error.details,
                )
            } else {
                error
            }
        })
    }
}

fn invalid_path() -> ServiceError {
    ServiceError::new(
        "invalid_path",
        "Le chemin Android est invalide.",
        "Expected an absolute path without parent traversal or NUL bytes",
    )
}

fn upload_command(parent: &str, name: &str, stage: &str) -> Result<String, ServiceError> {
    validate_name(name)?;
    let target = quote(&format!("./{name}"));
    let write = at_path(
        parent,
        &format!("[ ! -e {target} ] && [ ! -L {target} ] || exit 1; set -C; cat > {target}"),
    )?;
    Ok(format!("sh -c {} < {}", quote(&write), quote(stage)))
}

fn local_error(error: io::Error) -> ServiceError {
    ServiceError::new(
        "file_transfer",
        "Le transfert a échoué. Vérifiez les droits et l’espace disponible. Un transfert de dossier peut être partiel ; choisissez une nouvelle destination pour réessayer.",
        error.to_string(),
    )
}

fn unsupported_entry() -> ServiceError {
    ServiceError::new(
        "unsupported_file",
        "Le transfert contient un lien symbolique ou un fichier spécial non pris en charge. Les éléments précédents ont pu être transférés.",
        "Only regular files and directories can be transferred",
    )
}

fn check_depth(depth: usize) -> Result<(), ServiceError> {
    if depth > 128 {
        return Err(invalid_path());
    }
    Ok(())
}

fn validate_name(name: &str) -> Result<(), ServiceError> {
    if name.is_empty() || matches!(name, "." | "..") || name.contains(['/', '\0']) {
        return Err(invalid_path());
    }
    Ok(())
}

fn validate_local_name(name: &str) -> Result<(), ServiceError> {
    validate_name(name)?;
    if name.contains('\\') || name.contains(':') || Path::new(name).components().count() != 1 {
        return Err(invalid_path());
    }
    Ok(())
}

fn writable_directory(path: &str) -> Result<(), ServiceError> {
    if matches!(path, "/data" | "/data/data") {
        return Err(invalid_path());
    }
    Ok(())
}

fn entry_target(path: &str) -> Result<(&str, &str), ServiceError> {
    let (parent, name) = path.rsplit_once('/').ok_or_else(invalid_path)?;
    validate_name(name)?;
    writable_directory(parent)?;
    if path == "/data" {
        return Err(invalid_path());
    }
    Ok((if parent.is_empty() { "/" } else { parent }, name))
}

fn invalid_response() -> ServiceError {
    ServiceError::new(
        "invalid_response",
        "La réponse de l’explorateur Android est invalide.",
        "Unable to decode file metadata",
    )
}

fn normalize_path(path: &str) -> Result<String, ServiceError> {
    if !path.starts_with('/') || path.contains('\0') || path.len() > 4096 {
        return Err(invalid_path());
    }
    let mut parts = Vec::new();
    for part in path.split('/') {
        match part {
            ".." => return Err(invalid_path()),
            "" | "." => (),
            _ => parts.push(part),
        }
    }
    Ok(format!("/{}", parts.join("/")))
}

fn quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', "'\\''"))
}

fn valid_package(package: &str) -> bool {
    !package.is_empty()
        && package.split('.').all(|part| {
            !part.is_empty() && part.bytes().all(|c| c.is_ascii_alphanumeric() || c == b'_')
        })
}

fn at_path(path: &str, script: &str) -> Result<String, ServiceError> {
    if let Some(private) = path.strip_prefix("/data/data/") {
        let (package, relative) = private.split_once('/').unwrap_or((private, ""));
        if !valid_package(package) {
            return Err(invalid_path());
        }
        // run-as starts in the app data directory. Keep nested paths relative to it.
        let script = format!("cd {} && {{\n{script}\n}}", quote(&format!("./{relative}")));
        Ok(format!(
            "run-as {} sh -c {}",
            quote(package),
            quote(&script)
        ))
    } else {
        Ok(format!("cd {} && {{\n{script}\n}}", quote(path)))
    }
}

fn parse_packages(bytes: &[u8]) -> Result<Vec<FileEntry>, ServiceError> {
    let output = std::str::from_utf8(bytes).map_err(|_| invalid_response())?;
    let mut packages = Vec::new();
    for line in output.lines().filter(|line| !line.trim().is_empty()) {
        let package = line
            .trim()
            .strip_prefix("package:")
            .ok_or_else(invalid_response)?;
        if !valid_package(package) {
            return Err(invalid_response());
        }
        packages.push(package);
    }
    packages.sort_unstable();
    packages.dedup();
    Ok(packages.into_iter().map(FileEntry::directory).collect())
}

fn parse_entries(mut bytes: &[u8]) -> Result<Vec<FileEntry>, ServiceError> {
    let mut entries = Vec::new();
    while !bytes.is_empty() {
        let end = bytes
            .iter()
            .position(|b| *b == b'\n')
            .ok_or_else(invalid_response)?;
        let metadata = std::str::from_utf8(&bytes[..end]).map_err(|_| invalid_response())?;
        let fields: Vec<_> = metadata.split_whitespace().collect();
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
        let name = std::str::from_utf8(&bytes[..end]).map_err(|_| invalid_response())?;
        if name.is_empty() || name == "." || name == ".." || name.contains('/') {
            return Err(invalid_response());
        }
        entries.push(FileEntry {
            name: name.to_owned(),
            kind: match mode & 0o170000 {
                0o040000 => "directory",
                0o100000 => "file",
                0o120000 => "symlink",
                _ => "other",
            },
            size: Some(size),
            modified_at: Some(modified_at),
            permissions: Some(format!("{:04o}", mode & 0o7777)),
        });
        bytes = &bytes[end + 1..];
    }
    Ok(entries)
}

fn decode_preview(bytes: &[u8]) -> Result<FilePreview, ServiceError> {
    let truncated = bytes.len() > PREVIEW_LIMIT;
    let bytes = &bytes[..bytes.len().min(PREVIEW_LIMIT)];
    let binary_error = || {
        ServiceError::new(
            "binary_file",
            "L’aperçu est disponible uniquement pour les fichiers texte UTF-8.",
            "Binary or non-UTF-8 content",
        )
    };
    if bytes
        .iter()
        .any(|b| *b < 32 && !matches!(b, b'\n' | b'\r' | b'\t'))
    {
        return Err(binary_error());
    }
    let text = match std::str::from_utf8(bytes) {
        Ok(text) => text,
        Err(error) if truncated && error.error_len().is_none() => {
            std::str::from_utf8(&bytes[..error.valid_up_to()]).map_err(|_| binary_error())?
        }
        Err(_) => return Err(binary_error()),
    };
    Ok(FilePreview {
        text: text.to_owned(),
        truncated,
    })
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;

    #[cfg(unix)]
    #[test]
    fn upload_stream_preserves_binary_data_and_refuses_collisions() {
        let directory = tempfile::tempdir().unwrap();
        let parent = directory.path().to_str().unwrap();
        let source = directory.path().join("source ' file");
        let bytes = b"binary\0\xff\r\ncontent";
        fs::write(&source, bytes).unwrap();
        let name = "-a ' ; $(exit 99)\n.bin";
        let command = upload_command(parent, name, source.to_str().unwrap()).unwrap();
        let run = |command: &str| {
            std::process::Command::new("sh")
                .args(["-c", command])
                .output()
                .unwrap()
                .status
                .success()
        };
        assert!(run(&command));
        assert_eq!(fs::read(directory.path().join(name)).unwrap(), bytes);
        fs::write(&source, b"replacement").unwrap();
        assert!(!run(&command));
        assert_eq!(fs::read(directory.path().join(name)).unwrap(), bytes);
        std::os::unix::fs::symlink(
            directory.path().join("missing"),
            directory.path().join("link"),
        )
        .unwrap();
        assert!(!run(&upload_command(
            parent,
            "link",
            source.to_str().unwrap()
        )
        .unwrap()));
        assert!(!directory.path().join("missing").exists());
        assert!(!run(
            &upload_command(parent, "new", "/nonexistent/source").unwrap()
        ));
        assert!(!directory.path().join("new").exists());
    }

    #[test]
    fn validates_mutation_targets_and_transfer_names() {
        for path in ["/", "/data", "/data/data", "/data/data/com.example"] {
            assert!(entry_target(path).is_err(), "{path}");
        }
        assert_eq!(
            entry_target("/data/data/com.example/files/a").unwrap(),
            ("/data/data/com.example/files", "a")
        );
        for name in ["", ".", "..", "a/b", "a\0b"] {
            assert!(validate_name(name).is_err());
        }
        for name in ["../escape", "a\\b", "C:escape"] {
            assert!(validate_local_name(name).is_err());
        }
        assert!(validate_name("a ' ; $(id)\n.txt").is_ok());
        assert!(check_depth(129).is_err());
    }

    #[test]
    fn parses_metadata_without_splitting_names() {
        let entries = parse_entries(b"41ed 4096 1700000000\n.hidden dir\0".as_slice()).unwrap();
        assert_eq!(entries[0].kind, "directory");
        assert_eq!(entries[0].permissions.as_deref(), Some("0755"));
        let entries =
            parse_entries(b"81a4 12 1700000001\na\n'b;$(id).txt\0a1ff 4 0\nlink\0").unwrap();
        assert_eq!(entries[0].name, "a\n'b;$(id).txt");
        assert_eq!(entries[0].size, Some(12));
        assert_eq!(entries[1].kind, "symlink");
        assert!(parse_entries(b"81a4 12 0\nincomplete").is_err());
        assert!(parse_entries(b"Permission denied\n").is_err());
        assert!(parse_entries(b"81a4 12 0\n../escape\0").is_err());
        assert!(parse_entries(b"").unwrap().is_empty());
    }

    #[test]
    fn validates_paths_and_quotes_nested_run_as_commands() {
        assert_eq!(
            normalize_path("//sdcard/./Download/").unwrap(),
            "/sdcard/Download"
        );
        for path in ["relative", "/sdcard/../data", "/a\0b"] {
            assert!(normalize_path(path).is_err());
        }
        assert_eq!(quote("a'b"), "'a'\\''b'");
        assert_eq!(
            at_path("/data/data/com.example", "pwd").unwrap(),
            "run-as 'com.example' sh -c 'cd '\\''./'\\'' && {\npwd\n}'"
        );
        assert!(at_path("/data/data/--user", "pwd").is_err());
        assert!(at_path("/data/data/com.app;id", "pwd").is_err());
        assert!(
            at_path("/data/data/com.example/files", "pwd")
                .unwrap()
                .contains("./files")
        );
    }

    #[test]
    fn parses_package_list_and_rejects_errors() {
        let entries = parse_packages(b"package:com.b\npackage:com.a\r\npackage:com.a\n").unwrap();
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].name, "com.a");
        assert!(parse_packages(b"Error: package manager unavailable").is_err());
    }

    #[test]
    fn bounds_preview_and_handles_binary_and_utf8_boundaries() {
        assert_eq!(decode_preview(b"hello\n").unwrap().text, "hello\n");
        assert!(decode_preview(b"a\0b").is_err());
        assert!(decode_preview(&[255]).is_err());
        let mut bytes = vec![b'a'; PREVIEW_LIMIT - 1];
        bytes.extend_from_slice("é".as_bytes());
        let preview = decode_preview(&bytes).unwrap();
        assert!(preview.truncated);
        assert_eq!(preview.text.len(), PREVIEW_LIMIT - 1);
    }
}
