use super::{ApkError, models::Permission};

pub fn parse(manifest: &str) -> Result<Vec<Permission>, ApkError> {
    let document = roxmltree::Document::parse(manifest).map_err(|error| {
        ApkError::new(
            "manifest",
            "Le manifeste décodé n’est pas un document XML valide.",
            error.to_string(),
        )
    })?;
    let root = document.root_element();
    if !root.has_tag_name("manifest") {
        return Err(ApkError::new(
            "manifest",
            "La racine du manifeste Android est invalide.",
            "Expected manifest element",
        ));
    }
    let mut permissions = Vec::new();
    for node in root.children().filter(|node| node.is_element()) {
        let kind = match node.tag_name().name() {
            "uses-permission" => "requested",
            "uses-permission-sdk-23" | "uses-permission-sdk-m" => "requestedSdk23",
            "permission" => "declared",
            _ => continue,
        };
        let attribute = |name| {
            node.attribute(("http://schemas.android.com/apk/res/android", name))
                .map(str::to_owned)
        };
        if let Some(name) = attribute("name").filter(|name| !name.is_empty()) {
            permissions.push(Permission {
                name,
                kind,
                max_sdk: attribute("maxSdkVersion"),
                protection_level: attribute("protectionLevel"),
            });
        }
    }
    permissions.sort_by(|a, b| a.name.cmp(&b.name).then(a.kind.cmp(b.kind)));
    Ok(permissions)
}
