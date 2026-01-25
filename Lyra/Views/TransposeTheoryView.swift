//
//  TransposeTheoryView.swift
//  Lyra
//
//  Educational view for music theory and key relationships
//  Part of Phase 7.9: Transpose Intelligence
//

import SwiftUI

struct TransposeTheoryView: View {
    let song: Song

    @State private var selectedKey: String

    private let circleOfFifths = ["C", "G", "D", "A", "E", "B", "F#/Gb", "Db", "Ab", "Eb", "Bb", "F"]

    init(song: Song) {
        self.song = song
        _selectedKey = State(initialValue: song.currentKey ?? song.originalKey ?? "C")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Key Section
                currentKeySection

                // Circle of Fifths
                circleOfFifthsSection

                // Key Signatures
                keySignaturesSection

                // Interval Reference
                intervalReferenceSection

                // Transpose Tips
                transposeTipsSection
            }
            .padding()
        }
        .navigationTitle("Music Theory")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Current Key Section

    private var currentKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note")
                    .foregroundStyle(.blue)
                Text("Current Song Key")
                    .font(.headline)
            }

            HStack {
                Text("Key:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("Key", selection: $selectedKey) {
                    ForEach(circleOfFifths, id: \.self) { key in
                        Text(key).tag(key)
                    }
                }
                .pickerStyle(.menu)
            }

            if let keyInfo = getKeyInfo(selectedKey) {
                VStack(alignment: .leading, spacing: 8) {
                    infoRow(label: "Key Signature", value: keyInfo.signature)
                    infoRow(label: "Relative Minor", value: keyInfo.relativeMinor)
                    infoRow(label: "Common Chords", value: keyInfo.commonChords.joined(separator: ", "))
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Circle of Fifths

    private var circleOfFifthsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundStyle(.purple)
                Text("Circle of Fifths")
                    .font(.headline)
            }

            Text("Keys arranged by musical relationships")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Visual circle (simplified)
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 2)
                    .frame(width: 280, height: 280)

                // Key positions
                ForEach(Array(circleOfFifths.enumerated()), id: \.element) { index, key in
                    let angle = Double(index) * (360.0 / Double(circleOfFifths.count)) - 90
                    let radius: CGFloat = 120

                    let x = radius * CGFloat(cos(angle * .pi / 180))
                    let y = radius * CGFloat(sin(angle * .pi / 180))

                    ZStack {
                        Circle()
                            .fill(key == selectedKey ? Color.blue : Color(.systemGray5))
                            .frame(width: 44, height: 44)

                        Text(key)
                            .font(.caption)
                            .fontWeight(key == selectedKey ? .bold : .regular)
                            .foregroundStyle(key == selectedKey ? .white : .primary)
                    }
                    .offset(x: x, y: y)
                    .onTapGesture {
                        withAnimation {
                            selectedKey = key
                        }
                    }
                }
            }
            .frame(height: 300)
            .padding()

            Text("Tap any key to see its relationships")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Key Signatures

    private var keySignaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "number")
                    .foregroundStyle(.green)
                Text("Key Signatures")
                    .font(.headline)
            }

            VStack(spacing: 0) {
                keySignatureRow("C Major", "No sharps or flats", color: .green)
                keySignatureRow("G Major", "1 sharp (F#)", color: .blue)
                keySignatureRow("D Major", "2 sharps (F#, C#)", color: .blue)
                keySignatureRow("A Major", "3 sharps (F#, C#, G#)", color: .blue)
                keySignatureRow("E Major", "4 sharps (F#, C#, G#, D#)", color: .blue)
                keySignatureRow("F Major", "1 flat (Bb)", color: .orange)
                keySignatureRow("Bb Major", "2 flats (Bb, Eb)", color: .orange)
                keySignatureRow("Eb Major", "3 flats (Bb, Eb, Ab)", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func keySignatureRow(_ key: String, _ signature: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 8, height: 8)

            Text(key)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Text(signature)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    // MARK: - Interval Reference

    private var intervalReferenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundStyle(.orange)
                Text("Common Intervals")
                    .font(.headline)
            }

            VStack(spacing: 0) {
                intervalRow("Half Step", "1 semitone", "C to C#")
                intervalRow("Whole Step", "2 semitones", "C to D")
                intervalRow("Minor 3rd", "3 semitones", "C to Eb")
                intervalRow("Major 3rd", "4 semitones", "C to E")
                intervalRow("Perfect 4th", "5 semitones", "C to F")
                intervalRow("Perfect 5th", "7 semitones", "C to G")
                intervalRow("Octave", "12 semitones", "C to C")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func intervalRow(_ name: String, _ semitones: String, _ example: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(example)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(semitones)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .clipShape(Capsule())
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    // MARK: - Transpose Tips

    private var transposeTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Transposing Tips")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 16) {
                tipCard(
                    icon: "mic.fill",
                    title: "Match Your Voice",
                    description: "Transpose to fit your comfortable vocal range. Most people sing best within 1.5-2 octaves."
                )

                tipCard(
                    icon: "guitars",
                    title: "Use a Capo",
                    description: "Instead of learning new chords, use a capo to play easier chord shapes in a different key."
                )

                tipCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Stay Close",
                    description: "Small transpositions (±2-3 semitones) usually sound more natural than large jumps."
                )

                tipCard(
                    icon: "music.note.list",
                    title: "Experiment",
                    description: "Try different keys! You might discover the song works better in an unexpected key."
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tipCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helper Views

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    // MARK: - Key Information

    private func getKeyInfo(_ key: String) -> KeyInfo? {
        let keyData: [String: KeyInfo] = [
            "C": KeyInfo(
                signature: "No sharps or flats",
                relativeMinor: "Am",
                commonChords: ["C", "Dm", "Em", "F", "G", "Am"]
            ),
            "G": KeyInfo(
                signature: "1 sharp (F#)",
                relativeMinor: "Em",
                commonChords: ["G", "Am", "Bm", "C", "D", "Em"]
            ),
            "D": KeyInfo(
                signature: "2 sharps (F#, C#)",
                relativeMinor: "Bm",
                commonChords: ["D", "Em", "F#m", "G", "A", "Bm"]
            ),
            "A": KeyInfo(
                signature: "3 sharps (F#, C#, G#)",
                relativeMinor: "F#m",
                commonChords: ["A", "Bm", "C#m", "D", "E", "F#m"]
            ),
            "E": KeyInfo(
                signature: "4 sharps (F#, C#, G#, D#)",
                relativeMinor: "C#m",
                commonChords: ["E", "F#m", "G#m", "A", "B", "C#m"]
            ),
            "F": KeyInfo(
                signature: "1 flat (Bb)",
                relativeMinor: "Dm",
                commonChords: ["F", "Gm", "Am", "Bb", "C", "Dm"]
            ),
            "Bb": KeyInfo(
                signature: "2 flats (Bb, Eb)",
                relativeMinor: "Gm",
                commonChords: ["Bb", "Cm", "Dm", "Eb", "F", "Gm"]
            ),
            "Eb": KeyInfo(
                signature: "3 flats (Bb, Eb, Ab)",
                relativeMinor: "Cm",
                commonChords: ["Eb", "Fm", "Gm", "Ab", "Bb", "Cm"]
            )
        ]

        return keyData[key]
    }
}

// MARK: - Supporting Types

struct KeyInfo {
    let signature: String
    let relativeMinor: String
    let commonChords: [String]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        let container = PreviewContainer.shared.container
        let song = try! container.mainContext.fetch(FetchDescriptor<Song>()).first!

        TransposeTheoryView(song: song)
    }
}
