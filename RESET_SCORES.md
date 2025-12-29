# How to Reset Scores and Progress in GridRun

## Understanding the Data Structure

GridRun stores player data in **TWO separate tables** in Supabase:

### 1. `progress` Table (Source of Truth)
Stores detailed per-level progress for each player:
- `user_id` - Player's unique ID
- `worlds_unlocked` - Number of worlds unlocked
- `levels_unlocked` - Array of levels unlocked per world
- `best_scores` - 3x5 array of best scores for each level
- `endless_best` - Best score in endless mode

### 2. `leaderboards` Table (Calculated Display)
Stores aggregated scores for leaderboard display:
- `user_id` - Player's unique ID
- `username` - Player's display name
- `endless_best` - Best endless score (copied from progress)
- `campaign_total` - Sum of all campaign scores (calculated from progress)
- `world_totals` - Array of totals per world (calculated from progress)

## Why Resetting Only `leaderboards` Doesn't Work

When you reset only the `leaderboards` table:
1. ✅ Leaderboard shows empty/reset state
2. ❌ **BUT** when users log in or refresh, the app calls `updateLeaderboardsFromProgress()`
3. ❌ This function reads from the `progress` table and recalculates leaderboard scores
4. ❌ The old scores reappear in the leaderboards!

**The `progress` table is the source of truth.** Leaderboards are automatically regenerated from it.

## How to Properly Reset All Scores

You need to reset **BOTH** tables. Here are the SQL commands:

### Option 1: Complete Reset (Recommended for Fresh Start)

```sql
-- Reset progress (source of truth)
UPDATE progress 
SET worlds_unlocked = 1,
    levels_unlocked = ARRAY[1, 0, 0],
    best_scores = ARRAY[[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]],
    endless_best = 0,
    updated_at = NOW();

-- Reset leaderboards (calculated display)
UPDATE leaderboards 
SET endless_best = 0,
    campaign_total = 0,
    world_totals = ARRAY[0, 0, 0],
    updated_at = NOW();
```

### Option 2: Delete All Entries (Clean Slate)

```sql
-- Delete all progress
DELETE FROM progress;

-- Delete all leaderboards
DELETE FROM leaderboards;
```

**Note**: With Option 2, entries will be recreated with default values (all zeros) when users next log in.

### Option 3: Archive Before Reset (Preserve History)

```sql
-- Create archive tables (run once)
CREATE TABLE IF NOT EXISTS progress_archive (
    archived_at TIMESTAMP DEFAULT NOW(),
    season_name TEXT,
    LIKE progress INCLUDING ALL
);

CREATE TABLE IF NOT EXISTS leaderboards_archive (
    archived_at TIMESTAMP DEFAULT NOW(),
    season_name TEXT,
    LIKE leaderboards INCLUDING ALL
);

-- Archive current data
INSERT INTO progress_archive (season_name, user_id, worlds_unlocked, levels_unlocked, best_scores, endless_best, updated_at)
SELECT 'Season 1 - 2024', user_id, worlds_unlocked, levels_unlocked, best_scores, endless_best, updated_at
FROM progress;

INSERT INTO leaderboards_archive (season_name, user_id, username, endless_best, campaign_total, world_totals, updated_at)
SELECT 'Season 1 - 2024', user_id, username, endless_best, campaign_total, world_totals, updated_at
FROM leaderboards;

-- Now reset (use Option 1 or Option 2 above)
```

## Step-by-Step Reset Process

### 1. Announce to Players
⚠️ **IMPORTANT**: Notify your players before resetting scores!
- In-game announcement
- Email notification
- Social media post
- Set expectations on when reset will happen

### 2. Run the SQL Commands

**In Supabase Dashboard:**
1. Go to SQL Editor
2. Choose your reset option (1, 2, or 3 above)
3. Copy and paste the SQL commands
4. Click "Run" to execute

### 3. Verify the Reset

**Check Progress Table:**
```sql
SELECT user_id, worlds_unlocked, endless_best, best_scores 
FROM progress 
LIMIT 10;
```

**Check Leaderboards Table:**
```sql
SELECT username, endless_best, campaign_total, world_totals 
FROM leaderboards 
ORDER BY campaign_total DESC 
LIMIT 10;
```

All scores should be 0 (Option 1) or tables should be empty (Option 2).

### 4. Monitor After Reset

After the reset:
- ✅ Players will see empty leaderboards
- ✅ When players log in, default progress will be created
- ✅ As players complete levels, new scores will appear
- ✅ Refresh button allows players to manually sync if needed

## Troubleshooting

### Problem: Scores Reappear After Reset

**Cause**: You only reset the `leaderboards` table, not the `progress` table.

**Solution**: Run the reset commands for **BOTH** tables as shown in Option 1 or Option 2 above.

### Problem: Some Users Still Have Old Scores

**Cause**: Those users may have been offline during reset and have old data cached.

**Solution**: 
1. Their cache will sync on next login
2. They can click the "Refresh" button on leaderboards
3. Or run: `UPDATE progress SET best_scores = ... WHERE user_id = 'specific-user-id';`

### Problem: Players Can't See New Scores After Reset

**Cause**: Realtime subscription may have disconnected.

**Solution**: 
1. Players should click the "Refresh" button
2. Or reload the page
3. Check Supabase realtime connection status

### Problem: Leaderboards Show "No scores yet" But Players Have Played

**Cause**: Leaderboards haven't been updated from progress yet.

**Solution**:
1. Players should complete a level or endless run
2. Or click the "Refresh" button to force sync
3. The `updateLeaderboardsFromProgress()` function will run automatically

## Testing Your Reset

After running the reset SQL, test with a test account:

1. **Login** with a test account
2. **Check** that progress shows default values (world 1 level 1 unlocked)
3. **Play** a level and complete it
4. **Verify** that the new score appears in leaderboards
5. **Test** the refresh button on leaderboards page
6. **Check** that realtime updates work (open two browsers, complete level in one, see update in other)

## Advanced: Partial Resets

### Reset Only Endless Mode
```sql
-- Reset endless in progress
UPDATE progress SET endless_best = 0, updated_at = NOW();

-- Reset endless in leaderboards
UPDATE leaderboards SET endless_best = 0, updated_at = NOW();
```

### Reset Only Campaign Mode
```sql
-- Reset campaign in progress
UPDATE progress 
SET worlds_unlocked = 1,
    levels_unlocked = ARRAY[1, 0, 0],
    best_scores = ARRAY[[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]],
    updated_at = NOW();

-- Reset campaign in leaderboards
UPDATE leaderboards 
SET campaign_total = 0,
    world_totals = ARRAY[0, 0, 0],
    updated_at = NOW();
```

### Reset Only Specific World
```sql
-- Reset World 1 scores (first 5 elements of best_scores array)
UPDATE progress 
SET best_scores[1] = ARRAY[0,0,0,0,0],
    updated_at = NOW();

-- Recalculate leaderboards
-- Players will need to login/refresh to sync
```

## Quick Reference

| What to Reset | Command |
|---------------|---------|
| Everything | `UPDATE progress SET ...; UPDATE leaderboards SET ...;` |
| Just Endless | `UPDATE progress SET endless_best=0; UPDATE leaderboards SET endless_best=0;` |
| Just Campaign | Reset `best_scores` in progress and `campaign_total`, `world_totals` in leaderboards |
| Delete All | `DELETE FROM progress; DELETE FROM leaderboards;` |

## Important Notes

1. ✅ **Always reset BOTH tables** (`progress` AND `leaderboards`)
2. ✅ **Announce resets in advance** to players
3. ✅ **Consider archiving** old data before resetting
4. ✅ **Test with a test account** before production reset
5. ✅ **Monitor** after reset to ensure everything works
6. ✅ **The refresh button** allows players to manually sync after reset

## Why the Architecture Works This Way

The two-table design has important benefits:
- **`progress`** stores detailed per-level data (source of truth)
- **`leaderboards`** stores aggregated totals for fast display
- This separation allows:
  - Fast leaderboard queries (no need to sum every time)
  - Detailed progress tracking for gameplay
  - Easy recalculation if leaderboard logic changes
  - Efficient realtime updates

The trade-off is that you must reset **both** tables when doing a score reset.

## Need Help?

If scores still aren't resetting properly:
1. Check both tables in Supabase SQL Editor
2. Verify realtime connection is active
3. Check browser console for errors
4. Try the refresh button on leaderboards
5. Test with a fresh incognito window

For more details on the architecture, see `LEADERBOARD_ARCHITECTURE.md`.
