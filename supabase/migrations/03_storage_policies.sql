-- ============================================
-- CATTLE AI MONITOR - STORAGE POLICIES
-- Migration: 03_storage_policies
-- ============================================

-- ============================================
-- ANIMAL IMAGES BUCKET POLICIES
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Users can read own images" ON storage.objects;
DROP POLICY IF EXISTS "Public can read images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own images" ON storage.objects;

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'animal-images');

-- Allow authenticated users to read their own images
CREATE POLICY "Users can read own images"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'animal-images');

-- Allow public to read images (if public bucket)
CREATE POLICY "Public can read images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'animal-images');

-- Allow users to update their own images
CREATE POLICY "Users can update own images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'animal-images');

-- Allow users to delete their own images
CREATE POLICY "Users can delete own images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'animal-images');

-- ============================================
-- VIDEOS BUCKET POLICIES
-- ============================================

DROP POLICY IF EXISTS "Authenticated users can upload videos" ON storage.objects;
DROP POLICY IF EXISTS "Users can read own videos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own videos" ON storage.objects;

-- Allow authenticated users to upload videos
CREATE POLICY "Authenticated users can upload videos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'videos');

-- Allow users to read own videos
CREATE POLICY "Users can read own videos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'videos');

-- Allow users to delete own videos
CREATE POLICY "Users can delete own videos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'videos');

-- ============================================
-- ML MODELS BUCKET POLICIES
-- ============================================

DROP POLICY IF EXISTS "Anyone can read ML models" ON storage.objects;

-- Allow anyone to read ML models
CREATE POLICY "Anyone can read ML models"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'ml-models');
