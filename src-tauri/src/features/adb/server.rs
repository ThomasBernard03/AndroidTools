use std::{
    io::{self, Read, Write},
    net::{Ipv4Addr, SocketAddr, TcpStream},
    time::Duration,
};

use super::domain::{AdbError, AdbErrorCode};

/// Releases USB ownership by requesting shutdown of the standard local ADB server.
/// Uses the smart socket protocol directly; no SDK executable is required.
pub(super) async fn stop_local_server() -> Result<(), AdbError> {
    let result = tokio::task::spawn_blocking(|| {
        stop_server(
            SocketAddr::from((Ipv4Addr::LOCALHOST, 5037)),
            Duration::from_secs(2),
        )
    })
    .await
    .map_err(|_| {
        AdbError::new(
            AdbErrorCode::Internal,
            "Local ADB server shutdown could not finish.",
        )
    })?;
    match result {
        Ok(stopped) => {
            log::info!("operation=stop_adb_server outcome=success stopped={stopped}");
            Ok(())
        }
        Err(error) => {
            log::warn!(
                "operation=stop_adb_server outcome=failure kind={:?}",
                error.kind()
            );
            Err(AdbError::new(
                AdbErrorCode::UsbAccess,
                "Could not stop the local ADB server. Close Android Studio and other ADB clients, then retry.",
            ))
        }
    }
}

fn stop_server(address: SocketAddr, timeout: Duration) -> io::Result<bool> {
    let mut stream = match TcpStream::connect_timeout(&address, timeout) {
        Ok(stream) => stream,
        Err(error) if error.kind() == io::ErrorKind::ConnectionRefused => return Ok(false),
        Err(error) => return Err(error),
    };
    stream.set_read_timeout(Some(timeout))?;
    stream.set_write_timeout(Some(timeout))?;
    // Smart socket requests start with their four-digit hexadecimal byte length.
    stream.write_all(b"0009host:kill")?;
    let mut status = [0; 4];
    stream.read_exact(&mut status)?;
    if &status != b"OKAY" {
        return Err(io::Error::other("ADB server rejected host:kill"));
    }
    // An acknowledgment alone does not mean the server has released USB yet.
    let mut byte = [0];
    match stream.read(&mut byte) {
        Ok(0) => Ok(true),
        Err(error) if error.kind() == io::ErrorKind::ConnectionReset => Ok(true),
        Err(error) => Err(error),
        Ok(_) => Err(io::Error::other("Unexpected ADB shutdown response")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::{net::TcpListener, sync::mpsc, thread};

    fn fake_server(response: &'static [u8]) -> (SocketAddr, thread::JoinHandle<()>) {
        let listener = TcpListener::bind((Ipv4Addr::LOCALHOST, 0)).expect("bind fake server");
        let address = listener.local_addr().expect("server address");
        let handle = thread::spawn(move || {
            let (mut stream, _) = listener.accept().expect("accept client");
            stream
                .set_read_timeout(Some(Duration::from_secs(2)))
                .expect("read timeout");
            let mut request = [0; 13];
            stream.read_exact(&mut request).expect("shutdown request");
            assert_eq!(&request, b"0009host:kill");
            stream.write_all(response).expect("server response");
        });
        (address, handle)
    }

    #[test]
    fn requests_shutdown_and_waits_for_close() {
        let (address, handle) = fake_server(b"OKAY");
        assert!(stop_server(address, Duration::from_secs(2)).expect("stop server"));
        handle.join().expect("server completed");
    }

    #[test]
    fn rejects_failed_truncated_and_unexpected_responses() {
        for response in [b"FAIL".as_slice(), b"OK", b"OKAYx"] {
            let (address, handle) = fake_server(response);
            assert!(stop_server(address, Duration::from_secs(2)).is_err());
            handle.join().expect("server completed");
        }
    }

    #[test]
    fn absent_server_is_not_an_error() {
        let listener = TcpListener::bind((Ipv4Addr::LOCALHOST, 0)).expect("bind server");
        let address = listener.local_addr().expect("server address");
        drop(listener);
        assert!(!stop_server(address, Duration::from_secs(2)).expect("absent server"));
    }

    #[test]
    fn acknowledgment_without_shutdown_times_out() {
        let listener = TcpListener::bind((Ipv4Addr::LOCALHOST, 0)).expect("bind server");
        let address = listener.local_addr().expect("server address");
        let (release, wait) = mpsc::channel();
        let handle = thread::spawn(move || {
            let (mut stream, _) = listener.accept().expect("accept client");
            stream
                .set_read_timeout(Some(Duration::from_secs(2)))
                .expect("read timeout");
            let mut request = [0; 13];
            stream.read_exact(&mut request).expect("shutdown request");
            stream.write_all(b"OKAY").expect("acknowledgment");
            let _ = wait.recv_timeout(Duration::from_secs(5));
        });
        let error = stop_server(address, Duration::from_millis(100)).expect_err("shutdown timeout");
        assert!(matches!(
            error.kind(),
            io::ErrorKind::TimedOut | io::ErrorKind::WouldBlock
        ));
        release.send(()).expect("release server");
        handle.join().expect("server completed");
    }
}
