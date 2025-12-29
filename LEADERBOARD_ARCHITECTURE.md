# GridRun Leaderboard Architecture Documentation

## Overview
This document explains how leaderboard scores are stored, updated, and retrieved in the GridRun game.

## Storage Mechanism

### Primary Storage: Supabase (Cloud Database)
Leaderboard scores are **stored in Supabase**, a cloud PostgreSQL database, NOT in localStorage.

**Table**: `leaderboards`

**Schema**:
- `user_id` (uuid, primary key): Unique user identifier from Supabase Auth
- `username` (text, unique): Player's display name
- `endless_best` (integer): Best score in Endless mode
- `campaign_total` (integer): Sum of all campaign level best scores
- `world_totals` (array of integers): Array of 3 integers for each world's total score
- `updated_at` (timestamp): Last update timestamp

### Secondary Storage: Progress Data (Supabase + localStorage fallback)
Player progress (unlocked levels, best scores per level) is stored separately:

**Table**: `progress`
- Stores per-level best scores in `best_scores` field (3x5 array)
- Stores `endless_best` score
- Falls back to localStorage if user is not logged in or Supabase is unavailable

## Data Flow

### 1. Score Update Flow
```
Player completes level/endless run
    ↓
Update local progress (saveProgress)
    ↓
Calculate totals from progress (sumCampaignTotals)
    ↓
Upsert to Supabase leaderboards table (updateLeaderboardsFromProgress)
    ↓
Realtime subscription notifies all clients
    ↓
UI auto-refreshes leaderboard display
```

### 2. Leaderboard Display Flow
```
User opens leaderboards screen (loadLeaderboards)
    ↓
Update leaderboards from current progress (updateLeaderboardsFromProgress)
    ↓
Subscribe to realtime updates (subscribeToLeaderboardUpdates)
    ↓
Fetch top 100 from Supabase (buildRanking)
    ↓
Sort client-side by selected metric
    ↓
Render top 25 in UI (renderLeaderboardList)
```

### 3. Realtime Update Flow
```
Any player anywhere improves their score
    ↓
Supabase database triggers postgres_changes event
    ↓
All subscribed clients receive notification via websocket
    ↓
Callback re-fetches and re-renders current leaderboard tab
```

## Key Functions

### `updateLeaderboardsFromProgress()`
**Location**: Line 708-741  
**Purpose**: Synchronizes player's current progress to the leaderboards table  
**When called**:
- On login (line 1273)
- On account creation (line 1337)
- After completing a level (line 1555)
- After ending an endless run (line 1562)
- When opening leaderboards screen (line 1453)
- When manually refreshing (line 852)

**Implementation**:
```javascript
async function updateLeaderboardsFromProgress(){
  // 1. Get current authenticated user
  // 2. Load player's progress from database
  // 3. Calculate campaign and world totals
  // 4. Upsert to leaderboards table with user_id as key
}
```

### `buildRanking(metric)`
**Location**: Line 743-799  
**Purpose**: Fetches and sorts leaderboard data for a specific metric  
**Parameters**: 
- `metric`: "endless", "campaign", "w1", "w2", or "w3"

**Implementation**:
```javascript
async function buildRanking(metric){
  // 1. Fetch top 100 entries from Supabase
  // 2. Clean and normalize data
  // 3. Sort by selected metric (score descending, then by timestamp)
  // 4. Return sorted list and score accessor function
}
```

### `subscribeToLeaderboardUpdates(callback)`
**Location**: Line 801-827  
**Purpose**: Subscribes to realtime database changes  
**Implementation**:
```javascript
function subscribeToLeaderboardUpdates(callback) {
  // 1. Create Supabase realtime channel
  // 2. Listen for all postgres_changes on leaderboards table
  // 3. Call provided callback when changes occur
  // 4. Callback re-renders the active leaderboard tab
}
```

## Current Issues Identified

### Issue 1: No Handling of Database Resets
**Problem**: If an administrator resets scores in the database, clients don't automatically detect or refresh the data beyond the realtime subscription.

**Impact**: 
- Cached data may show stale scores
- No manual way for users to force a refresh
- Progress data and leaderboard data may become out of sync

**Recommendation**: Add manual refresh functionality

### Issue 2: No Cache Invalidation
**Problem**: Leaderboard data is fetched fresh each time, but there's no explicit cache invalidation strategy when user logs in/out.

**Impact**: 
- User sees previous data briefly before refresh
- Multiple unnecessary fetches on tab switches

**Recommendation**: Implement proper cache invalidation

### Issue 3: No Error Recovery for Stale Data
**Problem**: If a fetch fails or returns stale data, there's no retry mechanism.

**Impact**:
- Users may see empty leaderboards temporarily
- No visual feedback that data is being refreshed

**Recommendation**: Add loading states and retry logic

## Recommendations for Database Reset Handling

### 1. Add Manual Refresh Button
Add a refresh button to the leaderboards UI that:
- Re-fetches all leaderboard data
- Re-synchronizes user's progress
- Provides visual feedback (spinner/animation)

### 2. Implement Periodic Auto-Refresh
Add a background timer that:
- Checks for data freshness every 30-60 seconds
- Compares local cached timestamp with server
- Refreshes if discrepancy detected

### 3. Add Loading States
Implement proper loading indicators:
- Show spinner when fetching data
- Display "Refreshing..." message
- Handle error states gracefully

### 4. Version/Timestamp Checking
Add version field to leaderboards:
- Track last reset timestamp in database
- Compare on each fetch
- Force full refresh if reset detected

## Testing Recommendations

### Test Scenario 1: Score Reset Recovery
1. Player views leaderboards
2. Admin resets scores in database
3. Player should see updated (empty/reset) leaderboards
4. Player completes a run
5. New score should appear correctly

### Test Scenario 2: Concurrent Updates
1. Multiple players complete runs simultaneously
2. All players should see realtime updates
3. Scores should be correctly ordered
4. No duplicate entries should appear

### Test Scenario 3: Offline/Online Transitions
1. Player goes offline
2. Completes runs (progress saves locally)
3. Returns online
4. Progress should sync to leaderboards
5. Leaderboards should reflect new scores

## Code Locations Reference

| Feature | File | Line Range | Function |
|---------|------|------------|----------|
| Supabase Init | index_dev.html | 240-261 | Global |
| Leaderboard Update | index_dev.html | 708-741 | updateLeaderboardsFromProgress() |
| Fetch Rankings | index_dev.html | 743-799 | buildRanking() |
| Realtime Subscribe | index_dev.html | 801-827 | subscribeToLeaderboardUpdates() |
| Manual Refresh | index_dev.html | 836-874 | refreshLeaderboardManually() |
| Render UI | index_dev.html | 1391-1443 | renderLeaderboardList() |
| Load Screen | index_dev.html | 1445-1517 | loadLeaderboards() |
| Progress Storage | index_dev.html | 429-486 | loadProgress() |
| Progress Save | index_dev.html | 518-547 | saveProgress() |

## Dependencies

### External Libraries
- **Supabase JS Client**: v2.39.0 (CDN loaded)
- **Phaser**: v3.80.1 (Game engine, not related to leaderboards)

### Database Tables Required
1. `leaderboards` - Stores public leaderboard data
2. `progress` - Stores per-user game progress
3. `settings` - Stores per-user settings (audio, etc.)

### Supabase Features Used
- **Authentication**: User management and session handling
- **Realtime**: WebSocket subscriptions for live updates
- **Database**: PostgreSQL queries (select, upsert)

## Security Considerations

### Row Level Security (RLS)
The implementation assumes Supabase RLS policies are configured to:
- Allow authenticated users to read all leaderboard data
- Allow authenticated users to update only their own leaderboard row
- Allow authenticated users to read/write only their own progress
- Allow authenticated users to read/write only their own settings

### Data Validation
- Username uniqueness enforced at database level
- Score values are validated (Math.floor, Math.max)
- User ID from auth token prevents spoofing

## Future Enhancements

### Recommended Additions
1. **Pagination**: Load more than 100 entries on demand
2. **Filtering**: Filter by date range, world, or mode
3. **Search**: Search for specific usernames
4. **Historical Data**: Track score history over time
5. **Achievements**: Badge system for milestones
6. **Seasons**: Periodic leaderboard resets with archival

### Performance Optimizations
1. **Caching**: Implement client-side cache with TTL
2. **Debouncing**: Debounce rapid score updates
3. **Lazy Loading**: Load leaderboard data only when viewed
4. **Compression**: Use database views for pre-computed totals
