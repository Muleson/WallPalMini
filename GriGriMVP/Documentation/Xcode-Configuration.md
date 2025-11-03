# Xcode Project Configuration for Deep Linking

## Overview
This guide covers the manual Xcode configuration needed to enable deep linking in the GriGriMVP app.

## 1. URL Scheme Configuration

URL schemes allow the app to handle `crahg://` URLs.

### Steps:
1. Open `GriGriMVP.xcodeproj` in Xcode
2. Select the **GriGriMVP** target
3. Go to the **Info** tab
4. Scroll down to **URL Types**
5. Click the **+** button to add a new URL type

### Configuration:
- **Identifier**: `com.samquested.grigrimvp`
- **URL Schemes**: `crahg`
- **Role**: `Editor`

### Visual Reference:
```
URL Types
└── URL Type 1
    ├── Identifier: com.samquested.grigrimvp
    ├── URL Schemes: crahg
    └── Role: Editor
```

### Result:
This allows the app to handle URLs like:
- `crahg://event/123`
- `crahg://gym/456`
- `crahg://home`

## 2. Associated Domains (Already Configured)

Universal Links are configured via the entitlements file.

### Current Configuration:
File: `GriGriMVP.entitlements`

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:crahg.app</string>
    <string>applinks:www.crahg.app</string>
</array>
```

### Verify in Xcode:
1. Select **GriGriMVP** target
2. Go to **Signing & Capabilities** tab
3. Look for **Associated Domains** section
4. Should show:
   - `applinks:crahg.app`
   - `applinks:www.crahg.app`

### If Missing:
1. Click **+ Capability**
2. Search for "Associated Domains"
3. Add it
4. Add domains:
   - `applinks:crahg.app`
   - `applinks:www.crahg.app`

## 3. App Transport Security (If Needed)

If testing with non-HTTPS URLs during development:

### Steps:
1. Open `Info.plist` (or target Info tab)
2. Add the following:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>crahg.app</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
        </dict>
    </dict>
</dict>
```

**Note:** Only needed for development. Production should always use HTTPS.

## 4. Signing Configuration

Universal Links require proper code signing.

### Requirements:
- ✅ Valid Apple Developer Account
- ✅ Provisioning Profile with App ID matching bundle identifier
- ✅ Associated Domains capability enabled in Apple Developer Portal

### Steps:
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your App ID: `com.samquested.grigrimvp`
4. Edit the App ID
5. Enable **Associated Domains** capability
6. Save changes
7. Regenerate provisioning profiles if needed

### In Xcode:
1. Select **GriGriMVP** target
2. Go to **Signing & Capabilities**
3. Select your team
4. Ensure **Automatically manage signing** is checked (recommended)
5. Or manually select provisioning profile

## 5. Build Settings

### Bundle Identifier
Must match the bundle ID in your AASA file.

**Current**: `com.samquested.grigrimvp`

Verify:
1. Select target
2. Go to **General** tab
3. Check **Bundle Identifier**
4. Should be: `com.samquested.grigrimvp`

### Deployment Target
Ensure iOS version supports Universal Links:

**Minimum**: iOS 14.0 (recommended)
**Universal Links**: Supported from iOS 9.0+

## 6. Testing Configuration

### Simulator Testing
Works without AASA file for custom URL schemes.

Test command:
```bash
xcrun simctl openurl booted "crahg://event/123"
```

### Device Testing
Requires proper configuration:
- ✅ Valid code signing
- ✅ Associated Domains capability
- ✅ AASA file deployed on web server
- ✅ Device connected to internet

## 7. Verification Checklist

### Before Building:
- [ ] URL scheme `crahg` is configured
- [ ] Associated Domains include `crahg.app`
- [ ] Bundle Identifier matches AASA file
- [ ] Code signing is configured
- [ ] Entitlements file is correct

### After Building:
- [ ] App installs successfully
- [ ] No signing errors in build log
- [ ] Associated Domains appear in device logs

### For Universal Links:
- [ ] AASA file is accessible at `https://crahg.app/.well-known/apple-app-site-association`
- [ ] Team ID in AASA matches your Apple Developer Team ID
- [ ] App was deleted and reinstalled (AASA caching)

## 8. Build & Run

### Clean Build (Recommended):
```bash
# In terminal
cd /Users/samquested/Projects/programming/Swift/GriGri/GriGriMVP
rm -rf ~/Library/Developer/Xcode/DerivedData/GriGriMVP-*
```

Or in Xcode:
1. Product → Clean Build Folder (⌘⇧K)
2. Product → Build (⌘B)
3. Product → Run (⌘R)

### Verify Installation:
After installing, check device console for:
```
swcd: Allowing app com.samquested.grigrimvp to handle crahg.app
```

## 9. Common Configuration Errors

### Error: "No Associated Domains"
**Solution**: Add Associated Domains capability in Signing & Capabilities

### Error: "Provisioning profile doesn't include Associated Domains"
**Solution**:
1. Enable Associated Domains for App ID in Developer Portal
2. Regenerate provisioning profile
3. Download and install in Xcode

### Error: "App ID mismatch"
**Solution**: Ensure bundle ID in Xcode matches AASA file

### Error: "Code signing failed"
**Solution**:
1. Check Apple Developer account is active
2. Verify provisioning profiles are up to date
3. Ensure correct team is selected

## 10. Advanced: Multiple Environments

### Development
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:dev.crahg.app</string>
</array>
```

### Staging
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:staging.crahg.app</string>
</array>
```

### Production
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:crahg.app</string>
    <string>applinks:www.crahg.app</string>
</array>
```

Use Xcode build configurations or schemes to manage different environments.

## 11. Debugging in Xcode

### Enable Console Logging:
The app includes extensive logging. View in Xcode console:

```
🔗 = URL handling
🎯 = Navigation
⚠️ = Warnings
❌ = Errors
```

### Breakpoints:
Set breakpoints in:
- `RootView.handleDeepLink()`
- `DeepLinkManager.handleURL()`
- `MainTabView.handlePendingDeepLink()`

### View Hierarchy:
Use Xcode's View Debugger to inspect navigation state:
1. Debug → View Debugging → Capture View Hierarchy
2. Inspect NavigationStack and TabView state

## 12. Performance Considerations

### App Launch Performance
Deep links are processed during app launch. Ensure:
- Fast URL parsing (already optimized)
- Efficient data fetching
- Minimal blocking on main thread

### Current Implementation:
- ✅ Parsing is synchronous and fast
- ✅ Data fetching is async (doesn't block UI)
- ✅ Navigation happens after authentication check

## Resources

- **Apple Documentation**: [Supporting Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- **WWDC Videos**: Search "Universal Links" on developer.apple.com
- **Xcode Help**: Help → Search "URL Schemes" or "Associated Domains"
