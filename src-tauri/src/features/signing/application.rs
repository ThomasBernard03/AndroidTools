use super::domain::*;
use std::path::Path;

/// Opens the save dialog only after signing succeeds. Cancellation drops the artifact.
pub fn sign_and_save(
    request: &SignRequest,
    signer: &impl ApkSigner,
    choose_destination: impl FnOnce(&str) -> Result<Option<String>, SigningError>,
) -> Result<Option<String>, SigningError> {
    let apk = Path::new(&request.apk_path);
    if !apk.is_absolute()
        || !Path::new(&request.keystore_path).is_absolute()
        || !apk
            .extension()
            .is_some_and(|e| e.eq_ignore_ascii_case("apk"))
        || request.alias.trim().is_empty()
        || request.password.is_empty()
    {
        return Err(SigningError::new(
            ErrorCode::InvalidInput,
            "Enter absolute APK and keystore paths, an alias and the keystore password.",
        ));
    }
    let stem = apk.file_stem().and_then(|s| s.to_str()).ok_or_else(|| {
        SigningError::new(ErrorCode::InvalidInput, "The APK filename is not valid.")
    })?;
    let artifact = signer.sign(request)?;
    let Some(destination) = choose_destination(&format!("{stem}-signed.apk"))? else {
        return Ok(None);
    };
    if !Path::new(&destination).is_absolute()
        || !Path::new(&destination)
            .extension()
            .is_some_and(|e| e.eq_ignore_ascii_case("apk"))
    {
        return Err(SigningError::new(
            ErrorCode::InvalidInput,
            "Choose an absolute destination ending in .apk.",
        ));
    }
    artifact.save(&destination)?;
    Ok(Some(destination))
}
