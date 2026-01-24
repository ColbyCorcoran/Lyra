//
//  ChordDetectionView.swift
//  Lyra
//
//  Main view for AI-powered chord detection from audio files
//  Part of Phase 7: Audio Intelligence
//

import SwiftUI
import UniformTypeIdentifiers

struct ChordDetectionView: View {

    // MARK: - Properties

    @State private var engine = ChordDetectionEngine.shared
    @State private var showFilePicker = false
    @State private var selectedQuality: DetectionQuality = .balanced
    @State private var isAnalyzing = false
    @State private var progress: Float = 0
    @State private var currentStatus: DetectionStatus = .pending
    @State private var session: ChordDetectionSession?
    @State private var showQualityPicker = false
    @State private var showExportOptions = false

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Quality Settings
                    qualitySection

                    // File Import
                    if session == nil && !isAnalyzing {
                        importSection
                    }

                    // Analysis Progress
                    if isAnalyzing {
                        progressSection
                    }

                    // Results
                    if let session = session, !isAnalyzing {
                        resultsSection(session)
                    }
                }
                .padding()
            }
            .navigationTitle("Chord Detection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if let session = session, !isAnalyzing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                exportToChordPro()
                            } label: {
                                Label("Export as ChordPro", systemImage: "square.and.arrow.up")
                            }

                            Button {
                                createSongFromDetection()
                            } label: {
                                Label("Create Song", systemImage: "music.note.list")
                            }

                            Button(role: .destructive) {
                                resetSession()
                            } label: {
                                Label("Start Over", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)

            Text("AI Chord Detection")
                .font(.title2)
                .fontWeight(.bold)

            Text("Upload a song and Lyra will automatically detect chords, tempo, and song structure.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Quality Section

    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Quality")
                .font(.headline)

            Picker("Quality", selection: $selectedQuality) {
                ForEach(DetectionQuality.allCases, id: \.self) { quality in
                    Label(quality.rawValue, systemImage: quality.icon)
                        .tag(quality)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isAnalyzing)

            Text(selectedQuality.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Import Section

    private var importSection: some View {
        VStack(spacing: 16) {
            Button {
                showFilePicker = true
            } label: {
                Label("Import Audio File", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }

            Text("Supported formats: MP3, M4A, WAV")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Limitations
            VStack(alignment: .leading, spacing: 8) {
                Text("Important Notes:")
                    .font(.caption)
                    .fontWeight(.semibold)

                ForEach([
                    "AI isn't perfect - review detected chords",
                    "Works best with clear recordings",
                    "May struggle with heavy distortion/effects",
                    "Complex chords may be simplified"
                ], id: \.self) { note in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(note)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 20) {
            // Status Icon
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: progress)

                Image(systemName: currentStatus.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
            }

            // Status Text
            VStack(spacing: 8) {
                Text(currentStatus.rawValue)
                    .font(.headline)

                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress Bar
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(.blue)

            // Cancel Button
            Button(role: .destructive) {
                engine.cancelAnalysis()
                resetSession()
            } label: {
                Text("Cancel")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Results Section

    private func resultsSection(_ session: ChordDetectionSession) -> some View {
        VStack(spacing: 20) {
            // Summary Card
            summaryCard(session)

            // Detected Chords Timeline
            chordsTimeline(session)

            // Sections (if detected)
            if !session.sections.isEmpty {
                sectionsView(session)
            }

            // Low Confidence Warnings
            if session.lowConfidenceCount > 0 {
                lowConfidenceWarning(session)
            }
        }
    }

    private func summaryCard(_ session: ChordDetectionSession) -> some View {
        VStack(spacing: 16) {
            HStack {
                Label("Analysis Complete", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                Spacer()
            }

            Divider()

            // Metadata Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                infoItem(title: "Key", value: session.detectedKey ?? "Unknown", icon: "music.note")
                infoItem(title: "Tempo", value: session.formattedTempo, icon: "metronome")
                infoItem(title: "Time", value: session.timeSignature ?? "Unknown", icon: "clock")
                infoItem(title: "Capo", value: session.suggestedCapo.map { "Fret \($0)" } ?? "None", icon: "guitars")
                infoItem(title: "Chords", value: "\(session.detectedChords.count)", icon: "music.quarternote.3")
                infoItem(title: "Sections", value: "\(session.sections.count)", icon: "list.bullet")
            }

            Divider()

            HStack {
                Text("Average Confidence:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                ConfidenceBadge(confidence: session.averageConfidence)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func infoItem(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chordsTimeline(_ session: ChordDetectionSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Detected Chords")
                    .font(.headline)

                Spacer()

                Text("\(session.detectedChords.count) chords")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(session.detectedChords.enumerated()), id: \.element.id) { index, chord in
                        ChordCard(chord: chord, index: index)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func sectionsView(_ session: ChordDetectionSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Sections")
                .font(.headline)

            ForEach(session.sections) { section in
                SectionRow(section: section)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func lowConfidenceWarning(_ session: ChordDetectionSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.lowConfidenceCount) chords detected with low confidence")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Review and correct these chords before exporting")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            startAnalysis(url: url)

        case .failure(let error):
            print("File selection error: \(error)")
        }
    }

    private func startAnalysis(url: URL) {
        isAnalyzing = true
        progress = 0
        currentStatus = .analyzing

        Task {
            do {
                let detectedSession = try await engine.detectChords(
                    from: url,
                    quality: selectedQuality
                ) { prog, status in
                    await MainActor.run {
                        progress = prog
                        currentStatus = status
                    }
                }

                await MainActor.run {
                    session = detectedSession
                    isAnalyzing = false
                }

            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    print("Detection error: \(error)")
                }
            }
        }
    }

    private func exportToChordPro() {
        guard let chordProText = engine.exportToChordPro() else { return }
        // TODO: Show share sheet or save dialog
        print("ChordPro export:\n\(chordProText)")
    }

    private func createSongFromDetection() {
        guard let session = session else { return }
        // TODO: Create new song from detected chords
        print("Creating song from detection...")
    }

    private func resetSession() {
        session = nil
        isAnalyzing = false
        progress = 0
        currentStatus = .pending
    }
}

// MARK: - Supporting Views

struct ChordCard: View {
    let chord: DetectedChord
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(chord.chord)
                    .font(.title3)
                    .fontWeight(.bold)

                ConfidenceBadge(confidence: chord.confidence)
            }

            Text(chord.formattedPosition)
                .font(.caption)
                .foregroundStyle(.secondary)

            if chord.isUserCorrected {
                Label("Edited", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .frame(width: 120)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(chord.confidenceLevel.color.opacity(0.3), lineWidth: 2)
        )
    }
}

struct ConfidenceBadge: View {
    let confidence: Float

    private var level: ConfidenceLevel {
        switch confidence {
        case 0..<0.5: return .low
        case 0.5..<0.75: return .medium
        default: return .high
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.caption2)

            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(level.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(level.color.opacity(0.15))
        .cornerRadius(4)
    }
}

struct SectionRow: View {
    let section: DetectedSection

    var body: some View {
        HStack {
            Image(systemName: section.type.systemImage)
                .foregroundStyle(section.type.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(section.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(section.formattedDuration) • \(section.chordPattern.joined(separator: " - "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if section.isUserLabeled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    ChordDetectionView()
}
