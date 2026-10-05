use std::sync::Arc;

use super::domain::{DeviceError, DeviceRepository, DeviceSummary};

/// Lists devices independently of Tauri and the concrete discovery transport.
#[derive(Clone)]
pub struct DeviceService {
    repository: Arc<dyn DeviceRepository>,
}

impl DeviceService {
    pub fn new(repository: impl DeviceRepository + 'static) -> Self {
        Self {
            repository: Arc::new(repository),
        }
    }

    pub fn list(&self) -> Result<Vec<DeviceSummary>, DeviceError> {
        let mut devices = self.repository.list()?;
        devices.sort_by(|a, b| a.name.cmp(&b.name).then(a.id.cmp(&b.id)));
        Ok(devices)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::features::devices::domain::DeviceErrorCode;

    struct FakeRepository(Result<Vec<DeviceSummary>, DeviceError>);

    impl DeviceRepository for FakeRepository {
        fn list(&self) -> Result<Vec<DeviceSummary>, DeviceError> {
            self.0.clone()
        }
    }

    fn device(id: &str) -> DeviceSummary {
        DeviceSummary {
            id: id.into(),
            name: "Pixel".into(),
            serial: None,
            manufacturer: None,
            product: None,
            vendor_id: 0x18d1,
            product_id: 0x4ee7,
            warning: None,
        }
    }

    #[test]
    fn preserves_same_model_devices_and_orders_them_by_connection() {
        let service =
            DeviceService::new(FakeRepository(Ok(vec![device("usb:2"), device("usb:1")])));
        assert_eq!(service.list(), Ok(vec![device("usb:1"), device("usb:2")]));
    }

    #[test]
    fn returns_an_empty_list_without_inventing_demo_devices() {
        assert_eq!(
            DeviceService::new(FakeRepository(Ok(vec![]))).list(),
            Ok(vec![])
        );
    }

    #[test]
    fn preserves_discovery_failures_instead_of_returning_an_empty_list() {
        let error = DeviceError {
            code: DeviceErrorCode::UsbUnavailable,
            message: "Access denied".into(),
        };
        assert_eq!(
            DeviceService::new(FakeRepository(Err(error.clone()))).list(),
            Err(error)
        );
    }

    #[test]
    fn serializes_the_frontend_contract_with_explicit_missing_metadata() {
        assert_eq!(
            serde_json::to_value(device("usb:1")).expect("serialize device"),
            serde_json::json!({"id": "usb:1", "name": "Pixel", "serial": null,
                "manufacturer": null, "product": null, "vendorId": 0x18d1,
                "productId": 0x4ee7, "warning": null})
        );
        assert_eq!(
            serde_json::to_value(DeviceError {
                code: DeviceErrorCode::UsbUnavailable,
                message: "USB failed".into()
            })
            .expect("serialize error"),
            serde_json::json!({"code": "usb_unavailable", "message": "USB failed"})
        );
    }
}
