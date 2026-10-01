use std::{path::PathBuf, time::Duration};

use rusqlite::Connection;

use super::ApkError;

pub struct ApkHistory(pub PathBuf);

pub fn history_error(error: impl std::fmt::Display) -> ApkError {
    ApkError::new(
        "history",
        "Impossible de lire ou d’enregistrer l’historique des APK.",
        error.to_string(),
    )
}

impl ApkHistory {
    fn connect(&self) -> Result<Connection, ApkError> {
        if let Some(parent) = self.0.parent() {
            std::fs::create_dir_all(parent).map_err(history_error)?;
        }
        let connection = Connection::open(&self.0).map_err(history_error)?;
        connection
            .busy_timeout(Duration::from_secs(5))
            .map_err(history_error)?;
        connection
            .execute_batch(
                "CREATE TABLE IF NOT EXISTS recent_apks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                path TEXT NOT NULL UNIQUE
            );",
            )
            .map_err(history_error)?;
        Ok(connection)
    }

    pub fn list(&self) -> Result<Vec<String>, ApkError> {
        let connection = self.connect()?;
        let mut query = connection
            .prepare("SELECT path FROM recent_apks ORDER BY id DESC LIMIT 10")
            .map_err(history_error)?;
        query
            .query_map([], |row| row.get(0))
            .map_err(history_error)?
            .collect::<Result<Vec<_>, _>>()
            .map_err(history_error)
    }

    pub fn remember(&self, path: &str) -> Result<(), ApkError> {
        let mut connection = self.connect()?;
        let transaction = connection.transaction().map_err(history_error)?;
        transaction
            .execute("DELETE FROM recent_apks WHERE path = ?1", [path])
            .map_err(history_error)?;
        transaction
            .execute("INSERT INTO recent_apks (path) VALUES (?1)", [path])
            .map_err(history_error)?;
        transaction.execute(
            "DELETE FROM recent_apks WHERE id NOT IN (SELECT id FROM recent_apks ORDER BY id DESC LIMIT 10)",
            [],
        ).map_err(history_error)?;
        transaction.commit().map_err(history_error)
    }

    pub fn remove(&self, path: &str) -> Result<(), ApkError> {
        self.connect()?
            .execute("DELETE FROM recent_apks WHERE path = ?1", [path])
            .map_err(history_error)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn persists_deduplicates_orders_and_limits_paths() {
        let directory = tempfile::tempdir().expect("temporary directory");
        let path = directory.path().join("data/history.sqlite");
        let history = ApkHistory(path.clone());
        assert!(history.list().expect("empty history").is_empty());
        for index in 0..12 {
            history
                .remember(&format!("/tmp/app {index}.apk"))
                .expect("save");
        }
        history.remember("/tmp/app 5.apk").expect("reopen");
        let reopened = ApkHistory(path);
        let paths = reopened.list().expect("persisted history");
        assert_eq!(paths.len(), 10);
        assert_eq!(paths[0], "/tmp/app 5.apk");
        assert_eq!(paths[1], "/tmp/app 11.apk");
        assert!(!paths.contains(&"/tmp/app 1.apk".into()));
        let unicode = "/tmp/l’application 'été'.apk";
        reopened.remember(unicode).expect("unicode path");
        assert_eq!(reopened.list().expect("list")[0], unicode);
        reopened.remove(unicode).expect("remove");
        assert!(!reopened.list().expect("list").contains(&unicode.into()));
    }

    #[test]
    fn reports_storage_failures() {
        let directory = tempfile::tempdir().expect("temporary directory");
        let history = ApkHistory(directory.path().to_path_buf());
        assert_eq!(
            history
                .remember("/tmp/demo.apk")
                .expect_err("directory is not a database")
                .code,
            "history"
        );
    }
}
