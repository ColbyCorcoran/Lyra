# Google Drive Integration Setup Guide

This guide explains how to complete the Google Drive integration setup for Lyra.

## Prerequisites

1. Xcode 15+
2. A Google Cloud Platform account
3. GoogleSignIn SDK
4. GoogleAPIClientForREST (Drive API)

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "New Project" or select an existing project
3. Name it **Lyra** (or your preferred name)
4. Click "Create"
5. Note your **Project ID** (you'll need this)

## Step 2: Enable Google Drive API

1. In the Google Cloud Console, go to **APIs & Services > Library**
2. Search for "Google Drive API"
3. Click on "Google Drive API"
4. Click "Enable"

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services > OAuth consent screen**
2. Select **External** user type (or Internal if using Google Workspace)
3. Click "Create"
4. Fill in the required fields:
   - **App name**: Lyra
   - **User support email**: Your email
   - **Developer contact**: Your email
5. Click "Save and Continue"
6. On **Scopes** page, click "Add or Remove Scopes"
7. Add the following scopes:
   - `https://www.googleapis.com/auth/drive.readonly` (View files)
   - `https://www.googleapis.com/auth/drive.metadata.readonly` (View metadata)
   - `https://www.googleapis.com/auth/userinfo.email` (See your email)
   - `https://www.googleapis.com/auth/userinfo.profile` (See your profile)
8. Click "Update" then "Save and Continue"
9. Add test users if needed (for development)
10. Click "Back to Dashboard"

## Step 4: Create OAuth 2.0 Credentials

1. Go to **APIs & Services > Credentials**
2. Click "Create Credentials" > "OAuth client ID"
3. Choose **iOS** application type
4. Fill in:
   - **Name**: Lyra iOS Client
   - **Bundle ID**: Your app's bundle identifier (e.g., `com.yourcompany.Lyra`)
5. Click "Create"
6. Note your **Client ID** (you'll need this)
7. Download the credentials JSON file (optional, for reference)

## Step 5: Add SDKs via Swift Package Manager

### Add GoogleSignIn

1. Open your Xcode project
2. Go to **File > Add Package Dependencies**
3. Enter the repository URL:
   ```
   https://github.com/google/GoogleSignIn-iOS
   ```
4. Select version: **7.0.0** or later
5. Click **Add Package**
6. Select **GoogleSignIn** and **GoogleSignInSwift** and click **Add Package**

### Add GoogleAPIClientForREST

1. Go to **File > Add Package Dependencies** again
2. Enter the repository URL:
   ```
   https://github.com/google/google-api-objectivec-client-for-rest
   ```
3. Select version: **3.0.0** or later
4. Click **Add Package**
5. Select **GoogleAPIClientForREST_Drive** and click **Add Package**

## Step 6: Configure Info.plist

Add the following to your `Info.plist`:

### URL Scheme for OAuth callback

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
    <key>CFBundleURLName</key>
    <string>GoogleSignIn</string>
  </dict>
</array>
```

### LSApplicationQueriesSchemes

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>googlechromes</string>
  <string>googlechrome</string>
</array>
```

### Google Sign-In Client ID

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
```

**Note**: Replace `YOUR_CLIENT_ID` with your actual OAuth client ID from Step 4.

For the URL scheme, use the **reversed client ID** (typically looks like `com.googleusercontent.apps.1234567890-abcdefg`).

## Step 7: Initialize SDK in App

In your main `@main` App file (e.g., `LyraApp.swift`):

```swift
import SwiftUI
import GoogleSignIn

@main
struct LyraApp: App {
    init() {
        // Configure Google Sign-In
        // The client ID from Info.plist will be used automatically
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

## Step 8: Handle OAuth Callback

In your main `@main` App file, add the URL handler:

```swift
import SwiftUI
import GoogleSignIn

@main
struct LyraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)

                    // Also let our manager handle it for state updates
                    let handled = GoogleDriveManager.shared.handleAuthCallback(url: url)
                    if handled {
                        print("✅ Google Drive OAuth callback handled")
                    }
                }
        }
    }
}
```

## Step 9: Uncomment Code in GoogleDriveManager.swift

The `GoogleDriveManager.swift` file has commented-out code that requires the Google SDKs. After completing the setup:

1. Open `Lyra/Utilities/GoogleDriveManager.swift`
2. Uncomment the lines:
   ```swift
   // import GoogleSignIn
   // import GoogleAPIClientForREST
   // import GTMSessionFetcherCore
   ```
3. Uncomment all the method implementations marked with `// TODO: Uncomment after adding Google SDKs`

These sections include:
- `authenticate()`
- `handleAuthCallback(url:)`
- `signOut()`
- `fetchAccountInfo()`
- `listFiles(folderId:)`
- `listSharedDrives()`
- `downloadFile(fileId:progress:)`
- `searchFiles(query:folderId:)`

## Step 10: Test the Integration

1. Run the app
2. Go to **Settings > Cloud Services > Google Drive**
3. Tap **Connect to Google Drive**
4. Complete the OAuth flow in Safari/Chrome
5. Grant requested permissions
6. You should see "Connected" status with your email
7. Try importing files from **Library > Import > Import from Google Drive**
8. Test shared drives by tapping the shared drives menu in the browser

## Troubleshooting

### OAuth Redirect Fails

**Issue**: After authorizing in the browser, the app doesn't open.

**Solution**:
- Verify the URL scheme in Info.plist matches your reversed client ID
- Check that it's the full reversed client ID, not just the numbers
- Example: `com.googleusercontent.apps.123456789-abc123def456` (not `123456789-abc123def456`)
- Ensure `GIDClientID` in Info.plist is the full client ID with `.apps.googleusercontent.com`

### "Not authenticated" Error

**Issue**: Getting authentication errors when trying to browse files.

**Solution**:
- Make sure the client ID in Info.plist matches your OAuth credentials
- Verify all required scopes are granted in OAuth consent screen
- Check that Google Drive API is enabled in Cloud Console
- Try signing out and reconnecting
- Check Xcode console for specific error messages

### "Access Not Configured" Error

**Issue**: API requests fail with 403 errors.

**Solution**:
- Verify Google Drive API is enabled in Cloud Console
- Check that OAuth scopes include `drive.readonly` and `drive.metadata.readonly`
- Re-authorize the app to grant new permissions
- Wait a few minutes after enabling the API (propagation delay)

### Shared Drives Not Showing

**Issue**: Can't see shared drives.

**Solution**:
- Verify your Google account has access to shared drives
- Check that `supportsAllDrives=true` parameter is set in API calls
- Ensure the user has at least "Viewer" access to the shared drives
- Some Google Workspace settings may restrict shared drive access

### API Rate Limiting

**Issue**: Requests fail after many operations.

**Solution**:
- Google Drive API has quotas (default: 1,000 queries per 100 seconds per user)
- Implement exponential backoff for retries (already included in code)
- Consider batching operations where possible
- Monitor quota usage in Cloud Console

### File Download Fails

**Issue**: Can't download files from Drive.

**Solution**:
- Check file permissions (must have at least "Viewer" access)
- Verify file is not corrupted or zero-bytes
- For Google Docs/Sheets/Slides, they need to be exported (not yet supported)
- Check network connectivity
- Review Xcode console for specific error messages

## File Type Support

The Google Drive integration supports importing:
- **Text files**: .txt, .cho, .chordpro, .chopro, .crd
- **PDF files**: .pdf
- **OnSong files**: .onsong

**Note**: Google Workspace files (Docs, Sheets, Slides) are not currently supported. They need to be exported to supported formats first.

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
- Token refresh is handled automatically by GoogleSignIn SDK
- File data is only stored locally, not uploaded back to Drive
- Only requested scopes (read-only) are granted
- Tokens can be revoked from Google Account settings

## MIME Type Handling

Google Drive uses MIME types to identify files. The integration handles:

| File Type | MIME Type |
|-----------|-----------|
| Text files | `text/plain` |
| PDF files | `application/pdf` |
| Generic files | `application/octet-stream` |
| Folders | `application/vnd.google-apps.folder` |

Google Workspace files have special MIME types:
- Google Docs: `application/vnd.google-apps.document`
- Google Sheets: `application/vnd.google-apps.spreadsheet`
- Google Slides: `application/vnd.google-apps.presentation`

These require export API calls to convert to standard formats (future enhancement).

## Shared Drives Support

The integration includes full shared drives support:

1. **List Shared Drives**: Shows all drives the user has access to
2. **Browse Shared Drives**: Navigate folders within shared drives
3. **Import from Shared Drives**: Download and import files from shared drives
4. **Search Shared Drives**: Search works across shared drives

Shared drives appear in a menu in the browser view, allowing easy switching between "My Drive" and team drives.

## Future Enhancements

Potential features to add:
- [ ] Export Google Docs/Sheets to supported formats
- [ ] Bi-directional sync (upload changes back to Drive)
- [ ] Automatic sync on app launch
- [ ] Conflict resolution for synced files
- [ ] Folder mapping (specific Drive folder → specific Book/Set)
- [ ] Background sync with background URLSession
- [ ] Star/favorite files in Drive from within app
- [ ] Share songs directly to Drive
- [ ] Team drive permission management

## Additional Resources

- [GoogleSignIn iOS Documentation](https://developers.google.com/identity/sign-in/ios)
- [Google Drive API Reference](https://developers.google.com/drive/api/v3/reference)
- [GoogleAPIClientForREST Documentation](https://github.com/google/google-api-objectivec-client-for-rest)
- [OAuth 2.0 for Mobile Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
- [Drive API Quotas](https://developers.google.com/drive/api/v3/handle-errors#resolve-a-403-error-rate-limit-exceeded)

## Support

If you encounter issues:
1. Check the Xcode console for error messages
2. Verify all setup steps are complete
3. Test OAuth flow in Google OAuth Playground
4. Review Google Cloud Console for API errors and quota usage
5. Check GoogleSignIn GitHub issues for similar problems
6. Verify scopes match between consent screen and code

## Testing Checklist

Before deploying, test the following:

- [ ] OAuth flow from not authenticated state
- [ ] OAuth flow when already authenticated (should skip)
- [ ] Browse root folder (My Drive)
- [ ] Navigate into subfolders
- [ ] Navigate back using breadcrumb
- [ ] Search for files
- [ ] List shared drives
- [ ] Browse shared drive folders
- [ ] Import .txt file
- [ ] Import .cho file
- [ ] Import .pdf file
- [ ] Import multiple files at once
- [ ] Import from shared drive
- [ ] Handle network errors gracefully
- [ ] Handle offline state
- [ ] Sign out and verify state clears
- [ ] Re-authenticate after sign out
- [ ] Storage quota display
- [ ] Large folder browsing (100+ files)

---

**Note**: Remember to keep your OAuth client ID and client secret (if any) confidential. Don't commit them to public repositories. Consider using Xcode configuration files or environment variables for sensitive credentials.

For production apps, you'll need to:
1. Publish the OAuth consent screen (currently in "Testing" mode)
2. Complete app verification process if using restricted scopes
3. Add privacy policy and terms of service URLs
4. Submit for OAuth verification if requesting sensitive scopes
