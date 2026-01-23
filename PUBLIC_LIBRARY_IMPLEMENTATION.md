# Public Song Library Implementation

## Overview

The Public Song Library enables Lyra users to share and discover chord charts created by the community. This creates powerful network effects - the app becomes more valuable as more users contribute.

## Architecture

### Models

#### PublicSong (PublicSong.swift)
Core model for community-shared songs stored in CloudKit Public Database.

**Properties:**
- Song content (title, artist, chords, lyrics)
- Musical metadata (key, tempo, time signature, capo)
- Uploader information (can be anonymous or credited)
- Statistics (downloads, views, likes, ratings)
- Categorization (genre, category, tags)
- Licensing information
- Moderation status and flags

**Features:**
- CloudKit integration for public sharing
- Trending score calculation based on recent activity
- Anonymous or credited uploads
- Automatic moderation queue

#### Supporting Models

**PublicSongRating:**
- User ratings (1-5 stars)
- Optional written reviews
- Calculates average ratings

**PublicSongFlag:**
- Content reporting system
- Multiple flag reasons (copyright, inappropriate, inaccurate, spam, duplicate)
- Admin review and resolution tracking

**PublicSongLike:**
- Simple like/unlike functionality
- Tracks user engagement

### Managers

#### PublicLibraryManager (PublicLibraryManager.swift)
Manages all public library operations.

**Key Functions:**

1. **Upload:**
   ```swift
   uploadSong(song, genre, category, tags, isAnonymous, licenseType, copyrightInfo)
   ```
   - Uploads to CloudKit Public Database
   - Enters moderation queue
   - Tracks uploader attribution

2. **Browse & Search:**
   ```swift
   fetchPublicSongs(searchTerm, genre, category, key, sortBy, limit)
   fetchTrendingSongs(limit)
   fetchFeaturedSongs(limit)
   ```
   - Multiple filter options
   - Sort by: Recently Added, Most Downloaded, Highest Rated, Trending, Alphabetical
   - Search by title or artist

3. **Download:**
   ```swift
   downloadSong(publicSong, modelContext)
   ```
   - Imports to personal library
   - Adds attribution notes
   - Increments download counter

4. **Rating & Feedback:**
   ```swift
   rateSong(publicSong, rating, review, userRecordID)
   likeSong(publicSong, userRecordID)
   unlikeSong(publicSong, userRecordID)
   flagSong(publicSong, reason, details, userRecordID)
   ```

#### ContentModerationManager (ContentModerationManager.swift)
Admin tools for content moderation.

**Features:**
- Pending review queue
- Flagged content review
- Approve/reject/remove actions
- Featured songs curation
- Admin user management

**Moderation Workflow:**
1. Song uploaded → Status: Pending
2. Admin reviews → Approves or Rejects
3. If flagged (5+ reports) → Status: Flagged for Review
4. Admin can remove inappropriate content

#### DiscoveryEngine (DiscoveryEngine.swift)
Recommendation and discovery algorithms.

**Recommendation Types:**

1. **Personalized Recommendations:**
   - Analyzes user's library (genres, keys, artists, tags)
   - Scores public songs based on similarity
   - Combines multiple factors:
     - Genre match (high weight)
     - Artist match (high weight)
     - Key match (medium weight)
     - Tag overlap (medium weight)
     - Popularity (low weight)

2. **Similar Songs:**
   - Finds songs similar to a specific song
   - Matches: artist, key, tempo, tags, title

3. **Occasion-Based:**
   - Filters by category (Christmas, Easter, Wedding, etc.)
   - Sorts by rating and popularity

## Data Flow

### Upload Flow
```
User → UploadToPublicLibraryView
     → PublicLibraryManager.uploadSong()
     → Create PublicSong (local)
     → Upload to CloudKit Public DB
     → Moderation Queue (Status: Pending)
```

### Download Flow
```
User → PublicLibraryView (Browse)
     → PublicSongDetailView (Preview)
     → PublicLibraryManager.downloadSong()
     → Create Song (personal library)
     → Add attribution
     → Increment download count
```

### Moderation Flow
```
Admin → ContentModerationManager.fetchPendingReview()
      → Review song
      → Approve/Reject/Remove
      → Update CloudKit status
      → Notify uploader (if rejection)
```

## Privacy & Safety

### Content Guidelines

**Implemented:**
- Copyright compliance warnings
- License type selection
- Terms of service acceptance required
- Clear attribution requirements
- Moderation queue for all uploads

**Copyright Protection:**
- License types: User Generated, Public Domain, CCLI, Creative Commons, Copyrighted (with permission)
- Copyright flag reason available
- Moderation review for reported content

### Privacy Controls

**User Options:**
- Anonymous uploads (no attribution)
- Credited uploads (display name shown)
- Can delete own uploads
- Private library remains private

**Data Protection:**
- User record IDs from CloudKit (not email/names)
- No personal data in public records
- Optional attribution

## Moderation System

### Auto-Moderation
- All uploads start as "Pending"
- Auto-flag at 5+ reports
- Trending score drops for flagged content

### Flag Reasons
1. Copyright Violation
2. Inappropriate Content
3. Inaccurate Information
4. Spam
5. Duplicate Song
6. Other

### Flag Outcomes
1. Dismissed (no action)
2. Warning Issued
3. Content Removed
4. User Banned (future feature)

## Discovery Features

### Trending Algorithm
Calculates score based on:
```swift
trendingScore = (
    downloadCount * 2.0 +
    likeCount * 1.5 +
    averageRating * ratingCount +
    recentDownloadBoost
) * recencyPenalty
```

**Factors:**
- Downloads (high weight)
- Likes (medium weight)
- Ratings (quality and quantity)
- Recent activity boost
- Recency penalty after 30 days

### Editor's Picks
- Admin-curated featured songs
- Displayed prominently in UI
- Quality guarantee

### Recommendations
- Personalized based on user's library
- Similar song suggestions
- Category-based discovery

## Statistics Tracking

**Per Song:**
- Download count
- View count
- Like count
- Average rating (0-5 stars)
- Trending score
- Last downloaded date

**Aggregate (Future):**
- Most downloaded songs (all-time, this month, this week)
- Top rated songs
- Most active uploaders
- Popular genres/categories

## CloudKit Schema

### Public Database Record Type: "PublicSong"

**Fields:**
- `title`: String (indexed)
- `artist`: String (indexed)
- `content`: String
- `contentFormat`: String
- `originalKey`: String
- `tempo`: Int
- `genre`: String (indexed)
- `category`: String (indexed)
- `tags`: [String]
- `uploaderDisplayName`: String
- `isAnonymous`: Int (0 or 1)
- `licenseType`: String
- `copyrightInfo`: String
- `downloadCount`: Int (indexed for sorting)
- `viewCount`: Int
- `likeCount`: Int
- `averageRating`: Double (indexed for sorting)
- `moderationStatus`: String (indexed)
- `flagCount`: Int
- `isFeatured`: Int (0 or 1, indexed)
- `trendingScore`: Double (indexed for sorting)

**Indexes:**
- title (queryable)
- artist (queryable)
- genre (queryable)
- category (queryable)
- moderationStatus (queryable)
- downloadCount (sortable)
- averageRating (sortable)
- trendingScore (sortable)
- isFeatured (queryable)

## Future Enhancements

### UI Views (Next Phase)
1. **PublicLibraryView** - Browse and search interface
2. **PublicSongDetailView** - Preview with ratings and comments
3. **UploadToPublicLibraryView** - Share workflow with guidelines
4. **ModerationDashboardView** - Admin tools
5. **DiscoveryView** - Recommendations and trending

### Features
- Comments on songs
- User profiles (uploaders)
- Collections/playlists
- Social sharing
- Song versioning (updates to uploaded songs)
- Collaborative improvements
- Community voting on featured songs

### Analytics
- User engagement metrics
- Content quality scores
- Search analytics
- Recommendation effectiveness

## Security Considerations

### CloudKit Public Database
- Read: Anyone (including non-users)
- Write: Authenticated users only
- Delete: Original uploader + admins only
- Modify: Original uploader + admins only

### Rate Limiting
- Upload limits per user (to prevent spam)
- Download tracking (no limit, just stats)
- Flag limits (prevent abuse)

### Content Validation
- Title/artist required
- Content length limits
- Tag count limits
- Inappropriate word filtering (future)

## Testing Checklist

### Upload
- [ ] Anonymous upload works
- [ ] Credited upload shows name
- [ ] CloudKit record created
- [ ] Moderation status = pending
- [ ] License type saved correctly

### Download
- [ ] Song imported to personal library
- [ ] Attribution added to notes
- [ ] Download count incremented
- [ ] CloudKit updated

### Search & Browse
- [ ] Search by title works
- [ ] Search by artist works
- [ ] Genre filter works
- [ ] Category filter works
- [ ] Key filter works
- [ ] Sort options work

### Rating & Likes
- [ ] Can rate 1-5 stars
- [ ] Average rating calculated correctly
- [ ] Can like/unlike
- [ ] Like count updates

### Flagging
- [ ] Can flag with reason
- [ ] Flag count increments
- [ ] Auto-flags at 5 reports
- [ ] Admin can review flags

### Moderation
- [ ] Admin can approve songs
- [ ] Admin can reject songs
- [ ] Admin can remove songs
- [ ] Admin can feature songs
- [ ] Status updates in CloudKit

### Discovery
- [ ] Recommendations based on library
- [ ] Similar songs work
- [ ] Trending calculation correct
- [ ] Category filtering works

## Network Effects

The public library creates powerful network effects:

1. **More Users = More Content**
   - Each user can contribute songs
   - Library grows organically
   - Reduces duplicate work

2. **More Content = More Value**
   - Users find songs they need
   - Less time creating from scratch
   - Higher app retention

3. **More Engagement = Better Quality**
   - Ratings surface best content
   - Downloads indicate usefulness
   - Community moderation

4. **Virtuous Cycle**
   - Quality content attracts users
   - More users create more content
   - Better content improves quality
   - Cycle repeats

This transforms Lyra from a personal tool into a community platform, making it essential for musicians and worship leaders worldwide.
