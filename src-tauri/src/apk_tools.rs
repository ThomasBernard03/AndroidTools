use std::{
    fs,
    io::{Read, Write},
    path::Path,
};

use apksig::{Algorithms, Apk, ValueSigningBlock};
use p12_keystore::{Certificate, KeyStore, KeyStoreEntry, PrivateKeyChain};
use rcgen::{CertificateParams, DistinguishedName, DnType, KeyPair};
use rsa::{
    RsaPrivateKey,
    pkcs8::{DecodePrivateKey, EncodePrivateKey, EncodePublicKey},
    rand_core::OsRng,
};
use serde::Deserialize;
use zip::{CompressionMethod, ZipArchive, ZipWriter, write::SimpleFileOptions};

use crate::apk::ApkError;

type Result<T> = std::result::Result<T, ApkError>;
const MAX_APK_SIZE: u64 = 2 * 1024 * 1024 * 1024;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct KeystoreRequest {
    pub output_path: String,
    pub alias: String,
    pub password: String,
    pub common_name: String,
    pub organization: String,
    pub country: String,
    pub validity_days: u32,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SignRequest {
    pub apk_path: String,
    pub keystore_path: String,
    pub output_path: String,
    pub alias: String,
    pub store_password: String,
    pub key_password: String,
}

fn error(message: &'static str, details: impl ToString) -> ApkError {
    ApkError::new("apk_tools", message, details.to_string())
}

fn validate_output(output: &str) -> Result<&Path> {
    let path = Path::new(output);
    if !path.is_absolute() || path.file_name().is_none() || path.symlink_metadata().is_ok() {
        return Err(error(
            "Choisissez un nouveau fichier de sortie (chemin absolu). Aucun fichier existant n’est remplacé.",
            output,
        ));
    }
    Ok(path)
}

fn validate_alias(alias: &str) -> Result<()> {
    if alias.trim().is_empty() || alias.len() > 256 || alias.contains(['\0', '\n', '\r']) {
        return Err(error(
            "Renseignez un alias de clé valide (256 octets maximum).",
            "Alias vide ou invalide",
        ));
    }
    Ok(())
}

fn publish(mut source: impl Read, destination: &Path) -> Result<String> {
    let parent = destination
        .parent()
        .ok_or_else(|| error("Dossier de sortie invalide.", "Missing parent"))?;
    let mut file = tempfile::NamedTempFile::new_in(parent)
        .map_err(|e| error("Impossible de créer le fichier de sortie.", e))?;
    std::io::copy(&mut source, &mut file)
        .map_err(|e| error("Impossible d’écrire le résultat.", e))?;
    file.as_file()
        .sync_all()
        .map_err(|e| error("Impossible d’enregistrer le résultat.", e))?;
    file.persist_noclobber(destination).map_err(|e| {
        error(
            "Impossible d’enregistrer le résultat. Le fichier existe peut-être déjà.",
            e.error,
        )
    })?;
    Ok(destination.to_string_lossy().into_owned())
}

pub fn generate_keystore(request: KeystoreRequest) -> Result<String> {
    let output = validate_output(&request.output_path)?;
    let information_path = format!("{}.json", request.output_path);
    let information_output = validate_output(&information_path)?;
    validate_alias(&request.alias)?;
    if request.password.chars().count() < 6 || request.password.contains('\0') {
        return Err(error(
            "Le mot de passe doit contenir au moins 6 caractères.",
            "Mot de passe invalide",
        ));
    }
    if !(1..=36500).contains(&request.validity_days) || request.common_name.trim().is_empty() {
        return Err(error(
            "Renseignez le nom du certificat et une validité de 1 à 36 500 jours.",
            "Certificat invalide",
        ));
    }
    if !request.country.is_empty()
        && (request.country.len() != 2 || !request.country.bytes().all(|b| b.is_ascii_alphabetic()))
    {
        return Err(error(
            "Le code pays doit contenir deux lettres.",
            "Exemple : FR",
        ));
    }
    let key = RsaPrivateKey::new(&mut OsRng, 3072)
        .map_err(|e| error("Impossible de générer la clé RSA.", e))?;
    let der = key
        .to_pkcs8_der()
        .map_err(|e| error("Impossible d’encoder la clé.", e))?;
    let pair = KeyPair::try_from(der.as_bytes())
        .map_err(|e| error("Impossible de créer le certificat.", e))?;
    let now = time::OffsetDateTime::now_utc();
    let mut params = CertificateParams::default();
    params.not_before = now - time::Duration::minutes(5);
    let expires_at = now + time::Duration::days(i64::from(request.validity_days));
    params.not_after = expires_at;
    params.distinguished_name = DistinguishedName::new();
    params
        .distinguished_name
        .push(DnType::CommonName, request.common_name.trim());
    if !request.organization.trim().is_empty() {
        params
            .distinguished_name
            .push(DnType::OrganizationName, request.organization.trim());
    }
    if !request.country.is_empty() {
        params
            .distinguished_name
            .push(DnType::CountryName, request.country.to_ascii_uppercase());
    }
    let certificate = params
        .self_signed(&pair)
        .map_err(|e| error("Impossible de signer le certificat.", e))?;
    let certificate =
        Certificate::from_der(certificate.der()).map_err(|e| error("Certificat invalide.", e))?;
    let chain = PrivateKeyChain::new(der.as_bytes(), request.alias.as_bytes(), [certificate]);
    let mut store = KeyStore::new();
    store.add_entry(&request.alias, KeyStoreEntry::PrivateKeyChain(chain));
    let bytes = store
        .writer(&request.password)
        .write()
        .map_err(|e| error("Impossible de chiffrer le keystore.", e))?;
    let information = serde_json::to_vec_pretty(&serde_json::json!({
        "format": "PKCS#12",
        "keyAlgorithm": "RSA",
        "keySize": 3072,
        "keystoreFile": output.file_name()
            .ok_or_else(|| error("Nom du keystore invalide.", "Missing file name"))?
            .to_string_lossy(),
        "alias": request.alias,
        "storePassword": request.password,
        "keyPassword": request.password,
        "commonName": request.common_name.trim(),
        "organization": request.organization.trim(),
        "country": request.country.to_ascii_uppercase(),
        "validityDays": request.validity_days,
        "createdAtUtc": now.to_string(),
        "expiresAtUtc": expires_at.to_string(),
    }))
    .map_err(|e| error("Impossible de préparer les informations du keystore.", e))?;
    let path = publish(bytes.as_slice(), output)?;
    if let Err(cause) = publish(information.as_slice(), information_output) {
        fs::remove_file(output).map_err(|e| {
            error(
                "Le fichier d’informations n’a pas pu être enregistré et le keystore n’a pas pu être supprimé.",
                format!("Keystore : {path}. {e}"),
            )
        })?;
        return Err(cause);
    }
    Ok(path)
}

fn signing_key(request: &SignRequest) -> Result<(RsaPrivateKey, Vec<u8>)> {
    let file =
        fs::File::open(&request.keystore_path).map_err(|e| error("Keystore introuvable.", e))?;
    let mut bytes = Vec::new();
    file.take(16 * 1024 * 1024 + 1)
        .read_to_end(&mut bytes)
        .map_err(|e| error("Impossible de lire le keystore.", e))?;
    if bytes.len() > 16 * 1024 * 1024 {
        return Err(error(
            "Le keystore dépasse la limite de 16 Mio.",
            "Keystore trop volumineux",
        ));
    }
    let (private, cert) = if bytes.starts_with(&[0xfe, 0xed, 0xfe, 0xed]) {
        let password = if request.key_password.is_empty() {
            &request.store_password
        } else {
            &request.key_password
        };
        if !password.is_ascii() || !request.store_password.is_ascii() {
            return Err(error(
                "Les mots de passe JKS non ASCII ne sont pas pris en charge.",
                "Utilisez un keystore PKCS#12 pour les mots de passe Unicode.",
            ));
        }
        let mut store = jks::KeyStore::new();
        store
            .load(bytes.as_slice(), request.store_password.as_bytes())
            .map_err(|e| error("Keystore JKS illisible ou mot de passe incorrect.", e))?;
        let entry = store
            .get_private_key_entry(&request.alias, password.as_bytes())
            .map_err(|e| error("Alias introuvable ou mot de passe de clé incorrect.", e))?;
        let cert = entry
            .certificate_chain
            .first()
            .ok_or_else(|| {
                error(
                    "Le keystore ne contient pas de certificat pour cette clé.",
                    &request.alias,
                )
            })?
            .content
            .clone();
        (entry.private_key, cert)
    } else {
        if !request.key_password.is_empty() && request.key_password != request.store_password {
            return Err(error(
                "PKCS#12 : utilisez le même mot de passe pour la clé et le keystore.",
                "Les mots de passe distincts sont pris en charge pour JKS uniquement.",
            ));
        }
        let store = KeyStore::from_pkcs12(&bytes, &request.store_password)
            .map_err(|e| error("Keystore PKCS#12 illisible ou mot de passe incorrect.", e))?;
        let entry = store.entry(&request.alias).or_else(|| {
            store
                .entries()
                .find(|(alias, _)| alias.eq_ignore_ascii_case(&request.alias))
                .map(|(_, entry)| entry)
        });
        let Some(KeyStoreEntry::PrivateKeyChain(chain)) = entry else {
            return Err(error("Aucune clé privée pour cet alias.", &request.alias));
        };
        let cert = chain
            .chain()
            .first()
            .ok_or_else(|| error("Certificat absent.", &request.alias))?;
        (chain.key().to_vec(), cert.as_der().to_vec())
    };
    let key = RsaPrivateKey::from_pkcs8_der(&private)
        .map_err(|e| error("Seules les clés de signature RSA sont prises en charge.", e))?;
    let (_, certificate) = x509_parser::parse_x509_certificate(&cert)
        .map_err(|e| error("Certificat X.509 invalide.", e))?;
    let public = key
        .to_public_key()
        .to_public_key_der()
        .map_err(|e| error("Clé publique invalide.", e))?;
    if public.as_bytes() != certificate.public_key().raw {
        return Err(error(
            "Le certificat ne correspond pas à la clé privée.",
            &request.alias,
        ));
    }
    Ok((key, cert))
}

fn signature_entry(name: &str) -> bool {
    let name = name.to_ascii_uppercase();
    if name == "STAMP-CERT-SHA256" {
        return true;
    }
    let Some(leaf) = name.strip_prefix("META-INF/") else {
        return false;
    };
    !leaf.contains('/')
        && (leaf == "MANIFEST.MF"
            || leaf.starts_with("SIG-")
            || [".SF", ".RSA", ".DSA", ".EC"]
                .iter()
                .any(|ext| leaf.ends_with(ext)))
}

fn align_apk(source: &Path, destination: &Path) -> Result<()> {
    let file = fs::File::open(source).map_err(|e| error("APK source introuvable.", e))?;
    let metadata = file.metadata().map_err(|e| error("APK illisible.", e))?;
    if !metadata.is_file() || metadata.len() > MAX_APK_SIZE {
        return Err(error(
            "Sélectionnez un APK de moins de 2 Gio.",
            "Fichier invalide ou trop volumineux",
        ));
    }
    let mut archive = ZipArchive::new(file).map_err(|e| error("Archive APK invalide.", e))?;
    if archive.index_for_name("AndroidManifest.xml").is_none() {
        return Err(error(
            "L’APK ne contient pas de manifeste Android.",
            "AndroidManifest.xml absent",
        ));
    }
    let file =
        fs::File::create(destination).map_err(|e| error("Impossible de préparer l’APK.", e))?;
    let mut writer = ZipWriter::new(file);
    let mut estimated_size = 0u64;
    for index in 0..archive.len() {
        let mut entry = archive
            .by_index(index)
            .map_err(|e| error("Entrée ZIP invalide.", e))?;
        if signature_entry(entry.name()) {
            continue;
        }
        // Bound the rewritten archive even when multiple entries share the same source data.
        estimated_size = estimated_size
            .saturating_add(entry.compressed_size())
            .saturating_add(65536);
        if estimated_size > MAX_APK_SIZE {
            return Err(error(
                "L’APK aligné dépasserait la limite de 2 Gio.",
                "Archive trop volumineuse",
            ));
        }
        match entry.compression() {
            CompressionMethod::Stored => {
                if entry.size() > MAX_APK_SIZE {
                    return Err(error("Une entrée APK dépasse 2 Gio.", entry.name()));
                }
                let alignment = if entry.name().ends_with(".so") {
                    16384
                } else {
                    4
                };
                let options = SimpleFileOptions::default()
                    .compression_method(CompressionMethod::Stored)
                    .with_alignment(alignment)
                    .unix_permissions(entry.unix_mode().unwrap_or(0o644))
                    .last_modified_time(entry.last_modified().unwrap_or_default());
                writer
                    .start_file(entry.name(), options)
                    .map_err(|e| error("Impossible d’aligner l’APK.", e))?;
                std::io::copy(&mut entry, &mut writer)
                    .map_err(|e| error("Impossible de copier une entrée APK.", e))?;
            }
            CompressionMethod::Deflated => writer
                .raw_copy_file(entry)
                .map_err(|e| error("Impossible de copier une entrée APK.", e))?,
            _ => {
                return Err(error(
                    "Méthode de compression APK non prise en charge.",
                    entry.name(),
                ));
            }
        }
    }
    let file = writer
        .finish()
        .map_err(|e| error("Impossible de finaliser l’alignement.", e))?;
    if file
        .metadata()
        .map_err(|e| error("APK illisible.", e))?
        .len()
        > MAX_APK_SIZE
    {
        return Err(error(
            "L’APK aligné dépasse 2 Gio.",
            "Fichier trop volumineux",
        ));
    }
    Ok(())
}

// apksig verifies the signed data, but callers must also compare the actual APK digest.
pub(crate) fn verify_generated_apk(path: &Path, expected_certificate: &[u8]) -> Result<()> {
    let apk =
        Apk::new(path.to_path_buf()).map_err(|e| error("Impossible de relire l’APK signé.", e))?;
    apk.verify()
        .map_err(|e| error("La vérification de la signature a échoué.", e))?;
    let block = apk
        .get_signing_block()
        .map_err(|e| error("Bloc de signature absent.", e))?;
    let v2 = block
        .content
        .iter()
        .find_map(|block| match block {
            ValueSigningBlock::SignatureSchemeV2Block(v2) => Some(v2),
            _ => None,
        })
        .ok_or_else(|| error("Signature v2 absente.", "Missing v2 block"))?;
    let algorithm = Algorithms::RSASSA_PKCS1_v1_5_256;
    let digest = apk
        .digest(&algorithm)
        .map_err(|e| error("Impossible de vérifier l’intégrité de l’APK.", e))?;
    if v2.signers.signers_data.len() != 1 {
        return Err(error(
            "Nombre de signataires inattendu.",
            "Expected one signer",
        ));
    }
    let signer = &v2.signers.signers_data[0];
    let valid_digest = signer
        .signed_data
        .digests
        .digests_data
        .iter()
        .any(|entry| entry.signature_algorithm_id == algorithm && entry.digest == digest);
    let valid_certificate = signer
        .signed_data
        .certificates
        .certificates_data
        .first()
        .is_some_and(|cert| cert.certificate == expected_certificate);
    let (_, certificate) = x509_parser::parse_x509_certificate(expected_certificate)
        .map_err(|e| error("Certificat X.509 invalide.", e))?;
    if !valid_digest || !valid_certificate || signer.pub_key.data != certificate.public_key().raw {
        return Err(error(
            "L’intégrité de l’APK signé ou son certificat ne correspond pas.",
            "Digest or certificate mismatch",
        ));
    }
    Ok(())
}

pub fn sign_apk(request: SignRequest) -> Result<String> {
    let output = validate_output(&request.output_path)?;
    validate_alias(&request.alias)?;
    let (key, certificate) = signing_key(&request)?;
    let workspace =
        tempfile::tempdir().map_err(|e| error("Impossible de créer le dossier temporaire.", e))?;
    let aligned = workspace.path().join("aligned.apk");
    let signed = workspace.path().join("signed.apk");
    align_apk(Path::new(&request.apk_path), &aligned)?;
    let mut apk = Apk::new_raw(aligned).map_err(|e| error("APK aligné illisible.", e))?;
    apk.sign_v2(&Algorithms::RSASSA_PKCS1_v1_5_256, &certificate, key)
        .map_err(|e| error("Impossible de signer l’APK.", e))?;
    let mut file =
        fs::File::create(&signed).map_err(|e| error("Impossible de créer l’APK signé.", e))?;
    apk.write_with_signature(&mut file)
        .map_err(|e| error("Impossible d’écrire la signature.", e))?;
    file.flush()
        .map_err(|e| error("Impossible d’enregistrer la signature.", e))?;
    drop(file);
    verify_generated_apk(&signed, &certificate)?;
    publish(
        fs::File::open(&signed).map_err(|e| error("APK signé illisible.", e))?,
        output,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn publication_never_overwrites_existing_files() {
        let dir = tempfile::tempdir().expect("directory");
        let output = dir.path().join("output");
        fs::write(&output, "original").expect("output");
        assert!(publish("new".as_bytes(), &output).is_err());
        assert_eq!(fs::read_to_string(&output).expect("read"), "original");
        assert!(validate_output(output.to_str().expect("path")).is_err());
    }

    #[test]
    fn publication_preserves_content_and_restricts_permissions() {
        let dir = tempfile::tempdir().expect("directory");
        let output = dir.path().join("output");
        publish("private key".as_bytes(), &output).expect("publish");
        assert_eq!(fs::read_to_string(&output).expect("read"), "private key");
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            assert_eq!(
                fs::metadata(output).expect("metadata").permissions().mode() & 0o777,
                0o600
            );
        }
    }
}
