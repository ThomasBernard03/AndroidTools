use super::domain::{AppSettings, SettingsError};
use std::{io::Write, path::Path};

/// Missing settings are a first launch; unreadable or malformed files are errors.
pub fn load(directory: &Path) -> Result<AppSettings, SettingsError> {
    match std::fs::read(directory.join("settings.json")) {
        Ok(bytes) => serde_json::from_slice(&bytes).map_err(|_| SettingsError::storage()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(AppSettings::default()),
        Err(_) => Err(SettingsError::storage()),
    }
}

/// Atomically replace preferences so an interrupted write cannot truncate them.
pub fn set_crash_reporting(directory: &Path, enabled: bool) -> Result<AppSettings, SettingsError> {
    let mut settings = load(directory)?;
    settings.crash_reporting_enabled = enabled;
    std::fs::create_dir_all(directory).map_err(|_| SettingsError::storage())?;
    let bytes = serde_json::to_vec_pretty(&settings).map_err(|_| SettingsError::storage())?;
    let mut file =
        tempfile::NamedTempFile::new_in(directory).map_err(|_| SettingsError::storage())?;
    file.write_all(&bytes)
        .map_err(|_| SettingsError::storage())?;
    file.as_file()
        .sync_all()
        .map_err(|_| SettingsError::storage())?;
    file.persist(directory.join("settings.json"))
        .map_err(|_| SettingsError::storage())?;
    Ok(settings)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_to_off_and_persists_both_choices() {
        let directory = tempfile::tempdir().expect("temporary directory");
        let path = directory.path().join("app");
        assert!(!load(&path).expect("default").crash_reporting_enabled);
        for enabled in [true, false] {
            set_crash_reporting(&path, enabled).expect("save preference");
            assert_eq!(
                load(&path).expect("reload").crash_reporting_enabled,
                enabled
            );
        }
    }

    #[test]
    fn malformed_preferences_are_not_silently_overwritten() {
        let directory = tempfile::tempdir().expect("temporary directory");
        let path = directory.path().join("settings.json");
        std::fs::write(&path, b"broken").expect("fixture");
        assert!(load(directory.path()).is_err());
        assert!(set_crash_reporting(directory.path(), true).is_err());
        assert_eq!(std::fs::read(path).expect("original file"), b"broken");
    }

    #[test]
    fn storage_errors_are_reported() {
        let directory = tempfile::tempdir().expect("temporary directory");
        let path = directory.path().join("file");
        std::fs::write(&path, b"not a directory").expect("fixture");
        assert!(set_crash_reporting(&path, true).is_err());
    }

    #[test]
    fn settings_wire_contract_uses_camel_case() {
        assert_eq!(
            serde_json::to_value(AppSettings::default()).expect("serialize"),
            serde_json::json!({"crashReportingEnabled": false})
        );
    }
}
