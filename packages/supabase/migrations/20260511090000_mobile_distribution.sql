-- Create app_versions table to track mobile releases
CREATE TABLE IF NOT EXISTS public.app_versions (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    platform TEXT NOT NULL, -- 'android' or 'ios'
    version_number TEXT NOT NULL,
    build_number INTEGER NOT NULL,
    download_url TEXT NOT NULL,
    release_notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- Allow public read access to version info
CREATE POLICY "Public can view app versions" 
ON public.app_versions FOR SELECT 
USING (true);

-- Allow admins to manage versions
CREATE POLICY "Admins can manage app versions" 
ON public.app_versions FOR ALL 
USING (has_any_role(ARRAY['super_admin', 'gso_staff']));

-- Create storage bucket for distribution if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('distribution', 'distribution', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies for distribution bucket
-- Allow public to download
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'distribution');

-- Allow authenticated admins to upload/delete
CREATE POLICY "Admin Management" 
ON storage.objects FOR ALL 
TO authenticated
USING (bucket_id = 'distribution' AND (select has_any_role(ARRAY['super_admin', 'gso_staff'])));
