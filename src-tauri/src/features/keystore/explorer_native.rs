use super::explorer::*;
use openssl::{
    hash::MessageDigest,
    pkcs12::Pkcs12,
    pkey::PKey,
    x509::{X509, X509NameRef},
};
use std::{fs::File, io::Read};
use zeroize::Zeroizing;

pub struct NativeInspector;

fn invalid() -> ExploreError {
    ExploreError::new(
        "invalid_keystore",
        "The keystore could not be decoded. It may be damaged or use an unsupported format or encryption algorithm.",
    )
}
fn unlock() -> ExploreError {
    ExploreError::new(
        "unlock_failed",
        "Could not verify the keystore password and integrity. The password may be incorrect, the file may be damaged, or its encryption may be unsupported.",
    )
}
fn read_error() -> ExploreError {
    ExploreError::new(
        "read_failed",
        "Could not read the keystore. Choose a readable regular file up to 16 MiB.",
    )
}

fn name(value: &X509NameRef) -> Result<String, ExploreError> {
    value
        .entries()
        .map(|e| {
            Ok(format!(
                "{}={}",
                e.object().nid().short_name().unwrap_or("OID"),
                e.data().to_string().map_err(|_| invalid())?
            ))
        })
        .collect::<Result<Vec<_>, ExploreError>>()
        .map(|v| v.join(", "))
}
fn certificate(cert: &X509) -> Result<CertificateInfo, ExploreError> {
    let fingerprint = |digest| -> Result<String, ExploreError> {
        Ok(cert
            .digest(digest)
            .map_err(|_| invalid())?
            .iter()
            .map(|b| format!("{b:02X}"))
            .collect::<Vec<_>>()
            .join(":"))
    };
    Ok(CertificateInfo {
        subject: name(cert.subject_name())?,
        issuer: name(cert.issuer_name())?,
        serial: cert
            .serial_number()
            .to_bn()
            .and_then(|n| n.to_hex_str())
            .map_err(|_| invalid())?
            .to_string(),
        valid_from: cert.not_before().to_string(),
        valid_until: cert.not_after().to_string(),
        sha1: fingerprint(MessageDigest::sha1())?,
        sha256: fingerprint(MessageDigest::sha256())?,
    })
}

impl KeystoreInspector for NativeInspector {
    fn inspect(&self, request: &ExploreRequest) -> Result<KeystoreReport, ExploreError> {
        let file = File::open(&request.path).map_err(|_| read_error())?;
        let metadata = file.metadata().map_err(|_| read_error())?;
        if !metadata.is_file() || metadata.len() > 16 * 1024 * 1024 {
            return Err(read_error());
        }
        let mut bytes = Zeroizing::new(Vec::new());
        file.take(16 * 1024 * 1024 + 1)
            .read_to_end(&mut bytes)
            .map_err(|_| read_error())?;
        if bytes.len() > 16 * 1024 * 1024 {
            return Err(read_error());
        }
        if bytes.starts_with(&[0xfe, 0xed, 0xfe, 0xed]) {
            inspect_jks(&bytes, request)
        } else {
            inspect_pkcs12(&bytes, request)
        }
    }
}

fn inspect_jks(bytes: &[u8], request: &ExploreRequest) -> Result<KeystoreReport, ExploreError> {
    let expected_entries = super::explorer_jks::validate(bytes)?;
    let mut store = jks::KeyStore::new();
    let mut input = bytes;
    store
        .load(&mut input, request.password.as_bytes())
        .map_err(|e| match e {
            jks::KeyStoreError::InvalidDigest => unlock(),
            _ => invalid(),
        })?;
    if !input.is_empty() || store.len() != expected_entries {
        return Err(invalid());
    }
    let mut aliases = store.aliases();
    aliases.sort();
    if request
        .key_alias
        .as_ref()
        .is_some_and(|a| !store.is_private_key_entry(a))
    {
        return Err(ExploreError::new(
            "invalid_alias",
            "The selected alias is not a private key entry.",
        ));
    }
    let mut entries = Vec::new();
    for alias in aliases {
        let private = store.is_private_key_entry(&alias);
        let chain = if private {
            store
                .get_private_key_entry_certificate_chain(&alias)
                .map_err(|_| invalid())?
        } else {
            vec![
                store
                    .get_trusted_certificate_entry(&alias)
                    .map_err(|_| invalid())?
                    .certificate,
            ]
        };
        let certs = chain
            .iter()
            .map(|c| X509::from_der(&c.content).map_err(|_| invalid()))
            .collect::<Result<Vec<_>, _>>()?;
        let mut key_status = if private {
            "not_checked"
        } else {
            "not_applicable"
        };
        if request
            .key_alias
            .as_deref()
            .is_some_and(|a| a.eq_ignore_ascii_case(&alias))
        {
            let password = if request.key_password.is_empty() {
                &request.password
            } else {
                &request.key_password
            };
            key_status = match store.get_private_key_entry(&alias, password.as_bytes()) {
                Ok(mut entry) => {
                    let der = Zeroizing::new(std::mem::take(&mut entry.private_key));
                    match (
                        PKey::private_key_from_pkcs8(&der),
                        certs.first().and_then(|c| c.public_key().ok()),
                    ) {
                        (Ok(key), Some(public)) if key.public_eq(&public) => "verified",
                        _ => "failed",
                    }
                }
                Err(_) => "failed",
            };
        }
        entries.push(ExploredEntry {
            alias: Some(alias),
            kind: if private {
                "private_key"
            } else {
                "trusted_certificate"
            },
            key_status,
            certificates: certs.iter().map(certificate).collect::<Result<_, _>>()?,
        });
    }
    Ok(KeystoreReport {
        format: "jks",
        entries,
        limitation: None,
    })
}

fn inspect_pkcs12(bytes: &[u8], request: &ExploreRequest) -> Result<KeystoreReport, ExploreError> {
    let parsed = Pkcs12::from_der(bytes)
        .map_err(|_| invalid())?
        .parse2(&request.password)
        .map_err(|_| unlock())?;
    let mut entries = Vec::new();
    if let Some(cert) = parsed.cert {
        let alias = cert
            .alias()
            .map(|a| String::from_utf8_lossy(a).into_owned());
        if request
            .key_alias
            .as_ref()
            .is_some_and(|a| Some(a) != alias.as_ref())
        {
            return Err(ExploreError::new(
                "invalid_alias",
                "The selected alias does not match the PKCS12 signing identity.",
            ));
        }
        let private = parsed.pkey.is_some();
        let status = if let Some(key) = parsed.pkey {
            let public = cert.public_key().map_err(|_| invalid())?;
            if (!request.key_password.is_empty() && request.key_password != request.password)
                || !key.public_eq(&public)
            {
                "failed"
            } else {
                "verified"
            }
        } else {
            "not_applicable"
        };
        entries.push(ExploredEntry {
            alias,
            kind: if private {
                "private_key"
            } else {
                "trusted_certificate"
            },
            key_status: status,
            certificates: vec![certificate(&cert)?],
        });
    } else if parsed.pkey.is_some() {
        return Err(invalid());
    }
    if let Some(ca) = parsed.ca {
        for cert in ca {
            entries.push(ExploredEntry {
                alias: cert
                    .alias()
                    .map(|a| String::from_utf8_lossy(a).into_owned()),
                kind: "certificate",
                key_status: "not_applicable",
                certificates: vec![certificate(&cert)?],
            });
        }
    }
    Ok(KeystoreReport {
        format: "pkcs12",
        entries,
        limitation: Some(
            "PKCS12 shows the first signing identity and additional certificates exposed by OpenSSL. Multi-key inventory is not supported. Key and store passwords must match. OpenSSL checks password protection and the integrity MAC when present; MAC-less stores cannot establish store integrity. A successful read is not a complete audit of all bags.",
        ),
    })
}
