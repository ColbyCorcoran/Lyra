//
//  AIContentModerationEngine.swift
//  Lyra
//
//  Phase 7.13: AI-powered content moderation for public library
//  Uses on-device Apple frameworks for privacy-first moderation
//

import Foundation
import NaturalLanguage
import SwiftData

/// AI-powered content moderation engine using on-device analysis
@MainActor
class AIContentModerationEngine {
    static let shared = AIContentModerationEngine()

    private init() {}

    // MARK: - Moderation Result

    struct ModerationResult {
        let score: Double // 0.0 (safe) to 1.0 (high risk)
        let decision: ModerationDecision
        let reasons: [ModerationReason]
        let details: String
        let confidence: Double // 0.0 to 1.0

        var isApproved: Bool {
            decision == .autoApprove
        }

        var requiresReview: Bool {
            decision == .requiresReview
        }

        var isQuarantined: Bool {
            decision == .quarantine
        }
    }

    enum ModerationDecision: String {
        case autoApprove = "Auto-Approved"
        case requiresReview = "Requires Review"
        case quarantine = "Quarantined"
        case rejected = "Auto-Rejected"
    }

    enum ModerationReason: String {
        // Content issues
        case inappropriateContent = "Inappropriate content detected"
        case profanity = "Profanity detected"
        case explicitContent = "Explicit content detected"

        // Copyright issues
        case likelyCopyrighted = "Likely copyrighted material"
        case knownCopyrightedWork = "Matches known copyrighted work"

        // Quality issues
        case poorQuality = "Poor quality upload"
        case incomplete = "Incomplete song"
        case malformedChordPro = "Malformed ChordPro format"
        case missingMetadata = "Missing required metadata"

        // Spam issues
        case potentialSpam = "Potential spam detected"
        case repetitiveContent = "Repetitive content"
        case suspiciousPattern = "Suspicious upload pattern"

        var severity: Int {
            switch self {
            case .explicitContent, .knownCopyrightedWork:
                return 3 // High
            case .inappropriateContent, .profanity, .likelyCopyrighted, .potentialSpam:
                return 2 // Medium
            case .poorQuality, .incomplete, .malformedChordPro, .missingMetadata, .repetitiveContent, .suspiciousPattern:
                return 1 // Low
            }
        }
    }

    // MARK: - Main Analysis

    /// Analyzes a public song upload for moderation
    func analyzeSong(
        _ publicSong: PublicSong,
        uploaderReputation: UserReputation?,
        recentUploads: [PublicSong]
    ) async -> ModerationResult {
        var reasons: [ModerationReason] = []
        var scores: [Double] = []

        // 1. Content Analysis
        let contentAnalysis = await analyzeContent(publicSong.content, lyrics: publicSong.content)
        reasons.append(contentsOf: contentAnalysis.reasons)
        scores.append(contentAnalysis.score)

        // 2. Copyright Detection
        let copyrightAnalysis = await detectCopyright(publicSong)
        reasons.append(contentsOf: copyrightAnalysis.reasons)
        scores.append(copyrightAnalysis.score)

        // 3. Quality Filtering
        let qualityAnalysis = analyzeQuality(publicSong)
        reasons.append(contentsOf: qualityAnalysis.reasons)
        scores.append(qualityAnalysis.score)

        // 4. Spam Detection
        let spamAnalysis = detectSpam(publicSong, recentUploads: recentUploads)
        reasons.append(contentsOf: spamAnalysis.reasons)
        scores.append(spamAnalysis.score)

        // Calculate overall score
        let overallScore = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)

        // Apply reputation multiplier
        let reputationMultiplier = getReputationMultiplier(uploaderReputation)
        let adjustedScore = overallScore * reputationMultiplier

        // Determine decision
        let decision = determineDecision(
            score: adjustedScore,
            reasons: reasons,
            reputation: uploaderReputation
        )

        // Generate details
        let details = generateDetailsString(reasons: reasons, score: adjustedScore, reputation: uploaderReputation)

        // Calculate confidence
        let confidence = calculateConfidence(reasons: reasons, reputation: uploaderReputation)

        return ModerationResult(
            score: adjustedScore,
            decision: decision,
            reasons: reasons,
            details: details,
            confidence: confidence
        )
    }

    // MARK: - 1. Content Analysis

    private func analyzeContent(_ content: String, lyrics: String) async -> (score: Double, reasons: [ModerationReason]) {
        var reasons: [ModerationReason] = []
        var scores: [Double] = []

        // Use NaturalLanguage for sentiment and content analysis
        let tagger = NLTagger(tagSchemes: [.sentimentScore, .lexicalClass, .language])
        tagger.string = lyrics

        // Check for profanity and inappropriate language
        let profanityCheck = checkForProfanity(lyrics)
        if profanityCheck.detected {
            reasons.append(.profanity)
            scores.append(profanityCheck.severity)
        }

        // Check for explicit content markers
        let explicitCheck = checkForExplicitContent(lyrics)
        if explicitCheck.detected {
            reasons.append(.explicitContent)
            scores.append(explicitCheck.severity)
        }

        // Check for inappropriate themes
        let inappropriateCheck = checkForInappropriateThemes(lyrics)
        if inappropriateCheck.detected {
            reasons.append(.inappropriateContent)
            scores.append(inappropriateCheck.severity)
        }

        let avgScore = scores.isEmpty ? 0.0 : scores.reduce(0, +) / Double(scores.count)
        return (avgScore, reasons)
    }

    private func checkForProfanity(_ text: String) -> (detected: Bool, severity: Double) {
        let profanityWords = loadProfanityList()
        let lowercaseText = text.lowercased()

        var matchCount = 0
        for word in profanityWords {
            if lowercaseText.contains(word) {
                matchCount += 1
            }
        }

        if matchCount > 0 {
            let severity = min(1.0, Double(matchCount) * 0.3)
            return (true, severity)
        }

        return (false, 0.0)
    }

    private func checkForExplicitContent(_ text: String) -> (detected: Bool, severity: Double) {
        let explicitMarkers = ["explicit", "parental advisory", "nsfw", "18+", "mature content"]
        let lowercaseText = text.lowercased()

        for marker in explicitMarkers {
            if lowercaseText.contains(marker) {
                return (true, 0.9)
            }
        }

        return (false, 0.0)
    }

    private func checkForInappropriateThemes(_ text: String) -> (detected: Bool, severity: Double) {
        // Check for inappropriate themes using keyword analysis
        let inappropriateKeywords = loadInappropriateKeywords()
        let lowercaseText = text.lowercased()

        var matchCount = 0
        for keyword in inappropriateKeywords {
            if lowercaseText.contains(keyword) {
                matchCount += 1
            }
        }

        if matchCount > 2 {
            let severity = min(0.8, Double(matchCount) * 0.2)
            return (true, severity)
        }

        return (false, 0.0)
    }

    // MARK: - 2. Copyright Detection

    private func detectCopyright(_ publicSong: PublicSong) async -> (score: Double, reasons: [ModerationReason]) {
        var reasons: [ModerationReason] = []
        var score = 0.0

        // Check if license indicates copyright
        if publicSong.licenseType == .copyrighted && publicSong.copyrightInfo == nil {
            reasons.append(.likelyCopyrighted)
            score = 0.7
        }

        // Check for known copyrighted work indicators
        let knownWorkCheck = await checkAgainstKnownWorks(publicSong)
        if knownWorkCheck.isMatch {
            reasons.append(.knownCopyrightedWork)
            score = max(score, knownWorkCheck.confidence)
        }

        // Fuzzy matching of lyrics against known database
        let fuzzyMatch = await fuzzyMatchLyrics(publicSong.content)
        if fuzzyMatch.similarity > 0.8 {
            reasons.append(.likelyCopyrighted)
            score = max(score, fuzzyMatch.similarity * 0.6)
        }

        return (score, reasons)
    }

    private func checkAgainstKnownWorks(_ publicSong: PublicSong) async -> (isMatch: Bool, confidence: Double) {
        // Check against database of known copyrighted works
        // This would use a local database of song titles and artists
        let knownCopyrightedWorks = getKnownCopyrightedWorks()

        let songIdentifier = "\(publicSong.title.lowercased())|\(publicSong.artist?.lowercased() ?? "")"

        for work in knownCopyrightedWorks {
            let workIdentifier = "\(work.title.lowercased())|\(work.artist.lowercased())"

            let similarity = calculateStringSimilarity(songIdentifier, workIdentifier)
            if similarity > 0.9 {
                return (true, similarity)
            }
        }

        return (false, 0.0)
    }

    private func fuzzyMatchLyrics(_ content: String) async -> (similarity: Double, matchedWork: String?) {
        // Use NaturalLanguage for semantic similarity
        // Extract key phrases and compare against known works

        let embedding = NLEmbedding.wordEmbedding(for: .english)
        let contentWords = extractKeyWords(content)

        // Check against known lyric patterns
        // For now, basic pattern matching
        let suspiciousPatterns = [
            "all rights reserved",
            "© copyright",
            "used by permission",
            "ccli license"
        ]

        let lowercaseContent = content.lowercased()
        for pattern in suspiciousPatterns {
            if lowercaseContent.contains(pattern) {
                return (0.85, pattern)
            }
        }

        return (0.0, nil)
    }

    // MARK: - 3. Quality Filtering

    private func analyzeQuality(_ publicSong: PublicSong) -> (score: Double, reasons: [ModerationReason]) {
        var reasons: [ModerationReason] = []
        var qualityIssues = 0

        // Check for incomplete songs
        if isIncomplete(publicSong) {
            reasons.append(.incomplete)
            qualityIssues += 1
        }

        // Check for malformed ChordPro
        if publicSong.contentFormat == .chordPro {
            if isMalformedChordPro(publicSong.content) {
                reasons.append(.malformedChordPro)
                qualityIssues += 1
            }
        }

        // Check for missing metadata
        if hasMissingMetadata(publicSong) {
            reasons.append(.missingMetadata)
            qualityIssues += 1
        }

        // Check overall quality
        if isPoorQuality(publicSong) {
            reasons.append(.poorQuality)
            qualityIssues += 1
        }

        let score = min(1.0, Double(qualityIssues) * 0.25)
        return (score, reasons)
    }

    private func isIncomplete(_ publicSong: PublicSong) -> Bool {
        let content = publicSong.content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Too short
        if content.count < 50 {
            return true
        }

        // No chords detected
        if !containsChords(content) {
            return true
        }

        return false
    }

    private func isMalformedChordPro(_ content: String) -> Bool {
        // Check for basic ChordPro structure
        let chordProPattern = /\{[^}]+\}/

        // Count directive-like patterns
        let directiveCount = content.matches(of: chordProPattern).count

        // Check for mismatched brackets
        let openBrackets = content.filter { $0 == "{" }.count
        let closeBrackets = content.filter { $0 == "}" }.count

        if openBrackets != closeBrackets {
            return true
        }

        // If it claims to be ChordPro but has no directives
        if directiveCount == 0 {
            return true
        }

        return false
    }

    private func hasMissingMetadata(_ publicSong: PublicSong) -> Bool {
        // Title is required
        if publicSong.title.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }

        // Should have at least artist or some metadata
        let hasArtist = publicSong.artist != nil && !publicSong.artist!.isEmpty
        let hasKey = publicSong.originalKey != nil && !publicSong.originalKey!.isEmpty
        let hasTags = publicSong.tags != nil && !publicSong.tags!.isEmpty

        // At least one should be present
        return !(hasArtist || hasKey || hasTags)
    }

    private func isPoorQuality(_ publicSong: PublicSong) -> Bool {
        let content = publicSong.content

        // Check for excessive special characters (gibberish)
        let specialCharRatio = Double(content.filter { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }.count) / Double(max(1, content.count))
        if specialCharRatio > 0.3 {
            return true
        }

        // Check for very short lines (possibly incomplete)
        let lines = content.components(separatedBy: .newlines)
        let shortLines = lines.filter { $0.trimmingCharacters(in: .whitespaces).count < 5 }
        if shortLines.count > lines.count / 2 {
            return true
        }

        return false
    }

    private func containsChords(_ content: String) -> Bool {
        // Simple chord detection
        let chordPatterns = [
            /[A-G](?:#|b)?(?:m|maj|min|dim|aug)?(?:\d+)?/,  // Basic chords
            /\[[A-G](?:#|b)?(?:m|maj)?(?:\d+)?\]/,          // Bracketed chords
        ]

        for pattern in chordPatterns {
            if content.contains(pattern) {
                return true
            }
        }

        return false
    }

    // MARK: - 4. Spam Detection

    private func detectSpam(_ publicSong: PublicSong, recentUploads: [PublicSong]) -> (score: Double, reasons: [ModerationReason]) {
        var reasons: [ModerationReason] = []
        var score = 0.0

        // Check for repetitive content
        let repetitiveCheck = checkRepetitiveContent(publicSong, recentUploads: recentUploads)
        if repetitiveCheck.isRepetitive {
            reasons.append(.repetitiveContent)
            score = max(score, repetitiveCheck.severity)
        }

        // Check upload rate
        let rateCheck = checkUploadRate(recentUploads)
        if rateCheck.isSuspicious {
            reasons.append(.suspiciousPattern)
            score = max(score, rateCheck.severity)
        }

        // Check for spam patterns in content
        let spamCheck = checkSpamPatterns(publicSong.content)
        if spamCheck.isSpam {
            reasons.append(.potentialSpam)
            score = max(score, spamCheck.severity)
        }

        return (score, reasons)
    }

    private func checkRepetitiveContent(_ publicSong: PublicSong, recentUploads: [PublicSong]) -> (isRepetitive: Bool, severity: Double) {
        var duplicateCount = 0

        for upload in recentUploads.prefix(10) {
            let similarity = calculateStringSimilarity(publicSong.content, upload.content)
            if similarity > 0.9 {
                duplicateCount += 1
            }
        }

        if duplicateCount > 0 {
            let severity = min(1.0, Double(duplicateCount) * 0.4)
            return (true, severity)
        }

        return (false, 0.0)
    }

    private func checkUploadRate(_ recentUploads: [PublicSong]) -> (isSuspicious: Bool, severity: Double) {
        // Check if uploading too frequently
        let last24Hours = Date().addingTimeInterval(-24 * 60 * 60)
        let recentCount = recentUploads.filter { $0.createdAt > last24Hours }.count

        if recentCount > 10 {
            let severity = min(1.0, Double(recentCount) / 20.0)
            return (true, severity)
        }

        return (false, 0.0)
    }

    private func checkSpamPatterns(_ content: String) -> (isSpam: Bool, severity: Double) {
        let spamKeywords = ["click here", "visit my", "check out my", "follow me", "subscribe", "www.", "http"]
        let lowercaseContent = content.lowercased()

        var matchCount = 0
        for keyword in spamKeywords {
            if lowercaseContent.contains(keyword) {
                matchCount += 1
            }
        }

        if matchCount > 2 {
            let severity = min(1.0, Double(matchCount) * 0.3)
            return (true, severity)
        }

        return (false, 0.0)
    }

    // MARK: - Decision Logic

    private func determineDecision(
        score: Double,
        reasons: [ModerationReason],
        reputation: UserReputation?
    ) -> ModerationDecision {
        let maxSeverity = reasons.map { $0.severity }.max() ?? 0

        // Check for auto-reject conditions (high severity issues)
        if maxSeverity >= 3 {
            return .rejected
        }

        // Check for quarantine conditions (medium-high risk)
        if score > 0.7 || maxSeverity >= 2 {
            return .quarantine
        }

        // Check for manual review (medium risk or new user)
        if score > 0.4 || reasons.count >= 2 {
            return .requiresReview
        }

        // Trusted users with clean content get auto-approved
        if let reputation = reputation, reputation.isTrusted, score < 0.2 {
            return .autoApprove
        }

        // New users with clean content require review
        if reputation == nil || !reputation!.isTrusted {
            return .requiresReview
        }

        // Default to auto-approve for low-risk content
        return score < 0.3 ? .autoApprove : .requiresReview
    }

    private func getReputationMultiplier(_ reputation: UserReputation?) -> Double {
        guard let reputation = reputation else {
            return 1.0 // New users get no benefit
        }

        if reputation.isTrusted {
            return 0.5 // 50% reduction in risk score
        } else if reputation.score > 50 {
            return 0.75 // 25% reduction
        } else if reputation.score < 20 {
            return 1.5 // 50% increase in risk score
        }

        return 1.0
    }

    private func generateDetailsString(reasons: [ModerationReason], score: Double, reputation: UserReputation?) -> String {
        var details = "Moderation Analysis:\n\n"

        if reasons.isEmpty {
            details += "✓ No issues detected\n"
        } else {
            details += "Issues found:\n"
            for reason in reasons {
                let severity = ["Low", "Medium", "High"][min(2, reason.severity - 1)]
                details += "• [\(severity)] \(reason.rawValue)\n"
            }
        }

        details += "\nRisk Score: \(String(format: "%.1f", score * 100))%\n"

        if let reputation = reputation {
            details += "Uploader Reputation: \(String(format: "%.0f", reputation.score))/100"
            if reputation.isTrusted {
                details += " (Trusted)"
            }
            details += "\n"
        } else {
            details += "Uploader: New user\n"
        }

        return details
    }

    private func calculateConfidence(reasons: [ModerationReason], reputation: UserReputation?) -> Double {
        // Higher confidence when we have clear signals
        var confidence = 0.7 // Base confidence

        // More reasons = higher confidence
        confidence += min(0.2, Double(reasons.count) * 0.05)

        // Known user = higher confidence
        if reputation != nil {
            confidence += 0.1
        }

        return min(1.0, confidence)
    }

    // MARK: - Helper Methods

    private func loadProfanityList() -> [String] {
        // In production, load from local database
        return [
            "damn", "hell", "crap", "shit", "fuck", "ass", "bitch",
            // Add more as needed
        ]
    }

    private func loadInappropriateKeywords() -> [String] {
        return [
            "violence", "death", "suicide", "hate", "racist", "sexist",
            "drug", "alcohol", "abuse", "murder", "kill", "weapon"
        ]
    }

    private func getKnownCopyrightedWorks() -> [(title: String, artist: String)] {
        // In production, load from local database
        return [
            ("Amazing Grace", "John Newton"),
            ("How Great Thou Art", "Carl Boberg"),
            // This would be a comprehensive database
        ]
    }

    private func extractKeyWords(_ text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var keywords: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if tag == .noun || tag == .verb {
                keywords.append(String(text[range]))
            }
            return true
        }

        return keywords
    }

    private func calculateStringSimilarity(_ str1: String, _ str2: String) -> Double {
        // Levenshtein distance-based similarity
        let distance = levenshteinDistance(str1, str2)
        let maxLength = max(str1.count, str2.count)

        if maxLength == 0 {
            return 1.0
        }

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let s1 = Array(str1)
        let s2 = Array(str2)

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)

        for i in 0...s1.count {
            matrix[i][0] = i
        }

        for j in 0...s2.count {
            matrix[0][j] = j
        }

        for i in 1...s1.count {
            for j in 1...s2.count {
                if s1[i-1] == s2[j-1] {
                    matrix[i][j] = matrix[i-1][j-1]
                } else {
                    matrix[i][j] = min(
                        matrix[i-1][j] + 1,
                        matrix[i][j-1] + 1,
                        matrix[i-1][j-1] + 1
                    )
                }
            }
        }

        return matrix[s1.count][s2.count]
    }
}
