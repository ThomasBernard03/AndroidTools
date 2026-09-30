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
