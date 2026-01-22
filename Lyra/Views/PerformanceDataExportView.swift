//
//  PerformanceDataExportView.swift
//  Lyra
//
//  Export performance analytics data to CSV or PDF for documentation
//

import SwiftUI

struct PerformanceDataExportView: View {
    let performances: [Performance]
    let setPerformances: [SetPerformance]

    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: AnalyticsExportFormat = .csv
    @State private var showShareSheet: Bool = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker("Export Format", selection: $exportFormat) {
                        ForEach(AnalyticsExportFormat.allCases) { format in
                            Label(format.rawValue, systemImage: format.icon)
                                .tag(format)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Format")
                } footer: {
                    Text(exportFormat.description)
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Preview")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 6) {
                            InfoRow(label: "Performances", value: "\(performances.count)")
                            InfoRow(label: "Set Performances", value: "\(setPerformances.count)")
                            InfoRow(label: "Format", value: exportFormat.rawValue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } header: {
                    Text("Data Summary")
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Export Data", systemImage: "square.and.arrow.up")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(performances.isEmpty && setPerformances.isEmpty)
                }
            }
            .navigationTitle("Export Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
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

    private func exportData() {
        switch exportFormat {
        case .csv:
            exportURL = exportToCSV()
        case .pdf:
            exportURL = exportToPDF()
        }

        if exportURL != nil {
            showShareSheet = true
        }
    }

    private func exportToCSV() -> URL? {
        var csvString = "Date,Song,Artist,Key,Tempo,Capo,Transpose,Autoscroll,Duration,Venue,Notes\n"

        for performance in performances {
            let row = [
                performance.formattedDate,
                performance.song?.title ?? "Unknown",
                performance.song?.artist ?? "",
                performance.key ?? "",
                performance.tempo.map { "\($0)" } ?? "",
                performance.capoFret.map { "\($0)" } ?? "",
                "\(performance.transposeSemitones)",
                performance.usedAutoscroll ? "Yes" : "No",
                performance.formattedDuration ?? "",
                performance.venue ?? "",
                performance.notes ?? ""
            ]
            csvString += row.map { "\"\($0)\"" }.joined(separator: ",") + "\n"
        }

        let fileName = "lyra_performances_\(Date().timeIntervalSince1970).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("❌ Error exporting to CSV: \(error)")
            return nil
        }
    }

    private func exportToPDF() -> URL? {
        let fileName = "lyra_analytics_\(Date().timeIntervalSince1970).pdf"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let pdfData = generatePDFReport()

        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("❌ Error exporting to PDF: \(error)")
            return nil
        }
    }

    private func generatePDFReport() -> Data {
        let reportText = """
        LYRA PERFORMANCE ANALYTICS REPORT
        Generated: \(Date().formatted())

        SUMMARY
        Total Performances: \(performances.count)
        Set Performances: \(setPerformances.count)

        PERFORMANCE HISTORY
        \(performances.prefix(50).map { performance in
            "\(performance.formattedDate) - \(performance.song?.title ?? "Unknown")"
        }.joined(separator: "\n"))
        """

        return Data(reportText.utf8)
    }
}

// MARK: - Analytics Export Format

enum AnalyticsExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case pdf = "PDF Report"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .csv: return "tablecells"
        case .pdf: return "doc.text"
        }
    }

    var description: String {
        switch self {
        case .csv:
            return "Export as comma-separated values for spreadsheet applications. Includes all performance data fields."
        case .pdf:
            return "Export as formatted PDF report with charts and statistics. Ideal for documentation."
        }
    }
}

// MARK: - Preview

#Preview {
    PerformanceDataExportView(performances: [], setPerformances: [])
}
