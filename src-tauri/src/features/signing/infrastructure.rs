use super::domain::*;
use apksig::{Algorithms, Apk};
use openssl::{
    pkcs12::Pkcs12,
    pkey::{PKey, Private},
    x509::X509,
};
use rsa::pkcs8::DecodePrivateKey;
use std::{
    collections::HashSet,
    fs::File,
    io::{self, Read, Write},
    path::Path,
};
use tempfile::NamedTempFile;
use zeroize::Zeroizing;
use zip::{CompressionMethod, ZipArchive, ZipWriter, write::SimpleFileOptions};

pub struct NativeSigner;
pub struct NativeArtifact(NamedTempFile);

fn apk_error() -> SigningError {
    SigningError::new(
        ErrorCode::InvalidApk,
        "Could not read the APK. Use a valid APK up to 1 GiB (2 GiB unpacked).",
    )
}
fn key_error() -> SigningError {
    SigningError::new(
        ErrorCode::InvalidKeystore,
        "Could not unlock the signing key. Check the JKS or PKCS12 file, alias and passwords. PKCS12 requires one RSA key and matching passwords.",
    )
}
fn signing_error() -> SigningError {
    SigningError::new(
        ErrorCode::SigningFailed,
        "Could not sign and verify the APK with this RSA key.",
    )
}
fn write_error() -> SigningError {
    SigningError::new(
        ErrorCode::WriteFailed,
        "Could not save the signed APK. Choose a writable folder and a filename that does not already exist.",
    )
}

fn load_key(request: &SignRequest) -> Result<(PKey<Private>, X509), SigningError> {
    let file = File::open(&request.keystore_path).map_err(|_| key_error())?;
    if !file.metadata().map_err(|_| key_error())?.is_file() {
        return Err(key_error());
    }
    let mut bytes = Zeroizing::new(Vec::new());
    file.take(16 * 1024 * 1024 + 1)
        .read_to_end(&mut bytes)
        .map_err(|_| key_error())?;
    if bytes.len() > 16 * 1024 * 1024 {
        return Err(key_error());
    }
    let key_password = if request.key_password.is_empty() {
        &request.password
    } else {
        &request.key_password
    };
    let (key, cert) = if bytes.starts_with(&[0xfe, 0xed, 0xfe, 0xed]) {
        let mut store = jks::KeyStore::new();
        store
            .load(bytes.as_slice(), request.password.as_bytes())
            .map_err(|_| key_error())?;
        let mut entry = store
            .get_private_key_entry(&request.alias, key_password.as_bytes())
            .map_err(|_| key_error())?;
        let private_key = Zeroizing::new(std::mem::take(&mut entry.private_key));
        let cert = entry.certificate_chain.first().ok_or_else(key_error)?;
        (
            PKey::private_key_from_pkcs8(&private_key).map_err(|_| key_error())?,
            X509::from_der(&cert.content).map_err(|_| key_error())?,
        )
    } else {
        if key_password != &request.password {
            return Err(key_error());
        }
        let parsed = Pkcs12::from_der(&bytes)
            .and_then(|p| p.parse2(&request.password))
            .map_err(|_| key_error())?;
        let cert = parsed.cert.ok_or_else(key_error)?;
        if cert.alias() != Some(request.alias.as_bytes()) {
            return Err(key_error());
        }
        (parsed.pkey.ok_or_else(key_error)?, cert)
    };
    let public = cert.public_key().map_err(|_| key_error())?;
    if key.rsa().is_err() || !key.public_eq(&public) {
        return Err(key_error());
    }
    Ok((key, cert))
}

fn old_signature(name: &str) -> bool {
    let upper = name.to_ascii_uppercase();
    let Some(name) = upper.strip_prefix("META-INF/") else {
        return false;
    };
    !name.contains('/')
        && (name == "MANIFEST.MF"
            || name.starts_with("SIG-")
            || [".SF", ".RSA", ".DSA", ".EC"]
                .iter()
                .any(|ext| name.ends_with(ext)))
}

/// Rebuilds ZIP entries to discard previous signing blocks and v1 signatures.
/// Stored native libraries are 16 KiB aligned; other stored entries are 4-byte aligned.
fn prepare_apk(path: &str) -> Result<NamedTempFile, SigningError> {
    let input = File::open(path).map_err(|_| apk_error())?;
    let metadata = input.metadata().map_err(|_| apk_error())?;
    if !metadata.is_file() || metadata.len() > 1024 * 1024 * 1024 {
        return Err(apk_error());
    }
    // Snapshot before parsing to avoid reading different revisions during signing.
    let mut snapshot = NamedTempFile::new().map_err(|_| write_error())?;
    let copied = io::copy(&mut input.take(1024 * 1024 * 1024 + 1), &mut snapshot)
        .map_err(|_| apk_error())?;
    if copied > 1024 * 1024 * 1024 {
        return Err(apk_error());
    }
    let mut archive =
        ZipArchive::new(snapshot.reopen().map_err(|_| apk_error())?).map_err(|_| apk_error())?;
    if archive.len() > 100_000 || archive.by_name("AndroidManifest.xml").is_err() {
        return Err(apk_error());
    }
    let mut output = NamedTempFile::new().map_err(|_| write_error())?;
    let mut writer = ZipWriter::new(output.as_file_mut());
    let mut total = 0_u64;
    let mut names = HashSet::new();
    for index in 0..archive.len() {
        let mut entry = archive.by_index(index).map_err(|_| apk_error())?;
        if !names.insert(entry.name().to_owned()) || entry.encrypted() {
            return Err(apk_error());
        }
        if old_signature(entry.name()) {
            continue;
        }
        if !matches!(
            entry.compression(),
            CompressionMethod::Stored | CompressionMethod::Deflated
        ) {
            return Err(apk_error());
        }
        let limit = 2 * 1024 * 1024 * 1024_u64 - total;
        if entry.size() > limit {
            return Err(apk_error());
        }
        let alignment = if entry.compression() == CompressionMethod::Stored {
            if entry.name().starts_with("lib/") && entry.name().ends_with(".so") {
                16384
            } else {
                4
            }
        } else {
            1
        };
        let options = SimpleFileOptions::default()
            .compression_method(entry.compression())
            .with_alignment(alignment);
        writer
            .start_file(entry.name(), options)
            .map_err(|_| apk_error())?;
        let expected = entry.size();
        let copied =
            io::copy(&mut entry.by_ref().take(limit + 1), &mut writer).map_err(|_| apk_error())?;
        if copied != expected || copied > limit {
            return Err(apk_error());
        }
        total += copied;
    }
    writer.finish().map_err(|_| apk_error())?;
    Ok(output)
}

impl ApkSigner for NativeSigner {
    type Artifact = NativeArtifact;
    fn sign(&self, request: &SignRequest) -> Result<NativeArtifact, SigningError> {
        let (key, cert) = load_key(request)?;
        let unsigned = prepare_apk(&request.apk_path)?;
        let der = Zeroizing::new(key.private_key_to_pkcs8().map_err(|_| signing_error())?);
        let private = rsa::RsaPrivateKey::from_pkcs8_der(&der).map_err(|_| key_error())?;
        let mut apk = Apk::new_raw(unsigned.path().to_owned()).map_err(|_| apk_error())?;
        let algorithm = Algorithms::RSASSA_PKCS1_v1_5_256;
        let expected_digest = apk.digest(&algorithm).map_err(|_| signing_error())?;
        apk.sign_v2(
            &algorithm,
            &cert.to_der().map_err(|_| key_error())?,
            private,
        )
        .map_err(|_| signing_error())?;
        let mut signed = NamedTempFile::new().map_err(|_| write_error())?;
        apk.write_with_signature(&mut signed)
            .map_err(|_| signing_error())?;
        signed.flush().map_err(|_| write_error())?;
        let result = Apk::new(signed.path().to_owned()).map_err(|_| signing_error())?;
        result.verify().map_err(|_| signing_error())?;
        if result.digest(&algorithm).map_err(|_| signing_error())? != expected_digest {
            return Err(signing_error());
        }
        Ok(NativeArtifact(signed))
    }
}

impl SignedArtifact for NativeArtifact {
    fn save(self, destination: &str) -> Result<(), SigningError> {
        let parent = Path::new(destination).parent().ok_or_else(write_error)?;
        let mut output = NamedTempFile::new_in(parent).map_err(|_| write_error())?;
        io::copy(
            &mut self.0.reopen().map_err(|_| write_error())?,
            &mut output,
        )
        .map_err(|_| write_error())?;
        output.as_file().sync_all().map_err(|_| write_error())?;
        // Atomic no-clobber publication also protects the source APK and keystore.
        output
            .persist_noclobber(destination)
            .map_err(|_| write_error())?;
        Ok(())
    }
}
