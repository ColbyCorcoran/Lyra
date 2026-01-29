//
//  SongDisplayViewTemplateTests.swift
//  LyraTests
//
//  Tests for SongDisplayView template integration
//

import Testing
import SwiftUI
import SwiftData
@testable import Lyra

@Suite("SongDisplayView Template Integration Tests")
@MainActor
struct SongDisplayViewTemplateTests {
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

    // MARK: - Helper Methods

    private func createTestSong(
        title: String = "Test Song",
        content: String? = nil
    ) -> Song {
        let defaultContent = """
        {title: \(title)}
        {artist: Test Artist}
        {key: C}

        {verse}
        [C]Test [F]line [G]one
        With [C]basic [F]chords

        {chorus}
        [C]This is [F]chorus
        [G]Singing [C]along
        """

        return Song(
            title: title,
            content: content ?? defaultContent
        )
    }

    // MARK: - Template Selection Tests

    @Test("Song uses single column template by default")
    func testDefaultSingleColumnTemplate() throws {
        let song = createTestSong()
        context.insert(song)
        try context.save()

        let effectiveTemplate = song.effectiveTemplate(context: context)

        #expect(effectiveTemplate.columnCount == 1)
        #expect(effectiveTemplate.isBuiltIn == true)
        #expect(effectiveTemplate.name == "Single Column")
    }

    @Test("Song can be assigned a two-column template")
    func testTwoColumnTemplateAssignment() throws {
        let song = createTestSong()
        let template = Template.builtInTwoColumn()

        context.insert(song)
        context.insert(template)

        song.template = template
        try context.save()

        let effectiveTemplate = song.effectiveTemplate(context: context)

        #expect(effectiveTemplate.columnCount == 2)
        #expect(effectiveTemplate.name == "Two Column")
    }

    @Test("Song can be assigned a three-column template")
    func testThreeColumnTemplateAssignment() throws {
        let song = createTestSong()
        let template = Template.builtInThreeColumn()

        context.insert(song)
        context.insert(template)

        song.template = template
        try context.save()

        let effectiveTemplate = song.effectiveTemplate(context: context)

        #expect(effectiveTemplate.columnCount == 3)
        #expect(effectiveTemplate.name == "Three Column")
    }

    @Test("Song template can be changed from single to multi-column")
    func testTemplateChangeFromSingleToMulti() throws {
        let song = createTestSong()
        let singleTemplate = Template.builtInSingleColumn()
        let twoTemplate = Template.builtInTwoColumn()

        context.insert(song)
        context.insert(singleTemplate)
        context.insert(twoTemplate)

        // Start with single column
        song.template = singleTemplate
        try context.save()

        #expect(song.effectiveTemplate(context: context).columnCount == 1)

        // Change to two column
        song.template = twoTemplate
        try context.save()

        #expect(song.effectiveTemplate(context: context).columnCount == 2)
    }

    @Test("Song template can be changed from multi to single-column")
    func testTemplateChangeFromMultiToSingle() throws {
        let song = createTestSong()
        let threeTemplate = Template.builtInThreeColumn()
        let singleTemplate = Template.builtInSingleColumn()

        context.insert(song)
        context.insert(threeTemplate)
        context.insert(singleTemplate)

        // Start with three column
        song.template = threeTemplate
        try context.save()

        #expect(song.effectiveTemplate(context: context).columnCount == 3)

        // Change to single column
        song.template = singleTemplate
        try context.save()

        #expect(song.effectiveTemplate(context: context).columnCount == 1)
    }

    @Test("Song template can be removed to use default")
    func testTemplateRemoval() throws {
        let song = createTestSong()
        let template = Template.builtInTwoColumn()

        context.insert(song)
        context.insert(template)

        // Assign template
        song.template = template
        try context.save()
        #expect(song.template != nil)

        // Remove template
        song.template = nil
        try context.save()
        #expect(song.template == nil)

        // Should fall back to default (built-in single column)
        let effectiveTemplate = song.effectiveTemplate(context: context)
        #expect(effectiveTemplate.columnCount == 1)
    }

    // MARK: - Custom Template Tests

    @Test("Song can use custom template")
    func testCustomTemplate() throws {
        let song = createTestSong()
        let customTemplate = Template(
            name: "My Custom Layout",
            columnCount: 2,
            columnGap: 30.0,
            columnBalancingStrategy: .balanced
        )

        context.insert(song)
        context.insert(customTemplate)

        song.template = customTemplate
        try context.save()

        let effectiveTemplate = song.effectiveTemplate(context: context)

        #expect(effectiveTemplate.name == "My Custom Layout")
        #expect(effectiveTemplate.columnCount == 2)
        #expect(effectiveTemplate.columnGap == 30.0)
        #expect(effectiveTemplate.columnBalancingStrategy == .balanced)
    }

    @Test("Song with custom template survives template deletion")
    func testSongSurvivesCustomTemplateDeletion() throws {
        let song = createTestSong()
        let customTemplate = Template(name: "Temporary Template")

        context.insert(song)
        context.insert(customTemplate)

        song.template = customTemplate
        try context.save()

        #expect(song.template != nil)

        // Delete template
        context.delete(customTemplate)
        try context.save()

        // Song should still exist
        #expect(song.template == nil)

        // Should fall back to default
        let effectiveTemplate = song.effectiveTemplate(context: context)
        #expect(effectiveTemplate.columnCount == 1)
        #expect(effectiveTemplate.isBuiltIn == true)
    }

    // MARK: - Default Template Tests

    @Test("Song uses global default template when no specific template is set")
    func testGlobalDefaultTemplate() throws {
        // Clear existing default
        UserDefaults.standard.defaultTemplateID = nil

        let song = createTestSong()
        let defaultTemplate = Template(name: "Global Default", columnCount: 2)

        context.insert(song)
        context.insert(defaultTemplate)
        try context.save()

        // Set as global default
        UserDefaults.standard.defaultTemplateID = defaultTemplate.id

        let effectiveTemplate = song.effectiveTemplate(context: context)

        #expect(effectiveTemplate.name == "Global Default")
        #expect(effectiveTemplate.columnCount == 2)

        // Clean up
        UserDefaults.standard.defaultTemplateID = nil
    }

    @Test("Song-specific template overrides global default")
    func testSongTemplateOverridesGlobalDefault() throws {
        // Clear existing default
        UserDefaults.standard.defaultTemplateID = nil

        let song = createTestSong()
        let songTemplate = Template(name: "Song Template", columnCount: 3)
        let defaultTemplate = Template(name: "Global Default", columnCount: 2)

        context.insert(song)
        context.insert(songTemplate)
        context.insert(defaultTemplate)
        try context.save()

        // Set global default
        UserDefaults.standard.defaultTemplateID = defaultTemplate.id

        // Set song template
        song.template = songTemplate
        try context.save()

        let effectiveTemplate = song.effectiveTemplate(context: context)

        // Should use song template, not global default
        #expect(effectiveTemplate.name == "Song Template")
        #expect(effectiveTemplate.columnCount == 3)

        // Clean up
        UserDefaults.standard.defaultTemplateID = nil
    }

    // MARK: - Multi-Column Rendering Tests

    @Test("Single-column template uses traditional rendering")
    func testSingleColumnRendering() throws {
        let song = createTestSong()
        let template = Template.builtInSingleColumn()

        context.insert(song)
        context.insert(template)

        song.template = template
        try context.save()

        let effectiveTemplate = song.effectiveTemplate(context: context)

        #expect(effectiveTemplate.columnCount == 1)
        // In actual view, this would use the traditional VStack rendering
    }

    @Test("Multi-column template should trigger MultiColumnSongView")
    func testMultiColumnRendering() throws {
        let song = createTestSong()
        let template = Template.builtInTwoColumn()

        context.insert(song)
        context.insert(template)

        song.template = template
        try context.save()

        let effectiveTemplate = song.effectiveTemplate(context: context)

        #expect(effectiveTemplate.columnCount > 1)
        // In actual view, this would use MultiColumnSongView
    }

    // MARK: - Integration Tests

    @Test("Complete workflow: create song, assign template, change template")
    func testCompleteWorkflow() throws {
        // Create song
        let song = createTestSong(title: "Workflow Test")
        context.insert(song)
        try context.save()

        // Initially uses built-in default
        var effectiveTemplate = song.effectiveTemplate(context: context)
        #expect(effectiveTemplate.columnCount == 1)

        // Assign two-column template
        let twoColumnTemplate = Template.builtInTwoColumn()
        context.insert(twoColumnTemplate)
        song.template = twoColumnTemplate
        song.modifiedAt = Date()
        try context.save()

        effectiveTemplate = song.effectiveTemplate(context: context)
        #expect(effectiveTemplate.columnCount == 2)

        // Change to three-column template
        let threeColumnTemplate = Template.builtInThreeColumn()
        context.insert(threeColumnTemplate)
        song.template = threeColumnTemplate
        song.modifiedAt = Date()
        try context.save()

        effectiveTemplate = song.effectiveTemplate(context: context)
        #expect(effectiveTemplate.columnCount == 3)

        // Remove template to use default
        song.template = nil
        song.modifiedAt = Date()
        try context.save()

        effectiveTemplate = song.effectiveTemplate(context: context)
        #expect(effectiveTemplate.columnCount == 1)
    }

    @Test("Multiple songs with different templates")
    func testMultipleSongsDifferentTemplates() throws {
        let singleTemplate = Template.builtInSingleColumn()
        let twoTemplate = Template.builtInTwoColumn()
        let threeTemplate = Template.builtInThreeColumn()

        context.insert(singleTemplate)
        context.insert(twoTemplate)
        context.insert(threeTemplate)

        let song1 = createTestSong(title: "Song 1")
        let song2 = createTestSong(title: "Song 2")
        let song3 = createTestSong(title: "Song 3")

        context.insert(song1)
        context.insert(song2)
        context.insert(song3)

        song1.template = singleTemplate
        song2.template = twoTemplate
        song3.template = threeTemplate

        try context.save()

        #expect(song1.effectiveTemplate(context: context).columnCount == 1)
        #expect(song2.effectiveTemplate(context: context).columnCount == 2)
        #expect(song3.effectiveTemplate(context: context).columnCount == 3)
    }

    // MARK: - Edge Cases

    @Test("Song with no content uses template correctly")
    func testEmptySongWithTemplate() throws {
        let song = Song(title: "Empty Song", content: "")
        let template = Template.builtInTwoColumn()

        context.insert(song)
        context.insert(template)

        song.template = template
        try context.save()

        let effectiveTemplate = song.effectiveTemplate(context: context)

        #expect(effectiveTemplate.columnCount == 2)
    }

    @Test("Song with complex content uses template correctly")
    func testComplexSongWithTemplate() throws {
        let complexContent = """
        {title: Complex Song}
        {artist: Test Artist}
        {key: G}
        {tempo: 120}
        {time: 4/4}
        {capo: 2}

        {verse: Verse 1}
        [G]Amazing [G7]grace how [C]sweet the [G]sound
        That saved a [Em]wretch like [D]me

        {verse: Verse 2}
        'Twas [G]grace that [G7]taught my [C]heart to [G]fear
        And grace my [Em]fears re[D]lieved

        {chorus}
        [C]Amazing [G]grace how [D]sweet the [G]sound
        [C]Forever [G]singing [D]Your [G]praise

        {bridge}
        [Am]When we've [F]been there [C]ten thousand [G]years
        [Am]Bright shining [F]as the [C]sun [G]

        {ending}
        [G]Amazing [C]grace [D]how sweet the [G]sound
        """

        let song = createTestSong(title: "Complex Song", content: complexContent)
        let template = Template.builtInThreeColumn()

        context.insert(song)
        context.insert(template)

        song.template = template
        try context.save()

        let effectiveTemplate = song.effectiveTemplate(context: context)

        #expect(effectiveTemplate.columnCount == 3)
    }
}
