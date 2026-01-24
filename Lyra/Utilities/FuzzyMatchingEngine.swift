//
//  FuzzyMatchingEngine.swift
//  Lyra
//
//  Fuzzy string matching with typo tolerance and phonetic matching
//  Part of Phase 7.4: Search Intelligence
//

import Foundation

/// Engine for fuzzy string matching and typo tolerance
class FuzzyMatchingEngine {

    // MARK: - Properties

    private let maxLevenshteinDistance: Int = 3
    private let phoneticWeight: Float = 0.8

    // Common abbreviations in music context
    private let commonAbbreviations: [String: String] = [
        "AG": "Amazing Grace",
        "HTL": "How Great Thou Art",
        "BOTT": "Blessed Be Your Name",
        "WAYC": "What A Friend We Have In Jesus",
        "HGTA": "How Great Thou Art",
        "AOTF": "All of the Father",
        "GOTW": "God of Wonders"
    ]

    // MARK: - Fuzzy Matching

    /// Calculate fuzzy match score between query and target
    func fuzzyMatch(_ query: String, _ target: String) -> Float {
        let queryNorm = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let targetNorm = target.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Exact match
        if queryNorm == targetNorm {
            return 1.0
        }

        // Contains match
        if targetNorm.contains(queryNorm) {
            return 0.9
        }

        // Levenshtein distance
        let distance = levenshteinDistance(queryNorm, targetNorm)
        let maxLength = max(queryNorm.count, targetNorm.count)

        guard maxLength > 0 else { return 0.0 }

        // Convert distance to similarity score
        let similarity = 1.0 - (Float(distance) / Float(maxLength))

        // Apply threshold
        if distance <= maxLevenshteinDistance {
            return max(0.5, similarity)
        }

        // Check phonetic similarity
        let phoneticScore = phoneticMatch(queryNorm, targetNorm)
        if phoneticScore > 0.7 {
            return phoneticScore * phoneticWeight
        }

        return similarity
    }

    /// Calculate Levenshtein distance between two strings
    func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let s1 = Array(str1)
        let s2 = Array(str2)

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1),
                             count: s1.count + 1)

        // Initialize first row and column
        for i in 0...s1.count {
            matrix[i][0] = i
        }
        for j in 0...s2.count {
            matrix[0][j] = j
        }

        // Fill matrix
        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[i - 1] == s2[j - 1] ? 0 : 1

                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[s1.count][s2.count]
    }

    // MARK: - Phonetic Matching

    /// Check if two strings sound similar using Soundex
    func phoneticMatch(_ str1: String, _ str2: String) -> Float {
        let soundex1 = soundex(str1)
        let soundex2 = soundex(str2)

        if soundex1 == soundex2 {
            return 1.0
        }

        // Check if they share the same first letter and most of the code
        if soundex1.prefix(1) == soundex2.prefix(1) {
            let sharedDigits = zip(soundex1.dropFirst(), soundex2.dropFirst())
                .filter { $0 == $1 }
                .count

            return Float(sharedDigits) / 3.0
        }

        return 0.0
    }

    /// Generate Soundex code for phonetic matching
    func soundex(_ str: String) -> String {
        let normalized = str.uppercased()
            .filter { $0.isLetter }

        guard !normalized.isEmpty else { return "0000" }

        var code = String(normalized.prefix(1))

        let soundexMap: [Character: Character] = [
            "B": "1", "F": "1", "P": "1", "V": "1",
            "C": "2", "G": "2", "J": "2", "K": "2", "Q": "2", "S": "2", "X": "2", "Z": "2",
            "D": "3", "T": "3",
            "L": "4",
            "M": "5", "N": "5",
            "R": "6"
        ]

        var previousCode: Character = "0"

        for char in normalized.dropFirst() {
            if let soundCode = soundexMap[char] {
                if soundCode != previousCode {
                    code.append(soundCode)
                    previousCode = soundCode

                    if code.count == 4 {
                        break
                    }
                }
            } else {
                previousCode = "0"
            }
        }

        // Pad with zeros
        while code.count < 4 {
            code.append("0")
        }

        return code
    }

    /// Create phonetic encoding for a string
    func createPhoneticEncoding(_ str: String) -> PhoneticEncoding {
        return PhoneticEncoding(
            original: str,
            soundex: soundex(str),
            metaphone: nil // Soundex is sufficient for now
        )
    }

    // MARK: - Abbreviation Expansion

    /// Expand abbreviations to full terms
    func expandAbbreviation(_ query: String) -> [String] {
        let upper = query.uppercased()

        var expansions: [String] = []

        // Check known abbreviations
        if let expansion = commonAbbreviations[upper] {
            expansions.append(expansion)
        }

        // Check if it could be initials
        if query.count >= 2 && query.allSatisfy({ $0.isUppercase || $0.isWhitespace }) {
            // Could be initials - keep for matching
            expansions.append(query)
        }

        return expansions.isEmpty ? [query] : expansions
    }

    /// Check if query might be an abbreviation
    func isLikelyAbbreviation(_ query: String) -> Bool {
        // All uppercase letters with length 2-6
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count < 2 || trimmed.count > 6 {
            return false
        }

        return trimmed.allSatisfy { $0.isUppercase || $0.isWhitespace }
    }

    /// Match abbreviation against full text
    func matchAbbreviation(_ abbreviation: String, against text: String) -> Float {
        let abbr = abbreviation.uppercased()
            .filter { $0.isLetter }
        let words = text.split(separator: " ")
            .map { String($0) }

        // Check if abbreviation matches first letters of words
        if words.count >= abbr.count {
            let firstLetters = words.prefix(abbr.count)
                .map { String($0.prefix(1)).uppercased() }
                .joined()

            if firstLetters == abbr {
                return 1.0
            }
        }

        // Check if abbreviation matches first letters of any consecutive words
        for startIndex in 0..<words.count {
            let endIndex = min(startIndex + abbr.count, words.count)
            let subset = words[startIndex..<endIndex]

            let firstLetters = subset
                .map { String($0.prefix(1)).uppercased() }
                .joined()

            if firstLetters == abbr {
                return 0.9
            }
        }

        return 0.0
    }

    // MARK: - Typo Detection

    /// Common typo patterns and corrections
    func detectCommonTypos(_ query: String) -> [String] {
        var corrections: Set<String> = []

        // Double letter typos
        let singleLetters = query.replacingOccurrences(of: "(.)\\1+", with: "$1", options: .regularExpression)
        if singleLetters != query {
            corrections.insert(singleLetters)
        }

        // Transposition typos (swapped adjacent characters)
        var chars = Array(query)
        for i in 0..<chars.count - 1 {
            chars.swapAt(i, i + 1)
            corrections.insert(String(chars))
            chars.swapAt(i, i + 1) // swap back
        }

        // Common letter substitutions
        let substitutions: [(String, String)] = [
            ("ei", "ie"), ("ie", "ei"),
            ("a", "e"), ("e", "a"),
            ("c", "k"), ("k", "c"),
            ("s", "z"), ("z", "s")
        ]

        for (from, to) in substitutions {
            if query.contains(from) {
                corrections.insert(query.replacingOccurrences(of: from, with: to))
            }
        }

        return Array(corrections)
    }

    /// Get all possible fuzzy matches for a query
    func getAllFuzzyVariations(_ query: String) -> [String] {
        var variations = Set<String>()

        // Original query
        variations.insert(query)

        // Abbreviation expansions
        variations.formUnion(expandAbbreviation(query))

        // Common typos
        variations.formUnion(detectCommonTypos(query))

        // Case variations
        variations.insert(query.lowercased())
        variations.insert(query.uppercased())
        variations.insert(query.capitalized)

        return Array(variations)
    }

    // MARK: - Prefix Matching

    /// Check if target starts with query (for autocomplete)
    func prefixMatch(_ query: String, _ target: String) -> Float {
        let queryNorm = query.lowercased()
        let targetNorm = target.lowercased()

        if targetNorm.hasPrefix(queryNorm) {
            return 1.0
        }

        // Check word boundaries
        let words = targetNorm.split(separator: " ")
        for word in words {
            if word.hasPrefix(queryNorm) {
                return 0.9
            }
        }

        return 0.0
    }

    // MARK: - Token Matching

    /// Match query tokens against target tokens
    func tokenMatch(_ query: String, _ target: String) -> Float {
        let queryTokens = query.lowercased()
            .split(separator: " ")
            .map { String($0) }

        let targetTokens = target.lowercased()
            .split(separator: " ")
            .map { String($0) }

        guard !queryTokens.isEmpty else { return 0.0 }

        var matchedTokens = 0

        for queryToken in queryTokens {
            for targetToken in targetTokens {
                if fuzzyMatch(queryToken, targetToken) > 0.7 {
                    matchedTokens += 1
                    break
                }
            }
        }

        return Float(matchedTokens) / Float(queryTokens.count)
    }

    // MARK: - Similarity Scoring

    /// Calculate overall similarity score between query and target
    func calculateSimilarity(_ query: String, _ target: String) -> Float {
        let fuzzyScore = fuzzyMatch(query, target)
        let tokenScore = tokenMatch(query, target)
        let prefixScore = prefixMatch(query, target)

        // Weighted combination
        return (fuzzyScore * 0.5) + (tokenScore * 0.3) + (prefixScore * 0.2)
    }

    /// Find best match from a list of candidates
    func findBestMatch(_ query: String, in candidates: [String]) -> (match: String, score: Float)? {
        var bestMatch: String?
        var bestScore: Float = 0.0

        for candidate in candidates {
            let score = calculateSimilarity(query, candidate)

            if score > bestScore {
                bestScore = score
                bestMatch = candidate
            }
        }

        guard let match = bestMatch, bestScore > 0.5 else {
            return nil
        }

        return (match, bestScore)
    }

    // MARK: - Artist Name Variations

    /// Handle common artist name variations
    func matchArtistName(_ query: String, _ artistName: String) -> Float {
        let queryNorm = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let artistNorm = artistName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Exact match
        if queryNorm == artistNorm {
            return 1.0
        }

        // Check without "the", "&", "and"
        let stripWords = ["the", "&", "and", ","]
        var queryStripped = queryNorm
        var artistStripped = artistNorm

        for word in stripWords {
            queryStripped = queryStripped.replacingOccurrences(of: " \(word) ", with: " ")
            artistStripped = artistStripped.replacingOccurrences(of: " \(word) ", with: " ")
        }

        if queryStripped == artistStripped {
            return 0.95
        }

        // Check if one contains the other
        if artistNorm.contains(queryNorm) || queryNorm.contains(artistNorm) {
            return 0.9
        }

        // Fuzzy match
        return fuzzyMatch(queryNorm, artistNorm)
    }
}
