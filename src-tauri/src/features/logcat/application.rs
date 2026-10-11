use std::{
    collections::VecDeque,
    sync::{Arc, Mutex as SyncMutex},
};

use super::history::{DiskHistory, Page, SearchRequest, SearchResult, Snapshot};
use serde::Serialize;
use tokio::sync::Mutex;

use crate::features::adb::{
    application::AdbService,
    domain::{AdbError, AdbErrorCode, AdbStream},
};

fn error(message: &str) -> AdbError {
    AdbError::new(AdbErrorCode::ReadFailed, message)
}

/// One literal threadtime line, with its Android priority (continuations inherit it).
#[derive(Debug, Serialize)]
pub struct LogEntry {
    pub text: String,
    pub level: char,
}

/// Incremental byte decoder preserves UTF-8 across USB chunks and bounds partial lines.
#[derive(Default)]
pub(crate) struct Decoder {
    pending: Vec<u8>,
    lines: VecDeque<LogEntry>,
    level: Option<char>,
}

impl Decoder {
    pub(crate) fn drain(&mut self) -> Vec<LogEntry> {
        let count = self.lines.len().min(200);
        self.lines.drain(..count).collect()
    }
    pub(crate) fn push(&mut self, bytes: &[u8]) -> Result<(), AdbError> {
        if self.pending.len() + bytes.len() > 2 * 1024 * 1024 {
            return Err(error("Logcat output exceeded the 2 MiB chunk limit."));
        }
        self.pending.extend_from_slice(bytes);
        let mut consumed = 0;
        for line in self.pending.split_inclusive(|byte| *byte == b'\n') {
            if !line.ends_with(b"\n") {
                break;
            }
            consumed += line.len();
            if line.len() > 64 * 1024 {
                return Err(error("A Logcat line exceeded 64 KiB."));
            }
            let text = String::from_utf8_lossy(line)
                .trim_end_matches(['\r', '\n'])
                .to_owned();
            if text.starts_with("--------- beginning of") {
                continue;
            }
            if let Some(priority) = text
                .split_whitespace()
                .nth(4)
                .filter(|part| part.len() == 1)
                .and_then(|part| part.chars().next())
                .filter(|level| "VDIWEF".contains(*level))
            {
                self.level = Some(priority);
            }
            self.lines.push_back(LogEntry {
                text,
                level: self.level.unwrap_or('I'),
            });
        }
        self.pending.drain(..consumed);
        if self.pending.len() > 64 * 1024 {
            return Err(error("A Logcat line exceeded 64 KiB."));
        }
        Ok(())
    }
}

struct Active {
    token: u32,
    history: Arc<SyncMutex<DiskHistory>>,
    worker: tokio::task::JoinHandle<()>,
}

impl Drop for Active {
    fn drop(&mut self) {
        self.worker.abort();
    }
}

async fn history_io<T: Send + 'static>(
    history: Arc<SyncMutex<DiskHistory>>,
    operation: impl FnOnce(&mut DiskHistory) -> Result<T, AdbError> + Send + 'static,
) -> Result<T, AdbError> {
    tokio::task::spawn_blocking(move || {
        let mut history = history
            .lock()
            .map_err(|_| error("Logcat history is unavailable."))?;
        operation(&mut history)
    })
    .await
    .map_err(|_| error("Logcat history operation could not finish."))?
}

async fn collect(mut stream: Box<dyn AdbStream>, history: Arc<SyncMutex<DiskHistory>>) {
    let mut decoder = Decoder::default();
    let result: Result<(), AdbError> = async {
        loop {
            decoder.push(&stream.next().await?)?;
            loop {
                let entries = decoder.drain();
                if entries.is_empty() {
                    break;
                }
                history_io(history.clone(), move |history| history.append(entries)).await?;
            }
        }
    }
    .await;
    if let Err(error) = result {
        let _ = history_io(history, move |history| {
            history.fail(error);
            Ok(())
        })
        .await;
    }
}

/// Owns a continuous capture and disk-backed history independently of frontend polling.
#[derive(Default)]
pub struct LogcatService {
    active: Mutex<Option<Active>>,
    sequence: std::sync::atomic::AtomicU32,
}

impl LogcatService {
    /// Replays all logs still available on the phone, then captures until stopped or failed.
    pub async fn start(
        &self,
        adb: &AdbService,
        id: &str,
        package: String,
    ) -> Result<u32, AdbError> {
        if !package.is_empty() && !valid_package(&package) {
            return Err(error("Enter a valid Android package name."));
        }
        let token = self
            .sequence
            .fetch_add(1, std::sync::atomic::Ordering::SeqCst)
            + 1;
        let stream = adb.with_session(id, move |session| Box::pin(async move {
            let uid = if package.is_empty() { String::new() } else {
                let output = session.shell("pm list packages -U").await?;
                let uid = packages(&output).into_iter().find(|(name, _)| name == &package).map(|(_, uid)| uid).ok_or_else(|| error("The package is not installed or its UID is unavailable. Refresh the package list."))?;
                format!(" --uid={uid}")
            };
            session.stream_shell(&format!("logcat -v threadtime{uid} '*:V'")).await
        })).await?;
        let history = Arc::new(SyncMutex::new(
            tokio::task::spawn_blocking(DiskHistory::new)
                .await
                .map_err(|_| error("Logcat history could not be created."))??,
        ));
        let mut active = self.active.lock().await;
        if self.sequence.load(std::sync::atomic::Ordering::SeqCst) != token {
            return Err(error("A newer Logcat capture was requested."));
        }
        *active = Some(Active {
            token,
            worker: tokio::spawn(collect(stream, history.clone())),
            history,
        });
        Ok(token)
    }

    async fn history(&self, token: u32) -> Result<Arc<SyncMutex<DiskHistory>>, AdbError> {
        self.active
            .lock()
            .await
            .as_ref()
            .filter(|active| active.token == token)
            .map(|active| active.history.clone())
            .ok_or_else(|| error("This Logcat history is no longer available."))
    }

    /// Reports counts without transferring the captured history to the webview.
    pub async fn read(&self, token: u32) -> Result<Snapshot, AdbError> {
        history_io(self.history(token).await?, |history| Ok(history.snapshot())).await
    }

    /// Loads at most 200 rows from any position in the selected priority index.
    pub async fn page(
        &self,
        token: u32,
        minimum: char,
        start: u64,
        grouped: bool,
    ) -> Result<Page, AdbError> {
        history_io(self.history(token).await?, move |history| {
            history.page(minimum, start, grouped)
        })
        .await
    }

    /// Searches a bounded portion of the requested range; callers resume from its cursor.
    pub async fn search(
        &self,
        token: u32,
        request: SearchRequest,
    ) -> Result<SearchResult, AdbError> {
        history_io(self.history(token).await?, move |history| {
            history.search(request)
        })
        .await
    }

    /// Token-scoped stop cannot close a newer stream after a stale frontend response.
    /// Stops capture while retaining disk history for a retry or a failed clear operation.
    pub async fn pause(&self, token: u32) {
        let mut active = self.active.lock().await;
        if let Some(active) = active
            .as_mut()
            .filter(|active| active.token == token && !active.worker.is_finished())
        {
            active.worker.abort();
            let _ = (&mut active.worker).await;
        }
    }

    /// Disposes both capture and temporary history; stale tokens have no effect.
    pub async fn stop(&self, token: u32) {
        let mut active = self.active.lock().await;
        if active.as_ref().is_some_and(|active| active.token == token) {
            *active = None;
        }
    }
}

fn valid_package(package: &str) -> bool {
    package.len() <= 255
        && package.split('.').all(|part| {
            !part.is_empty()
                && part
                    .bytes()
                    .all(|byte| byte.is_ascii_alphanumeric() || byte == b'_')
        })
}

pub(crate) fn packages(output: &str) -> Vec<(String, u32)> {
    output
        .lines()
        .filter_map(|line| {
            let mut fields = line.split_whitespace();
            let name = fields.next()?.strip_prefix("package:")?;
            let uid = fields
                .find_map(|field| field.strip_prefix("uid:"))?
                .parse()
                .ok()?;
            valid_package(name).then(|| (name.to_owned(), uid))
        })
        .collect()
}

/// Lists installed package names; the UID is resolved again when starting a capture.
pub async fn list_packages(adb: &AdbService, id: &str) -> Result<Vec<String>, AdbError> {
    adb.with_session(id, |session| {
        Box::pin(async move {
            let output = session.shell("pm list packages -U").await?;
            let mut names: Vec<_> = packages(&output)
                .into_iter()
                .map(|(name, _)| name)
                .collect();
            names.sort();
            names.dedup();
            Ok(names)
        })
    })
    .await
}

/// Clears the same default Android log buffers used by the live stream.
pub async fn clear(adb: &AdbService, id: &str) -> Result<(), AdbError> {
    adb.with_session(id, |session| {
        Box::pin(async move {
            session.shell("logcat -c").await?;
            Ok(())
        })
    })
    .await
}
