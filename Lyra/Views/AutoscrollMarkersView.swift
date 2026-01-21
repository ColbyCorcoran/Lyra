//
//  AutoscrollMarkersView.swift
//  Lyra
//
//  Manage smart pause markers for autoscroll
//

import SwiftUI
import SwiftData

struct AutoscrollMarkersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song

    @State private var markers: [AutoscrollMarker] = []
    @State private var showAddMarker: Bool = false
    @State private var editingMarker: AutoscrollMarker? = nil
    @State private var hasChanges: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Visual timeline
                if !markers.isEmpty {
                    markerTimeline
                        .padding()
                        .background(Color(.systemGray6))
                }

                // Markers list
                Form {
                    if markers.isEmpty {
                        Section {
                            emptyState
                        }
                    } else {
                        Section {
                            ForEach(markers.sorted(by: { $0.progress < $1.progress })) { marker in
                                markerRow(marker)
                            }
                            .onDelete(perform: deleteMarkers)
                        } header: {
                            Text("Markers")
                        } footer: {
                            Text("Autoscroll will pause at these positions. Drag markers to reorder.")
                        }
                    }

                    // Add Marker
                    Section {
                        Button {
                            showAddMarker = true
                        } label: {
                            Label("Add Marker", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Info
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Use markers to automatically pause at specific points in the song, like before a key change or difficult section.")
                                .font(.caption)
                        }
                    } header: {
                        Text("About Markers")
                    }
                }
            }
            .navigationTitle("Autoscroll Markers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMarkers()
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
            }
            .sheet(isPresented: $showAddMarker) {
                AddMarkerView(markers: $markers, hasChanges: $hasChanges)
            }
            .sheet(item: $editingMarker) { marker in
                EditMarkerView(marker: Binding(
                    get: { marker },
                    set: { updatedMarker in
                        if let index = markers.firstIndex(where: { $0.id == marker.id }) {
                            markers[index] = updatedMarker
                            hasChanges = true
                        }
                    }
                ))
            }
            .onAppear {
                loadMarkers()
            }
        }
    }

    // MARK: - Marker Timeline

    private var markerTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(height: 8)

                    // Markers
                    ForEach(markers) { marker in
                        VStack(spacing: 4) {
                            // Marker line
                            Rectangle()
                                .fill(markerColor(for: marker.action))
                                .frame(width: 2, height: 20)

                            // Marker dot
                            Circle()
                                .fill(markerColor(for: marker.action))
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )

                            // Label
                            Text(marker.name)
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(markerColor(for: marker.action).opacity(0.2))
                                )
                        }
                        .offset(x: geometry.size.width * marker.progress - 6)
                    }
                }
                .frame(height: 60)
            }
            .frame(height: 60)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.circle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("No Markers")
                    .font(.headline)

                Text("Add markers to pause at specific points during autoscroll")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Marker Row

    @ViewBuilder
    private func markerRow(_ marker: AutoscrollMarker) -> some View {
        Button {
            editingMarker = marker
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(markerColor(for: marker.action).opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: markerIcon(for: marker.action))
                        .foregroundStyle(markerColor(for: marker.action))
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(marker.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                .font(.caption2)
                            Text("\(Int(marker.progress * 100))%")
                                .font(.caption)
                                .monospacedDigit()
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "tag")
                                .font(.caption2)
                            Text(marker.action.displayName)
                                .font(.caption)
                        }

                        if let duration = marker.pauseDuration {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.caption2)
                                Text("\(Int(duration))s")
                                    .font(.caption)
                            }
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func deleteMarkers(at offsets: IndexSet) {
        markers.remove(atOffsets: offsets)
        hasChanges = true
        HapticManager.shared.notification(.warning)
    }

    private func saveMarkers() {
        // Save markers to song configuration
        var config = song.autoscrollConfiguration ?? AdvancedAutoscrollConfig()
        config.markers = markers

        song.autoscrollConfiguration = config
        song.modifiedAt = Date()

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Failed to save markers: \(error)")
            HapticManager.shared.operationFailed()
        }
    }

    private func loadMarkers() {
        // Load markers from song configuration
        if let config = song.autoscrollConfiguration {
            markers = config.markers
        }
    }

    // MARK: - Visual Helpers

    private func markerColor(for action: MarkerAction) -> Color {
        switch action {
        case .pause: return .orange
        case .speedChange: return .blue
        case .notification: return .green
        }
    }

    private func markerIcon(for action: MarkerAction) -> String {
        switch action {
        case .pause: return "pause.circle.fill"
        case .speedChange: return "gauge.with.dots.needle.67percent"
        case .notification: return "bell.fill"
        }
    }
}

// MARK: - Add Marker View

struct AddMarkerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var markers: [AutoscrollMarker]
    @Binding var hasChanges: Bool

    @State private var name: String = ""
    @State private var progress: Double = 0.5
    @State private var action: MarkerAction = .pause
    @State private var pauseDuration: Double? = 3.0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Marker Name", text: $name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give this marker a descriptive name, e.g. 'Key Change' or 'Chorus Start'")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Position: \(Int(progress * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Slider(value: $progress, in: 0...1, step: 0.01)
                    }
                } header: {
                    Text("Position")
                } footer: {
                    Text("Where in the song should this marker trigger")
                }

                Section {
                    Picker("Action", selection: $action) {
                        ForEach(MarkerAction.allCases, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    .pickerStyle(.segmented)

                    if action == .pause {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Auto-resume")
                                .font(.subheadline)

                            Picker("Duration", selection: Binding(
                                get: { pauseDuration ?? -1 },
                                set: { pauseDuration = $0 >= 0 ? $0 : nil }
                            )) {
                                Text("Manual Resume").tag(-1.0)
                                Text("1 second").tag(1.0)
                                Text("2 seconds").tag(2.0)
                                Text("3 seconds").tag(3.0)
                                Text("5 seconds").tag(5.0)
                                Text("10 seconds").tag(10.0)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                } header: {
                    Text("Action")
                } footer: {
                    if action == .pause {
                        Text("Autoscroll will pause at this marker. Choose manual resume or set an auto-resume duration.")
                    } else if action == .speedChange {
                        Text("Playback speed will change at this marker")
                    } else {
                        Text("A notification will be shown at this marker")
                    }
                }
            }
            .navigationTitle("Add Marker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addMarker()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func addMarker() {
        let marker = AutoscrollMarker(
            name: name,
            progress: progress,
            pauseDuration: pauseDuration,
            action: action
        )

        markers.append(marker)
        hasChanges = true

        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Edit Marker View

struct EditMarkerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var marker: AutoscrollMarker

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Marker Name", text: $marker.name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Name")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Position: \(Int(marker.progress * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Slider(value: $marker.progress, in: 0...1, step: 0.01)
                    }
                } header: {
                    Text("Position")
                }

                Section {
                    Picker("Action", selection: $marker.action) {
                        ForEach(MarkerAction.allCases, id: \.self) { action in
                            Text(action.displayName).tag(action)
                        }
                    }
                    .pickerStyle(.segmented)

                    if marker.action == .pause {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Auto-resume")
                                .font(.subheadline)

                            Picker("Duration", selection: Binding(
                                get: { marker.pauseDuration ?? -1 },
                                set: { marker.pauseDuration = $0 >= 0 ? $0 : nil }
                            )) {
                                Text("Manual Resume").tag(-1.0)
                                Text("1 second").tag(1.0)
                                Text("2 seconds").tag(2.0)
                                Text("3 seconds").tag(3.0)
                                Text("5 seconds").tag(5.0)
                                Text("10 seconds").tag(10.0)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                } header: {
                    Text("Action")
                }
            }
            .navigationTitle("Edit Marker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let container = PreviewContainer.shared.container
    let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!

    return AutoscrollMarkersView(song: song)
        .modelContainer(container)
}
