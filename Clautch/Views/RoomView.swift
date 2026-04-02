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
        VStack(spacing: 12) {
            // Room code display
            if let room = roomManager.currentRoom {
                HStack(spacing: 8) {
                    Button(action: copyCode) {
                        HStack(spacing: 6) {
                            Text(room.roomCode)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                                .tracking(2)

                            Image(systemName: copiedCode ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy room invite code")
                    .accessibilityHint("Copies the room code and invite token to the clipboard")

                    Text(copiedCode ? "Copied!" : "Copy invite")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(peerList.count + 1) online")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            Divider()
                .padding(.horizontal, 20)

            // Peer list (compact)
            VStack(alignment: .leading, spacing: 6) {
                // Self
                if let profile = UserProfile.current {
                    peerRow(
                        name: "\(profile.displayName) (you)",
                        creature: profile.creatureType,
                        task: roomManager.localState?.task ?? .idle,
                        isLocal: true
                    )
                }

                // Remote peers
                ForEach(peerList, id: \.peerId) { peer in
                    peerRow(
                        name: peer.displayName,
                        creature: peer.creatureType,
                        task: peer.task,
                        isLocal: false
                    )
                }
            }
            .padding(.horizontal, 20)

            Divider()
                .padding(.horizontal, 20)

            // Activity feed
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if activityFeed.events.isEmpty {
                        Text("No activity yet")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(activityFeed.events) { event in
                            HStack(spacing: 6) {
                                Image(systemName: event.icon)
                                    .font(.system(size: 8))
                                    .foregroundStyle(eventColor(event.kind))
                                    .frame(width: 12)

                                if event.kind == .chat {
                                    Text("\(event.peerName): ")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.primary) +
                                    Text(event.text)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(event.text)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(event.timeAgo)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)

            // Chat input
            HStack(spacing: 8) {
                TextField("Send a message…", text: $chatInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(6)
                    .onSubmit { sendChat() }

                Button(action: sendChat) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(chatInput.isEmpty ? Color.secondary : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(chatInput.isEmpty)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Leave button
            Button(action: {
                Task {
                    activityFeed.clear()
                    await roomManager.leaveRoom()
                }
            }) {
                Text("Leave Room")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }

    private var peerList: [PeerState] {
        guard let profile = UserProfile.current else { return [] }
        return roomManager.peerStore.visiblePeers(excludingPeerId: profile.peerId)
    }

    private func peerRow(name: String, creature: CreatureType, task: CreatureTask, isLocal: Bool) -> some View {
        HStack(spacing: 10) {
            // Mini creature preview
            PixelCreatureView(
                type: creature,
                frame: 0,
                task: task,
                emotion: .neutral
            )
            .frame(width: 20, height: 20)

            Text(name)
                .font(.system(size: 13))
                .foregroundStyle(.primary)

            Spacer()

            Text(task.rawValue)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(taskColor(task).opacity(0.15))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(task.rawValue)")
    }

    private func taskColor(_ task: CreatureTask) -> Color {
        switch task {
        case .idle: return .gray
        case .working: return .blue
        case .thinking: return .yellow
        case .sleeping: return .purple
        case .compacting: return .red
        }
    }

    private func eventColor(_ kind: RoomEvent.Kind) -> Color {
        switch kind {
        case .chat:     return .blue
        case .join:     return .green
        case .leave:    return .orange
        case .reaction: return .yellow
        }
    }

    // MARK: - Disconnected

    private var disconnectedView: some View {
        VStack(spacing: 20) {
            Spacer()

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
            .disabled(isLoading)
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
                                .fill(joinCodeValid
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.3))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!joinCodeValid || isLoading)
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
        activityFeed.addChat(from: name, message: msg)
        chatInput = ""
    }

    private func copyCode() {
        guard let room = roomManager.currentRoom else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(room.shareableCode, forType: .string)
        copiedCode = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedCode = false
        }
    }
}
