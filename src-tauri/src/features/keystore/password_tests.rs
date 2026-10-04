use super::{
    application::generate,
    domain::{Format, GenerateRequest},
    infrastructure::{NativeEncoder, NativeFiles},
};
use openssl::pkcs12::Pkcs12;
use std::fs;

#[test]
fn empty_key_password_reuses_store_password_in_both_formats() {
    let directory = tempfile::tempdir().expect("tempdir");
    for format in [Format::Jks, Format::Pkcs12] {
        let request = GenerateRequest {
            path: directory
                .path()
                .join(format!("shared.{}", format.extension()))
                .to_string_lossy()
                .into_owned(),
            format,
            password: "store-password".into(),
            key_password: String::new(),
            alias: "upload".into(),
            validity_years: 30,
            common_name: "Signing".into(),
            organization: String::new(),
            organizational_unit: String::new(),
            locality: String::new(),
            state: String::new(),
            country: String::new(),
        };
        generate(&request, &NativeEncoder, &NativeFiles).expect("generate with fallback");
        let bytes = fs::read(&request.path).expect("read store");
        match format {
            Format::Jks => {
                let mut store = jks::KeyStore::new();
                store
                    .load(&mut bytes.as_slice(), request.password.as_bytes())
                    .expect("open store");
                assert!(store.get_private_key_entry("upload", b"").is_err());
                assert!(
                    store
                        .get_private_key_entry("upload", request.password.as_bytes())
                        .is_ok()
                );
            }
            Format::Pkcs12 => {
                let store = Pkcs12::from_der(&bytes).expect("PKCS12");
                assert!(store.parse2("").is_err());
                assert!(
                    store
                        .parse2(&request.password)
                        .expect("decrypt with store password")
                        .pkey
                        .is_some()
                );
            }
        }
    }
}
