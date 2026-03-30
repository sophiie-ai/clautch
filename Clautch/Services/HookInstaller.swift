import Foundation
import os

/// Installs the Clautch hook script into Claude Code's hook system.
final class HookInstaller {
    static let shared = HookInstaller()
    private let logger = Logger(subsystem: "com.clautch.app", category: "HookInstaller")

    private var claudeDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
    }
    private var hooksDir: URL { claudeDir.appendingPathComponent("hooks") }
    private var settingsFile: URL { claudeDir.appendingPathComponent("settings.json") }
    private var hookDest: URL { hooksDir.appendingPathComponent("clautch-hook.sh") }

    func installIfNeeded() {
        do {
            try FileManager.default.createDirectory(at: hooksDir, withIntermediateDirectories: true)
            try copyHookScript()
            try registerHooks()
            logger.info("Hooks installed")
        } catch {
            logger.error("Hook install failed: \(error)")
        }
    }

    // MARK: - Private

    private func copyHookScript() throws {
        guard let src = Bundle.main.url(forResource: "clautch-hook", withExtension: "sh") else {
            logger.warning("clautch-hook.sh not in bundle, writing inline fallback")
            try inlineHookScript().write(to: hookDest, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: hookDest.path
            )
            return
        }
        try FileManager.default.copyItem(at: src, to: hookDest)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755], ofItemAtPath: hookDest.path
        )
    }

    private func registerHooks() throws {
        var settings: [String: Any] = [:]

        if FileManager.default.fileExists(atPath: settingsFile.path) {
            let data = try Data(contentsOf: settingsFile)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                settings = json
            }
        }

        var hooks = settings["hooks"] as? [String: [[String: Any]]] ?? [:]

        let events = [
            "UserPromptSubmit", "SessionStart", "SessionEnd",
            "PreToolUse", "PostToolUse", "Stop",
            "PermissionRequest", "PreCompact",
        ]

        let entry: [String: Any] = [
            "type": "command",
            "command": hookDest.path,
        ]

        for event in events {
            var list = hooks[event] ?? []
            let alreadyInstalled = list.contains {
                ($0["command"] as? String)?.contains("clautch-hook") == true
            }
            if !alreadyInstalled {
                list.append(entry)
                hooks[event] = list
            }
        }

        settings["hooks"] = hooks

        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: settingsFile, options: .atomic)
        logger.info("Claude Code settings updated with Clautch hooks")
    }

    /// Fallback hook script embedded in code (used when bundle resource is missing,
    /// e.g. during development).
    private func inlineHookScript() -> String {
        """
        #!/bin/bash
        SOCKET="/tmp/clautch.sock"
        [ -S "$SOCKET" ] || exit 0

        EVENT=$(cat)

        python3 -c "
        import socket, sys, json, os

        raw = sys.stdin.read() if not '''$EVENT''' else '''$EVENT'''
        try:
            event = json.loads(raw)
        except:
            sys.exit(0)

        if 'session_id' not in event:
            event['session_id'] = os.environ.get('CLAUDE_SESSION_ID', 'unknown')

        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            sock.connect('$SOCKET')
            sock.sendall(json.dumps(event).encode())
        except:
            pass
        finally:
            sock.close()
        " 2>/dev/null

        exit 0
        """
    }
}
