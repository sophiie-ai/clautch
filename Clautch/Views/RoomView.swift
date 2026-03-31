import SwiftUI

/// Room management view: create, join, or view current room.
struct RoomView: View {
    @State private var roomManager = RoomManager.shared
    @State private var joinCode = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var copiedCode = false
    @State private var chatInput = ""

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
        .frame(width: 320, height: 380)
    }

    // MARK: - Connected

    private var connectedView: some View {
        VStack(spacing: 16) {
            // Room code display
            if let room = roomManager.currentRoom {
                VStack(spacing: 6) {
                    Text("Room Code")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Button(action: copyCode) {
                        HStack(spacing: 8) {
                            Text(room.roomCode)
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundStyle(.primary)
                                .tracking(4)

                            Image(systemName: copiedCode ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Text(copiedCode ? "Copied invite link!" : "Click to copy invite")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
            }

            Divider()
                .padding(.horizontal, 20)

            // Peer list
            VStack(alignment: .leading, spacing: 8) {
                Text("Team (\(peerList.count + 1))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

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

            Spacer()

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
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Leave button
            Button(action: {
                Task { await roomManager.leaveRoom() }
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
            .padding(.bottom, 16)
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

    // MARK: - Disconnected

    private var disconnectedView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Create room
            Button(action: {
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
                    isLoading = true
                    errorMessage = nil
                    Task {
                        do {
                            try await roomManager.joinRoom(shareableCode: joinCode)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isLoading = false
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
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    /// The join input is valid if it contains at least a 6-char code.
    private var joinCodeValid: Bool {
        let (code, _) = RoomInfo.parse(shareableCode: joinCode)
        return code.count == 6
    }

    // MARK: - Actions

    private func sendChat() {
        let msg = chatInput.trimmingCharacters(in: .whitespaces)
        guard !msg.isEmpty else { return }
        roomManager.sendChat(msg)
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
