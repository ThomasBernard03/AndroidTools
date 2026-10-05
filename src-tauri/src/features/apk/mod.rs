//! Local, read-only APK inspection with no Android SDK dependency.
pub mod commands;
pub mod domain;
mod icons;
pub mod infrastructure;
mod verification;

#[cfg(test)]
mod tests;
