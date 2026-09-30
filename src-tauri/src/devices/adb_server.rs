use std::{
    io::{self, Read, Write},
    net::{Ipv4Addr, SocketAddr, TcpStream},
    time::Duration,
};

use super::ServiceError;

pub fn stop_adb_server() -> Result<bool, ServiceError> {
    stop_server(
        SocketAddr::from((Ipv4Addr::LOCALHOST, 5037)),
        Duration::from_secs(2),
    )
    .map_err(|error| {
        ServiceError::new(
            "adb_server",
            "Impossible d’arrêter le serveur ADB local. Fermez l’outil qui l’utilise, puis réessayez.",
            error.to_string(),
        )
    })
}

fn stop_server(address: SocketAddr, timeout: Duration) -> io::Result<bool> {
    let mut stream = match TcpStream::connect_timeout(&address, timeout) {
        Ok(stream) => stream,
        Err(error) if error.kind() == io::ErrorKind::ConnectionRefused => return Ok(false),
        Err(error) => return Err(error),
    };
    stream.set_read_timeout(Some(timeout))?;
    stream.set_write_timeout(Some(timeout))?;
    // The smart socket protocol prefixes each request with its hexadecimal byte length.
    stream.write_all(b"0009host:kill")?;
    let mut status = [0; 4];
    stream.read_exact(&mut status)?;
    if &status != b"OKAY" {
        return Err(io::Error::other("ADB server rejected host:kill"));
    }
    // Wait for shutdown before allowing a new USB connection.
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
    use std::{net::TcpListener, thread};

    fn fake_server(response: &'static [u8]) -> (SocketAddr, thread::JoinHandle<()>) {
        let listener = TcpListener::bind((Ipv4Addr::LOCALHOST, 0)).expect("bind test server");
        let address = listener.local_addr().expect("test server address");
        let handle = thread::spawn(move || {
            let (mut stream, _) = listener.accept().expect("accept client");
            stream
                .set_read_timeout(Some(Duration::from_secs(2)))
                .expect("set test timeout");
            let mut request = [0; 13];
            stream.read_exact(&mut request).expect("read kill request");
            assert_eq!(&request, b"0009host:kill");
            stream.write_all(response).expect("write test response");
        });
        (address, handle)
    }

    #[test]
    fn requests_shutdown_and_waits_for_close() {
        let (address, handle) = fake_server(b"OKAY");
        assert!(stop_server(address, Duration::from_secs(2)).expect("stop server"));
        handle.join().expect("test server completed");
    }

    #[test]
    fn rejects_failed_or_truncated_responses() {
        for response in [b"FAIL".as_slice(), b"OK"] {
            let (address, handle) = fake_server(response);
            assert!(stop_server(address, Duration::from_secs(2)).is_err());
            handle.join().expect("test server completed");
        }
    }

    #[test]
    fn missing_server_is_not_an_error() {
        let listener = TcpListener::bind((Ipv4Addr::LOCALHOST, 0)).expect("bind test server");
        let address = listener.local_addr().expect("test server address");
        drop(listener);
        assert!(!stop_server(address, Duration::from_secs(2)).expect("absent server"));
    }
}
