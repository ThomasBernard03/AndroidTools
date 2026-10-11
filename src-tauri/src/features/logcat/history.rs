//! Disk-backed capture history. Neither text nor per-line indexes accumulate in RAM.
use super::application::LogEntry;
use crate::features::adb::domain::{AdbError, AdbErrorCode};
use serde::{Deserialize, Serialize};
use std::{
    fs::File,
    io::{Read, Seek, SeekFrom, Write},
    time::{Duration, Instant},
};

fn storage_error(_: impl std::fmt::Display) -> AdbError {
    AdbError::new(
        AdbErrorCode::SaveFailed,
        "Logcat history could not be read or written. Check available disk space and refresh. Captured history has not been evicted.",
    )
}

fn rank(level: char) -> Result<usize, AdbError> {
    "VDIWEF"
        .find(level)
        .ok_or_else(|| AdbError::new(AdbErrorCode::ReadFailed, "Invalid Logcat priority."))
}

/// A stable capture-wide identity, independent of the current minimum priority.
#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StoredEntry {
    pub id: u64,
    pub text: String,
    pub level: char,
    pub repeat_count: u64,
}

/// Per-minimum-priority counts and an optional terminal capture error.
#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Snapshot {
    pub counts: [u64; 6],
    pub grouped_counts: [u64; 6],
    pub error: Option<AdbError>,
}

/// A bounded viewport, positioned within the selected minimum-priority index.
#[derive(Debug, Serialize)]
pub struct Page {
    pub start: u64,
    pub entries: Vec<StoredEntry>,
}

/// A bounded search step; the caller continues from `next` without retaining matches.
#[derive(Debug, Serialize)]
pub struct SearchResult {
    pub position: Option<u64>,
    pub next: Option<u64>,
}

#[derive(Clone, Deserialize)]
pub struct SearchRequest {
    pub minimum: char,
    pub query: String,
    pub start: u64,
    pub end: u64,
    pub backward: bool,
    pub grouped: bool,
}

/// Anonymous temporary files are removed on close, including normal app shutdown.
/// Each cumulative priority index holds only disk offsets, enabling constant-time seeks.
pub struct DiskHistory {
    data: File,
    indexes: [File; 6],
    grouped_indexes: [File; 6],
    last: Option<(String, char, u64, u64)>,
    snapshot: Snapshot,
}

impl DiskHistory {
    pub fn new() -> Result<Self, AdbError> {
        fn indexes() -> Result<[File; 6], AdbError> {
            let mut files = Vec::new();
            for _ in 0..6 {
                files.push(tempfile::tempfile().map_err(storage_error)?);
            }
            files
                .try_into()
                .map_err(|_| storage_error("index initialization"))
        }
        Ok(Self {
            data: tempfile::tempfile().map_err(storage_error)?,
            indexes: indexes()?,
            grouped_indexes: indexes()?,
            last: None,
            snapshot: Snapshot {
                counts: [0; 6],
                grouped_counts: [0; 6],
                error: None,
            },
        })
    }

    pub fn snapshot(&self) -> Snapshot {
        self.snapshot.clone()
    }

    pub fn fail(&mut self, error: AdbError) {
        self.snapshot.error = Some(error);
    }

    /// Publishes each row only after its text and all relevant indexes have been written.
    /// A write failure terminates capture; already published rows remain readable.
    pub fn append(&mut self, entries: Vec<LogEntry>) -> Result<(), AdbError> {
        for entry in entries {
            let priority = rank(entry.level)?;
            let signature = signature(&entry.text).to_owned();
            let repeat = self
                .last
                .as_ref()
                .filter(|(text, level, _, _)| text == &signature && *level == entry.level)
                .map(|(_, _, offset, count)| (*offset, *count));
            let record = StoredEntry {
                id: self.snapshot.counts[0],
                text: entry.text,
                level: entry.level,
                repeat_count: 1,
            };
            let bytes = serde_json::to_vec(&record).map_err(storage_error)?;
            let offset = self.data.seek(SeekFrom::End(0)).map_err(storage_error)?;
            self.data
                .write_all(&(bytes.len() as u32).to_le_bytes())
                .map_err(storage_error)?;
            self.data
                .write_all(&1_u64.to_le_bytes())
                .map_err(storage_error)?;
            self.data.write_all(&bytes).map_err(storage_error)?;
            for index in &mut self.indexes[..=priority] {
                index.seek(SeekFrom::End(0)).map_err(storage_error)?;
                index
                    .write_all(&offset.to_le_bytes())
                    .map_err(storage_error)?;
            }
            if let Some((first, count)) = repeat {
                self.data
                    .seek(SeekFrom::Start(first + 4))
                    .map_err(storage_error)?;
                self.data
                    .write_all(&(count + 1).to_le_bytes())
                    .map_err(storage_error)?;
                self.last = Some((signature, record.level, first, count + 1));
            } else {
                for index in &mut self.grouped_indexes[..=priority] {
                    index.seek(SeekFrom::End(0)).map_err(storage_error)?;
                    index
                        .write_all(&offset.to_le_bytes())
                        .map_err(storage_error)?;
                }
                for count in &mut self.snapshot.grouped_counts[..=priority] {
                    *count += 1;
                }
                self.last = Some((signature, record.level, offset, 1));
            }
            for count in &mut self.snapshot.counts[..=priority] {
                *count += 1;
            }
        }
        Ok(())
    }

    fn entry(
        &mut self,
        priority: usize,
        position: u64,
        grouped: bool,
    ) -> Result<StoredEntry, AdbError> {
        let index = if grouped {
            &mut self.grouped_indexes[priority]
        } else {
            &mut self.indexes[priority]
        };
        index
            .seek(SeekFrom::Start(position * 8))
            .map_err(storage_error)?;
        let mut offset = [0; 8];
        index.read_exact(&mut offset).map_err(storage_error)?;
        self.data
            .seek(SeekFrom::Start(u64::from_le_bytes(offset)))
            .map_err(storage_error)?;
        let mut length = [0; 4];
        self.data.read_exact(&mut length).map_err(storage_error)?;
        let mut repeats = [0; 8];
        self.data.read_exact(&mut repeats).map_err(storage_error)?;
        let length = u32::from_le_bytes(length) as usize;
        if length > 512 * 1024 {
            return Err(storage_error("invalid record length"));
        }
        let mut bytes = vec![0; length];
        self.data.read_exact(&mut bytes).map_err(storage_error)?;
        let mut entry: StoredEntry = serde_json::from_slice(&bytes).map_err(storage_error)?;
        entry.repeat_count = if grouped {
            u64::from_le_bytes(repeats)
        } else {
            1
        };
        Ok(entry)
    }

    pub fn page(&mut self, minimum: char, start: u64, grouped: bool) -> Result<Page, AdbError> {
        let priority = rank(minimum)?;
        let counts = if grouped {
            self.snapshot.grouped_counts
        } else {
            self.snapshot.counts
        };
        let start = start.min(counts[priority]);
        let end = (start + 200).min(counts[priority]);
        let mut entries = Vec::new();
        for position in start..end {
            entries.push(self.entry(priority, position, grouped)?);
        }
        Ok(Page { start, entries })
    }

    /// Searches at most 2,000 rows / 15 ms per step so capture and scrolling can proceed.
    pub fn search(&mut self, request: SearchRequest) -> Result<SearchResult, AdbError> {
        let priority = rank(request.minimum)?;
        if request.query.is_empty() || request.query.len() > 4096 {
            return Err(AdbError::new(
                AdbErrorCode::ReadFailed,
                "Search text must contain between 1 and 4,096 UTF-8 bytes.",
            ));
        }
        let counts = if request.grouped {
            self.snapshot.grouped_counts
        } else {
            self.snapshot.counts
        };
        let end = request.end.min(counts[priority]);
        let start = request.start.min(end);
        let needle = request.query.to_lowercase();
        let now = Instant::now();
        let mut cursor = if request.backward { end } else { start };
        let mut scanned = 0;
        while if request.backward {
            cursor > start
        } else {
            cursor < end
        } {
            let position = if request.backward { cursor - 1 } else { cursor };
            if self
                .entry(priority, position, request.grouped)?
                .text
                .to_lowercase()
                .contains(&needle)
            {
                return Ok(SearchResult {
                    position: Some(position),
                    next: None,
                });
            }
            cursor = if request.backward {
                position
            } else {
                position + 1
            };
            scanned += 1;
            if scanned >= 2000 || now.elapsed() >= Duration::from_millis(15) {
                return Ok(SearchResult {
                    position: None,
                    next: Some(cursor),
                });
            }
        }
        Ok(SearchResult {
            position: None,
            next: None,
        })
    }
}

/// Standard threadtime timestamps change for every repeat. Keep PID, TID, priority,
/// tag and the exact message; continuation lines are compared literally.
fn signature(text: &str) -> &str {
    let mut fields = text.split_whitespace();
    let Some(date) = fields.next() else {
        return text;
    };
    let Some(time) = fields.next() else {
        return text;
    };
    if date.len() != 5
        || date.as_bytes()[2] != b'-'
        || !date
            .bytes()
            .enumerate()
            .all(|(i, byte)| i == 2 || byte.is_ascii_digit())
        || time.len() < 8
        || time.as_bytes()[2] != b':'
        || time.as_bytes()[5] != b':'
    {
        return text;
    }
    text.trim_start()
        .strip_prefix(date)
        .and_then(|rest| rest.trim_start().strip_prefix(time))
        .map(str::trim_start)
        .unwrap_or(text)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_write_failure_does_not_publish_or_evict_history() {
        let mut history = DiskHistory::new().expect("history");
        history
            .append(vec![LogEntry {
                text: "retained".into(),
                level: 'I',
            }])
            .expect("initial row");
        let mut readonly = tempfile::NamedTempFile::new().expect("read-only fixture");
        history.data.rewind().expect("rewind");
        std::io::copy(&mut history.data, readonly.as_file_mut()).expect("copy fixture");
        history.data = File::open(readonly.path()).expect("read-only handle");
        let error = history
            .append(vec![LogEntry {
                text: "cannot write".into(),
                level: 'E',
            }])
            .expect_err("write denied");
        history.fail(error);
        assert_eq!(history.snapshot().counts[0], 1);
        assert_eq!(history.snapshot().grouped_counts[0], 1);
        assert_eq!(
            history.page('V', 0, false).expect("old row").entries[0].text,
            "retained"
        );
        assert_eq!(
            history.snapshot().error.expect("reported error").code,
            AdbErrorCode::SaveFailed
        );
    }
}
