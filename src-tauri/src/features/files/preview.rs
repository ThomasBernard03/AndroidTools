use super::{application::shell, domain::FileError, paths::*};
use crate::features::adb::domain::AdbSession;
use serde::Serialize;

const TEXT_LIMIT: usize = 1024 * 1024;
const IMAGE_LIMIT: usize = 8 * 1024 * 1024;

/// Read-only, bounded content suitable for display without interpreting document markup.
#[derive(Debug, Serialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum FilePreview {
    Text { content: String },
    Image { content: String },
}

/// Read at most the preview limit plus one byte, including when a remote file grows.
pub async fn read(session: &dyn AdbSession, path: &str) -> Result<FilePreview, FileError> {
    let path = normalize(path)?;
    let (parent, name) = target(&path)?;
    let extension = name.rsplit('.').next().unwrap_or("").to_ascii_lowercase();
    let mime = match extension.as_str() {
        "png" => Some("image/png"),
        "jpg" | "jpeg" => Some("image/jpeg"),
        "webp" => Some("image/webp"),
        _ => None,
    };
    let limit = if mime.is_some() {
        IMAGE_LIMIT
    } else {
        TEXT_LIMIT
    };
    let source = quote(&format!("./{name}"));
    let command = at(
        parent,
        &format!(
            "[ -e {source} ] || [ -L {source} ] || exit 46\n[ ! -L {source} ] && [ -f {source} ] || exit 45\nhead -c {} {source}",
            limit + 1
        ),
    )?;
    let bytes = shell(session, &path, &command, None).await?;
    if bytes.len() > limit {
        return Err(FileError::new(
            "preview_too_large",
            if mime.is_some() {
                "Image previews are limited to 8 MiB. Download the file to view it."
            } else {
                "Text previews are limited to 1 MiB. Download the file to view it."
            },
        ));
    }
    if let Some(mime) = mime {
        let matches = match mime {
            "image/png" => bytes.starts_with(b"\x89PNG\r\n\x1a\n"),
            "image/jpeg" => bytes.starts_with(b"\xff\xd8\xff"),
            _ => bytes.starts_with(b"RIFF") && bytes.get(8..12) == Some(b"WEBP"),
        };
        let dimensions = imagesize::blob_size(&bytes).map_err(|_| unsupported())?;
        if !matches
            || dimensions.width == 0
            || dimensions.height == 0
            || dimensions.width.saturating_mul(dimensions.height) > 32_000_000
        {
            return Err(FileError::new(
                "unsupported_preview",
                "The image is invalid or exceeds the 32 megapixel preview limit.",
            ));
        }
        return Ok(FilePreview::Image {
            content: format!(
                "data:{mime};base64,{}",
                openssl::base64::encode_block(&bytes)
            ),
        });
    }
    let content = String::from_utf8(bytes).map_err(|_| unsupported())?;
    if content
        .chars()
        .any(|c| c.is_control() && !matches!(c, '\n' | '\r' | '\t'))
    {
        return Err(unsupported());
    }
    Ok(FilePreview::Text { content })
}

fn unsupported() -> FileError {
    FileError::new(
        "unsupported_preview",
        "Preview supports UTF-8 text and PNG, JPEG or WebP images. Download this file to open it externally.",
    )
}
