-- ============================================================
-- Migration 010: Booking Storage Policies
-- ============================================================

-- Note: The bucket 'booking_attachments' must be created via Supabase Dashboard
-- or CLI: supabase storage new booking_attachments

-- Allow authenticated users to upload their letters
CREATE POLICY "Booking Attachments Upload"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'booking_attachments');

-- Allow users to view their own attachments
CREATE POLICY "Booking Attachments Select Own"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'booking_attachments' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Allow staff to view all attachments
CREATE POLICY "Booking Attachments Select Staff"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'booking_attachments' AND has_any_role(ARRAY['super_admin', 'gso_staff']));
