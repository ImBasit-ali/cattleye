-- Row Level Security (RLS) Policies for AI Monitoring System Tables

-- Enable RLS on new tables
ALTER TABLE camera_feeds ENABLE ROW LEVEL SECURITY;
ALTER TABLE identification_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE bcs_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeding_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE localization_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE veterinary_alerts ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- CAMERA FEEDS POLICIES
-- ============================================================================

-- Users can view their own camera feeds
CREATE POLICY "Users can view own camera feeds"
  ON camera_feeds FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own camera feeds
CREATE POLICY "Users can insert own camera feeds"
  ON camera_feeds FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own camera feeds
CREATE POLICY "Users can update own camera feeds"
  ON camera_feeds FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own camera feeds
CREATE POLICY "Users can delete own camera feeds"
  ON camera_feeds FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- IDENTIFICATION RECORDS POLICIES
-- ============================================================================

-- Users can view identification records for their animals
CREATE POLICY "Users can view own identification records"
  ON identification_records FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert identification records
CREATE POLICY "Users can insert identification records"
  ON identification_records FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- BCS RECORDS POLICIES
-- ============================================================================

-- Users can view BCS records for their animals
CREATE POLICY "Users can view own BCS records"
  ON bcs_records FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert BCS records
CREATE POLICY "Users can insert BCS records"
  ON bcs_records FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own BCS records
CREATE POLICY "Users can update own BCS records"
  ON bcs_records FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- FEEDING RECORDS POLICIES
-- ============================================================================

-- Users can view feeding records for their animals
CREATE POLICY "Users can view own feeding records"
  ON feeding_records FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert feeding records
CREATE POLICY "Users can insert feeding records"
  ON feeding_records FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own feeding records
CREATE POLICY "Users can update own feeding records"
  ON feeding_records FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- LOCALIZATION RECORDS POLICIES
-- ============================================================================

-- Users can view localization records for their animals
CREATE POLICY "Users can view own localization records"
  ON localization_records FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert localization records
CREATE POLICY "Users can insert localization records"
  ON localization_records FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- SYSTEM MONITORING POLICIES
-- ============================================================================

-- Users can view their own system monitoring data
CREATE POLICY "Users can view own system monitoring"
  ON system_monitoring FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert system monitoring data
CREATE POLICY "Users can insert system monitoring"
  ON system_monitoring FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- VETERINARY ALERTS POLICIES
-- ============================================================================

-- Users can view their own veterinary alerts
CREATE POLICY "Users can view own veterinary alerts"
  ON veterinary_alerts FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert veterinary alerts
CREATE POLICY "Users can insert veterinary alerts"
  ON veterinary_alerts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update (acknowledge) their own alerts
CREATE POLICY "Users can update own veterinary alerts"
  ON veterinary_alerts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own veterinary alerts
CREATE POLICY "Users can delete own veterinary alerts"
  ON veterinary_alerts FOR DELETE
  USING (auth.uid() = user_id);
