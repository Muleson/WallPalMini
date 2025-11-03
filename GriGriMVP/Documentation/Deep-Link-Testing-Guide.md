# Deep Link Testing Guide

## What Was Fixed

The navigation issue where deep links only opened the home page has been resolved. The problem was:
- Each tab had its own `NavigationStack` but only the home tab had a bound `navigationPath`
- When navigating to events/gyms, the code was using the home tab's navigation path
- Now each tab has its own navigation path that's properly bound

## Testing Your Deep Links

### 1. Test Event Deep Links

#### Using Terminal (Simulator)
```bash
# Test with a real event ID from your database
xcrun simctl openurl booted "crahg://event/YOUR_EVENT_ID"
```

#### Expected Console Output
```
🔗 App received URL: crahg://event/YOUR_EVENT_ID
🔗 RootView received URL: crahg://event/YOUR_EVENT_ID
🔗 DeepLinkManager: Handling URL: crahg://event/YOUR_EVENT_ID
🔗 Custom scheme path: event, components: ["YOUR_EVENT_ID"]
📌 DeepLinkManager: Pending deep link set to: event(id: "YOUR_EVENT_ID")
🎯 MainTabView: Processing deep link: event(id: "YOUR_EVENT_ID")
🔍 Fetching event with ID: YOUR_EVENT_ID
✅ Event found: Event Name Here
📍 Navigated to event: Event Name Here
✅ DeepLinkManager: Pending deep link cleared
```

#### Expected Behavior
1. App launches/activates
2. Switches to "What's On" tab (calendar icon)
3. Fetches event data
4. Navigates to event detail page
5. Shows full event information

### 2. Test Gym Deep Links

#### Using Terminal (Simulator)
```bash
# Test with a real gym ID from your database
xcrun simctl openurl booted "crahg://gym/YOUR_GYM_ID"
```

#### Expected Console Output
```
🔗 App received URL: crahg://gym/YOUR_GYM_ID
🔗 RootView received URL: crahg://gym/YOUR_GYM_ID
🔗 DeepLinkManager: Handling URL: crahg://gym/YOUR_GYM_ID
🔗 Custom scheme path: gym, components: ["YOUR_GYM_ID"]
📌 DeepLinkManager: Pending deep link set to: gym(id: "YOUR_GYM_ID")
🎯 MainTabView: Processing deep link: gym(id: "YOUR_GYM_ID")
🔍 Fetching gym with ID: YOUR_GYM_ID
✅ Gym found: Gym Name Here
📍 Navigated to gym: Gym Name Here
✅ DeepLinkManager: Pending deep link cleared
```

#### Expected Behavior
1. App launches/activates
2. Switches to "Gyms" tab (building icon)
3. Fetches gym data
4. Navigates to gym profile page
5. Shows full gym information

### 3. Test Tab Navigation

#### Home Tab
```bash
xcrun simctl openurl booted "crahg://home"
```
**Expected**: Opens home tab

#### Passes Tab
```bash
xcrun simctl openurl booted "crahg://passes"
```
**Expected**: Opens passes tab

#### What's On Tab
```bash
xcrun simctl openurl booted "crahg://whatson"
```
**Expected**: Opens events tab (but stays at list view)

#### Gyms Tab
```bash
xcrun simctl openurl booted "crahg://gyms"
```
**Expected**: Opens gyms tab (but stays at list view)

### 4. Test Universal Links (After AASA Setup)

Once you've deployed the AASA file:

```bash
# Test universal links
xcrun simctl openurl booted "https://crahg.app/events/YOUR_EVENT_ID"
xcrun simctl openurl booted "https://crahg.app/gyms/YOUR_GYM_ID"
```

Should work identically to custom scheme URLs.

## Testing on Physical Device

### Method 1: Notes App
1. Open Notes
2. Create a new note
3. Type: `crahg://event/YOUR_EVENT_ID`
4. The text should become a blue clickable link
5. Tap the link
6. App should open and navigate to event

### Method 2: Messages App
1. Open Messages
2. Send yourself a message: `crahg://event/YOUR_EVENT_ID`
3. Tap the link
4. App should open and navigate to event

### Method 3: Safari
1. Open Safari
2. Type in address bar: `crahg://event/YOUR_EVENT_ID`
3. Press Go
4. Safari should ask to open in GriGriMVP
5. Tap "Open"
6. App should navigate to event

### Method 4: Web App (Once Integrated)
1. Open your web app in Safari: `https://crahg.app`
2. Navigate to an event
3. Tap the share button (if implemented)
4. Copy link or share via Messages
5. Tap the shared link
6. App should open and navigate to that event

## Debugging Failed Navigation

### Issue: App Opens but Stays on Home Tab

**Check Console for:**
```
⚠️ Event not found: YOUR_EVENT_ID
```

**Cause**: Event ID doesn't exist in your database

**Solution**: Use a valid event ID from your database

---

### Issue: App Opens but Shows Events List (Not Detail)

**Check Console for:**
```
❌ Error fetching event: [error details]
```

**Causes**:
1. Repository error
2. Network/Firebase error
3. Permission error

**Solutions**:
1. Check Firebase connection
2. Verify user authentication
3. Check repository implementation
4. Verify event ID format is correct

---

### Issue: No Console Output at All

**Cause**: Deep link not being received

**Solutions**:
1. Verify URL scheme is registered in Xcode
2. Rebuild app (clean build folder)
3. Reinstall app
4. Check URL format is correct

---

### Issue: Console Shows Navigation but UI Doesn't Update

**Check for:**
```
📍 Navigated to event: Event Name
```

**If you see this but UI doesn't update:**
1. Try with a longer delay (increase from 0.1 to 0.3 seconds)
2. Check `EventPageView` is properly configured
3. Verify navigation destination is set up

## Finding Valid IDs for Testing

### Get Event IDs

#### From Firebase Console
1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to `events` collection
4. Copy an event document ID
5. Use that ID for testing

#### From Your App
1. Run app in simulator
2. Go to "What's On" tab
3. Open Xcode console
4. Look for event IDs in logs
5. Or add temporary print statement in `UpcomingEventsView`

### Get Gym IDs

#### From Firebase Console
1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to `gyms` collection
4. Copy a gym document ID
5. Use that ID for testing

#### From Your App
1. Run app in simulator
2. Go to "Gyms" tab
3. Open Xcode console
4. Look for gym IDs in logs
5. Or add temporary print statement in `GymsListView`

## Testing Checklist

Before considering deep linking complete:

- [ ] Custom URL scheme registered in Xcode
- [ ] App builds without errors
- [ ] Test: `crahg://home` opens home tab
- [ ] Test: `crahg://passes` opens passes tab
- [ ] Test: `crahg://whatson` opens events tab
- [ ] Test: `crahg://gyms` opens gyms tab
- [ ] Test: `crahg://event/{valid-id}` navigates to event detail
- [ ] Test: `crahg://gym/{valid-id}` navigates to gym detail
- [ ] Test: Invalid event ID shows warning in console
- [ ] Test: Invalid gym ID shows warning in console
- [ ] Console shows all expected emoji logs (🔗, 🎯, ✅, etc.)
- [ ] Navigation works from app closed state
- [ ] Navigation works from app background state
- [ ] Navigation works from app foreground state

### Optional (After AASA Deployment):
- [ ] AASA file deployed to `crahg.app/.well-known/`
- [ ] AASA file accessible via curl
- [ ] App deleted and reinstalled
- [ ] Test: `https://crahg.app/events/{id}` works
- [ ] Test: `https://crahg.app/gyms/{id}` works
- [ ] Universal links tested on physical device
- [ ] Universal links tested from Safari
- [ ] Universal links tested from Messages

## Advanced Testing Scenarios

### Scenario 1: Deep Link While Logged Out
1. Log out of app
2. Close app completely
3. Tap deep link: `crahg://event/YOUR_EVENT_ID`
4. **Expected**:
   - App opens
   - Shows login screen
   - After login, navigates to event

### Scenario 2: Deep Link While on Different Tab
1. Open app
2. Navigate to Passes tab
3. Switch to another app
4. Tap deep link: `crahg://gym/YOUR_GYM_ID`
5. **Expected**:
   - App comes to foreground
   - Switches from Passes to Gyms tab
   - Navigates to gym detail

### Scenario 3: Multiple Deep Links in Sequence
1. Tap: `crahg://event/EVENT_1`
2. Wait for navigation
3. Press home button
4. Tap: `crahg://event/EVENT_2`
5. **Expected**: Navigates to EVENT_2 (not EVENT_1)

### Scenario 4: Deep Link to Non-Existent Content
1. Tap: `crahg://event/FAKE_ID_12345`
2. **Expected**:
   - App opens
   - Switches to Events tab
   - Shows warning in console
   - Stays on events list (no navigation)

## Performance Testing

### Measure Navigation Time
Add this to test performance:

```swift
// In MainTabView.handlePendingDeepLink()
let startTime = Date()

// After navigation completes
let elapsedTime = Date().timeIntervalSince(startTime)
print("⏱️ Navigation took \(elapsedTime) seconds")
```

**Target**: < 1 second for navigation
**Acceptable**: < 2 seconds
**Needs optimization**: > 2 seconds

## What to Look For in Console

### ✅ Successful Event Deep Link
```
🔗 App received URL: crahg://event/abc123
🔗 DeepLinkManager: Handling URL
📌 Pending deep link set
🎯 Processing deep link: event(id: "abc123")
🔍 Fetching event with ID: abc123
✅ Event found: Amazing Event
📍 Navigated to event: Amazing Event
✅ Pending deep link cleared
```

### ⚠️ Invalid Event ID
```
🔗 App received URL: crahg://event/invalid
🔗 DeepLinkManager: Handling URL
📌 Pending deep link set
🎯 Processing deep link: event(id: "invalid")
🔍 Fetching event with ID: invalid
⚠️ Event not found: invalid
✅ Pending deep link cleared
```

### ❌ Repository Error
```
🔗 App received URL: crahg://event/abc123
🔗 DeepLinkManager: Handling URL
📌 Pending deep link set
🎯 Processing deep link: event(id: "abc123")
🔍 Fetching event with ID: abc123
❌ Error fetching event: [error details here]
✅ Pending deep link cleared
```

## Next Steps After Successful Testing

1. **Add Share Buttons**: Implement share functionality in event/gym detail views
2. **Analytics**: Track deep link usage
3. **Error UI**: Show user-friendly errors for invalid links
4. **Loading States**: Add loading indicators during fetch
5. **Fallback Handling**: Graceful degradation for errors
6. **Web Integration**: Deploy AASA file and test universal links
7. **QR Codes**: Generate QR codes for easy sharing
8. **Push Notifications**: Deep link from notifications

## Troubleshooting Quick Reference

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| No console output | URL scheme not registered | Check Xcode Info → URL Types |
| Opens but no navigation | Wrong event/gym ID | Use valid ID from database |
| Error fetching event | Repository/Firebase issue | Check network, authentication |
| Navigation to wrong tab | DeepLinkManager routing error | Check switch statement in handlePendingDeepLink |
| UI doesn't update | Navigation path issue | Check navigationDestination is set up |
| Works in simulator, not device | App not reinstalled | Delete and reinstall app |

## Getting Help

If navigation still doesn't work:

1. **Check all console logs**: Copy full console output
2. **Verify event/gym exists**: Check Firebase console
3. **Test with different IDs**: Try multiple events/gyms
4. **Clean build**: Product → Clean Build Folder
5. **Restart Xcode**: Sometimes helps with state issues
6. **Review code**: Check MainTabView navigation setup

## Success Criteria

Deep linking is working correctly when:

✅ You can navigate to specific events via `crahg://event/{id}`
✅ You can navigate to specific gyms via `crahg://gym/{id}`
✅ Tab switching works correctly
✅ Console shows complete log trail
✅ Navigation works from all app states (closed, background, foreground)
✅ Invalid IDs are handled gracefully
✅ No crashes or errors

Once all tests pass, your deep linking is production-ready! 🎉
