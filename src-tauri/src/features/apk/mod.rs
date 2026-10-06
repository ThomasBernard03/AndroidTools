//! Local APK inspection and selected-device installation without an Android SDK.
pub mod commands;
pub mod domain;
mod icons;
pub mod infrastructure;
mod installation;
mod verification;

#[cfg(test)]
mod tests;
