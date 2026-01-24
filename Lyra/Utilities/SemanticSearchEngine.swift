//
//  SemanticSearchEngine.swift
//  Lyra
//
//  Semantic search with sentiment analysis and meaning-based matching
//  Part of Phase 7.4: Search Intelligence
//

import Foundation
import NaturalLanguage

/// Engine for semantic and sentiment-based search
class SemanticSearchEngine {

    // MARK: - Properties

    private let sentimentPredictor = NLModel(mlModel: createSentimentModel())
    private let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])

    // MARK: - Sentiment Analysis

    /// Analyze sentiment of text
    func analyzeSentiment(_ text: String) -> SearchQuery.Sentiment {
        tagger.string = text

        var positiveScore: Float = 0.0
        var negativeScore: Float = 0.0

        // Analyze using NaturalLanguage sentiment
        let sentimentScore = getSentimentScore(text)

        if sentimentScore > 0.2 {
            return .positive
        } else if sentimentScore < -0.2 {
            return .negative
        } else {
            return .neutral
        }
    }

    /// Get numerical sentiment score (-1.0 to 1.0)
    private func getSentimentScore(_ text: String) -> Float {
        let positiveWords = [
            "happy", "joy", "joyful", "glad", "cheerful", "blessed", "wonderful",
            "amazing", "great", "awesome", "love", "peace", "hope", "praise",
            "celebrate", "rejoice", "glory", "hallelujah", "victorious", "triumph"
        ]

        let negativeWords = [
            "sad", "sorrow", "grief", "pain", "hurt", "broken", "lost",
            "darkness", "despair", "trouble", "fear", "cry", "tears", "mourn",
            "weep", "suffering", "anguish", "burden", "struggle"
        ]

        let lowercased = text.lowercased()
        var score: Float = 0.0

        for word in positiveWords {
            if lowercased.contains(word) {
                score += 0.2
            }
        }

        for word in negativeWords {
            if lowercased.contains(word) {
                score -= 0.2
            }
        }

        return max(-1.0, min(1.0, score))
    }

    // MARK: - Mood Detection

    /// Detect mood category from text
    func detectMood(_ text: String) -> [MoodCategory] {
        let lowercased = text.lowercased()
        var detectedMoods: [(mood: MoodCategory, score: Int)] = []

        for mood in MoodCategory.allCases {
            var score = 0

            for keyword in mood.keywords {
                if lowercased.contains(keyword) {
                    score += 1
                }
            }

            if score > 0 {
                detectedMoods.append((mood, score))
            }
        }

        // Return top moods sorted by score
        return detectedMoods
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0.mood }
    }

    /// Check if text matches a mood
    func matchesMood(_ text: String, mood: MoodCategory) -> Float {
        let lowercased = text.lowercased()
        var matchCount = 0

        for keyword in mood.keywords {
            if lowercased.contains(keyword) {
                matchCount += 1
            }
        }

        return Float(matchCount) / Float(mood.keywords.count)
    }

    // MARK: - Semantic Similarity

    /// Calculate semantic similarity between query and text
    func semanticSimilarity(_ query: String, _ text: String) -> Float {
        // Extract key terms from query
        let queryTerms = extractKeyTerms(query)
        let textTerms = extractKeyTerms(text)

        guard !queryTerms.isEmpty else { return 0.0 }

        var matchScore: Float = 0.0

        for queryTerm in queryTerms {
            for textTerm in textTerms {
                if areSemanticallyRelated(queryTerm, textTerm) {
                    matchScore += 1.0
                }
            }
        }

        return matchScore / Float(queryTerms.count)
    }

    /// Extract key terms from text (nouns, verbs, adjectives)
    func extractKeyTerms(_ text: String) -> [String] {
        tagger.string = text
        var terms: [String] = []

        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        let tags: [NLTag] = [.noun, .verb, .adjective]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass,
                            options: options) { tag, range in
            if let tag = tag, tags.contains(tag) {
                let term = String(text[range]).lowercased()
                terms.append(term)
            }
            return true
        }

        return terms
    }

    /// Check if two terms are semantically related
    func areSemanticallyRelated(_ term1: String, _ term2: String) -> Bool {
        // Exact match
        if term1 == term2 {
            return true
        }

        // Get lemmas (base forms)
        let lemma1 = getLemma(term1)
        let lemma2 = getLemma(term2)

        if lemma1 == lemma2 {
            return true
        }

        // Check synonyms
        return areSynonyms(term1, term2)
    }

    /// Get lemma (base form) of a word
    func getLemma(_ word: String) -> String {
        tagger.string = word
        var lemma = word

        tagger.enumerateTags(in: word.startIndex..<word.endIndex,
                            unit: .word,
                            scheme: .lemma,
                            options: []) { tag, _ in
            if let tag = tag {
                lemma = tag.rawValue
            }
            return false
        }

        return lemma.lowercased()
    }

    /// Check if two words are synonyms (simplified)
    func areSynonyms(_ word1: String, _ word2: String) -> Bool {
        // Simplified synonym matching for common music terms
        let synonymGroups: [[String]] = [
            ["happy", "joyful", "glad", "cheerful", "merry"],
            ["sad", "sorrowful", "melancholic", "blue", "down"],
            ["slow", "ballad", "gentle", "soft", "calm"],
            ["fast", "upbeat", "energetic", "lively", "quick"],
            ["worship", "praise", "adoration", "glorify"],
            ["hope", "hopeful", "optimistic", "promising"],
            ["peace", "peaceful", "calm", "serene", "tranquil"],
            ["love", "beloved", "dear", "cherished"],
            ["power", "powerful", "mighty", "strong"],
            ["grace", "gracious", "merciful", "kind"]
        ]

        let w1 = word1.lowercased()
        let w2 = word2.lowercased()

        for group in synonymGroups {
            if group.contains(w1) && group.contains(w2) {
                return true
            }
        }

        return false
    }

    // MARK: - Contextual Understanding

    /// Understand query intent and context
    func analyzeQueryContext(_ query: String) -> [String: Any] {
        var context: [String: Any] = [:]

        // Detect sentiment
        context["sentiment"] = analyzeSentiment(query)

        // Detect moods
        context["moods"] = detectMood(query)

        // Extract key terms
        context["keyTerms"] = extractKeyTerms(query)

        // Detect tempo-related terms
        context["tempo"] = detectTempoIntent(query)

        // Detect key-related terms
        context["key"] = detectKeyIntent(query)

        return context
    }

    /// Detect tempo-related intent in query
    func detectTempoIntent(_ query: String) -> TempoCategory? {
        let lowercased = query.lowercased()

        for category in TempoCategory.allCases {
            for keyword in category.keywords {
                if lowercased.contains(keyword) {
                    return category
                }
            }
        }

        return nil
    }

    /// Detect key-related intent in query
    func detectKeyIntent(_ query: String) -> String? {
        // Match patterns like "in C", "key of G", "C major", etc.
        let keyPattern = #"(?:in|key of|key:)\s*([A-G][#b]?(?:\s*(?:major|minor|m))?)|(^|\s)([A-G][#b]?(?:\s*(?:major|minor|m))?)\s*(?:key|songs)"#

        let regex = try? NSRegularExpression(pattern: keyPattern, options: .caseInsensitive)
        let nsString = query as NSString

        if let match = regex?.firstMatch(in: query, range: NSRange(location: 0, length: nsString.length)) {
            for i in 1..<match.numberOfRanges {
                let range = match.range(at: i)
                if range.location != NSNotFound {
                    let key = nsString.substring(with: range).trimmingCharacters(in: .whitespaces)
                    if !key.isEmpty {
                        return key
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Meaning-Based Search

    /// Search by meaning rather than exact keywords
    func searchByMeaning(_ query: String, in texts: [(id: UUID, text: String)]) -> [(id: UUID, score: Float)] {
        let queryContext = analyzeQueryContext(query)
        var results: [(id: UUID, score: Float)] = []

        for item in texts {
            var score: Float = 0.0

            // Semantic similarity
            score += semanticSimilarity(query, item.text) * 0.4

            // Mood matching
            if let queryMoods = queryContext["moods"] as? [MoodCategory] {
                let textMoods = detectMood(item.text)

                for queryMood in queryMoods {
                    if textMoods.contains(queryMood) {
                        score += 0.3
                    }
                }
            }

            // Sentiment matching
            if let querySentiment = queryContext["sentiment"] as? SearchQuery.Sentiment {
                let textSentiment = analyzeSentiment(item.text)

                if querySentiment == textSentiment {
                    score += 0.2
                }
            }

            // Key term matching
            if let queryTerms = queryContext["keyTerms"] as? [String] {
                let textTerms = extractKeyTerms(item.text)

                for queryTerm in queryTerms {
                    for textTerm in textTerms {
                        if areSemanticallyRelated(queryTerm, textTerm) {
                            score += 0.1
                        }
                    }
                }
            }

            if score > 0.3 {
                results.append((item.id, score))
            }
        }

        return results.sorted { $0.score > $1.score }
    }

    // MARK: - Query Expansion

    /// Expand query with synonyms and related terms
    func expandQuery(_ query: String) -> [String] {
        var expansions = Set<String>()

        // Original query
        expansions.insert(query.lowercased())

        // Extract key terms and add synonyms
        let terms = extractKeyTerms(query)

        for term in terms {
            // Add lemma
            expansions.insert(getLemma(term))

            // Add potential synonyms from our groups
            let synonymGroups: [[String]] = [
                ["happy", "joyful", "glad", "cheerful", "merry"],
                ["sad", "sorrowful", "melancholic"],
                ["slow", "ballad", "gentle"],
                ["fast", "upbeat", "energetic"],
                ["worship", "praise"],
                ["hope", "hopeful"],
                ["peace", "peaceful", "calm"],
                ["love", "beloved"]
            ]

            for group in synonymGroups {
                if group.contains(term.lowercased()) {
                    expansions.formUnion(group)
                }
            }
        }

        return Array(expansions)
    }
}

// MARK: - Helper Functions

/// Create a simple sentiment model (placeholder for actual ML model)
private func createSentimentModel() -> MLModel {
    // In a real implementation, this would load a trained Core ML model
    // For now, we use rule-based sentiment in getSentimentScore()
    fatalError("Sentiment model not implemented - using rule-based approach instead")
}
