//
//  MainTabView.swift
//  Lyra
//
//  Main tab navigation container
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewContainer.shared.container)
}
