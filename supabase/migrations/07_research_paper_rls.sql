-- Row Level Security Policies for Research Paper 7-Table Schema

-- Enable RLS on all 7 tables
ALTER TABLE cow ENABLE ROW LEVEL SECURITY;
ALTER TABLE ear_tag_camera ENABLE ROW LEVEL SECURITY;
ALTER TABLE depth_camera ENABLE ROW LEVEL SECURITY;
ALTER TABLE side_view_camera ENABLE ROW LEVEL SECURITY;
ALTER TABLE rgbd_camera ENABLE ROW LEVEL SECURITY;
ALTER TABLE head_view_camera ENABLE ROW LEVEL SECURITY;
ALTER TABLE back_view_camera ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- COW TABLE POLICIES
-- ============================================================================

CREATE POLICY "Users can view own cattle"
  ON cow FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cattle"
  ON cow FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cattle"
  ON cow FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own cattle"
  ON cow FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- EAR-TAG CAMERA TABLE POLICIES
-- ============================================================================

CREATE POLICY "Users can view own ear tag records"
  ON ear_tag_camera FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert ear tag records"
  ON ear_tag_camera FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- DEPTH CAMERA TABLE POLICIES
-- ============================================================================

CREATE POLICY "Users can view own depth camera records"
  ON depth_camera FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert depth camera records"
  ON depth_camera FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- SIDE VIEW CAMERA TABLE POLICIES
-- ============================================================================

CREATE POLICY "Users can view own side view records"
  ON side_view_camera FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert side view records"
  ON side_view_camera FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- RGB-D CAMERA TABLE POLICIES
-- ============================================================================

CREATE POLICY "Users can view own RGB-D records"
  ON rgbd_camera FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert RGB-D records"
  ON rgbd_camera FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- HEAD VIEW CAMERA TABLE POLICIES
-- ============================================================================

CREATE POLICY "Users can view own head view records"
  ON head_view_camera FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert head view records"
  ON head_view_camera FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update head view records"
  ON head_view_camera FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- BACK VIEW CAMERA TABLE POLICIES
-- ============================================================================

CREATE POLICY "Users can view own back view records"
  ON back_view_camera FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert back view records"
  ON back_view_camera FOR INSERT
  WITH CHECK (auth.uid() = user_id);
