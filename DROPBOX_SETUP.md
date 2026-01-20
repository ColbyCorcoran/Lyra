# Dropbox Integration Setup Guide

This guide explains how to complete the Dropbox integration setup for Lyra.

## Prerequisites

1. Xcode 15+
2. A Dropbox developer account
3. SwiftyDropbox SDK

## Step 1: Create Dropbox App

1. Go to [Dropbox App Console](https://www.dropbox.com/developers/apps)
2. Click "Create app"
3. Choose:
   - **API**: Scoped access
   - **Access**: Full Dropbox (or App folder for limited access)
   - **Name**: LyraChordManager (or your preferred name)
4. Click "Create app"
5. Note your **App key** (you'll need this)

## Step 2: Configure OAuth Settings

In your Dropbox app settings:

1. Under **OAuth 2**, add redirect URIs:
   ```
   db-YOUR_APP_KEY://2/token
   db-YOUR_APP_KEY://1/connect
   ```
   (Replace `YOUR_APP_KEY` with your actual app key)

2. Under **Permissions**, enable:
   - `files.metadata.read`
   - `files.content.read`
   - `files.content.write` (optional, for future sync features)

## Step 3: Add SwiftyDropbox via Swift Package Manager

1. Open your Xcode project
2. Go to **File > Add Package Dependencies**
3. Enter the repository URL:
   ```
   https://github.com/dropbox/SwiftyDropbox
   ```
4. Select version: **10.0.0** or later
5. Click **Add Package**
6. Select **SwiftyDropbox** and click **Add Package**

## Step 4: Configure Info.plist

Add the following to your `Info.plist`:

### URL Scheme for OAuth callback

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>db-YOUR_APP_KEY</string>
    </array>
    <key>CFBundleURLName</key>
    <string></string>
  </dict>
</array>
```

### LSApplicationQueriesSchemes

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>dbapi-2</string>
  <string>dbapi-8-emm</string>
</array>
```

**Note**: Replace `YOUR_APP_KEY` with your actual Dropbox app key from Step 1.

## Step 5: Initialize SDK in App

In your main `@main` App file (e.g., `LyraApp.swift`):

```swift
import SwiftUI
import SwiftyDropbox

@main
struct LyraApp: App {
    init() {
        // Initialize Dropbox SDK
        DropboxClientsManager.setupWithAppKey("YOUR_APP_KEY")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Step 6: Handle OAuth Callback

In your main `@main` App file, add the URL handler:

```swift
import SwiftUI
import SwiftyDropbox

@main
struct LyraApp: App {
    init() {
        DropboxClientsManager.setupWithAppKey("YOUR_APP_KEY")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    let handled = DropboxManager.shared.handleAuthCallback(url: url)
                    if handled {
                        print("✅ Dropbox OAuth callback handled")
                    }
                }
        }
    }
}
```

## Step 7: Uncomment Code in DropboxManager.swift

The `DropboxManager.swift` file has commented-out code that requires the SwiftyDropbox SDK. After completing the setup:

1. Open `Lyra/Utilities/DropboxManager.swift`
2. Uncomment the line:
   ```swift
   // import SwiftyDropbox
   ```
3. Uncomment all the method implementations marked with `// TODO: Uncomment after adding SwiftyDropbox`

These sections include:
- `authenticate()`
- `handleAuthCallback(url:)`
- `signOut()`
- `fetchAccountInfo()`
- `listFolder(path:)`
- `downloadFile(path:progress:)`
- `searchFiles(query:path:)`

## Step 8: Test the Integration

1. Run the app
2. Go to **Settings > Cloud Services > Dropbox**
3. Tap **Connect to Dropbox**
4. Complete the OAuth flow in Safari/Dropbox app
5. You should see "Connected" status with your email
6. Try importing files from **Library > Import > Import from Dropbox**

## Troubleshooting

### OAuth Redirect Fails

**Issue**: After authorizing in Safari, the app doesn't open.

**Solution**:
- Verify the URL scheme in Info.plist matches your app key: `db-YOUR_APP_KEY`
- Check that redirect URIs in Dropbox app settings are correct
- Make sure the scheme is exactly: `db-` followed by your app key (no spaces)

### "Not authenticated" Error

**Issue**: Getting authentication errors when trying to browse files.

**Solution**:
- Make sure `DropboxClientsManager.setupWithAppKey()` is called on app launch
- Check that the token is being saved to keychain correctly
- Try signing out and reconnecting

### Import Permission Denied

**Issue**: Can't download/import files.

**Solution**:
- Verify the app has `files.content.read` permission in Dropbox app settings
- Re-authorize the app to grant new permissions

### API Rate Limiting

**Issue**: Requests fail after many operations.

**Solution**:
- Dropbox has rate limits (varies by endpoint)
- Implement exponential backoff for retries
- Consider batching operations where possible

## File Type Support

The Dropbox integration supports importing:
- **Text files**: .txt, .cho, .chordpro, .chopro, .crd
- **PDF files**: .pdf
- **OnSong files**: .onsong

Files are automatically detected and imported using the appropriate handler:
- Text files → `ImportManager.importFile()`
- PDF files → `ImportManager.importPDF()`

## Storage Strategy

Downloaded files are:
1. Saved to temporary directory during download
2. Imported into the app's database
3. Temporary files are cleaned up after import
4. PDFs are stored per the app's PDF storage strategy (inline for <5MB, external for larger)

## Security Considerations

- Access tokens are stored securely in iOS Keychain
- OAuth 2.0 flow ensures no passwords are stored
- Token refresh is handled automatically by SwiftyDropbox
- File data is only stored locally, not uploaded back to Dropbox

## Future Enhancements

Potential features to add:
- [ ] Bi-directional sync (upload changes back to Dropbox)
- [ ] Automatic sync on app launch
- [ ] Conflict resolution for synced files
- [ ] Folder mapping (specific Dropbox folder → specific Book/Set)
- [ ] Background sync with background URLSession

## Additional Resources

- [SwiftyDropbox Documentation](https://github.com/dropbox/SwiftyDropbox)
- [Dropbox API Reference](https://www.dropbox.com/developers/documentation/http/documentation)
- [Dropbox OAuth Guide](https://developers.dropbox.com/oauth-guide)

## Support

If you encounter issues:
1. Check the Xcode console for error messages
2. Verify all setup steps are complete
3. Test with the Dropbox API Explorer to verify credentials
4. Review the SwiftyDropbox GitHub issues for similar problems

---

**Note**: Remember to keep your Dropbox app key secret. Don't commit it to public repositories. Consider using a configuration file or environment variables for sensitive credentials.
