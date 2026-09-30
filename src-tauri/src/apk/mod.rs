mod models;
mod permissions;
mod signatures;

pub use models::{ApkError, ApkReport};

use apk_info::{Apk, ZipEntry};
use std::{fs::File, path::Path};

pub fn analyze(path: &Path) -> Result<ApkReport, ApkError> {
    if !path
        .extension()
        .is_some_and(|ext| ext.eq_ignore_ascii_case("apk"))
    {
        return Err(ApkError::new(
            "extension",
            "Sélectionnez un fichier .apk.",
            "Unsupported file extension",
        ));
    }
    let file = File::open(path).map_err(|error| {
        ApkError::new(
            "file",
            "Impossible d’ouvrir ce fichier APK.",
            error.to_string(),
        )
    })?;
    let metadata = file.metadata().map_err(|error| {
        ApkError::new(
            "file",
            "Impossible de lire ce fichier APK.",
            error.to_string(),
        )
    })?;
    if !metadata.is_file() || metadata.len() == 0 {
        return Err(ApkError::new(
            "file",
            "Le fichier APK est vide ou n’est pas un fichier régulier.",
            "Empty or non-regular file",
        ));
    }
    let zip = ZipEntry::from_reader(file).map_err(|error| {
        ApkError::new(
            "archive",
            "Ce fichier n’est pas une archive APK lisible.",
            error.to_string(),
        )
    })?;
    if zip.entry_info("AndroidManifest.xml").is_none() {
        return Err(ApkError::new(
            "manifest",
            "L’archive ne contient pas de manifeste Android lisible.",
            "AndroidManifest.xml not found",
        ));
    }
    // Only metadata entries are decompressed. Avoid allocating excessively large resource tables.
    for name in zip.namelist().filter(|name| {
        matches!(*name, "AndroidManifest.xml" | "resources.arsc") || name.starts_with("META-INF/")
    }) {
        if zip.entry_info(name).is_some_and(|entry| {
            entry.uncompressed_size > 64 * 1024 * 1024 || entry.compressed_size > 64 * 1024 * 1024
        }) {
            return Err(ApkError::new(
                "size",
                "Un élément de métadonnées de cet APK dépasse la limite de 64 Mio.",
                name,
            ));
        }
    }
    let apk = Apk::new(path).map_err(|error| {
        ApkError::new(
            "manifest",
            "Impossible de décoder le manifeste de cet APK.",
            error.to_string(),
        )
    })?;
    let manifest = apk.get_xml_string();
    let permissions = permissions::parse(&manifest)?;
    let (signatures, signature_warnings) = signatures::read(&zip);

    Ok(ApkReport {
        file_name: path
            .file_name()
            .map(|name| name.to_string_lossy().into_owned())
            .unwrap_or_default(),
        file_size: metadata.len(),
        package_name: apk.get_package_name(),
        app_label: apk.get_application_label(),
        version_name: apk.get_version_name(),
        version_code: apk.get_version_code(),
        min_sdk: apk.get_min_sdk_version(),
        target_sdk: apk.get_attribute_value("uses-sdk", "targetSdkVersion"),
        manifest,
        permissions,
        signatures,
        signature_warnings,
    })
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests;
