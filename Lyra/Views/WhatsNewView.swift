//
//  WhatsNewView.swift
//  Lyra
//
//  Shows new features and improvements after app updates
//

import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("whatsNew.lastSeenVersion") private var lastSeenVersion: String = "0.0.0"

    // Current version's features
    private let currentVersion = "1.0.0"
    private let features: [WhatsNewFeature] = [
        WhatsNewFeature(
            title: "Autoscroll",
            description: "Hands-free scrolling with adjustable speed. Now enabled by default for all songs!",
            icon: "play.fill",
            color: .green,
            isNew: true
        ),
        WhatsNewFeature(
            title: "Metronome",
            description: "Built-in metronome with visual feedback, multiple sound presets, and tap tempo",
            icon: "metronome.fill",
            color: .red,
            isNew: true
        ),
        WhatsNewFeature(
            title: "Backing Tracks",
            description: "Add audio files to songs with full mixer controls for volume, pan, mute, and solo",
            icon: "waveform",
            color: .purple,
            isNew: true
        ),
        WhatsNewFeature(
            title: "Display Settings",
            description: "Comprehensive customization with fonts, colors, layouts, accessibility features, and presets",
            icon: "textformat.size",
            color: .blue,
            isNew: true
        ),
        WhatsNewFeature(
            title: "Templates",
            description: "Multi-column layouts with customizable typography for optimal chart display",
            icon: "square.grid.2x2",
            color: .orange,
            isNew: true
        ),
        WhatsNewFeature(
            title: "Annotations & Drawing",
            description: "Add sticky notes and draw directly on charts for performance cues and reminders",
            icon: "pencil.tip.crop.circle",
            color: .pink,
            isNew: true
        ),
        WhatsNewFeature(
            title: "Local Backups",
            description: "Automatic daily/weekly backups with export to Files app. Keeps last 5 backups safe",
            icon: "externaldrive.fill",
            color: .green,
            isNew: true
        ),
        WhatsNewFeature(
            title: "OnSong Import",
            description: "Import your existing OnSong library from Files app, Dropbox, Google Drive, or iCloud",
            icon: "arrow.down.doc.fill",
            color: .blue,
            isNew: true
        ),
        WhatsNewFeature(
            title: "Bulk Export",
            description: "Export entire library as ZIP in ChordPro, PDF, plain text, or JSON format",
            icon: "arrow.up.doc.fill",
            color: .indigo,
            isNew: true
        ),
        WhatsNewFeature(
            title: "Low Light Mode",
            description: "Performance-optimized display with customizable colors for dark venues and stages",
            icon: "moon.fill",
            color: .purple,
            isNew: true
        ),
        WhatsNewFeature(
            title: "Transpose & Capo",
            description: "Transpose to any key with automatic capo suggestions. Temporary or permanent transpositions",
            icon: "arrow.up.arrow.down",
            color: .cyan,
            isNew: true
        ),
        WhatsNewFeature(
            title: "Song Info",
            description: "View comprehensive metadata, statistics, and performance details for each song",
            icon: "info.circle.fill",
            color: .teal,
            isNew: true
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Features grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(features) { feature in
                            FeatureCard(feature: feature)
                        }
                    }

                    // Footer
                    footerSection
                }
                .padding()
            }
            .navigationTitle("What's New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        markAsSeen()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // App icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "music.note")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text("Welcome to Lyra \(currentVersion)")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Your ultimate chord chart companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 16) {
            Divider()

            VStack(spacing: 12) {
                Text("Thank you for using Lyra!")
                    .font(.headline)

                Text("We hope these new features enhance your performance experience. If you have feedback or suggestions, we'd love to hear from you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Link(destination: URL(string: "https://github.com/yourusername/lyra")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("Visit our website")
                    }
                    .font(.subheadline)
                }
                .padding(.top, 8)
            }

            Divider()

            Text("Version \(currentVersion)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical)
    }

    // MARK: - Actions

    private func markAsSeen() {
        lastSeenVersion = currentVersion
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let feature: WhatsNewFeature

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: feature.icon)
                    .font(.title2)
                    .foregroundStyle(feature.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(feature.title)
                        .font(.headline)

                    if feature.isNew {
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(feature.color)
                            .clipShape(Capsule())
                    }
                }

                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - What's New Feature

struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isNew: Bool
}

// MARK: - What's New Manager

@Observable
class WhatsNewManager {
    static let shared = WhatsNewManager()

    private let currentVersion = "1.0.0"

    private init() {}

    /// Checks if user should see What's New screen
    func shouldShowWhatsNew() -> Bool {
        let lastSeen = UserDefaults.standard.string(forKey: "whatsNew.lastSeenVersion") ?? "0.0.0"
        return lastSeen != currentVersion
    }

    /// Marks What's New as seen for current version
    func markWhatsNewAsSeen() {
        UserDefaults.standard.set(currentVersion, forKey: "whatsNew.lastSeenVersion")
    }

    /// Gets the current app version
    var appVersion: String {
        currentVersion
    }
}

// MARK: - Preview

#Preview("What's New") {
    WhatsNewView()
}

#Preview("Feature Card") {
    FeatureCard(
        feature: WhatsNewFeature(
            title: "Autoscroll",
            description: "Hands-free scrolling with adjustable speed and foot pedal support",
            icon: "play.fill",
            color: .green,
            isNew: true
        )
    )
    .padding()
}
