-- ============================================
-- MILKING STATUS TABLE
-- Tracks milking status from video processing
-- ============================================

CREATE TABLE IF NOT EXISTS milking_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cow_id VARCHAR(20) NOT NULL,
    animal_id VARCHAR(20),
    is_being_milked BOOLEAN DEFAULT FALSE,
    milking_confidence DECIMAL(5, 2) CHECK (milking_confidence >= 0 AND milking_confidence <= 100),
    udder_detected BOOLEAN DEFAULT FALSE,
    udder_size VARCHAR(20),
    behavioral_score DECIMAL(5, 2),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Foreign key to animals table
    CONSTRAINT fk_cow_id FOREIGN KEY (cow_id) REFERENCES animals(animal_id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_milking_status_cow_id ON milking_status(cow_id);
CREATE INDEX IF NOT EXISTS idx_milking_status_timestamp ON milking_status(timestamp);
CREATE INDEX IF NOT EXISTS idx_milking_status_is_being_milked ON milking_status(is_being_milked);

-- Enable RLS
ALTER TABLE milking_status ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own milking status"
    ON milking_status FOR SELECT
    USING (
        cow_id IN (
            SELECT animal_id FROM animals WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own milking status"
    ON milking_status FOR INSERT
    WITH CHECK (
        cow_id IN (
            SELECT animal_id FROM animals WHERE user_id = auth.uid()
        )
    );

-- Update animals table to ensure milking_status column exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'animals' AND column_name = 'milking_status'
    ) THEN
        ALTER TABLE animals ADD COLUMN milking_status VARCHAR(20) DEFAULT 'unknown' 
        CHECK (milking_status IN ('milking', 'dry', 'unknown'));
    END IF;
END $$;

-- Comment on table
COMMENT ON TABLE milking_status IS 'Stores milking status detected from video processing';
