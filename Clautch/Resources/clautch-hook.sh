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
if ! printf '%s' "$EVENT" | grep -q '"session_id"'; then
    SID="${CLAUDE_SESSION_ID:-unknown}"
    # Sanitize SID: strip characters that could break JSON.
    SID=$(printf '%s' "$SID" | tr -d '"\\/\n\r\t')
    if [ "$EVENT" = "{}" ]; then
        EVENT="{\"session_id\":\"${SID}\"}"
    else
        EVENT=$(printf '%s' "$EVENT" | sed "s/^{/{\"session_id\":\"${SID}\",/")
    fi
fi

# Fire-and-forget: redirect all streams so nothing leaks into Claude Code's
# hook stdout (which it parses as JSON control output), and bound the call
# with -w 1 so a stalled Clautch can never block the session.
printf '%s' "$EVENT" | nc -U -w 1 "$SOCKET" >/dev/null 2>&1 || true
exit 0
