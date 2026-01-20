//
//  BookDetailView.swift
//  Lyra
//
//  Detail view for a book showing all songs in the collection
//

import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let book: Book

    @State private var showSongPicker: Bool = false
    @State private var showEditBook: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showExportOptions: Bool = false
    @State private var shareItem: ShareItem?
    @State private var exportError: Error?
    @State private var showError: Bool = false

    private var songs: [Song] {
        book.songs ?? []
    }

    private var bookColor: Color {
        if let colorHex = book.color {
            return Color(hex: colorHex) ?? .accentColor
        }
        return .accentColor
    }

    var body: some View {
        List {
            // Book info header
            Section {
                HStack(spacing: 16) {
                    // Book icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(bookColor.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: book.icon ?? "book.fill")
                            .font(.largeTitle)
                            .foregroundStyle(bookColor)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let description = book.bookDescription, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Text("\(songs.count) \(songs.count == 1 ? "song" : "songs")")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            // Songs section
            Section {
                if songs.isEmpty {
                    BookEmptyStateView(showSongPicker: $showSongPicker)
                } else {
                    ForEach(songs) { song in
                        NavigationLink(destination: SongDisplayView(song: song)) {
                            BookSongRowView(song: song)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                HapticManager.shared.swipeAction()
                                removeSong(song)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("Songs")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showSongPicker = true
                    } label: {
                        Label("Add Songs", systemImage: "plus")
                    }

                    Button {
                        showEditBook = true
                    } label: {
                        Label("Edit Book", systemImage: "pencil")
                    }

                    Divider()

                    Button {
                        showExportOptions = true
                    } label: {
                        Label("Export Book", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        printBook()
                    } label: {
                        Label("Print Book", systemImage: "printer")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Book", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Book options")
            }
        }
        .sheet(isPresented: $showSongPicker) {
            SongPickerView(book: book)
        }
        .sheet(isPresented: $showEditBook) {
            EditBookView(book: book)
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(
                exportType: .book(book),
                onExport: { format, configuration in
                    exportBook(format: format, configuration: configuration)
                }
            )
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: item.items)
        }
        .alert("Delete Book?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteBook()
            }
        } message: {
            Text("This will permanently delete \"\(book.name)\". Songs in this book will not be deleted.")
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = exportError {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Actions

    private func removeSong(_ song: Song) {
        guard var bookSongs = book.songs else { return }

        bookSongs.removeAll(where: { $0.id == song.id })
        book.songs = bookSongs
        book.modifiedAt = Date()

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("❌ Error removing song from book: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }

    private func deleteBook() {
        modelContext.delete(book)

        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("❌ Error deleting book: \(error.localizedDescription)")
            HapticManager.shared.operationFailed()
        }
    }

    // MARK: - Export Actions

    private func exportBook(format: ExportManager.ExportFormat, configuration: PDFExporter.PDFConfiguration) {
        Task {
            do {
                let data = try ExportManager.shared.exportBook(book, format: format, configuration: configuration)
                let filename = "\(book.name).\(format.fileExtension)"

                // Save to temporary file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try data.write(to: tempURL)

                // Show share sheet
                await MainActor.run {
                    shareItem = ShareItem(items: [tempURL])
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    showError = true
                    HapticManager.shared.operationFailed()
                }
            }
        }
    }

    private func printBook() {
        Task {
            do {
                let data = try ExportManager.shared.exportBook(book, format: .pdf)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(book.name).pdf")
                try data.write(to: tempURL)

                await MainActor.run {
                    let printController = UIPrintInteractionController.shared
                    printController.printingItem = tempURL

                    let printInfo = UIPrintInfo.printInfo()
                    printInfo.outputType = .general
                    printInfo.jobName = book.name
                    printController.printInfo = printInfo

                    printController.present(animated: true) { _, _, _ in }
                }
            } catch {
                await MainActor.run {
                    exportError = error
                    showError = true
                    HapticManager.shared.operationFailed()
                }
            }
        }
    }
}

// MARK: - Book Song Row View

struct BookSongRowView: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)

                if let artist = song.artist {
                    Text(artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Metadata badges
                if song.originalKey != nil || (song.capo ?? 0) > 0 {
                    HStack(spacing: 6) {
                        if let key = song.originalKey {
                            MetadataBadge(
                                icon: "music.note",
                                text: key,
                                color: .blue
                            )
                        }

                        if let capo = song.capo, capo > 0 {
                            MetadataBadge(
                                icon: "guitars",
                                text: "Capo \(capo)",
                                color: .orange
                            )
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Metadata Badge

struct MetadataBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))

            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Book Empty State View

struct BookEmptyStateView: View {
    @Binding var showSongPicker: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Songs Yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Add songs to this book to organize your collection")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showSongPicker = true
            } label: {
                Label("Add Songs", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Book with Songs") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, Song.self, configurations: config)

    let book = Book(name: "Classic Hymns", description: "Traditional hymns and worship songs")
    book.color = "#4A90E2"
    book.icon = "music.note.list"

    let song1 = Song(title: "Amazing Grace", artist: "John Newton", originalKey: "G")
    song1.capo = 2
    let song2 = Song(title: "How Great Thou Art", artist: "Carl Boberg", originalKey: "C")
    let song3 = Song(title: "It Is Well", artist: "Horatio Spafford", originalKey: "D")
    song3.capo = 4
    book.songs = [song1, song2, song3]

    container.mainContext.insert(book)
    container.mainContext.insert(song1)
    container.mainContext.insert(song2)
    container.mainContext.insert(song3)

    return NavigationStack {
        BookDetailView(book: book)
    }
    .modelContainer(container)
}

#Preview("Empty Book") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, Song.self, configurations: config)

    let book = Book(name: "New Collection", description: "A fresh collection waiting for songs")
    book.color = "#9B59B6"
    book.icon = "books.vertical.fill"

    container.mainContext.insert(book)

    return NavigationStack {
        BookDetailView(book: book)
    }
    .modelContainer(container)
}
