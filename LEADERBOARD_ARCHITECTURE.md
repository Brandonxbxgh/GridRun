# GridRun Leaderboard Architecture Documentation

## Overview
This document explains how leaderboard scores are stored, updated, and retrieved in the GridRun game.

## Storage Mechanism

### Two-Table Architecture ⚠️ IMPORTANT

GridRun uses **TWO separate tables** for player data:

#### 1. `progress` Table (Source of Truth)
Stores detailed per-level game progress:
- `user_id` (uuid, primary key): Unique user identifier
- `worlds_unlocked` (integer): Number of worlds unlocked (1-3)
- `levels_unlocked` (integer array): Levels unlocked per world [5, 3, 0]
- `best_scores` (integer 2D array): Best scores per level [[w1l1,w1l2,...],[w2l1,...],[w3l1,...]]
- `endless_best` (integer): Best score in Endless mode
- `updated_at` (timestamp): Last update timestamp

#### 2. `leaderboards` Table (Calculated Display)
Stores aggregated scores for leaderboard display:
- `user_id` (uuid, primary key): Unique user identifier from Supabase Auth
- `username` (text, unique): Player's display name
- `endless_best` (integer): Best score in Endless mode (copied from progress)
- `campaign_total` (integer): Sum of all campaign level best scores (calculated)
- `world_totals` (array of integers): Array of 3 integers for each world's total score (calculated)
- `updated_at` (timestamp): Last update timestamp

### Why Two Tables?

The separation provides important benefits:
- **Performance**: Fast leaderboard queries without calculating sums every time
- **Detail**: Progress table maintains per-level granularity for gameplay
- **Flexibility**: Can recalculate leaderboards if scoring logic changes
- **Efficiency**: Realtime updates only broadcast aggregated data

### ⚠️ Critical for Database Resets

**When resetting scores, you MUST reset BOTH tables:**

1. If you only reset `leaderboards`:
   - ❌ Scores reappear when users log in
   - ❌ `updateLeaderboardsFromProgress()` recalculates from `progress` table
   - ❌ Old scores are restored automatically

2. To properly reset, update BOTH tables:
   ```sql
   UPDATE progress SET best_scores = ..., endless_best = 0;
   UPDATE leaderboards SET campaign_total = 0, endless_best = 0, ...;
   ```

**See `RESET_SCORES.md` for complete reset instructions.**

### localStorage Fallback
Progress falls back to localStorage if:
- User is not logged in
- Supabase is not configured
- Supabase connection fails

**Note**: localStorage is only for progress, never for leaderboards. Leaderboards require authentication.

## Data Flow

### Table Relationship

```
progress table                    leaderboards table
(source of truth)                 (calculated display)
═════════════════                 ═══════════════════
user_id                    ─────> user_id
worlds_unlocked                   username
levels_unlocked                   
best_scores (3x5 array)    ─────> campaign_total (sum of best_scores)
                           ─────> world_totals (sum per world)
endless_best               ─────> endless_best (copied)
updated_at                        updated_at

              updateLeaderboardsFromProgress()
              (recalculates and syncs)
```

**Key Insight**: The `leaderboards` table is a **cached/calculated view** of the `progress` table. It's automatically regenerated whenever `updateLeaderboardsFromProgress()` is called.

### 1. Score Update Flow
```
Player completes level/endless run
    ↓
saveProgress() → progress table (source of truth updated)
    ↓
Calculate totals from progress (sumCampaignTotals)
    ↓
updateLeaderboardsFromProgress() → leaderboards table (calculated view updated)
    ↓
Realtime subscription notifies all clients
    ↓
UI auto-refreshes leaderboard display
```

### 2. Leaderboard Display Flow
```
User opens leaderboards screen (loadLeaderboards)
    ↓
updateLeaderboardsFromProgress() → Sync progress to leaderboards
    ↓
Subscribe to realtime updates (subscribeToLeaderboardUpdates)
    ↓
buildRanking() → Fetch top 100 from leaderboards table
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

## Common Issues and Solutions

### Issue 1: Scores Reappear After Resetting Leaderboards ⚠️ CRITICAL
**Problem**: Administrator resets the `leaderboards` table, but scores reappear when users log in.

**Root Cause**: The `progress` table is the source of truth. When users log in or refresh:
1. App calls `updateLeaderboardsFromProgress()`
2. Function reads from `progress` table (which still has old scores)
3. Function recalculates and re-inserts scores into `leaderboards` table
4. Old scores are restored automatically

**Solution**: Reset **BOTH** tables:
```sql
-- Reset progress (source of truth)
UPDATE progress SET best_scores = ARRAY[[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]], 
                    endless_best = 0, 
                    worlds_unlocked = 1, 
                    levels_unlocked = ARRAY[1,0,0];

-- Reset leaderboards (calculated display)
UPDATE leaderboards SET campaign_total = 0, 
                        world_totals = ARRAY[0,0,0], 
                        endless_best = 0;
```

**See `RESET_SCORES.md` for detailed reset instructions.**

### Issue 2: Manual Refresh (NOW IMPLEMENTED ✅)
**Problem**: Users cannot manually refresh leaderboard data if they suspect it's stale.

**Solution**: ✅ **IMPLEMENTED** - Added manual refresh button in PR
- Users can click "Refresh" button on leaderboards screen
- Forces re-fetch from database
- Shows loading state during operation

### Issue 3: No Explicit Reset Detection
**Problem**: System relies on realtime subscription for reset detection.

**Impact**: If subscription fails or is delayed, users see stale data.

**Solution**: ✅ **PARTIALLY ADDRESSED** 
- Manual refresh provides workaround
- Full solution would require database-side reset versioning
- Users can click refresh button if they suspect stale data

### Issue 4: No Cache Invalidation Strategy
**Problem**: Leaderboard data is fetched fresh each time, but no explicit cache strategy.

**Impact**: 
- Multiple fetches on rapid tab switches
- Potential for stale data between fetches

**Status**: ⚠️ LOW PRIORITY
- Current implementation re-fetches on each tab switch (acceptable performance)
- Future: Could add client-side caching with TTL

### Issue 5: Progress and Leaderboards Can Desync
**Problem**: If `updateLeaderboardsFromProgress()` fails, the two tables become out of sync.

**Impact**: Leaderboard shows outdated scores until next successful sync.

**Mitigation**: 
- Function is called frequently (login, level complete, screen entry, manual refresh)
- Multiple opportunities for resync
- Error logging helps identify issues

**Future Enhancement**: Add background sync job to ensure consistency

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
