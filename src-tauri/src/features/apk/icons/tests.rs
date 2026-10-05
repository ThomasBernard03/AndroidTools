use super::*;
use std::collections::HashMap;

#[derive(Default)]
struct FakeResources {
    files: HashMap<String, Vec<u8>>,
    references: HashMap<String, String>,
}
impl Resources for FakeResources {
    fn read(&mut self, path: &str) -> Option<Vec<u8>> {
        self.files.get(path).cloned()
    }
    fn resolve(&mut self, reference: &str) -> Option<String> {
        self.references.get(reference).cloned()
    }
}
fn preview(xml: &str) -> Option<resvg::tiny_skia::Pixmap> {
    let mut resources = FakeResources::default();
    resources
        .files
        .insert("icon.xml".into(), xml.as_bytes().to_vec());
    pixels(render(resources, "icon.xml")?)
}
fn pixels(url: String) -> Option<resvg::tiny_skia::Pixmap> {
    let bytes = openssl::base64::decode_block(url.strip_prefix("data:image/png;base64,")?).ok()?;
    resvg::tiny_skia::Pixmap::decode_png(&bytes).ok()
}

#[test]
fn renders_vector_geometry_argb_alpha_transforms_and_clipping() {
    let icon = preview(
        r##"<vector viewportWidth="108" viewportHeight="108">
        <path fillColor="#0000ff" pathData="M0,0 H108 V108 H0 Z"/>
        <group translateX="54"><clip-path pathData="M0,0 H27 V108 H0 Z"/>
          <path fillColor="#ff0000" pathData="M0,0 H108 V108 H0 Z"/>
        </group>
      </vector>"##,
    )
    .expect("render vector");
    assert_eq!((icon.width(), icon.height()), (192, 192));
    assert_eq!(icon.pixel(10, 96).expect("pixel").blue(), 255);
    assert_eq!(icon.pixel(110, 96).expect("pixel").red(), 255);
    assert_eq!(icon.pixel(170, 96).expect("pixel").blue(), 255);
    let alpha = preview(r##"<vector viewportWidth="24" viewportHeight="24"><path fillColor="#80ff0000" pathData="M0,0 H24 V24 H0 Z"/></vector>"##).expect("alpha vector");
    assert_eq!(alpha.pixel(96, 96).expect("pixel").alpha(), 128);
}

#[test]
fn composites_adaptive_layers_resolves_aliases_and_applies_a_circular_mask() {
    let mut resources = FakeResources::default();
    resources.files.insert("icon.xml".into(), br#"<adaptive-icon><background drawable="@color/background"/><foreground drawable="@7f020001"/></adaptive-icon>"#.to_vec());
    resources.files.insert("foreground.xml".into(), br##"<vector viewportWidth="108" viewportHeight="108"><path fillColor="#ff0000" pathData="M44,44 H64 V64 H44 Z"/></vector>"##.to_vec());
    resources
        .references
        .insert("@color/background".into(), "@7f010001".into());
    resources
        .references
        .insert("@7f010001".into(), "#0000ff".into());
    resources
        .references
        .insert("@7f020001".into(), "foreground.xml".into());
    let image = pixels(render(resources, "icon.xml").expect("adaptive icon")).expect("PNG");
    assert_eq!(image.pixel(96, 96).expect("pixel").red(), 255);
    assert_eq!(image.pixel(20, 96).expect("pixel").blue(), 255);
    assert_eq!(image.pixel(0, 0).expect("pixel").alpha(), 0);
}

#[test]
fn renders_inline_gradients_and_vector_tint() {
    let image = preview(r##"<vector xmlns:aapt="http://schemas.android.com/aapt" viewportWidth="108" viewportHeight="108">
      <path pathData="M0,0 H108 V108 H0 Z"><aapt:attr name="android:fillColor">
        <gradient startX="0" startY="0" endX="108" endY="0" type="linear">
          <item color="#ff0000" offset="0"/><item color="#0000ff" offset="1"/>
        </gradient>
      </aapt:attr></path></vector>"##).expect("gradient");
    assert!(image.pixel(10, 96).expect("left").red() > 230);
    assert!(image.pixel(180, 96).expect("right").blue() > 230);
    let tinted = preview(
        r##"<vector viewportWidth="24" viewportHeight="24" tint="#00ff00">
      <path fillColor="#ff0000" pathData="M0,0 H24 V24 H0 Z"/>
    </vector>"##,
    )
    .expect("tint");
    assert_eq!(tinted.pixel(96, 96).expect("pixel").green(), 255);
    assert_eq!(tinted.pixel(96, 96).expect("pixel").red(), 0);
}

#[test]
fn rejects_unresolved_cyclic_and_unsupported_drawables_instead_of_rendering_partial_icons() {
    let mut resources = FakeResources::default();
    resources.files.insert("loop.xml".into(), br#"<adaptive-icon><background drawable="@loop"/><foreground drawable="@missing"/></adaptive-icon>"#.to_vec());
    resources
        .references
        .insert("@loop".into(), "loop.xml".into());
    assert!(render(resources, "loop.xml").is_none());
    for xml in [
        r#"<vector viewportWidth="0" viewportHeight="24"/>"#,
        r#"<vector viewportWidth="24" viewportHeight="24"><path fillColor="@missing" pathData="M0 0 H24 V24 Z"/></vector>"#,
        r#"<vector viewportWidth="24" viewportHeight="24"><path trimPathEnd="0.5" pathData="M0 0 H24 V24 Z"/></vector>"#,
        r#"<svg><script>alert(1)</script></svg>"#,
        "not XML",
    ] {
        assert!(preview(xml).is_none(), "{xml}");
    }
}

/// Build a binary VectorDrawable fixture without aapt or Android SDK binaries.
#[test]
fn decodes_android_binary_xml_before_rendering() {
    let strings = [
        "vector",
        "viewportWidth",
        "24",
        "viewportHeight",
        "path",
        "fillColor",
        "#00ff00",
        "pathData",
        "M0,0 H24 V24 H0 Z",
    ];
    let mut data = Vec::new();
    let mut offsets = Vec::new();
    for value in strings {
        offsets.push(data.len() as u32);
        data.extend([value.len() as u8, value.len() as u8]);
        data.extend(value.as_bytes());
        data.push(0);
    }
    while data.len() % 4 != 0 {
        data.push(0);
    }
    let mut body = Vec::new();
    for value in [
        0x001c0001u32,
        (28 + offsets.len() * 4 + data.len()) as u32,
        offsets.len() as u32,
        0,
        0x100,
        (28 + offsets.len() * 4) as u32,
        0,
    ] {
        body.extend(value.to_le_bytes());
    }
    for offset in offsets {
        body.extend(offset.to_le_bytes());
    }
    body.extend(data);
    body.extend(0x00080180u32.to_le_bytes());
    body.extend(8u32.to_le_bytes());
    for (tag, attrs) in [(0, vec![(1, 2), (3, 2)]), (4, vec![(5, 6), (7, 8)])] {
        for value in [
            0x00100102u32,
            36 + attrs.len() as u32 * 20,
            1,
            u32::MAX,
            u32::MAX,
            tag,
            0x00140014,
            attrs.len() as u32,
            0,
        ] {
            body.extend(value.to_le_bytes());
        }
        for (name, value) in attrs {
            for word in [u32::MAX, name, value, 0x03000008, value] {
                body.extend(word.to_le_bytes());
            }
        }
    }
    for tag in [4, 0] {
        for word in [0x00100103u32, 24, 1, u32::MAX, u32::MAX, tag] {
            body.extend(word.to_le_bytes());
        }
    }
    let mut binary = Vec::new();
    binary.extend(0x00080003u32.to_le_bytes());
    binary.extend((body.len() as u32 + 8).to_le_bytes());
    binary.extend(body);
    let mut resources = FakeResources::default();
    resources.files.insert("icon.xml".into(), binary);
    let image = pixels(render(resources, "icon.xml").expect("binary vector")).expect("PNG");
    assert_eq!(image.pixel(96, 96).expect("pixel").green(), 255);
}
