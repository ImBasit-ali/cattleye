-- ============================================
-- CATTLE AI MONITOR - ROW LEVEL SECURITY
-- Migration: 02_enable_rls
-- ============================================

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE animals ENABLE ROW LEVEL SECURITY;
ALTER TABLE movement_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE lameness_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_records ENABLE ROW LEVEL SECURITY;

-- ============================================
-- ANIMALS POLICIES
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own animals" ON animals;
DROP POLICY IF EXISTS "Users can insert own animals" ON animals;
DROP POLICY IF EXISTS "Users can update own animals" ON animals;
DROP POLICY IF EXISTS "Users can delete own animals" ON animals;

-- Users can only see their own animals
CREATE POLICY "Users can view own animals"
    ON animals FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own animals
CREATE POLICY "Users can insert own animals"
    ON animals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own animals
CREATE POLICY "Users can update own animals"
    ON animals FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own animals
CREATE POLICY "Users can delete own animals"
    ON animals FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- MOVEMENT DATA POLICIES
-- ============================================

DROP POLICY IF EXISTS "Users can view movement data for their animals" ON movement_data;
DROP POLICY IF EXISTS "Users can insert movement data for their animals" ON movement_data;

CREATE POLICY "Users can view movement data for their animals"
    ON movement_data FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = movement_data.animal_id
            AND animals.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert movement data for their animals"
    ON movement_data FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = movement_data.animal_id
            AND animals.user_id = auth.uid()
        )
    );

-- ============================================
-- LAMENESS RECORDS POLICIES
-- ============================================

DROP POLICY IF EXISTS "Users can view lameness records for their animals" ON lameness_records;
DROP POLICY IF EXISTS "Users can insert lameness records for their animals" ON lameness_records;

CREATE POLICY "Users can view lameness records for their animals"
    ON lameness_records FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = lameness_records.animal_id
            AND animals.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert lameness records for their animals"
    ON lameness_records FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = lameness_records.animal_id
            AND animals.user_id = auth.uid()
        )
    );

-- ============================================
-- VIDEO RECORDS POLICIES
-- ============================================

DROP POLICY IF EXISTS "Users can view video records for their animals" ON video_records;
DROP POLICY IF EXISTS "Users can insert video records for their animals" ON video_records;

CREATE POLICY "Users can view video records for their animals"
    ON video_records FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = video_records.animal_id
            AND animals.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert video records for their animals"
    ON video_records FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM animals
            WHERE animals.id = video_records.animal_id
            AND animals.user_id = auth.uid()
        )
    );
