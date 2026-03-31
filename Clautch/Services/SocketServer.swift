import Foundation
import os

/// Listens on a Unix domain socket for JSON hook events from Claude Code.
final class SocketServer: @unchecked Sendable {
    static let shared = SocketServer()

    /// Use macOS per-user TMPDIR (e.g. /var/folders/.../T/) instead of
    /// world-writable /tmp to prevent symlink attacks and spoofed events.
    static let socketPath: String = {
        let tmpdir = NSTemporaryDirectory()
        return (tmpdir as NSString).appendingPathComponent("clautch.sock")
    }()

    private let logger = Logger(subsystem: "com.clautch.app", category: "SocketServer")
    private let queue = DispatchQueue(label: "com.clautch.socket", qos: .userInitiated)
    private var serverFD: Int32 = -1
    private var acceptSource: DispatchSourceRead?

    /// Maximum message size to prevent memory exhaustion (64 KB).
    private let maxMessageSize = 65_536

    /// Called on the **main thread** for every decoded event.
    var onEvent: (@Sendable (HookEvent) -> Void)?

    func start() {
        queue.async { [weak self] in self?.listen() }
    }

    func stop() {
        queue.async { [weak self] in
            self?.acceptSource?.cancel()
            self?.acceptSource = nil
        }
        if serverFD >= 0 {
            Darwin.close(serverFD)
            serverFD = -1
        }
        unlink(Self.socketPath)
    }

    // MARK: - Private

    private func listen() {
        // Remove stale socket
        unlink(Self.socketPath)

        serverFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFD >= 0 else {
            logger.error("socket() failed: \(errno)")
            return
        }

        // Non-blocking for DispatchSource
        let flags = fcntl(serverFD, F_GETFL)
        _ = fcntl(serverFD, F_SETFL, flags | O_NONBLOCK)

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        Self.socketPath.withCString { src in
            withUnsafeMutablePointer(to: &addr.sun_path) { dst in
                _ = strcpy(
                    UnsafeMutableRawPointer(dst).assumingMemoryBound(to: CChar.self),
                    src
                )
            }
        }

        let bindOK = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverFD, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bindOK == 0 else {
            logger.error("bind() failed: \(errno)")
            return
        }

        // Owner-only permissions (0600) — prevents other local users from sending events
        chmod(Self.socketPath, 0o600)

        guard Darwin.listen(serverFD, 5) == 0 else {
            logger.error("listen() failed: \(errno)")
            return
        }

        logger.info("Listening on \(Self.socketPath)")

        // Event-driven accept via GCD — zero CPU when idle
        let source = DispatchSource.makeReadSource(fileDescriptor: serverFD, queue: queue)
        source.setEventHandler { [weak self] in
            self?.acceptPendingConnections()
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.serverFD, fd >= 0 {
                Darwin.close(fd)
                self?.serverFD = -1
            }
        }
        acceptSource = source
        source.resume()
    }

    private func acceptPendingConnections() {
        while true {
            var clientAddr = sockaddr_un()
            var len = socklen_t(MemoryLayout<sockaddr_un>.size)

            let clientFD = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    accept(serverFD, $0, &len)
                }
            }

            if clientFD >= 0 {
                handleClient(clientFD)
            } else {
                break // EAGAIN — no more pending connections
            }
        }
    }

    private func handleClient(_ fd: Int32) {
        defer { Darwin.close(fd) }

        // Verify connecting process belongs to same user (defense-in-depth)
        var euid: uid_t = 0
        var egid: gid_t = 0
        if getpeereid(fd, &euid, &egid) == 0, euid != getuid() {
            logger.warning("Rejected socket connection from UID \(euid)")
            return
        }

        // Read timeout
        var tv = timeval(tv_sec: 0, tv_usec: 500_000)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        var data = Data()
        var buf = [UInt8](repeating: 0, count: 4096)

        while true {
            let n = read(fd, &buf, buf.count)
            if n > 0 {
                data.append(contentsOf: buf[..<n])
                // Enforce max message size to prevent memory exhaustion
                if data.count > maxMessageSize {
                    logger.warning("Message exceeded \(self.maxMessageSize) bytes, dropping")
                    return
                }
            } else {
                break
            }
        }

        guard !data.isEmpty else { return }

        do {
            let event = try JSONDecoder().decode(HookEvent.self, from: data)
            logger.debug("Event: \(event.eventType.rawValue) session=\(event.sessionId)")
            let handler = onEvent
            DispatchQueue.main.async { handler?(event) }
        } catch {
            logger.error("Decode failed: \(error.localizedDescription)")
        }
    }
}
