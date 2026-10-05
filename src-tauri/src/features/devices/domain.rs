use serde::Serialize;

/// A currently connected USB device exposing an ADB interface.
/// Presence does not imply that Android has authorized an ADB session.
#[derive(Clone, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceSummary {
    /// Connection identity, valid only for the current USB attachment.
    pub id: String,
    pub name: String,
    pub serial: Option<String>,
    /// Optional strings reported by the USB device, not Android system properties.
    pub manufacturer: Option<String>,
    pub product: Option<String>,
    /// USB descriptor identifiers remain available when string metadata cannot be read.
    pub vendor_id: u16,
    pub product_id: u16,
    /// Non-fatal failure to read USB metadata; the device is still listed.
    pub warning: Option<String>,
}

/// Structured discovery failure, serialized across the IPC boundary.
#[derive(Clone, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceError {
    pub code: DeviceErrorCode,
    pub message: String,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum DeviceErrorCode {
    UsbUnavailable,
    Internal,
}

/// Replaceable boundary for external device discovery.
pub trait DeviceRepository: Send + Sync {
    fn list(&self) -> Result<Vec<DeviceSummary>, DeviceError>;
}
