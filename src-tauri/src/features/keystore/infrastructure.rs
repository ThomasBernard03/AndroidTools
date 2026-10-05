use super::domain::*;
use chrono::{Months, Utc};
use openssl::{
    asn1::Asn1Time,
    bn::{BigNum, MsbOption},
    hash::MessageDigest,
    pkcs12::Pkcs12,
    pkey::PKey,
    rsa::Rsa,
    x509::{X509, X509NameBuilder},
};
use std::{fs, io::Write, path::Path, time::SystemTime};

pub struct NativeEncoder;

impl KeystoreEncoder for NativeEncoder {
    fn encode(
        &self,
        request: &GenerateRequest,
    ) -> Result<(Vec<u8>, GeneratedKeystore), KeystoreError> {
        encode(request).map_err(|_| {
            KeystoreError::new(
                ErrorCode::GenerationFailed,
                "Could not generate the signing key and certificate. Please retry.",
            )
        })
    }
}

fn fingerprint(cert: &X509, digest: MessageDigest) -> Result<String, openssl::error::ErrorStack> {
    Ok(cert
        .digest(digest)?
        .iter()
        .map(|byte| format!("{byte:02X}"))
        .collect::<Vec<_>>()
        .join(":"))
}

fn encode(
    request: &GenerateRequest,
) -> Result<(Vec<u8>, GeneratedKeystore), Box<dyn std::error::Error>> {
    let key = PKey::from_rsa(Rsa::generate(2048)?)?;
    let mut name = X509NameBuilder::new()?;
    for (attribute, value) in [
        ("CN", &request.common_name),
        ("OU", &request.organizational_unit),
        ("O", &request.organization),
        ("L", &request.locality),
        ("ST", &request.state),
        ("C", &request.country),
    ] {
        if !value.trim().is_empty() {
            name.append_entry_by_text(attribute, value.trim())?;
        }
    }
    let name = name.build();
    let now = Utc::now();
    // Calendar years, clamping February 29 to the last day of February.
    let expiry = now
        .checked_add_months(Months::new(request.validity_years * 12))
        .ok_or("Invalid expiry")?;
    let mut serial = BigNum::new()?;
    serial.rand(128, MsbOption::ONE, false)?;
    let serial = serial.to_asn1_integer()?;
    let mut builder = X509::builder()?;
    builder.set_version(2)?;
    builder.set_serial_number(&serial)?;
    builder.set_subject_name(&name)?;
    builder.set_issuer_name(&name)?;
    builder.set_pubkey(&key)?;
    let not_before = Asn1Time::from_unix(now.timestamp())?;
    let not_after = Asn1Time::from_unix(expiry.timestamp())?;
    builder.set_not_before(&not_before)?;
    builder.set_not_after(&not_after)?;
    builder.sign(&key, MessageDigest::sha256())?;
    let cert = builder.build();
    let bytes = match request.format {
        Format::Jks => {
            let mut store = jks::KeyStore::new();
            store.set_private_key_entry(
                &request.alias,
                jks::PrivateKeyEntry {
                    creation_time: SystemTime::now(),
                    private_key: key.private_key_to_pkcs8()?,
                    certificate_chain: vec![jks::Certificate {
                        cert_type: "X.509".into(),
                        content: cert.to_der()?,
                    }],
                },
                request.effective_key_password().as_bytes(),
            )?;
            let mut bytes = Vec::new();
            store.store(&mut bytes, request.password.as_bytes())?;
            bytes
        }
        Format::Pkcs12 => Pkcs12::builder()
            .name(&request.alias)
            .pkey(&key)
            .cert(&cert)
            .build2(&request.password)?
            .to_der()?,
    };
    Ok((
        bytes,
        GeneratedKeystore {
            path: request.path.clone(),
            format: request.format,
            alias: request.alias.clone(),
            expires_at: expiry.format("%Y-%m-%d").to_string(),
            sha1: fingerprint(&cert, MessageDigest::sha1())?,
            sha256: fingerprint(&cert, MessageDigest::sha256())?,
        },
    ))
}

pub struct NativeFiles;

fn write_error(error: &std::io::Error) -> KeystoreError {
    if error.kind() == std::io::ErrorKind::AlreadyExists {
        KeystoreError::new(
            ErrorCode::AlreadyExists,
            "A file already exists at this location. Choose another name.",
        )
    } else {
        KeystoreError::new(
            ErrorCode::WriteFailed,
            "Could not save the keystore. Check that the folder exists and is writable.",
        )
    }
}

impl KeystoreFiles for NativeFiles {
    fn ensure_available(&self, path: &str) -> Result<(), KeystoreError> {
        match fs::symlink_metadata(path) {
            Ok(_) => Err(write_error(&std::io::Error::from(
                std::io::ErrorKind::AlreadyExists,
            ))),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
            Err(error) => Err(write_error(&error)),
        }
    }

    fn publish(&self, path: &str, bytes: &[u8]) -> Result<(), KeystoreError> {
        let parent = Path::new(path)
            .parent()
            .ok_or_else(|| KeystoreError::invalid("path", "Choose a destination folder."))?;
        // A sibling temporary file allows atomic no-clobber publication. tempfile
        // creates owner-only files on Unix and cleans up failed writes on drop.
        let mut file = tempfile::NamedTempFile::new_in(parent).map_err(|e| write_error(&e))?;
        file.write_all(bytes).map_err(|e| write_error(&e))?;
        file.as_file().sync_all().map_err(|e| write_error(&e))?;
        file.persist_noclobber(path)
            .map_err(|e| write_error(&e.error))?;
        Ok(())
    }
}
