use std::{io::Write, path::PathBuf, sync::Arc, time::Duration};

use rsadb::{
    auth::{HostKey, KeyPaths},
    device::Device,
    session::Session,
    transport::usb,
};
use tokio::sync::OnceCell;

use super::domain::{AdbConnector, AdbError, AdbErrorCode, AdbFuture, AdbSession};
use crate::features::devices::{
    domain::{DeviceRepository, DeviceSummary},
    infrastructure::UsbDeviceRepository,
};

/// Direct USB ADB with an application-specific, persistent host key.
pub struct UsbAdbConnector {
    key_directory: PathBuf,
    key: OnceCell<Arc<HostKey>>,
}

impl UsbAdbConnector {
    pub fn new(key_directory: PathBuf) -> Self {
        Self {
            key_directory,
            key: OnceCell::new(),
        }
    }
}

fn map_error(error: rsadb::Error) -> AdbError {
    use AdbErrorCode as Code;
    let (code, message) = match error {
        rsadb::Error::Unauthorized => (
            Code::Unauthorized,
            "Unlock your phone and allow USB debugging, then retry.",
        ),
        rsadb::Error::Disconnected | rsadb::Error::StreamClosed | rsadb::Error::NoDevice(_) => (
            Code::Disconnected,
            "The device disconnected. Refresh the device list and reconnect.",
        ),
        rsadb::Error::ClaimFailed(_) => (
            Code::UsbAccess,
            "Cannot claim the USB ADB interface. Check USB permissions and close other ADB clients. If an adb server is running, stop it before retrying.",
        ),
        rsadb::Error::Key(_) => (
            Code::Key,
            "The application's ADB host key could not be loaded or created.",
        ),
        rsadb::Error::Unsupported(_) => (
            Code::Unsupported,
            "This device requires an ADB authentication method that is not supported yet.",
        ),
        rsadb::Error::Timeout(_) => (
            Code::Timeout,
            "The ADB request timed out. Check the phone and retry.",
        ),
        rsadb::Error::Usb(_) | rsadb::Error::Io(_) => (
            Code::UsbAccess,
            "USB communication failed. Check the connection and USB permissions, then retry.",
        ),
        _ => (
            Code::ReadFailed,
            "The device could not complete the ADB request. Retry the connection.",
        ),
    };
    AdbError::new(code, message)
}

fn timeout_error() -> AdbError {
    AdbError::new(
        AdbErrorCode::Timeout,
        "The ADB request timed out. Unlock the phone, check USB debugging and retry.",
    )
}

/// Persist atomically without replacing a host key created by another app instance.
fn load_key(directory: PathBuf) -> Result<Arc<HostKey>, AdbError> {
    let paths = KeyPaths::in_dir(&directory);
    let result = (|| -> rsadb::error::Result<HostKey> {
        match std::fs::read_to_string(&paths.private) {
            Ok(pem) => return HostKey::from_pem(&pem, "AndroidTools"),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
            Err(error) => return Err(error.into()),
        }
        let key = HostKey::generate("AndroidTools")?;
        std::fs::create_dir_all(&directory)?;
        let mut file = tempfile::NamedTempFile::new_in(&directory)?;
        file.write_all(key.to_pem()?.as_bytes())?;
        file.as_file().sync_all()?;
        match file.persist_noclobber(&paths.private) {
            Ok(_) => Ok(key),
            Err(error) if error.error.kind() == std::io::ErrorKind::AlreadyExists => {
                rsadb::auth::read_key(&paths, "AndroidTools")
            }
            Err(error) => Err(error.error.into()),
        }
    })();
    result.map(Arc::new).map_err(|_| {
        AdbError::new(
            AdbErrorCode::Key,
            "The application's ADB host key could not be loaded or saved.",
        )
    })
}

fn selected_device(devices: Vec<DeviceSummary>, id: &str) -> Result<DeviceSummary, AdbError> {
    let device = devices
        .iter()
        .find(|device| device.id == id)
        .ok_or_else(|| {
            AdbError::new(
                AdbErrorCode::Disconnected,
                "The selected USB connection is no longer present. Refresh the device list.",
            )
        })?;
    if device.serial.is_none()
        || devices
            .iter()
            .filter(|other| {
                other.serial == device.serial
                    && other.vendor_id == device.vendor_id
                    && other.product_id == device.product_id
            })
            .count()
            != 1
    {
        return Err(AdbError::new(
            AdbErrorCode::IdentityUnavailable,
            "A unique USB serial number is required to connect to this device safely. Check USB metadata permissions and refresh.",
        ));
    }
    Ok(device.clone())
}

impl AdbConnector for UsbAdbConnector {
    fn connect<'a>(&'a self, connection_id: &'a str) -> AdbFuture<'a, Box<dyn AdbSession>> {
        Box::pin(async move {
            super::server::stop_local_server().await?;
            let key = self
                .key
                .get_or_try_init(|| async {
                    let directory = self.key_directory.clone();
                    tokio::task::spawn_blocking(move || load_key(directory))
                        .await
                        .map_err(|_| {
                            AdbError::new(
                                AdbErrorCode::Internal,
                                "ADB key initialization could not finish.",
                            )
                        })?
                })
                .await?;
            let devices = tokio::task::spawn_blocking(|| UsbDeviceRepository.list())
                .await
                .map_err(|_| {
                    AdbError::new(AdbErrorCode::Internal, "USB discovery could not finish.")
                })?
                .map_err(|error| AdbError::new(AdbErrorCode::UsbAccess, error.message))?;
            let selected = selected_device(devices, connection_id)?;
            tokio::time::timeout(Duration::from_secs(40), async {
                let matches: Vec<_> = usb::list().await.map_err(map_error)?.into_iter().filter(|device| {
                    device.serial() == selected.serial.as_deref() && device.vendor_id() == selected.vendor_id && device.product_id() == selected.product_id
                }).collect();
                if matches.len() != 1 {
                    return Err(AdbError::new(AdbErrorCode::Disconnected, "The selected device could not be uniquely located. Refresh the device list."));
                }
                let transport = usb::open(&matches[0]).await.map_err(map_error)?;
                let session = Session::connect(transport, key, Duration::from_secs(30)).await.map_err(map_error)?;
                Ok(Box::new(NativeSession(Device::new(session))) as Box<dyn AdbSession>)
            }).await.map_err(|_| timeout_error())?
        })
    }
}

struct NativeSession(Device<Session>);

impl AdbSession for NativeSession {
    fn file_shell<'a>(
        &'a self,
        command: &'a str,
        destination: Option<tokio::fs::File>,
    ) -> AdbFuture<'a, super::domain::FileShellOutput> {
        Box::pin(async move {
            tokio::time::timeout(
                Duration::from_secs(1800),
                file_shell(&self.0, command, destination),
            )
            .await
            .map_err(|_| timeout_error())?
        })
    }

    fn push<'a>(&'a self, local: &'a std::path::Path, remote: &'a str) -> AdbFuture<'a, ()> {
        Box::pin(async move {
            tokio::time::timeout(Duration::from_secs(1800), async {
                let file = tokio::fs::File::open(local).await?;
                let mut sync = self.0.sync().await?;
                // Staging data remains readable only by the shell UID, even for public sources.
                sync.push(remote, 0o100600, 0, file).await?;
                sync.quit().await
            })
            .await
            .map_err(|_| timeout_error())?
            .map_err(map_error)
        })
    }

    fn shell<'a>(&'a self, command: &'a str) -> AdbFuture<'a, String> {
        Box::pin(async move {
            if !self.0.connection().is_alive() {
                return Err(AdbError::new(
                    AdbErrorCode::Disconnected,
                    "The ADB connection closed. Reconnect the device and retry.",
                ));
            }
            let output = tokio::time::timeout(Duration::from_secs(10), self.0.shell(command))
                .await
                .map_err(|_| timeout_error())?
                .map_err(map_error)?;
            if !self.0.connection().is_alive() {
                return Err(AdbError::new(
                    AdbErrorCode::Disconnected,
                    "The device disconnected while reading Android information.",
                ));
            }
            if !output.success() {
                return Err(AdbError::new(
                    AdbErrorCode::ReadFailed,
                    "The Android information command failed.",
                ));
            }
            Ok(output.stdout_text())
        })
    }
}

async fn file_shell(
    device: &Device<Session>,
    command: &str,
    mut destination: Option<tokio::fs::File>,
) -> Result<super::domain::FileShellOutput, AdbError> {
    use rsadb::channel::{Channel, ChannelReader, Connection};
    use rsadb::services::shell_v2::{self, FrameId};
    use tokio::io::AsyncWriteExt;
    if !device.has_feature("shell_v2").await.map_err(map_error)? {
        return Err(AdbError::new(
            AdbErrorCode::Unsupported,
            "File operations require Android shell v2 (Android 7 or later).",
        ));
    }
    let mut channel = device
        .connection()
        .open(&format!("shell,v2,raw:{command}"))
        .await
        .map_err(map_error)?;
    channel
        .send(shell_v2::encode(FrameId::CloseStdin, &[]).map_err(map_error)?)
        .await
        .map_err(map_error)?;
    let mut reader = ChannelReader::new(channel);
    let mut parser = shell_v2::Parser::default();
    let mut stdout = Vec::new();
    let mut stderr = Vec::new();
    let mut exit = None;
    while let Some(chunk) = tokio::time::timeout(Duration::from_secs(30), reader.next_chunk())
        .await
        .map_err(|_| timeout_error())?
        .map_err(map_error)?
    {
        for frame in parser.push(&chunk).map_err(map_error)? {
            match frame.id {
                FrameId::Stdout => {
                    if let Some(file) = destination.as_mut() {
                        file.write_all(&frame.data).await.map_err(|_| AdbError::new(AdbErrorCode::ReadFailed, "Cannot write the download. Check local permissions and free space."))?;
                    } else {
                        if stdout.len() + frame.data.len() > 16 * 1024 * 1024 {
                            return Err(AdbError::new(
                                AdbErrorCode::ReadFailed,
                                "The directory listing exceeds the 16 MiB limit.",
                            ));
                        }
                        stdout.extend_from_slice(&frame.data);
                    }
                }
                FrameId::Stderr => stderr.extend_from_slice(
                    &frame.data[..frame.data.len().min(8192usize.saturating_sub(stderr.len()))],
                ),
                FrameId::Exit if frame.data.len() == 1 => exit = Some(frame.data[0]),
                _ => {
                    return Err(AdbError::new(
                        AdbErrorCode::ReadFailed,
                        "Invalid file command response.",
                    ));
                }
            }
        }
    }
    reader.channel().close().await.map_err(map_error)?;
    if parser.pending() != 0 || exit.is_none() {
        return Err(AdbError::new(
            AdbErrorCode::Disconnected,
            "The file command ended without a complete result. Its changes may have been partially applied.",
        ));
    }
    if let Some(file) = destination.as_mut() {
        file.flush().await.map_err(|_| {
            AdbError::new(
                AdbErrorCode::ReadFailed,
                "Cannot flush the download to disk.",
            )
        })?;
    }
    Ok(super::domain::FileShellOutput {
        stdout,
        stderr: String::from_utf8_lossy(&stderr).into_owned(),
        exit_code: exit.expect("checked exit"),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn device(id: &str, serial: Option<&str>) -> DeviceSummary {
        DeviceSummary {
            id: id.into(),
            name: "Pixel".into(),
            serial: serial.map(str::to_owned),
            manufacturer: None,
            product: None,
            vendor_id: 0x18d1,
            product_id: 0x4ee7,
            warning: None,
        }
    }

    #[test]
    fn resolves_the_exact_attachment_and_rejects_missing_or_ambiguous_identity() {
        let a = device("usb:1", Some("A"));
        let b = device("usb:2", Some("B"));
        assert_eq!(
            selected_device(vec![a.clone(), b.clone()], "usb:2").expect("selected device"),
            b
        );
        assert_eq!(
            selected_device(vec![a.clone()], "usb:2")
                .expect_err("gone")
                .code,
            AdbErrorCode::Disconnected
        );
        assert_eq!(
            selected_device(vec![device("usb:1", None)], "usb:1")
                .expect_err("missing serial")
                .code,
            AdbErrorCode::IdentityUnavailable
        );
        assert_eq!(
            selected_device(vec![a, device("usb:2", Some("A"))], "usb:1")
                .expect_err("duplicate serial")
                .code,
            AdbErrorCode::IdentityUnavailable
        );
    }

    #[test]
    fn maps_authorization_access_and_disconnection_errors_separately() {
        assert_eq!(
            map_error(rsadb::Error::Unauthorized).code,
            AdbErrorCode::Unauthorized
        );
        assert_eq!(
            map_error(rsadb::Error::ClaimFailed("busy".into())).code,
            AdbErrorCode::UsbAccess
        );
        assert_eq!(
            map_error(rsadb::Error::Disconnected).code,
            AdbErrorCode::Disconnected
        );
        assert_eq!(timeout_error().code, AdbErrorCode::Timeout);
    }

    #[test]
    fn persists_the_host_key_and_does_not_replace_a_corrupt_existing_key() {
        let directory = tempfile::tempdir().expect("temporary key directory");
        let first = load_key(directory.path().into()).expect("generate key");
        let second = load_key(directory.path().into()).expect("reuse key");
        assert_eq!(
            first.public_key_line().expect("public key"),
            second.public_key_line().expect("public key")
        );
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let mode = std::fs::metadata(directory.path().join("adbkey"))
                .expect("metadata")
                .permissions()
                .mode();
            assert_eq!(mode & 0o777, 0o600);
        }
        std::fs::write(directory.path().join("adbkey"), "corrupt").expect("corrupt fixture");
        assert!(matches!(
            load_key(directory.path().into()),
            Err(AdbError {
                code: AdbErrorCode::Key,
                ..
            })
        ));
        assert_eq!(
            std::fs::read_to_string(directory.path().join("adbkey")).expect("read fixture"),
            "corrupt"
        );
    }
}
