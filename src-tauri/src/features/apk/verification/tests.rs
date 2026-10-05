use super::*;
use openssl::{
    asn1::Asn1Time,
    bn::BigNum,
    ec::{EcGroup, EcKey},
    nid::Nid,
    pkey::Private,
    rsa::Rsa,
    sign::Signer,
    x509::X509NameBuilder,
};
use std::io::{Cursor, Write};
use zip::{ZipWriter, write::SimpleFileOptions};

fn record(bytes: &[u8]) -> Vec<u8> {
    [(bytes.len() as u32).to_le_bytes().as_slice(), bytes].concat()
}
fn algorithm_record(id: u32, bytes: &[u8]) -> Vec<u8> {
    record(&[id.to_le_bytes().to_vec(), record(bytes)].concat())
}

fn identity(ec: bool) -> (PKey<Private>, Vec<u8>) {
    let key = if ec {
        let group = EcGroup::from_curve_name(Nid::X9_62_PRIME256V1).expect("curve");
        PKey::from_ec_key(EcKey::generate(&group).expect("EC key")).expect("key")
    } else {
        PKey::from_rsa(Rsa::generate(2048).expect("RSA key")).expect("key")
    };
    let mut name = X509NameBuilder::new().expect("name");
    name.append_entry_by_text("CN", "Integrity fixture")
        .expect("CN");
    let name = name.build();
    let mut cert = X509::builder().expect("certificate");
    cert.set_version(2).expect("version");
    cert.set_serial_number(
        &BigNum::from_u32(1)
            .expect("serial")
            .to_asn1_integer()
            .expect("ASN1"),
    )
    .expect("serial");
    cert.set_subject_name(&name).expect("subject");
    cert.set_issuer_name(&name).expect("issuer");
    cert.set_pubkey(&key).expect("public key");
    cert.set_not_before(&Asn1Time::from_unix(1704067200).expect("date"))
        .expect("start");
    cert.set_not_after(&Asn1Time::from_unix(2019686400).expect("date"))
        .expect("end");
    cert.sign(&key, MessageDigest::sha256())
        .expect("sign certificate");
    (key, cert.build().to_der().expect("DER"))
}

struct Fixture {
    file: tempfile::NamedTempFile,
    signature: Vec<u8>,
}
fn fixture(scheme: u32, algo: u32, wrong_certificate: bool) -> Fixture {
    let (key, mut certificate) = identity(algo == 0x0201);
    if wrong_certificate {
        certificate = identity(false).1;
    }
    let mut zip = ZipWriter::new(Cursor::new(Vec::new()));
    zip.start_file(
        "classes.dex",
        SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored),
    )
    .expect("entry");
    zip.write_all(b"known application contents")
        .expect("entry data");
    let raw = zip.finish().expect("ZIP").into_inner();
    let mut unsigned = tempfile::NamedTempFile::new().expect("file");
    unsigned.write_all(&raw).expect("write");
    let digest = apksig::Apk::new_raw(unsigned.path().into())
        .expect("APK")
        .digest(&Algorithms::RSASSA_PKCS1_v1_5_256)
        .expect("digest");
    let range = [28u32.to_le_bytes(), 35u32.to_le_bytes()].concat();
    let mut signed = [
        record(&algorithm_record(algo, &digest)),
        record(&record(&certificate)),
    ]
    .concat();
    if scheme != V2 {
        signed.extend(&range);
    }
    signed.extend(record(&[]));
    let mut signer = Signer::new(MessageDigest::sha256(), &key).expect("signer");
    if algo == 0x0101 {
        signer.set_rsa_padding(Padding::PKCS1_PSS).expect("PSS");
        signer
            .set_rsa_mgf1_md(MessageDigest::sha256())
            .expect("MGF");
        signer
            .set_rsa_pss_saltlen(RsaPssSaltlen::DIGEST_LENGTH)
            .expect("salt");
    }
    let signature = signer.sign_oneshot_to_vec(&signed).expect("signature");
    let mut signer = record(&signed);
    if scheme != V2 {
        signer.extend(&range);
    }
    signer.extend(record(&algorithm_record(algo, &signature)));
    signer.extend(record(&key.public_key_to_der().expect("public key")));
    let value = record(&record(&signer));
    let pair = [
        ((value.len() + 4) as u64).to_le_bytes().to_vec(),
        scheme.to_le_bytes().to_vec(),
        value,
    ]
    .concat();
    let size = (pair.len() as u64 + 24).to_le_bytes();
    let block = [size.as_slice(), &pair, &size, b"APK Sig Block 42"].concat();
    let eocd = raw.len() - 22;
    let cd = u32::from_le_bytes(raw[eocd + 16..eocd + 20].try_into().expect("CD offset")) as usize;
    let mut output = [raw[..cd].to_vec(), block.clone(), raw[cd..].to_vec()].concat();
    output[eocd + block.len() + 16..eocd + block.len() + 20]
        .copy_from_slice(&((cd + block.len()) as u32).to_le_bytes());
    let mut file = tempfile::NamedTempFile::new().expect("file");
    file.write_all(&output).expect("APK");
    Fixture { file, signature }
}

#[test]
fn verifies_v2_v3_v31_rsa_pss_and_ecdsa_against_apk_contents() {
    for (scheme, algo, name) in [
        (V2, 0x0103, "v2"),
        (V3, 0x0103, "v3"),
        (V31, 0x0103, "v3.1"),
        (V2, 0x0101, "v2"),
        (V3, 0x0201, "v3"),
    ] {
        let f = fixture(scheme, algo, false);
        let result = inspect(f.file.path(), false);
        assert_eq!(
            result.status,
            VerificationStatus::Verified,
            "{scheme:x} / {algo:x}: {}",
            result.message
        );
        assert_eq!(result.schemes, [name]);
    }
}

#[test]
fn rejects_modified_content_signature_and_certificate_key() {
    for mutate_signature in [false, true] {
        let f = fixture(V2, 0x0103, false);
        let mut data = std::fs::read(f.file.path()).expect("APK");
        let needle = if mutate_signature {
            f.signature.as_slice()
        } else {
            b"known application contents"
        };
        let index = data
            .windows(needle.len())
            .position(|w| w == needle)
            .expect("test data");
        data[index] ^= 1;
        std::fs::write(f.file.path(), data).expect("tamper");
        assert_eq!(
            inspect(f.file.path(), false).status,
            VerificationStatus::Invalid
        );
    }
    let f = fixture(V2, 0x0103, true);
    assert_eq!(
        inspect(f.file.path(), false).status,
        VerificationStatus::Invalid
    );
}

#[test]
fn distinguishes_unsupported_algorithms_v1_unsigned_and_malformed_blocks() {
    let f = fixture(V2, 0x9999, false);
    assert_eq!(
        inspect(f.file.path(), false).status,
        VerificationStatus::Unverified
    );
    let mut zip = ZipWriter::new(Cursor::new(Vec::new()));
    zip.start_file("classes.dex", SimpleFileOptions::default())
        .expect("entry");
    let bytes = zip.finish().expect("ZIP").into_inner();
    let mut file = tempfile::NamedTempFile::new().expect("file");
    file.write_all(&bytes).expect("ZIP");
    assert_eq!(
        inspect(file.path(), false).status,
        VerificationStatus::Unsigned
    );
    assert_eq!(
        inspect(file.path(), true).status,
        VerificationStatus::Unverified
    );
    let f = fixture(V2, 0x0103, false);
    let mut bytes = std::fs::read(f.file.path()).expect("APK");
    let footer = bytes
        .windows(16)
        .position(|w| w == b"APK Sig Block 42")
        .expect("footer");
    bytes[footer - 8..footer].copy_from_slice(&u64::MAX.to_le_bytes());
    std::fs::write(f.file.path(), bytes).expect("corrupt block");
    assert_eq!(
        inspect(f.file.path(), false).status,
        VerificationStatus::Invalid
    );
}
