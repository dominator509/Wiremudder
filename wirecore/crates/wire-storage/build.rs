// Link against the host SQLite C library (pinned 3.45.1, no vendored
// dependency, no new supply chain for EP-014).
fn main() {
    println!("cargo:rustc-link-lib=sqlite3");
    println!("cargo:rerun-if-changed=build.rs");
}
