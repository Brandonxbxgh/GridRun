# GridRun Supabase Migration - Quick Reference

## Implementation Overview

This document provides a quick reference for the Supabase migration implementation.

## Files Modified

### index_dev.html
**Major Changes:**
1. Added Supabase client initialization (line ~232-233)
2. Replaced all localStorage authentication with Supabase Auth
3. Converted progress storage to use Supabase database
4. Migrated settings to cloud storage
5. Implemented global leaderboards with real-time subscriptions
6. Updated all async functions to properly handle promises

**Key Functions Replaced:**
- `createLocalAccount()` → Uses Supabase Auth signup
- `loginLocalAccount()` → Uses Supabase Auth signin  
- `getActiveUser()` → Fetches from Supabase session
- `loadProgress()` / `saveProgress()` → Database operations
- `loadSettingsState()` / `saveSettingsState()` → Database operations
- `loadLeaderboardsState()` / `updateLeaderboardsFromProgress()` → Database operations
- `buildRanking()` / `renderLeaderboardList()` → Fetch from cloud

## Configuration Required

### Before Running
Update these values in `index_dev.html`:

```javascript
const SUPABASE_URL = "YOUR_SUPABASE_URL"; // Replace with your project URL
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY"; // Replace with your anon key
```

Get these from: Supabase Dashboard → Project Settings → API

## Database Tables Required

Run SQL scripts in this order (see SUPABASE_SETUP.md for full scripts):

1. **profiles** - User profile information
2. **progress** - Game progression data
3. **settings** - User preferences
4. **leaderboards** - Global rankings

All tables include:
- Row Level Security (RLS) policies
- Proper indexes for performance
- Foreign key constraints

## API Changes Summary

### Authentication
```javascript
// OLD (Local Storage)
localStorage.setItem(AUTH_KEY, JSON.stringify({email, username}))

// NEW (Supabase)
await supabase.auth.signUp({ email, password, options: { data: { username }}})
await supabase.auth.signInWithPassword({ email, password })
```

### Progress Storage
```javascript
// OLD (Local Storage)
localStorage.setItem(progressKey(), JSON.stringify(progress))

// NEW (Supabase)
await supabase.from('progress').upsert({
  user_id, worlds_unlocked, levels_unlocked, best_scores, endless_best
})
```

### Leaderboards
```javascript
// OLD (Local Storage)
localStorage.setItem(LB_KEY, JSON.stringify(leaderboards))

// NEW (Supabase)
await supabase.from('leaderboards').upsert({
  user_id, username, endless_best, campaign_total, world_totals
})

// With real-time updates
supabase.channel('leaderboards_channel')
  .on('postgres_changes', { table: 'leaderboards' }, callback)
  .subscribe()
```

## UI Changes

### Text Updates
- "Local" → "Cloud" or "Global"
- "Local-only for now" → "Powered by Supabase"
- "Top 25 (local)" → "Top 25 (global)"
- Added cloud sync indicators

### No Breaking UI Changes
- All screens remain the same
- Same buttons and layout
- Same navigation flow
- Same gameplay

## Security Model

### Row Level Security (RLS)
All tables protected with policies:

```sql
-- Users can only read their own data
CREATE POLICY "Users can view their own {table}"
  ON public.{table} FOR SELECT
  USING (auth.uid() = user_id);

-- Exception: Leaderboards are public read
CREATE POLICY "Anyone can view leaderboards"
  ON public.leaderboards FOR SELECT
  TO public USING (true);
```

### Safe to Expose
- ✅ Supabase URL - Public
- ✅ Anon Key - Public (protected by RLS)
- ❌ Service Role Key - NEVER expose

## Testing Checklist

### Essential Tests
- [ ] Create new account
- [ ] Login with account
- [ ] Logout
- [ ] Play campaign level
- [ ] Check progress saves
- [ ] Play endless mode
- [ ] Verify leaderboard updates
- [ ] Change settings
- [ ] Verify settings persist
- [ ] Edit username
- [ ] Test from different browser/device

### Edge Cases
- [ ] Create account with existing email (should fail)
- [ ] Login with wrong password (should fail)
- [ ] Rapid progress updates
- [ ] Network offline behavior
- [ ] Multiple simultaneous sessions

## Deployment Checklist

### Pre-Deployment
- [ ] Supabase project created
- [ ] Database tables created
- [ ] RLS policies enabled
- [ ] SUPABASE_URL configured
- [ ] SUPABASE_ANON_KEY configured
- [ ] Email provider enabled
- [ ] Site URL configured
- [ ] Test account created

### Post-Deployment
- [ ] Test live account creation
- [ ] Verify email deliverability
- [ ] Test cross-device sync
- [ ] Monitor Supabase dashboard
- [ ] Check error logs
- [ ] Verify leaderboards populate

## Troubleshooting

### Common Errors

**"Failed to initialize Supabase"**
```
Solution: Check SUPABASE_URL and SUPABASE_ANON_KEY are set correctly
```

**"No such table: progress"**
```
Solution: Run database creation scripts from SUPABASE_SETUP.md
```

**"new row violates row-level security policy"**
```
Solution: Verify RLS policies are created correctly
```

**Login works but data doesn't save**
```
Solution: 
1. Check browser console for errors
2. Verify user is authenticated (auth.uid() exists)
3. Check RLS policies allow INSERT/UPDATE
```

**Leaderboards show no data**
```
Solution:
1. Verify leaderboards table has public read policy
2. Check that updateLeaderboardsFromProgress() is called
3. Play a game to populate initial data
```

## Performance Considerations

### Optimization Points
1. **Progress caching**: Global `progress` variable reduces DB calls
2. **Settings caching**: Global `settings` variable for immediate access
3. **Leaderboard pagination**: Only fetch top 25
4. **Indexes**: All tables have appropriate indexes
5. **Real-time**: Optional, can be disabled for performance

### Monitoring
- Use Supabase Dashboard → Database → Logs
- Monitor API request counts
- Check query performance in Dashboard

## Future Enhancements

### Easy Additions
1. **OAuth Providers**: Already structured, just enable in Supabase
2. **Password Reset**: Supabase provides this out of the box
3. **Email Verification**: Enable in Auth settings
4. **Profile Pictures**: Use Supabase Storage

### Medium Complexity
1. **Friends System**: Add friends table with RLS
2. **Achievements**: Add achievements table
3. **Replay System**: Store game replays in Storage
4. **Chat/Social**: Use Supabase Realtime

## Code Patterns

### Async Function Pattern
```javascript
async function someFunction() {
  try {
    const user = await getActiveUser();
    if (!user) return;
    
    const { data, error } = await supabase
      .from('table')
      .select('*')
      .eq('user_id', user.userId);
    
    if (error) throw error;
    return data;
  } catch (e) {
    console.error("Error:", e);
    return null;
  }
}
```

### UI Loading Pattern
```javascript
function loadSomeScreen() {
  const container = document.getElementById("game-container");
  
  loadData().then(data => {
    container.innerHTML = `
      <div>Data: ${data}</div>
    `;
  });
}
```

## Support Resources

- **Supabase Docs**: https://supabase.com/docs
- **Setup Guide**: `SUPABASE_SETUP.md`
- **Migration Details**: `MIGRATION_SUMMARY.md`
- **Main README**: `README.md`

## Summary

✅ **Minimal Changes**: Core game logic unchanged  
✅ **Backward Compatible UI**: Same screens and flow  
✅ **Production Ready**: Secure authentication and data storage  
✅ **Scalable**: Cloud infrastructure via Supabase  
✅ **Feature Rich**: Global leaderboards with real-time updates

The migration successfully transforms GridRun into a cloud-connected multiplayer experience while maintaining the original game design and user experience.
