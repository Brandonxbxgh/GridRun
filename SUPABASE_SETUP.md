# Supabase Setup Guide for GridRun

This document provides complete instructions for setting up Supabase backend for GridRun, including database tables, authentication configuration, and real-time features.

## Prerequisites

1. Create a Supabase account at [https://supabase.com](https://supabase.com)
2. Create a new project in Supabase dashboard
3. Note down your project URL and anon key from Project Settings > API

## Step 1: Update Configuration

In `index_dev.html`, replace the placeholder values with your actual Supabase credentials:

```javascript
const SUPABASE_URL = "YOUR_SUPABASE_URL"; // Replace with https://xxxxx.supabase.co
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY"; // Replace with your public anon key
```

## Step 2: Configure Authentication

1. Go to **Authentication** > **Settings** in your Supabase dashboard
2. Configure the following settings:
   - **Enable Email Provider**: ON
   - **Confirm Email**: Optional (recommended for production)
   - **Enable Email Confirmations**: Optional
   - **Site URL**: Set to your game's URL (e.g., `https://yourdomain.com`)
   - **Redirect URLs**: Add your domain to the allowed redirect URLs

### Optional: Add OAuth Providers

To enable OAuth providers like Google or GitHub:

1. Go to **Authentication** > **Providers**
2. Enable desired providers (Google, GitHub, etc.)
3. Configure each provider with their respective client IDs and secrets
4. Update the login UI in `index_dev.html` to add OAuth buttons if desired

## Step 3: Create Database Tables

Run the following SQL in the **SQL Editor** of your Supabase dashboard:

### Table 1: Profiles

```sql
-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  username TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS profiles_username_idx ON public.profiles(username);
```

### Table 2: Progress

```sql
-- Create progress table
CREATE TABLE IF NOT EXISTS public.progress (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
  worlds_unlocked INTEGER DEFAULT 1,
  levels_unlocked INTEGER[] DEFAULT ARRAY[1, 0, 0],
  best_scores INTEGER[][] DEFAULT ARRAY[[0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0]],
  endless_best INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.progress ENABLE ROW LEVEL SECURITY;

-- Policies for progress
CREATE POLICY "Users can view their own progress"
  ON public.progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress"
  ON public.progress FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress"
  ON public.progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS progress_user_id_idx ON public.progress(user_id);
```

### Table 3: Settings

```sql
-- Create settings table
CREATE TABLE IF NOT EXISTS public.settings (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
  menu_music BOOLEAN DEFAULT TRUE,
  gameplay_music BOOLEAN DEFAULT TRUE,
  sfx BOOLEAN DEFAULT TRUE,
  volume_music DECIMAL DEFAULT 0.75,
  volume_sfx DECIMAL DEFAULT 0.85,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- Policies for settings
CREATE POLICY "Users can view their own settings"
  ON public.settings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
  ON public.settings FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings"
  ON public.settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS settings_user_id_idx ON public.settings(user_id);
```

### Table 4: Leaderboards

```sql
-- Create leaderboards table
CREATE TABLE IF NOT EXISTS public.leaderboards (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
  username TEXT NOT NULL,
  endless_best INTEGER DEFAULT 0,
  campaign_total INTEGER DEFAULT 0,
  world_totals INTEGER[] DEFAULT ARRAY[0, 0, 0],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.leaderboards ENABLE ROW LEVEL SECURITY;

-- Policies for leaderboards (public read, owner write)
CREATE POLICY "Anyone can view leaderboards"
  ON public.leaderboards FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can update their own leaderboard entry"
  ON public.leaderboards FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own leaderboard entry"
  ON public.leaderboards FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create indexes for leaderboard queries
CREATE INDEX IF NOT EXISTS leaderboards_endless_best_idx ON public.leaderboards(endless_best DESC);
CREATE INDEX IF NOT EXISTS leaderboards_campaign_total_idx ON public.leaderboards(campaign_total DESC);
CREATE INDEX IF NOT EXISTS leaderboards_updated_at_idx ON public.leaderboards(updated_at DESC);
CREATE INDEX IF NOT EXISTS leaderboards_username_idx ON public.leaderboards(username);
```

## Step 4: Enable Real-time (Optional)

To enable real-time leaderboard updates:

1. Go to **Database** > **Replication** in your Supabase dashboard
2. Enable replication for the `leaderboards` table
3. The game code already includes real-time subscription logic

## Step 5: Test the Setup

1. Open `index_dev.html` in a web browser
2. Create a test account
3. Play a game and verify:
   - Progress is saved to Supabase
   - Settings are synced
   - Leaderboards update correctly
4. Check the Supabase dashboard to verify data is being stored

## Database Schema Summary

### profiles
- `id` (UUID, Primary Key) - User ID from auth.users
- `email` (TEXT) - User's email address
- `username` (TEXT) - Display name (editable)
- `created_at` (TIMESTAMPTZ) - Account creation time
- `updated_at` (TIMESTAMPTZ) - Last profile update

### progress
- `id` (BIGSERIAL, Primary Key)
- `user_id` (UUID, Foreign Key) - References auth.users(id)
- `worlds_unlocked` (INTEGER) - Number of worlds unlocked (1-3)
- `levels_unlocked` (INTEGER[]) - Array of levels unlocked per world
- `best_scores` (INTEGER[][]) - 2D array of best scores per world/level
- `endless_best` (INTEGER) - Best score in endless mode
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)

### settings
- `id` (BIGSERIAL, Primary Key)
- `user_id` (UUID, Foreign Key) - References auth.users(id)
- `menu_music` (BOOLEAN) - Menu music on/off
- `gameplay_music` (BOOLEAN) - Gameplay music on/off
- `sfx` (BOOLEAN) - Sound effects on/off
- `volume_music` (DECIMAL) - Music volume (0-1)
- `volume_sfx` (DECIMAL) - SFX volume (0-1)
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)

### leaderboards
- `id` (BIGSERIAL, Primary Key)
- `user_id` (UUID, Foreign Key) - References auth.users(id)
- `username` (TEXT) - Display name
- `endless_best` (INTEGER) - Best endless score
- `campaign_total` (INTEGER) - Total campaign score
- `world_totals` (INTEGER[]) - Score totals per world
- `created_at` (TIMESTAMPTZ)
- `updated_at` (TIMESTAMPTZ)

## Security Notes

1. **Row Level Security (RLS)** is enabled on all tables
2. Users can only read/write their own data (except leaderboards which are public read)
3. The anon key is safe to expose publicly as RLS policies protect the data
4. Consider enabling email confirmation in production
5. Rate limiting is handled by Supabase automatically

## Troubleshooting

### "Failed to initialize Supabase" error
- Check that SUPABASE_URL and SUPABASE_ANON_KEY are correctly set
- Verify the values match your Supabase project settings

### Authentication errors
- Ensure email provider is enabled in Supabase dashboard
- Check that Site URL and Redirect URLs are configured correctly
- Verify RLS policies are created

### Data not saving
- Check browser console for errors
- Verify RLS policies allow the operation
- Ensure user is authenticated before operations

### Leaderboards not updating
- Verify the leaderboards table has public read policy
- Check real-time replication is enabled (optional)
- Confirm data is being upserted correctly in browser console

## Migration from Local Storage

If you have existing users with local storage data, you can create a migration script to:
1. Read local storage data
2. Create accounts via Supabase Auth
3. Upload progress/settings to Supabase tables

This would require a one-time migration tool that users run after the Supabase migration.

## Next Steps

1. **Production Deployment**: 
   - Enable email confirmations
   - Set up custom SMTP for email
   - Configure proper redirect URLs

2. **Enhanced Features**:
   - Add password reset functionality
   - Implement email change
   - Add profile pictures using Supabase Storage
   - Add friends/social features

3. **Monitoring**:
   - Use Supabase Dashboard to monitor database usage
   - Set up alerts for quota limits
   - Review authentication logs

## Support

- Supabase Documentation: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com
- GridRun Repository Issues: [Your GitHub repo issues link]
