use super::*;
use sha2::{Digest, Sha256};
use std::{
    fs,
    io::{Cursor, Write},
};
use zip::{ZipWriter, write::SimpleFileOptions};

fn archive(entries: &[(&str, &[u8])]) -> Vec<u8> {
    let mut writer = ZipWriter::new(Cursor::new(Vec::new()));
    for (name, bytes) in entries {
        writer
            .start_file(
                *name,
                SimpleFileOptions::default().compression_method(zip::CompressionMethod::Deflated),
            )
            .unwrap();
        writer.write_all(bytes).unwrap();
    }
    writer.finish().unwrap().into_inner()
}

fn chunk(kind: u16, header_size: u16, body: &[u8]) -> Vec<u8> {
    let mut output = Vec::new();
    output.extend(kind.to_le_bytes());
    output.extend(header_size.to_le_bytes());
    output.extend(((body.len() + 8) as u32).to_le_bytes());
    output.extend(body);
    output
}

fn words(values: &[u32]) -> Vec<u8> {
    values
        .iter()
        .flat_map(|value| value.to_le_bytes())
        .collect()
}

// Generate a real binary AXML fixture instead of requiring Android SDK tools or a downloaded APK.
fn binary_manifest() -> Vec<u8> {
    let strings = [
        "android",
        "http://schemas.android.com/apk/res/android",
        "manifest",
        "package",
        "com.example.demo",
        "versionCode",
        "17",
        "versionName",
        "1.2",
        "uses-sdk",
        "minSdkVersion",
        "24",
        "targetSdkVersion",
        "35",
        "uses-permission",
        "name",
        "android.permission.INTERNET",
        "uses-permission-sdk-23",
        "android.permission.READ_PHONE_STATE",
        "maxSdkVersion",
        "32",
        "permission",
        "com.example.ACCESS",
        "protectionLevel",
        "signature",
        "application",
        "label",
        "Demo",
    ];
    let index = |value: &str| strings.iter().position(|s| *s == value).unwrap() as u32;
    let mut data = Vec::new();
    let mut offsets = Vec::new();
    for string in strings {
        offsets.push(data.len() as u32);
        data.extend([string.len() as u8, string.len() as u8]);
        data.extend(string.as_bytes());
        data.push(0);
    }
    while data.len() % 4 != 0 {
        data.push(0);
    }
    let mut pool = words(&[
        strings.len() as u32,
        0,
        0x100,
        28 + strings.len() as u32 * 4,
        0,
    ]);
    pool.extend(words(&offsets));
    pool.extend(data);
    let mut body = chunk(1, 28, &pool);
    body.extend(chunk(0x100, 16, &words(&[1, u32::MAX, 0, 1])));
    let start = |name: &str, attributes: &[(&str, &str, bool)]| {
        let mut data = words(&[1, u32::MAX, u32::MAX, index(name)]);
        for value in [20u16, 20, attributes.len() as u16, 0, 0, 0] {
            data.extend(value.to_le_bytes());
        }
        for (name, value, android) in attributes {
            let typed_integer = match *name {
                "protectionLevel" => Some(2u32),
                "versionCode" | "minSdkVersion" | "targetSdkVersion" | "maxSdkVersion" => {
                    Some(value.parse::<u32>().unwrap())
                }
                _ => None,
            };
            data.extend(words(&[
                if *android { 1 } else { u32::MAX },
                index(name),
                if typed_integer.is_some() {
                    u32::MAX
                } else {
                    index(value)
                },
            ]));
            data.extend([8, 0, 0, if typed_integer.is_some() { 0x10 } else { 3 }]);
            data.extend(typed_integer.unwrap_or_else(|| index(value)).to_le_bytes());
        }
        chunk(0x102, 16, &data)
    };
    let end = |name| chunk(0x103, 16, &words(&[1, u32::MAX, u32::MAX, index(name)]));
    body.extend(start(
        "manifest",
        &[
            ("package", "com.example.demo", false),
            ("versionCode", "17", true),
            ("versionName", "1.2", true),
        ],
    ));
    for (name, attrs) in [
        (
            "uses-sdk",
            vec![
                ("minSdkVersion", "24", true),
                ("targetSdkVersion", "35", true),
            ],
        ),
        (
            "uses-permission",
            vec![("name", "android.permission.INTERNET", true)],
        ),
        (
            "uses-permission-sdk-23",
            vec![
                ("name", "android.permission.READ_PHONE_STATE", true),
                ("maxSdkVersion", "32", true),
            ],
        ),
        (
            "permission",
            vec![
                ("name", "com.example.ACCESS", true),
                ("protectionLevel", "signature", true),
            ],
        ),
        ("application", vec![("label", "Demo", true)]),
    ] {
        body.extend(start(name, &attrs));
        body.extend(end(name));
    }
    body.extend(end("manifest"));
    body.extend(chunk(0x101, 16, &words(&[1, u32::MAX, 0, 1])));
    chunk(3, 8, &body)
}

fn analyze_bytes(bytes: &[u8]) -> Result<ApkReport, ApkError> {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("démo app.APK");
    fs::write(&path, bytes).unwrap();
    analyze(&path)
}

#[test]
fn keystore_preserves_existing_companion() {
    let dir = tempfile::tempdir().unwrap();
    let output = dir.path().join("release.p12");
    let information = dir.path().join("release.p12.json");
    fs::write(&information, b"existing information").unwrap();
    let result = crate::apk_tools::generate_keystore(crate::apk_tools::KeystoreRequest {
        output_path: output.to_string_lossy().into_owned(),
        alias: "release".into(),
        password: "secret123".into(),
        common_name: "Test".into(),
        organization: String::new(),
        country: String::new(),
        validity_days: 365,
    });
    assert!(result.is_err());
    assert!(!output.exists());
    assert_eq!(fs::read(information).unwrap(), b"existing information");
}

fn signing_roundtrip(check_official_tools: bool) {
    use crate::apk_tools::{
        KeystoreRequest, SignRequest, generate_keystore, sign_apk, verify_generated_apk,
    };
    let dir = tempfile::tempdir().unwrap();
    let apk = dir.path().join("démo unsigned.apk");
    let keystore = dir.path().join("release key.p12");
    let output = dir.path().join("signed.apk");
    let mut writer = ZipWriter::new(Cursor::new(Vec::new()));
    writer
        .start_file(
            "AndroidManifest.xml",
            SimpleFileOptions::default().compression_method(zip::CompressionMethod::Deflated),
        )
        .unwrap();
    writer.write_all(&binary_manifest()).unwrap();
    writer
        .start_file(
            "lib/arm64-v8a/libdemo.so",
            SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored),
        )
        .unwrap();
    writer.write_all(&vec![42; 2 * 1024 * 1024 + 71]).unwrap();
    writer
        .start_file("META-INF/OLD.RSA", SimpleFileOptions::default())
        .unwrap();
    writer.write_all(b"old signature").unwrap();
    writer
        .start_file("META-INF/services/test", SimpleFileOptions::default())
        .unwrap();
    writer.write_all(b"keep me").unwrap();
    let original = writer.finish().unwrap().into_inner();
    fs::write(&apk, &original).unwrap();
    generate_keystore(KeystoreRequest {
        output_path: keystore.to_string_lossy().into_owned(),
        alias: "release".into(),
        password: "test password $ & 123".into(),
        common_name: "Android Tools Test".into(),
        organization: "Test".into(),
        country: "FR".into(),
        validity_days: 10000,
    })
    .unwrap();
    let request = |password: &str| SignRequest {
        apk_path: apk.to_string_lossy().into_owned(),
        keystore_path: keystore.to_string_lossy().into_owned(),
        output_path: output.to_string_lossy().into_owned(),
        alias: "release".into(),
        store_password: password.into(),
        key_password: String::new(),
    };
    let information_path = dir.path().join("release key.p12.json");
    let information: serde_json::Value =
        serde_json::from_slice(&fs::read(&information_path).unwrap()).unwrap();
    assert_eq!(information["keystoreFile"], "release key.p12");
    assert_eq!(information["alias"], "release");
    assert_eq!(information["storePassword"], "test password $ & 123");
    assert_eq!(information["keyPassword"], information["storePassword"]);
    assert_eq!(information["commonName"], "Android Tools Test");
    assert_eq!(information["validityDays"], 10000);
    assert!(
        information["expiresAtUtc"].as_str().unwrap()
            > information["createdAtUtc"].as_str().unwrap()
    );
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        assert_eq!(
            fs::metadata(&information_path)
                .unwrap()
                .permissions()
                .mode()
                & 0o777,
            0o600
        );
    }
    assert!(sign_apk(request("incorrect password")).is_err());
    assert!(!output.exists());
    sign_apk(request("test password $ & 123")).unwrap();
    assert!(output.is_file());
    assert_eq!(fs::read(&apk).unwrap(), original);
    assert!(sign_apk(request("test password $ & 123")).is_err());
    let store =
        p12_keystore::KeyStore::from_pkcs12(&fs::read(&keystore).unwrap(), "test password $ & 123")
            .unwrap();
    let (_, chain) = store.private_key_chain().unwrap();
    let cert = chain.chain()[0].as_der();
    verify_generated_apk(&output, cert).unwrap();
    let mut signed = zip::ZipArchive::new(fs::File::open(&output).unwrap()).unwrap();
    assert!(signed.by_name("META-INF/OLD.RSA").is_err());
    assert!(signed.by_name("META-INF/services/test").is_ok());
    let data_offset = signed
        .by_name("lib/arm64-v8a/libdemo.so")
        .unwrap()
        .data_start();
    assert_eq!(data_offset % 16384, 0);
    drop(signed);

    let resigned = dir.path().join("resigned.apk");
    let mut resign = request("test password $ & 123");
    resign.apk_path = output.to_string_lossy().into_owned();
    resign.output_path = resigned.to_string_lossy().into_owned();
    sign_apk(resign).unwrap();
    verify_generated_apk(&resigned, cert).unwrap();

    let mut jks = jks::KeyStore::new();
    jks.set_private_key_entry(
        "release",
        jks::PrivateKeyEntry {
            creation_time: std::time::SystemTime::now(),
            private_key: chain.key().to_vec(),
            certificate_chain: vec![jks::Certificate {
                cert_type: "X509".into(),
                content: cert.to_vec(),
            }],
        },
        b"key-password",
    )
    .unwrap();
    let jks_path = dir.path().join("release.jks");
    jks.store(fs::File::create(&jks_path).unwrap(), b"store-password")
        .unwrap();
    let mut jks_request = request("store-password");
    jks_request.keystore_path = jks_path.to_string_lossy().into_owned();
    jks_request.key_password = "key-password".into();
    jks_request.output_path = dir
        .path()
        .join("jks-signed.apk")
        .to_string_lossy()
        .into_owned();
    sign_apk(jks_request).unwrap();

    if check_official_tools {
        let apksigner =
            std::env::var("ANDROID_TOOLS_APKSIGNER").expect("Set ANDROID_TOOLS_APKSIGNER");
        let zipalign = std::env::var("ANDROID_TOOLS_ZIPALIGN").expect("Set ANDROID_TOOLS_ZIPALIGN");
        assert!(
            std::process::Command::new(apksigner)
                .args(["verify", "--verbose", "--min-sdk-version", "24"])
                .arg(&output)
                .status()
                .unwrap()
                .success()
        );
        assert!(
            std::process::Command::new(zipalign)
                .args(["-c", "-P", "16", "4"])
                .arg(&output)
                .status()
                .unwrap()
                .success()
        );
        assert!(
            std::process::Command::new("keytool")
                .args(["-list", "-keystore"])
                .arg(&keystore)
                .args([
                    "-storepass:env",
                    "ANDROID_TOOLS_TEST_PASSWORD",
                    "-alias",
                    "release"
                ])
                .env("ANDROID_TOOLS_TEST_PASSWORD", "test password $ & 123")
                .status()
                .unwrap()
                .success()
        );
    }

    use std::io::{Seek, SeekFrom};
    let mut tampered = fs::OpenOptions::new().write(true).open(&output).unwrap();
    tampered.seek(SeekFrom::Start(data_offset)).unwrap();
    tampered.write_all(&[0]).unwrap();
    drop(tampered);
    assert!(verify_generated_apk(&output, cert).is_err());
}

#[test]
fn native_keystore_and_apk_signing_roundtrip() {
    signing_roundtrip(false);
}

#[test]
#[ignore = "Requires keytool, ANDROID_TOOLS_APKSIGNER and ANDROID_TOOLS_ZIPALIGN"]
fn native_signatures_are_compatible_with_android_tools() {
    signing_roundtrip(true);
}

#[test]
fn decodes_binary_manifest_and_permissions_from_an_apk() {
    let report = analyze_bytes(&archive(&[("AndroidManifest.xml", &binary_manifest())])).unwrap();
    assert_eq!(report.package_name.as_deref(), Some("com.example.demo"));
    assert_eq!(report.app_label.as_deref(), Some("Demo"));
    assert_eq!(report.version_name.as_deref(), Some("1.2"));
    assert_eq!(report.version_code.as_deref(), Some("17"));
    assert_eq!(report.min_sdk.as_deref(), Some("24"));
    assert_eq!(report.target_sdk.as_deref(), Some("35"));
    assert!(report.manifest.contains("<manifest"));
    assert_eq!(report.permissions.len(), 3);
    assert_eq!(report.permissions[1].kind, "requestedSdk23");
    assert_eq!(report.permissions[1].max_sdk.as_deref(), Some("32"));
    assert_eq!(
        report.permissions[2].protection_level.as_deref(),
        Some("signature")
    );
    assert!(report.signatures.is_empty());
    assert!(report.signature_warnings.is_empty());
}

#[test]
fn corrupt_v1_signature_does_not_hide_manifest_and_permissions() {
    let report = analyze_bytes(&archive(&[
        ("AndroidManifest.xml", &binary_manifest()),
        ("META-INF/CERT.RSA", b"broken certificate"),
    ]))
    .unwrap();
    assert_eq!(report.permissions.len(), 3);
    assert_eq!(report.signature_warnings.len(), 1);
    assert!(report.signatures.is_empty());
}

#[test]
fn rejects_empty_invalid_and_manifestless_archives() {
    assert_eq!(analyze_bytes(b"").unwrap_err().code, "file");
    assert_eq!(analyze_bytes(b"not a zip").unwrap_err().code, "archive");
    assert_eq!(
        analyze_bytes(&archive(&[("classes.dex", b"dex")]))
            .unwrap_err()
            .code,
        "manifest"
    );
    assert_eq!(
        analyze_bytes(&archive(&[("AndroidManifest.xml", b"broken axml")]))
            .unwrap_err()
            .code,
        "manifest"
    );
    assert_eq!(
        analyze(Path::new("test.zip")).unwrap_err().code,
        "extension"
    );
}

#[test]
fn permission_parsing_uses_namespaces_and_only_root_declarations() {
    let parsed = permissions::parse(r#"<manifest xmlns:a="http://schemas.android.com/apk/res/android"><uses-permission a:name="android.permission.CAMERA" a:maxSdkVersion="30"/><uses-permission-sdk-m a:name="android.permission.LOCATION"/><permission a:name="custom" a:protectionLevel="signature"/><application><uses-permission a:name="not.a.root.permission"/></application></manifest>"#).unwrap();
    assert_eq!(parsed.len(), 3);
    assert_eq!(parsed[0].max_sdk.as_deref(), Some("30"));
    assert_eq!(parsed[1].kind, "requestedSdk23");
    assert!(permissions::parse("<invalid/>").is_err());
}

fn prefixed(data: &[u8]) -> Vec<u8> {
    let mut output = words(&[data.len() as u32]);
    output.extend(data);
    output
}

#[test]
fn extracts_real_certificate_and_fingerprint_from_v2_block() {
    let cert = rcgen::generate_simple_self_signed(vec!["apk-test.local".into()])
        .unwrap()
        .cert;
    let der = cert.der();
    let mut signed_data = prefixed(&[]);
    signed_data.extend(prefixed(&prefixed(der.as_ref())));
    signed_data.extend(prefixed(&[]));
    let mut signer = prefixed(&signed_data);
    // These fields are deliberately empty: extraction must never claim cryptographic validity.
    signer.extend(prefixed(&[]));
    signer.extend(prefixed(&[]));
    let value = prefixed(&prefixed(&signer));
    let mut pair = ((4 + value.len()) as u64).to_le_bytes().to_vec();
    pair.extend(0x7109871au32.to_le_bytes());
    pair.extend(value);
    let block_size = (pair.len() + 24) as u64;
    let mut block = block_size.to_le_bytes().to_vec();
    block.extend(pair);
    block.extend(block_size.to_le_bytes());
    block.extend(b"APK Sig Block 42");

    let mut apk = archive(&[("AndroidManifest.xml", &binary_manifest())]);
    let eocd = apk.len() - 22;
    let directory = u32::from_le_bytes(apk[eocd + 16..eocd + 20].try_into().unwrap()) as usize;
    let new_directory = (directory + block.len()) as u32;
    apk[eocd + 16..eocd + 20].copy_from_slice(&new_directory.to_le_bytes());
    apk.splice(directory..directory, block);

    let report = analyze_bytes(&apk).unwrap();
    assert_eq!(report.signatures.len(), 1);
    assert_eq!(report.signatures[0].scheme, "v2");
    let extracted = &report.signatures[0].certificates[0];
    assert_eq!(
        extracted.sha256,
        format!("{:x}", Sha256::digest(der.as_ref()))
    );
    assert!(!extracted.subject.is_empty());
    assert!(!extracted.valid_until.is_empty());
}
