//
//  AIEthicsModels.swift
//  Lyra
//
//  Phase 7.15: AI Ethics and Transparency
//  SwiftData models for AI ethics settings and transparency tracking
//

import Foundation
import SwiftData

// MARK: - AI Ethics Settings

/// User's AI ethics preferences
@Model
final class AIEthicsSettings {
    var userID: String
    var ethicsVersion: String
    var onboardingCompleted: Bool
    var lastUpdated: Date

    // Feature toggles
    var songwritingEnabled: Bool
    var practiceRecommendationsEnabled: Bool
    var songRecommendationsEnabled: Bool
    var semanticSearchEnabled: Bool
    var autoFormattingEnabled: Bool
    var contentModerationEnabled: Bool
    var ocrScanningEnabled: Bool
    var chordDetectionEnabled: Bool

    // Granular controls
    var showConfidenceScores: Bool
    var showAIBadges: Bool
    var requireConfirmationForAI: Bool
    var autoApplyAISuggestions: Bool
    var enableAIExplanations: Bool
    var privacyMode: Bool

    // Data control
    var allowDataCollectionForImprovement: Bool
    var allowUsageAnalytics: Bool

    init(userID: String) {
        self.userID = userID
        self.ethicsVersion = "1.0"
        self.onboardingCompleted = false
        self.lastUpdated = Date()

        // Default all features enabled
        self.songwritingEnabled = true
        self.practiceRecommendationsEnabled = true
        self.songRecommendationsEnabled = true
        self.semanticSearchEnabled = true
        self.autoFormattingEnabled = true
        self.contentModerationEnabled = true
        self.ocrScanningEnabled = true
        self.chordDetectionEnabled = true

        // Default granular controls
        self.showConfidenceScores = true
        self.showAIBadges = true
        self.requireConfirmationForAI = false
        self.autoApplyAISuggestions = false
        self.enableAIExplanations = true
        self.privacyMode = false

        // Default data control
        self.allowDataCollectionForImprovement = false
        self.allowUsageAnalytics = false
    }
}

// MARK: - AI Transparency Log

/// Log of AI decisions for transparency
@Model
final class AITransparencyLog {
    var logID: String
    var timestamp: Date
    var suggestionType: String
    var aiSource: String
    var confidence: Double
    var userAccepted: Bool?
    var userModified: Bool?
    var explainationViewed: Bool

    init(
        suggestionType: String,
        aiSource: String,
        confidence: Double
    ) {
        self.logID = UUID().uuidString
        self.timestamp = Date()
        self.suggestionType = suggestionType
        self.aiSource = aiSource
        self.confidence = confidence
        self.userAccepted = nil
        self.userModified = nil
        self.explainationViewed = false
    }

    func recordUserAction(accepted: Bool, modified: Bool) {
        self.userAccepted = accepted
        self.userModified = modified
    }

    func recordExplanationView() {
        self.explainationViewed = true
    }
}

// MARK: - Bias Detection Record

/// Record of bias detection tests
@Model
final class BiasDetectionRecord {
    var recordID: String
    var timestamp: Date
    var testType: String
    var biasScore: Double
    var biasLevel: String
    var overrepresentedCategories: String
    var underrepresentedCategories: String
    var mitigationApplied: Bool
    var notes: String?

    init(
        testType: String,
        biasScore: Double,
        biasLevel: String,
        overrepresented: [String],
        underrepresented: [String],
        mitigationApplied: Bool
    ) {
        self.recordID = UUID().uuidString
        self.timestamp = Date()
        self.testType = testType
        self.biasScore = biasScore
        self.biasLevel = biasLevel
        self.overrepresentedCategories = overrepresented.joined(separator: ", ")
        self.underrepresentedCategories = underrepresented.joined(separator: ", ")
        self.mitigationApplied = mitigationApplied
    }
}

// MARK: - Copyright Check Record

/// Record of copyright checks performed
@Model
final class CopyrightCheckRecord {
    var recordID: String
    var timestamp: Date
    var contentTitle: String
    var contentArtist: String?
    var checkStatus: String
    var violationsFound: Int
    var warningsIssued: Int
    var userEducated: Bool
    var actionTaken: String?

    init(
        contentTitle: String,
        contentArtist: String?,
        checkStatus: String,
        violationsFound: Int,
        warningsIssued: Int
    ) {
        self.recordID = UUID().uuidString
        self.timestamp = Date()
        self.contentTitle = contentTitle
        self.contentArtist = contentArtist
        self.checkStatus = checkStatus
        self.violationsFound = violationsFound
        self.warningsIssued = warningsIssued
        self.userEducated = false
    }

    func recordEducation() {
        self.userEducated = true
    }

    func recordAction(_ action: String) {
        self.actionTaken = action
    }
}

// MARK: - Data Deletion Record

/// Record of user data deletions
@Model
final class DataDeletionRecord {
    var recordID: String
    var timestamp: Date
    var deletionType: String // "partial" or "complete"
    var categoriesDeleted: String
    var confirmationCode: String
    var triggeredBy: String // "user" or "automatic"
    var dataDeleted: Bool

    init(
        deletionType: String,
        categoriesDeleted: [String],
        confirmationCode: String,
        triggeredBy: String
    ) {
        self.recordID = UUID().uuidString
        self.timestamp = Date()
        self.deletionType = deletionType
        self.categoriesDeleted = categoriesDeleted.joined(separator: ", ")
        self.confirmationCode = confirmationCode
        self.triggeredBy = triggeredBy
        self.dataDeleted = true
    }
}

// MARK: - Privacy Audit Record

/// Record of privacy audits and compliance checks
@Model
final class PrivacyAuditRecord {
    var auditID: String
    var timestamp: Date
    var auditType: String
    var compliant: Bool
    var privacyScore: Double
    var issuesFound: String?
    var recommendations: String?

    init(
        auditType: String,
        compliant: Bool,
        privacyScore: Double,
        issuesFound: [String]?,
        recommendations: [String]?
    ) {
        self.auditID = UUID().uuidString
        self.timestamp = Date()
        self.auditType = auditType
        self.compliant = compliant
        self.privacyScore = privacyScore
        self.issuesFound = issuesFound?.joined(separator: "; ")
        self.recommendations = recommendations?.joined(separator: "; ")
    }
}

// MARK: - User Feedback on AI

/// User feedback on AI suggestions
@Model
final class AIFeedbackRecord {
    var feedbackID: String
    var timestamp: Date
    var aiFeature: String
    var suggestionID: String?
    var rating: Int // 1-5 stars
    var helpful: Bool
    var accurate: Bool
    var concerns: String?
    var freeformFeedback: String?

    init(
        aiFeature: String,
        suggestionID: String?,
        rating: Int,
        helpful: Bool,
        accurate: Bool
    ) {
        self.feedbackID = UUID().uuidString
        self.timestamp = Date()
        self.aiFeature = aiFeature
        self.suggestionID = suggestionID
        self.rating = max(1, min(5, rating))
        self.helpful = helpful
        self.accurate = accurate
    }

    func addConcerns(_ concerns: String) {
        self.concerns = concerns
    }

    func addFeedback(_ feedback: String) {
        self.freeformFeedback = feedback
    }
}

// MARK: - Ethics Dashboard Snapshot

/// Snapshot of ethics dashboard for historical tracking
@Model
final class EthicsDashboardSnapshot {
    var snapshotID: String
    var timestamp: Date
    var transparencyScore: Double
    var privacyScore: Double
    var biasScore: Double
    var copyrightCompliance: Double
    var dataMinimizationScore: Double
    var userControlScore: Double
    var overallEthicsScore: Double

    init(dashboard: AIEthicsDashboard) {
        self.snapshotID = UUID().uuidString
        self.timestamp = Date()
        self.transparencyScore = dashboard.transparencyScore
        self.privacyScore = dashboard.privacyScore.score
        self.biasScore = dashboard.biasScore
        self.copyrightCompliance = dashboard.copyrightCompliance
        self.dataMinimizationScore = dashboard.dataMinimization
        self.userControlScore = dashboard.userControlScore
        self.overallEthicsScore = dashboard.overallEthicsScore
    }
}

// MARK: - Manual Override Record (already in UserControlEngine, duplicated for SwiftData)

/// SwiftData version of manual override
@Model
final class ManualOverrideRecord {
    var overrideID: String
    var timestamp: Date
    var feature: String
    var aiSuggestion: String
    var userChoice: String
    var reason: String?
    var confidenceDifference: Double?

    init(
        feature: String,
        aiSuggestion: String,
        userChoice: String,
        reason: String?
    ) {
        self.overrideID = UUID().uuidString
        self.timestamp = Date()
        self.feature = feature
        self.aiSuggestion = aiSuggestion
        self.userChoice = userChoice
        self.reason = reason
    }

    func recordConfidenceDifference(_ difference: Double) {
        self.confidenceDifference = difference
    }
}

// MARK: - Educational Content View

/// Track which educational content users have viewed
@Model
final class EducationalContentView {
    var viewID: String
    var timestamp: Date
    var contentType: String // "copyright", "privacy", "bias", "transparency"
    var contentTitle: String
    var completed: Bool
    var timeSpent: Double? // seconds

    init(
        contentType: String,
        contentTitle: String
    ) {
        self.viewID = UUID().uuidString
        self.timestamp = Date()
        self.contentType = contentType
        self.contentTitle = contentTitle
        self.completed = false
    }

    func markCompleted(timeSpent: Double?) {
        self.completed = true
        self.timeSpent = timeSpent
    }
}
