//
//  BulkImportProgressView.swift
//  Lyra
//
//  Progress view for bulk import operations
//

import SwiftUI
import SwiftData

struct BulkImportProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var queueManager = ImportQueueManager.shared

    // Post-import actions
    @State private var showPostImportActions: Bool = false
    @State private var navigateToImported: Bool = false
    @State private var showAddToBookSheet: Bool = false
    @State private var showCreateSetSheet: Bool = false
    @State private var showErrorLog: Bool = false
    @State private var errorLogText: String = ""

    // Duplicate handling
    @State private var showDuplicateOptions: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if queueManager.isImporting {
                    importingView
                } else {
                    resultsView
                }
            }
            .navigationTitle("Bulk Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if queueManager.isImporting {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") {
                            queueManager.cancelImport()
                        }
                        .foregroundStyle(.red)
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            queueManager.clearQueue()
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showErrorLog) {
                ErrorLogView(errorLog: errorLogText)
            }
            .interactiveDismissDisabled(queueManager.isImporting)
        }
        .task {
            await queueManager.startImport(modelContext: modelContext)
        }
    }

    // MARK: - Importing View

    private var importingView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Overall Progress
            VStack(spacing: 12) {
                Text("\(queueManager.currentFileIndex) of \(queueManager.totalFiles)")
                    .font(.title2)
                    .fontWeight(.semibold)

                ProgressView(value: queueManager.progress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .frame(width: 250)

                Text("\(Int(queueManager.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Current File
            if let currentItem = queueManager.currentItem {
                VStack(spacing: 8) {
                    Text("Importing")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.blue)

                        Text(currentItem.fileName)
                            .font(.body)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 8)
            }

            Spacer()

            // Queue Status
            queueStatusView
                .padding(.horizontal)
                .padding(.bottom, 24)
        }
        .padding()
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary
                VStack(spacing: 16) {
                    if queueManager.isCancelled {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)

                        Text("Import Cancelled")
                            .font(.title2)
                            .fontWeight(.semibold)
                    } else if queueManager.getResult().hasFailures {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)

                        Text("Import Completed with Errors")
                            .font(.title2)
                            .fontWeight(.semibold)
                    } else if queueManager.getResult().hasDuplicates {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)

                        Text("Import Complete")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Some files were skipped as duplicates")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)

                        Text("Import Complete")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    // Stats
                    resultStatsView
                }
                .padding(.top, 32)

                // Post-import actions
                if !queueManager.importedSongs.isEmpty {
                    postImportActionsView
                }

                // Failed items
                if !queueManager.failedItems.isEmpty {
                    failedItemsView
                }

                // Duplicate items
                if !queueManager.duplicateItems.isEmpty {
                    duplicateItemsView
                }

                // Queue list
                queueListView
            }
            .padding()
        }
    }

    // MARK: - Queue Status

    private var queueStatusView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Completed: \(queueManager.importedSongs.count)")
                Spacer()
            }

            if !queueManager.failedItems.isEmpty {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("Failed: \(queueManager.failedItems.count)")
                    Spacer()
                }
            }

            if !queueManager.duplicateItems.isEmpty {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundStyle(.orange)
                    Text("Duplicates: \(queueManager.duplicateItems.count)")
                    Spacer()
                }
            }

            let pendingCount = queueManager.queue.filter { $0.status == .pending || $0.status == .processing }.count
            if pendingCount > 0 {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.gray)
                    Text("Pending: \(pendingCount)")
                    Spacer()
                }
            }
        }
        .font(.subheadline)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8)
        )
    }

    // MARK: - Result Stats

    private var resultStatsView: some View {
        let result = queueManager.getResult()

        return HStack(spacing: 32) {
            StatColumn(
                icon: "checkmark.circle.fill",
                color: .green,
                value: result.successCount,
                label: "Imported"
            )

            if result.failedCount > 0 {
                StatColumn(
                    icon: "xmark.circle.fill",
                    color: .red,
                    value: result.failedCount,
                    label: "Failed"
                )
            }

            if result.duplicateCount > 0 {
                StatColumn(
                    icon: "doc.on.doc.fill",
                    color: .orange,
                    value: result.duplicateCount,
                    label: "Duplicates"
                )
            }

            if result.skippedCount > 0 {
                StatColumn(
                    icon: "forward.fill",
                    color: .gray,
                    value: result.skippedCount,
                    label: "Skipped"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Post-Import Actions

    private var postImportActionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                Button {
                    queueManager.clearQueue()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green)
                        Text("View Library")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    showAddToBookSheet = true
                } label: {
                    HStack {
                        Image(systemName: "book")
                            .foregroundStyle(.blue)
                        Text("Add All to Book")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    showCreateSetSheet = true
                } label: {
                    HStack {
                        Image(systemName: "music.note.list")
                            .foregroundStyle(.purple)
                        Text("Create Set from Imports")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showAddToBookSheet) {
            QuickAddToBookView(songs: queueManager.importedSongs)
        }
        .sheet(isPresented: $showCreateSetSheet) {
            QuickCreateSetView(songs: queueManager.importedSongs)
        }
    }

    // MARK: - Failed Items

    private var failedItemsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Failed Imports")
                    .font(.headline)

                Spacer()

                Button {
                    Task {
                        await queueManager.retryFailedImports(modelContext: modelContext)
                    }
                } label: {
                    Text("Retry All")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                Button {
                    errorLogText = queueManager.exportErrorLog()
                    showErrorLog = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(queueManager.failedItems) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.fileName)
                                .font(.body)

                            if let error = item.error {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Duplicate Items

    private var duplicateItemsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Duplicate Files")
                    .font(.headline)

                Spacer()

                Button {
                    showDuplicateOptions = true
                } label: {
                    Text("Import Anyway")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(queueManager.duplicateItems.prefix(5)) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "doc.on.doc.fill")
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.fileName)
                                .font(.body)

                            if let error = item.error {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if queueManager.duplicateItems.count > 5 {
                    Text("+ \(queueManager.duplicateItems.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading)
                }
            }
            .padding(.horizontal)
        }
        .alert("Import Duplicates?", isPresented: $showDuplicateOptions) {
            Button("Cancel", role: .cancel) {}
            Button("Import All Duplicates") {
                importDuplicatesAnyway()
            }
        } message: {
            Text("This will import all \(queueManager.duplicateItems.count) files that were detected as duplicates. You'll have multiple copies of similar songs.")
        }
    }

    // MARK: - Queue List

    private var queueListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Files")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 4) {
                ForEach(queueManager.queue) { item in
                    QueueItemRow(item: item)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func importDuplicatesAnyway() {
        Task {
            // Temporarily disable duplicate checking
            let previousSetting = queueManager.checkDuplicates
            queueManager.checkDuplicates = false

            // Reset duplicate items to pending
            for item in queueManager.duplicateItems {
                if let index = queueManager.queue.firstIndex(where: { $0.id == item.id }) {
                    queueManager.queue[index].status = .pending
                    queueManager.queue[index].error = nil
                }
            }

            queueManager.duplicateItems.removeAll()

            // Re-run import
            await queueManager.startImport(modelContext: modelContext)

            // Restore setting
            queueManager.checkDuplicates = previousSetting
        }
    }
}

// MARK: - Supporting Views

struct QueueItemRow: View {
    let item: ImportQueueItem

    var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(.body)
                    .lineLimit(1)

                if let error = item.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(.gray)
        case .processing:
            ProgressView()
                .controlSize(.small)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .skipped:
            Image(systemName: "forward.fill")
                .foregroundStyle(.gray)
        case .duplicate:
            Image(systemName: "doc.on.doc.fill")
                .foregroundStyle(.orange)
        }
    }

    private var backgroundColor: Color {
        switch item.status {
        case .pending, .processing:
            return Color(.tertiarySystemBackground)
        case .completed:
            return Color.green.opacity(0.1)
        case .failed:
            return Color.red.opacity(0.1)
        case .skipped:
            return Color.gray.opacity(0.1)
        case .duplicate:
            return Color.orange.opacity(0.1)
        }
    }
}

struct StatColumn: View {
    let icon: String
    let color: Color
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ErrorLogView: View {
    @Environment(\.dismiss) private var dismiss
    let errorLog: String

    @State private var showShareSheet: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(errorLog)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Error Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: [errorLog])
            }
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Quick Add to Book View

struct QuickAddToBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var books: [Book]

    let songs: [Song]

    @State private var selectedBook: Book?
    @State private var newBookName: String = ""
    @State private var createNew: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Create New Book", isOn: $createNew)

                    if createNew {
                        TextField("Book Name", text: $newBookName)
                    } else {
                        Picker("Select Book", selection: $selectedBook) {
                            Text("Select a book").tag(nil as Book?)
                            ForEach(books) { book in
                                Text(book.name).tag(book as Book?)
                            }
                        }
                    }
                }

                Section {
                    Text("This will add \(songs.count) songs to the book")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add to Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addToBook()
                        dismiss()
                    }
                    .disabled(!canAdd)
                }
            }
        }
    }

    private var canAdd: Bool {
        if createNew {
            return !newBookName.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            return selectedBook != nil
        }
    }

    private func addToBook() {
        let book: Book

        if createNew {
            book = Book(name: newBookName)
            modelContext.insert(book)
        } else {
            guard let selectedBook else { return }
            book = selectedBook
        }

        for song in songs {
            if book.songs == nil {
                book.songs = []
            }
            book.songs?.append(song)
        }

        try? modelContext.save()
        HapticManager.shared.success()
    }
}

// MARK: - Quick Create Set View

struct QuickCreateSetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let songs: [Song]

    @State private var setName: String = ""
    @State private var setDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Set Name", text: $setName)

                    DatePicker("Date", selection: $setDate, displayedComponents: [.date])
                }

                Section {
                    Text("This will create a set with \(songs.count) songs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Create Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createSet()
                        dismiss()
                    }
                    .disabled(setName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createSet() {
        let performanceSet = PerformanceSet(
            name: setName,
            scheduledDate: setDate
        )

        modelContext.insert(performanceSet)

        for (index, song) in songs.enumerated() {
            let setEntry = SetEntry(
                song: song,
                orderIndex: index
            )
            modelContext.insert(setEntry)
            if performanceSet.songEntries == nil {
                performanceSet.songEntries = []
            }
            performanceSet.songEntries?.append(setEntry)
        }

        try? modelContext.save()
        HapticManager.shared.success()
    }
}

// MARK: - Previews

#Preview("Progress") {
    BulkImportProgressView()
        .modelContainer(PreviewContainer.shared.container)
}
