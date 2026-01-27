# Phase 7.14: AI Songwriting Assistance

**Status:** ✅ Implemented
**Version:** 1.0
**Last Updated:** 2026-01-27

---

## Overview

Phase 7.14 implements comprehensive AI-powered songwriting assistance for Lyra, transforming it from a chord chart viewer into a creative songwriting partner. All intelligence features run 100% on-device using Apple's native frameworks and rule-based music theory—no external API calls, no subscriptions, complete privacy.

## Architecture

### 8 Specialized Engines

#### 1. ChordProgressionEngine (`ChordProgressionEngine.swift`)
- **Purpose**: Generate chord progressions and suggest chord continuations
- **Technology**: Rule-based music theory (Swift)
- **Features**:
  - Generate progressions in any key (major/minor)
  - Genre-specific patterns (pop, rock, jazz, folk, country, blues, worship)
  - Suggest next chord with music theory reasoning
  - Create variations (passing chords, substitutions, modal interchange)
  - Explain chord functions (tonic, dominant, subdominant)

#### 2. LyricSuggestionEngine (`LyricSuggestionEngine.swift`)
- **Purpose**: Assist with lyric writing through rhyme and word suggestions
- **Technology**: Apple's NaturalLanguage framework, word embeddings
- **Features**:
  - Rhyme suggestions (perfect, near, slant rhymes)
  - Word alternatives with semantic similarity
  - Theme-based phrase generation
  - Phrase completion
  - Syllable counting for meter consistency
  - Sentiment analysis

#### 3. MelodyHintEngine (`MelodyHintEngine.swift`)
- **Purpose**: Generate melodic patterns based on chords and scales
- **Technology**: Rule-based music theory, MIDI note generation
- **Features**:
  - Generate singable melodies in multiple styles
  - Stepwise, arpeggiated, pentatonic, and mixed patterns
  - Melody continuation (answering phrases)
  - Hook generation (catchy, repetitive patterns)
  - Singability scoring
  - Contour analysis (ascending/descending/wave)
  - Vocal range recommendations

#### 4. SongStructureEngine (`SongStructureEngine.swift`)
- **Purpose**: Suggest song structures and section arrangements
- **Technology**: Rule-based composition patterns
- **Features**:
  - Genre-specific structure templates
  - Custom structure builder
  - Section length recommendations
  - Dynamic arc suggestions (soft/medium/loud)
  - Structure analysis with strengths/weaknesses
  - Arrangement variations (add pre-chorus, double chorus, instrumental breaks)

#### 5. CollaborationEngine (`CollaborationEngine.swift`)
- **Purpose**: Enable iterative co-writing with AI
- **Technology**: Version control, A/B comparison
- **Features**:
  - Start collaborative writing sessions
  - Suggest refinements (chords, lyrics, melody, structure)
  - Create variations (subtle, moderate, dramatic)
  - A/B comparison with scoring
  - Version history tracking
  - User feedback recording for learning

#### 6. StyleTransferEngine (`StyleTransferEngine.swift`)
- **Purpose**: Transform songs between genres and styles
- **Technology**: Rule-based genre profiles and transformations
- **Features**:
  - Genre transformation with intensity control
  - Reharmonization (jazz substitutions, modal interchange, secondary dominants)
  - Style mimicry ("in the style of...")
  - Arrangement suggestions
  - Chord complexity adjustment
  - Tempo and rhythm feel recommendations

#### 7. LearningEngine (`LearningEngine.swift`)
- **Purpose**: Learn user's writing style and provide personalized suggestions
- **Technology**: On-device pattern recognition and preference tracking
- **Features**:
  - Track preferred genres, keys, tempos, chord progressions
  - Analyze writing style (complexity, patterns, strengths)
  - Personalized suggestions based on history
  - Progress metrics (diversity score, improvement areas)
  - Feedback learning (adjust weights based on acceptance)

#### 8. SongwritingAssistantManager (`SongwritingAssistantManager.swift`)
- **Purpose**: Orchestrate all 8 engines into cohesive workflows
- **Technology**: Central coordination layer
- **Features**:
  - Generate complete song starters
  - Provide contextual assistance
  - Coordinate multi-engine workflows
  - Feature help and documentation
  - Quick actions and shortcuts

---

## Key Features Implemented

### 1. Chord Progression Generator ✅

**Generate Progressions:**
```swift
let progression = ChordProgressionEngine.shared.generateProgression(
    in: "C",
    style: "pop",
    length: 4,
    isMinor: false
)
// Returns: C - Am - F - G with roman numerals and explanations
```

**Common Patterns:**
- Pop: I-vi-IV-V, vi-IV-I-V, I-V-vi-IV
- Rock: I-IV-V-I, I-bVII-IV-V
- Jazz: I-vi-ii-V, ii-V-I
- Folk: I-I-V-V, I-IV-I-V
- Blues: 12-bar blues progression

**Suggest Next Chord:**
```swift
let suggestions = ChordProgressionEngine.shared.suggestNextChord(
    after: ["C", "Am", "F"],
    in: "C",
    count: 3
)
// Returns suggestions with probability and music theory reasoning
```

**Create Variations:**
- Substitute relative chords (ii ↔ IV)
- Add passing chords
- Modal interchange (borrow from parallel key)

### 2. Chord Continuation ✅

**Features:**
- Analyze current progression to predict next chord
- Provide multiple options with probabilities
- Explain reasoning using music theory
- Include basic voicings for implementation

**Theory Reasoning:**
- I → IV: "Strong subdominant movement"
- I → V: "Dominant preparation"
- ii → V: "Classic ii-V progression"
- V → I: "Authentic cadence"
- V → vi: "Deceptive cadence"

### 3. Lyric Suggestions ✅

**Rhyme Suggestions:**
```swift
let rhymes = LyricSuggestionEngine.shared.suggestRhymes(
    for: "love",
    count: 10
)
// Returns: above, dove, shove with rhyme type and syllable count
```

**Word Alternatives:**
```swift
let alternatives = LyricSuggestionEngine.shared.suggestAlternatives(
    for: "happy",
    count: 8
)
// Returns: joyful, cheerful, delighted with semantic similarity scores
```

**Complete Phrases:**
```swift
let phrases = LyricSuggestionEngine.shared.completePhrase(
    "Love will always",
    theme: "hope",
    count: 5
)
// Returns: "Love will always remain", "Love will always shine", etc.
```

**Theme-Based:**
- Love: heart, passion, devotion, romance
- Hope: light, tomorrow, dream, faith
- Loss: memory, shadow, echo, absence
- Joy: laughter, sunshine, dancing

### 4. Melody Hints ✅

**Suggest Melodic Patterns:**
```swift
let melody = MelodyHintEngine.shared.suggestMelody(
    for: "C",
    in: "C",
    style: .stepwise,
    length: 8
)
// Returns: note names, MIDI notes, singability score, contour
```

**Melody Styles:**
- Stepwise: Smooth, singable motion
- Arpeggio: Chord tone-based
- Pentatonic: Safe, universally pleasing
- Mixed: Combination approach
- Hook: Catchy, repetitive patterns

**Singability Scoring:**
- Penalizes large leaps (> 5 semitones)
- Rewards stepwise motion
- Checks vocal range (< 12 semitones ideal)
- Scores 0.0 to 1.0

**Continue Melody:**
```swift
let continuation = MelodyHintEngine.shared.continuemelody(
    from: ["C4", "D4", "E4", "D4"],
    in: "C",
    currentChord: "F"
)
// Returns answering phrase with opposite contour
```

### 5. Song Structure ✅

**Suggest Structure:**
```swift
let structure = SongStructureEngine.shared.suggestStructure(
    for: "pop",
    targetLength: 64,
    mood: "balanced"
)
// Returns: Intro-Verse-Chorus-Verse-Chorus-Bridge-Chorus-Outro
```

**Structure Templates:**
- Pop: Verse-Chorus, ABABCB
- Rock: Verse-Chorus-Solo
- Folk: Simple Verse
- Worship: Verse-Chorus-Bridge with repeated choruses
- Blues: 12-Bar Blues

**Section Length Recommendations:**
- Intro: 4-16 bars (typical: 8)
- Verse: 8-32 bars (typical: 16)
- Chorus: 8-24 bars (typical: 16)
- Bridge: 8-16 bars (typical: 8)
- Solo: 16-32 bars (typical: 16)

**Dynamic Arc:**
- Intro: Soft
- Verse 1: Soft
- Chorus 1: Medium/Loud
- Verse 2: Medium
- Chorus 2: Loud
- Bridge: Soft/Medium
- Final Chorus: Loud
- Outro: Soft

### 6. Collaboration Mode ✅

**Start Co-Writing Session:**
```swift
let session = CollaborationEngine.shared.startSession(
    songID: songID,
    initialContent: "I have this chord progression: C-Am-F-G",
    goal: "Write an uplifting pop song"
)
```

**Suggest Refinements:**
```swift
let refinement = CollaborationEngine.shared.suggestRefinement(
    for: currentContent,
    aspect: .chordProgression,
    context: "Make it more interesting"
)
// Returns suggestions with reasoning
```

**Create Variations:**
- Subtle: Minor word changes, slight adjustments
- Moderate: Chord substitutions, lyric rewrites
- Dramatic: Key changes, major structural changes

**A/B Testing:**
```swift
let comparison = CollaborationEngine.shared.compareVersions(
    versionA: "C-Am-F-G",
    versionB: "C-Em-F-G",
    criteria: [.memorability, .emotionalImpact, .technicalQuality]
)
// Returns scored comparison with winner and recommendations
```

### 7. Style Transfer ✅

**Transform to Genre:**
```swift
let transform = StyleTransferEngine.shared.transformToGenre(
    currentChords: ["C", "Am", "F", "G"],
    currentKey: "C",
    targetGenre: "jazz",
    intensity: .moderate
)
// Returns: Reharmonized chords, tempo, rhythm feel, arrangement ideas
```

**Genre Profiles:**
- Pop: 120 BPM, simple chords, straight rhythm
- Rock: 130 BPM, moderate complexity, driving rhythm
- Jazz: 100 BPM, complex chords, swing feel
- Folk: 90 BPM, simple chords, relaxed rhythm
- Country: 110 BPM, simple chords, shuffle feel
- Worship: 75 BPM, moderate complexity, flowing rhythm
- Blues: 80 BPM, moderate complexity, shuffle feel

**Reharmonization Approaches:**
- Jazz Substitutions: Add 7ths, 9ths, 13ths
- Modal Interchange: Borrow from parallel minor/major
- Secondary Dominants: V/V, V/vi, V/IV
- Tritone Substitution: Replace V7 with bII7

**Style Transfer Examples:**
- "Make this sound like jazz" → Add 7ths, swing feel, complex harmony
- "In the style of folk" → Simplify chords, acoustic feel, storytelling
- "Worship arrangement" → Build dynamics, anthemic chorus, layered sound

### 8. Learning ✅

**Learn User Style:**
```swift
LearningEngine.shared.learnFromSong(
    chords: ["C", "Am", "F", "G"],
    key: "C",
    tempo: 120,
    genre: "pop",
    structure: ["Verse", "Chorus", "Verse", "Chorus"]
)
```

**Analyze Writing Style:**
```swift
let analysis = LearningEngine.shared.analyzeWritingStyle()
// Returns: dominant genre, chord complexity, favorite progressions,
//          tempo range, strengths, improvement suggestions
```

**Personalized Suggestions:**
- Chord suggestions based on user's most-used chords
- Key suggestions from favorite keys
- Tempo suggestions from typical range
- Genre suggestions from preference history

**Progress Tracking:**
```swift
let progress = LearningEngine.shared.getProgressMetrics()
// Returns: total songs, unique keys/genres/chords, diversity score,
//          songs this month, improvement areas
```

**Improvement Suggestions:**
- Harmony: "Expand chord vocabulary - try 7th chords"
- Melody: "Practice creating memorable 3-4 note motifs"
- Lyrics: "Experiment with different rhyme schemes"
- Structure: "Try bridges and pre-choruses for variety"

---

## Data Models

### SwiftData Models

All models in `Lyra/Models/SongwritingModels.swift`:

**SongwritingSession** - Track writing sessions
- sessionID, songID, goal, genre
- startedAt, endedAt, duration
- acceptedSuggestions, rejectedSuggestions, acceptanceRate

**SavedProgression** - Store favorite progressions
- name, chords, key, genre, isMinor
- usageCount, rating, createdAt

**SuggestionFeedback** - Learn from user feedback
- sessionID, suggestionType, suggestionContent
- accepted, rating, userNotes, timestamp

**WritingPatternRecord** - Track writing patterns
- userID, chords, key, tempo, genre, structure
- usageCount, lastUsed, isRecent

**SavedSongStarter** - Store generated starters
- name, genre, key, tempo, mood, theme
- chordProgressionData, structureData
- createdAt, lastModified

**CollaborationHistory** - Version control
- sessionID, versionNumber, content, changes
- aiContributed, timestamp

**SongwritingPreferences** - User preferences
- userID, preferredGenres, favoriteKeys, typicalTempo
- enabledFeatures, assistantMode, lastUpdated

**SavedStyleTransform** - Store transformations
- name, originalChords, transformedChords
- sourceGenre, targetGenre, intensity, rating

### Codable Structs

**GeneratedProgression** - Chord progression result
**ChordSuggestion** - Next chord suggestion
**RhymeSuggestion** - Rhyming word
**PhraseSuggestion** - Completed phrase
**WordAlternative** - Synonym option
**ThemePhrase** - Theme-based lyric
**MelodyHint** - Melodic pattern
**SongStructureTemplate** - Structure template
**StyleTransform** - Genre transformation
**WritingProgress** - Progress metrics

---

## User Interface

### Main Views

**SongwritingAssistantView** (`SongwritingAssistantView.swift`)
- Tab-based navigation
- Status bar with enable/disable toggle
- Help system

### Tabs

1. **Home Tab**
   - Quick Start generator
   - Genre, key, mood, theme selectors
   - Generate song starter button
   - Quick features grid

2. **Chord Progression Tab**
   - Key and genre selectors
   - Generate progression button
   - Display progressions with roman numerals
   - Chord function explanations

3. **Lyrics Tab**
   - Rhyme finder
   - Word alternative suggestions
   - Theme-based phrase generator
   - Phrase completion

4. **Melody Tab**
   - Chord and key selectors
   - Generate melody button
   - Display melody notes
   - Singability score

5. **Structure Tab**
   - Genre selector
   - Suggest structure button
   - Display structure template
   - Section lengths and dynamics

6. **Collaboration Tab**
   - Start co-writing session
   - Refinement suggestions
   - Version comparison
   - History tracking

### UI Components

**GeneratedStarterView** - Display complete song starter
**ProgressionView** - Show chord progression
**MelodyHintView** - Display melody pattern
**StructureTemplateView** - Show song structure
**FeatureCard** - Quick feature access
**HelpView** - Feature documentation

---

## API Usage Examples

### Generate Complete Song Starter

```swift
let starter = SongwritingAssistantManager.shared.generateSongStarter(
    genre: "pop",
    key: "C",
    mood: "happy",
    theme: "love"
)

print("Chords: \(starter.chordProgression.chords)")
print("Structure: \(starter.structure.sections)")
print("Tempo: \(starter.tempo) BPM")
print("Lyric ideas: \(starter.lyricIdeas)")
```

### Get Contextual Assistance

```swift
let assistance = SongwritingAssistantManager.shared.getContextualAssistance(
    currentChords: ["C", "Am", "F"],
    currentLyrics: "I feel the love",
    key: "C",
    genre: "pop"
)

print("Suggestions: \(assistance.suggestions)")
print("Quick actions: \(assistance.quickActions)")
```

### Complete Songwriting Session

```swift
let result = await SongwritingAssistantManager.shared.assistWithCompleteSong(
    initialIdea: "I want to write about hope",
    genre: "worship",
    goal: "Inspiring and uplifting"
)

print("Chord progression: \(result.chordProgression)")
print("Structure: \(result.structure)")
print("Arrangement ideas: \(result.arrangementIdeas)")
```

---

## Integration Points

Phase 7.14 integrates with:

- **Song.swift** - Embed AI suggestions into songs
- **MusicTheoryEngine** - Leverage existing transposition
- **ChordDatabase** - Use existing chord definitions
- **NaturalLanguageParser** - Share NL processing
- **PerformanceManager** - Performance-aware suggestions

---

## Performance Targets

- **Chord generation**: < 50ms
- **Rhyme suggestions**: < 100ms (with NLEmbedding)
- **Melody generation**: < 200ms
- **Structure suggestion**: < 50ms
- **Style transformation**: < 300ms
- **Complete song starter**: < 1 second
- **Memory footprint**: < 20MB

---

## Privacy & On-Device Processing

- ✅ 100% on-device intelligence
- ✅ No cloud AI APIs (OpenAI, GPT, Claude, etc.)
- ✅ No external API calls
- ✅ Local SwiftData storage
- ✅ User data never leaves device
- ✅ All learning happens locally
- ✅ Complete offline functionality

---

## Technology Stack

### Apple Frameworks
- **NaturalLanguage** - Word embeddings, sentiment analysis, POS tagging
- **Foundation** - Date, Data, encoders/decoders
- **SwiftData** - Local persistence
- **SwiftUI** - User interface

### Custom Components
- **Music Theory Engine** - Chord relationships, scale math
- **Pattern Recognition** - Progression analysis
- **Rhyme Dictionary** - Phonetic matching
- **Melody Generator** - MIDI note generation

---

## Testing Strategy

### Unit Tests
- Chord progression generation accuracy
- Rhyme suggestion quality
- Melody singability scoring
- Structure template validation
- Style transformation correctness

### Integration Tests
- End-to-end song starter generation
- Multi-engine coordination
- Learning and personalization
- UI responsiveness

### User Acceptance Testing
- Music therapist beta group
- Real-world songwriting workflows
- Suggestion quality assessment
- Performance on older devices

---

## Files Created

### Engines (7 files)
- ChordProgressionEngine.swift
- LyricSuggestionEngine.swift
- MelodyHintEngine.swift
- SongStructureEngine.swift
- CollaborationEngine.swift
- StyleTransferEngine.swift
- LearningEngine.swift
- SongwritingAssistantManager.swift (orchestrator)

### Models (1 file)
- SongwritingModels.swift

### UI (1 file)
- SongwritingAssistantView.swift

**Total: 10 new files**

---

## Success Criteria

✅ All 8 features implemented
✅ 100% on-device processing
✅ Following Phase 7 architectural patterns
✅ Comprehensive data models
✅ Full UI implementation
✅ Integration with existing codebase
✅ Documentation complete

---

## Key Innovations

1. **Creative Partnership**: AI acts as collaborative partner, not just a tool
2. **Music Theory Foundation**: All suggestions grounded in solid theory
3. **Learning System**: Improves suggestions based on user preferences
4. **Complete Workflow**: From idea to finished song structure
5. **Privacy-First**: No cloud dependencies, data never leaves device
6. **Therapeutic Focus**: Designed for music therapy workflows

---

## Future Enhancements

### Short-Term
- Audio playback preview for generated melodies
- Export song starters to full songs
- More genre templates
- Advanced reharmonization techniques
- MIDI export for melody patterns

### Long-Term
- Core ML model for smarter predictions
- Voice input for lyric capture
- Real-time collaboration suggestions during editing
- Style learning from imported songs
- Custom genre profile creation

---

## Known Limitations

- Rhyme dictionary is simplified (production needs comprehensive phonetic database)
- Melody generation doesn't consider vocal range preferences yet
- Style transfer is rule-based (could benefit from ML model)
- Learning engine needs more usage data for accurate personalization
- No audio playback for generated melodies yet

---

## Usage Recommendations

1. **Start Simple**: Begin with song starters to understand the AI's capabilities
2. **Iterate**: Use collaboration mode to refine ideas iteratively
3. **Learn Theory**: Pay attention to music theory explanations to grow as a songwriter
4. **Provide Feedback**: Rate suggestions to improve personalization
5. **Explore Styles**: Try different genres to discover new creative directions
6. **Track Progress**: Check learning dashboard to see improvement over time

---

## Comparison with External AI Tools

### Lyra's Advantages
✅ Completely offline - works anywhere
✅ No subscription fees - one-time purchase
✅ Perfect privacy - data never leaves device
✅ Music therapy focus - appropriate for clinical use
✅ Integrated workflow - built into chord chart app
✅ Learns your style - personalized over time

### Trade-offs
⚠️ Less sophisticated than GPT-4 language generation
⚠️ Limited to rule-based music theory (not ML-powered)
⚠️ Smaller rhyme/word database than cloud services
⚠️ No audio generation/synthesis

**Philosophy**: Lyra prioritizes privacy, reliability, and appropriateness for professional music therapy over cutting-edge AI capabilities that require cloud connectivity and subscriptions.

---

## Troubleshooting

### Suggestions seem generic
- **Solution**: Use the assistant more - learning engine improves with data

### Rhymes don't match
- **Solution**: Try different rhyme types (perfect/near/slant)

### Melodies not singable
- **Solution**: Use "stepwise" or "hook" styles for easier melodies

### Structure doesn't fit song
- **Solution**: Use custom structure builder or modify suggested template

### Can't find the right chord
- **Solution**: Generate multiple progressions or use chord continuation

---

## Support & Feedback

For issues or feature requests:
1. Check Help section in app
2. Review this documentation
3. Test with different genres/keys
4. Provide feedback through collaboration mode ratings

---

**Status**: Implementation Complete - Phase 7.14
**Integration**: Ready for production use
**Testing**: Pending user acceptance testing
**Next Steps**: Monitor usage patterns and refine algorithms

---

## Conclusion

Phase 7.14 transforms Lyra into a complete songwriting assistant, providing intelligent suggestions for every aspect of the songwriting process while maintaining the app's core values of privacy, offline functionality, and professional quality. Music therapists now have a creative AI partner that understands music theory, learns their style, and assists without ever compromising client privacy or requiring ongoing subscription costs.

The system's 8 specialized engines work together seamlessly, from initial chord progressions through lyric writing and melody creation to final structure and arrangement. All powered by on-device intelligence using Apple's native frameworks and proven music theory principles.

**Lyra is now a true AI-powered creative partner for music therapy professionals.**
