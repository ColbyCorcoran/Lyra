//
//  SongInfoView.swift
//  Lyra
//
//  Displays comprehensive metadata about a song
//

import SwiftUI

struct SongInfoView: View {
    let song: Song
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Basic Info
                Section {
                    InfoRow(label: "Title", value: song.title)

                    if let artist = song.artist {
                        InfoRow(label: "Artist", value: artist)
                    }

                    if let originalKey = song.originalKey {
                        InfoRow(label: "Original Key", value: originalKey)
                    }

                    if song.transposeAmount != 0 {
                        InfoRow(label: "Transposed", value: "\(song.transposeAmount > 0 ? "+" : "")\(song.transposeAmount) semitones")

                        if let currentKey = song.currentKey {
                            InfoRow(label: "Current Key", value: currentKey)
                        }
                    }

                    if let capo = song.capoPosition, capo > 0 {
                        InfoRow(label: "Capo Position", value: "Fret \(capo)")
                    }
                } header: {
                    Text("Song Details")
                }

                // Musical Info
                Section {
                    if let tempo = song.tempo {
                        InfoRow(label: "Tempo", value: "\(tempo) BPM")
                    }

                    if let timeSignature = song.timeSignature {
                        InfoRow(label: "Time Signature", value: timeSignature)
                    }

                    InfoRow(label: "Format", value: song.contentFormat.displayName)
                } header: {
                    Text("Musical Information")
                }

                // Metadata
                Section {
                    InfoRow(label: "Created", value: song.createdAt.formatted(date: .long, time: .shortened))

                    InfoRow(label: "Modified", value: song.modifiedAt.formatted(date: .long, time: .shortened))

                    if let lastPerformed = song.lastPerformedDate {
                        InfoRow(label: "Last Performed", value: lastPerformed.formatted(date: .abbreviated, time: .omitted))
                    }

                    if song.performanceCount > 0 {
                        InfoRow(label: "Performance Count", value: "\(song.performanceCount)")
                    }
                } header: {
                    Text("History")
                }

                // Content Stats
                Section {
                    InfoRow(label: "Characters", value: "\(song.content.count)")

                    let lineCount = song.content.components(separatedBy: .newlines).count
                    InfoRow(label: "Lines", value: "\(lineCount)")

                    let chordMatches = song.content.matches(of: /\[([A-G][#b♯♭]?(?:maj|min|m|sus|aug|dim|add)?[0-9]*(?:\/[A-G][#b♯♭]?)?)\]/)
                    InfoRow(label: "Chords", value: "\(chordMatches.count)")
                } header: {
                    Text("Content Statistics")
                }

                // Tags
                if let tags = song.tags, !tags.isEmpty {
                    Section {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    } header: {
                        Text("Tags")
                    }
                }

                // Notes
                if let notes = song.notes, !notes.isEmpty {
                    Section {
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Notes")
                    }
                }

                // Display Settings
                if let displaySettings = song.displaySettings {
                    Section {
                        InfoRow(label: "Font Size", value: "\(Int(displaySettings.fontSize)) pt")

                        InfoRow(label: "Spacing", value: "\(Int(displaySettings.spacing)) pt")

                        HStack {
                            Text("Chord Color")
                                .font(.subheadline)
                            Spacer()
                            Circle()
                                .fill(Color(hex: displaySettings.chordColor) ?? .blue)
                                .frame(width: 20, height: 20)
                        }

                        HStack {
                            Text("Lyrics Color")
                                .font(.subheadline)
                            Spacer()
                            Circle()
                                .fill(Color(hex: displaySettings.lyricsColor) ?? .primary)
                                .frame(width: 20, height: 20)
                        }
                    } header: {
                        Text("Display Settings")
                    }
                }
            }
            .navigationTitle("Song Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Flow Layout (Already defined in HelpView, but redefined here for completeness)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    SongInfoView(song: Song(
        title: "Amazing Grace",
        artist: "John Newton",
        content: "[G]Amazing grace, how [C]sweet the [G]sound",
        contentFormat: .chordPro,
        originalKey: "G"
    ))
}
