-- Migration 12: When a user is deleted from Supabase Auth, remove their storage
-- files and ensure related DB rows cascade (most tables already use ON DELETE CASCADE).
--
-- IMPORTANT: Delete users from Dashboard → Authentication → Users (auth.users).
-- Deleting only from user_profiles or public tables does NOT revoke login.

CREATE OR REPLACE FUNCTION public.handle_auth_user_deleted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage
AS $$
BEGIN
  -- Remove uploaded files in user-scoped folders ({user_id}/...)
  DELETE FROM storage.objects
  WHERE bucket_id IN ('videos', 'cattle_images')
    AND (storage.foldername(name))[1] = OLD.id::text;

  -- Explicit cleanup for tables that may exist without FK cascade in older DBs
  DELETE FROM public.cattle_ai_analyses WHERE user_id = OLD.id;
  DELETE FROM public.cattle_detections WHERE user_id = OLD.id;
  DELETE FROM public.animals WHERE user_id = OLD.id;

  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_deleted ON auth.users;
CREATE TRIGGER on_auth_user_deleted
  BEFORE DELETE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_auth_user_deleted();

COMMENT ON FUNCTION public.handle_auth_user_deleted() IS
  'Purges storage objects and app data when a user is removed from auth.users';
