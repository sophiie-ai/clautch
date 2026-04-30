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

    private var settingsWatcher: DispatchSourceFileSystemObject?
    private var hookScriptWatcher: DispatchSourceFileSystemObject?
    private let watchQueue = DispatchQueue(label: "com.clautch.hookWatcher", qos: .utility)

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

    /// Watches the settings file and hook script for modifications, repairing on change.
    func startPeriodicRepair(interval: TimeInterval = 60) {
        stopPeriodicRepair()
        watchFile(at: settingsFile, storing: &settingsWatcher)
        watchFile(at: hookDest, storing: &hookScriptWatcher)
    }

    func stopPeriodicRepair() {
        settingsWatcher?.cancel()
        settingsWatcher = nil
        hookScriptWatcher?.cancel()
        hookScriptWatcher = nil
    }

    private func watchFile(at url: URL, storing source: inout DispatchSourceFileSystemObject?) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            logger.warning("Could not open \(url.lastPathComponent) for watching")
            return
        }
        let watcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: watchQueue
        )
        watcher.setEventHandler { [weak self] in
            self?.repairIfNeeded()
        }
        watcher.setCancelHandler {
            close(fd)
        }
        source = watcher
        watcher.resume()
    }

    /// Checks hook integrity and reinstalls if broken.
    @discardableResult
    func repairIfNeeded() -> Bool {
        if verifyHooksIntact() { return false }
        logger.warning("Hooks missing or damaged — repairing")
        installIfNeeded()
        return true
    }

    /// Returns true if hooks appear correctly installed.
    func verifyHooksIntact() -> Bool {
        guard FileManager.default.fileExists(atPath: hookDest.path) else { return false }
        guard FileManager.default.fileExists(atPath: settingsFile.path),
              let data = try? Data(contentsOf: settingsFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any] else { return false }

        return hooks.values.contains { value in
            guard let groups = value as? [[String: Any]] else { return false }
            return groups.contains { isClautchGroup($0) }
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
    /// Validate that the settings file is safe to write to (not a symlink, owned by us).
    private func validateSettingsPath() throws {
        let fm = FileManager.default
        let path = settingsFile.path

        guard fm.fileExists(atPath: path) else { return } // will be created fresh

        // Reject symlinks — prevents writing to an attacker-controlled path
        let attrs = try fm.attributesOfItem(atPath: path)
        if attrs[.type] as? FileAttributeType == .typeSymbolicLink {
            throw NSError(domain: "HookInstaller", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "settings.json is a symlink — refusing to write"])
        }

        // Verify the file is owned by the current user
        if let ownerID = attrs[.ownerAccountID] as? UInt, ownerID != getuid() {
            throw NSError(domain: "HookInstaller", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "settings.json is not owned by current user"])
        }
    }

    private func registerHooks() throws {
        try validateSettingsPath()

        // Use NSFileCoordinator to safely read-modify-write settings.json,
        // preventing data corruption from concurrent access.
        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?
        var innerError: Error?

        coordinator.coordinate(writingItemAt: settingsFile, options: .forMerging, error: &coordinatorError) { url in
            do {
                var settings: [String: Any] = [:]

                if FileManager.default.fileExists(atPath: url.path) {
                    let data = try Data(contentsOf: url)
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        settings = json
                    }
                }

                var hooks = settings["hooks"] as? [String: Any] ?? [:]

                // Only events Claude Code actually dispatches. PermissionRequest
                // is not a real Claude Code hook — registering it does nothing
                // today and risks breaking sessions if validation tightens.
                let events = [
                    "UserPromptSubmit", "SessionStart", "SessionEnd",
                    "PreToolUse", "PostToolUse", "Stop", "PreCompact",
                ]

                let clautchHookEntry: [String: Any] = [
                    "type": "command",
                    "command": "CLAUTCH_SOCKET='\(SocketServer.socketPath)' \(self.hookDest.path)",
                ]

                let clautchMatcherGroup: [String: Any] = [
                    "matcher": "",
                    "hooks": [clautchHookEntry],
                ]

                for event in events {
                    var matcherGroups = hooks[event] as? [[String: Any]] ?? []
                    matcherGroups = self.migrateOldFormat(matcherGroups)
                    matcherGroups.removeAll { self.isClautchGroup($0) }
                    matcherGroups.append(clautchMatcherGroup)
                    hooks[event] = matcherGroups
                }

                settings["hooks"] = hooks

                let data = try JSONSerialization.data(
                    withJSONObject: settings,
                    options: [.prettyPrinted, .sortedKeys]
                )
                try data.write(to: url, options: .atomic)
                self.logger.info("Claude Code settings updated with Clautch hooks")
            } catch {
                innerError = error
            }
        }

        if let error = coordinatorError { throw error }
        if let error = innerError { throw error }
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

    /// Pure-bash hook script — no Python dependency.
    private func inlineHookScript() -> String {
        """
        #!/bin/bash
        SOCKET="${CLAUTCH_SOCKET:-${TMPDIR}clautch.sock}"
        [ -S "$SOCKET" ] || exit 0

        EVENT=$(cat)
        [ -z "$EVENT" ] && exit 0

        if ! printf '%s' "$EVENT" | grep -q '"session_id"'; then
            SID="${CLAUDE_SESSION_ID:-unknown}"
            SID=$(printf '%s' "$SID" | tr -d '"\\\\/\\n\\r\\t')
            if [ "$EVENT" = "{}" ]; then
                EVENT="{\\"session_id\\":\\"${SID}\\"}"
            else
                EVENT=$(printf '%s' "$EVENT" | sed "s/^{/{\\\"session_id\\\":\\\"${SID}\\\",/")
            fi
        fi

        printf '%s' "$EVENT" | nc -U -w 1 "$SOCKET" >/dev/null 2>&1 || true
        exit 0
        """
    }
}
