-- GridRun Supabase Database Schema
-- This file contains the SQL schema for the GridRun game database
-- Run these commands in your Supabase SQL editor to set up the database

-- Enable Row Level Security
-- Note: Supabase enables RLS by default on new tables

-- =====================================================
-- PROGRESS TABLE
-- Stores per-user game progress including unlocked worlds/levels and best scores
-- =====================================================
CREATE TABLE IF NOT EXISTS progress (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    worlds_unlocked INTEGER NOT NULL DEFAULT 1 CHECK (worlds_unlocked >= 1 AND worlds_unlocked <= 3),
    levels_unlocked INTEGER[] NOT NULL DEFAULT ARRAY[1, 0, 0],
    best_scores INTEGER[][] NOT NULL DEFAULT ARRAY[[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]],
    endless_best INTEGER NOT NULL DEFAULT 0 CHECK (endless_best >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS Policies for progress table
ALTER TABLE progress ENABLE ROW LEVEL SECURITY;

-- Users can only read their own progress
CREATE POLICY "Users can read own progress"
    ON progress FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own progress
CREATE POLICY "Users can insert own progress"
    ON progress FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own progress
CREATE POLICY "Users can update own progress"
    ON progress FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS progress_user_id_idx ON progress(user_id);

-- =====================================================
-- SETTINGS TABLE
-- Stores per-user audio and game settings
-- =====================================================
CREATE TABLE IF NOT EXISTS settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    menu_music BOOLEAN NOT NULL DEFAULT true,
    gameplay_music BOOLEAN NOT NULL DEFAULT true,
    sfx BOOLEAN NOT NULL DEFAULT true,
    volume_music NUMERIC(3,2) NOT NULL DEFAULT 0.75 CHECK (volume_music >= 0 AND volume_music <= 1),
    volume_sfx NUMERIC(3,2) NOT NULL DEFAULT 0.85 CHECK (volume_sfx >= 0 AND volume_sfx <= 1),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS Policies for settings table
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Users can only read their own settings
CREATE POLICY "Users can read own settings"
    ON settings FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own settings
CREATE POLICY "Users can insert own settings"
    ON settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own settings
CREATE POLICY "Users can update own settings"
    ON settings FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS settings_user_id_idx ON settings(user_id);

-- =====================================================
-- LEADERBOARDS TABLE
-- Stores global leaderboard data for all players
-- =====================================================
CREATE TABLE IF NOT EXISTS leaderboards (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL,
    endless_best INTEGER NOT NULL DEFAULT 0 CHECK (endless_best >= 0),
    campaign_total INTEGER NOT NULL DEFAULT 0 CHECK (campaign_total >= 0),
    world_1_total INTEGER NOT NULL DEFAULT 0 CHECK (world_1_total >= 0),
    world_2_total INTEGER NOT NULL DEFAULT 0 CHECK (world_2_total >= 0),
    world_3_total INTEGER NOT NULL DEFAULT 0 CHECK (world_3_total >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS Policies for leaderboards table
ALTER TABLE leaderboards ENABLE ROW LEVEL SECURITY;

-- Anyone can read leaderboards (public data)
CREATE POLICY "Anyone can read leaderboards"
    ON leaderboards FOR SELECT
    TO PUBLIC
    USING (true);

-- Users can insert their own leaderboard entry
CREATE POLICY "Users can insert own leaderboard entry"
    ON leaderboards FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own leaderboard entry
CREATE POLICY "Users can update own leaderboard entry"
    ON leaderboards FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Indexes for faster queries and sorting
CREATE INDEX IF NOT EXISTS leaderboards_user_id_idx ON leaderboards(user_id);
CREATE INDEX IF NOT EXISTS leaderboards_endless_best_idx ON leaderboards(endless_best DESC);
CREATE INDEX IF NOT EXISTS leaderboards_campaign_total_idx ON leaderboards(campaign_total DESC);
CREATE INDEX IF NOT EXISTS leaderboards_world_1_total_idx ON leaderboards(world_1_total DESC);
CREATE INDEX IF NOT EXISTS leaderboards_world_2_total_idx ON leaderboards(world_2_total DESC);
CREATE INDEX IF NOT EXISTS leaderboards_world_3_total_idx ON leaderboards(world_3_total DESC);
CREATE INDEX IF NOT EXISTS leaderboards_updated_at_idx ON leaderboards(updated_at DESC);

-- =====================================================
-- REALTIME SETUP
-- Enable realtime for leaderboards table
-- =====================================================
-- Note: Enable realtime in Supabase Dashboard under Database > Replication
-- Or run this command if you have permissions:
-- ALTER PUBLICATION supabase_realtime ADD TABLE leaderboards;

-- =====================================================
-- HELPFUL FUNCTIONS
-- =====================================================

-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to auto-update updated_at
CREATE TRIGGER update_progress_updated_at
    BEFORE UPDATE ON progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at
    BEFORE UPDATE ON settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_leaderboards_updated_at
    BEFORE UPDATE ON leaderboards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- NOTES
-- =====================================================
-- 1. Make sure to enable email authentication in Supabase Dashboard under Authentication > Providers
-- 2. Enable realtime for the leaderboards table in Database > Replication
-- 3. Update the Supabase URL and Anon Key in your application (index_dev.html)
-- 4. Consider adding additional indexes based on query patterns
-- 5. Monitor RLS policies to ensure proper security
