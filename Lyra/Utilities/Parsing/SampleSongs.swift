//
//  SampleSongs.swift
//  Lyra
//
//  Sample ChordPro songs for testing and development
//

import Foundation

enum SampleChordProSongs {

    static let amazingGrace = """
    {title: Amazing Grace}
    {artist: John Newton}
    {key: G}
    {tempo: 90}
    {time: 3/4}

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

    static let blestBeTheTie = """
    {title: Blest Be the Tie}
    {subtitle: That Binds}
    {artist: John Fawcett}
    {key: D}
    {tempo: 80}
    {capo: 0}

    {verse}
    [D]Blest be the [A]tie that [D]binds
    Our [A]hearts in [D]Christian [A]love
    The [D]fellowship of [A]kindred [Bm]minds
    Is [D]like to [A]that a[D]bove

    {verse}
    Be[D]fore our [A]Father's [D]throne
    We [A]pour our [D]ardent [A]prayers
    Our [D]fears, our [A]hopes, our [Bm]aims are one
    Our [D]comforts [A]and our [D]cares
    """

    static let howGreatThouArt = """
    {title: How Great Thou Art}
    {artist: Carl Boberg}
    {key: C}
    {tempo: 70}
    {copyright: Public Domain}

    {start_of_verse}
    [C]O Lord my God, when I in awesome wonder
    [F]Consider [C]all the worlds thy hands have [G]made
    I [C]see the stars, I hear the rolling thunder
    Thy [F]power through[C]out the uni[G]verse dis[C]played

    {start_of_chorus}
    Then sings my [C]soul, my [F]Savior [C]God, to thee
    How great thou [Am]art, [G]how great thou [C]art
    Then sings my soul, my [F]Savior [C]God, to thee
    How [F]great thou [C]art, [G]how great thou [C]art

    {verse}
    When through the woods and forest glades I wander
    And [F]hear the [C]birds sing sweetly in the [G]trees
    When [C]I look down from lofty mountain grandeur
    And [F]hear the [C]brook and [G]feel the gentle [C]breeze
    """

    static let inlineChords = """
    {title: Inline Chord Test}
    {key: G}

    {verse}
    Ama[G]zing gr[C]ace how [G]sweet the [D]sound
    That sa[G]ved a wr[C]etch like [G]me[D]

    {chorus}
    I [G]once was [C]lost but [G]now am [D]found
    Was [G]blind but [C]now I [G]see
    """

    static let separateChordsExample = """
    {title: Separate Chords Example}
    {artist: Test Artist}
    {key: C}

    {verse}
    [C]    [F]    [G]    [C]
    Amazing grace how sweet the sound
    [Am]   [F]    [G]
    That saved a wretch like me
    """

    static let complexExample = """
    {title: Complex Test Song}
    {subtitle: With All Features}
    {artist: Test Composer}
    {album: Test Album}
    {key: D}
    {tempo: 120}
    {time: 4/4}
    {capo: 2}
    {year: 2023}
    {copyright: Copyright 2023}
    {ccli: 7654321}

    # This is a comment about the intro
    {start_of_intro}
    [D] [A] [Bm] [G]
    {end_of_intro}

    {comment: First verse is slower}
    {start_of_verse}
    [D]First line with [A]inline chords
    And a [Bm]second line [G]too
    {end_of_verse}

    {start_of_prechorus}
    [Em]Building [A]up to the [D]chorus
    {end_of_prechorus}

    {start_of_chorus}
    [D]This is the [A]chorus line
    [Bm]Sung with [G]feeling
    {end_of_chorus}

    {start_of_bridge}
    [Em]Bridge section [A]here
    With [D]different [Bm]chords
    {end_of_bridge}

    {c: Repeat chorus twice}
    {chorus}
    [D]This is the [A]chorus line
    [Bm]Sung with [G]feeling

    {start_of_outro}
    [D] [A] [D]
    {end_of_outro}
    """

    static let minimalExample = """
    {title: Minimal Song}

    Just lyrics without chords
    Second line
    """

    static let malformedExample = """
    {title: Malformed Test
    [Unclosed chord
    Missing closing brace
    {unknown_directive: value}

    {verse}
    But still [G]has some [C]valid content
    """

    // Helper to get all sample songs
    static var all: [String: String] {
        return [
            "Amazing Grace": amazingGrace,
            "Blest Be the Tie": blestBeTheTie,
            "How Great Thou Art": howGreatThouArt,
            "Inline Chords": inlineChords,
            "Separate Chords": separateChordsExample,
            "Complex": complexExample,
            "Minimal": minimalExample,
            "Malformed": malformedExample
        ]
    }
}
