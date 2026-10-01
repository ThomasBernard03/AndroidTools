use serde::Serialize;

use super::{DeviceService, ServiceError};

#[derive(Debug, Serialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct LogEntry {
    level: String,
    text: String,
}

impl DeviceService {
    pub fn read_logcat(&self, device_id: &str) -> Result<Vec<LogEntry>, ServiceError> {
        // Finite snapshots release the USB interface between reads for other operations.
        let output = self.shell(
            device_id,
            "logcat -d -v threadtime -v year -v usec -t 2000 '*:V'",
        )?;
        Ok(parse_logcat(&String::from_utf8_lossy(&output)))
    }

    pub fn clear_logcat(&self, device_id: &str) -> Result<(), ServiceError> {
        self.shell(device_id, "logcat -c").map(|_| ())
    }
}

fn parse_logcat(output: &str) -> Vec<LogEntry> {
    let mut entries: Vec<LogEntry> = Vec::new();
    for line in output.lines() {
        if line.starts_with("--------- beginning of ") || line.starts_with("--------- switch to ") {
            continue;
        }
        let fields: Vec<_> = line.split_whitespace().take(5).collect();
        let level = if fields.len() == 5
            && fields[0].contains('-')
            && fields[1].contains(':')
            && fields[2].parse::<u32>().is_ok()
            && fields[3].parse::<u32>().is_ok()
            && matches!(fields[4], "V" | "D" | "I" | "W" | "E" | "F" | "A" | "S")
        {
            Some(fields[4])
        } else {
            None
        };
        if let Some(level) = level {
            entries.push(LogEntry {
                level: level.to_owned(),
                text: line.to_owned(),
            });
        } else if let Some(previous) = entries.last_mut() {
            previous.text.push('\n');
            previous.text.push_str(line);
        } else if !line.trim().is_empty() {
            entries.push(LogEntry {
                level: "?".to_owned(),
                text: line.to_owned(),
            });
        }
    }
    entries
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_priorities_and_keeps_multiline_messages() {
        let entries = parse_logcat(
            "--------- beginning of main\n2026-10-01 12:01:02.123456  42  43 E My Tag: problème\n    at example.method(File.java:1)\n2026-10-01 12:01:03.123456 42 44 I Tag: prêt\n",
        );
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].level, "E");
        assert!(entries[0].text.ends_with("at example.method(File.java:1)"));
        assert_eq!(entries[1].level, "I");
    }

    #[test]
    fn handles_empty_and_unrecognized_output() {
        assert!(parse_logcat("--------- beginning of system\n").is_empty());
        assert_eq!(parse_logcat("unexpected diagnostic")[0].level, "?");
    }
}
