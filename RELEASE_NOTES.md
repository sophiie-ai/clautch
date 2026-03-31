## What's New

### Security
- **Invite tokens for rooms** — Rooms now require a cryptographic invite token to join. Room codes are shared as `CODE-TOKEN` format (e.g. `HK3WPR-a8Bf2kQ9xLmN3pRsT7wY`). Guessing the 6-character code alone is no longer enough to join a room. Existing rooms without tokens continue to work.
- **Socket UID verification** — The Unix socket now verifies connecting processes belong to the same user via `getpeereid()`, preventing other local users from sending spoofed events.
- **Symlink protection** — The hook installer validates that `~/.claude/settings.json` is not a symlink and is owned by the current user before writing.
- **Hardened entitlements** — Explicitly disabled unsigned executable memory and library validation bypass in release builds.

### Performance
- **Concurrent CloudKit sync** — Room presence heartbeat and peer fetching now run in parallel, halving the network latency per sync cycle.

### Improvements
- **Updated release tooling** — Release script now supports hand-written release notes via a notes file parameter.
