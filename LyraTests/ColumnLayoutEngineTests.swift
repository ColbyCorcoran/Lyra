//
//  ColumnLayoutEngineTests.swift
//  LyraTests
//
//  Tests for ColumnLayoutEngine
//

import Testing
import Foundation
@testable import Lyra

@Suite("ColumnLayoutEngine Tests")
struct ColumnLayoutEngineTests {

    // MARK: - Test Data Helpers

    /// Create a simple test section
    private func createSection(label: String, lineCount: Int, hasChords: Bool = false, type: SectionType = .verse) -> SongSection {
        var lines: [SongLine] = []

        for i in 0..<lineCount {
            if hasChords {
                let segment = LineSegment(text: "Test line \(i)", chord: "C", position: 0)
                lines.append(SongLine(segments: [segment], type: .lyrics, rawText: "Test line \(i)"))
            } else {
                let segment = LineSegment(text: "Test line \(i)", chord: nil, position: 0)
                lines.append(SongLine(segments: [segment], type: .lyrics, rawText: "Test line \(i)"))
            }
        }

        return SongSection(type: type, label: label, lines: lines, index: 1)
    }

    /// Create test sections for distribution
    private func createTestSections() -> [SongSection] {
        return [
            createSection(label: "Verse 1", lineCount: 4, hasChords: true, type: .verse),
            createSection(label: "Chorus", lineCount: 4, hasChords: true, type: .chorus),
            createSection(label: "Verse 2", lineCount: 4, hasChords: true, type: .verse),
            createSection(label: "Bridge", lineCount: 2, hasChords: false, type: .bridge)
        ]
    }

    /// Create a test template
    private func createTemplate(
        columnCount: Int,
        strategy: ColumnBalancingStrategy = .balanced
    ) -> Template {
        return Template(
            name: "Test Template",
            columnCount: columnCount,
            columnGap: 20.0,
            columnBalancingStrategy: strategy
        )
    }

    // MARK: - Basic Tests

    @Test("Empty sections returns empty array")
    func testEmptySections() {
        let template = createTemplate(columnCount: 2)
        let result = ColumnLayoutEngine.distributeContent([], template: template, availableWidth: 600)

        #expect(result.count == 0)
    }

    @Test("Zero columns returns empty array")
    func testZeroColumns() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 0)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 600)

        #expect(result.count == 0)
    }

    @Test("Single column contains all sections")
    func testSingleColumn() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 1)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 600)

        #expect(result.count == 1)
        #expect(result[0].sections.count == sections.count)
        #expect(result[0].index == 0)
    }

    // MARK: - Fill First Strategy Tests

    @Test("Fill first strategy distributes across two columns")
    func testFillFirstStrategy() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 2, strategy: .fillFirst)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 600)

        #expect(result.count == 2)

        let totalSections = result.reduce(0) { $0 + $1.sections.count }
        #expect(totalSections == sections.count)
    }

    @Test("Fill first with three columns")
    func testFillFirstWithThreeColumns() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 3, strategy: .fillFirst)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 900)

        #expect(result.count == 3)

        let totalSections = result.reduce(0) { $0 + $1.sections.count }
        #expect(totalSections == sections.count)
    }

    // MARK: - Balanced Strategy Tests

    @Test("Balanced strategy distributes across two columns")
    func testBalancedStrategy() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 2, strategy: .balanced)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 600)

        #expect(result.count == 2)

        let totalSections = result.reduce(0) { $0 + $1.sections.count }
        #expect(totalSections == sections.count)

        // Verify heights are relatively balanced
        let height0 = ColumnLayoutEngine.estimateTotalHeight(result[0].sections)
        let height1 = ColumnLayoutEngine.estimateTotalHeight(result[1].sections)

        let averageHeight = (height0 + height1) / 2
        #expect(abs(height0 - averageHeight) <= averageHeight * 0.5)
        #expect(abs(height1 - averageHeight) <= averageHeight * 0.5)
    }

    @Test("Balanced strategy with three columns")
    func testBalancedStrategyWithThreeColumns() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 3, strategy: .balanced)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 900)

        #expect(result.count == 3)

        let totalSections = result.reduce(0) { $0 + $1.sections.count }
        #expect(totalSections == sections.count)
    }

    // MARK: - Section-Based Strategy Tests

    @Test("Section-based strategy keeps sections intact")
    func testSectionBasedStrategy() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 2, strategy: .sectionBased)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 600)

        #expect(result.count == 2)

        let totalSections = result.reduce(0) { $0 + $1.sections.count }
        #expect(totalSections == sections.count)

        // Verify sections are kept intact
        for column in result {
            for section in column.sections {
                #expect(sections.contains(where: { $0.id == section.id }))
            }
        }
    }

    @Test("Section-based with three columns")
    func testSectionBasedWithThreeColumns() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 3, strategy: .sectionBased)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 900)

        #expect(result.count == 3)

        let totalSections = result.reduce(0) { $0 + $1.sections.count }
        #expect(totalSections == sections.count)
    }

    @Test("Section-based ensures each section appears exactly once")
    func testSectionBasedKeepsSectionsIntact() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 2, strategy: .sectionBased)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 600)

        var distributedSections: [SongSection] = []
        for column in result {
            distributedSections.append(contentsOf: column.sections)
        }

        for originalSection in sections {
            let count = distributedSections.filter { $0.id == originalSection.id }.count
            #expect(count == 1)
        }
    }

    // MARK: - Height Estimation Tests

    @Test("Estimate section height returns positive value")
    func testEstimateSectionHeight() {
        let section = createSection(label: "Test", lineCount: 4, hasChords: true)
        let height = ColumnLayoutEngine.estimateSectionHeight(section, width: 300)

        #expect(height > 0)
    }

    @Test("Section with chords is taller than section without chords")
    func testSectionWithChordsIsTaller() {
        let sectionWithChords = createSection(label: "Test", lineCount: 4, hasChords: true)
        let sectionNoChords = createSection(label: "Test", lineCount: 4, hasChords: false)

        let heightWithChords = ColumnLayoutEngine.estimateSectionHeight(sectionWithChords, width: 300)
        let heightNoChords = ColumnLayoutEngine.estimateSectionHeight(sectionNoChords, width: 300)

        #expect(heightWithChords > heightNoChords)
    }

    @Test("Estimate total height equals sum of sections")
    func testEstimateTotalHeight() {
        let sections = createTestSections()
        let totalHeight = ColumnLayoutEngine.estimateTotalHeight(sections)

        #expect(totalHeight > 0)

        var sum: CGFloat = 0
        for section in sections {
            sum += ColumnLayoutEngine.estimateSectionHeight(section, width: 300)
        }

        #expect(abs(totalHeight - sum) < 0.1)
    }

    @Test("Empty section still has height for label")
    func testEstimateHeightForEmptySection() {
        let emptySection = createSection(label: "Empty", lineCount: 0)
        let height = ColumnLayoutEngine.estimateSectionHeight(emptySection, width: 300)

        #expect(height > 0)
    }

    // MARK: - Column Content Tests

    @Test("Column content initialization sets properties correctly")
    func testColumnContentInitialization() {
        let sections = createTestSections()
        let column = ColumnContent(index: 0, sections: sections)

        #expect(column.index == 0)
        #expect(column.sections.count == sections.count)
        #expect(!column.isEmpty)
    }

    @Test("Column content line count is sum of section lines")
    func testColumnContentLineCount() {
        let sections = [
            createSection(label: "Verse 1", lineCount: 4),
            createSection(label: "Chorus", lineCount: 3)
        ]
        let column = ColumnContent(index: 0, sections: sections)

        #expect(column.lineCount == 7)
    }

    @Test("Empty column returns true for isEmpty")
    func testColumnContentEmpty() {
        let column = ColumnContent(index: 0, sections: [])

        #expect(column.isEmpty)
        #expect(column.lineCount == 0)
    }

    // MARK: - Edge Cases

    @Test("More columns than sections creates empty columns")
    func testMoreColumnsThanSections() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 10, strategy: .balanced)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 1000)

        #expect(result.count == 10)

        let nonEmptyColumns = result.filter { !$0.isEmpty }
        #expect(nonEmptyColumns.count <= sections.count)
    }

    @Test("Single section with multiple columns")
    func testSingleSectionMultipleColumns() {
        let sections = [createSection(label: "Only Verse", lineCount: 8)]
        let template = createTemplate(columnCount: 3, strategy: .sectionBased)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 900)

        #expect(result.count == 3)

        let nonEmptyColumns = result.filter { !$0.isEmpty }
        #expect(nonEmptyColumns.count == 1)
    }

    @Test("Very wide layout distributes correctly")
    func testVeryWideLayout() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 4, strategy: .balanced)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 2000)

        #expect(result.count == 4)

        let totalSections = result.reduce(0) { $0 + $1.sections.count }
        #expect(totalSections == sections.count)
    }

    @Test("Narrow layout still distributes all sections")
    func testNarrowLayout() {
        let sections = createTestSections()
        let template = createTemplate(columnCount: 2, strategy: .balanced)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 200)

        #expect(result.count == 2)

        let totalSections = result.reduce(0) { $0 + $1.sections.count }
        #expect(totalSections == sections.count)
    }

    // MARK: - Real-World Scenarios

    @Test("Typical song layout with two columns")
    func testTypicalSongLayout() {
        let sections = [
            createSection(label: "Verse 1", lineCount: 8, hasChords: true, type: .verse),
            createSection(label: "Chorus", lineCount: 4, hasChords: true, type: .chorus),
            createSection(label: "Verse 2", lineCount: 8, hasChords: true, type: .verse),
            createSection(label: "Chorus", lineCount: 4, hasChords: true, type: .chorus),
            createSection(label: "Bridge", lineCount: 4, hasChords: true, type: .bridge),
            createSection(label: "Chorus", lineCount: 4, hasChords: true, type: .chorus)
        ]

        let template = createTemplate(columnCount: 2, strategy: .balanced)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 700)

        #expect(result.count == 2)

        let totalSections = result.reduce(0) { $0 + $1.sections.count }
        #expect(totalSections == sections.count)

        #expect(!result[0].isEmpty)
        #expect(!result[1].isEmpty)
    }

    @Test("Long song with three columns")
    func testLongSongWithThreeColumns() {
        var sections: [SongSection] = []
        for i in 1...6 {
            sections.append(createSection(label: "Verse \(i)", lineCount: 6, hasChords: true, type: .verse))
        }

        let template = createTemplate(columnCount: 3, strategy: .sectionBased)
        let result = ColumnLayoutEngine.distributeContent(sections, template: template, availableWidth: 900)

        #expect(result.count == 3)

        let totalSections = result.reduce(0) { $0 + $1.sections.count }
        #expect(totalSections == sections.count)

        for column in result {
            #expect(!column.isEmpty)
        }
    }
}
