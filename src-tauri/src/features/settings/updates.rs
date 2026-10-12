use std::future::Future;

use super::domain::SettingsError;

/// An update whose installer must verify its signature before executing it.
pub(super) trait PendingUpdate: Send {
    fn version(&self) -> &str;
    fn install(self) -> impl Future<Output = Result<(), SettingsError>> + Send;
}

/// Separates network, native dialogs and installation from update policy.
pub(super) trait UpdateBackend: Sync {
    type Update: PendingUpdate;
    fn discover(&self) -> impl Future<Output = Result<Option<Self::Update>, SettingsError>> + Send;
    fn confirm(&self, version: &str) -> impl Future<Output = Result<bool, SettingsError>> + Send;
    fn notify_current(&self) -> impl Future<Output = Result<(), SettingsError>> + Send;
}

/// Startup checks stay quiet when current; installation always requires consent.
pub(super) async fn check(
    backend: &impl UpdateBackend,
    interactive: bool,
) -> Result<(), SettingsError> {
    match backend.discover().await? {
        Some(update) => {
            if backend.confirm(update.version()).await? {
                update.install().await?;
            }
        }
        None if interactive => backend.notify_current().await?,
        None => {}
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::features::settings::domain::ErrorCode;
    use std::sync::{Arc, Mutex};

    struct FakeBackend {
        events: Arc<Mutex<Vec<&'static str>>>,
        available: bool,
        accept: bool,
        fail_check: bool,
        fail_install: bool,
    }

    struct FakeUpdate {
        events: Arc<Mutex<Vec<&'static str>>>,
        fail: bool,
    }

    fn failure() -> SettingsError {
        SettingsError {
            code: ErrorCode::UpdateFailed,
            message: "Simulated update failure.",
        }
    }

    impl PendingUpdate for FakeUpdate {
        fn version(&self) -> &str {
            "2026.10.9"
        }
        async fn install(self) -> Result<(), SettingsError> {
            self.events
                .lock()
                .expect("events")
                .push("verify_and_install");
            if self.fail { Err(failure()) } else { Ok(()) }
        }
    }

    impl UpdateBackend for FakeBackend {
        type Update = FakeUpdate;
        async fn discover(&self) -> Result<Option<FakeUpdate>, SettingsError> {
            self.events.lock().expect("events").push("discover");
            if self.fail_check {
                return Err(failure());
            }
            Ok(self.available.then(|| FakeUpdate {
                events: self.events.clone(),
                fail: self.fail_install,
            }))
        }
        async fn confirm(&self, version: &str) -> Result<bool, SettingsError> {
            assert_eq!(version, "2026.10.9");
            self.events.lock().expect("events").push("confirm");
            Ok(self.accept)
        }
        async fn notify_current(&self) -> Result<(), SettingsError> {
            self.events.lock().expect("events").push("current");
            Ok(())
        }
    }

    fn run(fake: &FakeBackend, interactive: bool) -> Result<(), SettingsError> {
        tokio::runtime::Builder::new_current_thread()
            .build()
            .expect("runtime")
            .block_on(check(fake, interactive))
    }

    #[test]
    fn requires_consent_for_startup_and_manual_updates_and_propagates_install_failure() {
        for interactive in [false, true] {
            for accept in [false, true] {
                for fail_install in [false, true] {
                    let fake = FakeBackend {
                        events: Arc::default(),
                        available: true,
                        accept,
                        fail_check: false,
                        fail_install,
                    };
                    assert_eq!(run(&fake, interactive).is_err(), accept && fail_install);
                    let mut expected = vec!["discover", "confirm"];
                    if accept {
                        expected.push("verify_and_install");
                    }
                    assert_eq!(*fake.events.lock().expect("events"), expected);
                }
            }
        }
    }

    #[test]
    fn only_manual_checks_report_current_and_network_errors_never_install() {
        for interactive in [false, true] {
            for fail_check in [false, true] {
                let fake = FakeBackend {
                    events: Arc::default(),
                    available: false,
                    accept: true,
                    fail_check,
                    fail_install: false,
                };
                assert_eq!(run(&fake, interactive).is_err(), fail_check);
                let expected = if interactive && !fail_check {
                    vec!["discover", "current"]
                } else {
                    vec!["discover"]
                };
                assert_eq!(*fake.events.lock().expect("events"), expected);
            }
        }
    }
}
