import SwiftUI

/// Room management view: create, join, or view current room.
struct RoomView: View {
    @State private var roomManager = RoomManager.shared
    @State private var joinCode = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var copiedCode = false
    @State private var chatInput = ""
    @State private var activityFeed = RoomActivityFeed.shared
    @State private var showKeychainAlert = false
    @State private var pendingAction: PendingRoomAction?
    @State private var iCloudAvailable: Bool?

    private enum PendingRoomAction {
        case create
        case join(String)
    }

    private static let keychainAcceptedKey = "com.clautch.keychainAccepted"
    private var keychainAccepted: Bool {
        UserDefaults.standard.bool(forKey: Self.keychainAcceptedKey)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Room")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                statusBadge
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            if roomManager.isInRoom {
                connectedView
            } else {
                disconnectedView
            }
        }
        .frame(minWidth: 300, minHeight: 350)
        .task {
            iCloudAvailable = await CloudKitService.shared.checkAvailability()
        }
        .onAppear {
            activityFeed.markAsRead()
        }
        .alert("Keychain Storage", isPresented: $showKeychainAlert) {
            Button("Allow") {
                UserDefaults.standard.set(true, forKey: Self.keychainAcceptedKey)
                executePendingAction()
            }
            Button("Cancel", role: .cancel) {
                pendingAction = nil
            }
        } message: {
            Text("Clautch stores room invite tokens in your macOS Keychain to keep them secure. The Keychain encrypts data at rest and protects it with your login password, so tokens are never stored in plain text.")
        }
    }

    // MARK: - Connected

    private var connectedView: some View {
        VStack(spacing: 0) {
            // Room header bar
            if let room = roomManager.currentRoom {
                HStack(spacing: 8) {
                    Button(action: copyCode) {
                        HStack(spacing: 6) {
                            Text(room.roomCode)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                                .tracking(2)

                            Image(systemName: copiedCode ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy room invite code")
                    .accessibilityHint("Copies the room code and invite token to the clipboard")

                    Text(copiedCode ? "Copied!" : "Copy invite")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Peer avatars row
                    HStack(spacing: -4) {
                        if let profile = UserProfile.current {
                            peerAvatar(creature: profile.creatureType, task: roomManager.localState?.task ?? .idle)
                        }
                        ForEach(peerList, id: \.peerId) { peer in
                            peerAvatar(creature: peer.creatureType, task: peer.task)
                        }
                    }

                    Text("\(peerList.count + 1)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider()

            // Chat messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        if activityFeed.events.isEmpty {
                            Text("No messages yet")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            let events = activityFeed.events
                            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                                if event.kind == .chat {
                                    chatBubble(for: event, previousEvent: index > 0 ? events[index - 1] : nil)
                                } else if event.kind == .sceneShare {
                                    sceneShareEvent(event)
                                } else {
                                    systemEvent(event)
                                }
                            }
                        }

                        // Anchor for auto-scroll
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: .infinity)
                .onChange(of: activityFeed.events.count) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }

            Divider()

            // iMessage-style input bar
            HStack(spacing: 6) {
                TextField("iMessage", text: $chatInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { sendChat() }
                    .onChange(of: chatInput) { _, newValue in
                        roomManager.setTyping(!newValue.isEmpty)
                    }

                Button(action: { roomManager.shareScene() }) {
                    Image(systemName: "paintbrush")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share your scene")
                .help("Share your current scene with the room")

                Button(action: sendChat) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(chatInput.isEmpty ? Color.secondary.opacity(0.4) : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(chatInput.isEmpty)
                .accessibilityLabel("Send message")
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.06))
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Leave button
            Button(action: {
                Task {
                    activityFeed.clear()
                    await roomManager.leaveRoom()
                }
            }) {
                Text("Leave Room")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Chat Bubble

    /// iMessage-style chat bubble: blue/right for local, gray/left for remote.
    private func chatBubble(for event: RoomEvent, previousEvent: RoomEvent?) -> some View {
        let isLocal = event.isLocal
        let showSender = !isLocal && (previousEvent?.kind != .chat || previousEvent?.peerName != event.peerName || previousEvent?.isLocal == true)

        return VStack(alignment: isLocal ? .trailing : .leading, spacing: 2) {
            if showSender {
                Text(event.peerName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
            }

            HStack(alignment: .bottom, spacing: 4) {
                if isLocal { Spacer(minLength: 40) }

                if isLocal {
                    Text(event.timeAgo)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 4)
                }

                Text(event.text)
                    .font(.system(size: 13))
                    .foregroundStyle(isLocal ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isLocal ? Color.accentColor : Color.primary.opacity(0.1))
                    )

                if !isLocal {
                    Text(event.timeAgo)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 4)
                    Spacer(minLength: 40)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: isLocal ? .trailing : .leading)
        .padding(.vertical, 1)
    }

    /// Scene share event with an Apply button for non-local users.
    private func sceneShareEvent(_ event: RoomEvent) -> some View {
        let theme = event.sceneThemeRaw.flatMap { SceneTheme(rawValue: $0) }
        let isCurrentScene = theme == (UserProfile.current?.sceneTheme ?? .meadow)

        return VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "paintbrush")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text(event.text)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            if let theme, !event.isLocal {
                Button(action: { applyScene(theme) }) {
                    Text(isCurrentScene ? "Applied" : "Apply")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isCurrentScene ? .secondary : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(isCurrentScene)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 4)
    }

    /// Centered, muted system event (join/leave/reaction).
    private func systemEvent(_ event: RoomEvent) -> some View {
        HStack(spacing: 4) {
            Image(systemName: event.icon)
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
            Text(event.text)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 4)
    }

    // MARK: - Peer Avatar

    private func peerAvatar(creature: CreatureType, task: CreatureTask) -> some View {
        PixelCreatureView(
            type: creature,
            frame: 0,
            task: task,
            emotion: .neutral
        )
        .frame(width: 18, height: 18)
        .background(Circle().fill(Color.primary.opacity(0.06)))
        .clipShape(Circle())
    }

    private var peerList: [PeerState] {
        guard let profile = UserProfile.current else { return [] }
        return roomManager.peerStore.visiblePeers(excludingPeerId: profile.peerId)
    }

    // MARK: - Disconnected

    private var disconnectedView: some View {
        VStack(spacing: 20) {
            Spacer()

            if iCloudAvailable == false {
                iCloudUnavailableBanner
            }

            // Create room
            Button(action: {
                if keychainAccepted {
                    performCreate()
                } else {
                    pendingAction = .create
                    showKeychainAlert = true
                }
            }) {
                Label("Create Room", systemImage: "plus.circle.fill")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isLoading || iCloudAvailable == false)
            .opacity(iCloudAvailable == false ? 0.5 : 1)
            .padding(.horizontal, 20)

            // Divider with "or"
            HStack {
                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                Text("or").font(.system(size: 12)).foregroundStyle(.secondary)
                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
            }
            .padding(.horizontal, 20)

            // Join room — accepts "CODE" or "CODE-TOKEN" invite format
            VStack(spacing: 10) {
                TextField("Paste invite code", text: $joinCode)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(10)

                Button(action: {
                    if keychainAccepted {
                        performJoin(joinCode)
                    } else {
                        pendingAction = .join(joinCode)
                        showKeychainAlert = true
                    }
                }) {
                    Text("Join Room")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(joinCodeValid && iCloudAvailable != false
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.3))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!joinCodeValid || isLoading || iCloudAvailable == false)
            }
            .padding(.horizontal, 20)

            // Error
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
            }

            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }

            Spacer()
        }
    }

    private var iCloudUnavailableBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.icloud")
                .font(.system(size: 16))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("iCloud Required")
                    .font(.system(size: 12, weight: .semibold))
                Text("Sign in to iCloud in System Settings to use rooms.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open Settings") {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane")!
                )
            }
            .font(.system(size: 11, weight: .medium))
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.08))
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(roomManager.status.label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch roomManager.status {
        case .connected:     return .green
        case .connecting:    return .yellow
        case .reconnecting:  return .orange
        case .disconnected:  return .gray
        case .error:         return .red
        }
    }

    /// The join input is valid if it contains a 6 or 8-char code.
    private var joinCodeValid: Bool {
        let (code, _) = RoomInfo.parse(shareableCode: joinCode)
        return code.count == 6 || code.count == 8
    }

    // MARK: - Actions

    private func performCreate() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await roomManager.createRoom()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func performJoin(_ code: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await roomManager.joinRoom(shareableCode: code)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func executePendingAction() {
        guard let action = pendingAction else { return }
        pendingAction = nil
        switch action {
        case .create:
            performCreate()
        case .join(let code):
            performJoin(code)
        }
    }

    private func sendChat() {
        let msg = chatInput.trimmingCharacters(in: .whitespaces)
        guard !msg.isEmpty else { return }
        let name = UserProfile.current?.displayName ?? "You"
        roomManager.sendChat(msg)
        activityFeed.addChat(from: name, message: msg, isLocal: true)
        NotificationService.shared.playSound(.chatSent)
        chatInput = ""
    }

    private func applyScene(_ theme: SceneTheme) {
        guard var profile = UserProfile.current else { return }
        profile.sceneTheme = theme
        UserProfile.current = profile
        UserDefaults.standard.set(theme.rawValue, forKey: "com.clautch.sceneTheme")
    }

    private func copyCode() {
        guard let room = roomManager.currentRoom else { return }
        let deepLink = "clautch://join/\(room.shareableCode)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(deepLink, forType: .string)
        copiedCode = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedCode = false
        }
    }
}
