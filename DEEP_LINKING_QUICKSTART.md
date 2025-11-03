# Deep Linking Quick Start Guide

## What Was Implemented

Your iOS app now supports deep linking! Users can share content from the web app (crahg.app) and open it directly in the iOS app.

### Supported Links
- **Events**: `https://crahg.app/events/{id}` → Opens event detail
- **Gyms**: `https://crahg.app/gyms/{id}` → Opens gym profile
- **Home**: `https://crahg.app/home` → Opens home tab
- **What's On**: `https://crahg.app/whats-on` → Opens events tab
- **Gyms List**: `https://crahg.app/gyms` → Opens gyms tab
- **Passes**: `https://crahg.app/passes` → Opens passes tab

### Custom URL Scheme (Fallback)
- `crahg://event/{id}`
- `crahg://gym/{id}`
- `crahg://home`
- `crahg://whatson`
- `crahg://gyms`
- `crahg://passes`

## Quick Test

### Test in Simulator
```bash
# Open terminal and run:
xcrun simctl openurl booted "crahg://event/event-123"
```

### Test on Device
1. Open Notes app
2. Type: `crahg://event/event-123`
3. Tap the link
4. App should open and navigate to event

## Next Steps

### 1. Xcode Configuration (Required - 2 minutes)
Configure URL scheme to enable `crahg://` links:

**Quick Steps:**
1. Open `GriGriMVP.xcodeproj` in Xcode
2. Select **GriGriMVP** target
3. Go to **Info** tab
4. Scroll to **URL Types** section
5. Click **+** to add:
   - **Identifier**: `com.samquested.grigrimvp`
   - **URL Schemes**: `crahg`
   - **Role**: `Editor`

**📖 Detailed Guide**: [URL-Types-Configuration-Guide.md](GriGriMVP/Documentation/URL-Types-Configuration-Guide.md)
*Complete step-by-step walkthrough with visual references, troubleshooting, and verification steps*

### 2. Web Server Setup (Required for Universal Links)
Deploy AASA file to enable `https://` links:

1. Get your Apple Team ID from [developer.apple.com](https://developer.apple.com/account/)
2. Create file: `public/.well-known/apple-app-site-association`
3. Add content:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YOUR_TEAM_ID.com.samquested.grigrimvp",
        "paths": ["/events/*", "/gyms/*", "/home", "/passes", "/whats-on"]
      }
    ]
  }
}
```
4. Deploy to `https://crahg.app/.well-known/apple-app-site-association`
5. Verify it's accessible (no .json extension)

**See**: [AASA-Configuration.md](GriGriMVP/Documentation/AASA-Configuration.md) for full guide

### 3. Test Deep Linking

#### Custom Scheme (Works Immediately)
```bash
# Simulator
xcrun simctl openurl booted "crahg://event/event-123"

# Device: Use Notes, Messages, or Safari
```

#### Universal Links (Requires AASA File)
1. Deploy AASA file (step 2 above)
2. Delete app from device
3. Reinstall app (iOS fetches AASA on install)
4. Test in Notes or Safari: `https://crahg.app/events/event-123`

## Files Modified/Created

### Modified
- ✅ `GriGriMVP.entitlements` - Added Associated Domains
- ✅ `GriGriMVPApp.swift` - Added URL logging
- ✅ `AppState.swift` - Integrated DeepLinkManager
- ✅ `MainTabView.swift` - Added deep link navigation

### Created
- ✅ `Services/DeepLinkManager.swift` - URL parsing and routing
- ✅ `Documentation/Deep-Linking-Setup.md` - Complete guide
- ✅ `Documentation/AASA-Configuration.md` - AASA setup
- ✅ `Documentation/Xcode-Configuration.md` - Xcode setup

## Architecture

```
Web Link Shared
       ↓
iOS Receives URL (crahg:// or https://)
       ↓
RootView.onOpenURL() catches it
       ↓
DeepLinkManager.handleURL() parses it
       ↓
Sets pendingDeepLink in AppState
       ↓
MainTabView detects pending link
       ↓
Fetches data (if needed)
       ↓
Navigates to content
       ↓
Clears pending link
```

## How It Works

### User Flow
1. **Share**: User shares event from web app
2. **Link**: Web generates `https://crahg.app/events/123`
3. **Tap**: Recipient taps link on their iPhone
4. **Open**: iOS opens your app (not Safari)
5. **Navigate**: App navigates directly to event 123
6. **View**: User sees event detail page

### Authentication Handling
- **Logged in**: Deep link processes immediately
- **Logged out**: Link is stored, processes after login

## Debugging

### Console Logs
The implementation includes extensive logging:
```
🔗 URL received: crahg://event/123
🔗 Custom scheme path: event, components: ["123"]
📌 Pending deep link set to: event(id: "123")
🎯 MainTabView: Processing deep link: event(id: "123")
✅ Pending deep link cleared
```

### Common Issues

**Links open Safari instead of app**
- AASA file not deployed correctly
- Need to reinstall app (delete first)
- Check Team ID in AASA file

**App crashes on deep link**
- Check console for error messages
- Verify event/gym ID exists in database
- Check repository implementation

**Navigation doesn't work**
- Ensure user is authenticated
- Check logs for 🎯 messages
- Verify navigation destinations exist

## Testing Checklist

- [ ] Custom URL scheme configured in Xcode
- [ ] Test `crahg://event/123` in simulator
- [ ] Test `crahg://gym/456` in simulator
- [ ] AASA file deployed to `crahg.app/.well-known/`
- [ ] AASA file accessible (check with curl)
- [ ] Team ID correct in AASA file
- [ ] App deleted and reinstalled on device
- [ ] Test `https://crahg.app/events/123` on device
- [ ] Test from Notes app
- [ ] Test from Messages app
- [ ] Test from Safari

## Support

### Documentation
- **Full Guide**: [Deep-Linking-Setup.md](GriGriMVP/Documentation/Deep-Linking-Setup.md)
- **AASA Setup**: [AASA-Configuration.md](GriGriMVP/Documentation/AASA-Configuration.md)
- **Xcode Config**: [Xcode-Configuration.md](GriGriMVP/Documentation/Xcode-Configuration.md)

### Apple Resources
- [Universal Links Guide](https://developer.apple.com/ios/universal-links/)
- [Handling Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)

### Validation Tools
- [AASA Validator](https://branch.io/resources/aasa-validator/)
- [Universal Links Tester](https://search.developer.apple.com/appsearch-validation-tool/)

## What's Next?

### Recommended Additions
1. **Share Buttons**: Add share functionality in EventPageView and GymProfileView
2. **Analytics**: Track which deep links are most used
3. **Smart Banners**: Add iOS Smart App Banners on web
4. **Dynamic Links**: Consider Firebase Dynamic Links for advanced features
5. **QR Codes**: Generate QR codes for events/gyms

### Integration with Web App
Your web app (crahg.app) already has the infrastructure:
- ✅ `DeepLinkManager` for iOS detection
- ✅ `ShareManager` for generating share content
- ✅ Banner to prompt app installation
- ✅ Matching URL structure

Just need to:
1. Deploy AASA file
2. Test end-to-end flow
3. Add share buttons where needed

## Success Metrics

Track these to measure adoption:
- Number of deep links opened
- Conversion rate: clicks → app opens
- Most shared content types
- User retention from deep links

## Questions?

Check the detailed documentation files in:
```
GriGriMVP/Documentation/
├── Deep-Linking-Setup.md (Main guide)
├── AASA-Configuration.md (Web setup)
└── Xcode-Configuration.md (App setup)
```

Happy linking! 🔗
