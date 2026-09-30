use super::models::SignatureInfo;
use apk_info::{Signature, ZipEntry};

pub fn read(zip: &ZipEntry) -> (Vec<SignatureInfo>, Vec<String>) {
    let mut signatures = Vec::new();
    let mut warnings = Vec::new();
    let v1_blocks = zip
        .namelist()
        .filter(|name| {
            name.starts_with("META-INF/")
                && [".RSA", ".DSA", ".EC"]
                    .iter()
                    .any(|extension| name.ends_with(extension))
        })
        .count();
    if v1_blocks > 1 {
        warnings.push("Plusieurs blocs v1 sont présents. La bibliothèque ne décode que les certificats du premier bloc v1.".to_owned());
    }
    // Read v1 separately: Apk::get_signatures silently discards v1 parsing errors.
    match zip.get_signature_v1() {
        Ok(signature) => append(signature, &mut signatures),
        Err(error) => warnings.push(format!("Certificats v1 illisibles : {error}")),
    }
    match zip.get_signatures_other() {
        Ok(found) => {
            for signature in found {
                append(signature, &mut signatures);
            }
        }
        Err(error) => warnings.push(format!("Bloc de signature APK illisible : {error}")),
    }
    (signatures, warnings)
}

fn append(signature: Signature, target: &mut Vec<SignatureInfo>) {
    let (scheme, certificates) = match signature {
        Signature::V1(certs) => ("v1", certs),
        Signature::V2(certs) => ("v2", certs),
        Signature::V3(certs) => ("v3", certs),
        Signature::V31(certs) => ("v3.1", certs),
        // Source stamps and distribution metadata are not app signing certificates.
        _ => return,
    };
    target.push(SignatureInfo {
        scheme,
        certificates: certificates.into_iter().map(Into::into).collect(),
    });
}
