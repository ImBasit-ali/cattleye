-- Migration 10: Comprehensive AI Analysis Results Table
-- Stores full OpenRouter analysis results (all 5 functions) per image/frame.
-- Works alongside existing: bcs_records, feeding_records, lameness_records.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- CATTLE AI ANALYSES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS cattle_ai_analyses (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_hash            VARCHAR(32) NOT NULL,          -- MD5 of first 100KB of frame
  analyzed_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  camera_id             VARCHAR(50),   -- no FK — camera_feeds may not exist yet
  animal_id             UUID REFERENCES animals(id) ON DELETE SET NULL,
  source_type           VARCHAR(20) DEFAULT 'live_camera'
                          CHECK (source_type IN ('live_camera', 'video_upload', 'manual')),
  video_file_name       TEXT,

  -- Ear tag results
  ear_tag_detected      BOOLEAN DEFAULT false,
  ear_tag_number        VARCHAR(50),
  ear_tag_confidence    INTEGER CHECK (ear_tag_confidence BETWEEN 0 AND 100),

  -- Muzzle / breed
  breed_estimate        VARCHAR(100),

  -- BCS results
  bcs_score             DECIMAL(2,1) CHECK (bcs_score BETWEEN 1.0 AND 5.0),
  bcs_category          VARCHAR(20),

  -- Lameness results
  lameness_detected     BOOLEAN DEFAULT false,
  lameness_score        INTEGER CHECK (lameness_score BETWEEN 1 AND 5),
  lameness_urgency      VARCHAR(30),

  -- Feeding behavior
  feeding_behavior      VARCHAR(50),
  feeding_engagement    INTEGER CHECK (feeding_engagement BETWEEN 0 AND 100),

  -- Overall health
  health_status         VARCHAR(30),
  priority_alert        TEXT,

  -- Full raw JSON for all 5 functions
  full_result           JSONB,

  created_at            TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_ai_analyses_user_id
  ON cattle_ai_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_analyses_analyzed_at
  ON cattle_ai_analyses(analyzed_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_analyses_camera_id
  ON cattle_ai_analyses(camera_id);
CREATE INDEX IF NOT EXISTS idx_ai_analyses_animal_id
  ON cattle_ai_analyses(animal_id);
CREATE INDEX IF NOT EXISTS idx_ai_analyses_image_hash
  ON cattle_ai_analyses(image_hash);
CREATE INDEX IF NOT EXISTS idx_ai_analyses_health_status
  ON cattle_ai_analyses(health_status);
CREATE INDEX IF NOT EXISTS idx_ai_analyses_lameness
  ON cattle_ai_analyses(lameness_detected) WHERE lameness_detected = true;

COMMENT ON TABLE cattle_ai_analyses IS
  'Full OpenRouter AI analysis results: ear tag, muzzle, BCS, lameness, feeding (all 5 functions per frame)';
COMMENT ON COLUMN cattle_ai_analyses.image_hash IS
  'MD5 of first 100KB of image bytes — used for 8-hour cache deduplication';
COMMENT ON COLUMN cattle_ai_analyses.full_result IS
  'Complete JSON from OpenRouter: eartag, muzzle, bcs, lameness, feeding, overall_health';
