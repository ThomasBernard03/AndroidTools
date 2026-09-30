use std::collections::HashMap;

use super::{DeviceInfo, ServiceError};

pub fn parse_device_info(device_id: &str, output: &str) -> Result<DeviceInfo, ServiceError> {
    let properties: HashMap<&str, &str> = output
        .lines()
        .filter_map(|line| {
            line.trim()
                .strip_prefix('[')?
                .strip_suffix(']')?
                .split_once("]: [")
        })
        .collect();

    if properties.is_empty() {
        return Err(ServiceError::new(
            "invalid_response",
            "L’appareil n’a renvoyé aucune propriété Android lisible.",
            "Empty or malformed getprop response",
        ));
    }

    let value = |key| {
        properties
            .get(key)
            .map(|value| value.trim())
            .filter(|value| !value.is_empty())
            .map(str::to_owned)
    };

    Ok(DeviceInfo {
        device_id: device_id.to_owned(),
        manufacturer: value("ro.product.manufacturer"),
        brand: value("ro.product.brand"),
        model: value("ro.product.model"),
        device: value("ro.product.device"),
        serial: value("ro.serialno").or_else(|| value("ro.boot.serialno")),
        android_version: value("ro.build.version.release"),
        api_level: value("ro.build.version.sdk"),
        security_patch: value("ro.build.version.security_patch"),
        build_id: value("ro.build.display.id").or_else(|| value("ro.build.id")),
        build_fingerprint: value("ro.build.fingerprint"),
        hardware: value("ro.hardware"),
        soc: value("ro.soc.model"),
        abis: value("ro.product.cpu.abilist").or_else(|| value("ro.product.cpu.abi")),
        bootloader: value("ro.bootloader"),
    })
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;

    #[test]
    fn parses_crlf_missing_values_and_values_containing_brackets() {
        let info = parse_device_info("usb-1", "[ro.product.model]: [Pixel [test]]\r\n[ro.build.version.release]: [16]\r\n[ro.soc.model]: []\r\nnoise\r\n").unwrap();
        assert_eq!(info.model.as_deref(), Some("Pixel [test]"));
        assert_eq!(info.android_version.as_deref(), Some("16"));
        assert!(info.soc.is_none());
        assert!(info.manufacturer.is_none());
    }

    #[test]
    fn falls_back_to_legacy_properties() {
        let info = parse_device_info("usb-2", "[ro.serialno]: []\n[ro.boot.serialno]: [ABC]\n[ro.product.cpu.abi]: [arm64-v8a]\n[ro.build.id]: [BUILD]").unwrap();
        assert_eq!(info.serial.as_deref(), Some("ABC"));
        assert_eq!(info.abis.as_deref(), Some("arm64-v8a"));
        assert_eq!(info.build_id.as_deref(), Some("BUILD"));
    }

    #[test]
    fn rejects_empty_or_failed_shell_output() {
        assert!(parse_device_info("usb-1", "").is_err());
        assert!(parse_device_info("usb-1", "/system/bin/sh: getprop: not found").is_err());
    }
}
