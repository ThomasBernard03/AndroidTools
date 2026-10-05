use std::time::Duration;

use rusb::{Context, UsbContext};

use super::domain::{DeviceError, DeviceErrorCode, DeviceRepository, DeviceSummary};

/// Discovers USB ADB interfaces without claiming them or starting an ADB session.
pub struct UsbDeviceRepository;

fn usb_error(error: rusb::Error) -> DeviceError {
    DeviceError {
        code: DeviceErrorCode::UsbUnavailable,
        message: format!("Unable to discover USB devices: {error}. Check USB access and retry."),
    }
}

fn is_adb_interface(class: u8, subclass: u8, protocol: u8) -> bool {
    class == 0xff && subclass == 0x42 && protocol == 0x01
}

fn non_empty(value: String) -> Option<String> {
    let value = value.trim();
    (!value.is_empty()).then(|| value.to_owned())
}

impl DeviceRepository for UsbDeviceRepository {
    fn list(&self) -> Result<Vec<DeviceSummary>, DeviceError> {
        let context = Context::new().map_err(usb_error)?;
        let devices = context.devices().map_err(usb_error)?;
        let mut result = Vec::new();
        for device in devices.iter() {
            // A device can disappear between enumeration and descriptor reads.
            let Ok(descriptor) = device.device_descriptor() else {
                continue;
            };
            let has_adb = (0..descriptor.num_configurations()).any(|index| {
                device.config_descriptor(index).is_ok_and(|config| {
                    config.interfaces().any(|interface| {
                        interface.descriptors().any(|descriptor| {
                            is_adb_interface(
                                descriptor.class_code(),
                                descriptor.sub_class_code(),
                                descriptor.protocol_code(),
                            )
                        })
                    })
                })
            });
            if !has_adb {
                continue;
            }

            let mut summary = DeviceSummary {
                id: format!(
                    "usb:{}:{}:{:04x}:{:04x}",
                    device.bus_number(),
                    device.address(),
                    descriptor.vendor_id(),
                    descriptor.product_id()
                ),
                name: "Android device".into(),
                serial: None,
                manufacturer: None,
                product: None,
                vendor_id: descriptor.vendor_id(),
                product_id: descriptor.product_id(),
                warning: None,
            };
            let metadata = (|| -> Result<(), rusb::Error> {
                let handle = device.open()?;
                let timeout = Duration::from_millis(200);
                let languages = handle.read_languages(timeout)?;
                let language = languages.first().ok_or(rusb::Error::NotFound)?;
                // USB strings are optional; preserve any metadata we can read.
                let manufacturer = handle.read_manufacturer_string(*language, &descriptor, timeout);
                let product = handle.read_product_string(*language, &descriptor, timeout);
                let serial = handle.read_serial_number_string(*language, &descriptor, timeout);
                if let Ok(value) = &product {
                    summary.product = non_empty(value.clone());
                    summary.name = summary
                        .product
                        .clone()
                        .unwrap_or_else(|| "Android device".into());
                }
                if let Ok(value) = &manufacturer {
                    summary.manufacturer = non_empty(value.clone());
                }
                if let Ok(value) = &serial {
                    summary.serial = non_empty(value.clone());
                }
                if product.is_err() || serial.is_err() || manufacturer.is_err() {
                    summary.warning = Some("Some USB metadata is unavailable. The device may require additional USB permissions.".into());
                }
                Ok(())
            })();
            if let Err(error) = metadata {
                summary.warning = Some(format!(
                    "USB metadata is unavailable: {error}. Check USB permissions."
                ));
            }
            result.push(summary);
        }
        Ok(result)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recognizes_adb_but_not_mtp_fastboot_or_unrelated_usb_interfaces() {
        assert!(is_adb_interface(0xff, 0x42, 0x01));
        assert!(!is_adb_interface(0x06, 0x01, 0x01));
        assert!(!is_adb_interface(0xff, 0x42, 0x03));
        assert!(!is_adb_interface(0xff, 0x00, 0x01));
    }

    #[test]
    fn normalizes_missing_and_padded_metadata() {
        assert_eq!(non_empty("  ".into()), None);
        assert_eq!(non_empty(" Pixel 9 ".into()), Some("Pixel 9".into()));
    }
}
