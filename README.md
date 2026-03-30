# Clautch

A macOS notch companion for dev teams. Pixel-art creatures live in your MacBook's notch and react to your Claude Code activity in real time. Create a room, share the code with your team, and watch everyone's creatures come alive.

## Features

- **Notch creatures** — animated pixel-art pets that live in the MacBook notch
- **Claude Code integration** — creatures react to your coding activity (thinking, working, idle)
- **Team rooms** (coming soon) — share a room code and see your teammates' creatures
- **Customizable** (coming soon) — pick your creature type, colors, and accessories

## Requirements

- macOS 14.0+ (Sonoma)
- MacBook with a notch (M1 Pro/Max 2021+, M2+ Air/Pro)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed

## Building

```bash
# Install xcodegen if you don't have it
brew install xcodegen

# Generate Xcode project and build
xcodegen generate
xcodebuild -scheme Clautch -configuration Debug build
```

Or open `Clautch.xcodeproj` in Xcode and hit Run.

## How it works

1. On launch, Clautch installs a hook into Claude Code (`~/.claude/hooks/clautch-hook.sh`)
2. When Claude Code is active, events flow through a Unix socket to the app
3. Your creature reacts: thinking, working, idle, sleeping, compacting
4. A ghost icon appears in the menu bar for quick access

## License

MIT
