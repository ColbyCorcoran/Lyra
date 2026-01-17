//
//  Song+Parsing.swift
//  Lyra
//
//  Extension to integrate ChordPro parsing with Song model
//

import Foundation

extension Song {
    /// Parse the song's content as ChordPro and return structured data
    func parsedContent() -> ParsedSong {
        return ChordProParser.parse(content)
    }

    /// Update song metadata from parsed ChordPro content
    func updateMetadataFromContent() {
        let parsed = parsedContent()

        if let title = parsed.title, self.title.isEmpty {
            self.title = title
        }

        if let artist = parsed.artist {
            self.artist = artist
        }

        if let key = parsed.key {
            self.originalKey = key
            if self.currentKey == nil {
                self.currentKey = key
            }
        }

        if let tempo = parsed.tempo {
            self.tempo = tempo
        }

        if let timeSignature = parsed.timeSignature {
            self.timeSignature = timeSignature
        }

        if let capo = parsed.capo {
            self.capo = capo
        }

        if let copyright = parsed.copyright {
            self.copyright = copyright
        }

        if let ccli = parsed.ccliNumber {
            self.ccliNumber = ccli
        }

        self.modifiedAt = Date()
    }
}

// MARK: - Preview Helper

extension ParsedSong {
    /// Sample ChordPro text for previews and testing
    static var sampleChordPro: String {
        """
        {title: Amazing Grace}
        {artist: John Newton}
        {key: G}
        {tempo: 90}
        {capo: 0}

        {start_of_verse}
        [G]Amazing [G7]grace, how [C]sweet the [G]sound
        That saved a wretch like [D]me
        [G]I once was [G7]lost, but [C]now am [G]found
        Was [Em]blind but [D]now I [G]see
        {end_of_verse}

        {start_of_verse}
        'Twas [G]grace that [G7]taught my [C]heart to [G]fear
        And grace my fears re[D]lieved
        How [G]precious [G7]did that [C]grace ap[G]pear
        The [Em]hour I [D]first be[G]lieved
        {end_of_verse}

        {start_of_chorus}
        [C]My chains are [G]gone, I've been set [Em]free
        My God, my [C]Savior has ransomed [G]me
        And like a [C]flood His mercy [G]reigns
        Unending [Em]love, [D]amazing [G]grace
        {end_of_chorus}
        """
    }

    /// Sample parsed song for previews
    static var sample: ParsedSong {
        ChordProParser.parse(sampleChordPro)
    }
}
