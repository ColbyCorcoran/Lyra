//
//  LibraryStatsView.swift
//  Lyra
//
//  Statistics and insights view showing library health and usage patterns
//

import SwiftUI
import SwiftData
import Charts

struct LibraryStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allSongs: [Song]
    @Query private var allBooks: [Book]
    @Query private var allSets: [PerformanceSet]

    @State private var showExportSheet: Bool = false
    @State private var showUnorganizedSongs: Bool = false
    @State private var showEmptyBooks: Bool = false
    @State private var exportText: String = ""
    @State private var isLoading: Bool = true

    // Cached computed values for performance
    @State private var cachedUniqueArtistsCount: Int = 0
    @State private var cachedTopViewedSongs: [Song] = []
    @State private var cachedTopPerformedSongs: [Song] = []
    @State private var cachedRecentlyAddedSongs: [Song] = []
    @State private var cachedUnorganizedSongs: [Song] = []
    @State private var cachedEmptyBooks: [Book] = []
    @State private var cachedAverageSongsPerBook: Double = 0
    @State private var cachedAverageSongsPerSet: Double = 0
    @State private var cachedSongsByKey: [(key: String, count: Int)] = []
    @State private var cachedSongsByDecade: [(decade: String, count: Int)] = []
    @State private var cachedSongsWithYearCount: Int = 0

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    // Loading state with skeleton
                    loadingView
                } else {
                    statisticsListView
                }
            }
            .navigationTitle("Library Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showUnorganizedSongs) {
                UnorganizedSongsView(songs: cachedUnorganizedSongs)
            }
            .sheet(isPresented: $showEmptyBooks) {
                EmptyBooksView(books: cachedEmptyBooks)
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(items: [exportText])
            }
            .onAppear {
                if isLoading {
                    computeStatistics()
                }
            }
        }
    }

    // MARK: - Statistics List View

    @ViewBuilder
    private var statisticsListView: some View {
        List {
            // MARK: - Overview Section

            Section {
                OverviewStatRow(
                    icon: "music.note",
                    label: "Total Songs",
                    value: "\(allSongs.count)",
                    color: .blue
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total Songs: \(allSongs.count)")

                OverviewStatRow(
                    icon: "book.fill",
                    label: "Total Books",
                    value: "\(allBooks.count)",
                    color: .purple
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total Books: \(allBooks.count)")

                OverviewStatRow(
                    icon: "music.note.list",
                    label: "Performance Sets",
                    value: "\(allSets.count)",
                    color: .green
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Performance Sets: \(allSets.count)")

                OverviewStatRow(
                    icon: "person.fill",
                    label: "Unique Artists",
                    value: "\(cachedUniqueArtistsCount)",
                    color: .orange
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Unique Artists: \(cachedUniqueArtistsCount)")
            } header: {
                Text("Overview")
            }

            // MARK: - Most Viewed Section

            if !cachedTopViewedSongs.isEmpty {
                    Section {
                        ForEach(Array(cachedTopViewedSongs.prefix(5).enumerated()), id: \.element.id) { index, song in
                            HStack(spacing: 12) {
                                // Rank badge
                                ZStack {
                                    Circle()
                                        .fill(rankColor(for: index).opacity(0.15))
                                        .frame(width: 32, height: 32)

                                    Text("\(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(rankColor(for: index))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    if let artist = song.artist {
                                        Text(artist)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: "eye.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(song.timesViewed)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Most Viewed Songs")
                    }
                }

                // MARK: - Most Performed Section

                if !cachedTopPerformedSongs.isEmpty {
                    Section {
                        ForEach(Array(cachedTopPerformedSongs.prefix(5).enumerated()), id: \.element.id) { index, song in
                            HStack(spacing: 12) {
                                // Rank badge
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.15))
                                        .frame(width: 32, height: 32)

                                    Text("\(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.green)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    if let artist = song.artist {
                                        Text(artist)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(song.timesPerformed)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Most Performed Songs")
                    }
                }

                // MARK: - Recently Added Section

                if !cachedRecentlyAddedSongs.isEmpty {
                    Section {
                        ForEach(cachedRecentlyAddedSongs.prefix(5)) { song in
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text(formatRelativeDate(song.createdAt))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                        }
                    } header: {
                        Text("Recently Added")
                    }
                }

                // MARK: - Organization Health Section

                Section {
                    OrganizationHealthRow(
                        icon: "folder.badge.questionmark",
                        label: "Unorganized Songs",
                        value: "\(cachedUnorganizedSongs.count)",
                        status: cachedUnorganizedSongs.count == 0 ? .good : .warning,
                        action: cachedUnorganizedSongs.count > 0 ? {
                            showUnorganizedSongs = true
                        } : nil
                    )

                    OrganizationHealthRow(
                        icon: "book.closed",
                        label: "Empty Books",
                        value: "\(cachedEmptyBooks.count)",
                        status: cachedEmptyBooks.count == 0 ? .good : .info,
                        action: cachedEmptyBooks.count > 0 ? {
                            showEmptyBooks = true
                        } : nil
                    )

                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.subheadline)
                            .foregroundStyle(.purple)
                            .frame(width: 32)

                        Text("Avg Songs per Book")
                            .font(.subheadline)

                        Spacer()

                        Text(String(format: "%.1f", cachedAverageSongsPerBook))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "music.note.list")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .frame(width: 32)

                        Text("Avg Songs per Set")
                            .font(.subheadline)

                        Spacer()

                        Text(String(format: "%.1f", cachedAverageSongsPerSet))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Organization Health")
                }

                // MARK: - Songs by Key Chart

                if !cachedSongsByKey.isEmpty {
                    Section {
                        Chart {
                            ForEach(cachedSongsByKey, id: \.key) { data in
                                BarMark(
                                    x: .value("Key", data.key),
                                    y: .value("Count", data.count)
                                )
                                .foregroundStyle(.blue.gradient)
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                    } header: {
                        Text("Songs by Key")
                    }
                }

                // MARK: - Songs by Decade Chart

                if !cachedSongsByDecade.isEmpty {
                    Section {
                        Chart {
                            ForEach(cachedSongsByDecade, id: \.decade) { data in
                                BarMark(
                                    x: .value("Decade", data.decade),
                                    y: .value("Count", data.count)
                                )
                                .foregroundStyle(.purple.gradient)
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                    } header: {
                        Text("Songs by Decade")
                    } footer: {
                        Text("Based on \(cachedSongsWithYearCount) songs with year metadata")
                    }
                }

                // MARK: - Export Section

                Section {
                    Button {
                        generateReport()
                        showExportSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.blue)
                            Text("Export Statistics Report")
                                .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    Text("Export")
                }
            }
        }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        List {
            Section {
                ForEach(0..<4) { _ in
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 120, height: 16)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                                .frame(width: 80, height: 12)
                        }

                        Spacer()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 50, height: 20)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Overview")
            }

            Section {
                ForEach(0..<3) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 150, height: 14)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                                .frame(width: 100, height: 12)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Most Viewed Songs")
            }
        }
        .redacted(reason: .placeholder)
        .disabled(true)
    }

    // MARK: - Compute Statistics Function

    private func computeStatistics() {
        Task {
            // Perform expensive computations off the main thread
            let uniqueArtists = Set(allSongs.compactMap { $0.artist }).count

            let topViewed = allSongs
                .filter { $0.timesViewed > 0 }
                .sorted { $0.timesViewed > $1.timesViewed }

            let topPerformed = allSongs
                .filter { $0.timesPerformed > 0 }
                .sorted { $0.timesPerformed > $1.timesPerformed }

            let recentlyAdded = allSongs.sorted { $0.createdAt > $1.createdAt }

            let unorganized = allSongs.filter { song in
                let inBooks = song.books?.isEmpty ?? true
                let inSets = song.setEntries?.isEmpty ?? true
                return inBooks && inSets
            }

            let emptyBooks = allBooks.filter { $0.songs?.isEmpty ?? true }

            let avgSongsPerBook: Double
            if !allBooks.isEmpty {
                let totalSongs = allBooks.reduce(0) { $0 + ($1.songs?.count ?? 0) }
                avgSongsPerBook = Double(totalSongs) / Double(allBooks.count)
            } else {
                avgSongsPerBook = 0
            }

            let avgSongsPerSet: Double
            if !allSets.isEmpty {
                let totalSongs = allSets.reduce(0) { $0 + ($1.songEntries?.count ?? 0) }
                avgSongsPerSet = Double(totalSongs) / Double(allSets.count)
            } else {
                avgSongsPerSet = 0
            }

            let songsByKey = Dictionary(grouping: allSongs.compactMap { $0.originalKey }, by: { $0 })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
                .map { (key: $0.key, count: $0.value) }

            let decades = allSongs.compactMap { song -> String? in
                guard let year = song.year else { return nil }
                let decade = (year / 10) * 10
                return "\(decade)s"
            }
            let songsByDecade = Dictionary(grouping: decades, by: { $0 })
                .mapValues { $0.count }
                .sorted { $0.key < $1.key }
                .map { (decade: $0.key, count: $0.value) }

            let songsWithYear = allSongs.filter { $0.year != nil }.count

            // Update state on main thread with animation
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    cachedUniqueArtistsCount = uniqueArtists
                    cachedTopViewedSongs = topViewed
                    cachedTopPerformedSongs = topPerformed
                    cachedRecentlyAddedSongs = recentlyAdded
                    cachedUnorganizedSongs = unorganized
                    cachedEmptyBooks = emptyBooks
                    cachedAverageSongsPerBook = avgSongsPerBook
                    cachedAverageSongsPerSet = avgSongsPerSet
                    cachedSongsByKey = songsByKey
                    cachedSongsByDecade = songsByDecade
                    cachedSongsWithYearCount = songsWithYear
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Computed Properties (Deprecated - Using Cached Values)

    private var uniqueArtistsCount: Int {
        Set(allSongs.compactMap { $0.artist }).count
    }

    private var topViewedSongs: [Song] {
        allSongs
            .filter { $0.timesViewed > 0 }
            .sorted { $0.timesViewed > $1.timesViewed }
    }

    private var topPerformedSongs: [Song] {
        allSongs
            .filter { $0.timesPerformed > 0 }
            .sorted { $0.timesPerformed > $1.timesPerformed }
    }

    private var recentlyAddedSongs: [Song] {
        allSongs.sorted { $0.createdAt > $1.createdAt }
    }

    private var unorganizedSongs: [Song] {
        allSongs.filter { song in
            let inBooks = song.books?.isEmpty ?? true
            let inSets = song.setEntries?.isEmpty ?? true
            return inBooks && inSets
        }
    }

    private var unorganizedSongsCount: Int {
        unorganizedSongs.count
    }

    private var emptyBooks: [Book] {
        allBooks.filter { $0.songs?.isEmpty ?? true }
    }

    private var emptyBooksCount: Int {
        emptyBooks.count
    }

    private var averageSongsPerBook: Double {
        guard !allBooks.isEmpty else { return 0 }
        let totalSongs = allBooks.reduce(0) { $0 + ($1.songs?.count ?? 0) }
        return Double(totalSongs) / Double(allBooks.count)
    }

    private var averageSongsPerSet: Double {
        guard !allSets.isEmpty else { return 0 }
        let totalSongs = allSets.reduce(0) { $0 + ($1.songEntries?.count ?? 0) }
        return Double(totalSongs) / Double(allSets.count)
    }

    private var songsByKey: [(key: String, count: Int)] {
        let keyCounts = Dictionary(grouping: allSongs.compactMap { $0.originalKey }, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        return keyCounts.map { (key: $0.key, count: $0.value) }
    }

    private var songsByDecade: [(decade: String, count: Int)] {
        let decades = allSongs.compactMap { song -> String? in
            guard let year = song.year else { return nil }
            let decade = (year / 10) * 10
            return "\(decade)s"
        }
        let decadeCounts = Dictionary(grouping: decades, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }
        return decadeCounts.map { (decade: $0.key, count: $0.value) }
    }

    private var songsWithYearCount: Int {
        allSongs.filter { $0.year != nil }.count
    }

    // MARK: - Helper Functions

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .blue
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func generateReport() {
        var report = "Lyra Library Statistics Report\n"
        report += "Generated: \(Date().formatted(date: .long, time: .shortened))\n"
        report += String(repeating: "=", count: 50) + "\n\n"

        // Overview
        report += "OVERVIEW\n"
        report += String(repeating: "-", count: 50) + "\n"
        report += "Total Songs: \(allSongs.count)\n"
        report += "Total Books: \(allBooks.count)\n"
        report += "Performance Sets: \(allSets.count)\n"
        report += "Unique Artists: \(cachedUniqueArtistsCount)\n\n"

        // Most Viewed
        if !cachedTopViewedSongs.isEmpty {
            report += "MOST VIEWED SONGS\n"
            report += String(repeating: "-", count: 50) + "\n"
            for (index, song) in cachedTopViewedSongs.prefix(10).enumerated() {
                let artist = song.artist ?? "Unknown"
                report += "\(index + 1). \(song.title) by \(artist) - \(song.timesViewed) views\n"
            }
            report += "\n"
        }

        // Most Performed
        if !cachedTopPerformedSongs.isEmpty {
            report += "MOST PERFORMED SONGS\n"
            report += String(repeating: "-", count: 50) + "\n"
            for (index, song) in cachedTopPerformedSongs.prefix(10).enumerated() {
                let artist = song.artist ?? "Unknown"
                report += "\(index + 1). \(song.title) by \(artist) - \(song.timesPerformed) performances\n"
            }
            report += "\n"
        }

        // Organization Health
        report += "ORGANIZATION HEALTH\n"
        report += String(repeating: "-", count: 50) + "\n"
        report += "Unorganized Songs: \(cachedUnorganizedSongs.count)\n"
        report += "Empty Books: \(cachedEmptyBooks.count)\n"
        report += "Average Songs per Book: \(String(format: "%.1f", cachedAverageSongsPerBook))\n"
        report += "Average Songs per Set: \(String(format: "%.1f", cachedAverageSongsPerSet))\n\n"

        // Songs by Key
        if !cachedSongsByKey.isEmpty {
            report += "SONGS BY KEY\n"
            report += String(repeating: "-", count: 50) + "\n"
            for data in cachedSongsByKey {
                report += "\(data.key): \(data.count) songs\n"
            }
            report += "\n"
        }

        exportText = report
    }
}

// MARK: - Overview Stat Row

struct OverviewStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            Text(label)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Organization Health Row

struct OrganizationHealthRow: View {
    enum Status {
        case good, warning, info

        var color: Color {
            switch self {
            case .good: return .green
            case .warning: return .orange
            case .info: return .blue
            }
        }

        var icon: String {
            switch self {
            case .good: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    let icon: String
    let label: String
    let value: String
    let status: Status
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(status.color)
                    .frame(width: 32)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 8) {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Image(systemName: status.icon)
                        .font(.caption)
                        .foregroundStyle(status.color)
                }

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .disabled(action == nil)
    }
}

// MARK: - Unorganized Songs View

struct UnorganizedSongsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let songs: [Song]

    @Query private var allBooks: [Book]

    @State private var selectedSong: Song?
    @State private var showBookPicker: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(songs) { song in
                        Button {
                            selectedSong = song
                            showBookPicker = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(song.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)

                                    if let artist = song.artist {
                                        Text(artist)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "folder.badge.plus")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                } header: {
                    Text("Unorganized Songs")
                } footer: {
                    Text("These songs are not in any books or performance sets. Tap to add them to a book.")
                }
            }
            .navigationTitle("Unorganized Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBookPicker) {
                if let song = selectedSong {
                    BookPickerForSongView(song: song, books: allBooks)
                }
            }
        }
    }
}

// MARK: - Empty Books View

struct EmptyBooksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let books: [Book]

    @State private var showDeleteConfirmation: Bool = false
    @State private var selectedBook: Book?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(books) { book in
                        HStack {
                            // Book icon with color
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill((Color(hex: book.color ?? "#4A90E2") ?? .blue).opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: book.icon ?? "book.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: book.color ?? "#4A90E2") ?? .blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Empty")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                selectedBook = book
                                showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                } header: {
                    Text("Empty Books")
                } footer: {
                    Text("These books don't contain any songs. You can delete them if they're no longer needed.")
                }
            }
            .navigationTitle("Empty Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Book?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let book = selectedBook {
                        deleteBook(book)
                    }
                }
            } message: {
                if let book = selectedBook {
                    Text("This will permanently delete \"\(book.name)\".")
                }
            }
        }
    }

    private func deleteBook(_ book: Book) {
        modelContext.delete(book)
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("❌ Error deleting book: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Book Picker for Song View

struct BookPickerForSongView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let song: Song
    let books: [Book]

    @State private var selectedBooks: Set<Book.ID> = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(books) { book in
                    Button {
                        if selectedBooks.contains(book.id) {
                            selectedBooks.remove(book.id)
                        } else {
                            selectedBooks.insert(book.id)
                        }
                    } label: {
                        HStack {
                            // Book icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill((Color(hex: book.color ?? "#4A90E2") ?? .blue).opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: book.icon ?? "book.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: book.color ?? "#4A90E2") ?? .blue)
                            }

                            Text(book.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedBooks.contains(book.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addToBooks()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedBooks.isEmpty)
                }
            }
        }
    }

    private func addToBooks() {
        for bookId in selectedBooks {
            guard let book = books.first(where: { $0.id == bookId }) else { continue }
            var bookSongs = book.songs ?? []
            if !bookSongs.contains(where: { $0.id == song.id }) {
                bookSongs.append(song)
                book.songs = bookSongs
                book.modifiedAt = Date()
            }
        }

        do {
            try modelContext.save()
            HapticManager.shared.saveSuccess()
            dismiss()
        } catch {
            print("❌ Error adding song to books: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Song.self, Book.self, PerformanceSet.self, SetEntry.self, configurations: config)

        // Create sample songs
        for i in 1...20 {
            let song = Song(title: "Song \(i)", artist: "Artist \(i % 5)", originalKey: ["C", "G", "D", "A", "E"].randomElement())
            song.timesViewed = Int.random(in: 0...50)
            song.timesPerformed = Int.random(in: 0...20)
            song.year = [1960, 1970, 1980, 1990, 2000, 2010, 2020].randomElement()
            container.mainContext.insert(song)
        }

        // Create sample books
        for i in 1...5 {
            let book = Book(name: "Book \(i)")
            book.color = "#4A90E2"
            container.mainContext.insert(book)
        }

        // Create sample sets
        for i in 1...3 {
            let set = PerformanceSet(name: "Set \(i)", scheduledDate: Date())
            container.mainContext.insert(set)
        }

        return container
    }()

    LibraryStatsView()
        .modelContainer(container)
}
