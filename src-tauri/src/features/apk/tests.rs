use super::{domain::*, infrastructure::NativeApkInspector};
use std::{io::Write, path::Path};
use zip::{ZipWriter, write::SimpleFileOptions};

// Minimal Android binary XML, generated here rather than depending on SDK tools
// or redistributing a third-party application. All attributes use string values.
fn manifest() -> Vec<u8> {
    let strings = [
        "manifest",
        "package",
        "com.example.fixture",
        "versionCode",
        "42",
        "versionName",
        "2.0",
        "application",
        "label",
        "Fixture",
        "uses-permission",
        "name",
        "android.permission.INTERNET",
        "activity",
        ".MainActivity",
        "exported",
        "true",
        "icon",
        "res/icon.png",
    ];
    let mut data = Vec::new();
    let mut offsets = Vec::new();
    for s in strings {
        offsets.push(data.len() as u32);
        data.extend([s.len() as u8, s.len() as u8]);
        data.extend(s.as_bytes());
        data.push(0);
    }
    while data.len() % 4 != 0 {
        data.push(0);
    }
    let mut pool = Vec::new();
    for value in [
        0x001c0001,
        (28 + offsets.len() * 4 + data.len()) as u32,
        offsets.len() as u32,
        0,
        0x100,
        (28 + offsets.len() * 4) as u32,
        0,
    ] {
        pool.extend(value.to_le_bytes());
    }
    for offset in offsets {
        pool.extend(offset.to_le_bytes());
    }
    pool.extend(data);
    pool.extend(0x00080180u32.to_le_bytes());
    pool.extend(8u32.to_le_bytes());
    fn start(out: &mut Vec<u8>, tag: u32, attrs: &[(u32, u32)]) {
        for v in [
            0x00100102,
            36 + attrs.len() as u32 * 20,
            1,
            u32::MAX,
            u32::MAX,
            tag,
            0x00140014,
            attrs.len() as u32,
            0,
        ] {
            out.extend(v.to_le_bytes());
        }
        for &(name, value) in attrs {
            for v in [u32::MAX, name, value, 0x03000008, value] {
                out.extend(v.to_le_bytes());
            }
        }
    }
    fn end(out: &mut Vec<u8>, tag: u32) {
        for v in [0x00100103u32, 24, 1, u32::MAX, u32::MAX, tag] {
            out.extend(v.to_le_bytes());
        }
    }
    start(&mut pool, 0, &[(1, 2), (3, 4), (5, 6)]);
    start(&mut pool, 10, &[(11, 12)]);
    end(&mut pool, 10);
    start(&mut pool, 7, &[(8, 9), (17, 18)]);
    start(&mut pool, 13, &[(11, 14), (15, 16)]);
    end(&mut pool, 13);
    end(&mut pool, 7);
    end(&mut pool, 0);
    let mut output = Vec::new();
    output.extend(0x00080003u32.to_le_bytes());
    output.extend((8 + pool.len() as u32).to_le_bytes());
    output.extend(pool);
    output
}

fn fixture(manifest: Option<&[u8]>) -> (tempfile::TempDir, std::path::PathBuf) {
    let dir = tempfile::tempdir().expect("temporary directory");
    let path = dir.path().join("fixture.apk");
    let mut zip = ZipWriter::new(std::fs::File::create(&path).expect("fixture file"));
    if let Some(xml) = manifest {
        zip.start_file("AndroidManifest.xml", SimpleFileOptions::default())
            .expect("manifest entry");
        zip.write_all(xml).expect("manifest content");
    }
    zip.start_file("lib/arm64-v8a/libfixture.so", SimpleFileOptions::default())
        .expect("library entry");
    zip.write_all(b"fixture").expect("library content");
    zip.finish().expect("archive");
    (dir, path)
}

#[test]
fn inspects_binary_manifest_archive_and_hash_without_sdk() {
    let (_dir, path) = fixture(Some(&manifest()));
    let apk = apk_info::Apk::new(&path).expect("binary fixture parses");
    assert!(apk.get_package_name().is_some(), "{}", apk.get_xml_string());
    let report = analyze(&path, &NativeApkInspector).expect("valid APK");
    let app = &report.sections[0];
    assert!(app.items.iter().any(|i| i.label == "Package name" && i.value.as_deref() == Some("com.example.fixture")));
    assert!(
        app.items
            .iter()
            .any(|i| i.label == "Version code" && i.value.as_deref() == Some("42"))
    );
    assert!(
        report
            .sections
            .iter()
            .any(|s| s.title == "Permissions" && s.items[0].label == "android.permission.INTERNET")
    );
    assert!(report.sections.iter().any(|s| {
        s.title == "Activities"
            && s.items[0]
                .value
                .as_deref()
                .is_some_and(|v| v.contains("exported: true"))
    }));
    assert!(report.manifest.contains("com.example.fixture"));
    assert_eq!(report.files.len(), 2);
    assert_eq!(report.signature.status, VerificationStatus::Unsigned);
    assert!(
        report
            .warnings
            .iter()
            .any(|w| w.contains("No signing certificates"))
    );
    let bytes = std::fs::read(&path).expect("fixture bytes");
    let hash: String = openssl::sha::sha256(&bytes)
        .iter()
        .map(|b| format!("{b:02X}"))
        .collect();
    assert_eq!(report.sha256, hash);
    assert_eq!(report.size, bytes.len() as u64);
    let json = serde_json::to_value(&report).expect("wire report");
    assert!(json["files"][0]["compressedSize"].is_number());
    assert!(json["iconDataUrl"].is_null());
}

#[test]
fn previews_the_referenced_raster_icon_and_ignores_unsupported_or_oversized_icons() {
    let png = openssl::base64::decode_block("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aN1sAAAAASUVORK5CYII=").expect("PNG");
    for (bytes, expected) in [
        (
            png.clone(),
            Some(format!(
                "data:image/png;base64,{}",
                openssl::base64::encode_block(&png)
            )),
        ),
        (b"<adaptive-icon/>".to_vec(), None),
        (vec![0; 2 * 1024 * 1024 + 1], None),
    ] {
        let (_dir, path) = fixture(Some(&manifest()));
        let file = std::fs::OpenOptions::new()
            .read(true)
            .write(true)
            .open(&path)
            .expect("archive");
        let mut zip = ZipWriter::new_append(file).expect("append");
        zip.start_file("res/icon.png", SimpleFileOptions::default())
            .expect("icon entry");
        zip.write_all(&bytes).expect("icon");
        zip.finish().expect("finish");
        let report =
            analyze(&path, &NativeApkInspector).expect("report survives unsupported icons");
        assert_eq!(report.icon_data_url, expected);
    }
}

#[test]
fn rejects_missing_corrupt_and_non_apk_inputs() {
    for xml in [None, Some(&b"not binary XML"[..])] {
        let (_dir, path) = fixture(xml);
        assert_eq!(
            analyze(&path, &NativeApkInspector)
                .expect_err("invalid APK")
                .code,
            "invalid_apk"
        );
    }
    assert_eq!(
        analyze(Path::new("/missing.apk"), &NativeApkInspector)
            .expect_err("missing")
            .code,
        "read_failed"
    );
    struct Unreachable;
    impl ApkInspector for Unreachable {
        fn inspect(&self, _: &Path) -> Result<ApkReport, ApkError> {
            panic!("invalid extension must not reach the adapter")
        }
    }
    assert_eq!(
        analyze(Path::new("file.zip"), &Unreachable)
            .expect_err("extension")
            .code,
        "invalid_extension"
    );
}

#[test]
fn rejects_oversized_apk_before_reading_contents() {
    let dir = tempfile::tempdir().expect("directory");
    let path = dir.path().join("large.apk");
    std::fs::File::create(&path)
        .expect("file")
        .set_len(1024 * 1024 * 1024 + 1)
        .expect("sparse file");
    assert_eq!(
        analyze(&path, &NativeApkInspector).expect_err("limit").code,
        "limit_exceeded"
    );
}

#[test]
fn reads_v1_certificate_identity_and_fingerprints_without_claiming_verification() {
    use openssl::{
        asn1::Asn1Time,
        hash::MessageDigest,
        pkcs7::{Pkcs7, Pkcs7Flags},
        pkey::PKey,
        rsa::Rsa,
        stack::Stack,
        x509::{X509, X509NameBuilder},
    };
    let key = PKey::from_rsa(Rsa::generate(2048).expect("RSA")).expect("key");
    let mut name = X509NameBuilder::new().expect("name");
    name.append_entry_by_text("CN", "APK fixture signer")
        .expect("CN");
    let name = name.build();
    let mut cert = X509::builder().expect("certificate");
    cert.set_version(2).expect("version");
    let serial = openssl::bn::BigNum::from_u32(42)
        .expect("serial")
        .to_asn1_integer()
        .expect("ASN1");
    cert.set_serial_number(&serial).expect("serial");
    cert.set_subject_name(&name).expect("subject");
    cert.set_issuer_name(&name).expect("issuer");
    cert.set_pubkey(&key).expect("public key");
    cert.set_not_before(&Asn1Time::from_unix(1704067200).expect("date"))
        .expect("start");
    cert.set_not_after(&Asn1Time::from_unix(2019686400).expect("date"))
        .expect("end");
    cert.sign(&key, MessageDigest::sha256()).expect("sign");
    let cert = cert.build();
    let signature = Pkcs7::sign(
        &cert,
        &key,
        &Stack::new().expect("chain"),
        b"fixture",
        Pkcs7Flags::BINARY | Pkcs7Flags::DETACHED,
    )
    .expect("PKCS7")
    .to_der()
    .expect("DER");
    let (_dir, path) = fixture(Some(&manifest()));
    let file = std::fs::OpenOptions::new()
        .read(true)
        .write(true)
        .open(&path)
        .expect("archive");
    let mut zip = ZipWriter::new_append(file).expect("append");
    zip.start_file("META-INF/CERT.RSA", SimpleFileOptions::default())
        .expect("signature entry");
    zip.write_all(&signature).expect("signature");
    zip.finish().expect("finish");
    let report = analyze(&path, &NativeApkInspector).expect("report");
    let certificate = report
        .sections
        .iter()
        .find(|s| s.title.starts_with("Certificate · v1"))
        .expect("v1 certificate");
    assert!(certificate.items.iter().any(|i| {
        i.label == "Subject"
            && i.value
                .as_deref()
                .is_some_and(|v| v.contains("APK fixture signer"))
    }));
    let fingerprint = cert
        .digest(MessageDigest::sha256())
        .expect("digest")
        .iter()
        .map(|b| format!("{b:02x}"))
        .collect::<String>();
    assert!(certificate.items.iter().any(|i| {
        i.label == "SHA-256"
            && i.value
                .as_deref()
                .is_some_and(|v| v.replace(':', "").to_lowercase() == fingerprint)
    }));
    assert_eq!(report.signature.status, VerificationStatus::Unverified);
    assert_eq!(report.signature.schemes, ["v1"]);
}
