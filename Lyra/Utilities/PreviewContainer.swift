//
//  PreviewContainer.swift
//  Lyra
//
//  Preview helper for SwiftData with sample data
//

import SwiftData
import Foundation

@MainActor
class PreviewContainer {
    static let shared = PreviewContainer()

    let container: ModelContainer
    let context: ModelContext

    private init() {
        let schema = Schema([
            Song.self,
            Template.self,
            Book.self,
            PerformanceSet.self,
            SetEntry.self,
            Annotation.self,
            UserSettings.self,
            RecurrenceRule.self
        ])

        // Validate preview schema matches production schema
        let missingModels = SchemaVersioning.validateSchema(schema)
        if !missingModels.isEmpty {
            fatalError("Preview schema validation failed. Missing models: \(missingModels.joined(separator: ", "))")
        }

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true // In-memory for previews
        )

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            context = container.mainContext

            // Add sample data
            addSampleData()
        } catch {
            fatalError("Could not create preview ModelContainer: \(error)")
        }
    }

    private func addSampleData() {
        // Create sample songs
        let song1 = Song(
            title: "Amazing Grace",
            artist: "Traditional",
            content: """
            {title: Amazing Grace}
            {artist: Traditional}
            {key: G}
            {tempo: 90}

            [G]Amazing [G7]grace, how [C]sweet the [G]sound
            That saved a wretch like [D]me
            [G]I once was [G7]lost, but [C]now am [G]found
            Was [Em]blind but [D]now I [G]see
            """,
            contentFormat: .chordPro,
            originalKey: "G"
        )
        song1.tempo = 90
        song1.tags = ["Hymn", "Classic", "Worship"]

        let song2 = Song(
            title: "Come Thou Fount",
            artist: "Robert Robinson",
            content: """
            {title: Come Thou Fount}
            {artist: Robert Robinson}
            {key: D}

            [D]Come thou fount of [A]every [D]blessing
            Tune my [A]heart to [D]sing thy [A]grace
            """,
            contentFormat: .chordPro,
            originalKey: "D"
        )
        song2.tags = ["Hymn", "Classic"]

        let song3 = Song(
            title: "How Great Thou Art",
            artist: "Carl Boberg",
            content: """
            {title: How Great Thou Art}
            {key: C}

            [C]O Lord my God, when I in awesome wonder
            [F]Consider [C]all the worlds thy hands have [G]made
            """,
            contentFormat: .chordPro,
            originalKey: "C"
        )

        // Create sample books
        let hymnBook = Book(name: "Classic Hymns", description: "Traditional hymns collection")
        hymnBook.color = "#4A90E2"
        hymnBook.icon = "music.note.list"

        let worshipBook = Book(name: "Sunday Worship", description: "Songs for Sunday service")
        worshipBook.color = "#E24A4A"
        worshipBook.icon = "sun.max.fill"

        // Add songs to books
        hymnBook.songs = [song1, song2, song3]
        worshipBook.songs = [song1, song3]

        // Create a sample set
        let sundaySet = PerformanceSet(name: "Sunday Morning Service", scheduledDate: Date())
        sundaySet.venue = "Main Sanctuary"
        sundaySet.notes = "Open with Amazing Grace, close with How Great Thou Art"

        // Create set entries
        let entry1 = SetEntry(song: song1, orderIndex: 0)
        entry1.performanceSet = sundaySet
        entry1.notes = "Slow tempo, build gradually"

        let entry2 = SetEntry(song: song2, orderIndex: 1)
        entry2.performanceSet = sundaySet
        entry2.keyOverride = "E" // Different key for this set

        let entry3 = SetEntry(song: song3, orderIndex: 2)
        entry3.performanceSet = sundaySet

        sundaySet.songEntries = [entry1, entry2, entry3]

        // Create sample annotation
        let annotation = Annotation(song: song1, type: .stickyNote, x: 0.5, y: 0.3)
        annotation.text = "Remember to slow down here"
        annotation.noteColor = "#FFEB3B"
        annotation.textColor = "#000000"

        // Create user settings
        let settings = UserSettings()

        // Insert all into context
        context.insert(song1)
        context.insert(song2)
        context.insert(song3)
        context.insert(hymnBook)
        context.insert(worshipBook)
        context.insert(sundaySet)
        context.insert(entry1)
        context.insert(entry2)
        context.insert(entry3)
        context.insert(annotation)
        context.insert(settings)

        // Save context
        do {
            try context.save()
        } catch {
            print("Failed to save preview data: \(error)")
        }
    }
}
