#[cfg(feature = "uwp")]
fn main() {
    println!("Universal Windows Platform Application")
}

#[cfg(not(feature = "uwp"))]
fn main() {
    println!("Classic Win32 Desktop Application")
}
