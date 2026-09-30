use std::{fs, io::Write, path::Path};

use rsa::{
    RsaPrivateKey,
    pkcs8::{DecodePrivateKey, EncodePrivateKey, LineEnding},
};

use super::ServiceError;

pub fn ensure_private_key(path: &Path) -> Result<(), ServiceError> {
    let result = (|| -> Result<(), Box<dyn std::error::Error>> {
        if path.try_exists()? {
            RsaPrivateKey::from_pkcs8_pem(&fs::read_to_string(path)?)?;
            return Ok(());
        }

        let parent = path.parent().ok_or("Missing key directory")?;
        fs::create_dir_all(parent)?;
        let private_key = RsaPrivateKey::new(&mut rsa::rand_core::OsRng, 2048)?;
        let pem = private_key.to_pkcs8_pem(LineEnding::LF)?;

        // NamedTempFile uses mode 0600 on Unix. Persist atomically without replacing an existing identity.
        let mut file = tempfile::NamedTempFile::new_in(parent)?;
        file.write_all(pem.as_bytes())?;
        file.as_file().sync_all()?;
        match file.persist_noclobber(path) {
            Ok(_) => Ok(()),
            Err(error) if error.error.kind() == std::io::ErrorKind::AlreadyExists => {
                RsaPrivateKey::from_pkcs8_pem(&fs::read_to_string(path)?)?;
                Ok(())
            }
            Err(error) => Err(Box::new(error.error)),
        }
    })();

    result.map_err(|error| {
        ServiceError::new(
            "identity",
            "Impossible de créer ou de lire la clé d’autorisation ADB de l’application.",
            error.to_string(),
        )
    })
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;

    #[test]
    fn persists_identity_between_connections() {
        let directory = tempfile::tempdir().unwrap();
        let path = directory.path().join("adbkey.pem");
        ensure_private_key(&path).unwrap();
        let first = fs::read(&path).unwrap();
        ensure_private_key(&path).unwrap();
        assert_eq!(first, fs::read(&path).unwrap());
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            assert_eq!(
                fs::metadata(&path).unwrap().permissions().mode() & 0o777,
                0o600
            );
        }
    }

    #[test]
    fn never_replaces_an_invalid_existing_key() {
        let directory = tempfile::tempdir().unwrap();
        let path = directory.path().join("adbkey.pem");
        fs::write(&path, "invalid").unwrap();
        assert!(ensure_private_key(&path).is_err());
        assert_eq!(fs::read_to_string(&path).unwrap(), "invalid");
    }
}
