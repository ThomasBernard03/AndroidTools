use std::{collections::BTreeMap, sync::Arc};

use tokio::sync::Mutex;

use super::domain::{AdbConnector, AdbError, AdbErrorCode, AdbSession, AndroidInfo};

struct ActiveSession {
    id: String,
    session: Box<dyn AdbSession>,
}

/// Owns one authenticated session. Changing selection or any transport failure releases it.
#[derive(Clone)]
pub struct AdbService {
    connector: Arc<dyn AdbConnector>,
    active: Arc<Mutex<Option<ActiveSession>>>,
}

impl AdbService {
    /// Holds the selected connection for a complete operation, including recursive transfers.
    /// Failed operations release the session so a retry cannot reuse a broken transport.
    pub async fn with_session<T, E, F>(&self, id: &str, operation: F) -> Result<T, E>
    where
        E: From<AdbError>,
        F: for<'a> FnOnce(
            &'a dyn AdbSession,
        ) -> std::pin::Pin<
            Box<dyn std::future::Future<Output = Result<T, E>> + Send + 'a>,
        >,
    {
        let mut active = self.active.lock().await;
        if active.as_ref().is_none_or(|session| session.id != id) {
            *active = None;
            *active = Some(ActiveSession {
                id: id.into(),
                session: self.connector.connect(id).await?,
            });
        }
        let result = operation(
            active
                .as_ref()
                .expect("session established")
                .session
                .as_ref(),
        )
        .await;
        if result.is_err() {
            *active = None;
        }
        result
    }

    pub fn new(connector: impl AdbConnector + 'static) -> Self {
        Self {
            connector: Arc::new(connector),
            active: Arc::new(Mutex::new(None)),
        }
    }

    /// Connects if needed and reads a fresh snapshot. Operations are serialized.
    pub async fn read(&self, id: &str) -> Result<AndroidInfo, AdbError> {
        self.with_session(id, |session| Box::pin(read_information(session)))
            .await
    }

    /// Returns a bounded PNG data URL using the shared, serialized ADB connection.
    pub async fn capture_screen(&self, id: &str) -> Result<String, AdbError> {
        self.with_session(id, |session| Box::pin(super::screenshot::capture(session)))
            .await
    }

    /// Releases the USB interface when no device is selected or the view closes.
    pub async fn disconnect(&self) {
        *self.active.lock().await = None;
    }
}

async fn read_information(session: &dyn AdbSession) -> Result<AndroidInfo, AdbError> {
    let properties = session.shell("getprop").await?;
    let mut info = parse_properties(&properties)?;
    match session.shell("dumpsys battery").await {
        Ok(battery) => {
            let (percent, status) = parse_battery(&battery);
            info.battery_percent = percent;
            info.battery_status = status;
            if percent.is_none() {
                info.warning = Some("Battery information is unavailable on this device.".into());
            }
        }
        Err(error) if error.code == AdbErrorCode::ReadFailed => {
            info.warning = Some(
                "Android properties were read, but battery information is unavailable.".into(),
            );
        }
        Err(error) => return Err(error),
    }
    Ok(info)
}

fn parse_properties(output: &str) -> Result<AndroidInfo, AdbError> {
    let properties: BTreeMap<_, _> = output
        .lines()
        .filter_map(|line| {
            let (key, value) = line
                .trim()
                .strip_prefix('[')?
                .strip_suffix(']')?
                .split_once("]: [")?;
            Some((key, value.trim()))
        })
        .collect();
    if properties.is_empty() {
        return Err(AdbError::new(
            AdbErrorCode::ReadFailed,
            "Android system properties could not be read. Retry the ADB connection.",
        ));
    }
    let value = |key| {
        properties
            .get(key)
            .filter(|value| !value.is_empty())
            .map(|value| (*value).to_owned())
    };
    Ok(AndroidInfo {
        manufacturer: value("ro.product.manufacturer"),
        model: value("ro.product.model"),
        android_version: value("ro.build.version.release"),
        api_level: value("ro.build.version.sdk"),
        security_patch: value("ro.build.version.security_patch"),
        build_id: value("ro.build.display.id"),
        architecture: value("ro.product.cpu.abilist").or_else(|| value("ro.product.cpu.abi")),
        battery_percent: None,
        battery_status: None,
        warning: None,
    })
}

fn parse_battery(output: &str) -> (Option<u8>, Option<String>) {
    let fields: BTreeMap<_, _> = output
        .lines()
        .filter_map(|line| {
            let (key, value) = line.trim().split_once(':')?;
            Some((key, value.trim()))
        })
        .collect();
    let number = |key| fields.get(key).and_then(|value| value.parse::<u32>().ok());
    let percent = number("level")
        .zip(number("scale"))
        .and_then(|(level, scale)| {
            (scale > 0 && level <= scale)
                .then(|| ((u64::from(level) * 100) / u64::from(scale)) as u8)
        });
    let status = match number("status") {
        Some(2) => Some("Charging"),
        Some(3) => Some("Discharging"),
        Some(4) => Some("Not charging"),
        Some(5) => Some("Full"),
        _ => None,
    }
    .map(str::to_owned);
    (percent, status)
}

#[cfg(test)]
mod tests {
    use super::super::domain::AdbFuture;
    use super::*;
    use std::sync::{
        Mutex as SyncMutex,
        atomic::{AtomicUsize, Ordering},
    };

    const PROPERTIES: &str = "[ro.product.model]: [Pixel 9]\r\n[ro.build.version.release]: [16]\n[ro.product.cpu.abi]: [arm64-v8a]\n[ro.build.version.security_patch]: []\n";

    struct FakeConnector {
        connections: Arc<SyncMutex<Vec<String>>>,
        drops: Arc<AtomicUsize>,
    }
    struct FakeSession {
        drops: Arc<AtomicUsize>,
        battery_error: Option<AdbErrorCode>,
    }
    impl Drop for FakeSession {
        fn drop(&mut self) {
            self.drops.fetch_add(1, Ordering::SeqCst);
        }
    }
    impl AdbSession for FakeSession {
        fn shell<'a>(&'a self, command: &'a str) -> AdbFuture<'a, String> {
            Box::pin(async move {
                match command {
                    "getprop" => Ok(PROPERTIES.into()),
                    "dumpsys battery" => match &self.battery_error {
                        Some(code) => Err(AdbError::new(code.clone(), "Simulated battery failure")),
                        None => Ok("level: 41\nscale: 50\nstatus: 2\n".into()),
                    },
                    _ => panic!("Unexpected command: {command}"),
                }
            })
        }
    }
    impl AdbConnector for FakeConnector {
        fn connect<'a>(&'a self, id: &'a str) -> AdbFuture<'a, Box<dyn AdbSession>> {
            Box::pin(async move {
                self.connections
                    .lock()
                    .expect("connections lock")
                    .push(id.into());
                if id == "unauthorized" {
                    return Err(AdbError::new(AdbErrorCode::Unauthorized, "Allow debugging"));
                }
                Ok(Box::new(FakeSession {
                    drops: self.drops.clone(),
                    battery_error: (id == "disconnected").then_some(AdbErrorCode::Disconnected),
                }) as Box<dyn AdbSession>)
            })
        }
    }

    #[tokio::test]
    async fn reuses_the_selected_session_and_releases_it_on_switch_failure_and_disconnect() {
        let connections = Arc::new(SyncMutex::new(Vec::new()));
        let drops = Arc::new(AtomicUsize::new(0));
        let service = AdbService::new(FakeConnector {
            connections: connections.clone(),
            drops: drops.clone(),
        });
        let info = service.read("phone-a").await.expect("first read");
        assert_eq!(info.model.as_deref(), Some("Pixel 9"));
        assert_eq!(info.battery_percent, Some(82));
        service.read("phone-a").await.expect("repeat read");
        assert_eq!(
            *connections.lock().expect("connections lock"),
            vec!["phone-a"]
        );
        service.read("phone-b").await.expect("second phone");
        assert_eq!(drops.load(Ordering::SeqCst), 1);
        assert_eq!(
            service
                .read("unauthorized")
                .await
                .expect_err("authorization required")
                .code,
            AdbErrorCode::Unauthorized
        );
        assert_eq!(drops.load(Ordering::SeqCst), 2);
        service.read("phone-b").await.expect("retry");
        service.disconnect().await;
        assert_eq!(drops.load(Ordering::SeqCst), 3);
        assert_eq!(
            service
                .read("disconnected")
                .await
                .expect_err("disconnection")
                .code,
            AdbErrorCode::Disconnected
        );
        assert_eq!(drops.load(Ordering::SeqCst), 4);
        assert!(service.active.lock().await.is_none());
    }

    #[tokio::test]
    async fn keeps_properties_when_only_the_battery_command_is_unsupported() {
        let session = FakeSession {
            drops: Arc::new(AtomicUsize::new(0)),
            battery_error: Some(AdbErrorCode::ReadFailed),
        };
        let info = read_information(&session)
            .await
            .expect("partial information");
        assert_eq!(info.android_version.as_deref(), Some("16"));
        assert_eq!(info.battery_percent, None);
        assert!(info.warning.is_some());
    }

    #[test]
    fn parses_missing_properties_and_rejects_non_property_output() {
        let info = parse_properties(PROPERTIES).expect("properties");
        assert_eq!(info.security_patch, None);
        assert_eq!(info.manufacturer, None);
        assert_eq!(info.architecture.as_deref(), Some("arm64-v8a"));
        assert!(parse_properties("/system/bin/sh: getprop: not found").is_err());
        let json = serde_json::to_value(info).expect("serialize");
        assert_eq!(json["androidVersion"], "16");
        assert_eq!(json["securityPatch"], serde_json::Value::Null);
        assert!(json.get("batteryPercent").is_some());
        assert_eq!(
            serde_json::to_value(AdbError::new(AdbErrorCode::UsbAccess, "Denied"))
                .expect("serialize"),
            serde_json::json!({"code": "usb_access", "message": "Denied"})
        );
    }

    #[test]
    fn handles_battery_scale_empty_and_invalid_values_without_inventing_a_percentage() {
        assert_eq!(
            parse_battery("level: 0\nscale: 100\nstatus: 3"),
            (Some(0), Some("Discharging".into()))
        );
        assert_eq!(parse_battery("level: 101\nscale: 100"), (None, None));
        assert_eq!(parse_battery("level: 1\nscale: 0"), (None, None));
        assert_eq!(parse_battery("level: -1\nscale: 100"), (None, None));
        assert_eq!(parse_battery("Permission denied"), (None, None));
    }
}
