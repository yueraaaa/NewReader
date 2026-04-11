-- REAL READER - Supabase Schema with Row Level Security (RLS)
-- Run this in Supabase SQL Editor to set up the database

-- Enable RLS on all tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeds ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any (to recreate cleanly)
DROP POLICY IF EXISTS "Users can view own categories" ON categories;
DROP POLICY IF EXISTS "Users can insert own categories" ON categories;
DROP POLICY IF EXISTS "Users can update own categories" ON categories;
DROP POLICY IF EXISTS "Users can delete own categories" ON categories;
DROP POLICY IF EXISTS "Users can view own feeds" ON feeds;
DROP POLICY IF EXISTS "Users can insert own feeds" ON feeds;
DROP POLICY IF EXISTS "Users can update own feeds" ON feeds;
DROP POLICY IF EXISTS "Users can delete own feeds" ON feeds;
DROP POLICY IF EXISTS "Users can view own articles" ON articles;
DROP POLICY IF EXISTS "Users can insert own articles" ON articles;
DROP POLICY IF EXISTS "Users can update own articles" ON articles;
DROP POLICY IF EXISTS "Users can delete own articles" ON articles;
DROP POLICY IF EXISTS "Users can view own settings" ON settings;
DROP POLICY IF EXISTS "Users can insert own settings" ON settings;
DROP POLICY IF EXISTS "Users can update own settings" ON settings;
DROP POLICY IF EXISTS "Users can delete own settings" ON settings;

-- Categories policies
CREATE POLICY "Users can view own categories" ON categories
  FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own categories" ON categories
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own categories" ON categories
  FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own categories" ON categories
  FOR DELETE USING (auth.uid()::text = user_id);

-- Feeds policies
CREATE POLICY "Users can view own feeds" ON feeds
  FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own feeds" ON feeds
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own feeds" ON feeds
  FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own feeds" ON feeds
  FOR DELETE USING (auth.uid()::text = user_id);

-- Articles policies
CREATE POLICY "Users can view own articles" ON articles
  FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own articles" ON articles
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own articles" ON articles
  FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own articles" ON articles
  FOR DELETE USING (auth.uid()::text = user_id);

-- Settings policies
CREATE POLICY "Users can view own settings" ON settings
  FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own settings" ON settings
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own settings" ON settings
  FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own settings" ON settings
  FOR DELETE USING (auth.uid()::text = user_id);
