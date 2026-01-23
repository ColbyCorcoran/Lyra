//
//  TeamAnalyticsSupport.swift
//  Lyra
//
//  Supporting views for insights and export functionality
//

import SwiftUI
import PDFKit

// MARK: - Insights Sheet

struct InsightsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let insights: [TeamInsight]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if insights.isEmpty {
                        ContentUnavailableView(
                            "No Insights Yet",
                            systemImage: "lightbulb",
                            description: Text("Keep collaborating to generate team insights")
                        )
                    } else {
                        ForEach(insights) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Team Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InsightCard: View {
    let insight: TeamInsight

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: insight.icon)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(insight.color.gradient)
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(insight.title)
                        .font(.headline)

                    Spacer()

                    InsightBadge(type: insight.type)
                }

                Text(insight.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InsightBadge: View {
    let type: TeamInsight.InsightType

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch type {
        case .achievement: return "Achievement"
        case .trend: return "Trend"
        case .recommendation: return "Tip"
        case .alert: return "Alert"
        }
    }

    private var color: Color {
        switch type {
        case .achievement: return .green
        case .trend: return .blue
        case .recommendation: return .orange
        case .alert: return .red
        }
    }
}

// MARK: - Export Report Sheet

struct ExportReportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let library: SharedLibrary
    let analytics: TeamAnalytics

    @State private var selectedFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF Report"
        case csv = "CSV Data"

        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .csv: return "tablecells"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button {
                            selectedFormat = format
                        } label: {
                            HStack {
                                Image(systemName: format.icon)
                                    .foregroundStyle(selectedFormat == format ? .blue : .secondary)

                                Text(format.rawValue)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Report Contents") {
                    Label("Dashboard metrics", systemImage: "chart.bar")
                    Label("Contributor statistics", systemImage: "person.3")
                    Label("Library health analysis", systemImage: "cross.case")
                    Label("Activity trends", systemImage: "chart.line.uptrend.xyaxis")
                    Label("Song popularity rankings", systemImage: "star")
                    Label("Team insights", systemImage: "lightbulb")
                }

                Section {
                    Button {
                        Task {
                            await exportReport()
                        }
                    } label: {
                        HStack {
                            Spacer()

                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }

                            Text(isExporting ? "Generating..." : "Export Report")
                                .fontWeight(.semibold)

                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportReport() async {
        isExporting = true

        switch selectedFormat {
        case .pdf:
            exportedFileURL = await generatePDFReport()
        case .csv:
            exportedFileURL = await generateCSVReport()
        }

        isExporting = false

        if exportedFileURL != nil {
            showingShareSheet = true
        }
    }

    private func generatePDFReport() async -> URL? {
        let fileName = "\(library.name)-analytics-\(Date().formatted(date: .numeric, time: .omitted)).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()

                var yPosition: CGFloat = 50

                // Title
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.label
                ]
                let title = "\(library.name) - Team Analytics Report"
                title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
                yPosition += 40

                // Date
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                let dateString = "Generated on \(Date().formatted(date: .long, time: .shortened))"
                dateString.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: dateAttributes)
                yPosition += 30

                // Section attributes
                let sectionAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.label
                ]
                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.label
                ]

                // Overview
                "Overview".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 25

                let overviewText = """
                Total Songs: \(analytics.totalSongs)
                Total Contributors: \(analytics.totalContributors)
                Songs Added This Week: \(analytics.songsAddedThisWeek)
                Songs Added This Month: \(analytics.songsAddedThisMonth)
                """
                overviewText.draw(in: CGRect(x: 50, y: yPosition, width: 500, height: 100), withAttributes: bodyAttributes)
                yPosition += 110

                // Top Contributors
                "Top Contributors".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 25

                for contributor in analytics.mostActiveContributors.prefix(5) {
                    let contributorText = "• \(contributor.displayName) - \(contributor.activityCount) actions"
                    contributorText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 20
                }
                yPosition += 10

                // Library Health
                if yPosition > 650 {
                    context.beginPage()
                    yPosition = 50
                }

                "Library Health".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 25

                let healthText = """
                Stale Songs: \(analytics.staleSongs.count)
                Unresolved Comments: \(analytics.songsWithUnresolvedComments.count)
                Conflicts: \(analytics.songsWithConflicts.count)
                Missing Metadata: \(analytics.songsMissingMetadata.count)
                """
                healthText.draw(in: CGRect(x: 50, y: yPosition, width: 500, height: 100), withAttributes: bodyAttributes)
                yPosition += 110

                // Insights
                if yPosition > 650 {
                    context.beginPage()
                    yPosition = 50
                }

                "Key Insights".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 25

                for insight in analytics.insights.prefix(5) {
                    if yPosition > 720 {
                        context.beginPage()
                        yPosition = 50
                    }

                    "• \(insight.title)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 20

                    let messageRect = CGRect(x: 60, y: yPosition, width: 500, height: 60)
                    insight.message.draw(in: messageRect, withAttributes: bodyAttributes)
                    yPosition += 40
                }
            }

            return tempURL
        } catch {
            print("Error generating PDF: \(error)")
            return nil
        }
    }

    private func generateCSVReport() async -> URL? {
        let fileName = "\(library.name)-analytics-\(Date().formatted(date: .numeric, time: .omitted)).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csvText = "Category,Metric,Value\n"

        // Overview metrics
        csvText += "Overview,Total Songs,\(analytics.totalSongs)\n"
        csvText += "Overview,Total Contributors,\(analytics.totalContributors)\n"
        csvText += "Overview,Songs Added This Week,\(analytics.songsAddedThisWeek)\n"
        csvText += "Overview,Songs Added This Month,\(analytics.songsAddedThisMonth)\n"

        // Contributor stats
        for contributor in analytics.contributorStats {
            csvText += "Contributors,\(contributor.displayName) - Songs Added,\(contributor.songsAdded)\n"
            csvText += "Contributors,\(contributor.displayName) - Edits,\(contributor.editsCount)\n"
            csvText += "Contributors,\(contributor.displayName) - Comments,\(contributor.commentsCount)\n"
        }

        // Health metrics
        csvText += "Health,Stale Songs,\(analytics.staleSongs.count)\n"
        csvText += "Health,Unresolved Comments,\(analytics.songsWithUnresolvedComments.count)\n"
        csvText += "Health,Conflicts,\(analytics.songsWithConflicts.count)\n"
        csvText += "Health,Missing Metadata,\(analytics.songsMissingMetadata.count)\n"

        // Popularity
        for song in analytics.mostViewedSongs {
            csvText += "Popularity,\(song.title) - Views,\(song.count)\n"
        }

        for song in analytics.mostEditedSongs {
            csvText += "Popularity,\(song.title) - Edits,\(song.count)\n"
        }

        do {
            try csvText.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Error generating CSV: \(error)")
            return nil
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
