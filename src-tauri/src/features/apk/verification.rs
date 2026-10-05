//! APK v2/v3/v3.1 cryptographic integrity checks over the original signed bytes.
//! This does not implement Android install policy, rotation lineage or JAR/v1 verification.
use super::domain::{SignatureVerification, VerificationStatus};
use apksig::{Algorithms, digest_apk, zip::FileOffsets};
use openssl::{
    hash::MessageDigest,
    pkey::PKey,
    rsa::Padding,
    sign::{RsaPssSaltlen, Verifier},
    x509::X509,
};
use std::{
    collections::{BTreeMap, HashSet},
    fs::File,
    io::{Read, Seek, SeekFrom},
    path::Path,
};

const V2: u32 = 0x7109871a;
const V3: u32 = 0xf05368c0;
const V31: u32 = 0x1b93ad61;
const MAX_BLOCK: usize = 16 * 1024 * 1024;

#[derive(Debug)]
enum Failure {
    Invalid,
    Unsupported,
    Io,
}
type Result<T> = std::result::Result<T, Failure>;

/// Length-prefixed records must be exhausted; trailing/duplicate data is rejected.
struct Bytes<'a>(&'a [u8]);
impl<'a> Bytes<'a> {
    fn take(&mut self, count: usize) -> Result<&'a [u8]> {
        let (value, rest) = self.0.split_at_checked(count).ok_or(Failure::Invalid)?;
        self.0 = rest;
        Ok(value)
    }
    fn u32(&mut self) -> Result<u32> {
        Ok(u32::from_le_bytes(
            self.take(4)?.try_into().map_err(|_| Failure::Invalid)?,
        ))
    }
    fn u64(&mut self) -> Result<u64> {
        Ok(u64::from_le_bytes(
            self.take(8)?.try_into().map_err(|_| Failure::Invalid)?,
        ))
    }
    fn record(&mut self) -> Result<Bytes<'a>> {
        let size = self.u32()? as usize;
        Ok(Bytes(self.take(size)?))
    }
    fn end(&self) -> Result<()> {
        if self.0.is_empty() {
            Ok(())
        } else {
            Err(Failure::Invalid)
        }
    }
}

fn read_at(file: &mut File, offset: u64, size: usize) -> Result<Vec<u8>> {
    file.seek(SeekFrom::Start(offset))
        .map_err(|_| Failure::Io)?;
    let mut bytes = vec![0; size];
    file.read_exact(&mut bytes).map_err(|_| Failure::Io)?;
    Ok(bytes)
}

/// Locate the signing block immediately before the central directory, not by scanning
/// for a magic string in arbitrary file data. ZIP64/multi-disk APKs are unsupported.
fn signing_block(file: &mut File) -> Result<Option<(Vec<u8>, FileOffsets)>> {
    let size = file.metadata().map_err(|_| Failure::Io)?.len();
    let tail_len = size.min(65535 + 22) as usize;
    let tail = read_at(file, size - tail_len as u64, tail_len)?;
    let pos = (0..tail_len.saturating_sub(21))
        .rev()
        .find(|&i| {
            tail[i..].starts_with(b"PK\x05\x06")
                && u16::from_le_bytes([tail[i + 20], tail[i + 21]]) as usize + i + 22 == tail_len
        })
        .ok_or(Failure::Invalid)?;
    let eocd = &tail[pos..];
    if eocd[4..8] != [0; 4] || eocd[8..10] != eocd[10..12] {
        return Err(Failure::Unsupported);
    }
    let mut fields = Bytes(&eocd[12..20]);
    let cd_size = fields.u32()? as u64;
    let cd = fields.u32()? as u64;
    let eocd_offset = size - tail_len as u64 + pos as u64;
    if cd == u32::MAX as u64 || cd_size == u32::MAX as u64 {
        return Err(Failure::Unsupported);
    }
    if cd + cd_size != eocd_offset {
        return Err(Failure::Invalid);
    }
    if cd < 24 {
        return Ok(None);
    }
    let footer = read_at(file, cd - 24, 24)?;
    if &footer[8..] != b"APK Sig Block 42" {
        return Ok(None);
    }
    let length = Bytes(&footer).u64()?;
    if length < 24 || length > cd - 8 {
        return Err(Failure::Invalid);
    }
    if length > MAX_BLOCK as u64 {
        return Err(Failure::Unsupported);
    }
    let start = cd - length - 8;
    let block = read_at(file, start, (length + 8) as usize)?;
    if Bytes(&block).u64()? != length {
        return Err(Failure::Invalid);
    }
    let entries = block[8..block.len() - 24].to_vec();
    Ok(Some((
        entries,
        FileOffsets {
            start_content: 0,
            stop_content: start as usize,
            start_cd: cd as usize,
            stop_cd: eocd_offset as usize,
            start_eocd: eocd_offset as usize,
            stop_eocd: size as usize,
        },
    )))
}

fn records<'a>(mut bytes: Bytes<'a>) -> Result<Vec<(u32, &'a [u8])>> {
    let mut result = Vec::new();
    let mut ids = HashSet::new();
    while !bytes.0.is_empty() {
        let mut entry = bytes.record()?;
        let id = entry.u32()?;
        let data = entry.record()?.0;
        entry.end()?;
        if !ids.insert(id) {
            return Err(Failure::Invalid);
        }
        result.push((id, data));
    }
    Ok(result)
}

fn algorithm(id: u32) -> Option<(MessageDigest, bool, u8)> {
    match id {
        0x0101 => Some((MessageDigest::sha256(), true, 1)),
        0x0102 => Some((MessageDigest::sha512(), true, 2)),
        0x0103 | 0x0201 | 0x0301 => Some((MessageDigest::sha256(), false, 1)),
        0x0104 | 0x0202 => Some((MessageDigest::sha512(), false, 2)),
        _ => None,
    }
}

fn verify_signer(
    mut signer: Bytes<'_>,
    id: u32,
    file: &mut File,
    offsets: &FileOffsets,
    cache: &mut BTreeMap<u8, Vec<u8>>,
    present: &HashSet<u32>,
) -> Result<()> {
    let signed_bytes = signer.record()?.0;
    let range = if id != V2 {
        Some((signer.u32()?, signer.u32()?))
    } else {
        None
    };
    let signatures = records(signer.record()?)?;
    let public_bytes = signer.record()?.0;
    signer.end()?;
    let mut data = Bytes(signed_bytes);
    let digests = records(data.record()?)?;
    if signatures.iter().map(|s| s.0).collect::<Vec<_>>()
        != digests.iter().map(|d| d.0).collect::<Vec<_>>()
    {
        return Err(Failure::Invalid);
    }
    let mut certificates = data.record()?;
    let first = certificates.record()?.0;
    let cert = X509::from_der(first).map_err(|_| Failure::Invalid)?;
    while !certificates.0.is_empty() {
        X509::from_der(certificates.record()?.0).map_err(|_| Failure::Invalid)?;
    }
    if let Some((min, max)) = range
        && (min > max || (data.u32()?, data.u32()?) != (min, max))
    {
        return Err(Failure::Invalid);
    }
    let mut attributes = data.record()?;
    let mut seen = HashSet::new();
    while !attributes.0.is_empty() {
        let mut attr = attributes.record()?;
        let kind = attr.u32()?;
        if !seen.insert(kind) {
            return Err(Failure::Invalid);
        }
        // v2 stripping protection: a signed declaration of v3 requires its block.
        if id == V2 && kind == 0xbeeff00d && attr.u32()? == 3 && !present.contains(&V3) {
            return Err(Failure::Invalid);
        }
    }
    data.end()?;
    let public = PKey::public_key_from_der(public_bytes).map_err(|_| Failure::Invalid)?;
    if !cert
        .public_key()
        .map_err(|_| Failure::Invalid)?
        .public_eq(&public)
    {
        return Err(Failure::Invalid);
    }
    // Android selects the strongest supported algorithm, not every optional algorithm.
    let (index, (md, pss, hash_kind)) = signatures
        .iter()
        .enumerate()
        .filter_map(|(i, s)| algorithm(s.0).map(|a| (i, a)))
        .max_by_key(|(_, a)| a.2)
        .ok_or(Failure::Unsupported)?;
    let (algo, signature) = signatures[index];
    let expected_key_type = match algo {
        0x0101..=0x0104 => openssl::pkey::Id::RSA,
        0x0201..=0x0202 => openssl::pkey::Id::EC,
        _ => openssl::pkey::Id::DSA,
    };
    if public.id() != expected_key_type {
        return Err(Failure::Invalid);
    }
    let mut verifier = Verifier::new(md, &public).map_err(|_| Failure::Unsupported)?;
    if pss {
        verifier
            .set_rsa_padding(Padding::PKCS1_PSS)
            .map_err(|_| Failure::Unsupported)?;
        verifier
            .set_rsa_mgf1_md(md)
            .map_err(|_| Failure::Unsupported)?;
        verifier
            .set_rsa_pss_saltlen(RsaPssSaltlen::DIGEST_LENGTH)
            .map_err(|_| Failure::Unsupported)?;
    }
    if !verifier
        .verify_oneshot(signature, signed_bytes)
        .map_err(|_| Failure::Invalid)?
    {
        return Err(Failure::Invalid);
    }
    if let std::collections::btree_map::Entry::Vacant(entry) = cache.entry(hash_kind) {
        let hashing = if hash_kind == 2 {
            Algorithms::RSASSA_PKCS1_v1_5_512
        } else {
            Algorithms::RSASSA_PKCS1_v1_5_256
        };
        entry.insert(digest_apk(file, offsets, &hashing).map_err(|_| Failure::Io)?);
    }
    if cache[&hash_kind].as_slice() != digests[index].1 {
        return Err(Failure::Invalid);
    }
    Ok(())
}

fn verify(path: &Path) -> Result<Vec<String>> {
    let mut file = File::open(path).map_err(|_| Failure::Io)?;
    let Some((entries, offsets)) = signing_block(&mut file)? else {
        return Ok(Vec::new());
    };
    let mut entries = Bytes(&entries);
    let mut blocks = Vec::new();
    let mut present = HashSet::new();
    while !entries.0.is_empty() {
        let length = entries.u64()?;
        let mut entry =
            Bytes(entries.take(usize::try_from(length).map_err(|_| Failure::Invalid)?)?);
        let id = entry.u32()?;
        if !present.insert(id) {
            return Err(Failure::Invalid);
        }
        if [V2, V3, V31].contains(&id) {
            blocks.push((id, entry.0));
        }
    }
    if blocks.is_empty() {
        return Err(Failure::Unsupported);
    }
    let mut cache = BTreeMap::new();
    let mut verified = Vec::new();
    let mut unsupported = false;
    for (id, bytes) in blocks {
        let mut outer = Bytes(bytes);
        let mut signers = outer.record()?;
        outer.end()?;
        if signers.0.is_empty() {
            return Err(Failure::Invalid);
        }
        while !signers.0.is_empty() {
            match verify_signer(
                signers.record()?,
                id,
                &mut file,
                &offsets,
                &mut cache,
                &present,
            ) {
                Err(Failure::Unsupported) => unsupported = true,
                result => result?,
            }
        }
        verified.push(
            match id {
                V2 => "v2",
                V3 => "v3",
                _ => "v3.1",
            }
            .into(),
        );
    }
    if unsupported {
        return Err(Failure::Unsupported);
    }
    Ok(verified)
}

pub(super) fn inspect(path: &Path, has_v1: bool) -> SignatureVerification {
    let (status, schemes, message) = match verify(path) {
        Ok(schemes) if !schemes.is_empty() => (
            VerificationStatus::Verified,
            schemes,
            "APK content digests and signer signatures match. This verifies file integrity, not publisher trust or Android installation compatibility.",
        ),
        Ok(_) if has_v1 => (
            VerificationStatus::Unverified,
            vec!["v1".into()],
            "This APK uses JAR/v1 signing. Its certificates are readable, but v1 cryptographic verification is not supported yet.",
        ),
        Ok(_) => (
            VerificationStatus::Unsigned,
            vec![],
            "No APK signing block or JAR signature was found.",
        ),
        Err(Failure::Invalid) => (
            VerificationStatus::Invalid,
            vec![],
            "The signature, signed content digest, certificate key or signing block is invalid. The APK may have been modified after signing.",
        ),
        Err(Failure::Unsupported) => (
            VerificationStatus::Unverified,
            vec![],
            "This APK uses a signing algorithm or structure that cannot be fully verified.",
        ),
        Err(Failure::Io) => (
            VerificationStatus::Unverified,
            vec![],
            "The APK could not be read completely for signature verification.",
        ),
    };
    SignatureVerification {
        status,
        schemes,
        message: message.into(),
    }
}

#[cfg(test)]
mod tests;
