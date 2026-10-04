//! Converts supported Android drawables to a fixed-size PNG preview, without a device.
use apk_info::{ARSC, AXML, Apk};
use roxmltree::{Document, Node};
use std::{fs::File, io::Read};

const MAX_IMAGE: u64 = 2 * 1024 * 1024;
const MAX_DEPTH: usize = 16;
const MAX_NODES: usize = 2048;

/// Resource lookup is injectable so drawable rendering can be tested without APK tooling.
trait Resources {
    fn read(&mut self, path: &str) -> Option<Vec<u8>>;
    fn resolve(&mut self, reference: &str) -> Option<String>;
}

struct ApkResources<'a> {
    apk: &'a Apk,
    zip: &'a mut zip::ZipArchive<File>,
    arsc: Option<ARSC>,
    loaded: bool,
    remaining: u64,
}

fn read_entry(zip: &mut zip::ZipArchive<File>, path: &str, limit: u64) -> Option<Vec<u8>> {
    let entry = zip.by_name(path).ok()?;
    if entry.size() > limit {
        return None;
    }
    let mut bytes = Vec::new();
    entry.take(limit + 1).read_to_end(&mut bytes).ok()?;
    (bytes.len() as u64 <= limit).then_some(bytes)
}

impl Resources for ApkResources<'_> {
    fn read(&mut self, path: &str) -> Option<Vec<u8>> {
        let bytes = read_entry(self.zip, path, MAX_IMAGE.min(self.remaining))?;
        self.remaining = self.remaining.checked_sub(bytes.len() as u64)?;
        Some(bytes)
    }
    fn resolve(&mut self, reference: &str) -> Option<String> {
        let raw = reference.strip_prefix('@')?;
        if let Ok(id) = u32::from_str_radix(raw.strip_prefix("0x").unwrap_or(raw), 16) {
            if !self.loaded {
                self.loaded = true;
                self.arsc = read_entry(self.zip, "resources.arsc", 64 * 1024 * 1024)
                    .and_then(|bytes| ARSC::new(&mut bytes.as_slice()).ok());
            }
            self.arsc.as_ref()?.get_resource_value(id)
        } else {
            self.apk.get_resource_value(reference)
        }
    }
}

fn escape(value: &str) -> String {
    value
        .replace('&', "&amp;")
        .replace('"', "&quot;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
}
fn attr<'a>(node: Node<'a, '_>, name: &str) -> Option<&'a str> {
    node.attributes()
        .find(|a| a.name() == name)
        .map(|a| a.value())
}
fn number(node: Node<'_, '_>, name: &str, default: f32) -> Option<f32> {
    let value = attr(node, name)
        .map(str::parse)
        .transpose()
        .ok()?
        .unwrap_or(default);
    (value.is_finite() && value.abs() <= 1_000_000.0).then_some(value)
}
fn rgba(value: &str) -> Option<(String, f32)> {
    let value = value.strip_prefix('#')?;
    if !value.bytes().all(|b| b.is_ascii_hexdigit()) {
        return None;
    }
    let expanded = if value.len() <= 4 {
        value.chars().flat_map(|c| [c, c]).collect::<String>()
    } else {
        value.into()
    };
    match expanded.len() {
        6 => Some((format!("#{expanded}"), 1.0)),
        8 => Some((
            format!("#{}", &expanded[2..]),
            u8::from_str_radix(&expanded[..2], 16).ok()? as f32 / 255.0,
        )),
        _ => None,
    }
}
fn raster(bytes: &[u8]) -> Option<String> {
    let mime = if bytes.starts_with(b"\x89PNG\r\n\x1a\n") {
        "image/png"
    } else if bytes.starts_with(&[0xff, 0xd8, 0xff]) {
        "image/jpeg"
    } else if bytes.starts_with(b"RIFF") && bytes.get(8..12) == Some(b"WEBP") {
        "image/webp"
    } else {
        return None;
    };
    let size = imagesize::blob_size(bytes).ok()?;
    if size.width == 0 || size.height == 0 || size.width > 2048 || size.height > 2048 {
        return None;
    }
    Some(format!(
        "data:{mime};base64,{}",
        openssl::base64::encode_block(bytes)
    ))
}

fn valid_path(path: &str) -> Option<()> {
    let mut count = 0;
    for segment in svgtypes::PathParser::from(path) {
        segment.ok()?;
        count += 1;
        if count > 10_000 {
            return None;
        }
    }
    (count > 0).then_some(())
}

struct Renderer<R> {
    resources: R,
    nodes: usize,
    ids: usize,
}
impl<R: Resources> Renderer<R> {
    fn id(&mut self) -> String {
        self.ids += 1;
        format!("drawable{}", self.ids)
    }
    fn resolve(&mut self, input: &str) -> Option<String> {
        let mut value = input.to_owned();
        for _ in 0..MAX_DEPTH {
            if !value.starts_with('@') {
                return Some(value);
            }
            value = self.resources.resolve(&value)?;
        }
        None
    }
    fn color(&mut self, input: &str) -> Option<(String, f32)> {
        let value = self.resolve(input)?;
        if let Some(color) = rgba(&value) {
            return Some(color);
        }
        // Default color of a ColorStateList, not a device/theme-specific state.
        let bytes = self.resources.read(&value)?;
        let xml = xml(&bytes)?;
        let document = Document::parse(&xml).ok()?;
        let root = document.root_element();
        if root.tag_name().name() != "selector" {
            return None;
        }
        let item = root
            .children()
            .filter(Node::is_element)
            .find(|n| !n.attributes().any(|a| a.name().starts_with("state_")))?;
        rgba(&self.resolve(attr(item, "color")?)?)
    }
    fn gradient(&mut self, node: Node<'_, '_>) -> Option<(String, String)> {
        if !node.has_tag_name("gradient") {
            return None;
        }
        let id = self.id();
        let mode = match attr(node, "tileMode") {
            Some("repeat" | "1" | "0x00000001") => "repeat",
            Some("mirror" | "2" | "0x00000002") => "reflect",
            _ => "pad",
        };
        let (tag, geometry) = match attr(node, "type") {
            None | Some("linear" | "0" | "0x00000000") => (
                "linearGradient",
                format!(
                    "x1=\"{}\" y1=\"{}\" x2=\"{}\" y2=\"{}\"",
                    number(node, "startX", 0.0)?,
                    number(node, "startY", 0.0)?,
                    number(node, "endX", 0.0)?,
                    number(node, "endY", 0.0)?
                ),
            ),
            Some("radial" | "1" | "0x00000001") => {
                let radius = number(node, "gradientRadius", 0.0)?;
                if radius <= 0.0 {
                    return None;
                }
                (
                    "radialGradient",
                    format!(
                        "cx=\"{}\" cy=\"{}\" r=\"{radius}\"",
                        number(node, "centerX", 0.0)?,
                        number(node, "centerY", 0.0)?
                    ),
                )
            }
            _ => return None,
        };
        let mut stops = Vec::new();
        for item in node.children().filter(Node::is_element) {
            if !item.has_tag_name("item") || stops.len() >= 256 {
                return None;
            }
            stops.push((
                number(item, "offset", 0.0)?.clamp(0.0, 1.0),
                self.color(attr(item, "color")?)?,
            ));
        }
        if stops.is_empty() {
            stops.push((0.0, self.color(attr(node, "startColor")?)?));
            if let Some(color) = attr(node, "centerColor") {
                stops.push((0.5, self.color(color)?));
            }
            stops.push((1.0, self.color(attr(node, "endColor")?)?));
        }
        if stops.len() < 2 || stops.windows(2).any(|s| s[0].0 > s[1].0) {
            return None;
        }
        let stops = stops
            .into_iter()
            .map(|(offset, (color, alpha))| {
                format!(
                    "<stop offset=\"{offset}\" stop-color=\"{color}\" stop-opacity=\"{alpha}\"/>"
                )
            })
            .collect::<String>();
        Some((
            format!(
                "<defs><{tag} id=\"{id}\" gradientUnits=\"userSpaceOnUse\" spreadMethod=\"{mode}\" {geometry}>{stops}</{tag}></defs>"
            ),
            format!("url(#{id})"),
        ))
    }
    fn paint(&mut self, node: Node<'_, '_>, name: &str) -> Option<(String, String, f32)> {
        if let Some(inline) = node.children().filter(Node::is_element).find(|child| {
            attr(*child, "name")
                .is_some_and(|value| value.strip_prefix("android:").unwrap_or(value) == name)
        }) {
            let (definitions, value) = self.gradient(inline.children().find(Node::is_element)?)?;
            return Some((definitions, value, 1.0));
        }
        let Some(value) = attr(node, name) else {
            return Some((String::new(), "none".into(), 1.0));
        };
        if let Some((color, alpha)) = self.color(value) {
            return Some((String::new(), color, alpha));
        }
        let path = self.resolve(value)?;
        let bytes = self.resources.read(&path)?;
        let xml = xml(&bytes)?;
        let doc = Document::parse(&xml).ok()?;
        let (definitions, color) = self.gradient(doc.root_element())?;
        Some((definitions, color, 1.0))
    }
    fn drawable(&mut self, input: &str, depth: usize) -> Option<String> {
        if depth > MAX_DEPTH {
            return None;
        }
        let value = self.resolve(input)?;
        if let Some((color, alpha)) = rgba(&value) {
            return Some(format!(
                "<rect width=\"108\" height=\"108\" fill=\"{color}\" opacity=\"{alpha}\"/>"
            ));
        }
        let bytes = self.resources.read(&value)?;
        if let Some(data) = raster(&bytes) {
            return Some(format!(
                "<image width=\"108\" height=\"108\" href=\"{data}\"/>"
            ));
        }
        let xml = xml(&bytes)?;
        let doc = Document::parse(&xml).ok()?;
        self.element(doc.root_element(), depth + 1)
    }
    fn element(&mut self, node: Node<'_, '_>, depth: usize) -> Option<String> {
        self.nodes += 1;
        if self.nodes > MAX_NODES || depth > MAX_DEPTH {
            return None;
        }
        match node.tag_name().name() {
            "vector" => {
                let width = number(node, "viewportWidth", 0.0)?;
                let height = number(node, "viewportHeight", 0.0)?;
                if width <= 0.0 || height <= 0.0 {
                    return None;
                }
                let alpha = number(node, "alpha", 1.0)?.clamp(0.0, 1.0);
                let mut content = self.children(node, depth + 1)?;
                if let Some(tint) = attr(node, "tint") {
                    if !matches!(
                        attr(node, "tintMode"),
                        None | Some("src_in" | "5" | "0x00000005")
                    ) {
                        return None;
                    }
                    let (color, opacity) = self.color(tint)?;
                    let id = self.id();
                    content = format!(
                        "<defs><filter id=\"{id}\" x=\"0\" y=\"0\" width=\"1\" height=\"1\"><feFlood flood-color=\"{color}\" flood-opacity=\"{opacity}\"/><feComposite in2=\"SourceGraphic\" operator=\"in\"/></filter></defs><g filter=\"url(#{id})\">{content}</g>"
                    );
                }
                Some(format!(
                    "<svg width=\"108\" height=\"108\" viewBox=\"0 0 {width} {height}\"><g opacity=\"{alpha}\">{content}</g></svg>"
                ))
            }
            "group" => {
                let px = number(node, "pivotX", 0.0)?;
                let py = number(node, "pivotY", 0.0)?;
                let tx = number(node, "translateX", 0.0)?;
                let ty = number(node, "translateY", 0.0)?;
                let sx = number(node, "scaleX", 1.0)?;
                let sy = number(node, "scaleY", 1.0)?;
                let rotation = number(node, "rotation", 0.0)?;
                let content = self.children(node, depth + 1)?;
                Some(format!(
                    "<g transform=\"translate({} {}) rotate({rotation}) scale({sx} {sy}) translate({} {})\">{content}</g>",
                    tx + px,
                    ty + py,
                    -px,
                    -py
                ))
            }
            "path" => {
                if number(node, "trimPathStart", 0.0)? != 0.0
                    || number(node, "trimPathEnd", 1.0)? != 1.0
                    || number(node, "trimPathOffset", 0.0)? != 0.0
                {
                    return None;
                }
                let path = attr(node, "pathData")?;
                // Validate geometry; malformed paths should use the generic icon.
                valid_path(path)?;
                let mut style = String::new();
                let mut definitions = String::new();
                for (android, svg, alpha) in [
                    ("fillColor", "fill", "fillAlpha"),
                    ("strokeColor", "stroke", "strokeAlpha"),
                ] {
                    let (defs, color, opacity) = self.paint(node, android)?;
                    definitions.push_str(&defs);
                    style.push_str(&format!(
                        " {svg}=\"{color}\" {svg}-opacity=\"{}\"",
                        opacity * number(node, alpha, 1.0)?.clamp(0.0, 1.0)
                    ));
                }
                if node.children().filter(Node::is_element).any(|n| {
                    n.tag_name().name() != "attr"
                        || !matches!(
                            attr(n, "name"),
                            Some(
                                "android:fillColor"
                                    | "android:strokeColor"
                                    | "fillColor"
                                    | "strokeColor"
                            )
                        )
                }) {
                    return None;
                }
                let rule = match attr(node, "fillType") {
                    Some("evenOdd" | "1" | "0x00000001") => "evenodd",
                    _ => "nonzero",
                };
                let cap = match attr(node, "strokeLineCap") {
                    Some("round" | "1" | "0x00000001") => "round",
                    Some("square" | "2" | "0x00000002") => "square",
                    _ => "butt",
                };
                let join = match attr(node, "strokeLineJoin") {
                    Some("round" | "1" | "0x00000001") => "round",
                    Some("bevel" | "2" | "0x00000002") => "bevel",
                    _ => "miter",
                };
                Some(format!(
                    "{definitions}<path d=\"{}\"{style} fill-rule=\"{rule}\" stroke-width=\"{}\" stroke-linecap=\"{cap}\" stroke-linejoin=\"{join}\" stroke-miterlimit=\"{}\"/>",
                    escape(path),
                    number(node, "strokeWidth", 0.0)?,
                    number(node, "strokeMiterLimit", 4.0)?
                ))
            }
            "adaptive-icon" => {
                let mut content = String::new();
                for layer in ["background", "foreground"] {
                    let node = node.children().find(|n| n.has_tag_name(layer))?;
                    content.push_str(&self.layer(node, depth + 1)?);
                }
                let id = self.id();
                // Android layers use a 108dp canvas with a 72dp masked viewport.
                Some(format!(
                    "<svg width=\"108\" height=\"108\" viewBox=\"18 18 72 72\"><defs><clipPath id=\"{id}\"><circle cx=\"54\" cy=\"54\" r=\"36\"/></clipPath></defs><g clip-path=\"url(#{id})\">{content}</g></svg>"
                ))
            }
            "inset" => {
                let inset = |name| {
                    attr(node, name)
                        .unwrap_or("0")
                        .strip_suffix('%')
                        .and_then(|n| n.parse::<f32>().ok())
                        .map(|v| v * 1.08)
                };
                let uniform = attr(node, "inset");
                let amount = if uniform.is_some() {
                    inset("inset")?
                } else {
                    0.0
                };
                let side = |name| {
                    if attr(node, name).is_some() {
                        inset(name)
                    } else {
                        Some(amount)
                    }
                };
                let left = side("insetLeft")?;
                let right = side("insetRight")?;
                let top = side("insetTop")?;
                let bottom = side("insetBottom")?;
                if [left, right, top, bottom]
                    .iter()
                    .any(|v| !v.is_finite() || *v < 0.0)
                    || left + right >= 108.0
                    || top + bottom >= 108.0
                {
                    return None;
                }
                Some(format!(
                    "<g transform=\"translate({left} {top}) scale({} {})\">{}</g>",
                    (108.0 - left - right) / 108.0,
                    (108.0 - top - bottom) / 108.0,
                    self.layer(node, depth + 1)?
                ))
            }
            "color" => {
                let (color, opacity) = self.color(node.text()?.trim())?;
                Some(format!(
                    "<rect width=\"108\" height=\"108\" fill=\"{color}\" opacity=\"{opacity}\"/>"
                ))
            }
            _ => None,
        }
    }
    fn layer(&mut self, node: Node<'_, '_>, depth: usize) -> Option<String> {
        if let Some(reference) = attr(node, "drawable") {
            self.drawable(reference, depth)
        } else {
            self.element(node.children().find(Node::is_element)?, depth)
        }
    }
    fn children(&mut self, node: Node<'_, '_>, depth: usize) -> Option<String> {
        let mut content = String::new();
        let mut clips = 0;
        for child in node.children().filter(Node::is_element) {
            if child.has_tag_name("clip-path") {
                self.nodes += 1;
                if self.nodes > MAX_NODES {
                    return None;
                }
                let path = attr(child, "pathData")?;
                valid_path(path)?;
                let id = self.id();
                content.push_str(&format!("<defs><clipPath id=\"{id}\"><path d=\"{}\"/></clipPath></defs><g clip-path=\"url(#{id})\">", escape(path)));
                clips += 1;
            } else {
                content.push_str(&self.element(child, depth)?);
            }
        }
        content.push_str(&"</g>".repeat(clips));
        Some(content)
    }
}

fn xml(bytes: &[u8]) -> Option<String> {
    if bytes.starts_with(&[3, 0, 8, 0]) {
        AXML::new(&mut &bytes[..], None)
            .ok()
            .map(|xml| xml.get_xml_string())
    } else {
        std::str::from_utf8(bytes).ok().map(str::to_owned)
    }
}

fn render(resources: impl Resources, path: &str) -> Option<String> {
    let mut renderer = Renderer {
        resources,
        nodes: 0,
        ids: 0,
    };
    let bytes = renderer.resources.read(path)?;
    if let Some(image) = raster(&bytes) {
        return Some(image);
    }
    let xml = xml(&bytes)?;
    let document = Document::parse(&xml).ok()?;
    let content = renderer.element(document.root_element(), 0)?;
    let svg = format!(
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"192\" height=\"192\" viewBox=\"0 0 108 108\">{content}</svg>"
    );
    let tree = resvg::usvg::Tree::from_str(&svg, &resvg::usvg::Options::default()).ok()?;
    let mut pixmap = resvg::tiny_skia::Pixmap::new(192, 192)?;
    resvg::render(
        &tree,
        resvg::tiny_skia::Transform::identity(),
        &mut pixmap.as_mut(),
    );
    let bytes = pixmap.encode_png().ok()?;
    Some(format!(
        "data:image/png;base64,{}",
        openssl::base64::encode_block(&bytes)
    ))
}

pub(super) fn preview(apk: &Apk, zip: &mut zip::ZipArchive<File>) -> Option<String> {
    let path = apk.get_application_icon()?;
    render(
        ApkResources {
            apk,
            zip,
            arsc: None,
            loaded: false,
            remaining: 8 * 1024 * 1024,
        },
        &path,
    )
}

#[cfg(test)]
mod tests;
