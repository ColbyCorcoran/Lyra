//
//  SetsTabView.swift
//  Lyra
//
//  Performance sets tab with management functionality
//

import SwiftUI
import SwiftData

struct SetsTabView: View {
    @State private var showAddSetSheet: Bool = false
    @State private var showSearch: Bool = false

    var body: some View {
        NavigationStack {
            SetListView()
                .navigationTitle("Sets")
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
                            showAddSetSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add set")
                    }
                }
        }
        .sheet(isPresented: $showAddSetSheet) {
            AddPerformanceSetView()
                .iPadSheetPresentation(detents: [.large])
        }
        .sheet(isPresented: $showSearch) {
            LibrarySearchView()
                .iPadSheetPresentation(detents: [.large])
        }
    }
}

#Preview {
    SetsTabView()
        .modelContainer(PreviewContainer.shared.container)
}
