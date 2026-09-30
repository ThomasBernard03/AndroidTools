use adb_client::RustADBError;
use serde::Serialize;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ServiceError {
    pub code: &'static str,
    pub message: &'static str,
    pub details: String,
}

impl ServiceError {
    pub fn new(code: &'static str, message: &'static str, details: impl Into<String>) -> Self {
        Self {
            code,
            message,
            details: details.into(),
        }
    }

    pub fn internal(details: impl Into<String>) -> Self {
        Self::new("internal", "Une erreur interne est survenue.", details)
    }

    pub fn not_found() -> Self {
        Self::new(
            "disconnected",
            "L’appareil a été déconnecté. Actualisez la liste.",
            "USB device not found",
        )
    }
}

impl From<rusb::Error> for ServiceError {
    fn from(error: rusb::Error) -> Self {
        let (code, message) = match error {
            rusb::Error::Busy => (
                "busy",
                "L’interface USB est déjà utilisée. Arrêtez le serveur ADB ou l’application qui l’occupe, puis réessayez.",
            ),
            rusb::Error::Access => (
                "access",
                "Accès USB refusé. Vérifiez les permissions USB ou le pilote de l’appareil.",
            ),
            rusb::Error::NoDevice => return Self::not_found(),
            rusb::Error::Timeout => (
                "timeout",
                "L’appareil n’a pas répondu. Déverrouillez-le, acceptez l’autorisation de débogage USB, puis réessayez.",
            ),
            _ => (
                "usb",
                "La communication USB a échoué. Vérifiez le câble et reconnectez l’appareil.",
            ),
        };
        Self::new(code, message, error.to_string())
    }
}

impl From<RustADBError> for ServiceError {
    fn from(error: RustADBError) -> Self {
        match error {
            RustADBError::DeviceBusy => rusb::Error::Busy.into(),
            RustADBError::UsbError(error) => error.into(),
            other => Self::new(
                "adb",
                "Impossible de lire les informations Android. Vérifiez l’autorisation de débogage USB et réessayez.",
                other.to_string(),
            ),
        }
    }
}
