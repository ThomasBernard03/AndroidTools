use super::{
    application::generate,
    domain::*,
    infrastructure::{NativeEncoder, NativeFiles},
};
use openssl::{hash::MessageDigest, pkcs12::Pkcs12, pkey::PKey, x509::X509};
use std::{cell::Cell, fs, path::Path};

fn request(path: &Path, format: Format) -> GenerateRequest {
    GenerateRequest {
        path: path.to_string_lossy().into_owned(),
        format,
        password: "test-store-password".into(),
        key_password: "test-key-password".into(),
        alias: "upload".into(),
        validity_years: 30,
        common_name: "Example, Signing + Team".into(),
        organization: "Example Studio".into(),
        organizational_unit: String::new(),
        locality: "Paris".into(),
        state: "Île-de-France".into(),
        country: "FR".into(),
    }
}

struct FakeEncoder(Cell<usize>);
impl KeystoreEncoder for FakeEncoder {
    fn encode(&self, r: &GenerateRequest) -> Result<(Vec<u8>, GeneratedKeystore), KeystoreError> {
        self.0.set(self.0.get() + 1);
        Ok((
            vec![1, 2, 3],
            GeneratedKeystore {
                path: r.path.clone(),
                format: r.format,
                alias: r.alias.clone(),
                expires_at: "2056-10-03".into(),
                sha1: "AA".into(),
                sha256: "BB".into(),
            },
        ))
    }
}

#[test]
fn rejects_invalid_input_before_crypto_or_filesystem_operations() {
    let directory = tempfile::tempdir().expect("tempdir");
    let mut r = request(&directory.path().join("test.jks"), Format::Jks);
    let encoder = FakeEncoder(Cell::new(0));
    r.password = "short".into();
    assert_eq!(
        generate(&r, &encoder, &NativeFiles)
            .expect_err("short password")
            .field
            .as_deref(),
        Some("password")
    );
    r.password = "long-enough".into();
    r.validity_years = 0;
    assert_eq!(
        generate(&r, &encoder, &NativeFiles)
            .expect_err("invalid years")
            .field
            .as_deref(),
        Some("validityYears")
    );
    r.validity_years = 30;
    r.country = "France".into();
    assert_eq!(
        generate(&r, &encoder, &NativeFiles)
            .expect_err("invalid country")
            .field
            .as_deref(),
        Some("country")
    );
    r.country = "FR".into();
    r.format = Format::Pkcs12;
    r.path = directory
        .path()
        .join("test.p12")
        .to_string_lossy()
        .into_owned();
    assert_eq!(
        generate(&r, &encoder, &NativeFiles)
            .expect_err("different passwords")
            .field
            .as_deref(),
        Some("keyPassword")
    );
    assert_eq!(encoder.0.get(), 0);
    assert_eq!(fs::read_dir(directory.path()).expect("list").count(), 0);
}

#[test]
fn preserves_existing_files_and_rejects_a_destination_created_during_generation() {
    let directory = tempfile::tempdir().expect("tempdir");
    let path = directory.path().join("test.jks");
    let r = request(&path, Format::Jks);
    let encoder = FakeEncoder(Cell::new(0));
    fs::write(&path, b"existing").expect("write");
    assert!(matches!(
        generate(&r, &encoder, &NativeFiles)
            .expect_err("existing")
            .code,
        ErrorCode::AlreadyExists
    ));
    assert_eq!(encoder.0.get(), 0);
    // Simulates a race after the application's availability check.
    assert!(matches!(
        NativeFiles
            .publish(&r.path, b"replacement")
            .expect_err("race")
            .code,
        ErrorCode::AlreadyExists
    ));
    assert_eq!(fs::read(path).expect("read"), b"existing");
    assert_eq!(fs::read_dir(directory.path()).expect("list").count(), 1);
}

#[test]
fn reports_write_failures_and_cleans_up_temporary_files() {
    let directory = tempfile::tempdir().expect("tempdir");
    let r = request(&directory.path().join("missing/test.jks"), Format::Jks);
    let encoder = FakeEncoder(Cell::new(0));
    assert!(matches!(
        generate(&r, &encoder, &NativeFiles)
            .expect_err("missing folder")
            .code,
        ErrorCode::WriteFailed
    ));
    assert_eq!(fs::read_dir(directory.path()).expect("list").count(), 0);
}

#[test]
fn crypto_failure_does_not_publish_a_file() {
    struct BrokenEncoder;
    impl KeystoreEncoder for BrokenEncoder {
        fn encode(
            &self,
            _: &GenerateRequest,
        ) -> Result<(Vec<u8>, GeneratedKeystore), KeystoreError> {
            Err(KeystoreError::new(
                ErrorCode::GenerationFailed,
                "Simulated failure",
            ))
        }
    }
    let directory = tempfile::tempdir().expect("tempdir");
    let r = request(&directory.path().join("test.jks"), Format::Jks);
    assert!(matches!(
        generate(&r, &BrokenEncoder, &NativeFiles)
            .expect_err("crypto failure")
            .code,
        ErrorCode::GenerationFailed
    ));
    assert_eq!(fs::read_dir(directory.path()).expect("list").count(), 0);
}

#[test]
fn creates_reopenable_stores_with_matching_rsa_keys_certificates_and_fingerprints() {
    let directory = tempfile::tempdir().expect("tempdir");
    for format in [Format::Jks, Format::Pkcs12] {
        let path = directory
            .path()
            .join(format!("test.{}", format.extension()));
        let mut r = request(&path, format);
        if format == Format::Pkcs12 {
            r.key_password = r.password.clone();
        }
        let result = generate(&r, &NativeEncoder, &NativeFiles).expect("generate");
        let bytes = fs::read(&path).expect("read");
        let (key, cert) = match format {
            Format::Jks => {
                let mut store = jks::KeyStore::new();
                assert!(store.load(&mut bytes.as_slice(), b"incorrect").is_err());
                let mut store = jks::KeyStore::new();
                store
                    .load(&mut bytes.as_slice(), r.password.as_bytes())
                    .expect("load JKS");
                assert!(store.get_private_key_entry("upload", b"incorrect").is_err());
                let entry = store
                    .get_private_key_entry("upload", r.key_password.as_bytes())
                    .expect("decrypt key");
                (
                    PKey::private_key_from_pkcs8(&entry.private_key).expect("key"),
                    X509::from_der(&entry.certificate_chain[0].content).expect("certificate"),
                )
            }
            Format::Pkcs12 => {
                let store = Pkcs12::from_der(&bytes).expect("PKCS12");
                assert!(store.parse2("incorrect").is_err());
                let parsed = store.parse2(&r.password).expect("decrypt PKCS12");
                (parsed.pkey.expect("key"), parsed.cert.expect("cert"))
            }
        };
        assert_eq!(key.bits(), 2048);
        assert!(cert.public_key().expect("public key").public_eq(&key));
        assert!(cert.verify(&key).expect("verify self signature"));
        assert_eq!(
            cert.signature_algorithm().object().nid(),
            openssl::nid::Nid::SHA256WITHRSAENCRYPTION
        );
        assert_eq!(
            cert.subject_name()
                .entries_by_nid(openssl::nid::Nid::STATEORPROVINCENAME)
                .next()
                .expect("state")
                .data()
                .to_string()
                .expect("UTF-8"),
            "Île-de-France"
        );
        assert!(
            (10957..=10958).contains(
                &cert
                    .not_before()
                    .diff(cert.not_after())
                    .expect("duration")
                    .days
            )
        );
        for (actual, digest) in [
            (&result.sha1, MessageDigest::sha1()),
            (&result.sha256, MessageDigest::sha256()),
        ] {
            assert_eq!(
                *actual,
                cert.digest(digest)
                    .expect("digest")
                    .iter()
                    .map(|b| format!("{b:02X}"))
                    .collect::<Vec<_>>()
                    .join(":")
            );
        }
        let wire = serde_json::to_value(&result).expect("serialize");
        assert_eq!(wire["path"], r.path);
        assert!(wire.get("expiresAt").is_some());
        assert!(!wire.to_string().contains("password"));
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            assert_eq!(
                fs::metadata(&path).expect("metadata").permissions().mode() & 0o777,
                0o600
            );
        }
    }
}

/// Optional cross-tool verification; never required by the SDK/Java-free suite.
#[test]
#[ignore = "requires a local Java keytool executable"]
fn keytool_can_import_both_formats_including_the_private_key() {
    let directory = tempfile::tempdir().expect("tempdir");
    for format in [Format::Jks, Format::Pkcs12] {
        let source = directory
            .path()
            .join(format!("source.{}", format.extension()));
        let destination = directory
            .path()
            .join(format!("imported-{}.p12", format.extension()));
        let mut r = request(&source, format);
        if format == Format::Pkcs12 {
            r.key_password = r.password.clone();
        }
        generate(&r, &NativeEncoder, &NativeFiles).expect("generate");
        let output = std::process::Command::new("keytool")
            .args(["-importkeystore", "-noprompt", "-srckeystore"])
            .arg(&source)
            .args([
                "-srcstoretype",
                if format == Format::Jks {
                    "JKS"
                } else {
                    "PKCS12"
                },
                "-srcstorepass",
                &r.password,
                "-srcalias",
                &r.alias,
                "-srckeypass",
                &r.key_password,
                "-destkeystore",
            ])
            .arg(&destination)
            .args([
                "-deststoretype",
                "PKCS12",
                "-deststorepass",
                "test-destination-password",
            ])
            .output()
            .expect("run keytool");
        assert!(
            output.status.success(),
            "{}",
            String::from_utf8_lossy(&output.stderr)
        );
        let imported = Pkcs12::from_der(&fs::read(destination).expect("imported file"))
            .expect("PKCS12")
            .parse2("test-destination-password")
            .expect("decrypt imported");
        assert!(imported.pkey.is_some());
    }
}
