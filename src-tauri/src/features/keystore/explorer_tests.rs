#![allow(clippy::unwrap_used)]
use super::{
    domain::*, explorer::*, explorer_native::NativeInspector, infrastructure::NativeEncoder,
};
use std::{fs, time::SystemTime};

fn generated(format: Format) -> Vec<u8> {
    NativeEncoder
        .encode(&GenerateRequest {
            path: "/unused".into(),
            format,
            password: "store-password".into(),
            key_password: if matches!(format, Format::Jks) {
                "key-password"
            } else {
                "store-password"
            }
            .into(),
            alias: "upload".into(),
            validity_years: 30,
            common_name: "Signing Team".into(),
            organization: "Example".into(),
            organizational_unit: String::new(),
            locality: String::new(),
            state: String::new(),
            country: "FR".into(),
        })
        .unwrap()
        .0
}
fn request(path: &std::path::Path) -> ExploreRequest {
    ExploreRequest {
        path: path.to_string_lossy().into_owned(),
        password: "store-password".into(),
        key_alias: None,
        key_password: String::new(),
    }
}

#[test]
fn explores_multiple_jks_entries_and_checks_separate_key_password_without_modifying_file() {
    let mut store = jks::KeyStore::new();
    store
        .load(generated(Format::Jks).as_slice(), b"store-password")
        .unwrap();
    let entry = store
        .get_private_key_entry("upload", b"key-password")
        .unwrap();
    store
        .set_trusted_certificate_entry(
            "trusted",
            jks::TrustedCertificateEntry {
                creation_time: SystemTime::now(),
                certificate: entry.certificate_chain[0].clone(),
            },
        )
        .unwrap();
    store
        .set_private_key_entry("second", entry, b"other-password")
        .unwrap();
    let mut bytes = Vec::new();
    store.store(&mut bytes, b"store-password").unwrap();
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("store.jks");
    fs::write(&path, &bytes).unwrap();
    let mut input = request(&path);
    let report = explore(&input, &NativeInspector).unwrap();
    assert_eq!(report.entries.len(), 3);
    assert_eq!(report.entries[0].alias.as_deref(), Some("second"));
    assert_eq!(report.entries[1].kind, "trusted_certificate");
    assert_eq!(report.entries[2].key_status, "not_checked");
    assert!(
        report.entries[2].certificates[0]
            .subject
            .contains("Signing Team")
    );
    input.key_alias = Some("upload".into());
    input.key_password = "wrong".into();
    assert_eq!(
        explore(&input, &NativeInspector).unwrap().entries[2].key_status,
        "failed"
    );
    input.key_password = "key-password".into();
    let report = explore(&input, &NativeInspector).unwrap();
    assert_eq!(report.entries[2].key_status, "verified");
    assert_eq!(report.entries[0].key_status, "not_checked");
    let wire = serde_json::to_value(&report).unwrap();
    assert_eq!(wire["entries"][2]["keyStatus"], "verified");
    assert!(wire["entries"][2]["certificates"][0]["validUntil"].is_string());
    assert!(!wire.to_string().contains("password"));
    input.key_alias = Some("missing".into());
    assert_eq!(
        explore(&input, &NativeInspector).unwrap_err().code,
        "invalid_alias"
    );
    input.password = "wrong".into();
    assert_eq!(
        explore(&input, &NativeInspector).unwrap_err().code,
        "unlock_failed"
    );
    assert_eq!(fs::read(path).unwrap(), bytes);
}

#[test]
fn verifies_pkcs12_identity_and_rejects_wrong_passwords_and_damaged_stores() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("store.p12");
    let bytes = generated(Format::Pkcs12);
    fs::write(&path, &bytes).unwrap();
    let mut input = request(&path);
    let report = explore(&input, &NativeInspector).unwrap();
    assert_eq!(report.format, "pkcs12");
    assert!(report.limitation.is_some());
    assert_eq!(report.entries[0].alias.as_deref(), Some("upload"));
    assert_eq!(report.entries[0].key_status, "verified");
    assert_eq!(report.entries[0].certificates[0].sha256.len(), 95);
    input.password = "wrong".into();
    assert_eq!(
        explore(&input, &NativeInspector).unwrap_err().code,
        "unlock_failed"
    );
    fs::write(&path, &bytes[..bytes.len() / 2]).unwrap();
    assert_eq!(
        explore(&input, &NativeInspector).unwrap_err().code,
        "invalid_keystore"
    );
}

#[test]
fn supports_empty_jks_and_empty_password_and_rejects_corruption_and_unreadable_files() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("empty.jks");
    let mut bytes = Vec::new();
    jks::KeyStore::with_options(jks::KeyStoreOptions {
        min_password_len: 0,
        ..Default::default()
    })
    .store(&mut bytes, b"")
    .unwrap();
    fs::write(&path, &bytes).unwrap();
    let mut input = request(&path);
    input.password.clear();
    assert!(
        explore(&input, &NativeInspector)
            .unwrap()
            .entries
            .is_empty()
    );
    *bytes.last_mut().unwrap() ^= 1;
    fs::write(&path, &bytes).unwrap();
    assert_eq!(
        explore(&input, &NativeInspector).unwrap_err().code,
        "unlock_failed"
    );
    fs::write(&path, &bytes[..10]).unwrap();
    assert_eq!(
        explore(&input, &NativeInspector).unwrap_err().code,
        "invalid_keystore"
    );
    fs::remove_file(&path).unwrap();
    assert_eq!(
        explore(&input, &NativeInspector).unwrap_err().code,
        "read_failed"
    );
    assert_eq!(
        explore(&request(dir.path()), &NativeInspector)
            .unwrap_err()
            .code,
        "read_failed"
    );
}

#[test]
fn validates_input_before_calling_an_injected_inspector() {
    struct Fake;
    impl KeystoreInspector for Fake {
        fn inspect(&self, _: &ExploreRequest) -> Result<KeystoreReport, ExploreError> {
            Ok(KeystoreReport {
                format: "jks",
                entries: vec![],
                limitation: None,
            })
        }
    }
    let mut input = request(std::path::Path::new("fake.jks"));
    assert!(explore(&input, &Fake).is_ok());
    input.path.clear();
    assert_eq!(explore(&input, &Fake).unwrap_err().code, "invalid_input");
}
