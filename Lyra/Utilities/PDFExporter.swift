//
//  PDFExporter.swift
//  Lyra
//
//  Utility for rendering ChordPro content as formatted PDF
//

import UIKit
import PDFKit

@MainActor
class PDFExporter {

    // MARK: - Configuration

    struct PDFConfiguration {
        var pageSize: CGSize = CGSize(width: 612, height: 792) // US Letter (8.5" x 11")
        var margins: UIEdgeInsets = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72) // 1" margins

        // Typography
        var titleFont: UIFont = .systemFont(ofSize: 24, weight: .bold)
        var artistFont: UIFont = .systemFont(ofSize: 16, weight: .regular)
        var metadataFont: UIFont = .systemFont(ofSize: 14, weight: .medium)
        var chordFont: UIFont = .monospacedSystemFont(ofSize: 14, weight: .bold)
        var lyricsFont: UIFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
        var sectionFont: UIFont = .systemFont(ofSize: 14, weight: .semibold)
        var footerFont: UIFont = .systemFont(ofSize: 10, weight: .regular)

        // Colors
        var chordColor: UIColor = .systemBlue
        var lyricsColor: UIColor = .black
        var sectionColor: UIColor = .darkGray
        var metadataColor: UIColor = .darkGray
        var footerColor: UIColor = .lightGray

        // Spacing
        var lineSpacing: CGFloat = 8
        var chordLineSpacing: CGFloat = 4
        var sectionSpacing: CGFloat = 20
        var metadataSpacing: CGFloat = 12

        // Header/Footer
        var includeHeader: Bool = true
        var includeFooter: Bool = true
        var footerText: String = "Created with Lyra"
    }

    // MARK: - Export Methods

    /// Export a single song as PDF
    static func exportSong(
        _ song: Song,
        configuration: PDFConfiguration = .init()
    ) throws -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: configuration.pageSize))

        let data = renderer.pdfData { context in
            var currentY: CGFloat = configuration.margins.top
            let contentWidth = configuration.pageSize.width - configuration.margins.left - configuration.margins.right

            // Start first page
            context.beginPage()

            // Draw header
            if configuration.includeHeader {
                currentY = drawHeader(
                    song: song,
                    context: context,
                    startY: currentY,
                    contentWidth: contentWidth,
                    margins: configuration.margins,
                    configuration: configuration
                )
            }

            // Parse and draw content
            let lines = parseChordProContent(song.content)

            for line in lines {
                // Check if we need a new page
                let estimatedHeight = estimateLineHeight(line: line, configuration: configuration)
                if currentY + estimatedHeight > configuration.pageSize.height - configuration.margins.bottom - 30 {
                    // Draw footer on current page
                    if configuration.includeFooter {
                        drawFooter(
                            context: context,
                            pageSize: configuration.pageSize,
                            margins: configuration.margins,
                            configuration: configuration
                        )
                    }

                    // Start new page
                    context.beginPage()
                    currentY = configuration.margins.top
                }

                // Draw line
                currentY = drawLine(
                    line: line,
                    context: context,
                    startY: currentY,
                    startX: configuration.margins.left,
                    contentWidth: contentWidth,
                    configuration: configuration
                )
            }

            // Draw footer on last page
            if configuration.includeFooter {
                drawFooter(
                    context: context,
                    pageSize: configuration.pageSize,
                    margins: configuration.margins,
                    configuration: configuration
                )
            }
        }

        return data
    }

    /// Export a performance set as PDF with table of contents
    static func exportSet(
        _ set: PerformanceSet,
        configuration: PDFConfiguration = .init()
    ) throws -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: configuration.pageSize))

        let data = renderer.pdfData { context in
            var currentPage = 1

            // Draw title page
            context.beginPage()
            drawSetTitlePage(
                set: set,
                context: context,
                configuration: configuration
            )
            currentPage += 1

            // Draw table of contents
            context.beginPage()
            _ = drawTableOfContents(
                set: set,
                context: context,
                startPage: currentPage + 1,
                configuration: configuration
            )
            currentPage += 1

            // Draw each song
            guard let sortedEntries = set.sortedSongEntries else { return }

            for entry in sortedEntries {
                guard let song = entry.song else { continue }

                // Start new page for song
                context.beginPage()

                var currentY: CGFloat = configuration.margins.top
                let contentWidth = configuration.pageSize.width - configuration.margins.left - configuration.margins.right

                // Draw song header
                currentY = drawSetSongHeader(
                    song: song,
                    entry: entry,
                    orderIndex: entry.orderIndex,
                    context: context,
                    startY: currentY,
                    contentWidth: contentWidth,
                    margins: configuration.margins,
                    configuration: configuration
                )

                // Draw song content
                let lines = parseChordProContent(song.content)

                for line in lines {
                    // Check if we need a new page
                    let estimatedHeight = estimateLineHeight(line: line, configuration: configuration)
                    if currentY + estimatedHeight > configuration.pageSize.height - configuration.margins.bottom - 30 {
                        // Draw footer
                        drawSetFooter(
                            setName: set.name,
                            pageNumber: currentPage,
                            context: context,
                            pageSize: configuration.pageSize,
                            margins: configuration.margins,
                            configuration: configuration
                        )

                        // Start new page
                        context.beginPage()
                        currentY = configuration.margins.top
                        currentPage += 1
                    }

                    // Draw line
                    currentY = drawLine(
                        line: line,
                        context: context,
                        startY: currentY,
                        startX: configuration.margins.left,
                        contentWidth: contentWidth,
                        configuration: configuration
                    )
                }

                // Draw footer
                drawSetFooter(
                    setName: set.name,
                    pageNumber: currentPage,
                    context: context,
                    pageSize: configuration.pageSize,
                    margins: configuration.margins,
                    configuration: configuration
                )

                currentPage += 1
            }
        }

        return data
    }

    /// Export a book as PDF with cover and table of contents
    static func exportBook(
        _ book: Book,
        configuration: PDFConfiguration = .init()
    ) throws -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: configuration.pageSize))

        let data = renderer.pdfData { context in
            var currentPage = 1

            // Draw cover page
            context.beginPage()
            drawBookCoverPage(
                book: book,
                context: context,
                configuration: configuration
            )
            currentPage += 1

            // Draw table of contents
            context.beginPage()
            drawBookTableOfContents(
                book: book,
                context: context,
                startPage: currentPage + 1,
                configuration: configuration
            )
            currentPage += 1

            // Draw each song
            guard let songs = book.songs?.sorted(by: { $0.title < $1.title }) else { return }

            for song in songs {
                // Start new page for song
                context.beginPage()

                var currentY: CGFloat = configuration.margins.top
                let contentWidth = configuration.pageSize.width - configuration.margins.left - configuration.margins.right

                // Draw song header
                currentY = drawHeader(
                    song: song,
                    context: context,
                    startY: currentY,
                    contentWidth: contentWidth,
                    margins: configuration.margins,
                    configuration: configuration
                )

                // Draw song content
                let lines = parseChordProContent(song.content)

                for line in lines {
                    // Check if we need a new page
                    let estimatedHeight = estimateLineHeight(line: line, configuration: configuration)
                    if currentY + estimatedHeight > configuration.pageSize.height - configuration.margins.bottom - 30 {
                        // Draw footer
                        drawBookFooter(
                            bookName: book.name,
                            pageNumber: currentPage,
                            context: context,
                            pageSize: configuration.pageSize,
                            margins: configuration.margins,
                            configuration: configuration
                        )

                        // Start new page
                        context.beginPage()
                        currentY = configuration.margins.top
                        currentPage += 1
                    }

                    // Draw line
                    currentY = drawLine(
                        line: line,
                        context: context,
                        startY: currentY,
                        startX: configuration.margins.left,
                        contentWidth: contentWidth,
                        configuration: configuration
                    )
                }

                // Draw footer
                drawBookFooter(
                    bookName: book.name,
                    pageNumber: currentPage,
                    context: context,
                    pageSize: configuration.pageSize,
                    margins: configuration.margins,
                    configuration: configuration
                )

                currentPage += 1
            }
        }

        return data
    }

    // MARK: - Content Parsing

    enum ParsedLine {
        case title(String)
        case metadata(String)
        case section(String)
        case chordLine(String)
        case lyricsLine(String)
        case chordLyrics(chords: String, lyrics: String)
        case empty
    }

    private static func parseChordProContent(_ content: String) -> [ParsedLine] {
        var lines: [ParsedLine] = []
        let contentLines = content.components(separatedBy: .newlines)

        var previousLineWasChords = false
        var previousChordLine: String?

        for line in contentLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip ChordPro directives (already handled in header)
            if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
                continue
            }

            // Empty line
            if trimmed.isEmpty {
                lines.append(.empty)
                previousLineWasChords = false
                previousChordLine = nil
                continue
            }

            // Section markers [Verse], [Chorus], etc.
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") && !trimmed.contains(":") {
                let section = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                lines.append(.section(section))
                previousLineWasChords = false
                previousChordLine = nil
                continue
            }

            // Check if line contains chords
            let hasChords = trimmed.contains("[") && trimmed.contains("]")

            if hasChords {
                // Extract chords and lyrics
                let (chords, lyrics) = extractChordsAndLyrics(from: trimmed)

                if lyrics.trimmingCharacters(in: .whitespaces).isEmpty {
                    // Chords only line
                    previousLineWasChords = true
                    previousChordLine = chords
                } else {
                    // Chords and lyrics in same line
                    lines.append(.chordLyrics(chords: chords, lyrics: lyrics))
                    previousLineWasChords = false
                    previousChordLine = nil
                }
            } else {
                // No chords in this line
                if previousLineWasChords, let chordLine = previousChordLine {
                    // This is lyrics for the previous chord line
                    lines.append(.chordLyrics(chords: chordLine, lyrics: trimmed))
                    previousLineWasChords = false
                    previousChordLine = nil
                } else {
                    // Plain lyrics line
                    lines.append(.lyricsLine(trimmed))
                }
            }
        }

        return lines
    }

    private static func extractChordsAndLyrics(from line: String) -> (chords: String, lyrics: String) {
        var chords: [(position: Int, chord: String)] = []
        var lyrics = line

        // Find all chord patterns [...]
        let pattern = "\\[([^\\]]+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return ("", line)
        }

        let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))

        // Extract chords and their positions
        var offset = 0
        for match in matches {
            if let chordRange = Range(match.range(at: 1), in: line) {
                let chord = String(line[chordRange])
                let position = match.range.location - offset
                chords.append((position: position, chord: chord))
            }

            // Remove chord from lyrics
            if let fullRange = Range(match.range, in: lyrics) {
                lyrics.replaceSubrange(fullRange, with: "")
                offset += match.range.length
            }
        }

        // Build chord line with proper spacing
        var chordLine = ""

        for (position, chord) in chords {
            // Add spaces to position
            while chordLine.count < position {
                chordLine += " "
            }
            chordLine += chord
        }

        return (chordLine, lyrics)
    }

    // MARK: - Drawing Methods

    private static func drawHeader(
        song: Song,
        context: UIGraphicsPDFRendererContext,
        startY: CGFloat,
        contentWidth: CGFloat,
        margins: UIEdgeInsets,
        configuration: PDFConfiguration
    ) -> CGFloat {
        var currentY = startY

        // Draw title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: configuration.titleFont,
            .foregroundColor: UIColor.black
        ]
        let titleSize = song.title.size(withAttributes: titleAttributes)
        song.title.draw(
            at: CGPoint(x: margins.left, y: currentY),
            withAttributes: titleAttributes
        )
        currentY += titleSize.height + 8

        // Draw artist
        if let artist = song.artist {
            let artistAttributes: [NSAttributedString.Key: Any] = [
                .font: configuration.artistFont,
                .foregroundColor: configuration.metadataColor
            ]
            let artistSize = artist.size(withAttributes: artistAttributes)
            artist.draw(
                at: CGPoint(x: margins.left, y: currentY),
                withAttributes: artistAttributes
            )
            currentY += artistSize.height + configuration.metadataSpacing
        }

        // Draw metadata row (key, tempo, time signature)
        var metadataItems: [String] = []
        if let key = song.currentKey {
            metadataItems.append("Key: \(key)")
        }
        if let tempo = song.tempo {
            metadataItems.append("Tempo: \(tempo) BPM")
        }
        if let timeSignature = song.timeSignature {
            metadataItems.append("Time: \(timeSignature)")
        }

        if !metadataItems.isEmpty {
            let metadataText = metadataItems.joined(separator: "  •  ")
            let metadataAttributes: [NSAttributedString.Key: Any] = [
                .font: configuration.metadataFont,
                .foregroundColor: configuration.metadataColor
            ]
            let metadataSize = metadataText.size(withAttributes: metadataAttributes)
            metadataText.draw(
                at: CGPoint(x: margins.left, y: currentY),
                withAttributes: metadataAttributes
            )
            currentY += metadataSize.height + configuration.metadataSpacing
        }

        // Draw separator line
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margins.left, y: currentY))
        linePath.addLine(to: CGPoint(x: margins.left + contentWidth, y: currentY))
        configuration.metadataColor.setStroke()
        linePath.lineWidth = 0.5
        linePath.stroke()
        currentY += 20

        return currentY
    }

    private static func drawSetSongHeader(
        song: Song,
        entry: SetEntry,
        orderIndex: Int,
        context: UIGraphicsPDFRendererContext,
        startY: CGFloat,
        contentWidth: CGFloat,
        margins: UIEdgeInsets,
        configuration: PDFConfiguration
    ) -> CGFloat {
        var currentY = startY

        // Draw song number
        let numberText = "\(orderIndex + 1)."
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: configuration.titleFont,
            .foregroundColor: configuration.metadataColor
        ]
        let numberSize = numberText.size(withAttributes: numberAttributes)
        numberText.draw(
            at: CGPoint(x: margins.left, y: currentY),
            withAttributes: numberAttributes
        )

        // Draw title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: configuration.titleFont,
            .foregroundColor: UIColor.black
        ]
        let titleSize = song.title.size(withAttributes: titleAttributes)
        song.title.draw(
            at: CGPoint(x: margins.left + numberSize.width + 10, y: currentY),
            withAttributes: titleAttributes
        )
        currentY += titleSize.height + 8

        // Draw key override if present
        let key = entry.keyOverride ?? song.currentKey
        if let key = key {
            let keyText = "Key: \(key)"
            let keyAttributes: [NSAttributedString.Key: Any] = [
                .font: configuration.metadataFont,
                .foregroundColor: configuration.metadataColor
            ]
            let keySize = keyText.size(withAttributes: keyAttributes)
            keyText.draw(
                at: CGPoint(x: margins.left, y: currentY),
                withAttributes: keyAttributes
            )
            currentY += keySize.height + 8
        }

        // Draw entry notes if present
        if let notes = entry.notes, !notes.isEmpty {
            let notesText = "Notes: \(notes)"
            let notesAttributes: [NSAttributedString.Key: Any] = [
                .font: configuration.metadataFont.italic(),
                .foregroundColor: configuration.metadataColor
            ]
            let notesSize = notesText.size(withAttributes: notesAttributes)
            notesText.draw(
                at: CGPoint(x: margins.left, y: currentY),
                withAttributes: notesAttributes
            )
            currentY += notesSize.height + configuration.metadataSpacing
        }

        currentY += 10

        return currentY
    }

    private static func drawLine(
        line: ParsedLine,
        context: UIGraphicsPDFRendererContext,
        startY: CGFloat,
        startX: CGFloat,
        contentWidth: CGFloat,
        configuration: PDFConfiguration
    ) -> CGFloat {
        var currentY = startY

        switch line {
        case .empty:
            currentY += configuration.lineSpacing

        case .section(let text):
            let attributes: [NSAttributedString.Key: Any] = [
                .font: configuration.sectionFont,
                .foregroundColor: configuration.sectionColor
            ]
            let size = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(x: startX, y: currentY),
                withAttributes: attributes
            )
            currentY += size.height + configuration.sectionSpacing

        case .lyricsLine(let text):
            let attributes: [NSAttributedString.Key: Any] = [
                .font: configuration.lyricsFont,
                .foregroundColor: configuration.lyricsColor
            ]
            let size = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(x: startX, y: currentY),
                withAttributes: attributes
            )
            currentY += size.height + configuration.lineSpacing

        case .chordLine(let text):
            let attributes: [NSAttributedString.Key: Any] = [
                .font: configuration.chordFont,
                .foregroundColor: configuration.chordColor
            ]
            let size = text.size(withAttributes: attributes)
            text.draw(
                at: CGPoint(x: startX, y: currentY),
                withAttributes: attributes
            )
            currentY += size.height + configuration.chordLineSpacing

        case .chordLyrics(let chords, let lyrics):
            // Draw chords
            let chordAttributes: [NSAttributedString.Key: Any] = [
                .font: configuration.chordFont,
                .foregroundColor: configuration.chordColor
            ]
            let chordSize = chords.size(withAttributes: chordAttributes)
            chords.draw(
                at: CGPoint(x: startX, y: currentY),
                withAttributes: chordAttributes
            )
            currentY += chordSize.height + configuration.chordLineSpacing

            // Draw lyrics
            let lyricsAttributes: [NSAttributedString.Key: Any] = [
                .font: configuration.lyricsFont,
                .foregroundColor: configuration.lyricsColor
            ]
            let lyricsSize = lyrics.size(withAttributes: lyricsAttributes)
            lyrics.draw(
                at: CGPoint(x: startX, y: currentY),
                withAttributes: lyricsAttributes
            )
            currentY += lyricsSize.height + configuration.lineSpacing

        case .title, .metadata:
            break
        }

        return currentY
    }

    private static func drawFooter(
        context: UIGraphicsPDFRendererContext,
        pageSize: CGSize,
        margins: UIEdgeInsets,
        configuration: PDFConfiguration
    ) {
        let footerY = pageSize.height - margins.bottom + 10

        let attributes: [NSAttributedString.Key: Any] = [
            .font: configuration.footerFont,
            .foregroundColor: configuration.footerColor
        ]

        let size = configuration.footerText.size(withAttributes: attributes)
        let x = (pageSize.width - size.width) / 2

        configuration.footerText.draw(
            at: CGPoint(x: x, y: footerY),
            withAttributes: attributes
        )
    }

    private static func drawSetFooter(
        setName: String,
        pageNumber: Int,
        context: UIGraphicsPDFRendererContext,
        pageSize: CGSize,
        margins: UIEdgeInsets,
        configuration: PDFConfiguration
    ) {
        let footerY = pageSize.height - margins.bottom + 10

        let attributes: [NSAttributedString.Key: Any] = [
            .font: configuration.footerFont,
            .foregroundColor: configuration.footerColor
        ]

        // Left: Set name
        setName.draw(
            at: CGPoint(x: margins.left, y: footerY),
            withAttributes: attributes
        )

        // Right: Page number
        let pageText = "Page \(pageNumber)"
        let pageSize = pageText.size(withAttributes: attributes)
        pageText.draw(
            at: CGPoint(x: pageSize.width - margins.right - pageSize.width, y: footerY),
            withAttributes: attributes
        )
    }

    private static func drawBookFooter(
        bookName: String,
        pageNumber: Int,
        context: UIGraphicsPDFRendererContext,
        pageSize: CGSize,
        margins: UIEdgeInsets,
        configuration: PDFConfiguration
    ) {
        let footerY = pageSize.height - margins.bottom + 10

        let attributes: [NSAttributedString.Key: Any] = [
            .font: configuration.footerFont,
            .foregroundColor: configuration.footerColor
        ]

        // Left: Book name
        bookName.draw(
            at: CGPoint(x: margins.left, y: footerY),
            withAttributes: attributes
        )

        // Right: Page number
        let pageText = "Page \(pageNumber)"
        let pageSizeCalc = pageText.size(withAttributes: attributes)
        pageText.draw(
            at: CGPoint(x: pageSize.width - margins.right - pageSizeCalc.width, y: footerY),
            withAttributes: attributes
        )
    }

    private static func drawSetTitlePage(
        set: PerformanceSet,
        context: UIGraphicsPDFRendererContext,
        configuration: PDFConfiguration
    ) {
        let centerX = configuration.pageSize.width / 2
        var currentY = configuration.pageSize.height / 3

        // Draw set name
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let titleSize = set.name.size(withAttributes: titleAttributes)
        set.name.draw(
            at: CGPoint(x: centerX - titleSize.width / 2, y: currentY),
            withAttributes: titleAttributes
        )
        currentY += titleSize.height + 30

        // Draw date
        if let date = set.scheduledDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            let dateText = dateFormatter.string(from: date)

            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let dateSize = dateText.size(withAttributes: dateAttributes)
            dateText.draw(
                at: CGPoint(x: centerX - dateSize.width / 2, y: currentY),
                withAttributes: dateAttributes
            )
            currentY += dateSize.height + 20
        }

        // Draw venue
        if let venue = set.venue {
            let venueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let venueSize = venue.size(withAttributes: venueAttributes)
            venue.draw(
                at: CGPoint(x: centerX - venueSize.width / 2, y: currentY),
                withAttributes: venueAttributes
            )
        }
    }

    private static func drawTableOfContents(
        set: PerformanceSet,
        context: UIGraphicsPDFRendererContext,
        startPage: Int,
        configuration: PDFConfiguration
    ) -> [Int: Int] {
        var currentY: CGFloat = configuration.margins.top
        var pageMap: [Int: Int] = [:]
        var currentPage = startPage

        // Draw TOC title
        let tocTitle = "Set List"
        let tocAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let tocSize = tocTitle.size(withAttributes: tocAttributes)
        tocTitle.draw(
            at: CGPoint(x: configuration.margins.left, y: currentY),
            withAttributes: tocAttributes
        )
        currentY += tocSize.height + 30

        // Draw song entries
        guard let sortedEntries = set.sortedSongEntries else { return pageMap }

        for entry in sortedEntries {
            guard let song = entry.song else { continue }

            pageMap[entry.orderIndex] = currentPage

            let entryText = "\(entry.orderIndex + 1). \(song.title)"
            let pageText = "\(currentPage)"

            let entryAttributes: [NSAttributedString.Key: Any] = [
                .font: configuration.lyricsFont,
                .foregroundColor: UIColor.black
            ]

            // Draw song title
            entryText.draw(
                at: CGPoint(x: configuration.margins.left, y: currentY),
                withAttributes: entryAttributes
            )

            // Draw page number (right-aligned)
            let pageSize = pageText.size(withAttributes: entryAttributes)
            pageText.draw(
                at: CGPoint(x: configuration.pageSize.width - configuration.margins.right - pageSize.width, y: currentY),
                withAttributes: entryAttributes
            )

            currentY += (entryAttributes[.font] as! UIFont).pointSize + 15
            currentPage += 1
        }

        return pageMap
    }

    private static func drawBookCoverPage(
        book: Book,
        context: UIGraphicsPDFRendererContext,
        configuration: PDFConfiguration
    ) {
        let centerX = configuration.pageSize.width / 2
        var currentY = configuration.pageSize.height / 3

        // Draw book name
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let titleSize = book.name.size(withAttributes: titleAttributes)
        book.name.draw(
            at: CGPoint(x: centerX - titleSize.width / 2, y: currentY),
            withAttributes: titleAttributes
        )
        currentY += titleSize.height + 20

        // Draw description
        if let description = book.bookDescription {
            let descAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let descSize = description.size(withAttributes: descAttributes)
            description.draw(
                at: CGPoint(x: centerX - descSize.width / 2, y: currentY),
                withAttributes: descAttributes
            )
            currentY += descSize.height + 30
        }

        // Draw song count
        if let songCount = book.songs?.count {
            let countText = "\(songCount) Songs"
            let countAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            let countSize = countText.size(withAttributes: countAttributes)
            countText.draw(
                at: CGPoint(x: centerX - countSize.width / 2, y: currentY),
                withAttributes: countAttributes
            )
        }
    }

    private static func drawBookTableOfContents(
        book: Book,
        context: UIGraphicsPDFRendererContext,
        startPage: Int,
        configuration: PDFConfiguration
    ) {
        var currentY: CGFloat = configuration.margins.top

        // Draw TOC title
        let tocTitle = "Table of Contents"
        let tocAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let tocSize = tocTitle.size(withAttributes: tocAttributes)
        tocTitle.draw(
            at: CGPoint(x: configuration.margins.left, y: currentY),
            withAttributes: tocAttributes
        )
        currentY += tocSize.height + 30

        // Draw songs
        guard let songs = book.songs?.sorted(by: { $0.title < $1.title }) else { return }

        var currentPage = startPage
        for song in songs {
            let entryText = song.title
            let pageText = "\(currentPage)"

            let entryAttributes: [NSAttributedString.Key: Any] = [
                .font: configuration.lyricsFont,
                .foregroundColor: UIColor.black
            ]

            // Draw song title
            entryText.draw(
                at: CGPoint(x: configuration.margins.left, y: currentY),
                withAttributes: entryAttributes
            )

            // Draw page number (right-aligned)
            let pageSize = pageText.size(withAttributes: entryAttributes)
            pageText.draw(
                at: CGPoint(x: configuration.pageSize.width - configuration.margins.right - pageSize.width, y: currentY),
                withAttributes: entryAttributes
            )

            currentY += (entryAttributes[.font] as! UIFont).pointSize + 15
            currentPage += 1
        }
    }

    private static func estimateLineHeight(line: ParsedLine, configuration: PDFConfiguration) -> CGFloat {
        switch line {
        case .empty:
            return configuration.lineSpacing
        case .section:
            return configuration.sectionFont.pointSize + configuration.sectionSpacing
        case .lyricsLine:
            return configuration.lyricsFont.pointSize + configuration.lineSpacing
        case .chordLine:
            return configuration.chordFont.pointSize + configuration.chordLineSpacing
        case .chordLyrics:
            return configuration.chordFont.pointSize + configuration.chordLineSpacing +
                   configuration.lyricsFont.pointSize + configuration.lineSpacing
        case .title:
            return configuration.titleFont.pointSize + 8
        case .metadata:
            return configuration.metadataFont.pointSize + configuration.metadataSpacing
        }
    }
}

// MARK: - UIFont Extension

extension UIFont {
    func italic() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic)
        return UIFont(descriptor: descriptor ?? fontDescriptor, size: pointSize)
    }
}
