//
//  MIDISceneView.swift
//  Lyra
//
//  UI for managing MIDI scenes for lighting, effects, and patches
//

import SwiftUI

struct MIDISceneView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var controlManager = MIDIControlManager.shared

    @State private var selectedScene: MIDIScene?
    @State private var showAddSheet = false
    @State private var showEditSheet = false
    @State private var executingScene: UUID?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if controlManager.sceneLibrary.scenes.isEmpty {
                    emptyState
                } else {
                    scenesList
                }
            }
            .navigationTitle("MIDI Scenes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search scenes")
            .sheet(isPresented: $showAddSheet) {
                MIDISceneEditView(scene: .constant(MIDIScene(name: "New Scene")), isNew: true)
            }
            .sheet(item: $selectedScene) { scene in
                MIDISceneEditView(scene: binding(for: scene), isNew: false)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No MIDI Scenes", systemImage: "wand.and.stars")
        } description: {
            Text("Create MIDI scenes to control lighting, effects, and patches")
        } actions: {
            Button {
                showAddSheet = true
            } label: {
                Text("Create Scene")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var scenesList: some View {
        List {
            ForEach(controlManager.sceneLibrary.categories) { category in
                let categoryScenes = filteredScenes.filter { scene in
                    category.sceneIDs.contains(scene.id)
                }

                if !categoryScenes.isEmpty {
                    Section {
                        ForEach(categoryScenes) { scene in
                            MIDISceneRow(
                                scene: scene,
                                isExecuting: executingScene == scene.id
                            ) {
                                executeScene(scene)
                            } onEdit: {
                                selectedScene = scene
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    controlManager.removeScene(scene)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.name)
                        }
                    }
                }
            }

            // Uncategorized scenes
            let uncategorizedScenes = filteredScenes.filter { scene in
                !controlManager.sceneLibrary.categories.contains { category in
                    category.sceneIDs.contains(scene.id)
                }
            }

            if !uncategorizedScenes.isEmpty {
                Section("Other") {
                    ForEach(uncategorizedScenes) { scene in
                        MIDISceneRow(
                            scene: scene,
                            isExecuting: executingScene == scene.id
                        ) {
                            executeScene(scene)
                        } onEdit: {
                            selectedScene = scene
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var filteredScenes: [MIDIScene] {
        if searchText.isEmpty {
            return controlManager.sceneLibrary.scenes
        }
        return controlManager.sceneLibrary.scenes.filter { scene in
            scene.name.localizedCaseInsensitiveContains(searchText) ||
            scene.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func executeScene(_ scene: MIDIScene) {
        executingScene = scene.id

        Task {
            await controlManager.executeScene(scene)
            executingScene = nil
        }
    }

    private func binding(for scene: MIDIScene) -> Binding<MIDIScene> {
        Binding(
            get: {
                controlManager.sceneLibrary.scenes.first { $0.id == scene.id } ?? scene
            },
            set: { newValue in
                controlManager.updateScene(newValue)
            }
        )
    }
}

// MARK: - MIDI Scene Row

struct MIDISceneRow: View {
    let scene: MIDIScene
    let isExecuting: Bool
    let onExecute: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: scene.color) ?? .blue)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(scene.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if !scene.description.isEmpty {
                    Text(scene.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    Label("\(scene.messageCount) msgs", systemImage: "envelope")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if scene.estimatedDuration > 0 {
                        Label(String(format: "%.1fs", scene.estimatedDuration), systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: onExecute) {
                    if isExecuting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(scene.enabled ? .blue : .gray)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!scene.enabled || isExecuting)
            }
        }
        .opacity(scene.enabled ? 1.0 : 0.5)
    }
}

// MARK: - MIDI Scene Edit View

struct MIDISceneEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var scene: MIDIScene
    let isNew: Bool

    @State private var controlManager = MIDIControlManager.shared
    @State private var showAddMessageSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $scene.name)

                    TextField("Description", text: $scene.description, axis: .vertical)
                        .lineLimit(2...4)

                    Toggle("Enabled", isOn: $scene.enabled)

                    Toggle("Send on Song Load", isOn: $scene.sendOnLoad)
                }

                Section("Appearance") {
                    ColorPicker("Color", selection: Binding(
                        get: { Color(hex: scene.color) ?? .blue },
                        set: { scene.color = $0.toHex() }
                    ))
                }

                Section("Timing") {
                    HStack {
                        Text("Delay between messages")
                        Spacer()
                        TextField("Delay", value: $scene.delay, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        Text("sec")
                            .foregroundStyle(.secondary)
                    }

                    Text("Estimated duration: \(String(format: "%.2f", scene.estimatedDuration))s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    ForEach(scene.messages) { message in
                        MIDISceneMessageRow(message: message)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    scene.messages.removeAll { $0.id == message.id }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onMove { from, to in
                        scene.messages.move(fromOffsets: from, toOffset: to)
                    }

                    Button {
                        showAddMessageSheet = true
                    } label: {
                        Label("Add Message", systemImage: "plus")
                    }
                } header: {
                    Text("MIDI Messages (\(scene.messages.count))")
                } footer: {
                    Text("Messages will be sent in order from top to bottom")
                }
            }
            .navigationTitle(isNew ? "New Scene" : "Edit Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Create" : "Save") {
                        if isNew {
                            controlManager.addScene(scene)
                        }
                        dismiss()
                    }
                    .disabled(scene.name.isEmpty)
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        Task {
                            await controlManager.executeScene(scene)
                        }
                    } label: {
                        Label("Test Scene", systemImage: "play.circle")
                    }
                    .disabled(scene.messages.isEmpty)
                }
            }
            .sheet(isPresented: $showAddMessageSheet) {
                MIDISceneMessageEditView { message in
                    scene.messages.append(message)
                }
            }
        }
    }
}

// MARK: - MIDI Scene Message Row

struct MIDISceneMessageRow: View {
    let message: MIDISceneMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForType(message.type))
                .font(.caption)
                .foregroundStyle(colorForType(message.type))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(message.displayName)
                    .font(.subheadline)

                Text("Channel \(message.channel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if message.delayAfter > 0 {
                Text("+\(String(format: "%.2f", message.delayAfter))s")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .opacity(message.enabled ? 1.0 : 0.5)
    }

    private func iconForType(_ type: MIDISceneMessageType) -> String {
        switch type {
        case .programChange: return "music.note"
        case .controlChange: return "slider.horizontal.3"
        case .noteOn: return "play.circle"
        case .noteOff: return "stop.circle"
        case .pitchBend: return "waveform.path.ecg"
        case .aftertouch: return "hand.tap"
        case .sysex: return "envelope"
        }
    }

    private func colorForType(_ type: MIDISceneMessageType) -> Color {
        switch type {
        case .programChange: return .blue
        case .controlChange: return .orange
        case .noteOn: return .green
        case .noteOff: return .red
        case .pitchBend: return .purple
        case .aftertouch: return .pink
        case .sysex: return .brown
        }
    }
}

// MARK: - MIDI Scene Message Edit View

struct MIDISceneMessageEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var messageType: MIDISceneMessageType = .controlChange
    @State private var channel: Int = 1
    @State private var controller: Int = 1
    @State private var value: Int = 64
    @State private var program: Int = 0
    @State private var note: Int = 60
    @State private var velocity: Int = 100
    @State private var delayAfter: Double = 0.0

    let onSave: (MIDISceneMessage) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Message Type") {
                    Picker("Type", selection: $messageType) {
                        ForEach(MIDISceneMessageType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Parameters") {
                    if messageType != .sysex {
                        Picker("Channel", selection: $channel) {
                            ForEach(1...16, id: \.self) { ch in
                                Text("Channel \(ch)").tag(ch)
                            }
                        }
                    }

                    switch messageType {
                    case .programChange:
                        Stepper("Program: \(program)", value: $program, in: 0...127)

                    case .controlChange:
                        Stepper("Controller: \(controller)", value: $controller, in: 0...127)
                        Stepper("Value: \(value)", value: $value, in: 0...127)

                    case .noteOn:
                        Stepper("Note: \(MIDIControlSource.noteName(for: note)) (\(note))", value: $note, in: 0...127)
                        Stepper("Velocity: \(velocity)", value: $velocity, in: 0...127)

                    case .noteOff:
                        Stepper("Note: \(MIDIControlSource.noteName(for: note)) (\(note))", value: $note, in: 0...127)

                    case .sysex:
                        Text("SysEx editing not yet implemented")
                            .foregroundStyle(.secondary)

                    case .pitchBend, .aftertouch:
                        Text("Coming soon")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Timing") {
                    HStack {
                        Text("Delay after message")
                        Spacer()
                        TextField("Delay", value: $delayAfter, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        Text("sec")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add MIDI Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let message = createMessage()
                        onSave(message)
                        dismiss()
                    }
                }
            }
        }
    }

    private func createMessage() -> MIDISceneMessage {
        switch messageType {
        case .programChange:
            return .programChange(program: program, channel: channel)

        case .controlChange:
            return .controlChange(controller: controller, value: value, channel: channel)

        case .noteOn:
            return .noteOn(note: note, velocity: velocity, channel: channel)

        case .noteOff:
            return .noteOff(note: note, channel: channel)

        case .sysex:
            return .sysex(data: [0xF0, 0xF7]) // Empty SysEx for now

        case .pitchBend:
            return MIDISceneMessage(type: .pitchBend, channel: channel, data: [0, 64])

        case .aftertouch:
            return MIDISceneMessage(type: .aftertouch, channel: channel, data: [64])
        }
    }
}

// MARK: - Color Extensions

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Preview

#Preview {
    MIDISceneView()
}
