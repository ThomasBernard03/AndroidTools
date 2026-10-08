use std::{io::Write, path::PathBuf, time::Duration};

use super::domain::{AdbError, AdbErrorCode, AdbSession};

/// Captures the default display without creating a file on the phone.
/// Shell v2 preserves PNG bytes; the transport bounds output to 16 MiB.
pub async fn capture(session: &dyn AdbSession) -> Result<String, AdbError> {
    let output = tokio::time::timeout(
        Duration::from_secs(15),
        session.file_shell("screencap -p", None),
    )
    .await
    .map_err(|_| {
        AdbError::new(
            AdbErrorCode::Timeout,
            "Screen capture timed out. Please retry.",
        )
    })??;
    if output.exit_code != 0 {
        return Err(AdbError::new(
            AdbErrorCode::ReadFailed,
            "Android could not capture the screen. Unlock the phone and retry.",
        ));
    }
    let bytes = output.stdout;
    validate_png(&bytes)?;
    Ok(format!(
        "data:image/png;base64,{}",
        openssl::base64::encode_block(&bytes)
    ))
}

fn validate_png(bytes: &[u8]) -> Result<(), AdbError> {
    let dimensions = imagesize::blob_size(bytes).ok();
    if bytes.len() > 16 * 1024 * 1024
        || !bytes.starts_with(b"\x89PNG\r\n\x1a\n")
        || !dimensions.is_some_and(|size| {
            size.width > 0
                && size.height > 0
                && size.width.saturating_mul(size.height) <= 32_000_000
        })
    {
        return Err(AdbError::new(
            AdbErrorCode::ReadFailed,
            "The device returned an invalid or oversized screen capture.",
        ));
    }
    Ok(())
}

/// Validates the displayed PNG before opening an injected destination picker.
/// Publishes atomically without replacing existing files. Cancellation writes nothing.
pub fn save(
    image: &str,
    choose: impl FnOnce() -> Result<Option<PathBuf>, AdbError>,
) -> Result<bool, AdbError> {
    let invalid = || {
        AdbError::new(
            AdbErrorCode::SaveFailed,
            "The preview is not a valid PNG image.",
        )
    };
    if image.len() > 23_000_000 {
        return Err(invalid());
    }
    let encoded = image
        .strip_prefix("data:image/png;base64,")
        .ok_or_else(invalid)?;
    let bytes = openssl::base64::decode_block(encoded).map_err(|_| invalid())?;
    validate_png(&bytes).map_err(|_| invalid())?;
    let Some(path) = choose()? else {
        return Ok(false);
    };
    let publish = || -> std::io::Result<()> {
        let parent = path
            .parent()
            .ok_or_else(|| std::io::Error::other("Missing parent directory"))?;
        let mut file = tempfile::NamedTempFile::new_in(parent)?;
        file.write_all(&bytes)?;
        file.as_file().sync_all()?;
        file.persist_noclobber(&path).map_err(|error| error.error)?;
        Ok(())
    };
    publish().map_err(|error| AdbError::new(AdbErrorCode::SaveFailed, if error.kind() == std::io::ErrorKind::AlreadyExists {
        "A file already exists at this location. Choose a new filename."
    } else {
        "Cannot save the preview. Check the destination permissions and free space, then retry."
    }))?;
    Ok(true)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::features::adb::domain::{AdbFuture, FileShellOutput};

    #[test]
    fn saves_exact_png_bytes_handles_cancellation_and_preserves_existing_files() {
        let encoded = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aN1sAAAAASUVORK5CYII=";
        let image = format!("data:image/png;base64,{encoded}");
        let directory = tempfile::tempdir().expect("temporary directory");
        let path = directory.path().join("preview.png");
        assert!(!save(&image, || Ok(None)).expect("cancel"));
        assert_eq!(
            std::fs::read_dir(directory.path())
                .expect("directory")
                .count(),
            0
        );
        assert!(save(&image, || Ok(Some(path.clone()))).expect("save"));
        let expected = openssl::base64::decode_block(encoded).expect("decode fixture");
        assert_eq!(std::fs::read(&path).expect("saved PNG"), expected);
        assert_eq!(
            save(&image, || Ok(Some(path.clone())))
                .expect_err("existing destination")
                .code,
            AdbErrorCode::SaveFailed
        );
        assert_eq!(std::fs::read(&path).expect("preserved PNG"), expected);
        assert!(
            save(&image, || Ok(Some(
                directory.path().join("missing/preview.png")
            )))
            .is_err()
        );
        assert_eq!(
            std::fs::read_dir(directory.path())
                .expect("directory")
                .count(),
            1
        );
        for invalid in [
            "not a data URL",
            "data:image/png;base64,invalid!",
            "data:image/png;base64,aGVsbG8=",
        ] {
            assert!(
                save(invalid, || panic!(
                    "Invalid images must not open the picker"
                ))
                .is_err()
            );
        }
    }

    struct FakeSession {
        bytes: Vec<u8>,
        exit_code: u8,
    }

    impl AdbSession for FakeSession {
        fn shell<'a>(&'a self, _: &'a str) -> AdbFuture<'a, String> {
            panic!("Screenshots must use binary-safe shell output")
        }

        fn file_shell<'a>(
            &'a self,
            command: &'a str,
            destination: Option<tokio::fs::File>,
        ) -> AdbFuture<'a, FileShellOutput> {
            assert_eq!(command, "screencap -p");
            assert!(destination.is_none());
            Box::pin(async move {
                Ok(FileShellOutput {
                    stdout: self.bytes.clone(),
                    stderr: String::new(),
                    exit_code: self.exit_code,
                })
            })
        }
    }

    #[tokio::test]
    async fn preserves_png_bytes_and_rejects_command_failures_and_non_images() {
        let png = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aN1sAAAAASUVORK5CYII=";
        let mut session = FakeSession {
            bytes: openssl::base64::decode_block(png).expect("PNG fixture"),
            exit_code: 0,
        };
        assert_eq!(
            capture(&session).await.expect("capture"),
            format!("data:image/png;base64,{png}")
        );
        session.exit_code = 1;
        assert_eq!(
            capture(&session).await.expect_err("remote failure").code,
            AdbErrorCode::ReadFailed
        );
        session.exit_code = 0;
        session.bytes = b"Permission denied".to_vec();
        assert!(capture(&session).await.is_err());
    }
}
