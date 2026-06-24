-- Run this once in Supabase Dashboard → SQL Editor
-- Creates the table the Flutter app expects (cattle_detections).
-- Your project currently has lameness_detections only — that is a different table.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS cattle_detections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cattle_id TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  confidence FLOAT DEFAULT 0.0,
  cattle_count INT DEFAULT 1,
  buffalo_count INT DEFAULT 0,
  lameness_score FLOAT DEFAULT 0.0,
  is_lame BOOLEAN DEFAULT FALSE,
  milking_status TEXT DEFAULT 'unknown',
  bcs_score FLOAT,
  feeding_alert BOOLEAN DEFAULT FALSE,
  source TEXT DEFAULT 'camera',
  detected_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cattle_detections_user_id
  ON cattle_detections(user_id);
CREATE INDEX IF NOT EXISTS idx_cattle_detections_detected_at
  ON cattle_detections(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_cattle_detections_cattle_id
  ON cattle_detections(cattle_id);

ALTER TABLE cattle_detections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own detections" ON cattle_detections;
CREATE POLICY "Users can view own detections"
  ON cattle_detections FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own detections" ON cattle_detections;
CREATE POLICY "Users can insert own detections"
  ON cattle_detections FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Realtime (optional — dashboard live updates)
ALTER PUBLICATION supabase_realtime ADD TABLE cattle_detections;

-- AI analyses RLS (if migration 10 was applied without policies)
ALTER TABLE IF EXISTS cattle_ai_analyses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own ai analyses" ON cattle_ai_analyses;
CREATE POLICY "Users can view own ai analyses"
  ON cattle_ai_analyses FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own ai analyses" ON cattle_ai_analyses;
CREATE POLICY "Users can insert own ai analyses"
  ON cattle_ai_analyses FOR INSERT
  WITH CHECK (auth.uid() = user_id);
