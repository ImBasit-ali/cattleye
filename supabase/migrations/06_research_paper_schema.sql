-- Complete Database Schema from Research Paper
-- Based on: "AI-powered cattle health monitoring system combining real-time computer vision"
-- Published in: Smart Agricultural Technology 12 (2025) 101300
-- 7-Table Structure as per Entity-Relationship Diagram (Fig. 8)

-- ============================================================================
-- TABLE 1: COW TABLE (General Health and Status Information)
-- ============================================================================

CREATE TABLE IF NOT EXISTS cow (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cattle_id VARCHAR(20) NOT NULL UNIQUE, -- Individual cattle identifier
  ear_tag_number VARCHAR(20) UNIQUE, -- Physical ear tag (J/M + digits)
  species VARCHAR(50) DEFAULT 'Dairy Cattle',
  breed VARCHAR(100),
  date_of_birth DATE,
  gender VARCHAR(10) CHECK (gender IN ('Male', 'Female')),
  
  -- Current Health Status
  current_health_status VARCHAR(30) DEFAULT 'Healthy',
  current_zone VARCHAR(50) DEFAULT 'Resting Space',
  last_seen_timestamp TIMESTAMP WITH TIME ZONE,
  last_seen_camera VARCHAR(50),
  
  -- Latest Scores (automatically updated by triggers)
  latest_bcs_score DECIMAL(2, 1), -- Body Condition Score (1.0-5.0)
  latest_bcs_date TIMESTAMP WITH TIME ZONE,
  latest_lameness_score INTEGER CHECK (latest_lameness_score >= 0 AND latest_lameness_score <= 5),
  latest_lameness_date TIMESTAMP WITH TIME ZONE,
  latest_lameness_severity VARCHAR(30),
  
  -- Body Measurements
  estimated_body_weight DECIMAL(6, 2), -- in kg
  last_weight_update TIMESTAMP WITH TIME ZONE,
  
  -- Feeding Statistics
  total_daily_feeding_time_hours DECIMAL(5, 2) DEFAULT 0,
  last_feeding_date DATE,
  
  -- Feature Vectors for Identification
  face_embedding VECTOR(512), -- ArcFace embeddings
  body_embedding VECTOR(512), -- ResNet-101 embeddings
  point_cloud_embedding VECTOR(256), -- PointNet++ embeddings
  
  -- Metadata
  notes TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_cow_cattle_id ON cow(cattle_id);
CREATE INDEX idx_cow_ear_tag ON cow(ear_tag_number);
CREATE INDEX idx_cow_user_id ON cow(user_id);
CREATE INDEX idx_cow_current_zone ON cow(current_zone);

-- ============================================================================
-- TABLE 2: EAR-TAG CAMERA TABLE (Milking Parlor - Cameras 1 & 2)
-- ============================================================================

CREATE TABLE IF NOT EXISTS ear_tag_camera (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cow_id UUID REFERENCES cow(id) ON DELETE CASCADE,
  
  -- Detection Information
  ear_tag_number VARCHAR(20), -- Recognized from CRAFT + ResNet18
  confidence DECIMAL(5, 2) CHECK (confidence >= 0 AND confidence <= 100),
  detection_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Camera and Location
  camera_number INTEGER CHECK (camera_number IN (1, 2)), -- Cameras 1 & 2 in milking parlor
  camera_name VARCHAR(100),
  functional_zone VARCHAR(50) DEFAULT 'Milking Parlor',
  
  -- Image Data
  head_image_url TEXT, -- 1920x1080 RGB image
  ear_tag_crop_url TEXT, -- Cropped ear tag region
  bounding_box JSONB, -- {x, y, width, height}
  
  -- Character Recognition Details
  detected_characters JSONB, -- Array of recognized characters with confidences
  recognition_method VARCHAR(50) DEFAULT 'CRAFT+ResNet18',
  
  -- Milking Session
  milking_session_start TIMESTAMP WITH TIME ZONE,
  milking_session_end TIMESTAMP WITH TIME ZONE,
  milking_position INTEGER, -- Position in milking parlor
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ear_tag_cow_id ON ear_tag_camera(cow_id);
CREATE INDEX idx_ear_tag_number ON ear_tag_camera(ear_tag_number);
CREATE INDEX idx_ear_tag_timestamp ON ear_tag_camera(detection_timestamp DESC);
CREATE INDEX idx_ear_tag_camera_num ON ear_tag_camera(camera_number);

-- ============================================================================
-- TABLE 3: DEPTH CAMERA TABLE (Return Lane - Lameness & Milking Info)
-- ============================================================================

CREATE TABLE IF NOT EXISTS depth_camera (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cow_id UUID REFERENCES cow(id) ON DELETE CASCADE,
  
  -- Lameness Classification (Extra Trees Classifier)
  lameness_score INTEGER CHECK (lameness_score >= 0 AND lameness_score <= 5),
  lameness_severity VARCHAR(30) CHECK (lameness_severity IN ('Normal', 'Mild Lameness', 'Severe Lameness')),
  lameness_confidence DECIMAL(5, 2),
  
  -- Detection Method
  detection_method VARCHAR(100) DEFAULT 'Detectron2 + Extra Trees',
  time_of_day VARCHAR(20) CHECK (time_of_day IN ('Morning', 'Evening')), -- Different accuracies: 88.2% morning, 89.0% evening
  
  -- Camera Information
  camera_number INTEGER CHECK (camera_number = 3), -- Camera 3 for lameness
  functional_zone VARCHAR(50) DEFAULT 'Return Lane',
  
  -- Depth Features
  depth_image_url TEXT,
  back_depth_features JSONB, -- Extracted depth features from cattle back
  segmentation_mask_url TEXT, -- Detectron2 segmentation mask
  
  -- Tracking Information
  tracking_id INTEGER,
  frame_number INTEGER,
  
  -- Milking Information (correlated with ear tag data)
  post_milking_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  related_milking_session_id UUID, -- Links to ear_tag_camera entry
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_depth_cow_id ON depth_camera(cow_id);
CREATE INDEX idx_depth_lameness_score ON depth_camera(lameness_score);
CREATE INDEX idx_depth_timestamp ON depth_camera(post_milking_timestamp DESC);

-- ============================================================================
-- TABLE 4: SIDE VIEW CAMERA TABLE (Return Lane - Lameness from RGB)
-- ============================================================================

CREATE TABLE IF NOT EXISTS side_view_camera (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cow_id UUID REFERENCES cow(id) ON DELETE CASCADE,
  
  -- Lameness Classification (SVM Classifier)
  lameness_score INTEGER CHECK (lameness_score >= 0 AND lameness_score <= 5),
  lameness_severity VARCHAR(30),
  classification_confidence DECIMAL(5, 2),
  
  -- Detection Method
  detection_method VARCHAR(100) DEFAULT 'YOLOv9 + SVM',
  
  -- Camera Information
  camera_number INTEGER CHECK (camera_number = 5), -- Camera 5 for side view
  functional_zone VARCHAR(50) DEFAULT 'Return Lane',
  
  -- Gait Analysis Features
  side_view_image_url TEXT,
  leg_keypoints JSONB, -- Tracked leg keypoints across frames
  gait_features JSONB, -- Temporal movement patterns
  movement_trajectory JSONB, -- Sequence of positions
  
  -- Tracking Information
  tracking_id INTEGER,
  sequence_start_frame INTEGER,
  sequence_end_frame INTEGER,
  total_frames_analyzed INTEGER,
  
  -- Temporal Data
  analysis_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  video_clip_url TEXT, -- Short clip of gait analysis
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_side_view_cow_id ON side_view_camera(cow_id);
CREATE INDEX idx_side_view_lameness ON side_view_camera(lameness_score);
CREATE INDEX idx_side_view_timestamp ON side_view_camera(analysis_timestamp DESC);

-- ============================================================================
-- TABLE 5: RGB-D CAMERA TABLE (Return Lane - BCS & Body Weight)
-- ============================================================================

CREATE TABLE IF NOT EXISTS rgbd_camera (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cow_id UUID REFERENCES cow(id) ON DELETE CASCADE,
  
  -- Body Condition Score (Random Forest Classifier)
  bcs_score DECIMAL(2, 1) CHECK (bcs_score >= 1.0 AND bcs_score <= 5.0),
  bcs_confidence DECIMAL(5, 2),
  bcs_tolerance_level DECIMAL(3, 2), -- 0, 0.25, or 0.5
  bcs_accuracy_at_tolerance DECIMAL(5, 2), -- 51.36%, 86.21%, or 97.83%
  
  -- Detection Method
  detection_method VARCHAR(100) DEFAULT 'Detectron2 + Random Forest',
  identification_method VARCHAR(100) DEFAULT 'PointNet++ Siamese Network',
  identification_confidence DECIMAL(5, 2),
  
  -- Camera Information
  camera_number INTEGER CHECK (camera_number = 4), -- Camera 4 for RGB-D
  functional_zone VARCHAR(50) DEFAULT 'Return Lane',
  
  -- Point Cloud Data (2048 downsampled points)
  point_cloud_url TEXT, -- Color point cloud file
  point_cloud_features JSONB, -- Extracted geometric features
  downsampled_points INTEGER DEFAULT 2048,
  
  -- Geometric Features (from Random Forest)
  normal_vectors JSONB,
  curvature_values JSONB,
  point_density DECIMAL(10, 4),
  planarity DECIMAL(6, 4),
  linearity DECIMAL(6, 4),
  sphericity DECIMAL(6, 4),
  fpfh_descriptor JSONB, -- Fast Point Feature Histograms
  triangle_mesh_area DECIMAL(10, 4),
  convex_hull_area DECIMAL(10, 4),
  
  -- Body Weight Estimation
  estimated_body_weight DECIMAL(6, 2), -- in kg
  weight_estimation_confidence DECIMAL(5, 2),
  
  -- Tracking Information
  tracking_id INTEGER,
  
  -- Temporal Data
  assessment_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  depth_image_url TEXT,
  rgb_image_url TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_rgbd_cow_id ON rgbd_camera(cow_id);
CREATE INDEX idx_rgbd_bcs_score ON rgbd_camera(bcs_score);
CREATE INDEX idx_rgbd_timestamp ON rgbd_camera(assessment_timestamp DESC);

-- ============================================================================
-- TABLE 6: HEAD VIEW CAMERA TABLE (Feeding Area - Cameras 7-10)
-- ============================================================================

CREATE TABLE IF NOT EXISTS head_view_camera (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cow_id UUID REFERENCES cow(id) ON DELETE CASCADE,
  
  -- Identification (ArcFace Model - 93.66% accuracy)
  cattle_id_predicted VARCHAR(20),
  identification_confidence DECIMAL(5, 2),
  identification_method VARCHAR(100) DEFAULT 'Mask R-CNN + Siamese + ArcFace',
  
  -- Camera Information
  camera_number INTEGER CHECK (camera_number IN (7, 8, 9, 10)), -- 4K RGB cameras
  functional_zone VARCHAR(50) DEFAULT 'Feeding Area',
  
  -- Head Detection & Tracking
  head_image_url TEXT, -- 1920x1080 resolution
  head_bounding_box JSONB, -- {x, y, width, height}
  tracking_id INTEGER,
  
  -- Facial Features
  facial_embedding VECTOR(512), -- ArcFace embeddings
  face_features JSONB, -- Additional facial characteristics
  
  -- Feeding Behavior
  feeding_line_y_coordinate INTEGER, -- Virtual feeding line position
  head_position_y INTEGER, -- Y-coordinate of head center
  is_feeding BOOLEAN DEFAULT false, -- Head below feeding line
  
  -- Feeding Time Calculation
  feeding_session_start TIMESTAMP WITH TIME ZONE,
  feeding_session_end TIMESTAMP WITH TIME ZONE,
  feeding_duration_seconds DECIMAL(10, 2),
  cumulative_daily_feeding_seconds DECIMAL(10, 2),
  
  -- Frame-level Data
  frame_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  frame_number INTEGER,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_head_view_cow_id ON head_view_camera(cow_id);
CREATE INDEX idx_head_view_camera_num ON head_view_camera(camera_number);
CREATE INDEX idx_head_view_timestamp ON head_view_camera(frame_timestamp DESC);
CREATE INDEX idx_head_view_feeding ON head_view_camera(is_feeding);

-- ============================================================================
-- TABLE 7: BACK VIEW CAMERA TABLE (Feeding & Resting - Cameras 11-23)
-- ============================================================================

CREATE TABLE IF NOT EXISTS back_view_camera (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cow_id UUID REFERENCES cow(id) ON DELETE CASCADE,
  
  -- Identification (ResNet-101 - 92.80% accuracy)
  cattle_id_predicted VARCHAR(20),
  identification_confidence DECIMAL(5, 2),
  identification_method VARCHAR(100) DEFAULT 'Mask R-CNN + ByteTrack + ResNet-101',
  
  -- Camera Information
  camera_number INTEGER CHECK (camera_number >= 11 AND camera_number <= 23), -- 13 Full HD cameras
  functional_zone VARCHAR(50) CHECK (functional_zone IN ('Feeding Area', 'Resting Space')),
  
  -- Body Detection & Tracking
  body_image_url TEXT,
  body_bounding_box JSONB, -- {x, y, width, height}
  body_mask_url TEXT, -- Mask R-CNN segmentation mask
  tracking_id INTEGER,
  
  -- Body Features
  body_embedding VECTOR(512), -- ResNet-101 embeddings
  body_color_features JSONB, -- Color histogram, dominant colors
  body_shape_features JSONB, -- Geometric shape descriptors
  
  -- Localization Information
  position_x INTEGER, -- X-coordinate in image
  position_y INTEGER, -- Y-coordinate in image
  current_zone VARCHAR(50),
  zone_entry_timestamp TIMESTAMP WITH TIME ZONE,
  
  -- Multi-Camera Tracking
  previous_camera_number INTEGER,
  next_camera_number INTEGER,
  camera_transition_timestamp TIMESTAMP WITH TIME ZONE,
  
  -- Recording Interval (one-minute intervals as per paper)
  recording_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_minute_marker BOOLEAN DEFAULT false, -- Marks one-minute interval records
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_back_view_cow_id ON back_view_camera(cow_id);
CREATE INDEX idx_back_view_camera_num ON back_view_camera(camera_number);
CREATE INDEX idx_back_view_zone ON back_view_camera(current_zone);
CREATE INDEX idx_back_view_timestamp ON back_view_camera(recording_timestamp DESC);
CREATE INDEX idx_back_view_tracking ON back_view_camera(tracking_id);

-- ============================================================================
-- TRIGGERS FOR AUTOMATIC COW TABLE UPDATES
-- ============================================================================

-- Update latest BCS from RGB-D camera
CREATE OR REPLACE FUNCTION update_cow_latest_bcs()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE cow 
  SET 
    latest_bcs_score = NEW.bcs_score,
    latest_bcs_date = NEW.assessment_timestamp,
    updated_at = NOW()
  WHERE id = NEW.cow_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_cow_bcs ON rgbd_camera;
CREATE TRIGGER trigger_update_cow_bcs
AFTER INSERT ON rgbd_camera
FOR EACH ROW
EXECUTE FUNCTION update_cow_latest_bcs();

-- Update latest lameness from depth camera
CREATE OR REPLACE FUNCTION update_cow_latest_lameness()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE cow 
  SET 
    latest_lameness_score = NEW.lameness_score,
    latest_lameness_severity = NEW.lameness_severity,
    latest_lameness_date = NEW.post_milking_timestamp,
    updated_at = NOW()
  WHERE id = NEW.cow_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_cow_lameness ON depth_camera;
CREATE TRIGGER trigger_update_cow_lameness
AFTER INSERT ON depth_camera
FOR EACH ROW
EXECUTE FUNCTION update_cow_latest_lameness();

-- Update current zone from back view camera
CREATE OR REPLACE FUNCTION update_cow_current_zone()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE cow 
  SET 
    current_zone = NEW.current_zone,
    last_seen_timestamp = NEW.recording_timestamp,
    last_seen_camera = 'Camera ' || NEW.camera_number,
    updated_at = NOW()
  WHERE id = NEW.cow_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_cow_zone ON back_view_camera;
CREATE TRIGGER trigger_update_cow_zone
AFTER INSERT ON back_view_camera
FOR EACH ROW
WHEN (NEW.is_minute_marker = true) -- Only update on minute markers
EXECUTE FUNCTION update_cow_current_zone();

-- Calculate daily feeding time
CREATE OR REPLACE FUNCTION update_cow_feeding_time()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.feeding_session_end IS NOT NULL THEN
    UPDATE cow 
    SET 
      total_daily_feeding_time_hours = COALESCE(total_daily_feeding_time_hours, 0) + 
        (EXTRACT(EPOCH FROM (NEW.feeding_session_end - NEW.feeding_session_start)) / 3600.0),
      last_feeding_date = CURRENT_DATE,
      updated_at = NOW()
    WHERE id = NEW.cow_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_cow_feeding ON head_view_camera;
CREATE TRIGGER trigger_update_cow_feeding
AFTER UPDATE ON head_view_camera
FOR EACH ROW
WHEN (NEW.feeding_session_end IS NOT NULL AND OLD.feeding_session_end IS NULL)
EXECUTE FUNCTION update_cow_feeding_time();

-- ============================================================================
-- MATERIALIZED VIEW FOR DASHBOARD (Real-time Statistics)
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS research_dashboard_stats AS
SELECT 
  c.user_id,
  COUNT(DISTINCT c.id) as total_cattle,
  COUNT(DISTINCT CASE WHEN c.latest_lameness_severity IN ('Mild Lameness', 'Severe Lameness') THEN c.id END) as lame_cattle,
  COUNT(DISTINCT CASE WHEN c.latest_bcs_score < 2.5 THEN c.id END) as thin_cattle,
  COUNT(DISTINCT CASE WHEN c.latest_bcs_score > 4.0 THEN c.id END) as overweight_cattle,
  AVG(c.latest_bcs_score) as average_bcs,
  AVG(c.total_daily_feeding_time_hours) as average_daily_feeding_hours,
  COUNT(DISTINCT CASE WHEN c.current_zone = 'Milking Parlor' THEN c.id END) as cattle_in_milking,
  COUNT(DISTINCT CASE WHEN c.current_zone = 'Feeding Area' THEN c.id END) as cattle_in_feeding,
  COUNT(DISTINCT CASE WHEN c.current_zone = 'Resting Space' THEN c.id END) as cattle_in_resting,
  COUNT(DISTINCT CASE WHEN c.current_zone = 'Return Lane' THEN c.id END) as cattle_in_return_lane
FROM cow c
WHERE c.is_active = true
GROUP BY c.user_id;

CREATE UNIQUE INDEX idx_research_dashboard_user ON research_dashboard_stats(user_id);

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE cow IS 'Main cattle registry with general health and identification data';
COMMENT ON TABLE ear_tag_camera IS 'Milking Parlor: Ear-tag recognition (94% accuracy) using CRAFT+ResNet18';
COMMENT ON TABLE depth_camera IS 'Return Lane: Lameness detection from depth data (88.2-89.0% accuracy) using Detectron2+ExtraTrees';
COMMENT ON TABLE side_view_camera IS 'Return Lane: Lameness from RGB gait analysis using YOLOv9+SVM';
COMMENT ON TABLE rgbd_camera IS 'Return Lane: BCS prediction (86.21% accuracy) and identification (99.55%) using PointNet++';
COMMENT ON TABLE head_view_camera IS 'Feeding Area: Face identification (93.66% accuracy) and feeding time using ArcFace';
COMMENT ON TABLE back_view_camera IS 'Feeding/Resting: Body identification (92.80% accuracy) and localization using ResNet-101+ByteTrack';
