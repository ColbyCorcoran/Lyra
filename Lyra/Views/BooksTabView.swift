//
//  BooksTabView.swift
//  Lyra
//
//  Books tab with management functionality
//

import SwiftUI
import SwiftData

struct BooksTabView: View {
    @State private var showAddBookSheet: Bool = false
    @State private var showSearch: Bool = false

    var body: some View {
        NavigationStack {
            BookListView()
                .navigationTitle("Books")
                .toolbar {
                    // Search button
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showSearch = true
                        } label: {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                    }

                    // Add button
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddBookSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add book")
                    }
                }
        }
        .sheet(isPresented: $showAddBookSheet) {
            AddBookView()
                .iPadSheetPresentation()
        }
        .sheet(isPresented: $showSearch) {
            LibrarySearchView()
                .iPadSheetPresentation(detents: [.large])
        }
    }
}

#Preview {
    BooksTabView()
        .modelContainer(PreviewContainer.shared.container)
}
