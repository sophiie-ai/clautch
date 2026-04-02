# Clautch

A macOS notch companion for dev teams. Pixel-art creatures live in your MacBook's notch and react to your Claude Code activity in real time. Create a room, share the code with your team, and watch everyone's creatures come alive.

<!-- ![Clautch Screenshot](docs/screenshot.png) -->

## Features

- **Dynamic Island notch panel** — click the notch to expand, click again to collapse
- **Claude Code integration** — creature reacts in real time: thinking, working, sleeping, compacting
- **Visual state effects** — thought bubbles, sparkle particles, floating z's, pulsing warnings
- **Emotions** — creature shows happy/sad reactions based on tool success or failure
- **Team rooms** — CloudKit-backed rooms with 8-char codes and invite tokens; see teammates' creatures
- **Chat & reactions** — send messages and pixel-art reactions to teammates via the room
- **Activity feed** — scrollable history of joins, leaves, chats, and reactions in the room view
- **Push updates** — CloudKit subscriptions for near-real-time peer sync
- **Peer signing** — Ed25519 signatures prevent impersonation in rooms
- **Keychain storage** — room invite tokens stored securely in macOS Keychain
- **Day/night sky** — time-of-day sky gradient with sunrise, sunset, and stars
- **Creature interactions** — creatures face toward each other, idle yawns and look-arounds
- **Session tracking** — menu bar shows active sessions with state icons
- **Usage stats** — daily and weekly session time with a bar chart
- **Settings window** — tabbed preferences for display, notifications, and general options
- **Notifications** — optional macOS alerts on session complete or tool errors
- **Accessibility** — VoiceOver labels on creatures, controls, and onboarding elements
- **Launch at Login** — one-click toggle in Settings
- **Auto-updates** — Sparkle integration for seamless updates
- **6 creature types** — Ghost, Cat, Robot, Mushroom, Slime, Owl
- **Color presets** — Sky, Rose, Mint, Lavender, Lemon, Coral

## Requirements

- macOS 14.0+ (Sonoma)
- MacBook with a notch (M1 Pro/Max 2021+, M2+ Air/Pro)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed

## Install

### From DMG

Download the latest release from [Releases](https://github.com/sophiie-ai/clautch/releases), open the DMG, and drag Clautch to Applications.

### Build from source

```bash
# Prerequisites: Xcode 16+, xcodegen
brew install xcodegen

# Clone and build
git clone https://github.com/sophiie-ai/clautch.git
cd clautch
xcodegen generate
xcodebuild -scheme Clautch -configuration Debug build -allowProvisioningUpdates

# Or open in Xcode
open Clautch.xcodeproj
```

## How it works

### Architecture

```
Claude Code ──> Hook Scripts ──> Unix Socket ──> State Machine ──> Animated Sprites
                                                      │
                                                      └──> CloudKit ──> Room Peers
```

### Event pipeline

1. On launch, Clautch installs hooks into `~/.claude/settings.json`
2. Each Claude Code event triggers the hook script at `~/.claude/hooks/clautch-hook.sh`
3. The hook sends JSON over a Unix socket (`/tmp/clautch.sock`) to the app
4. The state machine maps events to creature states:

| Claude Code Event | Creature State |
|---|---|
| `UserPromptSubmit` | Thinking (yellow dots) |
| `PreToolUse` | Working (cyan sparkles) |
| `PostToolUse` | Thinking + emotion (happy/sad) |
| `PreCompact` | Compacting (pulse + warning) |
| `Stop` | Idle (wandering) |
| `SessionEnd` | Sleeping (floating z's) |

### Hooks

Clautch registers hooks for 8 Claude Code events. The hook script is pure bash with no Python dependency:

```bash
#!/bin/bash
SOCKET="/tmp/clautch.sock"
[ -S "$SOCKET" ] || exit 0
EVENT=$(cat)
echo "$EVENT" | nc -U "$SOCKET" 2>/dev/null
exit 0
```

Hooks auto-repair every 60 seconds if removed or overwritten.

### Rooms

Create a room from the menu bar → Room. Share the invite code with teammates. Each person's creature appears on everyone's notch island, reflecting their Claude Code activity in real time.

- **8-character room codes** with cryptographic invite tokens for secure access
- **Invite tokens** stored in macOS Keychain (you'll be prompted on first use)
- **Peer signing** via Ed25519 prevents others from impersonating your creature
- **Push notifications** via CloudKit subscriptions for near-real-time updates (polling fallback)
- **Auto-expiry** cleans up rooms with no active peers after 2 hours
- **Offline handling** — graceful reconnection when CloudKit is temporarily unreachable

Powered by CloudKit — no server required.

## Menu bar

The ghost icon in the menu bar provides:

- Active session list with state icons (brain, hammer, moon, etc.)
- Room management (create/join/leave, copy invite code, send reactions)
- Usage stats (today + this week)
- Creature customization
- Settings (Cmd+,) — display, notifications, and general preferences
- Check for Updates

## Development

```bash
# Generate project
xcodegen generate

# Build debug
xcodebuild -scheme Clautch -configuration Debug build -allowProvisioningUpdates

# Build release DMG
./scripts/build-dmg.sh

# Notarize (requires notarytool profile)
NOTARIZE=1 ./scripts/build-dmg.sh
```

### Project structure

```
Clautch/
├── AppDelegate.swift          # App lifecycle, window management
├── ClautchApp.swift           # SwiftUI entry point
├── Core/                      # Notch panel infrastructure
├── Views/                     # SwiftUI views + pixel creature renderer
├── Models/                    # Data models (sessions, creatures, events)
├── Services/                  # Hook installer, socket server, state machine
├── Networking/                # CloudKit rooms + peer sync
└── Resources/                 # Assets, hook script
```

## License

MIT
