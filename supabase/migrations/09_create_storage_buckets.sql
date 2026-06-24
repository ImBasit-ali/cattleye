-- ============================================
-- STORAGE BUCKETS SETUP
-- Create necessary storage buckets for the application
-- ============================================

-- Create videos bucket for processed videos
INSERT INTO storage.buckets (id, name, public)
VALUES ('videos', 'videos', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for videos bucket
CREATE POLICY "Videos are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'videos');

CREATE POLICY "Authenticated users can upload videos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'videos' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can update their own videos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'videos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own videos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'videos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Create cattle_images bucket for animal photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('cattle_images', 'cattle_images', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for cattle_images bucket
CREATE POLICY "Cattle images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'cattle_images');

CREATE POLICY "Authenticated users can upload cattle images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'cattle_images' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can update their own cattle images"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'cattle_images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own cattle images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'cattle_images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Verify buckets were created
SELECT id, name, public FROM storage.buckets;
