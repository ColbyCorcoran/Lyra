//
//  InsightsView.swift
//  Lyra
//
//  Detailed view showing all generated insights and recommendations
//

import SwiftUI

struct InsightsView: View {
    let performances: [Performance]
    let songs: [Song]

    @Environment(\.dismiss) private var dismiss

    private var allInsights: [Insight] {
        InsightsEngine.generateInsights(
            performances: performances,
            setPerformances: [],
            songs: songs
        )
    }

    private var groupedInsights: [Insight.InsightType: [Insight]] {
        Dictionary(grouping: allInsights, by: { $0.type })
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.yellow)

                        Text("Your Insights")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Based on your performance history")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Insights by category
                    ForEach(Array(Insight.InsightType.allCases), id: \.self) { type in
                        if let insights = groupedInsights[type], !insights.isEmpty {
                            insightSection(type: type, insights: insights)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func insightSection(type: Insight.InsightType, insights: [Insight]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(typeName(for: type))
                .font(.title3)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                ForEach(insights) { insight in
                    InsightDetailCard(insight: insight)
                }
            }
        }
    }

    private func typeName(for type: Insight.InsightType) -> String {
        switch type {
        case .trend: return "Trends"
        case .recommendation: return "Recommendations"
        case .milestone: return "Milestones"
        case .reminder: return "Reminders"
        case .pattern: return "Patterns"
        }
    }
}

// MARK: - Insight Detail Card

struct InsightDetailCard: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(insight.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: insight.icon)
                    .font(.title2)
                    .foregroundStyle(insight.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.headline)

                Text(insight.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Insight Type Extension

extension Insight.InsightType: CaseIterable {
    static var allCases: [Insight.InsightType] {
        [.milestone, .trend, .pattern, .recommendation, .reminder]
    }
}

// MARK: - Preview

#Preview {
    InsightsView(performances: [], songs: [])
}
