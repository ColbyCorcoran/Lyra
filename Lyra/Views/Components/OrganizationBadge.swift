//
//  OrganizationBadge.swift
//  Lyra
//
//  Compact badge showing song organization status
//

import SwiftUI
import SwiftData

struct OrganizationBadge: View {
    let song: Song

    private var organizationState: OrganizationState {
        let hasBooks = !(song.books?.isEmpty ?? true)
        let hasSets = !(song.setEntries?.isEmpty ?? true)

        switch (hasBooks, hasSets) {
        case (true, true):
            return .both
        case (true, false):
            return .booksOnly
        case (false, true):
            return .setsOnly
        case (false, false):
            return .none
        }
    }

    var body: some View {
        Group {
            switch organizationState {
            case .booksOnly:
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 14))
                    .opacity(0.8)
                    .accessibilityLabel("In \(song.books?.count ?? 0) book\(song.books?.count == 1 ? "" : "s")")

            case .setsOnly:
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 14))
                    .opacity(0.8)
                    .accessibilityLabel("In \(song.setEntries?.count ?? 0) set\(song.setEntries?.count == 1 ? "" : "s")")

            case .both:
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(.purple)
                    .font(.system(size: 14))
                    .opacity(0.8)
                    .accessibilityLabel("In \(song.books?.count ?? 0) book\(song.books?.count == 1 ? "" : "s") and \(song.setEntries?.count ?? 0) set\(song.setEntries?.count == 1 ? "" : "s")")

            case .none:
                EmptyView()
            }
        }
        .frame(width: 20, height: 20)
    }

    enum OrganizationState {
        case none
        case booksOnly
        case setsOnly
        case both
    }
}

// MARK: - Preview

#Preview("Books Only") {
    let song = Song(title: "Amazing Grace", artist: "Traditional")
    let book = Book(name: "Hymns")
    song.books = [book]

    return HStack {
        Text("Song Title")
        OrganizationBadge(song: song)
    }
    .padding()
}

#Preview("Sets Only") {
    let song = Song(title: "How Great Thou Art", artist: "Traditional")
    let set = PerformanceSet(name: "Sunday Service")
    let entry = SetEntry(song: song, orderIndex: 0)
    entry.performanceSet = set
    song.setEntries = [entry]

    return HStack {
        Text("Song Title")
        OrganizationBadge(song: song)
    }
    .padding()
}

#Preview("Both") {
    let song = Song(title: "Great Is Thy Faithfulness", artist: "Traditional")
    let book = Book(name: "Hymns")
    song.books = [book]
    let set = PerformanceSet(name: "Sunday Service")
    let entry = SetEntry(song: song, orderIndex: 0)
    entry.performanceSet = set
    song.setEntries = [entry]

    return HStack {
        Text("Song Title")
        OrganizationBadge(song: song)
    }
    .padding()
}

#Preview("None") {
    let song = Song(title: "Unorganized Song", artist: "Artist")

    return HStack {
        Text("Song Title")
        OrganizationBadge(song: song)
    }
    .padding()
}
