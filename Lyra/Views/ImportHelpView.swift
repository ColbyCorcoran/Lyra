//
//  ImportHelpView.swift
//  Lyra
//
//  In-app help and documentation for import features
//

import SwiftUI

struct ImportHelpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: HelpTab = .gettingStarted

    enum HelpTab: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case formats = "File Formats"
        case troubleshooting = "Troubleshooting"
        case tips = "Tips & Tricks"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Help Section", selection: $selectedTab) {
                    ForEach(HelpTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                ScrollView {
                    Group {
                        switch selectedTab {
                        case .gettingStarted:
                            gettingStartedContent
                        case .formats:
                            formatsContent
                        case .troubleshooting:
                            troubleshootingContent
                        case .tips:
                            tipsContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Import Help")
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

    // MARK: - Getting Started

    @ViewBuilder
    private var gettingStartedContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HelpSection(
                title: "Importing Songs",
                icon: "square.and.arrow.down",
                iconColor: .blue
            ) {
                Text("Lyra supports multiple ways to import your chord charts:")

                HelpBulletPoint("**Files App**: Import from your device or iCloud Drive")
                HelpBulletPoint("**Camera Scan**: Scan paper chord charts with your camera")
                HelpBulletPoint("**Paste**: Copy and paste ChordPro text directly")
                HelpBulletPoint("**Cloud Storage**: Import from Dropbox or Google Drive (when connected)")
            }

            HelpSection(
                title: "Quick Import Steps",
                icon: "1.circle.fill",
                iconColor: .green
            ) {
                HelpNumberedList(steps: [
                    "Tap the **Import** button in the Library",
                    "Choose your import source",
                    "Select the file(s) you want to import",
                    "Review and confirm the import",
                    "Songs will appear in your library immediately"
                ])
            }

            HelpSection(
                title: "Batch Imports",
                icon: "square.stack.3d.up",
                iconColor: .orange
            ) {
                Text("You can import multiple files at once:")

                HelpBulletPoint("Select multiple files in the file picker")
                HelpBulletPoint("Lyra will process them in sequence")
                HelpBulletPoint("Progress is shown for each file")
                HelpBulletPoint("Failed imports can be retried individually")
            }

            Spacer()
        }
    }

    // MARK: - File Formats

    @ViewBuilder
    private var formatsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HelpSection(
                title: "Supported Formats",
                icon: "doc.text",
                iconColor: .blue
            ) {
                FormatRow(format: "ChordPro", extensions: [".cho", ".chordpro", ".chopro"], recommended: true)
                FormatRow(format: "Plain Text", extensions: [".txt"], recommended: false)
                FormatRow(format: "OnSong", extensions: [".onsong"], recommended: false)
                FormatRow(format: "PDF", extensions: [".pdf"], recommended: false)
                FormatRow(format: "Chord Files", extensions: [".crd"], recommended: false)
            }

            HelpSection(
                title: "ChordPro Format",
                icon: "music.note.list",
                iconColor: .purple
            ) {
                Text("ChordPro is the recommended format for chord charts.")
                    .padding(.bottom, 8)

                Text("**Basic Example:**")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)

                CodeBlock("""
                {title: Amazing Grace}
                {artist: John Newton}
                {key: G}

                [G]Amazing [C]grace, how [G]sweet the sound
                That [G]saved a [D]wretch like [G]me
                """)

                Text("Common directives:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                HelpBulletPoint("**{title:}** - Song title")
                HelpBulletPoint("**{artist:}** - Artist/composer name")
                HelpBulletPoint("**{key:}** - Original key")
                HelpBulletPoint("**{capo:}** - Capo position")
                HelpBulletPoint("**{tempo:}** - Beats per minute")
                HelpBulletPoint("**{time:}** - Time signature")
            }

            HelpSection(
                title: "PDF Files",
                icon: "doc.richtext",
                iconColor: .red
            ) {
                Text("PDF files are supported as attachments:")

                HelpBulletPoint("Best for scanned chord charts")
                HelpBulletPoint("Maximum 100 pages per PDF")
                HelpBulletPoint("Files under 5MB stored in app")
                HelpBulletPoint("Larger files stored externally")

                Text("**Note:** You can extract text from PDFs to create editable chord charts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }

            Spacer()
        }
    }

    // MARK: - Troubleshooting

    @ViewBuilder
    private var troubleshootingContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HelpSection(
                title: "Common Issues",
                icon: "exclamationmark.triangle",
                iconColor: .orange
            ) {
                TroubleshootingItem(
                    problem: "Import fails with 'File not readable'",
                    solutions: [
                        "Make sure you have permission to access the file",
                        "Try selecting the file again from Files app",
                        "Check if the file is corrupted by opening it in another app"
                    ]
                )

                Divider()
                    .padding(.vertical, 8)

                TroubleshootingItem(
                    problem: "File is empty after import",
                    solutions: [
                        "Verify the original file contains content",
                        "Check the file encoding (should be UTF-8)",
                        "Try importing as plain text instead"
                    ]
                )

                Divider()
                    .padding(.vertical, 8)

                TroubleshootingItem(
                    problem: "PDF shows but no chords display",
                    solutions: [
                        "PDFs are shown as attachments, not parsed for chords",
                        "Use 'Extract Text from PDF' to create an editable version",
                        "Consider re-creating the chart in ChordPro format"
                    ]
                )

                Divider()
                    .padding(.vertical, 8)

                TroubleshootingItem(
                    problem: "Cloud import not working",
                    solutions: [
                        "Check your internet connection",
                        "Verify you're signed in to the cloud provider",
                        "Try reconnecting your account in Settings",
                        "Check if the file still exists in your cloud storage"
                    ]
                )
            }

            HelpSection(
                title: "File Size Limits",
                icon: "scale.3d",
                iconColor: .purple
            ) {
                HelpBulletPoint("**Text files**: Up to 100 MB")
                HelpBulletPoint("**PDF files**: Up to 100 MB")
                HelpBulletPoint("**PDF pages**: Maximum 100 pages")
                HelpBulletPoint("**Batch imports**: Up to 100 files at once")

                Text("Files larger than these limits will be rejected with a helpful error message.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }

            Spacer()
        }
    }

    // MARK: - Tips & Tricks

    @ViewBuilder
    private var tipsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HelpSection(
                title: "Import Best Practices",
                icon: "lightbulb",
                iconColor: .yellow
            ) {
                TipCard(
                    icon: "checkmark.circle",
                    title: "Use ChordPro Format",
                    description: "Convert your charts to ChordPro for the best experience with transposition, display settings, and more."
                )

                TipCard(
                    icon: "folder",
                    title: "Organize Before Import",
                    description: "Name your files clearly before importing. The filename will be used as the song title if no title is found in the file."
                )

                TipCard(
                    icon: "doc.badge.gearshape",
                    title: "Include Metadata",
                    description: "Add {title:}, {artist:}, {key:}, and other directives to your ChordPro files for automatic metadata extraction."
                )

                TipCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Avoid Duplicates",
                    description: "Lyra automatically detects duplicate songs based on title, artist, and content similarity."
                )
            }

            HelpSection(
                title: "Performance Tips",
                icon: "speedometer",
                iconColor: .green
            ) {
                HelpBulletPoint("**Large batches**: Import in groups of 50-100 files for best performance")
                HelpBulletPoint("**PDFs**: Smaller PDF files (under 5MB) load faster")
                HelpBulletPoint("**Cloud imports**: Download to device first for faster processing")
                HelpBulletPoint("**Memory**: Close other apps when importing many large files")
            }

            HelpSection(
                title: "Advanced Features",
                icon: "wand.and.stars",
                iconColor: .purple
            ) {
                HelpBulletPoint("**Scan to PDF**: Use document scanner to digitize paper charts")
                HelpBulletPoint("**Text extraction**: Extract text from PDF attachments to create editable versions")
                HelpBulletPoint("**Paste import**: Quickly add songs by pasting ChordPro text")
                HelpBulletPoint("**Import records**: View detailed logs of all imports in Settings")
            }

            Spacer()
        }
    }
}

// MARK: - Helper Views

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.bottom, 4)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HelpBulletPoint: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}

struct HelpNumberedList: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1).")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .frame(width: 24, alignment: .leading)

                    Text(.init(step))
                        .font(.body)
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct CodeBlock: View {
    let code: String

    init(_ code: String) {
        self.code = code
    }

    var body: some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
    }
}

struct FormatRow: View {
    let format: String
    let extensions: [String]
    let recommended: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(format)
                        .font(.body)
                        .fontWeight(.medium)

                    if recommended {
                        Text("RECOMMENDED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }

                Text(extensions.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TroubleshootingItem: View {
    let problem: String
    let solutions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("**Problem:** \(problem)")
                .font(.subheadline)

            Text("**Solutions:**")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            ForEach(Array(solutions.enumerated()), id: \.offset) { _, solution in
                HelpBulletPoint(.init(solution))
                    .font(.caption)
            }
        }
    }
}

struct TipCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
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
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    ImportHelpView()
}
