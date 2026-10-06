use super::{application::*, domain::*, paths::*, transfers};
use crate::features::adb::domain::{AdbFuture, AdbSession, FileShellOutput};
use std::sync::Mutex;

struct FakeSession {
    responses: Mutex<std::collections::VecDeque<FileShellOutput>>,
    commands: Mutex<Vec<String>>,
    push_fails: bool,
    pushed: Mutex<Vec<u8>>,
}

impl FakeSession {
    fn new(responses: Vec<FileShellOutput>) -> Self {
        Self {
            responses: Mutex::new(responses.into()),
            commands: Mutex::new(Vec::new()),
            push_fails: false,
            pushed: Mutex::new(Vec::new()),
        }
    }
}

impl AdbSession for FakeSession {
    fn push<'a>(&'a self, local: &'a std::path::Path, _: &'a str) -> AdbFuture<'a, ()> {
        Box::pin(async move {
            if self.push_fails {
                return Err(crate::features::adb::domain::AdbError::new(
                    crate::features::adb::domain::AdbErrorCode::Disconnected,
                    "Disconnected during push.",
                ));
            }
            *self.pushed.lock().expect("pushed") = std::fs::read(local).expect("source bytes");
            Ok(())
        })
    }
    fn shell<'a>(&'a self, _: &'a str) -> AdbFuture<'a, String> {
        panic!("Unexpected information request")
    }
    fn file_shell<'a>(
        &'a self,
        command: &'a str,
        destination: Option<tokio::fs::File>,
    ) -> AdbFuture<'a, FileShellOutput> {
        Box::pin(async move {
            self.commands.lock().expect("commands").push(command.into());
            let mut result = self
                .responses
                .lock()
                .expect("responses")
                .pop_front()
                .expect("scripted response");
            if let Some(mut file) = destination {
                use tokio::io::AsyncWriteExt;
                file.write_all(&result.stdout).await.expect("fake stream");
                result.stdout.clear();
            }
            Ok(result)
        })
    }
}

fn output(bytes: &[u8]) -> FileShellOutput {
    FileShellOutput {
        stdout: bytes.into(),
        stderr: String::new(),
        exit_code: 0,
    }
}

#[tokio::test]
async fn previews_literal_utf8_and_images_with_bounded_private_reads() {
    use super::preview::{FilePreview, read};
    let png = openssl::base64::decode_block("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aN1sAAAAASUVORK5CYII=").expect("PNG");
    let session = FakeSession::new(vec![output(b"<xml>hello</xml>"), output(&png), output(b"")]);
    let result = read(&session, "/data/data/com.example/files/a' $(id).xml")
        .await
        .expect("text");
    assert_eq!(
        serde_json::to_value(result).expect("wire"),
        serde_json::json!({"kind":"text", "content":"<xml>hello</xml>"})
    );
    assert!(
        matches!(read(&session, "/sdcard/picture.PNG").await.expect("image"), FilePreview::Image { content } if content.starts_with("data:image/png;base64,"))
    );
    assert!(
        matches!(read(&session, "/sdcard/empty").await.expect("empty"), FilePreview::Text { content } if content.is_empty())
    );
    let commands = session.commands.lock().expect("commands");
    assert!(commands[0].starts_with("run-as 'com.example'"));
    assert!(commands[0].contains("head -c 1048577"));
    assert!(commands[0].contains("[ ! -L"));
    assert!(commands[1].contains("head -c 8388609"));
}

#[tokio::test]
async fn preview_rejects_binary_oversized_invalid_images_and_remote_failures() {
    use super::preview::read;
    for (path, bytes, code) in [
        ("/sdcard/data", vec![0, 1], "unsupported_preview"),
        ("/sdcard/data", vec![255], "unsupported_preview"),
        (
            "/sdcard/text",
            vec![b'a'; 1024 * 1024 + 1],
            "preview_too_large",
        ),
        (
            "/sdcard/image.png",
            vec![0; 8 * 1024 * 1024 + 1],
            "preview_too_large",
        ),
        (
            "/sdcard/image.png",
            b"not an image".to_vec(),
            "unsupported_preview",
        ),
    ] {
        let session = FakeSession::new(vec![output(&bytes)]);
        let error = read(&session, path).await.expect_err("rejected preview");
        assert_eq!(error.code, code);
        assert!(!error.partial);
    }
    for (exit_code, code) in [
        (45, "unsupported_entry"),
        (46, "not_found"),
        (43, "permission_denied"),
    ] {
        let session = FakeSession::new(vec![FileShellOutput {
            exit_code,
            ..output(b"")
        }]);
        assert_eq!(
            read(&session, "/sdcard/file")
                .await
                .expect_err("remote failure")
                .code,
            code
        );
    }
}

#[cfg(unix)]
#[test]
fn upload_command_preserves_binary_data_and_shell_metacharacters_without_clobbering() {
    let dir = tempfile::tempdir().expect("directory");
    let source = dir.path().join("source ' file");
    std::fs::write(&source, b"binary\0\xff\r\n").expect("source");
    let name = "-a ' ; $(exit 99)\n.bin";
    let command = transfers::upload_command(
        dir.path().to_str().expect("path"),
        name,
        source.to_str().expect("source path"),
    )
    .expect("command");
    let run = || {
        std::process::Command::new("sh")
            .args(["-c", &command])
            .output()
            .expect("shell")
            .status
            .success()
    };
    assert!(run());
    assert_eq!(
        std::fs::read(dir.path().join(name)).expect("destination"),
        b"binary\0\xff\r\n"
    );
    std::fs::write(&source, b"replacement").expect("changed source");
    assert!(!run());
    assert_eq!(
        std::fs::read(dir.path().join(name)).expect("original destination"),
        b"binary\0\xff\r\n"
    );
}

#[test]
fn metadata_preserves_names_and_rejects_malformed_or_duplicate_entries() {
    let entries =
        parse_entries(b"81a4 12 1700000001\na\n'b;$(id).txt\0a1ff 4 0\nlink\0").expect("metadata");
    assert_eq!(entries[0].name, "a\n'b;$(id).txt");
    assert_eq!(entries[1].kind, EntryKind::Symlink);
    for bytes in [
        b"81a4 12 0\nincomplete".as_slice(),
        b"Permission denied\n",
        b"81a4 12 0\n../escape\0",
        b"81a4 1 0\na\x0081a4 1 0\na\0",
    ] {
        assert!(parse_entries(bytes).is_err());
    }
    assert!(parse_entries(b"").expect("empty directory").is_empty());
    let json = serde_json::to_value(&entries[0]).expect("wire contract");
    assert_eq!(json["modifiedAt"], 1700000001i64);
    assert_eq!(json["permissions"], "0644");
}

#[tokio::test]
async fn uploads_binary_files_through_run_as_and_cleans_staging_on_failure() {
    let dir = tempfile::tempdir().expect("directory");
    let source = dir.path().join("a ' ; $(id).bin");
    std::fs::write(&source, b"binary\0\xff").expect("source");
    let stage = b"/data/local/tmp/android-tools.A123\n";
    let session = FakeSession::new(vec![output(stage), output(b""), output(b"")]);
    transfers::upload(&session, "/data/data/com.example/files", source.clone())
        .await
        .expect("upload");
    assert_eq!(*session.pushed.lock().expect("bytes"), b"binary\0\xff");
    {
        let commands = session.commands.lock().expect("commands");
        assert!(commands[1].contains("run-as"));
        assert!(commands[1].contains("set -C"));
        assert_eq!(commands[2], "rm -f '/data/local/tmp/android-tools.A123'");
    }
    let mut failed = FakeSession::new(vec![output(stage), output(b"")]);
    failed.push_fails = true;
    assert_eq!(
        transfers::upload(&failed, "/sdcard", source)
            .await
            .expect_err("push failure")
            .code,
        "disconnected"
    );
    assert_eq!(failed.commands.lock().expect("cleanup").len(), 2);
}

#[tokio::test]
async fn downloads_nested_directories_and_empty_folders() {
    let dir = tempfile::tempdir().expect("directory");
    let session = FakeSession::new(vec![
        output(b"d"),
        output(b"41ed 0 0\nfolder\0"),
        output(b"d"),
        output(b"81a4 3 0\nfile.bin\0"),
        output(b"f"),
        output(b"abc"),
    ]);
    transfers::download(&session, "/sdcard/tree", dir.path().join("tree"))
        .await
        .expect("recursive transfer");
    assert_eq!(
        std::fs::read(dir.path().join("tree/folder/file.bin")).expect("nested file"),
        b"abc"
    );
    let empty = FakeSession::new(vec![output(b"d"), output(b"")]);
    transfers::download(&empty, "/sdcard/empty", dir.path().join("empty"))
        .await
        .expect("empty folder");
    assert!(dir.path().join("empty").is_dir());
}

#[test]
fn paths_protect_roots_packages_and_host_destinations() {
    assert_eq!(
        normalize("//sdcard/./Download/").expect("normalized"),
        "/sdcard/Download"
    );
    for value in ["relative", "/sdcard/../data", "/a\0b"] {
        assert!(normalize(value).is_err());
    }
    for value in [
        "/",
        "/data",
        "/data/data",
        "/data/data/com.example",
        "/sdcard",
    ] {
        assert!(target(value).is_err());
    }
    for value in ["../escape", "a\\b", "C:escape", "NUL.txt", "a."] {
        assert!(local_name(value).is_err());
    }
    assert!(at("/data/data/com.app;id", "pwd").is_err());
    assert!(
        at("/data/data/com.example/files", "pwd")
            .expect("run-as")
            .starts_with("run-as 'com.example' sh -c ")
    );
    assert_eq!(quote("a'b"), "'a'\\''b'");
}

#[tokio::test]
async fn lists_packages_and_sorts_directories_first_without_hiding_access_errors() {
    let session = FakeSession::new(vec![
        output(b"package:com.b\npackage:com.a\npackage:com.a\n"),
        output(b"81a4 1 0\na\x0041ed 0 0\nz\0"),
        FileShellOutput {
            stdout: Vec::new(),
            stderr: "run-as: package not debuggable".into(),
            exit_code: 1,
        },
    ]);
    let apps = list(&session, "/data/data").await.expect("packages");
    assert_eq!(apps.entries.len(), 2);
    assert_eq!(apps.entries[0].name, "com.a");
    assert_eq!(
        list(&session, "/sdcard").await.expect("directory").entries[0].name,
        "z"
    );
    assert_eq!(
        list(&session, "/data/data/com.a")
            .await
            .expect_err("private access")
            .code,
        "private_access"
    );
}

#[tokio::test]
async fn rejects_invalid_mutations_before_io_and_reports_collisions() {
    let session = FakeSession::new(vec![FileShellOutput {
        stdout: Vec::new(),
        stderr: String::new(),
        exit_code: 42,
    }]);
    assert!(
        mutate(&session, "/data/data/com.a", Mutation::Delete, "")
            .await
            .is_err()
    );
    assert!(
        mutate(&session, "/sdcard/a", Mutation::Rename, "../b")
            .await
            .is_err()
    );
    assert!(session.commands.lock().expect("commands").is_empty());
    assert_eq!(
        mutate(&session, "/sdcard/a", Mutation::Rename, "b")
            .await
            .expect_err("collision")
            .code,
        "already_exists"
    );
}

#[tokio::test]
async fn downloads_binary_data_without_overwriting_and_never_publishes_failed_files() {
    let dir = tempfile::tempdir().expect("directory");
    let bytes = b"binary\0\xff\r\n";
    let session = FakeSession::new(vec![
        output(b"f"),
        output(bytes),
        output(b"f"),
        output(b"replacement"),
        output(b"f"),
        FileShellOutput {
            stdout: b"partial".into(),
            stderr: "Permission denied".into(),
            exit_code: 1,
        },
    ]);
    let dest = dir.path().join("download");
    transfers::download(&session, "/sdcard/file", dest.clone())
        .await
        .expect("download");
    assert!(
        transfers::download(&session, "/sdcard/file", dest.clone())
            .await
            .is_err()
    );
    assert_eq!(std::fs::read(dest).expect("downloaded file"), bytes);
    let failed = dir.path().join("failed");
    assert!(
        transfers::download(&session, "/sdcard/file", failed.clone())
            .await
            .is_err()
    );
    assert!(!failed.exists());
}

#[tokio::test]
async fn recursive_download_reports_unsupported_links_and_preserves_existing_directories() {
    let dir = tempfile::tempdir().expect("directory");
    let session = FakeSession::new(vec![
        output(b"d"),
        output(b"a1ff 4 0\nlink\0"),
        output(b"d"),
    ]);
    let dest = dir.path().join("folder");
    assert_eq!(
        transfers::download(&session, "/sdcard/folder", dest.clone())
            .await
            .expect_err("link")
            .code,
        "unsupported_entry"
    );
    assert_eq!(
        transfers::download(&session, "/sdcard/folder", dest)
            .await
            .expect_err("collision")
            .code,
        "already_exists"
    );
}
