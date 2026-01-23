//
//  MIDIControlMappingView.swift
//  Lyra
//
//  UI for managing MIDI control mappings to app functions
//

import SwiftUI

struct MIDIControlMappingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var controlManager = MIDIControlManager.shared

    @State private var selectedMapping: MIDIControlMapping?
    @State private var showAddSheet = false
    @State private var showPresetsSheet = false
    @State private var showEditSheet = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if controlManager.mappings.isEmpty {
                    emptyState
                } else {
                    mappingsList
                }
            }
            .navigationTitle("MIDI Control Mapping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showAddSheet = true
                        } label: {
                            Label("Add Mapping", systemImage: "plus")
                        }

                        Button {
                            showPresetsSheet = true
                        } label: {
                            Label("Load Preset", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button(role: .destructive) {
                            controlManager.removeAllMappings()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                        .disabled(controlManager.mappings.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search mappings")
            .sheet(isPresented: $showAddSheet) {
                MIDILearnView()
            }
            .sheet(isPresented: $showPresetsSheet) {
                MIDIPresetsView()
            }
            .sheet(item: $selectedMapping) { mapping in
                MIDIMappingEditView(mapping: binding(for: mapping))
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No MIDI Mappings", systemImage: "slider.horizontal.3")
        } description: {
            Text("Add MIDI control mappings to control Lyra functions with your MIDI controller")
        } actions: {
            Button {
                showAddSheet = true
            } label: {
                Text("Add Mapping")
            }
            .buttonStyle(.borderedProminent)

            Button {
                showPresetsSheet = true
            } label: {
                Text("Load Preset")
            }
            .buttonStyle(.bordered)
        }
    }

    private var mappingsList: some View {
        List {
            ForEach(filteredMappings.grouped()) { group in
                Section(group.category) {
                    ForEach(group.mappings) { mapping in
                        MIDIMappingRow(mapping: mapping)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedMapping = mapping
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    controlManager.removeMapping(mapping)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    var updatedMapping = mapping
                                    updatedMapping.enabled.toggle()
                                    controlManager.updateMapping(updatedMapping)
                                } label: {
                                    Label(
                                        mapping.enabled ? "Disable" : "Enable",
                                        systemImage: mapping.enabled ? "pause.circle" : "play.circle"
                                    )
                                }
                                .tint(mapping.enabled ? .orange : .green)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var filteredMappings: [MIDIControlMapping] {
        if searchText.isEmpty {
            return controlManager.mappings
        }
        return controlManager.mappings.filter { mapping in
            mapping.name.localizedCaseInsensitiveContains(searchText) ||
            mapping.action.displayName.localizedCaseInsensitiveContains(searchText) ||
            mapping.source.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func binding(for mapping: MIDIControlMapping) -> Binding<MIDIControlMapping> {
        Binding(
            get: {
                controlManager.mappings.first { $0.id == mapping.id } ?? mapping
            },
            set: { newValue in
                controlManager.updateMapping(newValue)
            }
        )
    }
}

// MARK: - MIDI Mapping Row

struct MIDIMappingRow: View {
    let mapping: MIDIControlMapping

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(mapping.enabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(mapping.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    // Source
                    Text(mapping.source.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("→")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    // Action
                    Text(mapping.action.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if mapping.action.acceptsContinuousValue {
                Image(systemName: "slider.horizontal.3")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if mapping.action.isToggle {
                Image(systemName: "switch.2")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .opacity(mapping.enabled ? 1.0 : 0.5)
    }
}

// MARK: - Grouped Mappings

extension Array where Element == MIDIControlMapping {
    func grouped() -> [MappingGroup] {
        let grouped = Dictionary(grouping: self) { $0.action.category }
        return grouped.map { category, mappings in
            MappingGroup(category: category, mappings: mappings.sorted { $0.name < $1.name })
        }
        .sorted { $0.category < $1.category }
    }
}

struct MappingGroup: Identifiable {
    let id = UUID()
    let category: String
    let mappings: [MIDIControlMapping]
}

// MARK: - MIDI Learn View

struct MIDILearnView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var controlManager = MIDIControlManager.shared

    @State private var selectedAction: MIDIActionType = .toggleAutoscroll
    @State private var isListening = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Action") {
                    Picker("Action", selection: $selectedAction) {
                        ForEach(MIDIActionType.allCases.grouped(), id: \.category) { group in
                            Section(group.category) {
                                ForEach(group.actions, id: \.self) { action in
                                    Text(action.displayName).tag(action)
                                }
                            }
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section {
                    if controlManager.isLearning {
                        learningState
                    } else if let learned = controlManager.learnedSource {
                        learnedState(learned)
                    } else {
                        readyState
                    }
                }

                Section("Description") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedAction.displayName)
                            .font(.headline)

                        if selectedAction.acceptsContinuousValue {
                            Label("Continuous control (0-127)", systemImage: "slider.horizontal.3")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if selectedAction.isToggle {
                            Label("Toggle action (on/off)", systemImage: "switch.2")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Label("Trigger action", systemImage: "bolt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Learn MIDI Control")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if controlManager.isLearning {
                            controlManager.stopLearning()
                        }
                        dismiss()
                    }
                }
            }
        }
    }

    private var readyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.tap")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Ready to Learn")
                .font(.headline)

            Text("Press the button below, then move a control on your MIDI device")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                controlManager.startLearning(for: selectedAction)
            } label: {
                Label("Start Learning", systemImage: "record.circle")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var learningState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.red)

            Text("Listening...")
                .font(.headline)
                .foregroundStyle(.red)

            Text("Move a MIDI control now")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                controlManager.stopLearning()
            } label: {
                Text("Cancel")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func learnedState(_ source: MIDIControlSource) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Mapping Created!")
                .font(.headline)

            Text(source.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("→")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text(selectedAction.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                dismiss()
            } label: {
                Text("Done")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Action Type Grouping

extension Array where Element == MIDIActionType {
    func grouped() -> [ActionGroup] {
        let grouped = Dictionary(grouping: self) { $0.category }
        return grouped.map { category, actions in
            ActionGroup(category: category, actions: actions.sorted { $0.displayName < $1.displayName })
        }
        .sorted { $0.category < $1.category }
    }
}

struct ActionGroup {
    let category: String
    let actions: [MIDIActionType]
}

// MARK: - MIDI Presets View

struct MIDIPresetsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var controlManager = MIDIControlManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in Presets") {
                    ForEach(controlManager.presets.filter { $0.isBuiltIn }) { preset in
                        PresetRow(preset: preset) {
                            controlManager.applyPreset(preset)
                            dismiss()
                        }
                    }
                }

                let customPresets = controlManager.presets.filter { !$0.isBuiltIn }
                if !customPresets.isEmpty {
                    Section("Custom Presets") {
                        ForEach(customPresets) { preset in
                            PresetRow(preset: preset) {
                                controlManager.applyPreset(preset)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("MIDI Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PresetRow: View {
    let preset: MIDIControlMappingPreset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(preset.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(preset.mappings.count) mappings")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - MIDI Mapping Edit View

struct MIDIMappingEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var mapping: MIDIControlMapping

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $mapping.name)

                    Toggle("Enabled", isOn: $mapping.enabled)
                }

                Section("Value Mapping") {
                    if mapping.action.acceptsContinuousValue {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Input Range (MIDI)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack {
                                TextField("Min", value: $mapping.minValue, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)

                                Text("to")
                                    .foregroundStyle(.secondary)

                                TextField("Max", value: $mapping.maxValue, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Output Range")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack {
                                TextField("Min", value: $mapping.minOutput, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)

                                Text("to")
                                    .foregroundStyle(.secondary)

                                TextField("Max", value: $mapping.maxOutput, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                            }
                        }

                        Picker("Curve", selection: $mapping.curve) {
                            ForEach(MIDIValueCurve.allCases, id: \.self) { curve in
                                VStack(alignment: .leading) {
                                    Text(curve.displayName)
                                    Text(curve.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .tag(curve)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    } else if mapping.action.isToggle {
                        Stepper("Toggle Threshold: \(mapping.toggleThreshold)", value: $mapping.toggleThreshold, in: 0...127)
                        Text("Values >= \(mapping.toggleThreshold) trigger ON")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Control Info") {
                    LabeledContent("Source", value: mapping.source.displayName)
                    LabeledContent("Action", value: mapping.action.displayName)
                    LabeledContent("Category", value: mapping.action.category)
                }
            }
            .navigationTitle("Edit Mapping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MIDIControlMappingView()
}
