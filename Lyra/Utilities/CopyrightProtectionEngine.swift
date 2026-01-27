//
//  CopyrightProtectionEngine.swift
//  Lyra
//
//  Phase 7.15: AI Ethics and Transparency
//  Copyright respect: don't reproduce copyrighted lyrics, detect violations, educate users, respect artists' rights
//

import Foundation

/// Copyright protection engine for respecting artists' rights and preventing violations
class CopyrightProtectionEngine {
    static let shared = CopyrightProtectionEngine()

    private init() {}

    // MARK: - Copyright Detection

    /// Check if content potentially violates copyright
    func checkCopyrightViolation(
        title: String,
        artist: String?,
        lyrics: String?
    ) -> CopyrightCheckResult {
        var violations: [CopyrightViolation] = []
        var warnings: [String] = []

        // Check against known copyrighted works
        if let knownWork = checkAgainstKnownWorks(title: title, artist: artist) {
            violations.append(CopyrightViolation(
                type: .knownCopyrightedWork,
                work: knownWork,
                confidence: 0.9,
                severity: .high
            ))
        }

        // Check for full lyric reproduction
        if let lyrics = lyrics, !lyrics.isEmpty {
            if isFullLyricReproduction(lyrics) {
                violations.append(CopyrightViolation(
                    type: .fullLyricReproduction,
                    work: "\(title) - \(artist ?? "Unknown")",
                    confidence: 0.8,
                    severity: .high
                ))
            }

            // Check for partial reproduction
            if let matchedWork = detectPartialReproduction(lyrics) {
                warnings.append("Partial lyric match detected with '\(matchedWork)'")
            }
        }

        // Check for copyright indicators in text
        if hasExplicitCopyrightNotice(title: title, lyrics: lyrics) {
            warnings.append("Content contains copyright notice")
        }

        let status: CopyrightStatus = violations.isEmpty ? .clear :
                                       violations.contains(where: { $0.severity == .high }) ? .violation :
                                       .warning

        return CopyrightCheckResult(
            status: status,
            violations: violations,
            warnings: warnings,
            educationalMessage: generateEducationalMessage(status: status),
            suggestedAction: generateSuggestedAction(status: status)
        )
    }

    /// Detect if AI-generated content reproduces copyrighted material
    func detectAIReproduction(
        aiGeneratedContent: String,
        contentType: AIContentType
    ) -> AIReproductionCheck {
        var concerns: [ReproductionConcern] = []

        // Check for exact matches with known copyrighted phrases
        if let matches = findExactMatches(aiGeneratedContent) {
            for match in matches {
                concerns.append(ReproductionConcern(
                    type: .exactMatch,
                    matchedText: match.text,
                    originalWork: match.work,
                    confidence: 0.95
                ))
            }
        }

        // Check for substantial similarity
        if let similarWorks = findSubstantialSimilarity(aiGeneratedContent) {
            for work in similarWorks {
                concerns.append(ReproductionConcern(
                    type: .substantialSimilarity,
                    matchedText: work.matchedText,
                    originalWork: work.title,
                    confidence: work.similarityScore
                ))
            }
        }

        let isSafe = concerns.filter { $0.confidence > 0.7 }.isEmpty

        return AIReproductionCheck(
            isSafe: isSafe,
            concerns: concerns,
            recommendation: isSafe ? "AI content appears original" :
                           "Review AI content for copyright concerns"
        )
    }

    // MARK: - Copyright Education

    /// Get copyright education content
    func getCopyrightEducation() -> CopyrightEducation {
        return CopyrightEducation(
            principles: [
                "Songs are protected by copyright from the moment of creation",
                "Both music and lyrics are separately copyrighted",
                "Fair use allows limited quoting for education, criticism, or commentary",
                "Chord progressions alone are not copyrightable",
                "Copyright typically lasts 70 years after the creator's death"
            ],
            whatIsProtected: [
                "✅ Lyrics (protected)",
                "✅ Melodies (protected)",
                "✅ Arrangements (protected)",
                "✅ Recordings (protected)",
                "❌ Chord progressions (not protected)",
                "❌ Song titles (generally not protected)",
                "❌ Basic rhythms (not protected)"
            ],
            fairUse: [
                "Educational use in classroom settings",
                "Critical commentary or analysis",
                "Parody or transformative works",
                "Limited excerpts for review purposes"
            ],
            bestPractices: [
                "Use chord charts without full lyrics",
                "Include only essential lyric fragments",
                "Always attribute the original artist",
                "Link to legal sources for full lyrics",
                "Respect 'all rights reserved' notices",
                "When in doubt, use public domain works"
            ],
            publicDomain: [
                "Works published before 1928",
                "Works explicitly released to public domain",
                "Traditional folk songs (arrangements may be copyrighted)",
                "Government works (US federal government)"
            ],
            resources: [
                "US Copyright Office: copyright.gov",
                "Creative Commons: creativecommons.org",
                "Music Publishers Association: mpa.org",
                "ASCAP/BMI/SESAC for licensing"
            ]
        )
    }

    /// Generate copyright disclaimer
    func generateCopyrightDisclaimer(
        for content: String,
        contentType: ContentType
    ) -> String {
        switch contentType {
        case .chordChart:
            return """
            ⚠️ Copyright Notice

            This chord chart is for personal, educational use only.

            • The song and lyrics are copyrighted by their respective owners
            • Chord progressions themselves are not copyrighted
            • Do not reproduce or distribute copyrighted lyrics
            • Support artists by purchasing official sheet music
            • For public performance, obtain proper licensing (ASCAP/BMI/SESAC)

            Respect artists' rights. Use responsibly.
            """

        case .aiSuggestion:
            return """
            ℹ️ AI-Generated Content

            This suggestion was generated by on-device AI.

            • Review suggestions for unintentional copyright similarity
            • The AI was trained to avoid reproducing copyrighted material
            • You are responsible for ensuring your final work is original
            • If a suggestion seems familiar, verify its originality

            Create responsibly and respect others' intellectual property.
            """

        case .publicLibraryUpload:
            return """
            📚 Public Library Guidelines

            By uploading to the public library, you confirm:

            • You own the copyright OR have permission to share
            • The content does not infringe on others' copyrights
            • You will properly attribute any borrowed elements
            • The content is appropriate for public sharing

            Violations may result in content removal and account restrictions.
            """
        }
    }

    // MARK: - Artist Rights

    /// Educate about respecting artists' rights
    func getArtistRightsEducation() -> ArtistRightsEducation {
        return ArtistRightsEducation(
            moralRights: [
                "Right of attribution (being credited as creator)",
                "Right of integrity (work not being distorted)",
                "Right to control first publication"
            ],
            economicRights: [
                "Right to reproduce the work",
                "Right to create derivative works",
                "Right to distribute copies",
                "Right to perform publicly",
                "Right to display publicly"
            ],
            respectfulPractices: [
                "Always credit the original artist and songwriter",
                "Don't claim others' work as your own",
                "Support artists by purchasing legal copies",
                "Respect artists' wishes about their work",
                "Obtain permission before substantial modifications"
            ],
            howToAttribute: [
                "Include: Song title, artist name, songwriter(s)",
                "Format: 'Title' by Artist (Written by Songwriter)",
                "Example: 'Amazing Grace' - Traditional (John Newton)",
                "Add copyright year if known",
                "Link to official sources when possible"
            ]
        )
    }

    /// Verify proper attribution
    func verifyAttribution(
        title: String,
        artist: String?,
        songwriter: String?,
        copyrightYear: Int?
    ) -> AttributionCheck {
        var missing: [String] = []
        var suggestions: [String] = []

        if artist == nil {
            missing.append("artist")
            suggestions.append("Add the performing artist's name")
        }

        if songwriter == nil {
            suggestions.append("Consider adding the songwriter/composer name")
        }

        if copyrightYear == nil {
            suggestions.append("Adding the copyright year helps identify the version")
        }

        let isComplete = missing.isEmpty
        let quality: AttributionQuality = isComplete && songwriter != nil && copyrightYear != nil ? .excellent :
                                          isComplete ? .good :
                                          artist != nil ? .minimal :
                                          .inadequate

        return AttributionCheck(
            isComplete: isComplete,
            quality: quality,
            missingFields: missing,
            suggestions: suggestions
        )
    }

    // MARK: - Safe AI Generation

    /// Get guidelines for copyright-safe AI generation
    func getCopyrightSafeAIGuidelines() -> [String] {
        return [
            "🎵 AI generates original suggestions, not reproductions",
            "✏️ Review all AI suggestions before using",
            "🔍 Verify suggestions don't match existing songs",
            "🎨 Treat AI suggestions as inspiration, not final content",
            "⚖️ You are responsible for the originality of your work",
            "🛡️ All AI processing happens on-device for privacy",
            "📚 AI was designed to respect copyright from the start",
            "💡 Use AI as a creative tool, not a copying mechanism"
        ]
    }

    /// Filter AI suggestions to remove potential copyright concerns
    func filterCopyrightSafeSuggestions(
        suggestions: [String],
        contentType: AIContentType
    ) -> [String] {
        return suggestions.filter { suggestion in
            let check = detectAIReproduction(aiGeneratedContent: suggestion, contentType: contentType)
            return check.isSafe
        }
    }

    // MARK: - Helper Methods

    private func checkAgainstKnownWorks(title: String, artist: String?) -> String? {
        // In production, this would check against a database of known copyrighted works
        // For now, return nil (no match)
        return nil
    }

    private func isFullLyricReproduction(_ lyrics: String) -> Bool {
        // Check if lyrics contain multiple verses (likely full reproduction)
        let lines = lyrics.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return lines.count > 20 // Simplified heuristic
    }

    private func detectPartialReproduction(_ lyrics: String) -> String? {
        // In production, would check against known lyric fragments
        return nil
    }

    private func hasExplicitCopyrightNotice(title: String, lyrics: String?) -> Bool {
        let copyrightIndicators = ["©", "(c)", "copyright", "all rights reserved"]
        let searchText = "\(title) \(lyrics ?? "")".lowercased()

        return copyrightIndicators.contains { searchText.contains($0) }
    }

    private func generateEducationalMessage(status: CopyrightStatus) -> String {
        switch status {
        case .clear:
            return "No copyright concerns detected. Remember to properly attribute artists."
        case .warning:
            return "Potential copyright concerns detected. Review content and ensure proper attribution."
        case .violation:
            return "Copyright violation detected. This content appears to reproduce copyrighted material. Please use only chord progressions or obtain proper licensing."
        }
    }

    private func generateSuggestedAction(status: CopyrightStatus) -> String {
        switch status {
        case .clear:
            return "Proceed with proper attribution"
        case .warning:
            return "Review and remove questionable content"
        case .violation:
            return "Remove copyrighted content or obtain licensing"
        }
    }

    private func findExactMatches(_ content: String) -> [(text: String, work: String)]? {
        // In production, would check against database
        return nil
    }

    private func findSubstantialSimilarity(_ content: String) -> [(matchedText: String, title: String, similarityScore: Double)]? {
        // In production, would use fuzzy matching algorithms
        return nil
    }
}

// MARK: - Data Models

/// Copyright status
enum CopyrightStatus {
    case clear
    case warning
    case violation
}

/// Copyright violation type
enum CopyrightViolationType {
    case knownCopyrightedWork
    case fullLyricReproduction
    case partialReproduction
    case unlicensedDistribution
}

/// Copyright violation severity
enum CopyrightViolationSeverity {
    case low, medium, high, critical
}

/// Copyright violation
struct CopyrightViolation {
    let type: CopyrightViolationType
    let work: String
    let confidence: Double
    let severity: CopyrightViolationSeverity
}

/// Copyright check result
struct CopyrightCheckResult {
    let status: CopyrightStatus
    let violations: [CopyrightViolation]
    let warnings: [String]
    let educationalMessage: String
    let suggestedAction: String
}

/// AI content type
enum AIContentType {
    case lyrics
    case melody
    case chordProgression
    case structure
}

/// Reproduction concern type
enum ReproductionConcernType {
    case exactMatch
    case substantialSimilarity
    case stylisticImitation
}

/// Reproduction concern
struct ReproductionConcern {
    let type: ReproductionConcernType
    let matchedText: String
    let originalWork: String
    let confidence: Double
}

/// AI reproduction check
struct AIReproductionCheck {
    let isSafe: Bool
    let concerns: [ReproductionConcern]
    let recommendation: String
}

/// Copyright education
struct CopyrightEducation {
    let principles: [String]
    let whatIsProtected: [String]
    let fairUse: [String]
    let bestPractices: [String]
    let publicDomain: [String]
    let resources: [String]
}

/// Content type for disclaimers
enum ContentType {
    case chordChart
    case aiSuggestion
    case publicLibraryUpload
}

/// Artist rights education
struct ArtistRightsEducation {
    let moralRights: [String]
    let economicRights: [String]
    let respectfulPractices: [String]
    let howToAttribute: [String]
}

/// Attribution quality
enum AttributionQuality {
    case excellent
    case good
    case minimal
    case inadequate
}

/// Attribution check
struct AttributionCheck {
    let isComplete: Bool
    let quality: AttributionQuality
    let missingFields: [String]
    let suggestions: [String]
}
