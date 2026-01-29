//
//  SongTemplateTests.swift
//  LyraTests
//
//  Created by Claude on 1/28/26.
//

import Testing
import SwiftData
import Foundation
@testable import Lyra

@Suite("Song Template Tests")
struct SongTemplateTests {
    var container: ModelContainer
    var context: ModelContext

    init() throws {
        let schema = Schema([
            Song.self,
            Template.self,
            Book.self,
            SetEntry.self,
            Annotation.self
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
    }

    // MARK: - Template Relationship Tests

    @Test("Song can have a template assigned")
    func testSongTemplateAssignment() throws {
        let song = Song(title: "Test Song")
        let template = Template(name: "Test Template", columnCount: 2)

        context.insert(song)
        context.insert(template)

        song.template = template

        try context.save()

        #expect(song.template != nil)
        #expect(song.template?.name == "Test Template")
        #expect(song.template?.columnCount == 2)
    }

    @Test("Song template relationship is optional")
    func testSongWithoutTemplate() throws {
        let song = Song(title: "No Template Song")

        context.insert(song)
        try context.save()

        #expect(song.template == nil)
    }

    @Test("Song template can be changed")
    func testSongTemplateChange() throws {
        let song = Song(title: "Test Song")
        let template1 = Template(name: "Template 1", columnCount: 1)
        let template2 = Template(name: "Template 2", columnCount: 2)

        context.insert(song)
        context.insert(template1)
        context.insert(template2)

        song.template = template1
        try context.save()
        #expect(song.template?.name == "Template 1")

        song.template = template2
        try context.save()
        #expect(song.template?.name == "Template 2")
    }

    @Test("Song template can be removed")
    func testSongTemplateRemoval() throws {
        let song = Song(title: "Test Song")
        let template = Template(name: "Test Template")

        context.insert(song)
        context.insert(template)

        song.template = template
        try context.save()
        #expect(song.template != nil)

        song.template = nil
        try context.save()
        #expect(song.template == nil)
    }

    @Test("Template deletion nullifies song template reference")
    func testTemplateDeletionNullifyRule() throws {
        let song = Song(title: "Test Song")
        let template = Template(name: "Template to Delete")

        context.insert(song)
        context.insert(template)

        song.template = template
        try context.save()
        #expect(song.template != nil)

        context.delete(template)
        try context.save()

        // The deleteRule is .nullify, so song.template should be nil
        #expect(song.template == nil)
    }

    @Test("Multiple songs can share the same template")
    func testMultipleSongsShareTemplate() throws {
        let template = Template(name: "Shared Template", columnCount: 2)
        let song1 = Song(title: "Song 1")
        let song2 = Song(title: "Song 2")
        let song3 = Song(title: "Song 3")

        context.insert(template)
        context.insert(song1)
        context.insert(song2)
        context.insert(song3)

        song1.template = template
        song2.template = template
        song3.template = template

        try context.save()

        #expect(song1.template?.name == "Shared Template")
        #expect(song2.template?.name == "Shared Template")
        #expect(song3.template?.name == "Shared Template")
        #expect(song1.template?.id == song2.template?.id)
        #expect(song2.template?.id == song3.template?.id)
    }

    // MARK: - Effective Template Tests

    @Test("effectiveTemplate returns song-specific template when set")
    func testEffectiveTemplateWithSongTemplate() throws {
        let song = Song(title: "Test Song")
        let songTemplate = Template(name: "Song Template", columnCount: 3)

        context.insert(song)
        context.insert(songTemplate)

        song.template = songTemplate
        try context.save()

        let effective = song.effectiveTemplate(context: context)

        #expect(effective.name == "Song Template")
        #expect(effective.columnCount == 3)
        #expect(effective.id == songTemplate.id)
    }

    @Test("effectiveTemplate returns default template when no song template")
    func testEffectiveTemplateWithDefaultTemplate() throws {
        // Clear any existing default
        UserDefaults.standard.defaultTemplateID = nil

        let song = Song(title: "Test Song")
        let defaultTemplate = Template(name: "Default Template", columnCount: 2)

        context.insert(song)
        context.insert(defaultTemplate)
        try context.save()

        // Set as default
        UserDefaults.standard.defaultTemplateID = defaultTemplate.id

        let effective = song.effectiveTemplate(context: context)

        #expect(effective.name == "Default Template")
        #expect(effective.columnCount == 2)
        #expect(effective.id == defaultTemplate.id)

        // Clean up
        UserDefaults.standard.defaultTemplateID = nil
    }

    @Test("effectiveTemplate returns built-in when no template or default")
    func testEffectiveTemplateWithNoTemplateOrDefault() throws {
        // Clear any existing default
        UserDefaults.standard.defaultTemplateID = nil

        let song = Song(title: "Test Song")
        context.insert(song)
        try context.save()

        let effective = song.effectiveTemplate(context: context)

        // Should return built-in single column
        #expect(effective.name == "Single Column")
        #expect(effective.columnCount == 1)
        #expect(effective.isBuiltIn == true)
    }

    @Test("effectiveTemplate prefers song template over default")
    func testEffectiveTemplatePriority() throws {
        // Clear any existing default
        UserDefaults.standard.defaultTemplateID = nil

        let song = Song(title: "Test Song")
        let songTemplate = Template(name: "Song Template", columnCount: 3)
        let defaultTemplate = Template(name: "Default Template", columnCount: 2)

        context.insert(song)
        context.insert(songTemplate)
        context.insert(defaultTemplate)
        try context.save()

        // Set default
        UserDefaults.standard.defaultTemplateID = defaultTemplate.id

        // Set song template
        song.template = songTemplate
        try context.save()

        let effective = song.effectiveTemplate(context: context)

        // Should return song template, not default
        #expect(effective.name == "Song Template")
        #expect(effective.columnCount == 3)
        #expect(effective.id == songTemplate.id)

        // Clean up
        UserDefaults.standard.defaultTemplateID = nil
    }

    @Test("effectiveTemplate handles invalid default ID gracefully")
    func testEffectiveTemplateWithInvalidDefaultID() throws {
        let invalidUUID = UUID() // Random UUID that won't match any template

        UserDefaults.standard.defaultTemplateID = invalidUUID

        let song = Song(title: "Test Song")
        context.insert(song)
        try context.save()

        let effective = song.effectiveTemplate(context: context)

        // Should fallback to built-in when default ID is invalid
        #expect(effective.name == "Single Column")
        #expect(effective.columnCount == 1)
        #expect(effective.isBuiltIn == true)

        // Clean up
        UserDefaults.standard.defaultTemplateID = nil
    }

    @Test("effectiveTemplate handles deleted default template")
    func testEffectiveTemplateWithDeletedDefault() throws {
        // Clear any existing default
        UserDefaults.standard.defaultTemplateID = nil

        let song = Song(title: "Test Song")
        let defaultTemplate = Template(name: "Default Template", columnCount: 2)

        context.insert(song)
        context.insert(defaultTemplate)
        try context.save()

        // Set as default
        let defaultID = defaultTemplate.id
        UserDefaults.standard.defaultTemplateID = defaultID

        // Delete the default template
        context.delete(defaultTemplate)
        try context.save()

        let effective = song.effectiveTemplate(context: context)

        // Should fallback to built-in when default template is deleted
        #expect(effective.name == "Single Column")
        #expect(effective.columnCount == 1)
        #expect(effective.isBuiltIn == true)

        // Clean up
        UserDefaults.standard.defaultTemplateID = nil
    }

    // MARK: - UserDefaults Integration Tests

    @Test("defaultTemplateID can be set and retrieved")
    func testDefaultTemplateIDUserDefaults() throws {
        let testUUID = UUID()

        UserDefaults.standard.defaultTemplateID = testUUID

        let retrieved = UserDefaults.standard.defaultTemplateID

        #expect(retrieved == testUUID)

        // Clean up
        UserDefaults.standard.defaultTemplateID = nil
    }

    @Test("defaultTemplateID can be cleared")
    func testDefaultTemplateIDClear() throws {
        let testUUID = UUID()

        UserDefaults.standard.defaultTemplateID = testUUID
        #expect(UserDefaults.standard.defaultTemplateID != nil)

        UserDefaults.standard.defaultTemplateID = nil
        #expect(UserDefaults.standard.defaultTemplateID == nil)
    }

    @Test("defaultTemplateID returns nil when not set")
    func testDefaultTemplateIDNotSet() throws {
        // Clear any existing value
        UserDefaults.standard.defaultTemplateID = nil

        let retrieved = UserDefaults.standard.defaultTemplateID

        #expect(retrieved == nil)
    }

    // MARK: - Integration Tests

    @Test("Song template workflow: create, assign, fetch, verify")
    func testCompleteTemplateWorkflow() throws {
        // Create template
        let template = Template(
            name: "Workflow Template",
            columnCount: 2,
            columnGap: 20.0,
            columnBalancingStrategy: .balanced
        )
        context.insert(template)
        try context.save()

        // Create song and assign template
        let song = Song(title: "Workflow Song", artist: "Test Artist")
        context.insert(song)
        song.template = template
        try context.save()

        // Fetch song
        let descriptor = FetchDescriptor<Song>(
            predicate: #Predicate { song in
                song.title == "Workflow Song"
            }
        )
        let fetchedSongs = try context.fetch(descriptor)

        #expect(fetchedSongs.count == 1)
        let fetchedSong = fetchedSongs[0]

        // Verify template is properly linked
        #expect(fetchedSong.template != nil)
        #expect(fetchedSong.template?.name == "Workflow Template")
        #expect(fetchedSong.template?.columnCount == 2)

        // Verify effectiveTemplate works
        let effective = fetchedSong.effectiveTemplate(context: context)
        #expect(effective.name == "Workflow Template")
        #expect(effective.columnCount == 2)
    }

    @Test("Multiple songs with different templates")
    func testMultipleSongsDifferentTemplates() throws {
        let template1 = Template(name: "Template 1", columnCount: 1)
        let template2 = Template(name: "Template 2", columnCount: 2)
        let template3 = Template(name: "Template 3", columnCount: 3)

        context.insert(template1)
        context.insert(template2)
        context.insert(template3)

        let song1 = Song(title: "Song 1")
        let song2 = Song(title: "Song 2")
        let song3 = Song(title: "Song 3")
        let song4 = Song(title: "Song 4") // No template

        context.insert(song1)
        context.insert(song2)
        context.insert(song3)
        context.insert(song4)

        song1.template = template1
        song2.template = template2
        song3.template = template3
        // song4 has no template

        try context.save()

        #expect(song1.template?.columnCount == 1)
        #expect(song2.template?.columnCount == 2)
        #expect(song3.template?.columnCount == 3)
        #expect(song4.template == nil)

        // Verify effectiveTemplate for song without template
        let effective4 = song4.effectiveTemplate(context: context)
        #expect(effective4.isBuiltIn == true)
    }

    @Test("Song survives template deletion due to nullify rule")
    func testSongSurvivesTemplateDeletion() throws {
        let song = Song(title: "Survivor Song")
        let template = Template(name: "Doomed Template")

        context.insert(song)
        context.insert(template)

        song.template = template
        try context.save()

        #expect(song.template != nil)

        // Delete template
        context.delete(template)
        try context.save()

        // Song should still exist
        let descriptor = FetchDescriptor<Song>()
        let songs = try context.fetch(descriptor)
        #expect(songs.count == 1)
        #expect(songs[0].title == "Survivor Song")
        #expect(songs[0].template == nil)
    }
}
