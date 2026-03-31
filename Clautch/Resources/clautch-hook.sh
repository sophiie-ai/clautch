#!/bin/bash
# Clautch hook — forwards Claude Code events to the Clautch app via Unix socket.
# Installed automatically by Clautch into ~/.claude/hooks/

# Socket path uses macOS per-user TMPDIR for security (not world-writable /tmp).
SOCKET="${CLAUTCH_SOCKET:-${TMPDIR}clautch.sock}"

# If the app isn't running (no socket), exit silently.
[ -S "$SOCKET" ] || exit 0

# Read the event JSON from stdin.
EVENT=$(cat)
[ -z "$EVENT" ] && exit 0

# Inject session_id from environment if not present in the event.
# Use jq if available for safe JSON manipulation, otherwise use grep+sed carefully.
if ! printf '%s' "$EVENT" | grep -q '"session_id"'; then
    SID="${CLAUDE_SESSION_ID:-unknown}"
    # Sanitize SID: strip any characters that could break JSON (quotes, backslashes, control chars)
    SID=$(printf '%s' "$SID" | tr -d '"\\/\n\r\t')
    EVENT=$(printf '%s' "$EVENT" | sed "s/^{/{\"session_id\":\"${SID}\",/")
fi

# Send to Clautch via Unix socket using nc (no Python startup overhead).
printf '%s' "$EVENT" | nc -U "$SOCKET" 2>/dev/null
exit 0
