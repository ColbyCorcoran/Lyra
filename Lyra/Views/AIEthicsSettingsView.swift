//
//  AIEthicsSettingsView.swift
//  Lyra
//
//  Phase 7.15: AI Ethics and Transparency
//  Comprehensive UI for AI ethics settings and transparency
//

import SwiftUI

struct AIEthicsSettingsView: View {
    @State private var selectedTab: EthicsTab = .overview
    @State private var showDeleteConfirmation = false
    @State private var showPrivacyPolicy = false
    @State private var showCopyrightEducation = false

    private let ethicsManager = AIEthicsManager.shared
    private let userControl = UserControlEngine.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Ethics Section", selection: $selectedTab) {
                    ForEach(EthicsTab.allCases, id: \.self) { tab in
                        Text(tab.displayName).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .overview:
                            EthicsOverviewSection()
                        case .transparency:
                            TransparencySection()
                        case .control:
                            UserControlSection(showDeleteConfirmation: $showDeleteConfirmation)
                        case .privacy:
                            PrivacySection(showPrivacyPolicy: $showPrivacyPolicy)
                        case .fairness:
                            FairnessSection()
                        case .copyright:
                            CopyrightSection(showEducation: $showCopyrightEducation)
                        case .data:
                            DataManagementSection()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Ethics & Transparency")
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showCopyrightEducation) {
                CopyrightEducationView()
            }
            .alert("Delete All AI Data", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    let result = ethicsManager.performCompleteDataDeletion()
                    print(result.message)
                }
            } message: {
                Text("This will permanently delete all AI training data, learning history, and preferences. This cannot be undone.")
            }
        }
    }
}

// MARK: - Tabs

enum EthicsTab: CaseIterable {
    case overview
    case transparency
    case control
    case privacy
    case fairness
    case copyright
    case data

    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .transparency: return "Transparency"
        case .control: return "Control"
        case .privacy: return "Privacy"
        case .fairness: return "Fairness"
        case .copyright: return "Copyright"
        case .data: return "Data"
        }
    }
}

// MARK: - Ethics Overview Section

struct EthicsOverviewSection: View {
    @State private var dashboard: AIEthicsDashboard?
    private let ethicsManager = AIEthicsManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Ethics Dashboard")
                .font(.title2)
                .bold()

            if let dashboard = dashboard {
                // Overall score
                EthicsScoreCard(
                    title: "Overall Ethics Score",
                    score: dashboard.overallEthicsScore,
                    icon: "shield.checkered",
                    color: .green
                )

                // Individual scores
                VStack(spacing: 12) {
                    EthicsScoreMini(title: "Transparency", score: dashboard.transparencyScore)
                    EthicsScoreMini(title: "Privacy", score: dashboard.privacyScore.score / 100.0)
                    EthicsScoreMini(title: "Fairness", score: dashboard.biasScore)
                    EthicsScoreMini(title: "Copyright", score: dashboard.copyrightCompliance)
                    EthicsScoreMini(title: "Data Minimization", score: dashboard.dataMinimization)
                    EthicsScoreMini(title: "User Control", score: dashboard.userControlScore)
                }
            } else {
                ProgressView()
                    .onAppear {
                        dashboard = ethicsManager.getEthicsDashboard()
                    }
            }

            Divider()

            InfoCard(
                title: "What This Means",
                icon: "lightbulb",
                color: .blue,
                content: "Lyra's AI features are designed to be ethical, transparent, and respectful of your privacy. All AI processing happens on your device. You have full control over what data is collected and can delete it at any time."
            )
        }
    }
}

// MARK: - Transparency Section

struct TransparencySection: View {
    @State private var showConfidenceScores = UserControlEngine.shared.getGranularControls().showConfidenceScores
    @State private var showAIBadges = UserControlEngine.shared.getGranularControls().showAIBadges
    @State private var enableExplanations = UserControlEngine.shared.getGranularControls().enableAIExplanations

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Transparency")
                .font(.title2)
                .bold()

            InfoCard(
                title: "Why Transparency Matters",
                icon: "eye",
                color: .blue,
                content: "Transparency helps you understand how AI makes decisions, build trust in suggestions, and make informed choices about using AI features."
            )

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $showConfidenceScores) {
                    VStack(alignment: .leading) {
                        Text("Show Confidence Scores")
                            .font(.headline)
                        Text("Display AI's confidence in suggestions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: showConfidenceScores) { _, newValue in
                    UserControlEngine.shared.setGranularControl(.showConfidenceScores, value: newValue)
                }

                Divider()

                Toggle(isOn: $showAIBadges) {
                    VStack(alignment: .leading) {
                        Text("Show AI Badges")
                            .font(.headline)
                        Text("Mark AI-generated content with badges")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: showAIBadges) { _, newValue in
                    UserControlEngine.shared.setGranularControl(.showAIBadges, value: newValue)
                }

                Divider()

                Toggle(isOn: $enableExplanations) {
                    VStack(alignment: .leading) {
                        Text("Enable Explanations")
                            .font(.headline)
                        Text("Show 'Why this suggestion?' option")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: enableExplanations) { _, newValue in
                    UserControlEngine.shared.setGranularControl(.enableAIExplanations, value: newValue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - User Control Section

struct UserControlSection: View {
    @Binding var showDeleteConfirmation: Bool
    @State private var featureSettings: [AIFeatureControl: Bool] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Control")
                .font(.title2)
                .bold()

            InfoCard(
                title: "You're In Charge",
                icon: "hand.raised",
                color: .purple,
                content: "You have complete control over AI features. Enable or disable any feature, and your preferences are respected immediately."
            )

            VStack(alignment: .leading, spacing: 12) {
                ForEach(AIFeatureControl.allCases, id: \.self) { feature in
                    Toggle(isOn: binding(for: feature)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: feature.icon)
                                    .foregroundColor(.blue)
                                Text(feature.displayName)
                                    .font(.headline)
                            }
                            Text(feature.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Divider()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete All AI Data")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
        }
        .onAppear {
            featureSettings = UserControlEngine.shared.getAllFeatureSettings()
        }
    }

    private func binding(for feature: AIFeatureControl) -> Binding<Bool> {
        Binding(
            get: { featureSettings[feature] ?? false },
            set: { newValue in
                featureSettings[feature] = newValue
                UserControlEngine.shared.setFeature(feature, enabled: newValue)
            }
        )
    }
}

// MARK: - Privacy Section

struct PrivacySection: View {
    @Binding var showPrivacyPolicy: Bool
    @State private var privacyScore: PrivacyScore?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy Protection")
                .font(.title2)
                .bold()

            if let score = privacyScore {
                PrivacyScoreCard(score: score)
            }

            VStack(spacing: 12) {
                PrivacyPrincipleRow(
                    icon: "iphone",
                    title: "On-Device Processing",
                    description: "All AI runs on your device"
                )
                PrivacyPrincipleRow(
                    icon: "network.slash",
                    title: "No External APIs",
                    description: "No data sent to cloud AI services"
                )
                PrivacyPrincipleRow(
                    icon: "lock.shield",
                    title: "Complete Privacy",
                    description: "Your data never leaves your device"
                )
            }

            Button {
                showPrivacyPolicy = true
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                    Text("View Full Privacy Policy")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
        }
        .onAppear {
            privacyScore = PrivacyProtectionEngine.shared.calculatePrivacyScore()
        }
    }
}

// MARK: - Fairness Section

struct FairnessSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fairness & Bias Mitigation")
                .font(.title2)
                .bold()

            InfoCard(
                title: "Fighting Bias",
                icon: "scale.3d",
                color: .green,
                content: "Lyra actively works to prevent genre bias, ensure cultural sensitivity, and provide fair recommendations for all users."
            )

            VStack(alignment: .leading, spacing: 12) {
                FairnessFeatureRow(
                    icon: "music.note.list",
                    title: "Genre Diversity",
                    description: "Recommendations include diverse genres, not just popular ones"
                )
                FairnessFeatureRow(
                    icon: "globe",
                    title: "Cultural Sensitivity",
                    description: "Content is checked for cultural appropriateness"
                )
                FairnessFeatureRow(
                    icon: "person.3",
                    title: "Fair for Everyone",
                    description: "Recommendations work fairly across demographics"
                )
                FairnessFeatureRow(
                    icon: "accessibility",
                    title: "Accessibility First",
                    description: "AI features support VoiceOver and accessibility tools"
                )
            }
        }
    }
}

// MARK: - Copyright Section

struct CopyrightSection: View {
    @Binding var showEducation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Copyright Respect")
                .font(.title2)
                .bold()

            InfoCard(
                title: "Respecting Artists",
                icon: "person.text.rectangle",
                color: .orange,
                content: "Lyra respects artists' rights by not reproducing copyrighted lyrics, detecting potential violations, and educating users about copyright law."
            )

            VStack(alignment: .leading, spacing: 12) {
                CopyrightFeatureRow(
                    icon: "checkmark.shield",
                    title: "No Lyric Reproduction",
                    description: "AI won't generate copyrighted lyrics"
                )
                CopyrightFeatureRow(
                    icon: "magnifyingglass",
                    title: "Violation Detection",
                    description: "Checks content for copyright issues"
                )
                CopyrightFeatureRow(
                    icon: "graduationcap",
                    title: "User Education",
                    description: "Learn about copyright and fair use"
                )
                CopyrightFeatureRow(
                    icon: "hand.thumbsup",
                    title: "Proper Attribution",
                    description: "Always credit original artists"
                )
            }

            Button {
                showEducation = true
            } label: {
                HStack {
                    Image(systemName: "book")
                    Text("Learn About Copyright")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Data Management Section

struct DataManagementSection: View {
    @State private var retentionStatus: [DataCategory: RetentionStatus] = [:]
    @State private var showCleanupConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Management")
                .font(.title2)
                .bold()

            InfoCard(
                title: "Minimal Data Storage",
                icon: "internaldrive",
                color: .cyan,
                content: "Lyra stores only what's necessary for features to work. You can delete any data category at any time."
            )

            VStack(alignment: .leading, spacing: 12) {
                ForEach(DataCategory.allCases, id: \.self) { category in
                    if let status = retentionStatus[category] {
                        DataCategoryRow(category: category, status: status)
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Button {
                DataRetentionManager.shared.performAutomaticCleanup()
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Clean Up Old Data")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(12)
            }
        }
        .onAppear {
            retentionStatus = DataRetentionManager.shared.getRetentionStatus()
        }
    }
}

// MARK: - Supporting Views

struct EthicsScoreCard: View {
    let title: String
    let score: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }

            HStack {
                Text("\(Int(score * 100))%")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(color)

                Spacer()

                Image(systemName: scoreIcon(score))
                    .font(.system(size: 40))
                    .foregroundColor(color)
            }

            ProgressView(value: score, total: 1.0)
                .tint(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }

    private func scoreIcon(_ score: Double) -> String {
        score >= 0.9 ? "star.fill" : score >= 0.7 ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }
}

struct EthicsScoreMini: View {
    let title: String
    let score: Double

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text("\(Int(score * 100))%")
                .font(.subheadline)
                .bold()
            ProgressView(value: score, total: 1.0)
                .frame(width: 60)
        }
    }
}

struct InfoCard: View {
    let title: String
    let icon: String
    let color: Color
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PrivacyScoreCard: View {
    let score: PrivacyScore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: score.level.icon)
                    .foregroundColor(colorForLevel(score.level))
                Text(score.level.rawValue)
                    .font(.headline)
            }

            Text("\(Int(score.score))%")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(colorForLevel(score.level))

            ForEach(score.factors, id: \.self) { factor in
                Text(factor)
                    .font(.caption)
            }
        }
        .padding()
        .background(colorForLevel(score.level).opacity(0.1))
        .cornerRadius(12)
    }

    private func colorForLevel(_ level: PrivacyLevel) -> Color {
        switch level.color {
        case "green": return .green
        case "blue": return .blue
        case "cyan": return .cyan
        case "yellow": return .yellow
        case "red": return .red
        default: return .gray
        }
    }
}

struct PrivacyPrincipleRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FairnessFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CopyrightFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DataCategoryRow: View {
    let category: DataCategory
    let status: RetentionStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.displayName)
                .font(.headline)
            Text("\(status.itemCount) items • \(formatBytes(status.currentSize))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024

        if mb >= 1 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.1f KB", kb)
        }
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    private let policy = PrivacyProtectionEngine.shared.getAIPrivacyPolicy()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(policy.principles, id: \.title) { principle in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: principle.icon)
                                    .foregroundColor(.blue)
                                Text(principle.title)
                                    .font(.headline)
                            }
                            Text(principle.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Copyright Education View

struct CopyrightEducationView: View {
    @Environment(\.dismiss) var dismiss
    private let education = CopyrightProtectionEngine.shared.getCopyrightEducation()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Section("Principles") {
                        ForEach(education.principles, id: \.self) { principle in
                            Text("• \(principle)")
                                .padding(.bottom, 4)
                        }
                    }

                    Divider()

                    Section("What's Protected") {
                        ForEach(education.whatIsProtected, id: \.self) { item in
                            Text(item)
                                .padding(.bottom, 4)
                        }
                    }

                    Divider()

                    Section("Best Practices") {
                        ForEach(education.bestPractices, id: \.self) { practice in
                            Text("• \(practice)")
                                .padding(.bottom, 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Copyright Education")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AIEthicsSettingsView()
}
