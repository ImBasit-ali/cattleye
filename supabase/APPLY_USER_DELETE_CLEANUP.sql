-- Run in Supabase Dashboard → SQL Editor
-- When a user is deleted from Authentication → Users, their storage + app data is removed.

CREATE OR REPLACE FUNCTION public.handle_auth_user_deleted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage
AS $$
BEGIN
  DELETE FROM storage.objects
  WHERE bucket_id IN ('videos', 'cattle_images')
    AND (storage.foldername(name))[1] = OLD.id::text;

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
