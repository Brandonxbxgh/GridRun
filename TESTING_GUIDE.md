# Testing Guide for Supabase Integration

This guide provides comprehensive test cases to verify the Supabase integration works correctly.

## Prerequisites

For full testing, you'll need:
1. A Supabase project configured (see `SUPABASE_SETUP.md`)
2. Updated credentials in `index_dev.html`
3. Multiple browsers or devices for sync testing

## Test Matrix

### Test Environment 1: With Supabase Configured (Cloud Mode)
- Supabase credentials properly set in `index_dev.html`
- All features should work with cloud sync

### Test Environment 2: Without Supabase (Offline Mode)
- Placeholder credentials or invalid Supabase URL
- Game should fall back to localStorage
- Should display "offline mode" messaging

## Test Cases

### 1. Initial Load & Supabase Detection

**Test 1.1: Supabase Configured**
- [ ] Open browser console
- [ ] Load `index_dev.html`
- [ ] Verify console shows: "✅ Supabase initialized - Cloud sync enabled"
- [ ] Auth gate should appear with LOGIN and CREATE ACCOUNT buttons

**Test 1.2: Supabase Not Configured**
- [ ] Set credentials to placeholders in `index_dev.html`
- [ ] Open browser console
- [ ] Load `index_dev.html`
- [ ] Verify console shows: "ℹ️ Supabase not configured - Using localStorage mode"
- [ ] Main menu should appear directly (skip auth)

### 2. Authentication (Cloud Mode Only)

**Test 2.1: Create Account**
- [ ] Click "CREATE ACCOUNT"
- [ ] Enter valid email (e.g., test@example.com)
- [ ] Enter username (e.g., TestUser123)
- [ ] Enter password (6+ characters)
- [ ] Confirm password (matching)
- [ ] Click "Create"
- [ ] Should navigate to main menu
- [ ] Verify in Supabase dashboard: Users > auth.users has new entry
- [ ] Verify user_metadata contains username

**Test 2.2: Create Account - Validation**
- [ ] Try invalid email: Should show error
- [ ] Try empty username: Should show error
- [ ] Try password < 6 chars: Should show error
- [ ] Try mismatched passwords: Should show error
- [ ] Try duplicate email: Should show error

**Test 2.3: Login**
- [ ] Click "LOGIN"
- [ ] Enter existing email
- [ ] Enter correct password
- [ ] Click "Confirm"
- [ ] Should navigate to main menu
- [ ] Verify logged in as correct user

**Test 2.4: Login - Validation**
- [ ] Try invalid email: Should show error
- [ ] Try wrong password: Should show error
- [ ] Try non-existent email: Should show error

**Test 2.5: Logout**
- [ ] From Account screen, click "Logout"
- [ ] Should return to auth gate
- [ ] Verify session cleared

### 3. Progress Storage

**Test 3.1: New User Progress (Cloud Mode)**
- [ ] Create new account
- [ ] Start Campaign > World 1 > Level 1
- [ ] Complete the level
- [ ] Check Supabase dashboard > progress table
- [ ] Verify entry exists with user_id
- [ ] Verify best_scores updated for W1L1

**Test 3.2: Progress Sync (Cloud Mode)**
- [ ] Complete a level with score X
- [ ] Log out
- [ ] Log in on different browser/device
- [ ] Navigate to same level
- [ ] Verify "Best: X" shows correct score
- [ ] Verify unlocked levels match

**Test 3.3: Progress Update (Cloud Mode)**
- [ ] Complete a level with initial score
- [ ] Replay and get higher score
- [ ] Verify best score updates
- [ ] Check Supabase dashboard > progress table
- [ ] Verify best_scores array updated

**Test 3.4: Progress Offline Mode**
- [ ] Without Supabase configured
- [ ] Play several levels
- [ ] Close and reopen browser
- [ ] Verify progress persists (localStorage)
- [ ] Check browser's LocalStorage in DevTools
- [ ] Verify "gridrun_dom_progress_v2" key exists

**Test 3.5: World/Level Unlocking**
- [ ] Complete World 1, Level 1
- [ ] Verify Level 2 unlocks
- [ ] Complete all 5 levels of World 1
- [ ] Verify World 2 unlocks
- [ ] Verify World 2 Level 1 is accessible

### 4. Settings Storage

**Test 4.1: Settings Save (Cloud Mode)**
- [ ] Go to Settings
- [ ] Toggle Menu Music OFF
- [ ] Toggle SFX OFF
- [ ] Navigate away and back
- [ ] Verify settings persisted
- [ ] Check Supabase dashboard > settings table
- [ ] Verify menu_music = false, sfx = false

**Test 4.2: Settings Sync (Cloud Mode)**
- [ ] Change settings on device 1
- [ ] Log in on device 2
- [ ] Go to Settings
- [ ] Verify same settings appear
- [ ] Verify audio behavior matches settings

**Test 4.3: Settings Offline Mode**
- [ ] Without Supabase configured
- [ ] Change settings
- [ ] Close and reopen browser
- [ ] Verify settings persisted (localStorage)
- [ ] Check LocalStorage for "gridrun_audio_settings_v1"

### 5. Leaderboards

**Test 5.1: Leaderboard Update (Cloud Mode)**
- [ ] Complete a level with good score
- [ ] Go to Leaderboards
- [ ] Verify your username appears
- [ ] Verify score is correct
- [ ] Check Supabase dashboard > leaderboards table
- [ ] Verify entry exists with correct scores

**Test 5.2: Leaderboard Categories (Cloud Mode)**
- [ ] Complete levels in World 1
- [ ] Complete levels in World 2
- [ ] Complete an Endless run
- [ ] Go to Leaderboards
- [ ] Check "Endless" tab: Verify endless_best
- [ ] Check "Campaign Total" tab: Verify total score
- [ ] Check "World 1" tab: Verify W1 total
- [ ] Check "World 2" tab: Verify W2 total

**Test 5.3: Real-Time Updates (Cloud Mode)**
- [ ] Open game in Browser 1 (User A)
- [ ] Open game in Browser 2 (User B)
- [ ] Both navigate to Leaderboards
- [ ] User B completes a level with new high score
- [ ] User B goes to Leaderboards
- [ ] Verify User A's leaderboard updates automatically
- [ ] Look for "🔴 LIVE" indicator in UI

**Test 5.4: Leaderboard Ranking (Cloud Mode)**
- [ ] Create 3+ test accounts
- [ ] Complete levels with different scores
- [ ] Verify leaderboard sorts by score (highest first)
- [ ] Verify "YOU" badge on your entry
- [ ] Verify rank numbers are correct

**Test 5.5: Leaderboards Offline Mode**
- [ ] Without Supabase configured
- [ ] Go to Leaderboards
- [ ] Should show "No scores yet" or empty list
- [ ] Verify no errors in console

### 6. Account Management

**Test 6.1: Username Change (Cloud Mode)**
- [ ] Go to Account
- [ ] Change username
- [ ] Click "Save"
- [ ] Verify success message
- [ ] Check Supabase dashboard
- [ ] Verify user_metadata.username updated
- [ ] Verify leaderboards.username updated
- [ ] Refresh and verify username persists

**Test 6.2: Account Stats Display**
- [ ] Complete various levels
- [ ] Go to Account
- [ ] Verify "Endless Best" displays correct score
- [ ] Verify "Campaign Total" displays correct total
- [ ] Verify logged in email/username shown

### 7. Cross-Device Sync

**Test 7.1: Full Sync Scenario (Cloud Mode)**
- [ ] Device 1: Create account and play
- [ ] Device 1: Complete World 1, Levels 1-3
- [ ] Device 1: Change settings (music OFF)
- [ ] Device 2: Login with same account
- [ ] Device 2: Verify levels 1-3 unlocked
- [ ] Device 2: Verify level 4 locked
- [ ] Device 2: Verify settings match (music OFF)
- [ ] Device 2: Complete level 4
- [ ] Device 1: Refresh/reopen
- [ ] Device 1: Verify level 4 now shows best score

### 8. Gameplay Integration

**Test 8.1: Campaign Level Completion**
- [ ] Play a campaign level to completion
- [ ] Verify level clear bonus applied
- [ ] Verify final score saved
- [ ] Verify next level unlocked
- [ ] Verify tier (Bronze/Silver/Gold) calculated correctly

**Test 8.2: Endless Mode**
- [ ] Play Endless mode
- [ ] Die/fail after some time
- [ ] Verify score saved as endless_best
- [ ] Play again and get higher score
- [ ] Verify endless_best updates to higher score
- [ ] Verify lower score doesn't overwrite higher score

**Test 8.3: Results Screen**
- [ ] Complete a level
- [ ] Verify Results screen shows:
  - [ ] Correct score
  - [ ] Correct tier (Bronze/Silver/Gold)
  - [ ] Tier thresholds displayed
- [ ] Click "RETRY": Verify restarts level
- [ ] Click "NEXT LEVEL": Verify goes to next level
- [ ] Click "BACK TO LEVELS": Verify returns to level select

### 9. Error Handling

**Test 9.1: Network Interruption (Cloud Mode)**
- [ ] Start game with Supabase configured
- [ ] Disable network (airplane mode)
- [ ] Try to login: Should show appropriate error
- [ ] Re-enable network
- [ ] Try again: Should work

**Test 9.2: Invalid Credentials**
- [ ] Set invalid Supabase URL
- [ ] Open game
- [ ] Verify falls back to offline mode
- [ ] Verify no crashes or console errors
- [ ] Verify game is playable

**Test 9.3: Database Errors (Cloud Mode)**
- [ ] Temporarily remove RLS policies in Supabase
- [ ] Try to save progress
- [ ] Verify error logged to console
- [ ] Verify game doesn't crash
- [ ] Restore RLS policies
- [ ] Verify operations work again

### 10. Performance

**Test 10.1: Load Times**
- [ ] Measure initial page load
- [ ] Measure menu navigation speed
- [ ] Verify no noticeable lag
- [ ] Check console for slow queries

**Test 10.2: Realtime Performance**
- [ ] Open leaderboards with many entries
- [ ] Verify smooth scrolling
- [ ] Verify updates don't cause lag
- [ ] Check memory usage over time

## Browser Compatibility

Test on multiple browsers:
- [ ] Chrome/Chromium
- [ ] Firefox
- [ ] Safari
- [ ] Edge
- [ ] Mobile browsers (iOS Safari, Chrome Android)

## Expected Console Messages

### With Supabase Configured:
```
✅ Supabase initialized - Cloud sync enabled
```

### Without Supabase:
```
ℹ️ Supabase not configured - Using localStorage mode
```

### Realtime Unavailable:
```
ℹ️ Realtime leaderboards not available (Supabase not configured)
```

### Normal Operations:
- No error messages
- Possible info messages about leaderboard updates

## Troubleshooting

### Issue: "Cannot read property 'from' of undefined"
**Cause:** Supabase client not initialized
**Fix:** Verify URL and anon key are correct

### Issue: "Row Level Security Policy violation"
**Cause:** RLS policies not properly configured
**Fix:** Run `supabase-schema.sql` again

### Issue: Progress doesn't sync
**Cause:** Not logged in or Supabase unavailable
**Fix:** Verify authentication and network connection

### Issue: Leaderboards don't update in real-time
**Cause:** Realtime not enabled for leaderboards table
**Fix:** Enable replication in Supabase Dashboard

## Reporting Issues

When reporting bugs, include:
1. Which test case failed
2. Browser and OS
3. Supabase configured? (Yes/No)
4. Console error messages
5. Steps to reproduce
6. Expected vs actual behavior

## Success Criteria

All test cases should pass for the integration to be considered complete:
- ✅ Authentication works in cloud mode
- ✅ Game works in offline mode
- ✅ Progress syncs across devices
- ✅ Settings sync across devices
- ✅ Leaderboards update in real-time
- ✅ No console errors in normal operation
- ✅ Graceful fallbacks when Supabase unavailable
