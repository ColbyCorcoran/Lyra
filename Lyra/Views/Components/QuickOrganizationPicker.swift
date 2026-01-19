//
//  QuickOrganizationPicker.swift
//  Lyra
//
//  Quick picker sheet for adding songs to books/sets from context menu
//

import SwiftUI
import SwiftData

struct QuickOrganizationPicker: View {
    let song: Song
    let mode: PickerMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Book.name, order: .forward) private var allBooks: [Book]
    @Query(sort: \PerformanceSet.name, order: .forward) private var allSets: [PerformanceSet]

    @State private var showNewItemSheet = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    enum PickerMode {
        case book
        case set

        var title: String {
            switch self {
            case .book: return "Add to Book"
            case .set: return "Add to Set"
            }
        }

        var icon: String {
            switch self {
            case .book: return "folder.badge.plus"
            case .set: return "calendar.badge.plus"
            }
        }

        var createLabel: String {
            switch self {
            case .book: return "Create New Book"
            case .set: return "Create New Set"
            }
        }
    }

    private var songBooks: [Book] {
        song.books ?? []
    }

    private var songSets: [PerformanceSet] {
        let entries = song.setEntries ?? []
        return Array(Set(entries.compactMap { $0.performanceSet }))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    listContent
                }

                Section {
                    createButton
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showNewItemSheet) {
                sheetContent
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var listContent: some View {
        switch mode {
        case .book:
            if allBooks.isEmpty {
                Text("No books available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(allBooks) { book in
                    BookRow(
                        book: book,
                        isSelected: songBooks.contains(where: { $0.id == book.id })
                    ) {
                        handleBookSelection(book)
                    }
                }
            }

        case .set:
            if allSets.isEmpty {
                Text("No sets available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(allSets) { set in
                    SetRow(
                        set: set,
                        isSelected: songSets.contains(where: { $0.id == set.id })
                    ) {
                        handleSetSelection(set)
                    }
                }
            }
        }
    }

    private var createButton: some View {
        Button {
            showNewItemSheet = true
        } label: {
            Label(mode.createLabel, systemImage: "plus.circle.fill")
                .foregroundStyle(.blue)
        }
    }

    @ViewBuilder
    private var sheetContent: some View {
        switch mode {
        case .book:
            AddBookView()
        case .set:
            AddPerformanceSetView()
        }
    }

    // MARK: - Actions

    private func handleBookSelection(_ book: Book) {
        do {
            if songBooks.contains(where: { $0.id == book.id }) {
                // Remove from book
                try DataManager.shared.removeSongFromBook(song, book: book)
                HapticManager.shared.success()
            } else {
                // Add to book
                try DataManager.shared.addSongToBook(song, book: book)
                HapticManager.shared.success()
            }

            // Auto-dismiss after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        } catch {
            errorMessage = "Unable to update book membership."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }

    private func handleSetSelection(_ set: PerformanceSet) {
        do {
            let existingEntry = song.setEntries?.first(where: { $0.performanceSet?.id == set.id })

            if let entry = existingEntry {
                // Remove from set
                try DataManager.shared.removeSongFromPerformanceSet(entry, set: set)
                HapticManager.shared.success()
            } else {
                // Add to set
                _ = try DataManager.shared.addSongToPerformanceSet(song, set: set)
                HapticManager.shared.success()
            }

            // Auto-dismiss after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        } catch {
            errorMessage = "Unable to update set membership."
            showErrorAlert = true
            HapticManager.shared.operationFailed()
        }
    }
}

// MARK: - Row Components

struct BookRow: View {
    let book: Book
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Book icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(bookColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: book.icon ?? "folder.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(bookColor)
                }

                // Book name
                Text(book.name)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var bookColor: Color {
        Color(hex: book.color ?? "") ?? .blue
    }
}

struct SetRow: View {
    let set: PerformanceSet
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Set icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 16))
                        .foregroundStyle(.green)
                }

                // Set name
                Text(set.name)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Book Picker") {
    let song = Song(title: "Amazing Grace", artist: "Traditional")
    let book1 = Book(name: "Hymns")
    song.books = [book1]

    return QuickOrganizationPicker(song: song, mode: .book)
        .modelContainer(PreviewContainer.shared.container)
}

#Preview("Set Picker") {
    let song = Song(title: "How Great Thou Art", artist: "Traditional")
    let set1 = PerformanceSet(name: "Sunday Service")
    let entry = SetEntry(song: song, orderIndex: 0)
    entry.performanceSet = set1
    song.setEntries = [entry]

    return QuickOrganizationPicker(song: song, mode: .set)
        .modelContainer(PreviewContainer.shared.container)
}
