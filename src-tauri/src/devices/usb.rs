use std::{
    io::{self, Write},
    path::PathBuf,
    sync::{Arc, Mutex},
    time::Duration,
};

use adb_client::{
    ADBDeviceExt,
    usb::{ADBUSBDevice, USBTransport},
};
use rusb::{Context, Device, DeviceDescriptor, UsbContext};

use super::{
    DeviceInfo, DeviceSummary, ServiceError, identity::ensure_private_key,
    properties::parse_device_info,
};

pub struct DeviceService {
    key_path: PathBuf,
    connection: Mutex<()>,
}

impl DeviceService {
    pub fn new(key_path: PathBuf) -> Arc<Self> {
        Arc::new(Self {
            key_path,
            connection: Mutex::new(()),
        })
    }

    pub fn get_info(&self, device_id: &str) -> Result<DeviceInfo, ServiceError> {
        let output = self.shell(device_id, "getprop")?;
        let output = String::from_utf8(output).map_err(|error| {
            ServiceError::new(
                "invalid_response",
                "Les propriétés Android ne sont pas encodées correctement.",
                error.to_string(),
            )
        })?;
        parse_device_info(device_id, &output)
    }

    pub(super) fn shell(&self, device_id: &str, command: &str) -> Result<Vec<u8>, ServiceError> {
        let mut stdout = LimitedOutput::default();
        self.shell_to(device_id, command, &mut stdout)?;
        Ok(stdout.0)
    }

    pub(super) fn with_device<T>(
        &self,
        device_id: &str,
        action: impl FnOnce(&mut ADBUSBDevice) -> Result<T, ServiceError>,
    ) -> Result<T, ServiceError> {
        // A USB interface can only have one owner. Keep key creation and ADB sessions serialized.
        let _guard = self
            .connection
            .lock()
            .map_err(|error| ServiceError::internal(error.to_string()))?;
        let (usb_device, _) = enumerate()?
            .into_iter()
            .find(|(_, summary)| summary.id == device_id)
            .ok_or_else(ServiceError::not_found)?;
        ensure_private_key(&self.key_path)?;
        let transport = USBTransport::new_from_device(usb_device);
        let mut device = ADBUSBDevice::new_from_transport(transport, Some(self.key_path.clone()))?;
        action(&mut device)
    }

    pub(super) fn shell_to(
        &self,
        device_id: &str,
        command: &str,
        stdout: &mut dyn Write,
    ) -> Result<(), ServiceError> {
        self.with_device(device_id, |device| Self::run_shell(device, command, stdout))
    }

    pub(super) fn run_shell(
        device: &mut ADBUSBDevice,
        command: &str,
        stdout: &mut dyn Write,
    ) -> Result<(), ServiceError> {
        let mut stderr = LimitedOutput::default();
        let exit_code = device.shell_command(&command, Some(stdout), Some(&mut stderr))?;
        if exit_code.is_some_and(|code| code != 0) {
            return Err(ServiceError::new(
                "shell",
                "L’opération Android a échoué. Vérifiez les droits d’accès et réessayez.",
                String::from_utf8_lossy(&stderr.0).into_owned(),
            ));
        }
        Ok(())
    }
}

pub fn list_devices() -> Result<Vec<DeviceSummary>, ServiceError> {
    Ok(enumerate()?
        .into_iter()
        .map(|(_, summary)| summary)
        .collect())
}

fn enumerate() -> Result<Vec<(Device<Context>, DeviceSummary)>, ServiceError> {
    let context = Context::new()?;
    let mut result = Vec::new();
    for device in context.devices()?.iter() {
        let Ok(descriptor) = device.device_descriptor() else {
            continue;
        };
        if !has_adb_interface(&device, &descriptor) {
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
            name: "Appareil Android".to_owned(),
            serial: None,
            vendor_id: format!("{:04x}", descriptor.vendor_id()),
            product_id: format!("{:04x}", descriptor.product_id()),
            usb_location: format!("{}:{}", device.bus_number(), device.address()),
            access_error: None,
        };

        match device.open() {
            Ok(handle) => {
                let timeout = Duration::from_millis(200);
                if let Ok(languages) = handle.read_languages(timeout)
                    && let Some(language) = languages.first()
                {
                    let manufacturer = handle
                        .read_manufacturer_string(*language, &descriptor, timeout)
                        .unwrap_or_default();
                    let product = handle
                        .read_product_string(*language, &descriptor, timeout)
                        .unwrap_or_default();
                    let name = format!("{manufacturer} {product}").trim().to_owned();
                    if !name.is_empty() {
                        summary.name = name;
                    }
                    summary.serial = handle
                        .read_serial_number_string(*language, &descriptor, timeout)
                        .ok()
                        .filter(|serial| !serial.is_empty());
                }
            }
            Err(error) => summary.access_error = Some(error.into()),
        }
        result.push((device, summary));
    }
    result.sort_by(|(_, a), (_, b)| a.id.cmp(&b.id));
    Ok(result)
}

fn has_adb_interface(device: &Device<Context>, descriptor: &DeviceDescriptor) -> bool {
    // Match the interfaces supported by adb_client's USB transport, not MTP interfaces.
    (0..descriptor.num_configurations()).any(|index| {
        device.config_descriptor(index).is_ok_and(|config| {
            config.interfaces().any(|interface| {
                interface.descriptors().any(|interface| {
                    interface.class_code() == 0xff
                        && interface.sub_class_code() == 0x42
                        && interface.protocol_code() == 0x01
                })
            })
        })
    })
}

#[derive(Default)]
struct LimitedOutput(Vec<u8>);

impl Write for LimitedOutput {
    fn write(&mut self, bytes: &[u8]) -> io::Result<usize> {
        if self.0.len().saturating_add(bytes.len()) > 2 * 1024 * 1024 {
            return Err(io::Error::other("Device output exceeds 2 MiB"));
        }
        self.0.extend_from_slice(bytes);
        Ok(bytes.len())
    }

    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}
