use super::{application::sign_and_save, domain::*, infrastructure::NativeSigner};
use crate::features::keystore::{
    domain::{Format, GenerateRequest, KeystoreEncoder},
    infrastructure::NativeEncoder,
};
use std::{
    cell::RefCell,
    fs,
    io::{Read, Write},
    rc::Rc,
};
use zip::{ZipArchive, ZipWriter, write::SimpleFileOptions};

fn request() -> SignRequest {
    SignRequest {
        apk_path: "/input/my.app.APK".into(),
        keystore_path: "/keys/upload.jks".into(),
        alias: "upload".into(),
        password: "password".into(),
        key_password: String::new(),
    }
}

struct FakeSigner {
    events: Rc<RefCell<Vec<String>>>,
    fail: bool,
}
struct FakeArtifact(Rc<RefCell<Vec<String>>>);
impl ApkSigner for FakeSigner {
    type Artifact = FakeArtifact;
    fn sign(&self, _: &SignRequest) -> Result<FakeArtifact, SigningError> {
        self.events.borrow_mut().push("sign".into());
        if self.fail {
            return Err(SigningError::new(ErrorCode::SigningFailed, "Failed"));
        }
        Ok(FakeArtifact(self.events.clone()))
    }
}
impl SignedArtifact for FakeArtifact {
    fn save(self, path: &str) -> Result<(), SigningError> {
        self.0.borrow_mut().push(path.into());
        Ok(())
    }
}
impl Drop for FakeArtifact {
    fn drop(&mut self) {
        self.0.borrow_mut().push("cleanup".into());
    }
}

#[test]
fn signs_before_dialog_and_cleans_up_after_save_or_cancel() {
    for cancel in [true, false] {
        let events = Rc::new(RefCell::new(vec![]));
        let signer = FakeSigner {
            events: events.clone(),
            fail: false,
        };
        let result = sign_and_save(&request(), &signer, |name| {
            assert_eq!(name, "my.app-signed.apk");
            events.borrow_mut().push("dialog".into());
            Ok(if cancel {
                None
            } else {
                Some("/output/my.app-signed.apk".into())
            })
        })
        .expect("workflow");
        assert_eq!(result.is_none(), cancel);
        let expected = if cancel {
            vec!["sign", "dialog", "cleanup"]
        } else {
            vec!["sign", "dialog", "/output/my.app-signed.apk", "cleanup"]
        };
        assert_eq!(*events.borrow(), expected);
    }
}

#[test]
fn invalid_input_and_signing_failures_never_open_the_dialog() {
    let events = Rc::new(RefCell::new(vec![]));
    let signer = FakeSigner {
        events: events.clone(),
        fail: true,
    };
    assert!(sign_and_save(&request(), &signer, |_| panic!("No dialog on failure")).is_err());
    events.borrow_mut().clear();
    let mut input = request();
    input.password.clear();
    assert!(sign_and_save(&input, &signer, |_| panic!("No dialog on invalid input")).is_err());
    assert!(events.borrow().is_empty());
}

fn fixture(format: Format, directory: &std::path::Path) -> SignRequest {
    let key = GenerateRequest {
        path: directory
            .join("upload.keystore")
            .to_string_lossy()
            .into_owned(),
        format,
        password: "store-password".into(),
        key_password: if format == Format::Jks {
            "key-password".into()
        } else {
            String::new()
        },
        alias: "upload".into(),
        validity_years: 30,
        common_name: "APK Signing Test".into(),
        organization: String::new(),
        organizational_unit: String::new(),
        locality: String::new(),
        state: String::new(),
        country: String::new(),
    };
    let (bytes, _) = NativeEncoder.encode(&key).expect("encode keystore");
    fs::write(&key.path, bytes).expect("save keystore");
    let apk_path = directory.join("example.apk");
    let mut zip = ZipWriter::new(fs::File::create(&apk_path).expect("create APK"));
    for (name, content) in [
        ("AndroidManifest.xml", b"manifest".as_slice()),
        ("classes.dex", b"dex content"),
        ("lib/arm64-v8a/libtest.so", b"native library"),
        ("META-INF/OLD.SF", b"old signature"),
        ("META-INF/services/example", b"keep me"),
    ] {
        zip.start_file(
            name,
            SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored),
        )
        .expect("entry");
        zip.write_all(content).expect("content");
    }
    zip.finish().expect("finish ZIP");
    SignRequest {
        apk_path: apk_path.to_string_lossy().into_owned(),
        keystore_path: key.path.clone(),
        alias: key.alias.clone(),
        password: key.password.clone(),
        key_password: key.key_password.clone(),
    }
}

#[test]
fn signs_both_keystore_formats_verifies_content_and_preserves_sources() {
    for format in [Format::Jks, Format::Pkcs12] {
        let dir = tempfile::tempdir().expect("directory");
        let input = fixture(format, dir.path());
        let original = fs::read(&input.apk_path).expect("source");
        let destination = dir.path().join("example-signed.apk");
        let path = destination.to_string_lossy().into_owned();
        sign_and_save(&input, &NativeSigner, |name| {
            assert_eq!(name, "example-signed.apk");
            Ok(Some(path.clone()))
        })
        .expect("sign and save");
        assert_eq!(
            fs::read(&input.apk_path).expect("source unchanged"),
            original
        );
        let apk = apksig::Apk::new(destination.clone()).expect("signed APK");
        apk.verify().expect("signature verification");
        let block = apk.get_signing_block().expect("signing block");
        let signer = block
            .content
            .iter()
            .find_map(|b| match b {
                apksig::ValueSigningBlock::SignatureSchemeV2Block(v) => {
                    v.signers.signers_data.first()
                }
                _ => None,
            })
            .expect("v2 signer");
        let digest = &signer.signed_data.digests.digests_data[0];
        assert_eq!(
            apk.digest(&digest.signature_algorithm_id)
                .expect("content digest"),
            digest.digest
        );
        // Independently verify the signature with OpenSSL and the embedded certificate.
        let cert = openssl::x509::X509::from_der(
            &signer.signed_data.certificates.certificates_data[0].certificate,
        )
        .expect("certificate");
        let public = cert.public_key().expect("public key");
        let mut verifier =
            openssl::sign::Verifier::new(openssl::hash::MessageDigest::sha256(), &public)
                .expect("verifier");
        verifier
            .update(&signer.signed_data.to_u8()[4..])
            .expect("signed data");
        assert!(
            verifier
                .verify(&signer.signatures.signatures_data[0].signature)
                .expect("verify")
        );
        let mut archive =
            ZipArchive::new(fs::File::open(&destination).expect("open")).expect("ZIP");
        assert!(archive.by_name("META-INF/OLD.SF").is_err());
        assert!(archive.by_name("META-INF/services/example").is_ok());
        assert_eq!(
            archive
                .by_name("lib/arm64-v8a/libtest.so")
                .expect("library")
                .data_start()
                % 16384,
            0
        );
        let mut content = String::new();
        archive
            .by_name("classes.dex")
            .expect("dex")
            .read_to_string(&mut content)
            .expect("read dex");
        assert_eq!(content, "dex content");
        let saved = fs::read(&destination).expect("saved");
        assert!(sign_and_save(&input, &NativeSigner, |_| Ok(Some(path))).is_err());
        assert_eq!(
            fs::read(&destination).expect("unchanged destination"),
            saved
        );
        // Re-signing removes the previous signing block and still produces a valid APK.
        let mut second = request();
        second.apk_path = destination.to_string_lossy().into_owned();
        second.keystore_path = input.keystore_path.clone();
        second.password = input.password.clone();
        second.key_password = input.key_password.clone();
        NativeSigner.sign(&second).expect("re-sign");
        let mut tampered = saved;
        let position = tampered
            .windows(11)
            .position(|b| b == b"dex content")
            .expect("dex position");
        tampered[position] ^= 1;
        fs::write(&destination, tampered).expect("tamper");
        assert_ne!(
            apksig::Apk::new(destination)
                .expect("tampered")
                .digest(&digest.signature_algorithm_id)
                .expect("digest"),
            digest.digest
        );
    }
}

#[test]
fn rejects_wrong_password_alias_invalid_apk_and_unwritable_destination() {
    let dir = tempfile::tempdir().expect("directory");
    let mut input = fixture(Format::Jks, dir.path());
    input.password = "wrong".into();
    assert!(NativeSigner.sign(&input).is_err());
    input.password = "store-password".into();
    input.alias = "missing".into();
    assert!(NativeSigner.sign(&input).is_err());
    input.alias = "upload".into();
    input.key_password = "wrong".into();
    assert!(NativeSigner.sign(&input).is_err());
    input.key_password = "key-password".into();
    let artifact = NativeSigner.sign(&input).expect("sign");
    assert!(
        artifact
            .save(&dir.path().join("missing/output.apk").to_string_lossy())
            .is_err()
    );
    fs::write(&input.apk_path, b"not a ZIP").expect("invalid APK");
    assert!(NativeSigner.sign(&input).is_err());
}

#[test]
fn errors_use_the_ipc_contract_without_credentials() {
    let error = SigningError::new(ErrorCode::InvalidKeystore, "Check the keystore.");
    assert_eq!(
        serde_json::to_value(error).expect("serialize"),
        serde_json::json!({"code": "invalid_keystore", "message": "Check the keystore."})
    );
}
