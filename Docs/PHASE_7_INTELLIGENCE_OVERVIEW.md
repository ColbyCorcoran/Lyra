# Phase 7: On-Device Intelligence System

Comprehensive on-device AI/ML capabilities for professional Music Therapy workflows.

## System Goal

Lyra is a professional Chord Chart app built for Music Therapists, implementing advanced intelligence features entirely on-device to maintain:
- **One-time-fee business model** (no subscription costs)
- **100% offline reliability** (critical for clinical settings)
- **Privacy-first approach** (no external API calls)
- **Professional performance** (low latency, consistent behavior)

## Core Constraint

**EVERY intelligence feature MUST be implemented ON-DEVICE.**

Strictly avoid external API calls (OpenAI, Anthropic, Claude, GPT, etc.) to ensure:
- No ongoing API costs passed to therapists
- No internet dependency in clinical environments
- Complete data privacy for patient session materials
- Predictable performance regardless of network conditions

## Architecture Philosophy

Phase 7 leverages Apple's native frameworks to deliver professional-grade intelligence:
- **Vision** for visual understanding
- **SoundAnalysis** and **Core ML** for audio processing
- **NaturalLanguage** for semantic understanding
- **Swift** for rule-based logical reasoning
- **Create ML** for custom predictive models

All processing happens locally on iPhone/iPad hardware, using optimized neural engines and Apple Silicon acceleration.

---

## Implementation Priorities

### 1. Vision Intelligence

**Goal**: Digitize paper chord charts using optical character recognition.

**Primary Framework**: Vision framework

**Key Components**:

#### Text Recognition
```swift
// Use VNRecognizeTextRequest with accurate recognition
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = ["en-US"]
request.usesLanguageCorrection = true
```

**Features to Implement**:
- **Chord symbol detection**: Identify C, Dm, G7, Cmaj7, etc.
- **Lyric extraction**: Pull complete lyric lines
- **Spatial mapping**: Map chord symbols to their vertical position relative to lyrics using bounding box coordinates
- **Layout preservation**: Maintain verse/chorus structure from original chart
- **Quality validation**: Confidence scoring for recognition accuracy

**Technical Approach**:
1. Capture image via camera or photo library
2. Run `VNRecognizeTextRequest` with `.accurate` level
3. Extract `VNRecognizedTextObservation` results
4. Parse bounding boxes to determine chord-to-lyric alignment
5. Validate chord symbols against known chord vocabulary
6. Present editable preview before saving

**Use Cases**:
- Convert therapist's handwritten charts to digital
- Import published songbooks
- Quick digitization during session prep
- Archive physical chart collections

---

### 2. Audio Intelligence

**Goal**: Real-time chord detection and audio manipulation for practice and performance.

**Primary Frameworks**: SoundAnalysis, AVAudioEngine, Core ML

**Key Components**:

#### Real-Time Chord Detection
```swift
// SoundAnalysis running Core ML model
let request = try SNClassifySoundRequest(mlModel: chordDetectionModel)
let analyzer = SNAudioStreamAnalyzer(format: audioFormat)
try analyzer.add(request, withObserver: observer)
```

**Features to Implement**:
- **Live chord recognition**: Detect chords played on guitar/piano
- **Auto-transcription**: Generate chord chart from audio playback
- **Practice feedback**: Compare played chords to chart
- **Confidence scoring**: Indicate detection certainty

#### Audio Transposition
```swift
// AVAudioUnitTimePitch for pitch-shifting
let timePitch = AVAudioUnitTimePitch()
timePitch.pitch = pitchShiftInCents // +/- 1200 cents (1 octave)
audioEngine.attach(timePitch)
audioEngine.connect(playerNode, to: timePitch, format: format)
audioEngine.connect(timePitch, to: mainMixer, format: format)
```

**Features to Implement**:
- **Backing track transposition**: Shift pitch without changing tempo
- **Real-time preview**: Hear transposition before saving
- **Quality preservation**: Maintain audio fidelity
- **Offline processing**: All done on-device

**Technical Approach**:
1. Train Core ML chord classification model using Create ML
2. Feed live audio input to SoundAnalysis
3. Process classifications in real-time observer
4. For transposition: use AVAudioUnitTimePitch in AVAudioEngine graph
5. Route processed audio to appropriate outputs

**Use Cases**:
- Auto-generate charts from recordings
- Practice with instant feedback
- Transpose backing tracks to client's vocal range
- Verify chart accuracy against recording

---

### 3. Linguistic Intelligence

**Goal**: Natural language search and content assistance using semantic understanding.

**Primary Frameworks**: NaturalLanguage, NLEmbedding

**Key Components**:

#### Semantic Search
```swift
// NLEmbedding for semantic similarity
let embedding = NLEmbedding.wordEmbedding(for: .english)
let similarity = embedding?.distance(between: word1, and: word2)

// Cosine similarity for vector search
func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    let dotProduct = zip(a, b).map(*).reduce(0, +)
    let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
    let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
    return dotProduct / (magnitudeA * magnitudeB)
}
```

**Features to Implement**:
- **Natural language queries**: Search songs by description ("calming morning songs", "energetic group activities")
- **Semantic tagging**: Auto-suggest tags based on lyrics/mood
- **Content discovery**: Find similar songs based on theme/emotion
- **Context-aware suggestions**: Recommend songs for session goals

#### Songwriting Assistance
```swift
// NLTagger for linguistic analysis
let tagger = NLTagger(tagSchemes: [.lexicalClass, .language, .sentiment])
tagger.string = lyrics
tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass) { tag, range in
    // Analyze lyric structure, rhyme patterns, etc.
}
```

**Features to Implement**:
- **Rhyme suggestions**: Help complete lyric lines
- **Syllable counting**: Maintain meter consistency
- **Content moderation**: Flag inappropriate content
- **Language detection**: Support multilingual charts

**Technical Approach**:
1. Generate embeddings for song metadata (title, tags, lyrics)
2. Store embeddings locally in vector database
3. Convert search query to embedding
4. Compute cosine similarity against all songs
5. Return ranked results above similarity threshold
6. Use NLTagger for content analysis and writing assistance

**Use Cases**:
- "Find uplifting songs about friendship"
- "Show me slow, calming pieces in C major"
- Auto-tag songs based on lyric content
- Suggest rhymes when writing custom songs
- Detect and warn about sensitive content

---

### 4. Logical Intelligence (Music Theory)

**Goal**: Rule-based music theory engine for chord validation and transposition.

**Primary Implementation**: Pure Swift (no ML required)

**Key Components**:

#### Theory Engine Architecture
```swift
class MusicTheoryEngine {
    // Chromatic scale mapping
    let chromaticScale = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    // Key signature definitions
    struct KeySignature {
        let root: String
        let scale: [String] // Notes in the key
        let commonChords: [String] // I, ii, iii, IV, V, vi, vii°
    }

    func transposeChord(_ chord: String, by semitones: Int) -> String
    func analyzeKey(from chords: [String]) -> [KeySignature]
    func validateChord(_ chord: String, in key: KeySignature) -> ChordValidation
    func suggestCorrection(for chord: String, in key: KeySignature) -> [String]
}
```

**Features to Implement**:

#### Chord Validation
- **Key detection**: Analyze chord progression to determine likely key
- **Diatonic checking**: Identify non-diatonic chords (colored differently)
- **Theory suggestions**: "This Db might be C# in the key of A"
- **Modal analysis**: Detect modal borrowing and secondary dominants

#### Text-Based Transposition
- **Mathematical mapping**: Transpose chords using chromatic scale math
- **Enharmonic handling**: Choose A# vs Bb based on target key
- **Complex chord preservation**: Maintain extensions (7ths, 9ths, etc.)
- **Nashville number conversion**: Optional I-IV-V-I notation

#### Music Theory Rules
```swift
// Example: Transpose C to E (4 semitones up)
func transposeChord(_ chord: String, by semitones: Int) -> String {
    // 1. Parse chord root (C, D#, Gb, etc.)
    // 2. Find index in chromatic scale
    // 3. Add semitones (modulo 12)
    // 4. Rebuild chord with new root
    // 5. Apply enharmonic rules for target key
    return transposedChord
}

// Example: Detect key from chord progression
func analyzeKey(from chords: [String]) -> [KeySignature] {
    // 1. Score each possible key
    // 2. Award points for diatonic chords
    // 3. Consider cadences (V-I, IV-I)
    // 4. Return ranked key candidates
}
```

**Technical Approach**:
1. Build chromatic scale lookup tables
2. Define all major/minor key signatures
3. Implement chord parsing (root, quality, extensions)
4. Create transposition algorithms using modular arithmetic
5. Develop key detection heuristics
6. Build chord validation rules

**Use Cases**:
- Transpose song from G to C instantly
- Highlight non-key chords in red/orange
- "Did you mean F# instead of Gb here?"
- Convert chart to Nashville numbers for session musicians
- Validate transcribed charts for theory errors

---

### 5. Predictive Intelligence

**Goal**: Custom machine learning models for personalized recommendations and predictions.

**Primary Framework**: Create ML

**Key Components**:

#### Model Training Pipeline
```swift
// Example: Song recommendation model
import CreateML

let trainingData = try MLDataTable(contentsOf: trainingDataURL)
let model = try MLRecommender(
    trainingData: trainingData,
    userColumn: "therapist_id",
    itemColumn: "song_id",
    ratingColumn: "usage_frequency"
)
try model.write(to: modelURL)
```

**Features to Implement**:

#### Session Recommendation Engine
- **Usage patterns**: Learn which songs therapist uses for specific goals
- **Time-based suggestions**: Morning energizers vs evening wind-downs
- **Client preferences**: Track effective songs per client type
- **Sequence prediction**: Suggest next song based on session flow

#### Practice Progress Prediction
- **Tempo trajectory**: Predict optimal practice tempo increases
- **Mastery estimation**: Estimate when song will be performance-ready
- **Difficulty matching**: Recommend songs at appropriate skill level
- **Goal alignment**: Suggest songs matching therapeutic objectives

#### Smart Defaults
- **Auto-settings**: Predict preferred key, tempo, style per song type
- **Layout preferences**: Learn optimal chart formatting choices
- **Hardware presets**: Remember pedal/metronome configs per context

**Model Types**:
1. **Recommender**: Collaborative filtering for song suggestions
2. **Classifier**: Categorize songs (energy level, emotional valence, therapeutic application)
3. **Regressor**: Predict optimal tempo, session duration
4. **Clustering**: Group similar songs for discovery

**Technical Approach**:
1. Collect usage telemetry (locally, never transmitted)
2. Export training data in Create ML compatible format
3. Train models using Create ML app or framework
4. Export `.mlmodel` files
5. Integrate into app using Core ML
6. Update models periodically based on new usage data
7. Maintain model versioning for backwards compatibility

**Use Cases**:
- "Based on your morning sessions, try these 5 songs"
- "Clients respond well to these in anxiety reduction"
- Auto-populate setlist for specific therapeutic goal
- Predict when client will master current practice piece
- Suggest optimal practice routine based on progress

---

## Data Privacy & Ethics

### Local-First Principle
All intelligence features process data exclusively on-device:
- **No cloud uploads**: Patient lyrics, recordings, session notes stay local
- **No analytics transmission**: Usage patterns remain private
- **No model updates via internet**: Models ship with app updates
- **No account requirement**: Full functionality without sign-in

### Transparency
- **Confidence scores**: Always show AI certainty levels
- **Manual override**: User can correct all AI suggestions
- **Explainability**: Show why recommendations were made
- **Opt-out options**: All intelligence features can be disabled

### Clinical Responsibility
- **Human verification**: AI assists, therapist validates
- **Error handling**: Graceful fallbacks when detection fails
- **No medical claims**: Tool supports workflow, doesn't diagnose
- **Accessibility**: Intelligence features work with VoiceOver/accessibility modes

---

## Performance Targets

### Real-Time Features
- **Audio analysis**: < 100ms latency for chord detection
- **Text recognition**: < 2 seconds for typical chart page
- **Semantic search**: < 500ms for 1000+ song library
- **Transposition**: Instant for text, < 5 seconds for audio file

### Battery & Thermal
- **Background limits**: Intelligent features pause in low power mode
- **Thermal throttling**: Reduce analysis frequency if overheating
- **Neural Engine priority**: Use ANE over GPU/CPU when available
- **Batch processing**: Group tasks to minimize wake cycles

### Model Size Constraints
- **Per-model limit**: < 50MB compressed
- **Total ML budget**: < 200MB for all intelligence features
- **Download impact**: Consider app size for initial install
- **On-demand loading**: Load models only when feature activated

---

## Development Roadmap

### Phase 7.1: Vision Intelligence
- [ ] OCR chord chart scanning
- [ ] Bounding box chord-to-lyric mapping
- [ ] Editable recognition preview
- [ ] Confidence-based validation

### Phase 7.2: Audio Intelligence
- [ ] Core ML chord detection model training
- [ ] Real-time audio analysis integration
- [ ] AVAudioUnitTimePitch transposition
- [ ] Practice feedback system

### Phase 7.3: Linguistic Intelligence
- [ ] NLEmbedding semantic search
- [ ] Vector similarity engine
- [ ] NLTagger content analysis
- [ ] Songwriting assistance tools

### Phase 7.4: Logical Intelligence
- [ ] Music theory engine foundation
- [ ] Chord transposition algorithm
- [ ] Key detection heuristics
- [ ] Validation & correction system

### Phase 7.5: Recommendation Intelligence ✅
- [x] Song analysis engine
- [x] Similarity detection
- [x] Smart playlists
- [x] Discovery features
- [x] Personalization engine
- [x] Context-aware recommendations
- [x] Recommendation feedback system

### Phase 7.6: Integration & Polish
- [ ] Cross-feature workflows (e.g., scan → auto-transpose → practice)
- [ ] Performance optimization
- [ ] Accessibility integration
- [ ] User testing with therapists

---

## Technical Dependencies

### iOS Frameworks Required
```swift
import Vision              // OCR, image analysis
import SoundAnalysis       // Audio classification
import AVFoundation        // Audio processing, time-pitch
import NaturalLanguage     // Semantic search, NLP
import CoreML              // Model inference
import CreateML            // Model training (macOS only)
```

### Minimum OS Versions
- **Vision accurate OCR**: iOS 15.0+
- **SoundAnalysis**: iOS 15.0+
- **NLEmbedding**: iOS 14.0+
- **AVAudioUnitTimePitch**: iOS 8.0+ (already supported)
- **Core ML 5**: iOS 15.0+ (for newer model features)

### Hardware Considerations
- **Neural Engine**: iPhone 8 and later (A11+)
- **Performance targets**: Test on iPhone SE 2nd gen (A13) as baseline
- **iPad optimization**: Leverage larger screen for recognition preview

---

## Testing Strategy

### Unit Tests
- Theory engine: All transposition/key detection algorithms
- Chord parsing: Handle edge cases (C#m7b5, Bb/D, etc.)
- Similarity scoring: Validate cosine similarity calculations

### Integration Tests
- End-to-end OCR: Image → recognized chart → saved song
- Audio pipeline: Microphone → analysis → chord display
- Search accuracy: Natural queries → relevant results

### User Acceptance Testing
- Music therapist beta group
- Real clinical environment testing
- Offline mode verification
- Performance on older devices

### Accessibility Testing
- VoiceOver compatibility for all AI features
- Voice Control for OCR review/editing
- High contrast modes for confidence indicators

---

## Success Metrics

### Accuracy
- **OCR**: > 95% chord symbol accuracy
- **Audio detection**: > 90% correct chord in clean recordings
- **Key detection**: > 85% correct key identification
- **Semantic search**: > 80% user satisfaction (relevant results)

### Performance
- **Scan time**: < 5 seconds typical chart
- **Search latency**: < 500ms
- **Battery impact**: < 5% additional drain during active use

### Adoption
- **Feature discoverability**: > 60% of users try at least one AI feature
- **Regular usage**: > 30% use AI features weekly
- **Satisfaction**: > 4.5/5 rating from therapists

---

## Known Limitations

### Vision Intelligence
- Handwriting recognition accuracy varies by legibility
- Complex layouts (multi-column charts) may need manual adjustment
- Requires decent lighting for camera scanning

### Audio Intelligence
- Background noise impacts chord detection accuracy
- Works best with clear, isolated instrument recordings
- Complex polyphonic music may confuse classifier

### Linguistic Intelligence
- English-first (other languages via NLLanguage support)
- Slang and made-up words may not embed well
- Limited context window for long lyrics

### Logical Intelligence
- Cannot understand context/intent (purely rule-based)
- Unusual chord progressions may confuse key detection
- Jazz reharmonization not supported

### Predictive Intelligence
- Requires usage data (cold start for new users)
- Models can't explain "why" like humans
- May reinforce existing biases in song selection

---

## Future Enhancements (Post-Phase 7)

### Advanced Audio
- Multi-instrument separation (drums, bass, melody)
- Audio fingerprinting for song identification
- Beat detection for auto-tempo setting

### Enhanced Vision
- Tablature recognition (guitar tabs)
- Musical notation OCR (sheet music)
- Handwriting style adaptation (personalized training)

### Deeper Linguistic
- Sentiment analysis for lyric mood detection
- Multilingual support (Spanish, French, etc.)
- Rhyme scheme visualization

### Collaborative Intelligence
- Federated learning (improve models without sharing data)
- Anonymous trend aggregation (popular songs/keys)
- Community-contributed chord corrections

### Integration
- Siri Shortcuts for voice-activated intelligence
- Share extension for scanning from Photos
- Background audio analysis for practice tracking

---

## Resources & References

### Apple Documentation
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [Sound Analysis](https://developer.apple.com/documentation/soundanalysis)
- [Natural Language](https://developer.apple.com/documentation/naturallanguage)
- [Core ML](https://developer.apple.com/documentation/coreml)
- [Create ML](https://developer.apple.com/documentation/createml)

### WWDC Sessions
- WWDC 2021: Extract document data using Vision
- WWDC 2022: Explore the Speech Recognition API
- WWDC 2021: Build dynamic iOS apps with the Create ML framework
- WWDC 2020: Get to know the TrueDepth camera
- WWDC 2019: Understanding Images in Vision framework

### Music Theory Resources
- Chord progression databases for key detection training
- Chromatic scale mathematical relationships
- Nashville number system standards
- Jazz chord notation conventions

---

## Questions & Design Decisions

### Open Design Questions
1. **OCR Editing UI**: Inline editing vs separate review screen?
2. **Confidence Thresholds**: What % certainty before auto-accepting?
3. **Model Updates**: Ship new models via app updates or separate downloads?
4. **Search Defaults**: Should semantic search be default or opt-in?
5. **Practice Analytics**: How much usage tracking for predictions?

### Architectural Decisions
1. **Why no cloud ML?**: Maintains one-time-fee model, ensures privacy
2. **Why Vision over third-party OCR?**: Native integration, no dependencies, optimized for Apple Silicon
3. **Why Create ML over TensorFlow?**: Simpler pipeline, automatic optimization for Core ML, native tooling
4. **Why rule-based theory over ML?**: Music theory is deterministic, rules are 100% accurate and explainable

### Trade-offs
- **Accuracy vs Speed**: Prioritize accuracy (therapists prefer correct over fast)
- **Features vs App Size**: Limit to most impactful ML models
- **Automation vs Control**: Always allow manual override
- **Privacy vs Personalization**: Local-only means no cross-device sync

---

## Support & Maintenance

### Documentation
- User-facing: Help articles for each intelligence feature
- Developer: Technical guides for model training/integration
- Troubleshooting: Common issues and solutions

### Error Handling
- Graceful degradation when models fail to load
- Clear user messaging for low-confidence results
- Fallback to manual input when automation fails

### Updates
- Regular model retraining based on user feedback
- iOS version compatibility for new framework features
- Performance optimization as devices improve

---

## Conclusion

Phase 7 transforms Lyra from a digital chord chart tool into an intelligent music therapy assistant, all while maintaining complete offline functionality and user privacy. By leveraging Apple's on-device ML frameworks, we deliver professional-grade AI features without compromising our one-time-fee business model or requiring internet connectivity in clinical settings.

Every intelligence feature serves a real therapeutic workflow: scanning charts saves prep time, audio detection aids practice, semantic search finds the right song for the moment, theory validation prevents errors, and predictive recommendations learn from experience. Together, these capabilities empower music therapists to focus on their clients rather than administrative tasks.

**Remember**: Intelligence assists, therapists decide. AI confidence scores, manual overrides, and transparency ensure human expertise remains central to every therapeutic decision.
