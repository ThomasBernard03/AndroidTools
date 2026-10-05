use super::domain::*;
use apk_info::{Apk, Signature};
use openssl::hash::{Hasher, MessageDigest};
use std::{
    fs::File,
    io::{Read, Write},
    path::Path,
};

/// Bounds interactive analysis, including decompressed metadata and IPC output.
const MAX_APK: u64 = 1024 * 1024 * 1024;
const MAX_METADATA: u64 = 64 * 1024 * 1024;
const MAX_FILES: usize = 100_000;

pub struct NativeApkInspector;

fn invalid() -> ApkError {
    ApkError::new(
        "invalid_apk",
        "This file is not a readable APK, or its Android manifest is invalid.",
    )
}
fn io_error() -> ApkError {
    ApkError::new(
        "read_failed",
        "The APK could not be read. Check that the file exists and is accessible.",
    )
}
fn limit() -> ApkError {
    ApkError::new(
        "limit_exceeded",
        "This APK exceeds the analysis limits (1 GiB file, 64 MiB metadata, 100,000 entries).",
    )
}
fn section(title: &str, values: Vec<(&str, Option<String>)>) -> Section {
    Section {
        title: title.into(),
        items: values
            .into_iter()
            .map(|(label, value)| InfoItem {
                label: label.into(),
                value,
            })
            .collect(),
    }
}
fn list<'a>(title: &str, values: impl Iterator<Item = &'a str>) -> Section {
    section(
        title,
        values.map(|v| (v, Some("Declared".into()))).collect(),
    )
}
fn components<T: serde::Serialize>(title: &str, values: impl Iterator<Item = T>) -> Section {
    Section {
        title: title.into(),
        items: values
            .enumerate()
            .map(|(index, value)| {
                let object = serde_json::to_value(value).unwrap_or_default();
                let label = object
                    .get("name")
                    .and_then(|v| v.as_str())
                    .map(str::to_owned)
                    .unwrap_or_else(|| format!("Unnamed component {}", index + 1));
                let details = object
                    .as_object()
                    .map(|fields| {
                        fields
                            .iter()
                            .filter(|(key, value)| *key != "name" && !value.is_null())
                            .map(|(key, value)| {
                                format!(
                                    "{}: {}",
                                    key.replace('_', " "),
                                    value
                                        .as_str()
                                        .map(str::to_owned)
                                        .unwrap_or_else(|| value.to_string())
                                )
                            })
                            .collect::<Vec<_>>()
                            .join("\n")
                    })
                    .unwrap_or_default();
                InfoItem {
                    label,
                    value: Some(if details.is_empty() {
                        "No additional attributes declared".into()
                    } else {
                        details
                    }),
                }
            })
            .collect(),
    }
}

impl ApkInspector for NativeApkInspector {
    fn inspect(&self, path: &Path) -> Result<ApkReport, ApkError> {
        let source = File::open(path).map_err(|_| io_error())?;
        let metadata = source.metadata().map_err(|_| io_error())?;
        if !metadata.is_file() {
            return Err(io_error());
        }
        if metadata.len() > MAX_APK {
            return Err(limit());
        }
        // Parse and hash the same bounded snapshot even if the original file changes.
        let mut source = source.take(MAX_APK + 1);
        let mut snapshot = tempfile::NamedTempFile::new().map_err(|_| io_error())?;
        let mut hasher = Hasher::new(MessageDigest::sha256()).map_err(|_| io_error())?;
        let mut buffer = [0u8; 65536];
        let mut size = 0;
        loop {
            let count = source.read(&mut buffer).map_err(|_| io_error())?;
            if count == 0 {
                break;
            }
            size += count as u64;
            if size > MAX_APK {
                return Err(limit());
            }
            hasher.update(&buffer[..count]).map_err(|_| io_error())?;
            snapshot
                .write_all(&buffer[..count])
                .map_err(|_| io_error())?;
        }
        snapshot.flush().map_err(|_| io_error())?;
        let sha256 = hasher
            .finish()
            .map_err(|_| io_error())?
            .iter()
            .map(|b| format!("{b:02X}"))
            .collect();
        let mut zip = zip::ZipArchive::new(File::open(snapshot.path()).map_err(|_| io_error())?)
            .map_err(|_| invalid())?;
        if zip.len() > MAX_FILES {
            return Err(limit());
        }
        let mut files = Vec::with_capacity(zip.len());
        let mut metadata_size = 0u64;
        for i in 0..zip.len() {
            let entry = zip.by_index(i).map_err(|_| invalid())?;
            if entry.name() == "AndroidManifest.xml"
                || entry.name() == "resources.arsc"
                || entry.name().starts_with("META-INF/")
            {
                metadata_size = metadata_size.saturating_add(entry.size());
                if metadata_size > MAX_METADATA {
                    return Err(limit());
                }
            }
            files.push(ArchiveFile {
                name: entry.name().into(),
                size: entry.size(),
                compressed_size: entry.compressed_size(),
            });
        }
        if !files.iter().any(|f| f.name == "AndroidManifest.xml") {
            return Err(invalid());
        }
        files.sort_by(|a, b| a.name.cmp(&b.name));
        let apk = Apk::new(snapshot.path()).map_err(|_| invalid())?;
        let icon_data_url = super::icons::preview(&apk, &mut zip);
        let has_v1 = files.iter().any(|file| {
            let name = file.name.to_ascii_uppercase();
            name.starts_with("META-INF/")
                && [".RSA", ".DSA", ".EC", ".SF"]
                    .iter()
                    .any(|ext| name.ends_with(ext))
        });
        let signature = super::verification::inspect(snapshot.path(), has_v1);
        let package = apk
            .get_package_name()
            .filter(|p| !p.is_empty())
            .ok_or_else(invalid)?;
        let mut sections = vec![
            section(
                "Application",
                vec![
                    ("Package name", Some(package)),
                    ("Application label", apk.get_application_label()),
                    ("Version name", apk.get_version_name()),
                    ("Version code", apk.get_version_code()),
                    (
                        "Version code major",
                        apk.get_attribute_value("manifest", "versionCodeMajor"),
                    ),
                    ("Application class", apk.get_application_name()),
                    (
                        "Launcher activity",
                        apk.get_main_activity().map(str::to_owned),
                    ),
                    ("Icon resource", apk.get_application_icon()),
                    ("Install location", apk.get_install_location()),
                    ("Split name", apk.get_attribute_value("manifest", "split")),
                ],
            ),
            section(
                "Android compatibility",
                vec![
                    ("Minimum SDK", apk.get_min_sdk_version()),
                    (
                        "Target SDK (declared)",
                        apk.get_attribute_value("uses-sdk", "targetSdkVersion"),
                    ),
                    ("Maximum SDK", apk.get_max_sdk_version()),
                    ("Compile SDK", apk.get_compile_sdk_version()),
                    ("Native ABIs", Some(apk.get_supported_abis().join(", "))),
                    ("Multidex", Some(apk.is_multidex().to_string())),
                ],
            ),
            section(
                "Application flags (declared)",
                vec![
                    ("Debuggable", apk.get_application_debuggable()),
                    ("Allow backup", apk.get_application_allow_backup()),
                    (
                        "Uses cleartext traffic",
                        apk.get_attribute_value("application", "usesCleartextTraffic"),
                    ),
                    (
                        "Network security config",
                        apk.get_attribute_value("application", "networkSecurityConfig"),
                    ),
                    (
                        "Test only",
                        apk.get_attribute_value("application", "testOnly"),
                    ),
                    (
                        "Extract native libraries",
                        apk.get_attribute_value("application", "extractNativeLibs"),
                    ),
                ],
            ),
            list("Permissions", apk.get_permissions()),
            list("Permissions (SDK 23+)", apk.get_permissions_sdk23()),
            list("Declared features", apk.get_features()),
            list("Shared libraries", apk.get_libraries()),
            list("Native libraries", apk.get_native_libraries()),
            components("Declared permissions", apk.get_declared_permissions()),
            components("Activities", apk.get_activities()),
            components("Activity aliases", apk.get_activity_aliases()),
            components("Services", apk.get_services()),
            components("Receivers", apk.get_receivers()),
            components("Providers", apk.get_providers()),
        ];
        let mut warnings = Vec::new();
        match apk.get_signatures() {
            Ok(signatures) => {
                let mut count = 0;
                for signature in signatures {
                    let name = signature.name();
                    let certificates = match signature {
                        Signature::V1(c) | Signature::V2(c) | Signature::V3(c) | Signature::V31(c) => c,
                        Signature::StampBlockV1(c) | Signature::StampBlockV2(c) => vec![c],
                        _ => continue,
                    };
                    for (index, c) in certificates.into_iter().enumerate() {
                        count += 1;
                        sections.push(section(&format!("Certificate · {name} · {}", index + 1), vec![
                            ("Subject", Some(c.subject)), ("Issuer", Some(c.issuer)), ("Serial number", Some(c.serial_number)),
                            ("Valid from", Some(c.valid_from)), ("Valid until", Some(c.valid_until)),
                            ("Signature algorithm", Some(c.signature_type)), ("SHA-1", Some(c.sha1_fingerprint)), ("SHA-256", Some(c.sha256_fingerprint)),
                        ]));
                    }
                }
                if count == 0 { warnings.push("No signing certificates could be extracted.".into()); }
            }
            Err(_) => warnings.push("Signing certificates could not be parsed; other APK information is still available.".into()),
        }
        let manifest = apk.get_xml_string();
        if manifest.len() as u64 > MAX_METADATA {
            return Err(limit());
        }
        Ok(ApkReport {
            path: path.to_string_lossy().into_owned(),
            size,
            icon_data_url,
            signature,
            sha256,
            sections,
            files,
            manifest,
            warnings,
        })
    }
}
