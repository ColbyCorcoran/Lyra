//
//  OCRQualityIndicator.swift
//  Lyra
//
//  Phase 7.10: Enhanced OCR - Quality Visualization
//  Visual confidence display with breakdown
//

import SwiftUI

struct OCRQualityIndicator: View {

    let confidence: ConfidenceBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overall quality
            HStack {
                Label("Quality: \(confidence.qualityLevel.description)", systemImage: qualityIcon)
                    .font(.headline)
                    .foregroundStyle(confidence.qualityLevel.color)

                Spacer()

                Text("\(Int(confidence.overallConfidence * 100))%")
                    .font(.title2.bold())
                    .foregroundStyle(confidence.qualityLevel.color)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(confidence.qualityLevel.color.gradient)
                        .frame(width: geometry.size.width * CGFloat(confidence.overallConfidence))
                }
            }
            .frame(height: 8)

            // Breakdown
            VStack(spacing: 8) {
                MetricRow(label: "Image Quality", value: confidence.imageQuality, color: metricColor(confidence.imageQuality))
                MetricRow(label: "OCR Accuracy", value: confidence.ocrAccuracy, color: metricColor(confidence.ocrAccuracy))
                MetricRow(label: "Context Validation", value: confidence.contextValidation, color: metricColor(confidence.contextValidation))
            }
            .font(.caption)
        }
        .padding()
        .background(confidence.qualityLevel.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var qualityIcon: String {
        switch confidence.qualityLevel {
        case .excellent:
            return "checkmark.seal.fill"
        case .good:
            return "checkmark.circle.fill"
        case .fair:
            return "exclamationmark.triangle.fill"
        case .poor:
            return "xmark.circle.fill"
        }
    }

    private func metricColor(_ value: Float) -> Color {
        if value >= 0.8 {
            return .green
        } else if value >= 0.6 {
            return .blue
        } else if value >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: Float
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 4) {
                ProgressView(value: Double(value), total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(color)
                    .frame(width: 100)

                Text("\(Int(value * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(color)
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
}
