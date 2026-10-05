use super::domain::FileError;

pub fn invalid_path() -> FileError {
    FileError::new(
        "invalid_path",
        "Use an absolute Android path without parent traversal, and a single nonempty entry name.",
    )
}

pub fn name(value: &str) -> Result<(), FileError> {
    if value.is_empty()
        || matches!(value, "." | "..")
        || value.contains(['/', '\0'])
        || value.len() > 255
    {
        return Err(invalid_path());
    }
    Ok(())
}

pub fn normalize(path: &str) -> Result<String, FileError> {
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

pub fn quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', "'\\''"))
}

pub fn package(value: &str) -> bool {
    !value.is_empty()
        && value.split('.').all(|part| {
            !part.is_empty() && part.bytes().all(|c| c.is_ascii_alphanumeric() || c == b'_')
        })
}

pub fn writable(path: &str) -> Result<(), FileError> {
    if matches!(path, "/data" | "/data/data" | "/data/user" | "/data/user/0") {
        return Err(invalid_path());
    }
    Ok(())
}

pub fn target(path: &str) -> Result<(&str, &str), FileError> {
    let (parent, entry) = path.rsplit_once('/').ok_or_else(invalid_path)?;
    name(entry)?;
    writable(parent)?;
    if matches!(path, "/data" | "/sdcard" | "/storage" | "/data/user") {
        return Err(invalid_path());
    }
    Ok((if parent.is_empty() { "/" } else { parent }, entry))
}

pub fn join(parent: &str, entry: &str) -> String {
    format!("{}/{entry}", parent.trim_end_matches('/'))
}

/// run-as starts in the primary user's private application directory.
pub fn at(path: &str, script: &str) -> Result<String, FileError> {
    if let Some(private) = path.strip_prefix("/data/data/") {
        let (app, relative) = private.split_once('/').unwrap_or((private, ""));
        if !package(app) {
            return Err(invalid_path());
        }
        Ok(format!(
            "run-as {} sh -c {}",
            quote(app),
            quote(&format!(
                "cd {} || exit 43\n{script}",
                quote(&format!("./{relative}"))
            ))
        ))
    } else {
        Ok(format!("cd {} || exit 43\n{script}", quote(path)))
    }
}

pub fn local_name(value: &str) -> Result<(), FileError> {
    name(value)?;
    // Reject names that could escape or alias another entry on supported host filesystems.
    if value.contains(['\\', ':'])
        || value.ends_with(['.', ' '])
        || value.chars().any(|c| c < ' ' || "<>\"|?*".contains(c))
    {
        return Err(FileError::new(
            "unsupported_name",
            "An Android filename cannot be represented safely on the host filesystem.",
        ));
    }
    let stem = value.split('.').next().unwrap_or("").to_ascii_uppercase();
    if matches!(stem.as_str(), "CON" | "PRN" | "AUX" | "NUL")
        || (stem.len() == 4
            && (stem.starts_with("COM") || stem.starts_with("LPT"))
            && matches!(stem.as_bytes()[3], b'1'..=b'9'))
    {
        return Err(FileError::new(
            "unsupported_name",
            "An Android filename is reserved on the host filesystem.",
        ));
    }
    Ok(())
}
