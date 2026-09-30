use serde::Serialize;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceSummary {
    pub id: String,
    pub name: String,
    pub serial: Option<String>,
    pub vendor_id: String,
    pub product_id: String,
    pub usb_location: String,
    pub access_error: Option<super::ServiceError>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceInfo {
    pub device_id: String,
    pub manufacturer: Option<String>,
    pub brand: Option<String>,
    pub model: Option<String>,
    pub device: Option<String>,
    pub serial: Option<String>,
    pub android_version: Option<String>,
    pub api_level: Option<String>,
    pub security_patch: Option<String>,
    pub build_id: Option<String>,
    pub build_fingerprint: Option<String>,
    pub hardware: Option<String>,
    pub soc: Option<String>,
    pub abis: Option<String>,
    pub bootloader: Option<String>,
}
