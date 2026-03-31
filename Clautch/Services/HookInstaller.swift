import Foundation
import os

/// Installs the Clautch hook script into Claude Code's hook system.
/// Safely merges with existing user hooks without overwriting them.
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

    /// Marker used to identify Clautch-managed hook entries.
    private let clautchMarker = "clautch-hook"

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
        // Always overwrite to ensure latest version
        if FileManager.default.fileExists(atPath: hookDest.path) {
            try FileManager.default.removeItem(at: hookDest)
        }

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

    /// Register Clautch hooks in Claude Code's settings.json.
    ///
    /// The expected format per event type is:
    /// ```json
    /// "EventName": [
    ///   { "matcher": "", "hooks": [{"type": "command", "command": "..."}] }
    /// ]
    /// ```
    ///
    /// Each event type's array can contain multiple matcher groups. We add
    /// one matcher group for Clautch (matcher="" to match all) and leave
    /// any existing user-defined matcher groups untouched.
    private func registerHooks() throws {
        var settings: [String: Any] = [:]

        if FileManager.default.fileExists(atPath: settingsFile.path) {
            let data = try Data(contentsOf: settingsFile)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                settings = json
            }
        }

        var hooks = settings["hooks"] as? [String: Any] ?? [:]

        let events = [
            "UserPromptSubmit", "SessionStart", "SessionEnd",
            "PreToolUse", "PostToolUse", "Stop",
            "PermissionRequest", "PreCompact",
        ]

        let clautchHookEntry: [String: Any] = [
            "type": "command",
            "command": hookDest.path,
        ]

        let clautchMatcherGroup: [String: Any] = [
            "matcher": "",
            "hooks": [clautchHookEntry],
        ]

        for event in events {
            var matcherGroups = hooks[event] as? [[String: Any]] ?? []

            // Migrate old-format entries (flat {type, command} without matcher/hooks)
            matcherGroups = migrateOldFormat(matcherGroups)

            // Remove any existing Clautch matcher groups (we'll re-add a fresh one)
            matcherGroups.removeAll { group in
                isClautchGroup(group)
            }

            // Append our matcher group
            matcherGroups.append(clautchMatcherGroup)
            hooks[event] = matcherGroups
        }

        settings["hooks"] = hooks

        let data = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: settingsFile, options: .atomic)
        logger.info("Claude Code settings updated with Clautch hooks")
    }

    /// Check if a matcher group was created by Clautch.
    private func isClautchGroup(_ group: [String: Any]) -> Bool {
        guard let hooksList = group["hooks"] as? [[String: Any]] else { return false }
        return hooksList.contains { entry in
            (entry["command"] as? String)?.contains(clautchMarker) == true
        }
    }

    /// Migrate old-format flat entries (pre-matcher format) to the new format.
    /// Old: {"type": "command", "command": "..."} (flat, no matcher/hooks wrapper)
    /// New: {"matcher": "", "hooks": [{"type": "command", "command": "..."}]}
    private func migrateOldFormat(_ groups: [[String: Any]]) -> [[String: Any]] {
        var result: [[String: Any]] = []

        for group in groups {
            if group["hooks"] != nil {
                // Already in new format
                result.append(group)
            } else if let command = group["command"] as? String {
                // Old flat format — wrap it in the new structure
                if command.contains(clautchMarker) {
                    // Skip old Clautch entries; we'll add a fresh one
                    continue
                }
                // Preserve user's old-format entry by wrapping it
                let migrated: [String: Any] = [
                    "matcher": "",
                    "hooks": [group],
                ]
                result.append(migrated)
            }
        }

        return result
    }

    /// Fallback hook script embedded in code (used when bundle resource is missing).
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
