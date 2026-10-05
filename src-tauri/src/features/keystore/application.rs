use super::domain::*;
use std::path::Path;

pub fn validate(request: &GenerateRequest) -> Result<(), KeystoreError> {
    let path = Path::new(&request.path);
    if !path.is_absolute()
        || path.file_name().is_none()
        || path.extension().and_then(|s| s.to_str()) != Some(request.format.extension())
    {
        return Err(KeystoreError::invalid(
            "path",
            "Choose an absolute file path with the selected format's extension.",
        ));
    }
    for (field, password) in [
        ("password", request.password.as_str()),
        ("keyPassword", request.effective_key_password()),
    ] {
        if !(6..=128).contains(&password.len())
            || !password.bytes().all(|b| (32..=126).contains(&b))
        {
            return Err(KeystoreError::invalid(
                field,
                "Use 6–128 printable ASCII characters for Java/Android compatibility.",
            ));
        }
    }
    if request.format == Format::Pkcs12 && request.password != request.effective_key_password() {
        return Err(KeystoreError::invalid(
            "keyPassword",
            "PKCS12 requires the same password for the keystore and key.",
        ));
    }
    if request.alias.is_empty()
        || request.alias.len() > 64
        || !request
            .alias
            .bytes()
            .all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b"._-".contains(&b))
    {
        return Err(KeystoreError::invalid(
            "alias",
            "Use 1–64 lowercase letters, numbers, dots, underscores or hyphens.",
        ));
    }
    if !(1..=100).contains(&request.validity_years) {
        return Err(KeystoreError::invalid(
            "validityYears",
            "Choose a validity between 1 and 100 years.",
        ));
    }
    if request.common_name.trim().is_empty() {
        return Err(KeystoreError::invalid(
            "commonName",
            "Enter a certificate name.",
        ));
    }
    for (field, value) in [
        ("commonName", &request.common_name),
        ("organization", &request.organization),
        ("organizationalUnit", &request.organizational_unit),
        ("locality", &request.locality),
        ("state", &request.state),
    ] {
        if value.len() > 128 || value.chars().any(char::is_control) {
            return Err(KeystoreError::invalid(
                field,
                "Use at most 128 UTF-8 bytes without control characters.",
            ));
        }
    }
    if !request.country.is_empty()
        && (request.country.len() != 2 || !request.country.bytes().all(|b| b.is_ascii_uppercase()))
    {
        return Err(KeystoreError::invalid(
            "country",
            "Enter a two-letter uppercase country code.",
        ));
    }
    Ok(())
}

pub fn generate(
    request: &GenerateRequest,
    encoder: &impl KeystoreEncoder,
    files: &impl KeystoreFiles,
) -> Result<GeneratedKeystore, KeystoreError> {
    validate(request)?;
    files.ensure_available(&request.path)?;
    let (bytes, result) = encoder.encode(request)?;
    files.publish(&request.path, &bytes)?;
    Ok(result)
}
