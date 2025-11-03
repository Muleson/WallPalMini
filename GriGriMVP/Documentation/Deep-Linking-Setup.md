# Deep Linking Implementation Guide

## Overview
Deep linking allows users to share content from the web app (crahg.app) and open it directly in the iOS app. This implementation supports both **Universal Links** (https://) and **Custom URL Schemes** (crahg://).

## Architecture

### Components
1. **DeepLinkManager** (`Services/DeepLinkManager.swift`)
   - Parses incoming URLs
   - Determines navigation destination
   - Manages pending deep links

2. **AppState** (`Services/AppState.swift`)
   - Holds instance of DeepLinkManager
   - Shared across the app

3. **RootView** (`Services/AppState.swift`)
   - Receives initial URLs via `.onOpenURL`
   - Delegates to DeepLinkManager

4. **MainTabView** (`Views/MainTabView.swift`)
   - Processes pending deep links
   - Navigates to appropriate content
   - Fetches data if needed

## Supported URL Formats

### Universal Links (Primary)
- **Event**: `https://crahg.app/events/{eventId}`
- **Gym**: `https://crahg.app/gyms/{gymId}`
- **Home**: `https://crahg.app/home`
- **Passes**: `https://crahg.app/passes`
- **What's On**: `https://crahg.app/whats-on`
- **Gyms List**: `https://crahg.app/gyms`

### Custom URL Scheme (Fallback)
- **Event**: `crahg://event/{eventId}`
- **Gym**: `crahg://gym/{gymId}`
- **Home**: `crahg://home`
- **Passes**: `crahg://passes`
- **What's On**: `crahg://whatson` or `crahg://whats-on`
- **Gyms List**: `crahg://gyms`

## Configuration

### 1. Associated Domains (Entitlements)
Located in: `GriGriMVP.entitlements`

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:crahg.app</string>
    <string>applinks:www.crahg.app</string>
</array>
```

### 2. Info.plist (URL Schemes)
Add to your Info.plist:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.samquested.grigrimvp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>crahg</string>
        </array>
    </dict>
</array>
```

### 3. Apple App Site Association (AASA) File
The web server at `crahg.app` must serve this file at:
- `https://crahg.app/.well-known/apple-app-site-association`

Example AASA file:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.samquested.grigrimvp",
        "paths": [
          "/events/*",
          "/gyms/*",
          "/home",
          "/passes",
          "/whats-on"
        ]
      }
    ]
  }
}
```

**Important:** Replace `TEAMID` with your actual Apple Developer Team ID.

## Testing Deep Links

### Testing on Simulator

#### Method 1: Command Line
```bash
# Test event deep link
xcrun simctl openurl booted "crahg://event/event-123"

# Test gym deep link
xcrun simctl openurl booted "crahg://gym/gym-456"

# Test universal link
xcrun simctl openurl booted "https://crahg.app/events/event-123"
```

#### Method 2: Safari in Simulator
1. Open Safari in the simulator
2. Type a URL in the address bar: `crahg://event/event-123`
3. Press Go

### Testing on Physical Device

#### Method 1: Notes App
1. Open Notes app
2. Type a URL: `crahg://event/event-123`
3. Tap the URL

#### Method 2: Messages App
1. Open Messages
2. Send yourself a URL: `https://crahg.app/events/event-123`
3. Tap the URL

#### Method 3: QR Code
1. Generate a QR code with the URL
2. Scan with Camera app
3. Tap the notification

#### Method 4: Safari
1. Open Safari
2. Navigate to: `https://crahg.app/events/event-123`
3. The app should open (if AASA is configured)

## Navigation Flow

### Authenticated Users
1. User taps shared link
2. App launches/opens
3. `RootView.onOpenURL` receives URL
4. `DeepLinkManager.handleURL()` parses URL
5. Deep link is set as pending
6. `MainTabView` detects pending link
7. Switches to appropriate tab
8. Fetches data (if needed)
9. Navigates to detail view
10. Clears pending link

### Unauthenticated Users
1. User taps shared link
2. App launches
3. Deep link is stored as pending
4. User sees auth screen
5. User logs in
6. `MainTabView` appears
7. Pending deep link is processed
8. User navigates to content

## Debugging

### Enable Console Logging
The implementation includes extensive logging with emoji prefixes:
- 🔗 URL handling
- 🎯 Navigation processing
- ⚠️ Warnings
- ❌ Errors
- 📌 Pending link state
- ✅ Success messages

### Common Issues

#### Universal Links Not Working
1. **Check AASA file**: Visit `https://crahg.app/.well-known/apple-app-site-association`
2. **Verify Team ID**: Must match your Apple Developer account
3. **Domain must use HTTPS**: HTTP won't work
4. **Reinstall app**: AASA is cached during installation
5. **Check entitlements**: Verify Associated Domains are correct

#### Custom Scheme Not Working
1. **Check Info.plist**: Ensure URL scheme is registered
2. **Reinstall app**: URL schemes are registered at install time
3. **Check for conflicts**: Ensure no other app uses `crahg://`

#### Navigation Not Triggering
1. **Check logs**: Look for 🔗 and 🎯 emoji in console
2. **Verify event/gym ID**: Ensure the ID exists in your database
3. **Check authentication**: Deep links only process when authenticated
4. **Repository errors**: Check for ❌ error messages

## Web Integration

The web app (crahg.app) uses matching URLs, so sharing is seamless:

**Web URL** → **iOS Deep Link**
- `https://crahg.app/events/123` → Opens event 123 in app
- `https://crahg.app/gyms/456` → Opens gym 456 in app

### Share Functionality
Users can share from:
1. Event detail pages
2. Gym profile pages
3. Social sharing buttons
4. QR code generation

The web app automatically:
1. Detects iOS devices
2. Shows "Open in App" banner
3. Attempts to open the app
4. Falls back to App Store if not installed

## Future Enhancements

### Potential Additions
1. **User profiles**: `crahg://user/{userId}`
2. **Passes**: Direct linking to specific passes
3. **Search results**: Deep link to filtered content
4. **Onboarding**: `crahg://onboarding`
5. **Analytics**: Track deep link attribution
6. **Deferred deep linking**: Link attribution post-install
7. **Dynamic Links**: Firebase Dynamic Links integration

### Advanced Features
- **Smart Banners**: iOS Smart App Banners on web
- **Clipboard Detection**: Auto-detect URLs in clipboard
- **Push Notifications**: Deep linking from notifications
- **Widgets**: Deep link from home screen widgets
- **Spotlight**: Search results that deep link
- **Handoff**: Continue between devices

## Security Considerations

1. **Validate IDs**: Always validate event/gym IDs from URLs
2. **Auth checks**: Ensure user has permission to view content
3. **Rate limiting**: Prevent abuse of data fetching
4. **Error handling**: Gracefully handle invalid/expired links
5. **Privacy**: Don't expose sensitive user data in URLs

## Maintenance

### When Adding New Content Types
1. Add enum case to `DeepLinkDestination`
2. Update parsing in `DeepLinkManager`
3. Add navigation case in `MainTabView.handlePendingDeepLink()`
4. Update AASA file on web server
5. Update documentation
6. Add tests

### When Changing URL Structure
1. **Maintain backwards compatibility**: Old links should still work
2. Update `DeepLinkManager` parsing logic
3. Update web app link generation
4. Update AASA file
5. Test extensively
6. Document breaking changes

## Support & Resources

- **Apple Documentation**: [Universal Links](https://developer.apple.com/ios/universal-links/)
- **Testing Tool**: [Branch Link Tester](https://branch.io/resources/aasa-validator/)
- **AASA Validator**: [Universal Links Validator](https://branch.io/resources/aasa-validator/)
