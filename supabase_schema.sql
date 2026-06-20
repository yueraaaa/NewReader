-- REAL READER - Supabase Schema with Row Level Security (RLS)
-- Run this entire file in Supabase SQL Editor

-- ============================================
-- TABLE CREATION
-- ============================================

CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  user_id TEXT DEFAULT '',
  is_deleted INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS feeds (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  category_id TEXT REFERENCES categories(id),
  user_id TEXT DEFAULT '',
  is_deleted INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS articles (
  id TEXT PRIMARY KEY,
  feed_id TEXT NOT NULL REFERENCES feeds(id),
  title TEXT NOT NULL,
  link TEXT NOT NULL,
  description TEXT,
  content TEXT,
  author TEXT,
  image_url TEXT,
  published_at TEXT,
  is_read INTEGER DEFAULT 0,
  is_favorite INTEGER DEFAULT 0,
  read_progress REAL DEFAULT 0,
  user_id TEXT DEFAULT '',
  is_deleted INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS settings (
  key TEXT,
  user_id TEXT DEFAULT '',
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_metadata (
  table_name TEXT PRIMARY KEY,
  last_synced_at TEXT
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_articles_feed_id ON articles(feed_id);
CREATE INDEX IF NOT EXISTS idx_articles_published_at ON articles(published_at);
CREATE INDEX IF NOT EXISTS idx_feeds_category_id ON feeds(category_id);
CREATE INDEX IF NOT EXISTS idx_feeds_user_id ON feeds(user_id);
CREATE INDEX IF NOT EXISTS idx_articles_user_id ON articles(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeds ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any (for clean re-run)
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

-- ============================================
-- MIGRATION: Add user_id to settings table
-- ============================================
-- For existing Supabase instances, run these to migrate:
-- ALTER TABLE settings ADD COLUMN IF NOT EXISTS user_id TEXT DEFAULT '';
-- ALTER TABLE settings DROP CONSTRAINT IF EXISTS settings_pkey;
-- ALTER TABLE settings ADD PRIMARY KEY (key, user_id);
