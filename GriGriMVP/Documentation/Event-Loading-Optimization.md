# Event Loading Optimization

## Overview

This document describes the optimization implemented to reduce unnecessary database calls when loading events for display purposes in the user-facing parts of the application.

## Problem

Originally, every time events were loaded from the database, both the **author** (User) and **host** (Gym) information were fetched for each event. However, analysis of the UI revealed that:

1. **Event cards never display author information** - Only host (gym) information is shown
2. **User-facing ViewModels don't use the author property** - Only admin/management functions need author data
3. **This caused unnecessary database calls** - Each event fetch triggered additional User lookups that weren't used

## Solution

### New Display-Optimized Methods

Added new methods to the repository layer that skip author lookups for display purposes:

#### Repository Protocol Extensions
```swift
// EventRepositoryProtocol.swift
extension EventRepositoryProtocol {
    func fetchAllEventsForDisplay() async throws -> [EventItem]
    func fetchEventsForGymDisplay(gymId: String) async throws -> [EventItem]
    func fetchFavoriteEventsForDisplay(userId: String) async throws -> [EventItem]
    func searchEventsForDisplay(query: String) async throws -> [EventItem]
}
```

#### Firebase Implementation
- `FirebaseEventRepository.decodeEventForDisplay()` - Only fetches host (gym) data, skips author lookup
- Author property remains as placeholder (not used in display)

#### Cached Implementation
- `CachedEventRepository` implements the display methods with appropriate caching strategies
- Maintains same cache performance while reducing initial database load

### Updated ViewModels

The following ViewModels now use optimized display methods:

1. **UpcomingViewModel** - `fetchAllEventsForDisplay()`
2. **HomeViewModel** - `fetchAllEventsForDisplay()`
3. **GymsViewModel** - `fetchEventsForGymDisplay(gymId:)`

### When to Use Each Method

| Use Case | Method | Author Data | Reason |
|----------|--------|-------------|---------|
| Event display cards | `fetchAllEventsForDisplay()` | ❌ Placeholder | UI doesn't show author |
| Event management | `fetchAllEvents()` | ✅ Full data | Needed for editing |
| User profile (created events) | `fetchEventsCreatedByUser()` | ✅ Full data | Author context needed |
| Event editing | `getEvent(id:)` | ✅ Full data | Full context needed |

## Performance Impact

### Before Optimization
- **Fetch 10 events**: 10 event docs + 10 user docs + 10 gym docs = **30 database reads**
- **Fetch 100 events**: 100 event docs + 100 user docs + 100 gym docs = **300 database reads**

### After Optimization
- **Fetch 10 events for display**: 10 event docs + 10 gym docs = **20 database reads** (33% reduction)
- **Fetch 100 events for display**: 100 event docs + 100 gym docs = **200 database reads** (33% reduction)

## Implementation Details

### Key Files Modified

1. **EventRepositoryProtocol.swift** - Added display-optimized method signatures
2. **FirebaseEventRepository.swift** - Added `decodeEventForDisplay()` method
3. **CachedEventRepository.swift** - Added cached versions of display methods
4. **UpcomingViewModel.swift** - Updated to use `fetchAllEventsForDisplay()`
5. **HomeViewModel.swift** - Updated to use `fetchAllEventsForDisplay()`
6. **GymsViewModel.swift** - Updated to use `fetchEventsForGymDisplay()`

### Backward Compatibility

- Original methods remain unchanged
- Event management functionality unaffected
- Full author data still available when needed

## Future Considerations

1. **Monitor cache hit rates** - Ensure display-optimized methods benefit from caching
2. **Consider lazy loading** - Load author data on-demand if needed for specific UI features
3. **Extend optimization** - Apply similar patterns to other data models if needed

## Testing

The optimization maintains the same UI behavior while reducing database calls. Testing should verify:

1. Event cards display correctly (host information shown)
2. Event management features work (author data available when needed)
3. Performance improvement measurable in network tab/database monitoring
