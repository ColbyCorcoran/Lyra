//
//  ChordDetectionEngine.swift
//  Lyra
//
//  Main engine for AI-powered chord detection from audio files
//  Part of Phase 7: Audio Intelligence
//

import Foundation
import AVFoundation
import Observation

@Observable
class ChordDetectionEngine {

    // MARK: - Properties

    static let shared = ChordDetectionEngine()

    private(set) var currentSession: ChordDetectionSession?
    private(set) var isAnalyzing: Bool = false

    private var audioAnalyzer: AudioAnalyzer?
    private var tempoDetector: TempoDetector?
    private var sectionDetector: SectionDetector?
    private var theoryEngine: MusicTheoryEngine?

    // Background processing
    private var analysisTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        // Lazy initialization of components
    }

    // MARK: - Public API

    /// Start chord detection from an audio file
    func detectChords(
        from url: URL,
        quality: DetectionQuality = .balanced,
        progressCallback: @escaping (Float, DetectionStatus) -> Void
    ) async throws -> ChordDetectionSession {
        // Cancel any existing analysis
        analysisTask?.cancel()

        // Create new session
        let fileName = url.lastPathComponent
        var session = ChordDetectionSession(
            audioFileURL: url,
            audioFileName: fileName,
            quality: quality,
            status: .analyzing
        )

        currentSession = session
        isAnalyzing = true

        // Notify start
        NotificationCenter.default.post(
            name: .chordDetectionStarted,
            object: self,
            userInfo: ["session": session]
        )

        // Start analysis task
        analysisTask = Task {
            let startTime = Date()

            do {
                // Initialize components
                initializeComponents(quality: quality)

                // Step 1: Analyze audio file
                session.status = .detectingChords
                progressCallback(0.1, .detectingChords)

                let analysisResults = try await analyzeAudio(url: url, quality: quality) { progress in
                    progressCallback(0.1 + (progress * 0.5), .detectingChords)
                }

                // Step 2: Detect chords from analysis results
                session.detectedChords = detectChordsFromAnalysis(analysisResults)
                progressCallback(0.6, .detectingChords)

                // Step 3: Detect tempo
                session.status = .detectingTempo
                progressCallback(0.7, .detectingTempo)

                if let tempoResult = try await tempoDetector?.detectTempo(from: url) {
                    session.tempo = tempoResult.bpm
                    session.timeSignature = tempoResult.timeSignature
                }
                progressCallback(0.8, .detectingTempo)

                // Step 4: Detect key
                session.status = .detectingKey
                progressCallback(0.85, .detectingKey)

                if let keyResult = detectKey(from: session.detectedChords) {
                    session.detectedKey = keyResult.fullKeyName
                    session.suggestedCapo = suggestCapo(for: keyResult)
                }
                progressCallback(0.9, .detectingKey)

                // Step 5: Detect sections
                session.status = .detectingSections
                progressCallback(0.95, .detectingSections)

                session.sections = detectSections(from: session.detectedChords)

                // Complete
                session.status = .completed
                session.progress = 1.0
                session.processingTime = Date().timeIntervalSince(startTime)

                currentSession = session
                isAnalyzing = false

                progressCallback(1.0, .completed)

                // Notify completion
                NotificationCenter.default.post(
                    name: .chordDetectionCompleted,
                    object: self,
                    userInfo: ["session": session]
                )

                return session

            } catch {
                session.status = .failed
                session.progress = 0
                currentSession = session
                isAnalyzing = false

                // Notify failure
                NotificationCenter.default.post(
                    name: .chordDetectionFailed,
                    object: self,
                    userInfo: ["error": error]
                )

                throw error
            }
        }

        return try await analysisTask!.value
    }

    /// Cancel ongoing analysis
    func cancelAnalysis() {
        analysisTask?.cancel()
        isAnalyzing = false

        if var session = currentSession {
            session.status = .cancelled
            currentSession = session
        }
    }

    /// Correct a detected chord manually
    func correctChord(at index: Int, newChord: String) {
        guard var session = currentSession else { return }
        guard index < session.detectedChords.count else { return }

        session.detectedChords[index].chord = newChord
        session.detectedChords[index].isUserCorrected = true
        currentSession = session

        NotificationCenter.default.post(
            name: .chordCorrected,
            object: self,
            userInfo: ["index": index, "chord": newChord]
        )
    }

    /// Update section label
    func updateSection(at index: Int, type: SectionType) {
        guard var session = currentSession else { return }
        guard index < session.sections.count else { return }

        session.sections[index].type = type
        session.sections[index].isUserLabeled = true
        currentSession = session
    }

    /// Export detected chords as ChordPro format
    func exportToChordPro() -> String? {
        guard let session = currentSession else { return nil }

        var chordPro = ""

        // Add metadata
        if let key = session.detectedKey {
            chordPro += "{key: \(key)}\n"
        }
        if let tempo = session.tempo {
            chordPro += "{tempo: \(Int(tempo))}\n"
        }
        if let capo = session.suggestedCapo, capo > 0 {
            chordPro += "{capo: \(capo)}\n"
        }
        if let timeSignature = session.timeSignature {
            chordPro += "{time: \(timeSignature)}\n"
        }

        chordPro += "\n"

        // Group chords by sections
        if session.sections.isEmpty {
            // No sections detected, output all chords
            chordPro += "{start_of_verse}\n"
            for chord in session.detectedChords {
                chordPro += "[\(chord.chord)] "
            }
            chordPro += "\n{end_of_verse}\n"
        } else {
            // Output chords by section
            for section in session.sections {
                let sectionName = section.type.chordProDirective
                chordPro += "{start_of_\(sectionName)}\n"

                // Find chords in this section
                let sectionChords = session.detectedChords.filter {
                    $0.position >= section.startPosition && $0.position < section.endPosition
                }

                for chord in sectionChords {
                    chordPro += "[\(chord.chord)] "
                }

                chordPro += "\n{end_of_\(sectionName)}\n\n"
            }
        }

        return chordPro
    }

    // MARK: - Private Methods

    private func initializeComponents(quality: DetectionQuality) {
        audioAnalyzer = AudioAnalyzer(fftSize: quality.fftSize)
        tempoDetector = TempoDetector()
        sectionDetector = SectionDetector()
        theoryEngine = MusicTheoryEngine()
    }

    private func analyzeAudio(
        url: URL,
        quality: DetectionQuality,
        progressCallback: @escaping (Float) -> Void
    ) async throws -> [AudioAnalysisResult] {
        guard let analyzer = audioAnalyzer else {
            throw ChordDetectionError.analyzerNotInitialized
        }

        return try await analyzer.analyzeAudioFile(
            url: url,
            windowDuration: quality.analysisWindow,
            progressCallback: progressCallback
        )
    }

    private func detectChordsFromAnalysis(_ results: [AudioAnalysisResult]) -> [DetectedChord] {
        guard let analyzer = audioAnalyzer else { return [] }

        var detectedChords: [DetectedChord] = []
        var currentChord: DetectedChord?

        for result in results {
            // Detect chords from notes
            let chordCandidates = analyzer.detectChordsFromNotes(result.notes)

            guard let topChord = chordCandidates.first else { continue }

            // Check if this is a new chord or continuation of current
            if let current = currentChord {
                if current.chord == topChord.chord {
                    // Same chord, extend duration
                    currentChord?.duration += result.timestamp - current.position
                } else {
                    // New chord, save previous
                    detectedChords.append(current)
                    currentChord = DetectedChord(
                        chord: topChord.chord,
                        position: result.timestamp,
                        duration: 0,
                        confidence: topChord.confidence,
                        alternativeChords: chordCandidates.dropFirst().prefix(3).map {
                            AlternativeChord(chord: $0.chord, confidence: $0.confidence)
                        },
                        notes: result.notes.map { $0.note }
                    )
                }
            } else {
                // First chord
                currentChord = DetectedChord(
                    chord: topChord.chord,
                    position: result.timestamp,
                    duration: 0,
                    confidence: topChord.confidence,
                    alternativeChords: chordCandidates.dropFirst().prefix(3).map {
                        AlternativeChord(chord: $0.chord, confidence: $0.confidence)
                    },
                    notes: result.notes.map { $0.note }
                )
            }
        }

        // Add final chord
        if let current = currentChord {
            detectedChords.append(current)
        }

        // Filter out very short chords (likely noise)
        return detectedChords.filter { $0.duration > 0.5 }
    }

    private func detectKey(from chords: [DetectedChord]) -> SimpleKeyDetectionResult? {
        guard !chords.isEmpty else { return nil }
        guard let engine = theoryEngine else { return nil }

        let chordNames = chords.map { $0.chord }
        return engine.detectKey(from: chordNames)
    }

    private func suggestCapo(for keyResult: SimpleKeyDetectionResult) -> Int {
        guard let engine = theoryEngine else { return 0 }
        return engine.suggestCapoPosition(for: keyResult.key)
    }

    private func detectSections(from chords: [DetectedChord]) -> [DetectedSection] {
        guard let detector = sectionDetector else { return [] }
        return detector.detectSections(from: chords)
    }
}

// MARK: - Errors

enum ChordDetectionError: LocalizedError {
    case analyzerNotInitialized
    case invalidAudioFile
    case analysisCancelled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .analyzerNotInitialized:
            return "Audio analyzer not initialized"
        case .invalidAudioFile:
            return "Invalid audio file format"
        case .analysisCancelled:
            return "Analysis was cancelled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
