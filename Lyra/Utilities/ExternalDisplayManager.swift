//
//  ExternalDisplayManager.swift
//  Lyra
//
//  Service for managing external displays and projection
//

import Foundation
import UIKit
import SwiftUI
import Observation

/// Manager for external displays and projection
@Observable
class ExternalDisplayManager {
    static let shared = ExternalDisplayManager()

    // MARK: - Properties

    /// Available external displays
    private(set) var externalDisplays: [ExternalDisplayInfo] = []

    /// Currently selected external display
    private(set) var selectedDisplay: ExternalDisplayInfo?

    /// External display window
    private var externalWindow: UIWindow?

    /// Current configuration
    var configuration: ExternalDisplayConfiguration {
        didSet {
            saveConfiguration()
            applyConfiguration()
            NotificationCenter.default.post(name: .externalDisplayConfigurationChanged, object: self)
        }
    }

    /// Current content to display
    var content: ExternalDisplayContent = ExternalDisplayContent() {
        didSet {
            updateExternalDisplay()
            NotificationCenter.default.post(name: .externalDisplayContentChanged, object: self)
        }
    }

    /// Display profiles
    private(set) var profiles: [ExternalDisplayProfile] = []

    /// Currently active profile
    private(set) var activeProfile: ExternalDisplayProfile?

    /// Whether an external display is connected and active
    var isExternalDisplayActive: Bool {
        externalWindow != nil && selectedDisplay != nil
    }

    /// Whether external display is currently showing content
    var isDisplayingContent: Bool {
        isExternalDisplayActive && !content.isEmpty
    }

    // MARK: - Initialization

    private init() {
        self.configuration = ExternalDisplayConfiguration()
        setupNotificationObservers()
        scanForExternalDisplays()
        loadConfiguration()
        loadProfiles()
    }

    // MARK: - Setup

    private func setupNotificationObservers() {
        // Listen for display connection/disconnection
        NotificationCenter.default.addObserver(
            forName: UIScreen.didConnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleDisplayConnected(notification)
        }

        NotificationCenter.default.addObserver(
            forName: UIScreen.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleDisplayDisconnected(notification)
        }
    }

    private func handleDisplayConnected(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }

        scanForExternalDisplays()

        // Auto-connect to the new display
        if let display = externalDisplays.first(where: { $0.screen == screen }) {
            connectToDisplay(display)
        }

        NotificationCenter.default.post(
            name: .externalDisplayConnected,
            object: self,
            userInfo: ["screen": screen]
        )
    }

    private func handleDisplayDisconnected(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }

        if selectedDisplay?.screen == screen {
            disconnectDisplay()
        }

        scanForExternalDisplays()

        NotificationCenter.default.post(
            name: .externalDisplayDisconnected,
            object: self,
            userInfo: ["screen": screen]
        )
    }

    // MARK: - Display Detection

    func scanForExternalDisplays() {
        externalDisplays = UIScreen.screens
            .filter { $0 != UIScreen.main }
            .map { ExternalDisplayInfo(screen: $0) }
    }

    // MARK: - Display Connection

    func connectToDisplay(_ display: ExternalDisplayInfo) {
        // Disconnect existing display first
        disconnectDisplay()

        selectedDisplay = display

        // Create window on external screen
        let window = UIWindow(frame: display.screen.bounds)
        window.screen = display.screen

        // Create hosting controller with projection view
        let projectionView = ExternalProjectionView(
            configuration: configuration,
            content: content
        )
        let hostingController = UIHostingController(rootView: projectionView)
        hostingController.view.backgroundColor = .clear

        window.rootViewController = hostingController
        window.isHidden = false

        externalWindow = window

        // Apply current configuration
        applyConfiguration()
    }

    func disconnectDisplay() {
        externalWindow?.isHidden = true
        externalWindow = nil
        selectedDisplay = nil
    }

    // MARK: - Configuration

    private func applyConfiguration() {
        updateExternalDisplay()
    }

    func applyProfile(_ profile: ExternalDisplayProfile) {
        activeProfile = profile
        configuration = profile.configuration
        saveActiveProfile(profile.id)
    }

    private func updateExternalDisplay() {
        guard let window = externalWindow,
              let hostingController = window.rootViewController as? UIHostingController<ExternalProjectionView> else {
            return
        }

        // Update the view with new content and configuration
        let newView = ExternalProjectionView(
            configuration: configuration,
            content: content
        )
        hostingController.rootView = newView
    }

    // MARK: - Content Management

    func displaySection(_ section: String, nextSection: String? = nil) {
        var newContent = content
        newContent.currentSection = section
        newContent.nextSection = nextSection
        content = newContent
    }

    func displayLine(_ line: String, nextLine: String? = nil) {
        var newContent = content
        newContent.currentLine = line
        newContent.nextLine = nextLine
        content = newContent
    }

    func displaySong(title: String, artist: String? = nil) {
        var newContent = content
        newContent.songTitle = title
        newContent.artist = artist
        content = newContent
    }

    func clearDisplay() {
        content = ExternalDisplayContent()
    }

    func blankDisplay() {
        // Keep connection but show blank screen
        var newContent = ExternalDisplayContent()
        // Set a flag to indicate intentional blank
        newContent.currentSection = ""
        content = newContent
    }

    // MARK: - Profile Management

    func addProfile(_ profile: ExternalDisplayProfile) {
        profiles.append(profile)
        saveProfiles()
    }

    func removeProfile(_ profile: ExternalDisplayProfile) {
        profiles.removeAll { $0.id == profile.id }
        saveProfiles()

        if activeProfile?.id == profile.id {
            activeProfile = nil
        }
    }

    func updateProfile(_ profile: ExternalDisplayProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            var updatedProfile = profile
            updatedProfile.dateModified = Date()
            profiles[index] = updatedProfile
            saveProfiles()

            if activeProfile?.id == profile.id {
                activeProfile = updatedProfile
            }
        }
    }

    // MARK: - Persistence

    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: "externalDisplayConfiguration"),
           let decoded = try? JSONDecoder().decode(ExternalDisplayConfiguration.self, from: data) {
            configuration = decoded
        }
    }

    private func saveConfiguration() {
        if let encoded = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(encoded, forKey: "externalDisplayConfiguration")
        }
    }

    private func loadProfiles() {
        // Load built-in profiles
        profiles = [
            .worshipService,
            .concert,
            .rehearsal,
            .confidenceMonitor
        ]

        // Load custom profiles
        if let data = UserDefaults.standard.data(forKey: "externalDisplayProfiles"),
           let decoded = try? JSONDecoder().decode([ExternalDisplayProfile].self, from: data) {
            profiles.append(contentsOf: decoded.filter { !$0.isBuiltIn })
        }

        // Load active profile
        if let profileID = UserDefaults.standard.string(forKey: "activeDisplayProfile"),
           let uuid = UUID(uuidString: profileID) {
            activeProfile = profiles.first { $0.id == uuid }
            if let profile = activeProfile {
                configuration = profile.configuration
            }
        }
    }

    private func saveProfiles() {
        let customProfiles = profiles.filter { !$0.isBuiltIn }
        if let encoded = try? JSONEncoder().encode(customProfiles) {
            UserDefaults.standard.set(encoded, forKey: "externalDisplayProfiles")
        }
    }

    private func saveActiveProfile(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: "activeDisplayProfile")
    }

    // MARK: - Utilities

    var hasExternalDisplay: Bool {
        !externalDisplays.isEmpty
    }

    var displayCount: Int {
        externalDisplays.count
    }

    func displayInfo(for screen: UIScreen) -> ExternalDisplayInfo? {
        externalDisplays.first { $0.screen == screen }
    }

    // MARK: - Quick Actions

    func toggleBlank() {
        if content.isEmpty || content.currentSection == "" {
            // Restore previous content
            // TODO: Store previous content
        } else {
            blankDisplay()
        }
    }

    func nextSection() {
        // To be implemented with song integration
        // This will advance to the next section of the current song
    }

    func previousSection() {
        // To be implemented with song integration
        // This will go back to the previous section
    }
}

// MARK: - External Projection View

struct ExternalProjectionView: View {
    let configuration: ExternalDisplayConfiguration
    let content: ExternalDisplayContent

    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()

            // Background image if specified
            if let imageName = configuration.backgroundImage {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            }

            // Content
            if content.isEmpty || content.currentSection == "" {
                // Blank screen
                Color.clear
            } else {
                contentView
            }
        }
    }

    private var backgroundColor: Color {
        Color(hex: configuration.backgroundColor) ?? .black
    }

    private var textColor: Color {
        Color(hex: configuration.textColor) ?? .white
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: configuration.lineSpacing) {
            // Song title
            if let title = content.songTitle, configuration.mode != .blank {
                Text(title)
                    .font(.system(size: configuration.fontSize * 0.6, weight: .semibold))
                    .foregroundStyle(textColor.opacity(0.7))
                    .multilineTextAlignment(configuration.textAlignment.textAlignment)
                    .padding(.bottom, 20)
            }

            // Main content
            if let section = content.currentSection {
                Text(section)
                    .font(.system(size: configuration.fontSize, weight: .regular, design: .rounded))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(configuration.textAlignment.textAlignment)
                    .lineSpacing(configuration.lineSpacing)
                    .shadow(
                        color: configuration.shadowEnabled ?
                            (Color(hex: configuration.shadowColor) ?? .black).opacity(0.8) :
                            .clear,
                        radius: configuration.shadowRadius
                    )
                    .overlay {
                        if configuration.outlineEnabled {
                            Text(section)
                                .font(.system(size: configuration.fontSize, weight: .regular, design: .rounded))
                                .foregroundStyle(.clear)
                                .multilineTextAlignment(configuration.textAlignment.textAlignment)
                                .lineSpacing(configuration.lineSpacing)
                                .overlay(
                                    Text(section)
                                        .font(.system(size: configuration.fontSize, weight: .regular, design: .rounded))
                                        .foregroundStyle(.clear)
                                        .multilineTextAlignment(configuration.textAlignment.textAlignment)
                                        .stroke(
                                            Color(hex: configuration.outlineColor) ?? .black,
                                            lineWidth: configuration.outlineWidth
                                        )
                                )
                        }
                    }
            }

            // Next line (confidence monitor)
            if configuration.showNextLine, let nextLine = content.nextLine {
                Divider()
                    .background(textColor.opacity(0.3))
                    .padding(.vertical, 20)

                VStack(spacing: 8) {
                    Text("Next:")
                        .font(.system(size: configuration.fontSize * 0.4))
                        .foregroundStyle(textColor.opacity(0.5))

                    Text(nextLine)
                        .font(.system(size: configuration.fontSize * 0.6))
                        .foregroundStyle(textColor.opacity(0.6))
                        .multilineTextAlignment(configuration.textAlignment.textAlignment)
                }
            }

            // Timer (confidence monitor)
            if configuration.showTimer, let timer = content.timer {
                Text(formatTime(timer))
                    .font(.system(size: configuration.fontSize * 0.5, design: .monospaced))
                    .foregroundStyle(textColor.opacity(0.7))
                    .padding(.top, 20)
            }
        }
        .padding(.horizontal, configuration.horizontalMargin)
        .padding(.vertical, configuration.verticalMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Text Stroke Extension

extension Text {
    func stroke(_ color: Color, lineWidth: CGFloat) -> some View {
        self
            .background(
                ZStack {
                    ForEach(0..<Int(lineWidth * 2), id: \.self) { i in
                        let angle = Double(i) * .pi / Double(lineWidth)
                        self
                            .offset(
                                x: cos(angle) * lineWidth,
                                y: sin(angle) * lineWidth
                            )
                            .foregroundStyle(color)
                    }
                }
            )
    }
}
