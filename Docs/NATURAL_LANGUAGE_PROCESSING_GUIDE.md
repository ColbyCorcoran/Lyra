# Natural Language Processing Guide

## Overview

Phase 7.11 adds comprehensive natural language processing capabilities to Lyra, enabling voice commands and natural language interaction for hands-free control and enhanced accessibility.

## Features

### 1. Voice Command System

Speech-to-text conversion with real-time processing:
- Continuous listening mode
- Wake word activation ("Hey Lyra")
- Multi-language support
- Background noise filtering
- Offline capability

### 2. Supported Commands

#### Navigation Commands
- "Show me slow songs"
- "Find songs about hope"
- "Go to my worship set"
- "What's next in the set?"
- "Show recent songs"

#### Editing Commands
- "Transpose to C"
- "Transpose up two steps"
- "Change key to G major"
- "Set capo to 2"
- "Remove capo"

#### Set Management Commands
- "Add to worship set"
- "Add this to Sunday morning"
- "Create new set for Easter"
- "Remove from set"

#### Performance Commands
- "Start autoscroll"
- "Stop autoscroll"
- "Scroll faster"
- "Scroll slower"
- "Start metronome at 120"
- "Enable performance mode"

#### Search Commands
- "Find Amazing Grace"
- "Show me songs in D"
- "Find fast songs"
- "Search for Chris Tomlin songs"

### 3. Intent Classification

Machine learning model classifies commands into categories:
- **Search**: Find, show, search queries
- **Navigate**: Go to, open, display
- **Edit**: Transpose, change, modify
- **Perform**: Start, stop, enable performance features
- **Create**: Add, create, new items
- **Query**: Questions about songs, sets, or app state

### 4. Entity Extraction

Automatically extracts parameters from commands:
- **Song names**: "Amazing Grace", "How Great Thou Art"
- **Keys**: C, D, G, Am, F#m
- **Tempo**: Fast, slow, 120 BPM
- **Actions**: Transpose, add, find, show
- **Attributes**: Slow, fast, happy, peaceful
- **Numbers**: Capo positions, transpose steps
- **Set names**: "worship set", "Sunday morning"

### 5. Context Awareness

Remembers conversation history for natural follow-up:
- **Pronoun resolution**: "Add it to my set" (knows what "it" refers to)
- **Follow-up questions**: "Show more like this"
- **Multi-turn conversations**: Build complex queries across multiple commands
- **Session memory**: Retains context throughout app session

### 6. Confirmation and Feedback

Smart confirmation system:
- **Destructive actions**: Always confirm before deleting or major changes
- **Visual feedback**: Shows what was understood
- **Clarification requests**: Asks for more info when ambiguous
- **Suggestion prompts**: Offers corrections for misunderstood commands
- **Success messages**: Confirms completed actions

### 7. Hands-Free Mode

Complete voice-only navigation:
- Voice-activated controls
- Audio feedback for all actions
- Verbal song information readout
- Voice-guided setup
- Accessibility optimized
- Screen reader integration

### 8. Learning System

Adapts to user's speaking style:
- **Pattern recognition**: Learns frequently used commands
- **Personal vocabulary**: Adapts to your song names and terminology
- **Custom shortcuts**: Create personal voice commands
- **Accuracy improvement**: Gets better with use
- **Preference learning**: Remembers your common actions

## Architecture

### Core Components

```
VoiceCommandEngine (Main orchestrator)
├── SpeechRecognitionManager (Speech-to-text)
├── IntentClassifier (ML-based classification)
├── EntityExtractor (Parameter extraction)
├── ConversationContextManager (Context tracking)
├── CommandExecutor (Action execution)
├── VoiceFeedbackEngine (Audio responses)
└── UserCommandLearner (Personalization)
```

### Data Flow

1. **Speech Input** → SpeechRecognitionManager converts audio to text
2. **Text Processing** → IntentClassifier determines command type
3. **Entity Extraction** → EntityExtractor pulls out parameters
4. **Context Resolution** → ConversationContextManager resolves references
5. **Execution** → CommandExecutor performs action
6. **Feedback** → VoiceFeedbackEngine provides confirmation
7. **Learning** → UserCommandLearner updates user patterns

## Usage Examples

### Example 1: Finding and Adding Songs

```
User: "Find songs about grace"
Lyra: "I found 12 songs about grace. Would you like to see them?"
User: "Show the first five"
Lyra: "Showing Amazing Grace, Grace Like Rain, Grace Flows Down..."
User: "Add the second one to my worship set"
Lyra: "Added 'Grace Like Rain' to your worship set."
```

### Example 2: Transposing Songs

```
User: "Transpose this song to C"
Lyra: "Transposed from G to C. Would you like to add a capo suggestion?"
User: "Yes, what do you recommend?"
Lyra: "To make it easier, you could capo 5 and play in G shapes."
```

### Example 3: Performance Control

```
User: "Start autoscroll"
Lyra: "Autoscroll started at medium speed."
User: "A bit faster"
Lyra: "Speed increased to fast."
User: "Perfect, now start the metronome at 120"
Lyra: "Metronome set to 120 BPM."
```

### Example 4: Set Management

```
User: "Create a new set called Easter Sunday"
Lyra: "Created new set 'Easter Sunday'. Would you like to add songs?"
User: "Yes, add Christ the Lord is Risen Today"
Lyra: "Added to Easter Sunday set."
User: "What's in that set now?"
Lyra: "Easter Sunday has 1 song: Christ the Lord is Risen Today."
```

## Command Categories

### Search Intents
- `findSongs`: General song search
- `findByKey`: Search by musical key
- `findByTempo`: Search by speed/BPM
- `findByMood`: Search by mood/feeling
- `findByArtist`: Search by artist/composer
- `findByLyrics`: Search song lyrics

### Navigation Intents
- `goToSong`: Navigate to specific song
- `goToSet`: Open performance set
- `showNext`: Show next item
- `showPrevious`: Show previous item
- `goHome`: Return to main screen

### Edit Intents
- `transpose`: Change key
- `setCapo`: Add/change capo
- `editSong`: Modify song details
- `deleteSong`: Remove song

### Performance Intents
- `startAutoscroll`: Begin auto-scrolling
- `stopAutoscroll`: Stop auto-scrolling
- `adjustScrollSpeed`: Change scroll speed
- `startMetronome`: Start metronome
- `enablePerformanceMode`: Activate performance mode

### Set Management Intents
- `addToSet`: Add song to set
- `removeFromSet`: Remove song from set
- `createSet`: Create new set
- `reorderSet`: Change set order

### Query Intents
- `whatSong`: Ask about current song
- `whatSet`: Ask about current set
- `whatsNext`: Ask what's coming next
- `howMany`: Count songs/sets

## Confidence Scoring

Commands are scored for confidence:
- **High (>0.8)**: Execute immediately
- **Medium (0.5-0.8)**: Show confirmation
- **Low (<0.5)**: Ask for clarification

## Error Handling

### Ambiguous Commands
```
User: "Add it to my set"
Lyra: "I'm not sure which song you mean. Did you mean 'Amazing Grace' or 'How Great Thou Art'?"
```

### Unrecognized Commands
```
User: "Make it purple"
Lyra: "I didn't understand that command. Try saying 'change key', 'find songs', or 'start autoscroll'."
```

### Missing Context
```
User: "Add it"
Lyra: "What would you like to add? You can say 'add [song name] to [set name]'."
```

## Privacy and Security

- All speech processing happens on-device
- No voice data sent to servers
- Optional voice data retention for learning
- Can disable learning features
- Manual command history clearing

## Accessibility Features

- Voice-only navigation support
- VoiceOver integration
- Adjustable speech rate
- Audio feedback customization
- Visual command confirmation
- Haptic feedback options

## Performance Optimization

- Streaming speech recognition
- Background processing
- Low latency response (<500ms)
- Efficient ML model (CoreML)
- Minimal battery impact

## Customization

### Voice Settings
- Recognition language
- Wake word enable/disable
- Continuous listening mode
- Confirmation level (none/destructive/all)
- Feedback verbosity

### Learning Settings
- Enable/disable learning
- Clear learned patterns
- Reset to defaults
- Export/import custom commands

## Testing

### Test Commands
```
"Find songs in C"
"Transpose to G major"
"Add to worship set"
"Start autoscroll"
"What's next?"
"Show me slow songs"
"Create set called Test"
"Remove capo"
"Scroll faster"
"Stop performance mode"
```

### Edge Cases to Test
- Background noise
- Multiple languages
- Accents and dialects
- Fast speech
- Quiet speech
- Interruptions
- Ambiguous references
- Complex multi-part commands

## Troubleshooting

### Voice Not Recognized
- Check microphone permissions
- Reduce background noise
- Speak clearly and at normal volume
- Check language settings

### Wrong Action Executed
- Use more specific commands
- Include more context
- Enable confirmation for all commands
- Review and correct in command history

### Commands Not Learning
- Enable learning in settings
- Use commands consistently
- Review learned patterns
- Clear corrupted learning data

## Future Enhancements

- Multi-language support (currently English only)
- Custom wake word
- Voice profiles for multiple users
- Advanced query composition
- Natural conversation mode
- Integration with smart assistants
- Bluetooth headset optimization

## API Reference

### VoiceCommandEngine

```swift
// Start listening for commands
func startListening()

// Stop listening
func stopListening()

// Process text command directly
func processCommand(_ text: String) async -> CommandResult

// Get command history
func getCommandHistory() -> [VoiceCommand]

// Clear context
func clearContext()
```

### IntentClassifier

```swift
// Classify intent with confidence score
func classifyIntent(_ text: String) -> (intent: CommandIntent, confidence: Float)

// Get possible intents ranked by confidence
func getPossibleIntents(_ text: String) -> [(intent: CommandIntent, confidence: Float)]
```

### EntityExtractor

```swift
// Extract all entities from text
func extractEntities(_ text: String) -> [CommandEntity]

// Extract specific entity type
func extractEntity(_ text: String, type: EntityType) -> CommandEntity?
```

## Code Examples

### Processing a Voice Command

```swift
// Initialize voice command engine
let voiceEngine = VoiceCommandEngine(modelContext: modelContext)

// Start listening
voiceEngine.startListening()

// Process command
Task {
    let result = await voiceEngine.processCommand("Find songs in C")

    switch result {
    case .success(let action):
        print("Executing: \(action.description)")
    case .needsConfirmation(let action):
        // Show confirmation dialog
        await confirmAction(action)
    case .needsClarification(let options):
        // Show options to user
        await clarifyIntent(options)
    case .error(let message):
        print("Error: \(message)")
    }
}
```

### Adding Custom Command Patterns

```swift
// Register custom command
voiceEngine.registerCustomPattern(
    pattern: "play song {songName}",
    intent: .goToSong,
    entityMappings: ["songName": .songTitle]
)
```

## Conclusion

Phase 7.11's Natural Language Processing system makes Lyra accessible and controllable by voice, enabling hands-free operation perfect for performance situations and improved accessibility for all users.
