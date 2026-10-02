use std::{
    path::PathBuf,
    sync::{
        Arc, Mutex,
        atomic::{AtomicBool, Ordering},
    },
};

use serde::{Deserialize, Serialize};
use tauri::{Manager, State};
use tauri_plugin_opener::OpenerExt;

const PROJECT: &str = "https://github.com/ThomasBernard03/AndroidTools";
const DSN: Option<&str> = option_env!("SENTRY_DSN");

#[derive(Default, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
struct Preferences {
    crash_reporting_disabled: bool,
}

pub struct Settings {
    path: PathBuf,
    enabled: Arc<AtomicBool>,
    write_lock: Mutex<()>,
    _sentry: sentry::ClientInitGuard,
}

impl Settings {
    pub fn load(path: PathBuf, version: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let preferences = match std::fs::read(&path) {
            Ok(bytes) => serde_json::from_slice::<Preferences>(&bytes)?,
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => Preferences::default(),
            Err(error) => return Err(error.into()),
        };
        let enabled = Arc::new(AtomicBool::new(!preferences.crash_reporting_disabled));
        let gate = enabled.clone();
        let guard = sentry::init(sentry::ClientOptions {
            dsn: DSN
                .filter(|dsn| !dsn.is_empty())
                .map(str::parse)
                .transpose()?,
            release: Some(format!("android-tools@{version}").into()),
            send_default_pii: false,
            auto_session_tracking: false,
            before_send: Some(Arc::new(move |mut event| {
                if !gate.load(Ordering::SeqCst) {
                    return None;
                }
                event.breadcrumbs.values.clear();
                event.request = None;
                event.user = None;
                Some(event)
            })),
            ..Default::default()
        });
        let previous_hook = std::panic::take_hook();
        std::panic::set_hook(Box::new(move |info| {
            log::error!("Application panic at {:?}", info.location());
            previous_hook(info);
        }));
        Ok(Self {
            path,
            enabled,
            write_lock: Mutex::new(()),
            _sentry: guard,
        })
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SettingsResponse {
    crash_reporting_enabled: bool,
    sentry_dsn: Option<&'static str>,
}

#[tauri::command]
pub fn get_settings(settings: State<'_, Settings>) -> SettingsResponse {
    SettingsResponse {
        crash_reporting_enabled: settings.enabled.load(Ordering::SeqCst),
        sentry_dsn: DSN.filter(|dsn| !dsn.is_empty()),
    }
}

#[tauri::command]
pub fn set_crash_reporting(enabled: bool, settings: State<'_, Settings>) -> Result<(), String> {
    let _lock = settings
        .write_lock
        .lock()
        .map_err(|_| "Réglages indisponibles.")?;
    let parent = settings
        .path
        .parent()
        .ok_or("Dossier de réglages indisponible.")?;
    std::fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    let mut file = tempfile::NamedTempFile::new_in(parent).map_err(|e| e.to_string())?;
    serde_json::to_writer(
        &mut file,
        &Preferences {
            crash_reporting_disabled: !enabled,
        },
    )
    .map_err(|e| e.to_string())?;
    file.as_file().sync_all().map_err(|e| e.to_string())?;
    file.persist(&settings.path).map_err(|e| e.to_string())?;
    settings.enabled.store(enabled, Ordering::SeqCst);
    log::info!("Crash reporting preference updated: {enabled}");
    Ok(())
}

#[tauri::command]
pub fn open_app_log(app: tauri::AppHandle) -> Result<(), String> {
    log::logger().flush();
    let path = app
        .path()
        .app_log_dir()
        .map_err(|e| e.to_string())?
        .join("android-tools.log");
    app.opener()
        .open_path(path.to_string_lossy(), None::<&str>)
        .map_err(|e| e.to_string())
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ProjectLink {
    Repository,
    Issue,
    Releases,
}

#[tauri::command]
pub fn open_project_link(link: ProjectLink, app: tauri::AppHandle) -> Result<(), String> {
    let suffix = match link {
        ProjectLink::Repository => "",
        ProjectLink::Issue => "/issues/new/choose",
        ProjectLink::Releases => "/releases/latest",
    };
    app.opener()
        .open_url(format!("{PROJECT}{suffix}"), None::<&str>)
        .map_err(|e| e.to_string())
}

#[derive(Deserialize)]
struct Release {
    tag_name: String,
}

#[derive(Debug, Serialize)]
#[serde(tag = "status", rename_all = "camelCase")]
pub enum UpdateStatus {
    #[cfg(all(target_os = "macos", feature = "macos-updater"))]
    Native,
    Available {
        version: String,
    },
    Current,
}

fn compare_release(current: &str, tag: &str) -> Result<UpdateStatus, String> {
    // Historical calendar-version tags use a zero-padded month (2026.06.1).
    let raw = tag.trim_start_matches('v');
    let boundary = raw.find(['-', '+']).unwrap_or(raw.len());
    let normalized = raw[..boundary]
        .split('.')
        .map(|part| {
            if !part.is_empty() && part.bytes().all(|byte| byte.is_ascii_digit()) {
                let number = part.trim_start_matches('0');
                if number.is_empty() { "0" } else { number }
            } else {
                part
            }
        })
        .collect::<Vec<_>>()
        .join(".")
        + &raw[boundary..];
    let latest = semver::Version::parse(&normalized)
        .map_err(|_| "La version publiée sur GitHub n’a pas un format reconnu.".to_string())?;
    let current = semver::Version::parse(current).map_err(|e| e.to_string())?;
    Ok(if latest > current {
        UpdateStatus::Available {
            version: tag.to_owned(),
        }
    } else {
        UpdateStatus::Current
    })
}

#[tauri::command]
pub async fn check_app_updates(app: tauri::AppHandle) -> Result<UpdateStatus, String> {
    log::info!("Checking for application updates");
    #[cfg(all(target_os = "macos", feature = "macos-updater"))]
    {
        use tauri_plugin_sparkle_updater::SparkleUpdaterExt;
        if let Some(updater) = app.sparkle_updater() {
            updater.check_for_updates().map_err(|e| e.to_string())?;
            return Ok(UpdateStatus::Native);
        }
    }
    let release = reqwest::Client::builder()
        .user_agent(concat!("AndroidTools/", env!("CARGO_PKG_VERSION")))
        .timeout(std::time::Duration::from_secs(20))
        .build()
        .map_err(|e| e.to_string())?
        .get("https://api.github.com/repos/ThomasBernard03/AndroidTools/releases/latest")
        .send()
        .await
        .map_err(|e| e.to_string())?
        .error_for_status()
        .map_err(|e| e.to_string())?
        .json::<Release>()
        .await
        .map_err(|e| e.to_string())?;
    compare_release(&app.package_info().version.to_string(), &release.tag_name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compares_versions_numerically_and_rejects_unknown_tags() {
        assert!(matches!(
            compare_release("1.9.0", "v1.10.0"),
            Ok(UpdateStatus::Available { .. })
        ));
        assert!(matches!(
            compare_release("1.10.0", "v1.9.0"),
            Ok(UpdateStatus::Current)
        ));
        assert!(matches!(
            compare_release("1.10.0", "1.10.0"),
            Ok(UpdateStatus::Current)
        ));
        assert!(compare_release("1.0.0", "latest").is_err());
        assert!(matches!(
            compare_release("2026.6.2", "2026.06.1"),
            Ok(UpdateStatus::Current)
        ));
        assert!(matches!(
            compare_release("2026.6.2", "v2026.07.1"),
            Ok(UpdateStatus::Available { .. })
        ));
    }

    #[test]
    fn preference_survives_restart() {
        let dir = tempfile::tempdir().expect("temporary directory");
        let path = dir.path().join("settings.json");
        std::fs::write(&path, r#"{"crashReportingDisabled":true}"#).expect("write settings");
        let settings = Settings::load(path, "1.0.0").expect("load settings");
        assert!(!settings.enabled.load(Ordering::SeqCst));
    }
}
