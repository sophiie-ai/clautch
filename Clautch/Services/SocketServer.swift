import Foundation
import os

/// Listens on a Unix domain socket for JSON hook events from Claude Code.
final class SocketServer: @unchecked Sendable {
    static let shared = SocketServer()

    private let socketPath = "/tmp/clautch.sock"
    private let logger = Logger(subsystem: "com.clautch.app", category: "SocketServer")
    private let queue = DispatchQueue(label: "com.clautch.socket", qos: .userInitiated)
    private var serverFD: Int32 = -1
    private var isRunning = false

    /// Called on the **main thread** for every decoded event.
    var onEvent: (@Sendable (HookEvent) -> Void)?

    func start() {
        queue.async { [weak self] in self?.listen() }
    }

    func stop() {
        isRunning = false
        if serverFD >= 0 {
            Darwin.close(serverFD)
            serverFD = -1
        }
        unlink(socketPath)
    }

    // MARK: - Private

    private func listen() {
        // Remove stale socket
        unlink(socketPath)

        serverFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFD >= 0 else {
            logger.error("socket() failed: \(errno)")
            return
        }

        // Non-blocking accept loop
        var flags = fcntl(serverFD, F_GETFL)
        fcntl(serverFD, F_SETFL, flags | O_NONBLOCK)

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        socketPath.withCString { src in
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

        chmod(socketPath, 0o666)

        guard Darwin.listen(serverFD, 5) == 0 else {
            logger.error("listen() failed: \(errno)")
            return
        }

        logger.info("Listening on \(self.socketPath)")
        isRunning = true

        while isRunning {
            var clientAddr = sockaddr_un()
            var len = socklen_t(MemoryLayout<sockaddr_un>.size)

            let clientFD = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    accept(serverFD, $0, &len)
                }
            }

            if clientFD >= 0 {
                handleClient(clientFD)
            } else if errno == EAGAIN || errno == EWOULDBLOCK {
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
    }

    private func handleClient(_ fd: Int32) {
        defer { Darwin.close(fd) }

        // Read timeout
        var tv = timeval(tv_sec: 0, tv_usec: 500_000)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        var data = Data()
        var buf = [UInt8](repeating: 0, count: 4096)

        while true {
            let n = read(fd, &buf, buf.count)
            if n > 0 { data.append(contentsOf: buf[..<n]) } else { break }
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
