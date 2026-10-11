use super::application::*;
use crate::features::adb::domain::{AdbConnector, AdbFuture, AdbSession, AdbStream};
use std::sync::{
    Arc, Mutex,
    atomic::{AtomicUsize, Ordering},
};

struct Connector {
    commands: Arc<Mutex<Vec<String>>>,
    drops: Arc<AtomicUsize>,
}
struct Session {
    commands: Arc<Mutex<Vec<String>>>,
    drops: Arc<AtomicUsize>,
}
struct Stream {
    drops: Arc<AtomicUsize>,
    sent: bool,
}
impl Drop for Stream {
    fn drop(&mut self) {
        self.drops.fetch_add(1, Ordering::SeqCst);
    }
}
impl AdbStream for Stream {
    fn next(&mut self) -> AdbFuture<'_, Vec<u8>> {
        Box::pin(async move {
            if self.sent {
                return std::future::pending().await;
            }
            self.sent = true;
            Ok(b"10-10 12:00:00.000  123  124 I Test: live\n".to_vec())
        })
    }
}
impl AdbSession for Session {
    fn shell<'a>(&'a self, command: &'a str) -> AdbFuture<'a, String> {
        Box::pin(async move {
            self.commands.lock().expect("commands").push(command.into());
            Ok("package:com.example.app uid:10123\npackage:android uid:1000\n".into())
        })
    }
    fn stream_shell<'a>(&'a self, command: &'a str) -> AdbFuture<'a, Box<dyn AdbStream>> {
        Box::pin(async move {
            self.commands.lock().expect("commands").push(command.into());
            Ok(Box::new(Stream {
                drops: self.drops.clone(),
                sent: false,
            }) as Box<dyn AdbStream>)
        })
    }
}
impl AdbConnector for Connector {
    fn connect<'a>(&'a self, _: &'a str) -> AdbFuture<'a, Box<dyn AdbSession>> {
        Box::pin(async move {
            Ok(Box::new(Session {
                commands: self.commands.clone(),
                drops: self.drops.clone(),
            }) as Box<dyn AdbSession>)
        })
    }
}

#[tokio::test]
async fn streams_by_uid_without_blocking_other_operations_and_stops_by_token() {
    let commands = Arc::new(Mutex::new(Vec::new()));
    let drops = Arc::new(AtomicUsize::new(0));
    let adb = crate::features::adb::application::AdbService::new(Connector {
        commands: commands.clone(),
        drops: drops.clone(),
    });
    let service = LogcatService::default();
    let first = service
        .start(&adb, "phone", "com.example.app".into())
        .await
        .expect("start");
    wait_for_capture(&service, first).await;
    let entries = service
        .page(first, 'V', 0, false)
        .await
        .expect("live data")
        .entries;
    assert_eq!(entries.len(), 1);
    assert_eq!(
        serde_json::to_value(&entries[0]).expect("wire format"),
        serde_json::json!({"id":0,"text":"10-10 12:00:00.000  123  124 I Test: live", "level":"I", "repeatCount":1})
    );
    assert_eq!(
        service.read(first).await.expect("counts").counts,
        [1, 1, 1, 0, 0, 0]
    );
    assert_eq!(
        list_packages(&adb, "phone")
            .await
            .expect("concurrent operation"),
        vec!["android", "com.example.app"]
    );
    clear(&adb, "phone").await.expect("clear device buffers");
    let second = service
        .start(&adb, "phone", String::new())
        .await
        .expect("restart");
    wait_for_capture(&service, second).await;
    assert_eq!(drops.load(Ordering::SeqCst), 1);
    service.stop(first).await;
    assert_eq!(
        service
            .read(second)
            .await
            .expect("new stream preserved")
            .counts[0],
        1
    );
    service.stop(second).await;
    tokio::task::yield_now().await;
    assert_eq!(drops.load(Ordering::SeqCst), 2);
    assert!(service.read(second).await.is_err());
    let commands = commands.lock().expect("commands");
    assert!(commands.contains(&"logcat -v threadtime --uid=10123 '*:V'".into()));
    assert!(commands.contains(&"logcat -c".into()));
}

async fn wait_for_capture(service: &LogcatService, token: u32) {
    tokio::time::timeout(std::time::Duration::from_secs(2), async {
        while service.read(token).await.expect("snapshot").counts[0] == 0 {
            tokio::time::sleep(std::time::Duration::from_millis(1)).await;
        }
    })
    .await
    .expect("background capture progresses without frontend draining");
}

#[test]
fn retains_large_histories_on_disk_and_searches_beyond_the_viewport_in_both_directions() {
    use super::history::{DiskHistory, SearchRequest};
    let mut history = DiskHistory::new().expect("temporary history");
    for batch in 0..100 {
        history
            .append(
                (0..200)
                    .map(|row| {
                        let id = batch * 200 + row;
                        LogEntry {
                            text: format!(
                                "{} line {id} {}",
                                if id == 17 || id == 19017 {
                                    "Needle"
                                } else {
                                    "context"
                                },
                                "x".repeat(256)
                            ),
                            level: if id % 2 == 0 { 'D' } else { 'E' },
                        }
                    })
                    .collect(),
            )
            .expect("append");
    }
    assert_eq!(
        history.snapshot().counts,
        [20000, 20000, 10000, 10000, 10000, 0]
    );
    assert_eq!(
        history.page('V', 0, false).expect("oldest").entries[0].id,
        0
    );
    assert_eq!(
        history
            .page('E', 9500, false)
            .expect("filtered random seek")
            .entries[0]
            .id,
        19001
    );
    assert_eq!(
        history.page('V', 19999, false).expect("newest").entries[0].id,
        19999
    );
    for (backward, expected) in [(false, 17), (true, 19017)] {
        let mut request = SearchRequest {
            grouped: false,
            minimum: 'V',
            query: "NEEDLE".into(),
            start: 0,
            end: 20000,
            backward,
        };
        loop {
            let result = history.search(request.clone()).expect("search disk");
            if let Some(position) = result.position {
                assert_eq!(position, expected);
                break;
            }
            let next = result
                .next
                .expect("continue search without caching matches");
            if backward {
                request.end = next;
            } else {
                request.start = next;
            }
        }
    }
    assert!(history.page('X', 0, false).is_err());
    assert!(
        history
            .page('V', u64::MAX, false)
            .expect("clamped offset")
            .entries
            .is_empty()
    );
    history.fail(crate::features::adb::domain::AdbError::new(
        crate::features::adb::domain::AdbErrorCode::Disconnected,
        "Cable unplugged",
    ));
    assert!(history.snapshot().error.is_some());
    assert_eq!(
        history
            .page('V', 0, false)
            .expect("history after failure")
            .entries[0]
            .id,
        0
    );
}

#[tokio::test]
async fn rejects_unknown_packages_and_shell_metacharacters() {
    let commands = Arc::new(Mutex::new(Vec::new()));
    let adb = crate::features::adb::application::AdbService::new(Connector {
        commands: commands.clone(),
        drops: Arc::new(AtomicUsize::new(0)),
    });
    let service = LogcatService::default();
    assert!(
        service
            .start(&adb, "phone", "app;reboot".into())
            .await
            .is_err()
    );
    assert!(commands.lock().expect("commands").is_empty());
    assert!(
        service
            .start(&adb, "phone", "com.missing".into())
            .await
            .is_err()
    );
    assert!(
        !commands
            .lock()
            .expect("commands")
            .iter()
            .any(|command| command.starts_with("logcat"))
    );
}

#[test]
fn decodes_split_utf8_crlf_and_multiline_messages_and_bounds_lines() {
    let mut decoder = Decoder::default();
    let text =
        "--------- beginning of main\n10-10 12:00:00.000  123  124 E Tag: café\r\n  stack trace\n";
    for byte in text.as_bytes() {
        decoder.push(&[*byte]).expect("incremental decode");
    }
    let lines = decoder.drain();
    assert_eq!(lines.len(), 2);
    assert!(lines[0].text.ends_with("café"));
    assert_eq!(lines[1].text, "  stack trace");
    assert!(lines.iter().all(|line| line.level == 'E'));
    assert!(decoder.push(&vec![b'x'; 65537]).is_err());
    assert_eq!(
        packages("package:com.a uid:42\ninvalid\npackage:com.b uid:nope"),
        vec![("com.a".into(), 42)]
    );
}

#[test]
fn batches_backlogs_without_losing_lines() {
    let mut decoder = Decoder::default();
    decoder
        .push(
            "10-10 12:00:00.000 1 1 D Tag: message\n"
                .repeat(450)
                .as_bytes(),
        )
        .expect("backlog");
    assert_eq!(decoder.drain().len(), 200);
    assert_eq!(decoder.drain().len(), 200);
    assert_eq!(decoder.drain().len(), 50);
    assert!(decoder.drain().is_empty());
}

#[test]
fn groups_consecutive_payloads_across_batches_without_losing_original_timestamps() {
    use super::history::{DiskHistory, SearchRequest};
    let mut history = DiskHistory::new().expect("history");
    let entry = |time: &str, pid: u32, level: char, message: &str| LogEntry {
        text: format!("10-10 {time} {pid} 124 {level} Tag: {message}"),
        level,
    };
    history
        .append(vec![entry("12:00:00.000", 123, 'E', "retry")])
        .expect("first");
    history
        .append(vec![
            entry("12:00:01.000", 123, 'E', "retry"),
            entry("12:00:02.000", 123, 'E', "retry"),
        ])
        .expect("repetitions");
    assert_eq!(
        history.page('E', 0, true).expect("group").entries[0].repeat_count,
        3
    );
    history
        .append(vec![
            entry("12:00:03.000", 123, 'I', "context"),
            entry("12:00:04.000", 123, 'E', "retry"),
            entry("12:00:05.000", 999, 'E', "retry"),
        ])
        .expect("different rows");
    assert_eq!(history.snapshot().counts, [6, 6, 6, 5, 5, 0]);
    assert_eq!(history.snapshot().grouped_counts, [4, 4, 4, 3, 3, 0]);
    let grouped = history.page('E', 0, true).expect("grouped errors").entries;
    assert_eq!(
        grouped
            .iter()
            .map(|entry| entry.repeat_count)
            .collect::<Vec<_>>(),
        vec![3, 1, 1]
    );
    assert!(grouped[0].text.contains("12:00:00.000"));
    let raw = history.page('V', 0, false).expect("originals").entries;
    assert_eq!(raw.len(), 6);
    assert!(raw.iter().all(|entry| entry.repeat_count == 1));
    assert!(raw[1].text.contains("12:00:01.000"));
    let found = history
        .search(SearchRequest {
            minimum: 'E',
            query: "retry".into(),
            start: 0,
            end: 3,
            backward: true,
            grouped: true,
        })
        .expect("grouped search");
    assert_eq!(found.position, Some(2));
}
