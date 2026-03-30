#!/bin/bash
# Clautch hook — forwards Claude Code events to the Clautch app via Unix socket.
# Installed automatically by Clautch into ~/.claude/hooks/

SOCKET="/tmp/clautch.sock"

# If the app isn't running (no socket), exit silently.
[ -S "$SOCKET" ] || exit 0

# Read the event JSON from stdin.
EVENT=$(cat)

# Forward to the socket via python3 (available on all modern macOS).
python3 -c "
import socket, sys, json, os

raw = '''${EVENT}'''
try:
    event = json.loads(raw)
except Exception:
    sys.exit(0)

# Ensure session_id is present.
if 'session_id' not in event:
    event['session_id'] = os.environ.get('CLAUDE_SESSION_ID', 'unknown')

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    sock.connect('${SOCKET}')
    sock.sendall(json.dumps(event).encode())
except Exception:
    pass
finally:
    sock.close()
" 2>/dev/null

exit 0
