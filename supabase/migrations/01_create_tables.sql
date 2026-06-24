-- ============================================
-- CATTLE AI MONITOR - DATABASE SCHEMA
-- Migration: 01_create_tables
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ANIMALS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS animals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id VARCHAR(20) UNIQUE NOT NULL,
    species VARCHAR(50) NOT NULL,
    age INTEGER NOT NULL,
    health_status VARCHAR(50) NOT NULL,
    image_url TEXT,
    breed VARCHAR(100),
    weight DECIMAL(10, 2),
    notes TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for animals
CREATE INDEX IF NOT EXISTS idx_animals_user_id ON animals(user_id);
CREATE INDEX IF NOT EXISTS idx_animals_animal_id ON animals(animal_id);

-- ============================================
-- MOVEMENT DATA TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS movement_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    step_count INTEGER NOT NULL,
    activity_duration_hours DECIMAL(5, 2) NOT NULL,
    rest_duration_hours DECIMAL(5, 2) NOT NULL,
    movement_score DECIMAL(5, 2) NOT NULL,
    movement_level VARCHAR(20) NOT NULL,
    average_speed DECIMAL(10, 2),
    distance_covered INTEGER,
    raw_sensor_data JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for movement_data
CREATE INDEX IF NOT EXISTS idx_movement_animal_id ON movement_data(animal_id);
CREATE INDEX IF NOT EXISTS idx_movement_date ON movement_data(date);
CREATE INDEX IF NOT EXISTS idx_movement_timestamp ON movement_data(timestamp);

-- ============================================
-- LAMENESS RECORDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS lameness_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    detection_date DATE NOT NULL,
    severity VARCHAR(50) NOT NULL,
    confidence_score DECIMAL(5, 4) NOT NULL,
    detection_method VARCHAR(20) NOT NULL,
    step_count INTEGER,
    activity_hours DECIMAL(5, 2),
    rest_hours DECIMAL(5, 2),
    ml_input_features JSONB,
    ml_output_probabilities JSONB,
    video_url TEXT,
    notes TEXT,
    requires_attention BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for lameness_records
CREATE INDEX IF NOT EXISTS idx_lameness_animal_id ON lameness_records(animal_id);
CREATE INDEX IF NOT EXISTS idx_lameness_date ON lameness_records(detection_date);
CREATE INDEX IF NOT EXISTS idx_lameness_severity ON lameness_records(severity);

-- ============================================
-- VIDEO RECORDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS video_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    animal_id UUID NOT NULL REFERENCES animals(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    upload_date DATE NOT NULL,
    duration_seconds INTEGER NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    processing_status VARCHAR(20) NOT NULL,
    analysis_results JSONB,
    error_message TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for video_records
CREATE INDEX IF NOT EXISTS idx_video_animal_id ON video_records(animal_id);
CREATE INDEX IF NOT EXISTS idx_video_status ON video_records(processing_status);
CREATE INDEX IF NOT EXISTS idx_video_upload_date ON video_records(upload_date);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS update_animals_updated_at ON animals;
CREATE TRIGGER update_animals_updated_at BEFORE UPDATE ON animals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
