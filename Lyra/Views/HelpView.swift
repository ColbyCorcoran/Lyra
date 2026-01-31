//
//  HelpView.swift
//  Lyra
//
//  In-app help and tips system
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var selectedCategory: HelpCategory? = nil

    private let helpCategories: [HelpCategory] = [
        HelpCategory(
            id: "getting-started",
            title: "Getting Started",
            icon: "star.fill",
            color: .blue,
            articles: [
                HelpArticle(
                    title: "Welcome to Lyra",
                    content: """
                    Lyra is your ultimate chord chart companion for live performance. Whether you're a worship leader, music therapist, or performing musician, Lyra helps you stay organized and focused during performances.

                    **Key Features:**
                    • Organize songs into books and sets
                    • Autoscroll with adjustable speed
                    • Transpose chords to any key
                    • Built-in metronome and backing tracks
                    • Annotations and drawing tools
                    • Local backups for data protection
                    """,
                    tags: ["basics", "introduction"]
                ),
                HelpArticle(
                    title: "Creating Your First Song",
                    content: """
                    **To add a new song:**

                    1. Go to the Songs tab
                    2. Tap the + button
                    3. Enter the song title and artist
                    4. Paste or type your chord chart
                    5. Add optional metadata (key, tempo, time signature)
                    6. Tap Save

                    **Chord Chart Format:**
                    Lyra automatically detects chords in square brackets:
                    `[G]Amazing grace, how [C]sweet the [G]sound`

                    You can also use OnSong format, ChordPro, or plain text.
                    """,
                    tags: ["songs", "basics"]
                ),
                HelpArticle(
                    title: "Organizing with Books and Sets",
                    content: """
                    **Books** are collections of songs you perform regularly:
                    • Worship sets
                    • Client playlists (music therapy)
                    • Repertoire collections

                    **Sets** are ordered playlists for specific performances:
                    • Sunday service setlist
                    • Concert program
                    • Therapy session plan

                    Go to the Books or Sets tab to create new collections, then add songs by tapping the + button.
                    """,
                    tags: ["organization", "books", "sets"]
                )
            ]
        ),
        HelpCategory(
            id: "performance",
            title: "Performance Features",
            icon: "play.circle.fill",
            color: .green,
            articles: [
                HelpArticle(
                    title: "Autoscroll",
                    content: """
                    Autoscroll automatically scrolls your chord chart at a configurable speed, perfect for hands-free performance. Autoscroll is enabled by default for all songs.

                    **Controls:**
                    • Play/Pause button: Start/stop scrolling
                    • Speed controls: Adjust scroll speed with +/- buttons
                    • Jump to top: Reset to beginning
                    • Stop button: End autoscroll session

                    **Tips:**
                    • Tap the song to pause autoscroll temporarily
                    • Adjust speed during performance with speed controls
                    • Manual scrolling pauses autoscroll
                    • Enable/disable per song in the more menu (•••)
                    """,
                    tags: ["autoscroll", "performance"]
                ),
                HelpArticle(
                    title: "Metronome",
                    content: """
                    Built-in metronome keeps you on tempo during practice and performance.

                    **Features:**
                    • Visual and audio feedback
                    • Accent patterns for different time signatures
                    • Multiple sound presets (click, beep, drum, woodblock)
                    • Adjustable BPM and subdivisions
                    • Tap tempo for quick setup

                    **Using the Metronome:**
                    1. Tap the metronome button (bottom right of song view)
                    2. Set your tempo and time signature
                    3. Choose sound type and accent pattern
                    4. Tap Play to start

                    **Tips:**
                    • Use tap tempo to match the song's speed
                    • Metronome runs in background with other features
                    • Save tempo in song metadata for quick access
                    """,
                    tags: ["metronome", "performance", "tempo"]
                ),
                HelpArticle(
                    title: "Backing Tracks",
                    content: """
                    Add audio backing tracks to your songs for practice or performance.

                    **Adding Tracks:**
                    1. Open a song
                    2. Tap more menu (•••) → Backing Tracks
                    3. Add audio files from your device
                    4. Use mixer controls to adjust volume, pan, mute, and solo

                    **Mixer Controls:**
                    • Volume slider for each track
                    • Pan control (L/R balance)
                    • Mute/Solo buttons
                    • Master volume control

                    **Supported Formats:**
                    Most common audio formats including MP3, M4A, WAV, and AIFF.
                    """,
                    tags: ["backing-tracks", "audio", "performance"]
                ),
                HelpArticle(
                    title: "Low Light Mode",
                    content: """
                    Optimized display for dark venues and stage performances.

                    **Features:**
                    • Black background with customizable text color
                    • Reduced eye strain in dark environments
                    • Auto-enable based on time or brightness
                    • Quick toggle from song view

                    **Activation:**
                    • Tap the moon icon in the toolbar
                    • Long press for Low Light Settings
                    • Configure auto-enable preferences

                    **Tips:**
                    • Perfect for stage performances
                    • Use red text color to preserve night vision
                    • Auto-enable can trigger at sunset
                    """,
                    tags: ["low-light", "performance", "display"]
                )
            ]
        ),
        HelpCategory(
            id: "editing",
            title: "Editing & Customization",
            icon: "pencil.circle.fill",
            color: .orange,
            articles: [
                HelpArticle(
                    title: "Transposing Chords",
                    content: """
                    Transpose your chord charts to any key instantly.

                    **To transpose:**
                    • Tap the 🎵 key button
                    • Use +/- buttons or drag the pitch slider
                    • Capo position is calculated automatically

                    **Tips:**
                    • Transpose is non-destructive (original key is preserved)
                    • Each song remembers its transpose setting
                    """,
                    tags: ["transpose", "chords"]
                ),
                HelpArticle(
                    title: "Annotations",
                    content: """
                    Add personal notes, cues, and reminders to your chord charts.

                    **To add an annotation:**
                    1. Tap and hold on any line in the song
                    2. Select "Add Annotation"
                    3. Type your note
                    4. Choose a color for easy identification

                    **Annotation Types:**
                    • 📝 Notes: General reminders
                    • ⚠️ Warnings: Important cues
                    • 💡 Tips: Performance suggestions
                    • 🎤 Vocals: Singing instructions
                    """,
                    tags: ["annotations", "notes"]
                ),
                HelpArticle(
                    title: "Display Settings",
                    content: """
                    Customize the appearance of your chord charts with comprehensive display settings.

                    **Accessing Display Settings:**
                    Tap the Aa button (textformat.size icon) in the song view toolbar.

                    **Five Settings Tabs:**
                    • **Fonts**: Size, weight, and font families for title, lyrics, chords, and metadata
                    • **Colors**: Chord colors, lyrics colors, backgrounds with presets and color-blind friendly options
                    • **Layout**: Line spacing, margins, two-column mode, and dark mode preference
                    • **Access**: High contrast, bold text, minimum font size, and accessibility features
                    • **Presets**: Quick apply built-in presets (Default, Stage Performance, Practice, Large Print)

                    **Per-Song Customization:**
                    Each song can have unique display settings, or use global defaults. Remove custom settings anytime.

                    **Templates:**
                    Use the template selector to choose multi-column layouts with different typography options.
                    """,
                    tags: ["display", "customization", "accessibility"]
                )
            ]
        ),
        HelpCategory(
            id: "backup",
            title: "Backup & Data",
            icon: "externaldrive.fill",
            color: .blue,
            articles: [
                HelpArticle(
                    title: "Local Backups",
                    content: """
                    Protect your data with automatic local backups.

                    **Auto-Backup:**
                    • Daily or weekly automatic backups
                    • Keeps last 5 backups
                    • Stored locally on device
                    • Configure frequency in settings

                    **Manual Backup:**
                    1. Settings → Data Management → Backup & Restore
                    2. Tap "Create Backup Now"
                    3. Export to Files app for safekeeping

                    **Restore from Backup:**
                    1. Settings → Data Management → Backup & Restore
                    2. Tap "Restore from Backup"
                    3. Select backup file (or import from Files)
                    4. Confirm restoration

                    **Import/Export:**
                    • Export backups to iCloud Drive, Dropbox, or other cloud storage
                    • Import backups from any location
                    • JSON format for data portability
                    """,
                    tags: ["backup", "restore", "data"]
                ),
                HelpArticle(
                    title: "Song Info & Metadata",
                    content: """
                    View comprehensive information about each song.

                    **Viewing Song Info:**
                    1. Open a song
                    2. Tap more menu (•••) → Song Info

                    **Information Displayed:**
                    • Title, artist, album, year
                    • Musical details (key, tempo, time signature, capo)
                    • Dates (created, modified)
                    • Content statistics (characters, lines, chords)
                    • Tags and notes
                    • Import source and cloud sync info

                    **Tips:**
                    • Use tags to organize songs by theme or category
                    • Add notes for performance reminders
                    • Track when songs were last modified
                    """,
                    tags: ["metadata", "song-info", "organization"]
                )
            ]
        ),
        HelpCategory(
            id: "import-export",
            title: "Import & Export",
            icon: "arrow.up.arrow.down.circle.fill",
            color: .purple,
            articles: [
                HelpArticle(
                    title: "Importing Songs",
                    content: """
                    Import your existing chord charts from various sources.

                    **From OnSong:**
                    1. Settings → Data Management → OnSong Import
                    2. Choose "Import from Files"
                    3. Navigate to your OnSong files in Files app (Dropbox, Google Drive, iCloud Drive, etc.)
                    4. Select individual files or entire folders
                    5. Lyra converts automatically

                    **From Files:**
                    • Go to Songs tab
                    • Tap + button → Import File
                    • Choose .txt, .onsong, .pro, or .chopro files
                    • Supported from any cloud storage

                    **From Clipboard:**
                    • Copy chord chart from any source
                    • Go to Songs tab
                    • Tap + → Paste from Clipboard
                    • Chords are detected automatically

                    **Scan Chord Chart:**
                    • Tap + → Scan Chord Chart
                    • Use camera to capture printed charts
                    • OCR converts to editable text
                    """,
                    tags: ["import", "onsong", "files"]
                ),
                HelpArticle(
                    title: "Exporting Your Library",
                    content: """
                    Export your songs in various formats for backup or sharing.

                    **Individual Song Export:**
                    1. Open a song
                    2. Tap more menu (•••) → Export
                    3. Share as text file
                    4. Choose destination (Files, AirDrop, Email)

                    **Bulk Library Export:**
                    1. Settings → Data Management → Export Library
                    2. Choose format:
                       • ChordPro (.pro files)
                       • Plain Text (.txt files)
                       • PDF (printable charts)
                       • JSON (structured data)
                    3. Export creates a ZIP archive
                    4. Save to Files app or share

                    **What's Included:**
                    • All songs with metadata
                    • README with export details
                    • Organized folder structure
                    • Easy to re-import or share

                    **Tips:**
                    • Export regularly as an additional backup
                    • PDF format is perfect for printed binders
                    • ChordPro format works with other apps
                    """,
                    tags: ["export", "backup", "sharing"]
                )
            ]
        ),
        HelpCategory(
            id: "keyboard-shortcuts",
            title: "Shortcuts & Gestures",
            icon: "keyboard",
            color: .indigo,
            articles: [
                HelpArticle(
                    title: "Keyboard Shortcuts",
                    content: """
                    Use keyboard shortcuts for faster navigation (iPad with keyboard).

                    **Global:**
                    • ⌘ + N: New song
                    • ⌘ + F: Search
                    • ⌘ + ,: Settings

                    **Song View:**
                    • Space: Start/stop autoscroll
                    • ← / →: Transpose down/up
                    • ⌘ + E: Edit song
                    • ⌘ + T: Transpose view
                    """,
                    tags: ["keyboard", "shortcuts", "ipad"]
                ),
                HelpArticle(
                    title: "Drawing & Annotations",
                    content: """
                    Mark up your chord charts with notes and drawings during practice or performance.

                    **Annotations:**
                    1. Tap the note icon in song view toolbar
                    2. Tap anywhere on the chart to add a sticky note
                    3. Type your annotation
                    4. Color-code for organization

                    **Drawing Mode:**
                    1. Tap the pencil icon in toolbar
                    2. Draw directly on the chart
                    3. Use for circles, arrows, highlighting
                    4. Drawings are saved with the song

                    **Tips:**
                    • Use annotations for performance cues
                    • Draw circles around chord changes
                    • Add arrows for dynamic changes
                    • Both modes disable scrolling for precision
                    """,
                    tags: ["annotations", "drawing", "markup"]
                )
            ]
        ),
        HelpCategory(
            id: "troubleshooting",
            title: "Troubleshooting",
            icon: "wrench.fill",
            color: .red,
            articles: [
                HelpArticle(
                    title: "Common Issues",
                    content: """
                    **Sync Not Working:**
                    • Check iCloud is enabled in Settings
                    • Verify internet connection
                    • Check sync settings in app
                    • Try manual "Sync Now"

                    **Songs Not Importing:**
                    • Verify file format (.txt, .onsong, .pro, .chopro)
                    • Check cloud service connection
                    • Try importing to Files app first

                    **Chords Not Detected:**
                    • Use square brackets: [G] [C] [D]
                    • Avoid spaces inside brackets
                    • Check chord names are standard (G, Am, C#m7, etc.)
                    """,
                    tags: ["troubleshooting", "issues"]
                ),
                HelpArticle(
                    title: "Getting Help",
                    content: """
                    **Need More Help?**

                    • **Documentation:** lyraapp.com/docs
                    • **Video Tutorials:** lyraapp.com/tutorials
                    • **Email Support:** support@lyraapp.com
                    • **GitHub Issues:** github.com/yourusername/lyra/issues
                    • **Community:** Discord or forum links

                    **When Reporting Issues:**
                    1. Describe what you were doing
                    2. What you expected to happen
                    3. What actually happened
                    4. iOS version and device model
                    5. Screenshots if possible

                    **Feature Requests:**
                    We'd love to hear your ideas! Submit them via GitHub or email.
                    """,
                    tags: ["support", "help"]
                )
            ]
        )
    ]

    var filteredCategories: [HelpCategory] {
        if searchText.isEmpty {
            return helpCategories
        }

        return helpCategories.compactMap { category in
            let matchingArticles = category.articles.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.content.localizedCaseInsensitiveContains(searchText) ||
                article.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }

            guard !matchingArticles.isEmpty else { return nil }

            return HelpCategory(
                id: category.id,
                title: category.title,
                icon: category.icon,
                color: category.color,
                articles: matchingArticles
            )
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCategories) { category in
                    Section {
                        ForEach(category.articles) { article in
                            NavigationLink {
                                HelpArticleView(article: article, category: category)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: category.icon)
                                        .font(.title3)
                                        .foregroundStyle(category.color)
                                        .frame(width: 30)

                                    Text(article.title)
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Label(category.title, systemImage: category.icon)
                            .foregroundStyle(category.color)
                    }
                }
            }
            .navigationTitle("Help & Support")
            .searchable(text: $searchText, prompt: "Search help articles")
        }
    }
}

// MARK: - Help Category

struct HelpCategory: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let articles: [HelpArticle]
}

// MARK: - Help Article

struct HelpArticle: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let tags: [String]
}

// MARK: - Help Article View

struct HelpArticleView: View {
    let article: HelpArticle
    let category: HelpCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.largeTitle)
                        .foregroundStyle(category.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(article.title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(category.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Content
                Text(.init(article.content))
                    .font(.body)
                    .lineSpacing(6)

                // Tags
                if !article.tags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(article.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Flow Layout for Tags

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
    HelpView()
}
