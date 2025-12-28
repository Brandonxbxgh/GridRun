# Supabase Setup Instructions

This document explains how to set up Supabase for the GridRun game.

## Prerequisites

1. Create a free Supabase account at [supabase.com](https://supabase.com)
2. Create a new Supabase project

## Step 1: Configure Authentication

1. Go to **Authentication > Providers** in your Supabase dashboard
2. Enable **Email** provider
3. Configure email templates (optional) under **Authentication > Email Templates**

## Step 2: Set Up Database

1. Go to **SQL Editor** in your Supabase dashboard
2. Create a new query
3. Copy and paste the contents of `supabase-schema.sql`
4. Run the query to create all tables, indexes, and policies

## Step 3: Enable Realtime

1. Go to **Database > Replication** in your Supabase dashboard
2. Enable replication for the `leaderboards` table
3. This allows real-time updates when leaderboard scores change

## Step 4: Get Your Credentials

1. Go to **Settings > API** in your Supabase dashboard
2. Copy your **Project URL** (it looks like `https://xxxxx.supabase.co`)
3. Copy your **anon/public key**

## Step 5: Update Your Application

1. Open `index_dev.html`
2. Find the Supabase configuration section near the top:
   ```javascript
   const SUPABASE_URL = "YOUR_SUPABASE_URL";
   const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
   ```
3. Replace `YOUR_SUPABASE_URL` with your Project URL
4. Replace `YOUR_SUPABASE_ANON_KEY` with your anon/public key

## Database Schema Overview

### Tables

1. **progress** - Stores per-user game progress
   - `user_id` - References the authenticated user
   - `worlds_unlocked` - Number of worlds unlocked (1-3)
   - `levels_unlocked` - Array of levels unlocked per world
   - `best_scores` - 2D array of best scores for each level
   - `endless_best` - Best score in endless mode

2. **settings** - Stores per-user audio settings
   - `user_id` - References the authenticated user
   - `menu_music` - Whether menu music is enabled
   - `gameplay_music` - Whether gameplay music is enabled
   - `sfx` - Whether sound effects are enabled
   - `volume_music` - Music volume (0-1)
   - `volume_sfx` - SFX volume (0-1)

3. **leaderboards** - Global leaderboard data (public read)
   - `user_id` - References the authenticated user
   - `username` - Display name
   - `endless_best` - Best endless score
   - `campaign_total` - Total campaign score
   - `world_1_total`, `world_2_total`, `world_3_total` - Per-world totals

### Security

All tables use Row Level Security (RLS):
- **progress** and **settings**: Users can only read/write their own data
- **leaderboards**: Public read access, users can only update their own entry

## Features

### Authentication
- Sign up with email and password
- Sign in with email and password
- Session management with Supabase Auth
- Username stored in user metadata

### Data Sync
- Progress syncs automatically across devices
- Settings sync globally
- Leaderboards update in real-time

### Realtime Leaderboards
- Live updates when any player improves their score
- No page refresh needed
- Updates appear instantly across all connected clients

## Fallback Support

The application includes fallback to localStorage for:
- Offline mode
- Non-authenticated users
- Development/testing without Supabase

## Testing

1. Create a test account
2. Play through some levels
3. Check that progress is saved
4. Log out and log back in to verify data persistence
5. Open the app in multiple browsers/devices to test realtime updates

## Troubleshooting

### "Error loading progress" or similar errors
- Check browser console for detailed error messages
- Verify Supabase URL and key are correct
- Check that tables exist in Supabase dashboard
- Verify RLS policies are configured correctly

### Realtime updates not working
- Verify replication is enabled for `leaderboards` table
- Check browser console for WebSocket connection errors
- Ensure you're using the correct Supabase URL

### Authentication issues
- Verify email provider is enabled
- Check that user metadata includes username
- Confirm RLS policies allow authenticated users to access data

## Next Steps

1. Consider adding password reset functionality
2. Add email confirmation for new accounts
3. Implement social login (Google, GitHub, etc.)
4. Add admin dashboard for monitoring
5. Set up database backups
6. Configure custom SMTP for emails

## Support

For Supabase-specific issues, refer to:
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Discord](https://discord.supabase.com)

For GridRun game issues, check the repository README.
