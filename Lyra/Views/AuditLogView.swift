//
//  AuditLogView.swift
//  Lyra
//
//  View for displaying and filtering organization audit logs
//

import SwiftUI

struct AuditLogView: View {
    let organization: Organization

    @State private var selectedCategory: AuditCategory = .all
    @State private var searchText = ""
    @State private var showExportSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AuditCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.secondarySystemBackground))

                Divider()

                // Audit Log Entries
                if filteredEntries.isEmpty {
                    ContentUnavailableView(
                        "No Audit Logs",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("No audit log entries match your filter")
                    )
                } else {
                    List {
                        ForEach(filteredEntries) { entry in
                            AuditLogRow(entry: entry)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Audit Log")
            .searchable(text: $searchText, prompt: "Search logs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                AuditLogExportView(organization: organization, entries: filteredEntries)
            }
        }
    }

    private var filteredEntries: [AuditLogEntry] {
        var entries = organization.auditLog

        // Filter by category
        if selectedCategory != .all {
            entries = entries.filter { $0.action.category == selectedCategory }
        }

        // Filter by search
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.displayText.localizedCaseInsensitiveContains(searchText) ||
                entry.actorName.localizedCaseInsensitiveContains(searchText) ||
                (entry.targetName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return entries
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: AuditCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)

                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Audit Log Row

struct AuditLogRow: View {
    let entry: AuditLogEntry

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: entry.action.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(entry.action.color))
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayText)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(entry.relativeTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let deviceType = entry.deviceType {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label(deviceType, systemImage: deviceIcon(deviceType))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button {
                // Copy details
                UIPasteboard.general.string = entry.displayText
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Button {
                // View full details
            } label: {
                Label("View Details", systemImage: "info.circle")
            }
        }
    }

    private func deviceIcon(_ deviceType: String) -> String {
        switch deviceType.lowercased() {
        case "iphone":
            return "iphone"
        case "ipad":
            return "ipad"
        case "mac":
            return "macbook"
        default:
            return "laptopcomputer"
        }
    }
}

// MARK: - Audit Log Export View

struct AuditLogExportView: View {
    @Environment(\.dismiss) private var dismiss

    let organization: Organization
    let entries: [AuditLogEntry]

    @State private var selectedFormat: ExportFormat = .csv
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case pdf = "PDF"

        var icon: String {
            switch self {
            case .csv: return "tablecells"
            case .json: return "curlybraces"
            case .pdf: return "doc.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
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

                Section("Export Contents") {
                    Label("\(entries.count) audit log entries", systemImage: "doc.text")
                    Label("Date range: \(dateRangeText)", systemImage: "calendar")
                }

                Section {
                    Button {
                        exportLog()
                    } label: {
                        HStack {
                            Spacer()

                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }

                            Text(isExporting ? "Exporting..." : "Export Audit Log")
                                .fontWeight(.semibold)

                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Export Audit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private var dateRangeText: String {
        guard let oldest = entries.last?.timestamp,
              let newest = entries.first?.timestamp else {
            return "No entries"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short

        return "\(formatter.string(from: oldest)) - \(formatter.string(from: newest))"
    }

    private func exportLog() {
        isExporting = true

        Task {
            let fileName = "audit-log-\(organization.name)-\(Date().formatted(date: .numeric, time: .omitted))"

            switch selectedFormat {
            case .csv:
                exportURL = await generateCSV(fileName: fileName)
            case .json:
                exportURL = await generateJSON(fileName: fileName)
            case .pdf:
                exportURL = await generatePDF(fileName: fileName)
            }

            await MainActor.run {
                isExporting = false
                if exportURL != nil {
                    showShareSheet = true
                }
            }
        }
    }

    private func generateCSV(fileName: String) async -> URL? {
        var csv = "Timestamp,Actor,Action,Target,Details\n"

        for entry in entries {
            let timestamp = entry.formattedTimestamp
            let actor = entry.actorName
            let action = entry.action.rawValue
            let target = entry.targetName ?? ""
            let details = entry.details ?? ""

            csv += "\"\(timestamp)\",\"\(actor)\",\"\(action)\",\"\(target)\",\"\(details)\"\n"
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).csv")
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }

    private func generateJSON(fileName: String) async -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(entries)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).json")
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }

    private func generatePDF(fileName: String) async -> URL? {
        // Simplified PDF generation
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()

                var yPosition: CGFloat = 50

                // Title
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 20),
                    .foregroundColor: UIColor.label
                ]
                "Audit Log - \(organization.name)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
                yPosition += 40

                // Entries
                let entryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.label
                ]

                for entry in entries.prefix(50) { // Limit to first 50 entries
                    if yPosition > 720 {
                        context.beginPage()
                        yPosition = 50
                    }

                    let text = "\(entry.formattedTimestamp) - \(entry.displayText)"
                    text.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: entryAttributes)
                    yPosition += 20
                }
            }

            return tempURL
        } catch {
            return nil
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Color Extension

private extension Color {
    init?(_ colorString: String) {
        switch colorString {
        case "green": self = .green
        case "red": self = .red
        case "blue": self = .blue
        case "orange": self = .orange
        case "purple": self = .purple
        case "yellow": self = .yellow
        case "gray": self = .gray
        default: return nil
        }
    }
}

// MARK: - Preview

#Preview {
    let org = Organization(
        name: "Test Church",
        organizationType: .church,
        ownerRecordID: "owner123",
        ownerDisplayName: "John Doe"
    )

    // Add sample audit entries
    org.addAuditLogEntry(AuditLogEntry(
        actorRecordID: "user1",
        actorDisplayName: "Alice Smith",
        action: .memberAdded,
        details: "Added Bob Johnson as Editor",
        targetID: "user2",
        targetName: "Bob Johnson"
    ))

    org.addAuditLogEntry(AuditLogEntry(
        actorRecordID: "user1",
        actorDisplayName: "Alice Smith",
        action: .libraryCreated,
        details: "Created library 'Worship Songs'",
        targetID: "lib1",
        targetName: "Worship Songs"
    ))

    return AuditLogView(organization: org)
}
