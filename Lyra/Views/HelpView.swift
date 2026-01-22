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
                    • Performance mode for distraction-free viewing
                    • Autoscroll with adjustable speed
                    • Transpose chords to any key
                    • Offline-first design
                    • iCloud sync across devices
                    """,
                    tags: ["basics", "introduction"]
                ),
                HelpArticle(
                    title: "Creating Your First Song",
                    content: """
                    **To add a new song:**

                    1. Tap the + button in the Library
                    2. Enter the song title and artist
                    3. Paste or type your chord chart
                    4. Add optional metadata (key, tempo, time signature)
                    5. Tap Save

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

                    Create books and sets from the Library tab, then add songs by tapping the + button.
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
                    title: "Performance Mode",
                    content: """
                    Performance Mode provides a distraction-free, full-screen view optimized for live performance.

                    **To enter Performance Mode:**
                    Tap the ▶️ button at the top of any song

                    **Features:**
                    • Full-screen display with large, readable text
                    • Swipe gestures to navigate between songs
                    • Quick transpose buttons
                    • Autoscroll control
                    • Low-light mode for dark venues
                    • Hide system UI for maximum screen space

                    **Gestures:**
                    • Swipe left/right: Next/previous song
                    • Swipe down: Exit performance mode
                    • Two-finger tap: Toggle controls
                    • Pinch: Adjust font size
                    """,
                    tags: ["performance", "gestures"]
                ),
                HelpArticle(
                    title: "Autoscroll",
                    content: """
                    Autoscroll automatically scrolls your chord chart at a configurable speed, perfect for hands-free performance.

                    **Controls:**
                    • Play/Pause button: Start/stop scrolling
                    • Speed slider: Adjust scroll speed
                    • Reset button: Jump back to top

                    **Tips:**
                    • Adjust speed before performance
                    • Use foot pedals for hands-free control
                    • Autoscroll syncs with tempo if set
                    """,
                    tags: ["autoscroll", "performance"]
                ),
                HelpArticle(
                    title: "Foot Pedals",
                    content: """
                    Connect Bluetooth foot pedals for hands-free control during performance.

                    **Supported Actions:**
                    • Next/previous song
                    • Start/stop autoscroll
                    • Transpose up/down
                    • Toggle performance mode

                    **Setup:**
                    1. Go to Settings → Performance → Foot Pedals
                    2. Tap "Scan for Devices"
                    3. Select your foot pedal from the list
                    4. Map pedal actions to functions

                    **Compatible Devices:**
                    • AirTurn pedals
                    • PageFlip pedals
                    • Most Bluetooth page turners
                    """,
                    tags: ["foot-pedals", "bluetooth", "performance"]
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
                    • Quick transpose buttons in Performance Mode
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
                    Customize the appearance of your chord charts.

                    **Settings → Display Defaults:**
                    • Font size: 12-28pt
                    • Chord color: Blue, red, green, or custom
                    • Lyrics color: Black, white, or custom
                    • Spacing: Adjust line height

                    **Per-Song Overrides:**
                    Each song can override global settings for specific needs.

                    **Dark Mode:**
                    Lyra automatically adapts to your system dark mode preference.
                    """,
                    tags: ["display", "customization"]
                )
            ]
        ),
        HelpCategory(
            id: "sync",
            title: "Sync & Backup",
            icon: "icloud.fill",
            color: .blue,
            articles: [
                HelpArticle(
                    title: "iCloud Sync",
                    content: """
                    Keep your library in sync across all your devices.

                    **Setup:**
                    1. Settings → Data Management → Sync & Backup
                    2. Enable "iCloud Sync"
                    3. Choose sync scope (all data, sets only, etc.)
                    4. Optionally enable cellular sync

                    **Sync Status:**
                    • ✅ Synced: All changes uploaded
                    • 🔄 Syncing: Upload in progress
                    • ⚠️ Conflict: Needs your attention
                    • ❌ Error: Check network connection

                    **Conflict Resolution:**
                    If the same song is edited on two devices, Lyra will ask you to choose which version to keep.
                    """,
                    tags: ["icloud", "sync"]
                ),
                HelpArticle(
                    title: "Local Backups",
                    content: """
                    Protect your data with automatic local backups.

                    **Auto-Backup:**
                    • Daily or weekly automatic backups
                    • Keeps last 5 backups
                    • Stored locally on device

                    **Manual Backup:**
                    1. Settings → Data Management → Sync & Backup
                    2. Tap "Create Backup Now"
                    3. Optionally export to Files app

                    **Restore:**
                    1. Tap "Restore from Backup"
                    2. Select backup file
                    3. Confirm restoration (this replaces all current data)
                    """,
                    tags: ["backup", "restore"]
                ),
                HelpArticle(
                    title: "Offline Mode",
                    content: """
                    Lyra is designed to work perfectly offline - all features are available without internet.

                    **Offline Features:**
                    ✅ View and edit songs
                    ✅ Performance mode
                    ✅ Transpose and annotate
                    ✅ Create books and sets
                    ✅ All local operations

                    **When Back Online:**
                    • Changes sync automatically
                    • Queued cloud operations are processed
                    • Conflict resolution if needed

                    **Perfect for:**
                    • Venues with poor Wi-Fi
                    • Airplane mode during performance
                    • Areas with no cellular service
                    """,
                    tags: ["offline", "sync"]
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
                    1. Settings → Library → Import from OnSong
                    2. Connect to Dropbox or Google Drive
                    3. Select songs to import
                    4. Lyra converts automatically

                    **From Files:**
                    • Tap + in Library
                    • Select "Import File"
                    • Choose .txt, .onsong, .pro, or .chopro files

                    **From Clipboard:**
                    • Copy chord chart from any source
                    • Tap + in Library
                    • Paste content
                    • Chords are detected automatically
                    """,
                    tags: ["import", "onsong"]
                ),
                HelpArticle(
                    title: "Exporting Your Library",
                    content: """
                    Export your songs in various formats for backup or sharing.

                    **Export Formats:**
                    • PDF: Printable chord charts
                    • Plain Text: Universal format
                    • OnSong: Compatible with OnSong app
                    • ChordPro: Standard chord format

                    **To Export:**
                    1. Select song, book, or set
                    2. Tap share button
                    3. Choose export format
                    4. Select destination (Files, AirDrop, Email)

                    **Bulk Export:**
                    Settings → Library → Export Library to export everything at once.
                    """,
                    tags: ["export", "pdf", "backup"]
                )
            ]
        ),
        HelpCategory(
            id: "analytics",
            title: "Analytics & Insights",
            icon: "chart.bar.fill",
            color: .pink,
            articles: [
                HelpArticle(
                    title: "Performance Tracking",
                    content: """
                    Track which songs you perform and gain insights into your patterns.

                    **What's Tracked:**
                    • Songs performed and when
                    • Set completion
                    • Performance duration
                    • Key preferences
                    • Most performed songs

                    **Analytics Dashboard:**
                    View trends, charts, and insights in the Analytics tab.

                    **Privacy:**
                    All analytics data is stored locally on your device and synced via iCloud (if enabled). Nothing is sent to external servers.
                    """,
                    tags: ["analytics", "tracking"]
                ),
                HelpArticle(
                    title: "Understanding Insights",
                    content: """
                    The Insights engine analyzes your performance data to provide actionable recommendations.

                    **Insight Types:**
                    • 🔥 Trending: Songs gaining popularity
                    • 📊 Patterns: Repertoire distribution
                    • 🎯 Recommendations: Songs to revisit
                    • ⚠️ Alerts: Unused songs or imbalances

                    **Use Cases:**
                    • Music therapy: Track which songs resonate with clients
                    • Worship: Monitor song rotation
                    • Performance: Identify your "go-to" songs
                    """,
                    tags: ["insights", "analytics"]
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
                    • ⌘ + P: Performance mode
                    • ⌘ + E: Edit song
                    • ⌘ + T: Transpose view

                    **Performance Mode:**
                    • Space: Play/pause autoscroll
                    • ↑ / ↓: Adjust scroll speed
                    • ← / →: Previous/next song
                    • Esc: Exit performance mode
                    """,
                    tags: ["keyboard", "shortcuts", "ipad"]
                ),
                HelpArticle(
                    title: "Gesture Controls",
                    content: """
                    Master gesture controls for intuitive navigation.

                    **Song View:**
                    • Swipe left: Next song
                    • Swipe right: Previous song
                    • Pinch: Zoom in/out

                    **Performance Mode:**
                    • Swipe left/right: Navigate songs
                    • Swipe down: Exit
                    • Two-finger tap: Toggle controls
                    • Pinch: Font size
                    • Three-finger swipe up: Quick transpose

                    **Library:**
                    • Swipe left on song: Quick actions
                    • Long press: Context menu
                    • Drag and drop: Reorder
                    """,
                    tags: ["gestures", "navigation"]
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

                    **Performance Mode Issues:**
                    • Restart app
                    • Check display settings
                    • Disable low power mode
                    • Update to latest version
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
