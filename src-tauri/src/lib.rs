//! Desktop composition root. Feature logic will live outside the Tauri bootstrap.

/// Starts the desktop runtime and its main window.
///
/// # Panics
///
/// Panics if the native runtime cannot be initialized or fails while running.
pub fn run() {
    tauri::Builder::default()
        .run(tauri::generate_context!())
        .expect("failed to run Android Tools");
}
