fn main() {
    println!("cargo:rerun-if-env-changed=SENTRY_DSN");
    tauri_build::build();
}
