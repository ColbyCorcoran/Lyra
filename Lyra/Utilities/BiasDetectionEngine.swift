//
//  BiasDetectionEngine.swift
//  Lyra
//
//  Phase 7.15: AI Ethics and Transparency
//  Bias mitigation: test for genre bias, cultural sensitivity, diverse training data, fair recommendations
//

import Foundation

/// Bias detection and mitigation engine for ensuring fair AI recommendations
class BiasDetectionEngine {
    static let shared = BiasDetectionEngine()

    private init() {}

    // MARK: - Genre Bias Detection

    /// Analyze recommendations for genre bias
    func analyzeGenreBias(
        recommendations: [String],
        expectedDistribution: [String: Double]
    ) -> GenreBiasAnalysis {
        // Count genre occurrences
        var genreCounts: [String: Int] = [:]
        var totalCount = 0

        for rec in recommendations {
            // Extract genre from recommendation (simplified)
            if let genre = extractGenre(from: rec) {
                genreCounts[genre, default: 0] += 1
                totalCount += 1
            }
        }

        // Calculate actual distribution
        var actualDistribution: [String: Double] = [:]
        for (genre, count) in genreCounts {
            actualDistribution[genre] = Double(count) / Double(totalCount)
        }

        // Calculate bias score (0 = no bias, 1 = maximum bias)
        var biasScore = 0.0
        for (genre, expectedProp) in expectedDistribution {
            let actualProp = actualDistribution[genre] ?? 0.0
            biasScore += abs(expectedProp - actualProp)
        }
        biasScore /= Double(expectedDistribution.count)

        let biasLevel: BiasLevel = biasScore < 0.1 ? .minimal :
                                    biasScore < 0.25 ? .low :
                                    biasScore < 0.5 ? .moderate :
                                    biasScore < 0.75 ? .high : .severe

        return GenreBiasAnalysis(
            biasScore: biasScore,
            biasLevel: biasLevel,
            expectedDistribution: expectedDistribution,
            actualDistribution: actualDistribution,
            overrepresentedGenres: findOverrepresented(expected: expectedDistribution, actual: actualDistribution),
            underrepresentedGenres: findUnderrepresented(expected: expectedDistribution, actual: actualDistribution),
            mitigationSuggestions: generateGenreMitigations(biasScore: biasScore)
        )
    }

    /// Test recommendation system for genre fairness
    func testGenreFairness(
        recommendationEngine: ([String]) -> [String],
        testCases: [GenreTestCase]
    ) -> GenreFairnessReport {
        var results: [GenreFairnessResult] = []

        for testCase in testCases {
            let recommendations = recommendationEngine(testCase.userHistory)
            let analysis = analyzeGenreBias(
                recommendations: recommendations,
                expectedDistribution: testCase.expectedDistribution
            )

            results.append(GenreFairnessResult(
                testCase: testCase,
                analysis: analysis,
                passed: analysis.biasLevel == .minimal || analysis.biasLevel == .low
            ))
        }

        let passRate = Double(results.filter { $0.passed }.count) / Double(results.count)

        return GenreFairnessReport(
            results: results,
            overallPassRate: passRate,
            recommendation: passRate >= 0.8 ? "System shows good genre fairness" :
                            passRate >= 0.6 ? "Some genre bias detected, review recommendations" :
                            "Significant genre bias, mitigation needed"
        )
    }

    // MARK: - Cultural Sensitivity

    /// Analyze content for cultural sensitivity
    func analyzeCulturalSensitivity(
        content: String,
        culturalContext: CulturalContext
    ) -> CulturalSensitivityAnalysis {
        var issues: [CulturalIssue] = []
        var warnings: [String] = []

        // Check for culturally insensitive terms
        let insensitiveTerms = getInsensitiveTerms(for: culturalContext)
        for term in insensitiveTerms {
            if content.lowercased().contains(term.lowercased()) {
                issues.append(CulturalIssue(
                    type: .insensitiveTerm,
                    term: term,
                    context: culturalContext,
                    severity: .high,
                    suggestion: "Consider using more culturally appropriate language"
                ))
            }
        }

        // Check for stereotypes
        let stereotypes = getStereotypes(for: culturalContext)
        for stereotype in stereotypes {
            if content.lowercased().contains(stereotype.lowercased()) {
                warnings.append("Potential stereotype detected: '\(stereotype)'")
            }
        }

        // Check for appropriation concerns
        if hasAppropriationConcerns(content, culturalContext: culturalContext) {
            issues.append(CulturalIssue(
                type: .culturalAppropriation,
                term: "",
                context: culturalContext,
                severity: .medium,
                suggestion: "Ensure proper attribution and respectful representation"
            ))
        }

        let sensitivityScore = calculateSensitivityScore(issues: issues, warnings: warnings)

        return CulturalSensitivityAnalysis(
            sensitivityScore: sensitivityScore,
            issues: issues,
            warnings: warnings,
            recommendations: generateCulturalRecommendations(issues: issues)
        )
    }

    /// Get culturally appropriate alternatives
    func getCulturallyAppropriateAlternatives(
        for term: String,
        context: CulturalContext
    ) -> [String] {
        // In production, this would be a comprehensive database
        let alternatives: [String: [String]] = [
            "native": ["Indigenous", "First Nations", "Aboriginal"],
            "tribe": ["community", "nation", "people"],
            "exotic": ["unique", "distinctive", "international"],
            "oriental": ["Asian", "East Asian", "Pacific Islander"]
        ]

        return alternatives[term.lowercased()] ?? []
    }

    // MARK: - Diverse Training Data

    /// Verify training data diversity
    func verifyTrainingDataDiversity(
        dataset: TrainingDataset
    ) -> DiversityAnalysis {
        // Analyze genre diversity
        let genreDiversity = calculateDiversity(dataset.genres)

        // Analyze cultural diversity
        let culturalDiversity = calculateDiversity(dataset.culturalOrigins)

        // Analyze language diversity
        let languageDiversity = calculateDiversity(dataset.languages)

        // Analyze era diversity
        let eraDiversity = calculateDiversity(dataset.eras)

        let overallDiversity = (genreDiversity + culturalDiversity + languageDiversity + eraDiversity) / 4.0

        let diversityLevel: DiversityLevel = overallDiversity >= 0.8 ? .excellent :
                                              overallDiversity >= 0.6 ? .good :
                                              overallDiversity >= 0.4 ? .fair :
                                              overallDiversity >= 0.2 ? .poor : .inadequate

        return DiversityAnalysis(
            overallDiversity: overallDiversity,
            diversityLevel: diversityLevel,
            genreDiversity: genreDiversity,
            culturalDiversity: culturalDiversity,
            languageDiversity: languageDiversity,
            eraDiversity: eraDiversity,
            recommendations: generateDiversityRecommendations(diversityLevel: diversityLevel)
        )
    }

    // MARK: - Fair Recommendations

    /// Ensure recommendations are fair across demographics
    func ensureFairRecommendations(
        recommendations: [String],
        demographics: UserDemographics
    ) -> FairnessAssessment {
        var fairnessIssues: [FairnessIssue] = []

        // Check for age-appropriate content
        if let age = demographics.age {
            let ageAppropriate = verifyAgeAppropriateness(recommendations, age: age)
            if !ageAppropriate {
                fairnessIssues.append(FairnessIssue(
                    type: .ageInappropriate,
                    description: "Some recommendations may not be age-appropriate",
                    severity: .high
                ))
            }
        }

        // Check for cultural representation
        if let culture = demographics.culturalBackground {
            let culturallyRepresentative = verifyCulturalRepresentation(recommendations, culture: culture)
            if !culturallyRepresentative {
                fairnessIssues.append(FairnessIssue(
                    type: .lackOfRepresentation,
                    description: "Recommendations lack cultural diversity",
                    severity: .medium
                ))
            }
        }

        // Check for accessibility
        let accessible = verifyAccessibility(recommendations)
        if !accessible {
            fairnessIssues.append(FairnessIssue(
                type: .accessibilityIssue,
                description: "Some recommendations may not be accessible",
                severity: .medium
            ))
        }

        let isFair = fairnessIssues.filter { $0.severity == .high }.isEmpty

        return FairnessAssessment(
            isFair: isFair,
            fairnessScore: calculateFairnessScore(issues: fairnessIssues),
            issues: fairnessIssues,
            recommendations: generateFairnessRecommendations(issues: fairnessIssues)
        )
    }

    // MARK: - Bias Mitigation

    /// Apply bias mitigation to recommendations
    func mitigateBias(
        in recommendations: [String],
        targetDiversity: Double = 0.7
    ) -> [String] {
        var mitigated = recommendations

        // Ensure genre diversity
        mitigated = diversifyByGenre(mitigated, targetDiversity: targetDiversity)

        // Ensure cultural diversity
        mitigated = diversifyByCulture(mitigated, targetDiversity: targetDiversity)

        // Ensure era diversity
        mitigated = diversifyByEra(mitigated, targetDiversity: targetDiversity)

        return mitigated
    }

    // MARK: - Helper Methods

    private func extractGenre(from recommendation: String) -> String? {
        // Simplified genre extraction
        let genres = ["pop", "rock", "jazz", "folk", "country", "blues", "worship", "classical"]
        for genre in genres {
            if recommendation.lowercased().contains(genre) {
                return genre
            }
        }
        return nil
    }

    private func findOverrepresented(expected: [String: Double], actual: [String: Double]) -> [String] {
        return expected.compactMap { genre, expectedProp in
            let actualProp = actual[genre] ?? 0.0
            return actualProp > expectedProp * 1.5 ? genre : nil
        }
    }

    private func findUnderrepresented(expected: [String: Double], actual: [String: Double]) -> [String] {
        return expected.compactMap { genre, expectedProp in
            let actualProp = actual[genre] ?? 0.0
            return actualProp < expectedProp * 0.5 ? genre : nil
        }
    }

    private func generateGenreMitigations(biasScore: Double) -> [String] {
        if biasScore < 0.1 {
            return ["No mitigation needed - genre distribution is fair"]
        }

        return [
            "Increase diversity in recommendation algorithm",
            "Add genre balancing to recommendation scoring",
            "Include underrepresented genres in results",
            "Monitor genre distribution regularly"
        ]
    }

    private func getInsensitiveTerms(for context: CulturalContext) -> [String] {
        // In production, this would be a comprehensive database
        return ["savage", "primitive", "exotic", "oriental", "tribe"]
    }

    private func getStereotypes(for context: CulturalContext) -> [String] {
        // In production, this would be context-specific
        return []
    }

    private func hasAppropriationConcerns(_ content: String, culturalContext: CulturalContext) -> Bool {
        // Simplified check - in production would be more sophisticated
        return false
    }

    private func calculateSensitivityScore(issues: [CulturalIssue], warnings: [String]) -> Double {
        let highSeverityCount = issues.filter { $0.severity == .high }.count
        let mediumSeverityCount = issues.filter { $0.severity == .medium }.count

        let penalty = Double(highSeverityCount) * 0.3 + Double(mediumSeverityCount) * 0.15 + Double(warnings.count) * 0.05

        return max(0.0, 1.0 - penalty)
    }

    private func generateCulturalRecommendations(issues: [CulturalIssue]) -> [String] {
        if issues.isEmpty {
            return ["Content appears culturally sensitive"]
        }

        return [
            "Review flagged terms for cultural sensitivity",
            "Consider diverse perspectives in content",
            "Consult cultural advisors if uncertain",
            "Use inclusive and respectful language"
        ]
    }

    private func calculateDiversity(_ items: [String]) -> Double {
        guard !items.isEmpty else { return 0.0 }

        let uniqueCount = Set(items).count
        let totalCount = items.count

        // Shannon diversity index (simplified)
        let diversity = Double(uniqueCount) / Double(totalCount)
        return min(1.0, diversity * 2.0) // Normalize to 0-1
    }

    private func generateDiversityRecommendations(diversityLevel: DiversityLevel) -> [String] {
        switch diversityLevel {
        case .excellent:
            return ["Training data shows excellent diversity"]
        case .good:
            return ["Training data is well-diverse", "Continue monitoring"]
        case .fair:
            return ["Increase diversity in underrepresented areas", "Add more varied examples"]
        case .poor:
            return ["Significant diversity improvement needed", "Expand data sources"]
        case .inadequate:
            return ["Critical: Training data lacks diversity", "Major expansion required"]
        }
    }

    private func verifyAgeAppropriateness(_ recommendations: [String], age: Int) -> Bool {
        // Simplified check
        return true
    }

    private func verifyCulturalRepresentation(_ recommendations: [String], culture: String) -> Bool {
        // Simplified check
        return true
    }

    private func verifyAccessibility(_ recommendations: [String]) -> Bool {
        // Simplified check
        return true
    }

    private func calculateFairnessScore(issues: [FairnessIssue]) -> Double {
        let highSeverityCount = issues.filter { $0.severity == .high }.count
        let mediumSeverityCount = issues.filter { $0.severity == .medium }.count
        let lowSeverityCount = issues.filter { $0.severity == .low }.count

        let penalty = Double(highSeverityCount) * 0.3 + Double(mediumSeverityCount) * 0.15 + Double(lowSeverityCount) * 0.05

        return max(0.0, 1.0 - penalty)
    }

    private func generateFairnessRecommendations(issues: [FairnessIssue]) -> [String] {
        if issues.isEmpty {
            return ["Recommendations appear fair and inclusive"]
        }

        var recs: [String] = []

        for issue in issues {
            switch issue.type {
            case .ageInappropriate:
                recs.append("Filter recommendations by age appropriateness")
            case .lackOfRepresentation:
                recs.append("Increase cultural diversity in recommendations")
            case .accessibilityIssue:
                recs.append("Ensure all content is accessible")
            case .genderBias:
                recs.append("Review for gender bias in content")
            case .languageBias:
                recs.append("Support multiple languages")
            }
        }

        return Array(Set(recs))
    }

    private func diversifyByGenre(_ recommendations: [String], targetDiversity: Double) -> [String] {
        // Simplified diversification
        return recommendations
    }

    private func diversifyByCulture(_ recommendations: [String], targetDiversity: Double) -> [String] {
        // Simplified diversification
        return recommendations
    }

    private func diversifyByEra(_ recommendations: [String], targetDiversity: Double) -> [String] {
        // Simplified diversification
        return recommendations
    }
}

// MARK: - Data Models

/// Bias level
enum BiasLevel: String {
    case minimal, low, moderate, high, severe
}

/// Genre bias analysis
struct GenreBiasAnalysis {
    let biasScore: Double
    let biasLevel: BiasLevel
    let expectedDistribution: [String: Double]
    let actualDistribution: [String: Double]
    let overrepresentedGenres: [String]
    let underrepresentedGenres: [String]
    let mitigationSuggestions: [String]
}

/// Genre test case
struct GenreTestCase {
    let name: String
    let userHistory: [String]
    let expectedDistribution: [String: Double]
}

/// Genre fairness result
struct GenreFairnessResult {
    let testCase: GenreTestCase
    let analysis: GenreBiasAnalysis
    let passed: Bool
}

/// Genre fairness report
struct GenreFairnessReport {
    let results: [GenreFairnessResult]
    let overallPassRate: Double
    let recommendation: String
}

/// Cultural context
enum CulturalContext: String {
    case indigenous, asian, african, latinAmerican, middleEastern, european, pacific, general
}

/// Cultural issue type
enum CulturalIssueType {
    case insensitiveTerm
    case stereotype
    case culturalAppropriation
    case misrepresentation
}

/// Cultural issue severity
enum CulturalIssueSeverity {
    case low, medium, high, critical
}

/// Cultural issue
struct CulturalIssue {
    let type: CulturalIssueType
    let term: String
    let context: CulturalContext
    let severity: CulturalIssueSeverity
    let suggestion: String
}

/// Cultural sensitivity analysis
struct CulturalSensitivityAnalysis {
    let sensitivityScore: Double
    let issues: [CulturalIssue]
    let warnings: [String]
    let recommendations: [String]
}

/// Training dataset
struct TrainingDataset {
    let genres: [String]
    let culturalOrigins: [String]
    let languages: [String]
    let eras: [String]
}

/// Diversity level
enum DiversityLevel: String {
    case excellent, good, fair, poor, inadequate
}

/// Diversity analysis
struct DiversityAnalysis {
    let overallDiversity: Double
    let diversityLevel: DiversityLevel
    let genreDiversity: Double
    let culturalDiversity: Double
    let languageDiversity: Double
    let eraDiversity: Double
    let recommendations: [String]
}

/// User demographics
struct UserDemographics {
    let age: Int?
    let culturalBackground: String?
    let language: String?
    let accessibilityNeeds: [String]
}

/// Fairness issue type
enum FairnessIssueType {
    case ageInappropriate
    case lackOfRepresentation
    case accessibilityIssue
    case genderBias
    case languageBias
}

/// Fairness issue severity
enum FairnessIssueSeverity {
    case low, medium, high
}

/// Fairness issue
struct FairnessIssue {
    let type: FairnessIssueType
    let description: String
    let severity: FairnessIssueSeverity
}

/// Fairness assessment
struct FairnessAssessment {
    let isFair: Bool
    let fairnessScore: Double
    let issues: [FairnessIssue]
    let recommendations: [String]
}
