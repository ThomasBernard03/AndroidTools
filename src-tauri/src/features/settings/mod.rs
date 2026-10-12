pub(crate) mod commands;
pub(crate) mod domain;
pub(crate) mod infrastructure;

#[cfg(any(test, all(windows, feature = "windows-updater")))]
mod updates;
#[cfg(all(windows, feature = "windows-updater"))]
pub(crate) mod windows_updater;
