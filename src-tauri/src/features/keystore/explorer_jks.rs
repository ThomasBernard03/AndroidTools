//! Validate lengths before the JKS dependency allocates buffers from untrusted counts.
use super::explorer::ExploreError;

fn invalid() -> ExploreError {
    ExploreError::new(
        "invalid_keystore",
        "The JKS structure is damaged or exceeds supported limits (4096 entries, 64 certificates per chain).",
    )
}

fn take<'a>(input: &mut &'a [u8], size: usize) -> Result<&'a [u8], ExploreError> {
    if size > input.len() {
        return Err(invalid());
    }
    let (value, rest) = input.split_at(size);
    *input = rest;
    Ok(value)
}

fn number(input: &mut &[u8], size: usize) -> Result<usize, ExploreError> {
    Ok(take(input, size)?
        .iter()
        .fold(0, |value, byte| (value << 8) | usize::from(*byte)))
}

fn blob(input: &mut &[u8], size: usize) -> Result<(), ExploreError> {
    let length = number(input, size)?;
    take(input, length)?;
    Ok(())
}

fn certificate(input: &mut &[u8], version: usize) -> Result<(), ExploreError> {
    if version == 2 {
        blob(input, 2)?;
    }
    blob(input, 4)
}

pub fn validate(mut input: &[u8]) -> Result<usize, ExploreError> {
    take(&mut input, 4)?;
    let version = number(&mut input, 4)?;
    if !matches!(version, 1 | 2) {
        return Err(invalid());
    }
    let count = number(&mut input, 4)?;
    if count > 4096 {
        return Err(invalid());
    }
    for _ in 0..count {
        let tag = number(&mut input, 4)?;
        blob(&mut input, 2)?;
        take(&mut input, 8)?;
        match tag {
            1 => {
                blob(&mut input, 4)?;
                let certificates = number(&mut input, 4)?;
                if certificates > 64 {
                    return Err(invalid());
                }
                for _ in 0..certificates {
                    certificate(&mut input, version)?;
                }
            }
            2 => certificate(&mut input, version)?,
            _ => return Err(invalid()),
        }
    }
    // The remaining bytes must be exactly the password-protected SHA-1 digest.
    if input.len() != 20 {
        return Err(invalid());
    }
    Ok(count)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_oversized_lengths_counts_unknown_versions_and_trailing_data() {
        let mut header = vec![0xfe, 0xed, 0xfe, 0xed, 0, 0, 0, 2];
        header.extend_from_slice(&u32::MAX.to_be_bytes());
        assert!(validate(&header).is_err());
        header[8..12].copy_from_slice(&1_u32.to_be_bytes());
        header.extend_from_slice(&[0, 0, 0, 1, 0, 0]);
        header.extend_from_slice(&[0; 8]);
        header.extend_from_slice(&u32::MAX.to_be_bytes());
        assert!(validate(&header).is_err());
        header.truncate(12);
        header[8..12].copy_from_slice(&0_u32.to_be_bytes());
        header.extend_from_slice(&[0; 20]);
        assert!(validate(&header).is_ok());
        header[7] = 3;
        assert!(validate(&header).is_err());
        header[7] = 2;
        header.push(0);
        assert!(validate(&header).is_err());
    }
}
