# Migration Guide: localStorage to Supabase

This guide helps you migrate from the legacy localStorage-based system to the new Supabase-powered backend.

## Overview

The new system provides:
- ✅ **Global data sync** across devices
- ✅ **Real-time leaderboards** with live updates
- ✅ **Secure authentication** via Supabase Auth
- ✅ **Persistent cloud storage** for progress and settings
- ✅ **Automatic fallback** to localStorage when offline

## Migration Steps

### For End Users

Users don't need to do anything special! The new system includes:

1. **Automatic Fallback**: If Supabase is not configured, the game falls back to localStorage
2. **Seamless Transition**: When users create an account or log in, their data begins syncing to Supabase
3. **No Data Loss**: localStorage data remains intact and can be manually migrated if needed

### For Developers

#### Step 1: Set Up Supabase

Follow the instructions in `SUPABASE_SETUP.md` to:
1. Create a Supabase project
2. Run the SQL schema
3. Configure authentication
4. Enable realtime for leaderboards

#### Step 2: Update Configuration

Replace the placeholder credentials in `index_dev.html`:

```javascript
const SUPABASE_URL = "https://your-project.supabase.co";
const SUPABASE_ANON_KEY = "your-anon-key-here";
```

#### Step 3: Test Migration

1. Open the game in a browser with existing localStorage data
2. Create a new account or log in
3. Verify that:
   - Progress is maintained
   - Settings are preserved
   - Leaderboards show your scores

## Data Structure Comparison

### Before (localStorage)

```javascript
// Authentication
localStorage.getItem("gridrun_auth_v2") // { email, username }
localStorage.getItem("gridrun_accounts_v1") // { [email]: { email, username, passHash } }

// Progress
localStorage.getItem("gridrun_progress_email_[email]") // { worldsUnlocked, levelsUnlocked, bestScores, endlessBest }

// Settings
localStorage.getItem("gridrun_audio_settings_v1") // { menuMusic, gameplayMusic, sfx, volumeMusic, volumeSfx }

// Leaderboards
localStorage.getItem("gridrun_leaderboards_local_v1") // { users: { [username]: { ... } } }
```

### After (Supabase)

```sql
-- Authentication
auth.users table (managed by Supabase)
  - id (UUID)
  - email
  - user_metadata { username }

-- Progress
progress table
  - user_id (references auth.users)
  - worlds_unlocked
  - levels_unlocked
  - best_scores
  - endless_best

-- Settings
settings table
  - user_id (references auth.users)
  - menu_music
  - gameplay_music
  - sfx
  - volume_music
  - volume_sfx

-- Leaderboards
leaderboards table
  - user_id (references auth.users)
  - username
  - endless_best
  - campaign_total
  - world_1_total, world_2_total, world_3_total
```

## Key Changes

### Authentication

**Before:**
- SHA-256 hashed passwords in localStorage
- Single-device authentication
- No password recovery

**After:**
- Secure Supabase Auth with bcrypt
- Multi-device authentication
- Built-in password recovery (can be configured)
- Session management across tabs

### Progress & Settings

**Before:**
- Stored per-email in localStorage
- Device-specific
- No sync across devices

**After:**
- Stored per-user in Supabase
- Automatically synced across all devices
- Accessible from anywhere
- Falls back to localStorage when offline

### Leaderboards

**Before:**
- Username-based local storage
- Manual updates required
- Device-specific rankings
- No real-time updates

**After:**
- User ID-based global leaderboards
- Automatic updates on score improvement
- Real-time updates via Supabase Realtime
- Public read access for all users

## Backward Compatibility

The new system maintains backward compatibility:

### Offline/Unauthenticated Users

```javascript
// Falls back to localStorage
if (!user || !user.userId) {
  return loadProgressLegacy();
}
```

### Legacy Data Access

All localStorage keys remain functional:
- `gridrun_dom_progress_v2` - Legacy progress
- `gridrun_audio_settings_v1` - Legacy settings
- `gridrun_leaderboards_local_v1` - Legacy leaderboards

## API Changes

### Authentication Functions

```javascript
// Before (synchronous)
const user = getActiveUser();
createLocalAccount({ email, password, username });
loginLocalAccount({ email, password });
clearActiveUser();

// After (asynchronous)
const user = await getActiveUser();
await createLocalAccount({ email, password, username });
await loginLocalAccount({ email, password });
await clearActiveUser();
```

### Data Functions

```javascript
// Before (synchronous)
const progress = loadProgress();
saveProgress(progress);
const settings = loadSettingsState();
saveSettingsState(settings);

// After (asynchronous)
const progress = await loadProgress();
await saveProgress(progress);
const settings = await loadSettingsState();
await saveSettingsState(settings);
```

### Leaderboard Functions

```javascript
// Before (synchronous, local)
updateLeaderboardsFromProgress();
const { list, scoreOf } = buildRanking(metric);

// After (asynchronous, global)
await updateLeaderboardsFromProgress();
const { list, scoreOf } = await buildRanking(metric);

// New: Realtime subscriptions
subscribeToLeaderboardUpdates((payload) => {
  // Handle realtime update
});
unsubscribeFromLeaderboardUpdates();
```

## Menu Functions

All menu functions that access user data are now async:

```javascript
// Updated functions
await loadMainMenu()
await loadCampaignMode()
await loadWorld(worldNumber)
await loadLevelIntro(worldNumber, levelNumber)
await loadEndlessIntro()
await loadSettings()
await loadAccount()
await loadLeaderboards()
```

## Testing Checklist

After migration, verify:

- [ ] Users can create new accounts
- [ ] Users can log in with existing credentials
- [ ] Users can log out
- [ ] Progress saves and loads correctly
- [ ] Settings save and load correctly
- [ ] Leaderboards update after gameplay
- [ ] Realtime leaderboard updates work across tabs
- [ ] Username changes update in leaderboards
- [ ] Offline mode falls back to localStorage
- [ ] Game works without Supabase credentials (localStorage fallback)

## Rollback Plan

If you need to rollback to the old system:

1. Replace `index_dev.html` with the previous version
2. Users' localStorage data will still be intact
3. No data loss occurs (Supabase data remains in the cloud)

## Performance Considerations

### Caching

The app maintains global variables for frequently accessed data:
```javascript
let progress = defaultProgress();
let settings = defaultSettings();
```

These are loaded once at startup and updated as needed, minimizing database calls.

### Optimistic Updates

Progress and settings update immediately in the UI, with Supabase sync in the background.

### Realtime Efficiency

Leaderboard subscriptions only trigger UI updates when:
- User is viewing the leaderboards screen
- An actual score change occurs

## Security Notes

### Row Level Security (RLS)

All tables use RLS policies:
- Users can only access their own progress and settings
- Leaderboards are public-read, user-write (own entry only)

### API Keys

- **anon/public key**: Safe to include in client code
- **service_role key**: NEVER expose in client code
- Keys can be regenerated in Supabase dashboard if compromised

## Troubleshooting

### "Cannot read property 'from' of undefined"

**Cause:** Supabase client not initialized
**Fix:** Verify Supabase URL and key are set correctly

### "Row Level Security Policy violation"

**Cause:** User trying to access data they don't own
**Fix:** Check RLS policies in `supabase-schema.sql`

### "Realtime not working"

**Cause:** Replication not enabled for leaderboards
**Fix:** Enable in Database > Replication > leaderboards

### Progress not saving

**Cause:** Async function not awaited
**Fix:** Ensure all calls to `saveProgress()` use `await`

## Future Enhancements

Potential improvements with Supabase:
- [ ] Social authentication (Google, GitHub)
- [ ] Friend lists and social features
- [ ] Spectator mode for live games
- [ ] Achievements system
- [ ] Cloud save backups
- [ ] Admin dashboard
- [ ] Analytics and metrics

## Support

For migration issues:
1. Check browser console for errors
2. Verify Supabase configuration
3. Test with localStorage fallback
4. Review SQL schema in Supabase dashboard
5. Check RLS policies

For Supabase-specific help:
- [Supabase Docs](https://supabase.com/docs)
- [Supabase Discord](https://discord.supabase.com)
