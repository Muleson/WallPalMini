# URL Types Configuration - Step-by-Step Guide

## Overview
URL Types allow your app to respond to custom URL schemes like `crahg://`. This is a **required** configuration step to enable deep linking with custom schemes.

## Understanding URL Types

### What They Do
When configured, your app can handle URLs like:
- `crahg://event/123`
- `crahg://gym/456`
- `crahg://home`

Without this configuration, iOS won't know your app can handle `crahg://` URLs.

### What You Need
- **Identifier**: Your app's bundle identifier (usually reverse DNS format)
- **URL Scheme**: The custom scheme (e.g., `crahg`)
- **Role**: Usually `Editor` (allows opening and editing)

## Configuration Methods

### Method 1: Using Xcode Target Settings (Recommended)

This is the easiest method and works for modern Xcode projects.

#### Step-by-Step Instructions

1. **Open Your Project in Xcode**
   ```bash
   cd /Users/samquested/Projects/programming/Swift/GriGri/GriGriMVP
   open GriGriMVP.xcodeproj
   ```

2. **Select Your Target**
   - In the Project Navigator (left sidebar), click on `GriGriMVP` (the blue project icon at the top)
   - In the main editor area, select the `GriGriMVP` target from the TARGETS list

3. **Navigate to Info Tab**
   - Click on the **Info** tab at the top of the editor
   - Scroll down until you see the section labeled **URL Types**

4. **Add URL Type**
   - Click the **+** button (or triangle to expand if collapsed)
   - You'll see a new entry appear

5. **Configure the URL Type**
   Fill in these three fields:

   **Identifier:**
   ```
   com.samquested.grigrimvp
   ```
   _(This should match your Bundle Identifier)_

   **URL Schemes:**
   ```
   crahg
   ```
   _(Just the scheme name, no `://` suffix)_

   **Role:**
   ```
   Editor
   ```
   _(Select from dropdown: Editor, Viewer, Shell, or None)_

6. **Verify Your Configuration**
   After adding, you should see:
   ```
   URL Types (1)
   └── Item 0
       ├── Identifier: com.samquested.grigrimvp
       ├── URL Schemes (1)
       │   └── Item 0: crahg
       ├── Icon: (leave empty)
       └── Role: Editor
   ```

#### Visual Reference

Your configuration should look like this in Xcode:

```
┌─────────────────────────────────────────────────┐
│ URL Types                                  ▼    │
├─────────────────────────────────────────────────┤
│   Item 0                                   -    │
│   ├─ Identifier      com.samquested.grigrimvp  │
│   ├─ URL Schemes                           ▼    │
│   │   └─ Item 0      crahg                     │
│   ├─ Icon                                       │
│   └─ Role            Editor                ▼    │
└─────────────────────────────────────────────────┘
```

### Method 2: Direct Info.plist Editing (Alternative)

If you prefer editing the Info.plist file directly, or if your project has a visible Info.plist file:

#### Locate Info.plist

Check these locations:
```bash
# Common locations
GriGriMVP/Info.plist
GriGriMVP/GriGriMVP/Info.plist
GriGriMVP/Supporting Files/Info.plist
```

If not found, Xcode might be managing it internally. Use Method 1 instead.

#### Add URL Type to Info.plist

If you have an Info.plist file, add this XML:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.samquested.grigrimvp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>crahg</string>
        </array>
    </dict>
</array>
```

#### Full Info.plist Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Other existing keys... -->

    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLName</key>
            <string>com.samquested.grigrimvp</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>crahg</string>
            </array>
        </dict>
    </array>

    <!-- Other existing keys... -->
</dict>
</plist>
```

### Method 3: Build Settings (Advanced)

For programmatic configuration or build scripts:

```bash
# Use PlistBuddy to add URL Type
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleTypeRole string Editor" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string com.samquested.grigrimvp" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string crahg" Info.plist
```

## Understanding the Fields

### CFBundleURLName (Identifier)
- **What it is**: A unique identifier for this URL type
- **Format**: Reverse DNS notation (like bundle identifier)
- **Example**: `com.samquested.grigrimvp`
- **Purpose**: Distinguishes your URL type from others
- **Best Practice**: Use your app's bundle identifier

### CFBundleURLSchemes (URL Schemes)
- **What it is**: The custom scheme(s) your app handles
- **Format**: Lowercase string without `://`
- **Example**: `crahg` (not `crahg://`)
- **Purpose**: iOS uses this to route URLs to your app
- **Multiple Schemes**: You can add multiple if needed
  ```xml
  <array>
      <string>crahg</string>
      <string>grigri</string>
  </array>
  ```

### CFBundleTypeRole (Role)
- **What it is**: How your app interacts with URLs
- **Options**:
  - `Editor` - Can open and modify content (recommended)
  - `Viewer` - Can only view content
  - `Shell` - Provides services
  - `None` - No specific role
- **Best Practice**: Use `Editor` for most apps

### CFBundleURLIconFile (Icon) - Optional
- **What it is**: Icon to show when asking to open URLs
- **Format**: Filename without extension
- **Example**: `URLIcon` (for URLIcon.png)
- **Purpose**: Branding when iOS shows "Open with..." dialog
- **Usually**: Left empty for custom schemes

## Verification

### Method 1: Build and Check
After configuration:

1. **Clean Build**
   - Product → Clean Build Folder (⌘⇧K)

2. **Build**
   - Product → Build (⌘B)

3. **Check Build Output**
   - Look for Info.plist processing in build log
   - Should show no errors related to URL Types

### Method 2: Inspect Built App
Check the compiled app's Info.plist:

```bash
# After building, inspect the built app
cd ~/Library/Developer/Xcode/DerivedData/GriGriMVP-*/Build/Products/Debug-iphonesimulator/GriGriMVP.app
plutil -p Info.plist | grep -A 10 CFBundleURLTypes
```

Expected output:
```
"CFBundleURLTypes" => [
  0 => {
    "CFBundleTypeRole" => "Editor"
    "CFBundleURLName" => "com.samquested.grigrimvp"
    "CFBundleURLSchemes" => [
      0 => "crahg"
    ]
  }
]
```

### Method 3: Runtime Test
Test that iOS recognizes your URL scheme:

```bash
# In simulator
xcrun simctl openurl booted "crahg://test"
```

If configured correctly:
- App will launch/activate
- Console will show: `🔗 App received URL: crahg://test`

If not configured:
- Nothing happens, or
- Error: "No app configured to open crahg://"

## Testing Your Configuration

### Test 1: Basic Scheme Recognition
```bash
# Simple test
xcrun simctl openurl booted "crahg://home"
```

**Expected**: App opens and logs URL

### Test 2: Event Deep Link
```bash
# With path
xcrun simctl openurl booted "crahg://event/test-123"
```

**Expected**: App opens, navigates to event (or shows error if ID doesn't exist)

### Test 3: Invalid Scheme
```bash
# Wrong scheme
xcrun simctl openurl booted "wrongscheme://test"
```

**Expected**: Nothing happens (your app won't respond)

### Test 4: Notes App (Device)
1. Open Notes app
2. Type: `crahg://home`
3. URL should become a clickable link
4. Tap it
5. App should open

If it doesn't become clickable, URL scheme isn't registered.

## Common Issues & Solutions

### Issue 1: URL Not Clickable in Notes
**Symptom**: Typing `crahg://test` doesn't create a link

**Cause**: URL scheme not registered

**Solution**:
1. Verify URL Type is configured in Xcode
2. Clean build (⌘⇧K)
3. Delete app from simulator/device
4. Rebuild and reinstall
5. Restart device (sometimes needed)

### Issue 2: App Doesn't Open When Tapping Link
**Symptom**: Link is clickable but nothing happens

**Cause**: URL scheme registered but handler not implemented

**Solution**:
1. Verify `RootView.onOpenURL` is present (already implemented)
2. Check console for error messages
3. Ensure app is installed
4. Try reinstalling app

### Issue 3: Multiple Apps Claim Same Scheme
**Symptom**: Wrong app opens, or iOS shows app picker

**Cause**: Multiple apps registered with same scheme

**Solution**:
1. Choose a unique scheme (more specific)
2. Delete conflicting apps
3. Or use bundle identifier in scheme: `com-samquested-grigri://`

### Issue 4: Scheme Works in Simulator but Not Device
**Symptom**: Deep links work in simulator but not on physical device

**Cause**: App not properly installed with URL registration

**Solution**:
1. Delete app from device completely
2. Clean DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/GriGriMVP-*
   ```
3. Rebuild
4. Install on device
5. Wait 30 seconds
6. Test again

### Issue 5: Xcode Info Tab Doesn't Show URL Types
**Symptom**: Can't find URL Types section in Xcode

**Cause**: May be using different Xcode version or project format

**Solution**:
1. Try scrolling down - it's near the bottom
2. Or search in top-right: "URL Types"
3. Or use Info.plist direct editing (Method 2)
4. Update Xcode if very old version

## Advanced Configuration

### Multiple URL Schemes
If you want to support multiple schemes:

```xml
<key>CFBundleURLTypes</key>
<array>
    <!-- Primary scheme -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.samquested.grigrimvp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>crahg</string>
            <string>grigri</string>
        </array>
    </dict>

    <!-- OAuth/Social login scheme (example) -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.samquested.grigrimvp.oauth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>crahg-auth</string>
        </array>
    </dict>
</array>
```

### Environment-Specific Schemes
For different build configurations:

**Debug:**
- Scheme: `crahg-dev://`
- Identifier: `com.samquested.grigrimvp.dev`

**Staging:**
- Scheme: `crahg-staging://`
- Identifier: `com.samquested.grigrimvp.staging`

**Production:**
- Scheme: `crahg://`
- Identifier: `com.samquested.grigrimvp`

## Best Practices

### Choosing a URL Scheme

✅ **Good Schemes:**
- `crahg://` - Short, unique, matches brand
- `grigri://` - App name
- `com-samquested-grigri://` - Very unique, includes developer

❌ **Avoid:**
- `http://` - Reserved by system
- `mailto://` - Reserved by system
- `sms://` - Reserved by system
- `app://` - Too generic, conflicts likely
- `x://` - Too short, conflicts likely

### Security Considerations

1. **Validate Input**: Always validate data from URLs
   ```swift
   // Already implemented in DeepLinkManager
   if let destination = handleURL(url) {
       // Validated and safe to use
   }
   ```

2. **Sanitize IDs**: Check event/gym IDs exist before navigating
   ```swift
   // Already implemented in MainTabView
   if let event = try await repository.getEvent(id: id) {
       // Only navigate if found
   }
   ```

3. **Authentication**: Require auth for sensitive actions
   ```swift
   // Already implemented - deep links only process when authenticated
   ```

## Checklist

Before testing, ensure:

- [ ] URL Type added in Xcode (Method 1) or Info.plist (Method 2)
- [ ] Identifier matches bundle ID: `com.samquested.grigrimvp`
- [ ] URL Scheme is: `crahg` (lowercase, no `://`)
- [ ] Role is set to: `Editor`
- [ ] Clean build performed (⌘⇧K)
- [ ] App rebuilt (⌘B)
- [ ] App installed on simulator/device
- [ ] Tested with: `xcrun simctl openurl booted "crahg://test"`
- [ ] Console shows: `🔗 App received URL: crahg://test`

## Next Steps

After configuring URL Types:

1. **Test Custom Scheme**: `xcrun simctl openurl booted "crahg://event/123"`
2. **Configure AASA**: For Universal Links (see AASA-Configuration.md)
3. **Test End-to-End**: Share a link from web app and open in iOS app
4. **Add Share Buttons**: In EventPageView and GymProfileView

## Resources

- **Apple Docs**: [Defining a Custom URL Scheme](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- **Info.plist Reference**: [CFBundleURLTypes](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/TP40009249-102207-TPXREF115)
- **URL Scheme Guidelines**: [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/system-capabilities/url-schemes/)

## Summary

URL Types configuration is a **one-time setup** that:
- Takes 2-3 minutes in Xcode
- Enables custom URL schemes (`crahg://`)
- Is required for deep linking to work
- Persists with your project

Once configured, your app can handle custom URLs immediately!
