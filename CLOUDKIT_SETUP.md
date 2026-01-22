# CloudKit Setup Guide for Lyra

This guide walks you through the **final steps** to enable iCloud sync in Lyra. All the code is ready—you just need to configure Xcode and CloudKit.

---

## ⚡ Quick Setup (5 Minutes)

### 1. Enable iCloud Capability in Xcode

1. **Open the Lyra project in Xcode**
2. **Select the Lyra target** in the project navigator
3. **Go to "Signing & Capabilities" tab**
4. **Click "+ Capability"** button (top left)
5. **Select "iCloud"** from the list

### 2. Configure CloudKit

Once iCloud capability is added:

1. **Check "CloudKit"** checkbox
2. **Click the "+" button** next to "Containers"
3. **Choose "Use Default Container"** OR create a custom one:
   - Custom format: `iCloud.com.yourname.Lyra`
   - Example: `iCloud.com.johndoe.Lyra`

### 3. Verify iCloud Documents (Optional)

If you want to support iCloud Documents (for backup export):

1. In the same iCloud section
2. **Check "iCloud Documents"** (optional)
3. Select the same container

### 4. Update Bundle Identifier (If Needed)

1. Go to **"Signing & Capabilities" → "Signing"** section
2. Verify your **Bundle Identifier** matches:
   - Should be: `com.yourname.Lyra`
3. Select your **Development Team**
4. Xcode will auto-provision

### 5. Test on Device

⚠️ **Important:** CloudKit sync **only works on real devices**, not the simulator.

1. **Build and run on your iPhone/iPad**
2. **Sign in to iCloud** in Settings if not already
3. **Open Lyra** → Settings → Sync & Backup
4. **Enable "iCloud Sync"**
5. **Check sync status** (should show "Syncing..." then "Synced")

---

## 📋 CloudKit Dashboard (Optional)

To view/manage your CloudKit data:

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Sign in with your Apple Developer account
3. Select your container (`iCloud.com.yourname.Lyra`)
4. View **Development** and **Production** environments

### What You'll See:

- **Record Types:** Song, Book, PerformanceSet, Attachment, etc.
- **Records:** Your actual synced data
- **Subscriptions:** Automatic sync triggers
- **Indexes:** Query performance optimization

SwiftData creates these automatically—**no manual schema setup needed!**

---

## 🔐 Entitlements File

Xcode automatically creates/updates `Lyra.entitlements` with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.yourname.Lyra</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <key>com.apple.developer.ubiquity-container-identifiers</key>
    <array>
        <string>iCloud.com.yourname.Lyra</string>
    </array>
</dict>
</plist>
```

You **don't need to edit this manually**—Xcode handles it!

---

## ✅ Verify Everything Works

### In Lyra App:

1. **Settings → Sync & Backup**
2. **Enable iCloud Sync**
3. **Add/Edit a song**
4. **Check "Last Synced"** timestamp updates
5. **Install on second device** (iPhone + iPad)
6. **Verify song appears on both devices**

### Expected Behavior:

- ✅ New songs sync within seconds
- ✅ Edits sync automatically
- ✅ Conflicts show in UI if same song edited on both devices
- ✅ Offline changes queue and sync when online
- ✅ "Last Synced" timestamp updates

---

## 🐛 Troubleshooting

### "CloudKit is not enabled"

**Solution:**
- Go to Signing & Capabilities
- Verify iCloud capability is added
- Check CloudKit is enabled
- Rebuild the app

### "No container found"

**Solution:**
- Verify container ID matches in:
  - Signing & Capabilities → iCloud
  - Entitlements file
- Try "Use Default Container" first
- Rebuild and re-run

### "Sync not working on device"

**Solution:**
- Check device is signed into iCloud (Settings → [Your Name])
- Verify internet connection
- Check "Sync Over Cellular" if not on Wi-Fi
- Force sync with "Sync Now" button
- Check CloudKit Dashboard for errors

### "Simulator shows sync but doesn't work"

**Expected:**
- CloudKit sync **only works on real devices**
- Simulator will show UI but won't actually sync
- Use TestFlight or direct device install for testing

---

## 🚀 Development vs Production

### Development Environment
- Used when running from Xcode
- Separate CloudKit database
- Can be reset/cleared without affecting users
- Appears in CloudKit Dashboard as "Development"

### Production Environment
- Used in App Store builds
- TestFlight uses Production
- **Cannot be reset** (protects user data)
- Appears in CloudKit Dashboard as "Production"

### Switching Environments

Xcode automatically uses:
- **Development:** Debug builds from Xcode
- **Production:** Archive builds, TestFlight, App Store

No code changes needed!

---

## 🧪 Testing Checklist

Before submitting to App Store:

- [ ] Tested on real iPhone device
- [ ] Tested on real iPad device
- [ ] New song syncs between devices
- [ ] Edit syncs between devices
- [ ] Delete syncs between devices
- [ ] Conflict resolution UI appears when editing same song on both
- [ ] Offline mode queues operations
- [ ] Coming back online processes queue
- [ ] Large attachments sync (PDFs, images)
- [ ] iCloud storage limits respected

---

## 📊 CloudKit Limits (Free Tier)

Apple provides generous free CloudKit limits:

- **Storage:** 1 PB total (effectively unlimited)
- **Database Operations:** 40 requests/second
- **Asset Storage:** 1 MB per record (we use external storage)
- **Asset Bandwidth:** 250 MB per user per day

**Lyra's Implementation:**
- ✅ Uses `@Attribute(.externalStorage)` for large files
- ✅ Efficient sync (only changed records)
- ✅ Batch operations for performance
- ✅ Automatic throttling via SwiftData

You won't hit these limits in normal use!

---

## 🔒 Privacy & Security

### What's Stored in iCloud:

- ✅ Song metadata (title, artist, key, etc.)
- ✅ Chord chart content
- ✅ Books and sets
- ✅ Annotations and notes
- ✅ Performance history
- ✅ Attachments (PDFs, images)

### What's NOT Stored:

- ❌ No analytics sent to external servers
- ❌ No third-party tracking
- ❌ Only synced to user's personal iCloud account

### User Control:

- ✅ Sync is opt-in (disabled by default)
- ✅ Can be disabled anytime
- ✅ Cellular sync toggle
- ✅ Sync scope controls
- ✅ Local backups independent of iCloud

---

## 📝 Key Implementation Details (Already Done!)

Everything below is **already implemented** in the code:

### ✅ Model Configuration
```swift
// Lyra/LyraApp.swift
ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: iCloudEnabled ? .automatic : .none
)
```

### ✅ Large File Handling
```swift
// Lyra/Models/Attachment.swift
@Attribute(.externalStorage)
var fileData: Data?
```

### ✅ Unique Identifiers
```swift
// Lyra/Models/Song.swift
@Attribute(.unique)
var ccliNumber: String?

@Attribute(.unique)
var cloudFileId: String?
```

### ✅ Conflict Resolution
```swift
// Lyra/Utilities/ConflictResolutionManager.swift
// Full conflict detection and resolution system
// - Auto-resolve simple conflicts
// - User UI for complex conflicts
// - Keep Local, Keep Remote, Keep Both, Merge
```

### ✅ Sync Manager
```swift
// Lyra/Utilities/CloudSyncManager.swift
// - Sync status tracking
// - Last synced timestamp
// - Error handling
// - Cellular sync control
```

---

## 🎉 That's It!

Once you complete the Xcode configuration above, iCloud sync will be **fully functional**!

All the infrastructure is already built:
- ✅ Offline-first design
- ✅ Conflict resolution
- ✅ Sync status UI
- ✅ Settings controls
- ✅ Large file handling
- ✅ Error handling

**Just add the CloudKit capability in Xcode and you're done!**

---

## 📞 Need Help?

If you encounter issues:

1. Check [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/) for errors
2. Review Xcode console logs when syncing
3. Use Debug section in Sync Settings (DEBUG builds only)
4. File an issue on GitHub with:
   - Device model and iOS version
   - Xcode console logs
   - Steps to reproduce

---

**Happy Syncing! 🎸☁️**
