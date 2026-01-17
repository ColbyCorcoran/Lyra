# Lyra Phase 1 - Production Checklist

## Pre-Release Testing Checklist

### Device Testing

#### iPhone Testing
- [ ] iPhone 15 Pro Max (6.7" display)
  - [ ] All features working
  - [ ] Layouts look good
  - [ ] Performance smooth

- [ ] iPhone 15 Pro (6.1" display)
  - [ ] Standard size testing
  - [ ] Most common device

- [ ] iPhone SE (4.7" display)
  - [ ] Small screen layouts
  - [ ] Keyboard doesn't hide content
  - [ ] All buttons reachable

#### iPad Testing
- [ ] iPad Pro 12.9"
  - [ ] Layouts adapt properly
  - [ ] Uses screen space well
  - [ ] Navigation makes sense

- [ ] iPad Air/Mini
  - [ ] Medium tablet size
  - [ ] Split view compatible (future)

### iOS Version Testing
- [ ] iOS 17.0 (minimum supported)
- [ ] iOS 17.5
- [ ] iOS 18.0 (latest)

### Display Mode Testing

#### Light Mode
- [ ] All views visible
- [ ] Text readable
- [ ] Colors appropriate
- [ ] Shadows visible
- [ ] No white-on-white

#### Dark Mode
- [ ] All views visible
- [ ] Text readable
- [ ] Colors appropriate
- [ ] Shadows visible
- [ ] Sufficient contrast
- [ ] Chord colors work
- [ ] Lyrics colors work

### Accessibility Testing

#### VoiceOver
- [ ] All buttons labeled
- [ ] All images have alt text
- [ ] Navigation works
- [ ] Song rows announce correctly
- [ ] Color swatches announce selection
- [ ] Sliders announce values
- [ ] Hints provided where helpful

#### Dynamic Type
- [ ] Smallest text size (XS)
  - [ ] All text visible
  - [ ] No truncation
  - [ ] Layouts intact

- [ ] Largest text size (XXXL)
  - [ ] All text scales
  - [ ] Buttons readable
  - [ ] No layout breakage
  - [ ] Scrolling works

#### Contrast Ratios
- [ ] All text meets WCAG AA (4.5:1)
- [ ] Large text meets WCAG AAA (3:1)
- [ ] Interactive elements visible
- [ ] Focus indicators clear

#### Other Accessibility
- [ ] Reduced motion respected
- [ ] Increase contrast supported
- [ ] Button shapes work
- [ ] Bold text compatible

### Feature Testing

#### Song Management
- [ ] Create song manually
  - [ ] All fields save
  - [ ] Validation works
  - [ ] Character count accurate
  - [ ] Cancel discards changes

- [ ] View song
  - [ ] Displays correctly
  - [ ] Chords aligned
  - [ ] Metadata shown
  - [ ] Scrolling smooth

- [ ] Delete song
  - [ ] Swipe to delete works
  - [ ] Confirmation shown (future)
  - [ ] Song removed from list
  - [ ] No crashes

#### Import Feature
- [ ] Import .txt file
  - [ ] File picker shows
  - [ ] Selection works
  - [ ] Import succeeds
  - [ ] Song appears in list

- [ ] Import .cho file
  - [ ] Parses correctly
  - [ ] Metadata extracted
  - [ ] Content preserved

- [ ] Import .chordpro file
  - [ ] Works identically

- [ ] Import from iCloud Drive
  - [ ] Can browse iCloud
  - [ ] Import works

- [ ] Import from other providers
  - [ ] Dropbox (if installed)
  - [ ] Google Drive (if installed)

- [ ] Import errors
  - [ ] Empty file shows error
  - [ ] Invalid file shows error
  - [ ] Plain text fallback offered
  - [ ] Error messages clear

#### Paste Feature
- [ ] Paste with ChordPro
  - [ ] Button enabled when clipboard has text
  - [ ] Parse succeeds
  - [ ] Toast shows
  - [ ] Navigation works
  - [ ] Song created

- [ ] Paste without ChordPro
  - [ ] Plain text imported
  - [ ] Title extracted
  - [ ] Content saved

- [ ] Paste empty clipboard
  - [ ] Button disabled
  - [ ] No action on tap

- [ ] Paste errors
  - [ ] Empty content error shown
  - [ ] Recovery suggested

#### Display Customization
- [ ] Per-song settings
  - [ ] Sheet opens
  - [ ] Font size changes apply
  - [ ] Chord color changes apply
  - [ ] Lyrics color changes apply
  - [ ] Spacing changes apply
  - [ ] Real-time preview works
  - [ ] Save persists settings
  - [ ] Cancel discards changes

- [ ] Global defaults
  - [ ] Settings tab works
  - [ ] Changes save automatically
  - [ ] New songs use defaults
  - [ ] Existing songs unaffected (unless no custom)

- [ ] Set as default
  - [ ] Applies to global settings
  - [ ] Verified in Settings tab

- [ ] Reset to defaults
  - [ ] Reverts to factory defaults
  - [ ] Works in song sheet
  - [ ] Works in Settings tab

- [ ] Remove custom settings
  - [ ] Clears per-song settings
  - [ ] Song uses global defaults
  - [ ] Button only shows when applicable

#### Search & Sort
- [ ] Search
  - [ ] Search bar appears
  - [ ] Filters in real-time
  - [ ] Matches title
  - [ ] Matches artist
  - [ ] Clear button works
  - [ ] Cancel works

- [ ] Sort options
  - [ ] Title A-Z works
  - [ ] Title Z-A works
  - [ ] Artist A-Z works
  - [ ] Recently Added works
  - [ ] Recently Viewed works
  - [ ] Selection persists

#### Navigation
- [ ] Library tabs
  - [ ] All Songs tab works
  - [ ] Books tab (placeholder)
  - [ ] Sets tab (placeholder)
  - [ ] Tab selection persists

- [ ] Song → Detail → Back
  - [ ] Navigation smooth
  - [ ] Back button works
  - [ ] Swipe back works
  - [ ] State preserved

- [ ] Navigation during operations
  - [ ] Can't navigate while sheet open
  - [ ] Import navigation works
  - [ ] Paste navigation works

#### Performance
- [ ] App launch
  - [ ] < 1 second on device
  - [ ] No visible lag
  - [ ] Splash screen appropriate

- [ ] Song list
  - [ ] Loads quickly (100 songs)
  - [ ] Scrolling smooth (60fps)
  - [ ] Search responsive
  - [ ] Sort instant

- [ ] Song display
  - [ ] Opens quickly
  - [ ] Renders correctly
  - [ ] Scrolling smooth
  - [ ] Large songs (1000+ lines) work

- [ ] Memory usage
  - [ ] Stable over time
  - [ ] No leaks detected
  - [ ] < 100 MB with 100 songs

### Error Handling

#### All Errors
- [ ] Have clear messages
- [ ] Suggest recovery actions
- [ ] Allow retry where appropriate
- [ ] Don't crash the app

#### Specific Scenarios
- [ ] File not found
- [ ] File not readable
- [ ] Invalid encoding
- [ ] Empty content
- [ ] Parsing failed
- [ ] Save failed
- [ ] Network unavailable (future)

### User Experience

#### Haptic Feedback
- [ ] Button taps have feedback
- [ ] Success operations have success haptic
- [ ] Errors have error haptic
- [ ] Color selection has selection haptic
- [ ] Swipe actions have haptic

#### Loading States
- [ ] Import shows progress
- [ ] Paste shows loading (if slow)
- [ ] Large file parsing shows indicator
- [ ] Save operations show activity (if slow)

#### Animations
- [ ] Sheet transitions smooth
- [ ] Toast appearance smooth
- [ ] List updates animated
- [ ] Navigation transitions smooth
- [ ] No janky animations

#### Feedback
- [ ] All actions have visual feedback
- [ ] Success states clear
- [ ] Error states obvious
- [ ] In-progress states shown

### Code Quality

#### Swift
- [ ] No compiler warnings
- [ ] No force unwraps in production code
- [ ] All errors handled explicitly
- [ ] No silent failures (try?)
- [ ] SwiftLint clean (if configured)

#### SwiftUI
- [ ] No unnecessary re-renders
- [ ] State management correct
- [ ] Environment objects used properly
- [ ] No retain cycles

#### SwiftData
- [ ] Queries optimized
- [ ] No N+1 query issues
- [ ] Saves are explicit
- [ ] Errors handled

### Documentation

#### User-Facing
- [ ] README.md complete
- [ ] USAGE.md current
- [ ] Feature docs accurate
- [ ] Testing guides current

#### Developer-Facing
- [ ] Code comments clear
- [ ] Complex logic explained
- [ ] Architecture documented
- [ ] API usage documented

### App Store Readiness

#### App Info
- [ ] Bundle identifier set
- [ ] Version number set (1.0.0)
- [ ] Build number set (1)
- [ ] Deployment target set (iOS 17.0)

#### Icons & Assets
- [ ] App icon designed (1024x1024)
- [ ] All required sizes included
- [ ] Launch screen configured
- [ ] SF Symbols used correctly

#### Privacy
- [ ] Privacy manifest created (if needed)
- [ ] Clipboard usage justified
- [ ] File access justified
- [ ] No tracking

#### Legal
- [ ] Copyright notices
- [ ] Open source licenses (if applicable)
- [ ] Terms of Service (if applicable)

### Final Review

#### User Flow Testing
Complete these flows 3 times each:

1. **First Time User**
   - [ ] Launch app
   - [ ] See empty state
   - [ ] Tap "Add Song" button
   - [ ] Create first song
   - [ ] View song
   - [ ] Go back
   - [ ] See song in list

2. **Import Flow**
   - [ ] Tap Import button
   - [ ] Browse to file
   - [ ] Select ChordPro file
   - [ ] Import succeeds
   - [ ] Tap "View Song"
   - [ ] Song displays correctly
   - [ ] Go back
   - [ ] Song in list

3. **Paste Flow**
   - [ ] Copy ChordPro content
   - [ ] Open Lyra
   - [ ] Tap Paste button
   - [ ] Toast appears
   - [ ] Song opens automatically
   - [ ] Content correct
   - [ ] Go back
   - [ ] Song in list

4. **Customize Display**
   - [ ] Open any song
   - [ ] Tap "AA" button
   - [ ] Change font to 24
   - [ ] Change chords to red
   - [ ] Tap "Done"
   - [ ] Changes applied
   - [ ] Go back and reopen
   - [ ] Settings persisted

5. **Search & View**
   - [ ] Have 10+ songs
   - [ ] Tap search bar
   - [ ] Type partial title
   - [ ] Results filter
   - [ ] Tap result
   - [ ] Song opens
   - [ ] Go back
   - [ ] Clear search

#### Stress Testing
- [ ] Import 50 songs
  - [ ] App stable
  - [ ] Performance good
  - [ ] Memory reasonable

- [ ] Import very large file (100KB+)
  - [ ] Loading indicator shows
  - [ ] Import succeeds
  - [ ] Display works

- [ ] Rapid navigation
  - [ ] Open/close 20 songs quickly
  - [ ] No crashes
  - [ ] No memory leaks

- [ ] Rapid searching
  - [ ] Type/delete repeatedly
  - [ ] Performance steady
  - [ ] Results accurate

### Sign-Off

#### Development Team
- [ ] Developer sign-off
- [ ] Code review complete
- [ ] All tests passing

#### Design Review
- [ ] UI/UX approved
- [ ] Accessibility verified
- [ ] Branding correct

#### QA Review
- [ ] Manual testing complete
- [ ] All bugs fixed
- [ ] Edge cases handled

#### Final Approval
- [ ] Ready for TestFlight
- [ ] Ready for App Store submission
- [ ] Release notes prepared

---

## Notes & Issues

### Known Issues
(Document any known issues here before release)

### Future Improvements
(Document features planned for next version)

### Testing Notes
(Add notes during testing)

---

## Sign-Off

**Date:** _______________

**Tested By:** _______________

**Status:** ☐ Ready for Release  ☐ Needs Work

**Notes:**

---

## Post-Release Checklist

### TestFlight
- [ ] Build uploaded
- [ ] Beta testers invited
- [ ] Feedback collected
- [ ] Issues addressed

### App Store
- [ ] Listing complete
- [ ] Screenshots uploaded
- [ ] Description written
- [ ] Keywords optimized
- [ ] Submitted for review

### Launch
- [ ] App approved
- [ ] Released to App Store
- [ ] Social media announced
- [ ] Website updated

### Monitoring
- [ ] Crash reports monitored
- [ ] User feedback reviewed
- [ ] Analytics tracking
- [ ] Bug reports triaged

Use this checklist to ensure Lyra is production-ready and polished before release!
