-- Enhanced Database Schema for AI-Powered Cattle Health Monitoring System
-- Based on Research: Multi-camera, Multi-zone Intelligent Monitoring
-- Supports: Ear-tag/Face/Body identification, BCS, Lameness, Feeding, Localization

-- Extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- CAMERA SYSTEM TABLES
-- ============================================================================

-- Camera Feeds Table (22 cameras: RGB, RGB-D, ToF Depth)
CREATE TABLE IF NOT EXISTS camera_feeds (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  camera_id VARCHAR(50) NOT NULL UNIQUE,
  camera_name VARCHAR(100) NOT NULL,
  camera_type VARCHAR(20) NOT NULL CHECK (camera_type IN ('RGB', 'RGB-D', 'ToF Depth')),
  functional_zone VARCHAR(50) NOT NULL CHECK (functional_zone IN ('Milking Parlor', 'Return Lane', 'Feeding Area', 'Resting Space')),
  view_type VARCHAR(50) NOT NULL,
  stream_url TEXT,
  is_active BOOLEAN DEFAULT true,
  current_fps DECIMAL(5, 2) DEFAULT 30.0,
  latency DECIMAL(5, 3) DEFAULT 0.620, -- Average 0.62s per frame
  last_frame_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- CATTLE IDENTIFICATION TABLES
-- ============================================================================

-- Identification Records (Ear Tag, Face, Body, Body-Color)
CREATE TABLE IF NOT EXISTS identification_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  identification_method VARCHAR(50) NOT NULL CHECK (identification_method IN ('Ear Tag', 'Face-based', 'Body-based', 'Body-Color Point Cloud')),
  confidence DECIMAL(5, 2) NOT NULL CHECK (confidence >= 0 AND confidence <= 100),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  camera_id VARCHAR(50) REFERENCES camera_feeds(camera_id),
  image_url TEXT,
  features JSONB, -- Stores extracted features (face embeddings, body descriptors, etc.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX idx_identification_records_animal_id ON identification_records(animal_id);
CREATE INDEX idx_identification_records_method ON identification_records(identification_method);
CREATE INDEX idx_identification_records_timestamp ON identification_records(timestamp DESC);

-- ============================================================================
-- BODY CONDITION SCORE (BCS) TABLES
-- ============================================================================

-- BCS Records (86.21% accuracy from research)
CREATE TABLE IF NOT EXISTS bcs_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bcs_score DECIMAL(2, 1) NOT NULL CHECK (bcs_score >= 1.0 AND bcs_score <= 5.0),
  confidence DECIMAL(5, 2) NOT NULL CHECK (confidence >= 0 AND confidence <= 100),
  assessment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  assessment_method VARCHAR(20) DEFAULT 'AI-predicted' CHECK (assessment_method IN ('AI-predicted', 'Manual')),
  veterinarian_notes TEXT,
  image_url TEXT,
  measurements JSONB, -- Body measurements from depth cameras
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for BCS tracking
CREATE INDEX idx_bcs_records_animal_id ON bcs_records(animal_id);
CREATE INDEX idx_bcs_records_date ON bcs_records(assessment_date DESC);

-- ============================================================================
-- FEEDING TIME ESTIMATION TABLES
-- ============================================================================

-- Feeding Records
CREATE TABLE IF NOT EXISTS feeding_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  duration_hours DECIMAL(5, 2) DEFAULT 0,
  functional_zone VARCHAR(50) DEFAULT 'Feeding Area',
  camera_id VARCHAR(50) REFERENCES camera_feeds(camera_id),
  confidence DECIMAL(5, 2) DEFAULT 0,
  behavior_data JSONB, -- Head position, eating patterns, etc.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for feeding analytics
CREATE INDEX idx_feeding_records_animal_id ON feeding_records(animal_id);
CREATE INDEX idx_feeding_records_start_time ON feeding_records(start_time DESC);

-- ============================================================================
-- REAL-TIME LOCALIZATION TABLES
-- ============================================================================

-- Localization Records (Real-time position tracking)
CREATE TABLE IF NOT EXISTS localization_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  current_zone VARCHAR(50) NOT NULL CHECK (current_zone IN ('Milking Parlor', 'Return Lane', 'Feeding Area', 'Resting Space')),
  position_x DECIMAL(10, 3) NOT NULL, -- X coordinate in meters
  position_y DECIMAL(10, 3) NOT NULL, -- Y coordinate in meters
  position_z DECIMAL(10, 3), -- Z coordinate from depth cameras
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  camera_id VARCHAR(50) REFERENCES camera_feeds(camera_id),
  confidence DECIMAL(5, 2) DEFAULT 0,
  spatial_data JSONB, -- Point cloud data, trajectories
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for real-time queries
CREATE INDEX idx_localization_records_animal_id ON localization_records(animal_id);
CREATE INDEX idx_localization_records_timestamp ON localization_records(timestamp DESC);
CREATE INDEX idx_localization_records_zone ON localization_records(current_zone);

-- ============================================================================
-- ENHANCED ANIMALS TABLE
-- ============================================================================

-- Add new columns to existing animals table
ALTER TABLE animals ADD COLUMN IF NOT EXISTS species VARCHAR(50) DEFAULT 'Cow';
ALTER TABLE animals ADD COLUMN IF NOT EXISTS current_zone VARCHAR(50) DEFAULT 'Resting Space';
ALTER TABLE animals ADD COLUMN IF NOT EXISTS latest_bcs DECIMAL(2, 1);
ALTER TABLE animals ADD COLUMN IF NOT EXISTS latest_bcs_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE animals ADD COLUMN IF NOT EXISTS identification_methods JSONB; -- Stores enabled identification methods
ALTER TABLE animals ADD COLUMN IF NOT EXISTS ear_tag_id VARCHAR(50) UNIQUE;

-- ============================================================================
-- ENHANCED LAMENESS RECORDS TABLE
-- ============================================================================

-- Add lameness score and severity
ALTER TABLE lameness_records ADD COLUMN IF NOT EXISTS lameness_score INTEGER CHECK (lameness_score >= 0 AND lameness_score <= 5);
ALTER TABLE lameness_records ADD COLUMN IF NOT EXISTS severity VARCHAR(30) CHECK (severity IN ('Normal', 'Mild Lameness', 'Severe Lameness'));
ALTER TABLE lameness_records ADD COLUMN IF NOT EXISTS camera_id VARCHAR(50) REFERENCES camera_feeds(camera_id);
ALTER TABLE lameness_records ADD COLUMN IF NOT EXISTS gait_analysis JSONB; -- Gait features from video analysis

-- ============================================================================
-- SYSTEM MONITORING TABLE
-- ============================================================================

-- System Health Monitoring (24-hour continuous operation)
CREATE TABLE IF NOT EXISTS system_monitoring (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  check_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  total_cameras_active INTEGER DEFAULT 0,
  average_latency DECIMAL(5, 3),
  average_fps DECIMAL(5, 2),
  total_identifications_24h INTEGER DEFAULT 0,
  total_bcs_assessments_24h INTEGER DEFAULT 0,
  total_lameness_detections_24h INTEGER DEFAULT 0,
  system_uptime_hours DECIMAL(10, 2),
  metrics JSONB, -- Additional performance metrics
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- VETERINARY ALERTS TABLE
-- ============================================================================

-- Veterinary Alerts (from GX/DX initiatives)
CREATE TABLE IF NOT EXISTS veterinary_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN ('Health Alert', 'Lameness Detected', 'Feeding Alert', 'Location Alert', 'BCS Alert')),
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('Low', 'Medium', 'High', 'Critical')),
  message TEXT NOT NULL,
  is_acknowledged BOOLEAN DEFAULT false,
  acknowledged_by UUID REFERENCES auth.users(id),
  acknowledged_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_veterinary_alerts_animal_id ON veterinary_alerts(animal_id);
CREATE INDEX idx_veterinary_alerts_severity ON veterinary_alerts(severity);
CREATE INDEX idx_veterinary_alerts_created ON veterinary_alerts(created_at DESC);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update animal's latest BCS
CREATE OR REPLACE FUNCTION update_animal_latest_bcs()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE animals 
  SET 
    latest_bcs = NEW.bcs_score,
    latest_bcs_date = NEW.assessment_date,
    updated_at = NOW()
  WHERE id = NEW.animal_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for BCS updates
DROP TRIGGER IF EXISTS trigger_update_animal_bcs ON bcs_records;
CREATE TRIGGER trigger_update_animal_bcs
AFTER INSERT ON bcs_records
FOR EACH ROW
EXECUTE FUNCTION update_animal_latest_bcs();

-- Function to update animal's current zone
CREATE OR REPLACE FUNCTION update_animal_current_zone()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE animals 
  SET 
    current_zone = NEW.current_zone,
    updated_at = NOW()
  WHERE id = NEW.animal_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for location updates
DROP TRIGGER IF EXISTS trigger_update_animal_zone ON localization_records;
CREATE TRIGGER trigger_update_animal_zone
AFTER INSERT ON localization_records
FOR EACH ROW
EXECUTE FUNCTION update_animal_current_zone();

-- Function to calculate feeding duration on end_time update
CREATE OR REPLACE FUNCTION calculate_feeding_duration()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.end_time IS NOT NULL AND NEW.start_time IS NOT NULL THEN
    NEW.duration_hours = EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) / 3600.0;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for feeding duration
DROP TRIGGER IF EXISTS trigger_calculate_feeding_duration ON feeding_records;
CREATE TRIGGER trigger_calculate_feeding_duration
BEFORE INSERT OR UPDATE ON feeding_records
FOR EACH ROW
EXECUTE FUNCTION calculate_feeding_duration();

-- ============================================================================
-- PERFORMANCE OPTIMIZATIONS
-- ============================================================================

-- Partitioning for large tables (optional, for production scale)
-- CREATE TABLE localization_records_partitioned (LIKE localization_records INCLUDING ALL)
-- PARTITION BY RANGE (timestamp);

-- Materialized view for dashboard statistics
CREATE MATERIALIZED VIEW IF NOT EXISTS dashboard_statistics AS
SELECT 
  a.user_id,
  COUNT(DISTINCT a.id) as total_animals,
  COUNT(DISTINCT CASE WHEN a.is_milking THEN a.id END) as milking_cows,
  COUNT(DISTINCT CASE WHEN lr.is_lame THEN a.id END) as lame_cows,
  AVG(CASE WHEN a.latest_bcs IS NOT NULL THEN a.latest_bcs END) as average_bcs,
  COUNT(DISTINCT cf.id) as total_cameras_active,
  AVG(cf.latency) as average_system_latency
FROM animals a
LEFT JOIN camera_feeds cf ON cf.user_id = a.user_id AND cf.is_active = true
LEFT JOIN LATERAL (
  SELECT DISTINCT ON (animal_id) *
  FROM lameness_records
  WHERE animal_id = a.id
  ORDER BY animal_id, detected_at DESC
) lr ON lr.animal_id = a.id
GROUP BY a.user_id;

-- Index on materialized view
CREATE UNIQUE INDEX idx_dashboard_statistics_user ON dashboard_statistics(user_id);

-- Refresh function for dashboard
CREATE OR REPLACE FUNCTION refresh_dashboard_statistics()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY dashboard_statistics;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE camera_feeds IS 'Multi-camera setup: RGB, RGB-D, ToF depth cameras across 4 functional zones';
COMMENT ON TABLE identification_records IS 'Cattle identification: Ear-tag (94%), Face (93.66%), Body (92.8%), Body-color (99.55%)';
COMMENT ON TABLE bcs_records IS 'Body Condition Scoring with 86.21% AI accuracy';
COMMENT ON TABLE feeding_records IS 'Feeding time estimation from AI video analysis';
COMMENT ON TABLE localization_records IS 'Real-time cattle position tracking across zones';
COMMENT ON TABLE veterinary_alerts IS 'Automated alerts for veterinarians and farm personnel';
COMMENT ON TABLE system_monitoring IS 'System health monitoring for 24-hour continuous operation';
