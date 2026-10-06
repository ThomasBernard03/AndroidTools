use std::{
    fs::File,
    io::{Read, Write},
    path::Path,
};

use crate::features::adb::domain::{AdbError, AdbErrorCode, AdbSession};

fn failed(message: impl Into<String>) -> AdbError {
    AdbError::new(AdbErrorCode::ReadFailed, message)
}

/// Freeze and verify the analyzed bytes before any device mutation.
pub fn snapshot(path: &Path, expected_hash: &str) -> Result<tempfile::NamedTempFile, AdbError> {
    let io_error = |_| failed("The APK could not be read. Analyze it again before installing.");
    if !path
        .extension()
        .is_some_and(|ext| ext.eq_ignore_ascii_case("apk"))
    {
        return Err(failed("Choose a single .apk file."));
    }
    let mut source = File::open(path).map_err(io_error)?;
    let metadata = source.metadata().map_err(io_error)?;
    if !metadata.is_file() || metadata.len() > 1024 * 1024 * 1024 {
        return Err(failed("Choose a regular APK file no larger than 1 GiB."));
    }
    let mut snapshot = tempfile::NamedTempFile::new().map_err(io_error)?;
    let mut hash = openssl::sha::Sha256::new();
    let mut buffer = [0; 65536];
    let mut total = 0_u64;
    loop {
        let count = source.read(&mut buffer).map_err(io_error)?;
        if count == 0 {
            break;
        }
        total += count as u64;
        if total > 1024 * 1024 * 1024 {
            return Err(failed("The APK exceeds 1 GiB."));
        }
        hash.update(&buffer[..count]);
        snapshot.write_all(&buffer[..count]).map_err(io_error)?;
    }
    let actual: String = hash
        .finish()
        .iter()
        .map(|byte| format!("{byte:02X}"))
        .collect();
    if actual != expected_hash {
        return Err(failed(
            "The APK has changed since analysis. Analyze it again before installing.",
        ));
    }
    snapshot.flush().map_err(io_error)?;
    Ok(snapshot)
}

/// Stage, install (allowing updates), and attempt cleanup even after remote failure.
pub async fn install(session: &dyn AdbSession, path: &Path) -> Result<(), AdbError> {
    let mut nonce = [0_u8; 16];
    openssl::rand::rand_bytes(&mut nonce)
        .map_err(|_| failed("Could not prepare APK installation."))?;
    let token: String = nonce.iter().map(|byte| format!("{byte:02x}")).collect();
    let remote = format!("/data/local/tmp/android-tools-{token}.apk");
    let result = async {
        session.push(path, &remote).await?;
        let output = session
            .file_shell(&format!("pm install -r '{remote}'"), None)
            .await?;
        let stdout = String::from_utf8_lossy(&output.stdout);
        if output.exit_code != 0 || !stdout.lines().any(|line| line.trim() == "Success") {
            return Err(failed(format!(
                "APK installation failed: {} {}",
                stdout.trim(),
                output.stderr.trim()
            )));
        }
        Ok(())
    }
    .await;
    let cleanup = session.file_shell(&format!("rm -f '{remote}'"), None).await;
    result?;
    match cleanup {
        Ok(output) if output.exit_code == 0 => Ok(()),
        _ => Err(failed(
            "APK installed, but its temporary device file could not be removed.",
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::features::adb::domain::{AdbFuture, FileShellOutput};
    use std::sync::Mutex;

    struct FakeSession {
        calls: Mutex<Vec<String>>,
        push_fails: bool,
        rejected: bool,
    }
    impl AdbSession for FakeSession {
        fn shell<'a>(&'a self, _: &'a str) -> AdbFuture<'a, String> {
            Box::pin(async { unreachable!() })
        }
        fn push<'a>(&'a self, _: &'a Path, remote: &'a str) -> AdbFuture<'a, ()> {
            Box::pin(async move {
                self.calls
                    .lock()
                    .expect("calls lock")
                    .push(format!("push {remote}"));
                if self.push_fails {
                    Err(failed("Disconnected during upload"))
                } else {
                    Ok(())
                }
            })
        }
        fn file_shell<'a>(
            &'a self,
            command: &'a str,
            _: Option<tokio::fs::File>,
        ) -> AdbFuture<'a, FileShellOutput> {
            Box::pin(async move {
                self.calls.lock().expect("calls lock").push(command.into());
                let rejected = self.rejected && command.starts_with("pm install");
                Ok(FileShellOutput {
                    stdout: if rejected {
                        b"Failure [INSTALL_FAILED_UPDATE_INCOMPATIBLE]".to_vec()
                    } else {
                        b"Success\n".to_vec()
                    },
                    stderr: String::new(),
                    // Some Android versions report package rejection with a successful shell exit.
                    exit_code: 0,
                })
            })
        }
    }

    #[tokio::test]
    async fn installs_exact_staged_path_and_cleans_up_after_success_or_failure() {
        for (push_fails, rejected) in [(false, false), (true, false), (false, true)] {
            let session = FakeSession {
                calls: Mutex::new(vec![]),
                push_fails,
                rejected,
            };
            let result = install(&session, Path::new("snapshot")).await;
            assert_eq!(result.is_ok(), !push_fails && !rejected);
            if rejected {
                assert!(
                    result
                        .expect_err("installation rejected")
                        .message
                        .contains("INSTALL_FAILED_UPDATE_INCOMPATIBLE")
                );
            }
            let calls = session.calls.lock().expect("calls lock");
            let remote = calls[0].strip_prefix("push ").expect("upload first");
            assert!(remote.starts_with("/data/local/tmp/android-tools-"));
            if !push_fails {
                assert_eq!(calls[1], format!("pm install -r '{remote}'"));
            }
            assert_eq!(
                calls.last().expect("cleanup call"),
                &format!("rm -f '{remote}'")
            );
        }
    }

    #[test]
    fn snapshot_rejects_changed_apks_and_preserves_verified_bytes() {
        let dir = tempfile::tempdir().expect("temporary directory");
        let path = dir.path().join("sample.apk");
        std::fs::write(&path, b"analyzed bytes").expect("write APK");
        let hash: String = openssl::sha::sha256(b"analyzed bytes")
            .iter()
            .map(|byte| format!("{byte:02X}"))
            .collect();
        let frozen = snapshot(&path, &hash).expect("verified snapshot");
        std::fs::write(&path, b"changed bytes").expect("change APK");
        assert_eq!(
            std::fs::read(frozen.path()).expect("read snapshot"),
            b"analyzed bytes"
        );
        assert!(
            snapshot(&path, &hash)
                .expect_err("changed APK rejected")
                .message
                .contains("changed since analysis")
        );
    }
}
